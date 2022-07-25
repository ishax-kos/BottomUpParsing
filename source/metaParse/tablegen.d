module metaparse.tablegen;

import metaparse.types;
import metaparse.itemsets;
import metaparse.parsing;
import metaparse.tabletypes;

import std.format;
import std.algorithm;
import std.sumtype;
import std.array;
import std.range;
import std.typecons;
import std.conv;
import std.bitmanip;

import collections.treemap;

import std.stdio;




void addAction(ref Action[][] tblAction, ulong state, ulong symbol, Action newAction) {
    Action* tableCell = &(tblAction[state][symbol]);
    
    if (tableCell.actionType == ErrState) {
        *tableCell = newAction;
    }
    else if (*tableCell != newAction) {
        throw new Exception(format!"%s - %s conflict"(
            tableCell.actionType, newAction.actionType));
    }
}


struct TableContext {
    Action[][] tblAction;
    GoTo[][] tblGoto;

    ushort[] prodResult;
    ushort[][] prodBody;
    
    TreeMap!(GramSymbol, ushort) terminals;
    TreeMap!(GramSymbol, ushort) nonTerminals;
    
    TreeMap!(Nonterminal, IProduction[]) prodLookup;
}

TableContext buildTables(string s) {
    return buildTables(PContext.fromString(s));
}


TableContext buildTables(PContext ctx) {

    GramSymbol[] symbolTable = (ctx.allSymbols.dup);
    Item[][] states = ctx.findStateSets();
    auto prodLookup = genProductionLookup(ctx.productions);


    /// Build index reference tables for terminals and nonterminals
    TreeMap!(GramSymbol, ushort) terminals;
    TreeMap!(GramSymbol, ushort) nonTerminals;
    TreeMap!(GramSymbol, ushort) symbolLookup;
    
    {ushort ct, cn;
    foreach (i, sym; symbolTable) {
        if (i > ushort.max) {throw new Exception("Too many symbols.");}
        sym.match!(
            (Empty _) {},
            (Nonterminal _) {
                nonTerminals[sym] = cn;
                symbolLookup[sym] = cast(ushort) ~cn;
                cn++;
            },
            (_) {
                terminals[sym] = ct;
                symbolLookup[sym] = ct;
                ct++;
            }
        );
    }}
    
    ushort[] prodResult = new ushort[ctx.productions.length-1];
    ushort[][] prodBody = new ushort[][ctx.productions.length-1];
    foreach (i, prod; ctx.productions[1..$]) {
        prodResult[i] = nonTerminals[GramSymbol(prod.result)];
        prodBody[i] = prod.symbols.map!(s => symbolLookup[s]).array;
    }
    

    /// Build goto and action tables.
    Action[][] tblAction = new Action[][states.length];
    GoTo[][] tblGoto = new GoTo[][states.length];
    
    foreach(i; 0..states.length) {
        tblAction[i] = new Action[terminals.length];
        tblGoto[i] = new GoTo[nonTerminals.length];
    }

    foreach (setIndex, set; states) {
        import std.random;

        foreach(item; set ) {
            if (item.empty) {
                
                if (item == ctx.item(0, 1)) {
                    /// if at augment production
                    /// Add the 'Accept' action
                    uint eoi = terminals[GramSymbol.eoi];
                    tblAction.addAction(setIndex, eoi, Action(Accept));
                }
                else {
                    /// if at some production
                    /// Add a 'Reduce' action
                    GramSymbol[] followsA = findFollowSet(item.production.result, prodLookup);
                    ushort pi = cast(ushort) ctx.productions.countUntil(item.production);

                    foreach (a; followsA) {
                        tblAction.addAction(
                            setIndex, terminals[a], 
                            Action(Reduce, pi)
                        );
                    }
                }
            }
            else {
                /// Add a 'Shift' action
                foreach (jsetIndex, Item[] setj; states) {
                    GramSymbol itemFront = item.front;
                    
                    itemFront.match!(
                        (Nonterminal _) {}, (Empty _) {},
                        (_) {
                            if (setj == findItemGoto(ctx.productions, set, itemFront)) {
                                ushort index = terminals[itemFront];
                                tblAction.addAction(setIndex, index, Action(Shift, cast(ushort) jsetIndex));
                            }
                        }
                    );
                }
            }
        }
        /// Goto table building
        foreach (nt, nt_i; nonTerminals) {
            foreach (jsetIndex, Item[] setj; states) {
                if (setj == findItemGoto(ctx.productions, set, nt)) {
                    tblGoto[setIndex][nt_i] = GoTo(jsetIndex);
                }
            }
        }
    }
    // GramSymbol[] terms = new GramSymbol[terminals.length];
    // foreach(k, v; terminals) {terms[v] = k;}



    return TableContext(
        tblAction, tblGoto, 
        prodResult, prodBody,
        terminals, nonTerminals,
        prodLookup);
}

//+
unittest {
    import std.conv;
    import std.stdio;
    writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");
    auto ctx = PContext.fromString(q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    });
    TableContext tables = ctx.buildTables;

    // writefln!"    %-(%=4s%) ..."(
    //     tables.symbolKey.map!(to!string)
    // );
    foreach(r; 0..tables.tblAction.length) {
        writef!"%3s["(r);
        foreach(item; tables.tblAction[r]) {
            writef("%=4s", item.toString);
        }
        write("][");
        
        foreach(item; tables.tblGoto[r]) {
            writef("%=4s", item.to!string);
        }
        writeln("]");
    }
    // writefln!"%([%(%s %)]\n%)"(ctx.tblAction);
}


// +/