module metaparse.itemsets;

import metaparse.types;
import metaparse.parsing;

import std.container.rbtree;
import std.sumtype;
import std.typecons;
import std.array;
import std.range;
import std.algorithm;

import std.stdio;



// alias Unit = int[0];
// enum nil = Unit.init;
// alias Set(T) = T[];
// auto set(T)(T[] items...) {
//     return items;
// }
// auto set(T)(T range) 
// if (isInputRange!T) {
//     return range.array;
// }

int insert(T)(ref T[] s, T t) {
    import std.algorithm: canFind;
    
    if (s.canFind(t)) {
        return 0;
    }
    else {
        s ~= t;
        return 1;
    }
}

struct Item {
    immutable IProduction production;
    uint position;

    bool empty() pure {
        return (position >= production.length);
    }
    GramSymbol front() pure {
        if (empty) {return GramSymbol.empty;}
        else {
            return production.symbols[position];
        }
    }
    auto opBinary(string op, R)(R rhs) pure {
        return Item(production, mixin("position ", op, " rhs"));
    }

    string toString() pure {
        auto sym = production.symbols.map!(a=>a.toGramString);
        string tbody = sym[0..position].join(" ") ~ "·" ~ sym[position..$].join(" ");
        return production.result.str ~ " -> " ~ tbody;
    }
    // int value(PContext ctx) const {
    //     ctx.
    //     int ret = productions;
    //     if (ret == 0) {
    //         ret = 
    //             position > other.position ? 1 : 
    //             position < other.position ? -1 : 
    //             0;
    //     }
    //     return ret;
    // }
}

T1 transmute(T1, T2)(T2 item) if (T1.sizeof == T2.sizeof) {
    return *cast(T1*)&item;
}


alias QGramSymbol = Nullable!(GramSymbol, GramSymbol(Empty()));

Item[] findItemClosure(T)(IProduction[] productions, T items)
if (isInputRange!T && is(typeof(items.front) == Item)) 
{
    import std.stdio;
    Item[] j = items.array;
    uint i;
    while (true) {
        ulong jLength = j.length;
        foreach (Item item; j) {
            GramSymbol symbol = item.front;
            symbol.match!(
                (NonTerminal nt) {
                    foreach (pindex, prod; productions) {
                        if (sum(prod.result) == symbol) {
                            j.insert(Item(prod, 0));
                        }
                    }
                },
                (Terminal _) {},
                (Empty _) {},
                (EndOfInput _) {},
            );
        }

        if (jLength == j.length) {
            break;
        }
    }
    return j;
}


Item[] findItemGoto(IProduction[] productions, Item[] items, GramSymbol symbol) {
    // import std.stdio;
    import std.algorithm;
    import std.range;
    Item[] j;
    foreach (item; items) {
        if (item.front == symbol) {
            j ~= item + 1;
        }
        else {
            
        // writeln(item.front.tupleof, " isn't ", symbol.tupleof);
        }
    }

    return findItemClosure(productions, j);
}


Item[][] findStateSets(PContext ctx) {
    import std.stdio;
    Item aug = ctx.item(0, 0);
    Item[][] c = [findItemClosure(ctx.productions, [aug])];
    ulong clen = 0;
    while (true) {
        clen = c.length;
        foreach (itemSet; c) { 
            foreach (symbol; ctx.allSymbols) {
                if (symbol!=GramSymbol.empty) {
                    Item[] gotoo = findItemGoto(ctx.productions, itemSet, symbol);
                    if (!gotoo.empty) {
                        c.insert(gotoo);
                    }
                }
            } 
        }
        if (clen == c.length) {break;}
    }
    return c;
}


Item item(PContext ctx, int prod, int pos) {
    assert(ctx.productions[prod].symbols.length >= pos);
    return Item(
        ctx.productions[prod],
        pos
    );
}


GramSymbol[] genSymbolTable(GramSymbol[] allSymbols) pure {
    import std.stdio;

    string[] nterm;
    string[] term;
    foreach (sym; allSymbols) {
        sym.match!(
            (NonTerminal a) { nterm ~= a.str; },
            (Terminal a) { term ~= a.str; },
            (_) {},
        );
    }
    auto term2 = term.sort
            .map!(a => GramSymbol.terminal(a));
    auto nterm2 = nterm.sort
            .map!(a => GramSymbol.nonTerminal(a));

    return [GramSymbol.eoi] ~ term2.array ~ nterm2.array;
}

//+
unittest {
    import metaparse.parsing;
    import std.stdio;
    import std.algorithm;

    writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");

    auto ctx = PContext.fromString(q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    });
    auto items = [ctx.item(0,0)];
    writefln!"Productions:\n%(    %s\n%)"(ctx.productions);
    auto closure = findItemClosure(ctx.productions, items);
    items = [ctx.item(0,1), ctx.item(1,1)];
    auto goTo = findItemGoto(ctx.productions, items, GramSymbol.terminal("+"));
    writefln!"Closure:\n%(    %s\n%)"(closure);
    writefln!"Goto:\n%s"(goTo);

    //+
    auto states = findStateSets(ctx);
    writeln(ctx.allSymbols);
    foreach(i,state; states) {
        writefln!"[%s]\n%-(    %s\n%)\n"(i, state);
    }// +/
}// +/
