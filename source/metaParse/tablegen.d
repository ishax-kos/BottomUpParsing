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

import collections.treemap;

import std.stdio;

void addAction(ref Action[][] tblAction, ulong state, ulong symbol, Action newAction
) {
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

    GramSymbol[] symbolKey;
}

TableContext buildTables(string s) {
    return buildTables(PContext.fromString(s));
}


TableContext buildTables(PContext ctx) {

    GramSymbol[] symbolTable = (ctx.allSymbols.dup);
    Item[][] states = ctx.findStateSets();
    auto prodLookup = genProductionLookup(ctx.productions);
    

    // ushort[GramSymbol] symbolIndex;
    TreeMap!(GramSymbol, ushort) terminals;
    TreeMap!(GramSymbol, ushort) nonTerminals;
    
    
    {ushort ct, cn;
    foreach (i, sym; symbolTable) {
        if (i > ushort.max) {throw new Exception("Too many symbols.");}

        // symbolIndex[sym] = cast(ushort) i;
        sym.match!( 
            (Empty _) {},
            (NonTerminal _) {
                // if (!nonTerminals.has(sym))
                nonTerminals[sym] = cn++;
            }, 
            (_) {
                // if (!terminals.has(sym))
                terminals[sym] = ct++;
            } 
        );
    }}
    // debug {
        
    // writeln(nonTerminals);
    // writeln(terminals);
    // }

    Action[][] tblAction = new Action[][states.length];
    GoTo[][] tblGoto = new GoTo[][states.length];
    // tblAction
    // tblAction.length = states.length;
    // tblGoto  .length = states.length;
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
                    uint eoi = terminals[GramSymbol.eoi];
                    tblAction.addAction(setIndex, eoi, Action(Accept));
                }
                else {
                    /// if at some production
                    GramSymbol sym = item.production.symbols[item.position-1];
                    GramSymbol[] followsA = findFollowSet(item.production.result, prodLookup);
                    ushort pi = cast(ushort) ctx.productions.countUntil(item.production);
                    writefln!"%s %s %s"(setIndex, followsA, pi);

                    // assert(sym in terminals, sym.to!string);

                    // auto handler(T)(T _) {//Terminal
                        foreach (a; followsA) {//if(a == sym) {
                            tblAction.addAction(
                                setIndex, terminals[a], 
                                Action(Reduce, pi)
                            );
                        }
                    //writeln(a);//}
                    // }
                    // sym.match!(
                    //     (NonTerminal _) {}, (Empty _) {},
                    //     handler!Terminal,
                    //     handler!EndOfInput
                    // );
                }
            }
            else {
                foreach (jsetIndex, Item[] setj; states) {
                    GramSymbol itemFront = item.front;
                    
                    itemFront.match!(
                        (NonTerminal _) {}, (Empty _) {},
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

        foreach (nt, nt_i; nonTerminals) {
            foreach (jsetIndex, Item[] setj; states) {
                if (setj == findItemGoto(ctx.productions, set, nt)) {
                    tblGoto[setIndex][nt_i] = GoTo(jsetIndex);
                }
            }
        }
    }
    GramSymbol[] terms = new GramSymbol[terminals.length];
    foreach(k, v; terminals) {terms[v] = k;}
    return TableContext(tblAction, tblGoto, terms);
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

    writefln!"    %-(%=4s%) ..."(
        tables.symbolKey.map!(to!string)
    );
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