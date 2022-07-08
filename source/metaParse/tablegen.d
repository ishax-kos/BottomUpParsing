module metaparse.tablegen;

import metaparse.types;
import metaparse.itemsets;
import metaparse.parsing;

import std.format;
import std.algorithm;
import std.sumtype;
import std.array;
import std.range;
import std.typecons;


import std.stdio;

enum {
    ErrState,
    Shift,
    Reduce,
    Accept,
    ACTION_TYPE_MAX
}
struct Action {
    ushort actionType;
    ushort value;

    this(T1,T2)(T1 at, T2 val) {
        assert(at == Shift || at == Reduce);
        actionType = cast(ushort) at;
        assert(val < ushort.max);
        value = cast(ushort) val;
    }
    this(T)(T at) {
        assert(at == ErrState || at == Accept);
        actionType = cast(ushort) at;
    }

    string toString() const @safe pure nothrow {
        import std.conv;
        final switch(actionType) {
            case ErrState: return "";
            case Shift: return "s" ~ value.to!string;
            case Reduce: return "r" ~ value.to!string;
            case Accept: return "Ac";
        }
    }
}

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
    int[][] tblGoto;
}

TableContext parseGrammar(string input) {
    auto ctx = PContext.fromString(input);

    GramSymbol[] symbolTable = ctx.genSymbolTable;
    Item[][] states = ctx.findStateSets(symbolTable);
    

    ushort[GramSymbol] symbolIndex;
    ushort[GramSymbol] terminals;
    ushort[GramSymbol] nonTerminals;
    
    ushort ct, cn;
    foreach (i, sym; symbolTable) {
        if (i > ushort.max) {throw new Exception("Too many symbols.");}

        symbolIndex[sym] = cast(ushort) i;
        sym.match!( 
            (Empty _) {},
            (NonTerminal _) {
                nonTerminals[sym] = cn++;
            }, 
            (_) {
                terminals[sym] = ct++;
            } 
        );
    }

    Action[][] tblAction = new Action[][states.length];
    int[][] tblGoto = new int[][states.length];
    // tblAction
    // tblAction.length = states.length;
    // tblGoto  .length = states.length;
    foreach(i; 0..states.length) {
        tblAction[i] = new Action[terminals.length];
        tblGoto[i] = new int[nonTerminals.length];
    }
    
    writeln(terminals);

    foreach (setIndex, set; states) {

        foreach(f, item; set) {
            if (item.empty) {
                if (item == ctx.item(0, 1)) {
                    enum eoi = 0;
                    tblAction.addAction(setIndex, eoi, Action(Accept));
                }
                else {
                    GramSymbol sym = item.production.symbols[item.position-1];
                    sym.match!(
                        (NonTerminal _) {}, (Empty _) {},
                        (_) {//Terminal
                            tblAction.addAction(
                                setIndex, symbolIndex[sym], 
                                Action(Reduce, cast(ushort) 
                                    ctx.productions.countUntil(*item.production))
                            );
                        }
                    );
                }
            }
            else {
                foreach (jsetIndex, Item[] setj; states) {
                    GramSymbol itemFront = item.front;
                    
                    itemFront.match!(
                        (NonTerminal _) {}, (Empty _) {},
                        (_) {
                            if (setj == findItemGoto(ctx.productions, set, itemFront)) {
                                ushort index = symbolIndex[itemFront];
                                tblAction.addAction(setIndex, index, Action(Shift, cast(ushort) jsetIndex));
                            }
                        }
                    );
                }
            }
        }

        uint a = 0;
        foreach (nt, nt_i; nonTerminals) {
            foreach (jsetIndex, Item[] setj; states) {
                if (setj == findItemGoto(ctx.productions, set, nt)) {
                    tblGoto[setIndex][a] = cast(int) jsetIndex;
                }
            }
            a++;
        }
    }
    return TableContext(tblAction, tblGoto);
}




unittest {
    import std.stdio;
    writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");
    auto ctx = parseGrammar(q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    });


    writefln!"  %(%4s%)"(iota(1,7));
    foreach(i, row; ctx.tblAction) {
        writef!"%3s["(i);
        foreach(item; row) {
            writef("%=4s", item.toString);
        }
        writeln("]");
    }
    // writefln!"%([%(%s %)]\n%)"(ctx.tblAction);
}


// void main() {
    
// }