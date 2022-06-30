module metaParse.itemsets;

import metaParse.types;

import std.container.rbtree;
import std.sumtype;
import std.typecons;

alias Unit = int[0];
enum nil = Unit.init;
alias Set(T...) = RedBlackTree!(T);
alias set = redBlackTree;

struct Item {
    uint production;
    uint position;

    int opCmp(const Item other) const {
        int compare(T)(T a, T b) {
            return a > b ? 1 : a < b ? -1 : 0;
        }

        int comp = compare(this.production, other.production);
        if (comp == 0) {
            comp = compare(this.position, other.position);
        }
        return comp;
    }
    auto opBinary(string op, R)(const R rhs) const {
        return Item(production, mixin("position ", op, " rhs"));
    }
}

T1 transmute(T1, T2)(T2 item) if (T1.sizeof == T2.sizeof) {
    return *cast(T1*)&item;
}


alias QGramSymbol = Nullable!(GramSymbol, GramSymbol(Empty()));

GramSymbol getSymbolAtIndex(Context* ctx, Item item) {
    Production prod = ctx.productions[item.production];
    if (prod.symbols.length <= item.position) {
        return GramSymbol(Empty());
    } else {
        return prod.symbols[item.position];
    }
}
Set!Item findItemClosure(Context* ctx, Item item) {
    return findItemClosure(ctx, set(item));
}
Set!Item findItemClosure(Context* ctx, Set!Item items) {
            import std.stdio;
    Set!Item j = items.dup;
    while (true) {
        ulong jLength = j.length;
        foreach (Item item; j) {
            GramSymbol symbol = ctx.getSymbolAtIndex(item);
            symbol.match!(
                (NonTerminal _) {
                    foreach (pi, prod; ctx.productions) {
                        if (prod.result == symbol) {
                            j.insert(Item(cast(uint) pi, 0));
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


Set!Item findItemGoto(Context* ctx, Set!Item items, GramSymbol symbol) {
    import std.stdio;
    import std.algorithm;
    import std.range;
    Set!Item j = findItemClosure(ctx, items[].filter!(
        item => getSymbolAtIndex(ctx, item) == symbol
    ).map!(item => item + 1).set);
    writeln("n");

    return j;
}

// uint[][] generateTable() {

// }

unittest {
    import metaParse.parsing;
    import std.stdio;
    Context* ctx = Context.fromString(q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    }
    );

    ctx.parseRuleTable();
    Set!Item items = set(Item(0,0));
    Set!Item next = ctx.findItemClosure(items);
    writeln("CLOSURE ", next);
    writeln("GOTO ", ctx.findItemGoto(set(Item(0,1)), GramSymbol(Terminal("+"))));
}
