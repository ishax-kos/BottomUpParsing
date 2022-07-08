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
    immutable IProduction* production;
    uint position;

    bool empty() {
        return (position >= production.length);
    }
    GramSymbol front() {
        if (empty) {return GramSymbol.empty;}
        else {
            return production.symbols[position];
        }
    }
    auto opBinary(string op, R)(R rhs) {
        return Item(production, mixin("position ", op, " rhs"));
    }

    // string toString() {
    //     auto sym = production.symbols.map!(a=>a.toGramString);
    //     string tbody = sym[0..position].join() ~ "·" ~ sym[position..$].join();
    //     return production.result.str ~ " -> " ~ tbody;
    // }
    string toString() {
        string tbody;
        tbody.reserve = production.length;

        {size_t i = 0;
        while (i < production.symbols.length) {
            auto sym = &production.symbols[i];
            
            if (i == position) {tbody ~= "·";}
            tbody ~= sym.toGramString;

            i += 1;
        }}

        return production.result.str ~ " -> " ~ tbody;
    }
}

T1 transmute(T1, T2)(T2 item) if (T1.sizeof == T2.sizeof) {
    return *cast(T1*)&item;
}


alias QGramSymbol = Nullable!(GramSymbol, GramSymbol(Empty()));

Item[] findItemClosure(T)(IProduction[] productions, T items) 
if (isInputRange!T && is(typeof(items.front) == Item)) 
{
    Item[] j = items.array;
    while (true) {
        ulong jLength = j.length;
        foreach (Item item; j) {
            GramSymbol symbol = item.front;
            symbol.match!(
                (NonTerminal _) {
                    foreach (pindex, prod; productions) {
                        if (GramSymbol(prod.result) == symbol) {
                            j.insert(Item(&prod, 0));
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
    import std.stdio;
    import std.algorithm;
    import std.range;
    
    Item[] j = findItemClosure(productions, items[].filter!(
        item => item.front == symbol
    ).map!(item => item + 1).array);

    return j;
}


Item[][] findStateSets(PContext ctx, GramSymbol[] symbolTable) {
    import std.stdio;
    Item aug = ctx.item(0, 0);
    Item[][] c = [findItemClosure(ctx.productions, [aug])];
    ulong clen = 0;
    while (true) {
        clen = c.length;
        foreach (itemSet; c) { 
            foreach (symbol; symbolTable) {
                Item[] gotoo = findItemGoto(ctx.productions, itemSet, symbol);
                if (!gotoo.empty) {
                    c.insert(gotoo);
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
        &ctx.productions[prod],
        pos
    );
}


GramSymbol[] genSymbolTable(PContext ctx) {
    import std.stdio;

    string[] nterm;
    string[] term;
    foreach (sym; ctx.allSymbols) {
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
    writeln(items);
    auto closure = findItemClosure(ctx.productions, items);
    auto goTo = findItemGoto(ctx.productions, items, GramSymbol.nonTerminal("E"));
    writefln!"Closure:\n%s"(closure);
    writefln!"Goto:\n%s"(goTo);

    /+
    GramSymbol[] symbolTable = ctx.genSymbolTable;
    auto states = findStateSets(ctx, symbolTable);
    foreach(i,state; states) {
        writefln!"[%s]\n%-(    %s\n%)\n"(i, state);
    }// +/
}// +/
