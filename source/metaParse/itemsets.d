module metaparse.itemsets;

import metaparse.types;
import metaparse.parsing;

import std.container.rbtree;
import std.sumtype;
import std.typecons;
import std.array;
import std.range;
import std.algorithm;
import std.meta;

import collections.treemap;

import std.stdio;



// bool canFindItem(Item[] arr, Item compare) {
//     foreach (item; arr) {
//         if (item == compare) {return true;}
//     }
//     return false;
// }


int insert(T)(ref T[] s, T t) {
    import std.algorithm: canFind;
    // static if (is(T==Item)) {
    //     if (s.canFindItem(t)) {
    //         return 0;
    //     }
    //     else {
    //         s ~= t;
    //         return 1;
    //     }
    // } else {
        if (s.canFind(t)) {
            return 0;
        }
        else {
            s ~= t;
            return 1;
        }
    // }
}

int insert(T, R)(ref T[] set, R range) if (is(ElementType!R == T)) {
    int accum = 0;
    foreach (T val; range) {
        accum += set.insert(val);
    }
    return accum;
}

struct Item {
    immutable IProduction production;
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

    string toString() {
        auto sym = production.symbols.map!(a=>a.toGramString);
        string tbody = sym[0..position].join(" ") ~ "·" ~ sym[position..$].join(" ");
        return production.result.str ~ " -> " ~ tbody;
    }
    bool opEquals(R)(const R other) const {
        if (this.position != other.position) {return false;}
        if (this.production.result != other.production.result) {return false;}
        if (this.production.length != other.production.length) {return false;}
        immutable GramSymbol[] prodA = this.production.symbols;
        immutable GramSymbol[] prodB = other.production.symbols;
        foreach (i; 0..prodA.length) {
            if (prodA[i] != prodB[i]) {return false;}
        }
        return true;
    }
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


TreeMap!(NonTerminal, IProduction[]) genProductionLookup(IProduction[] productions) {
    TreeMap!(NonTerminal, IProduction[]) productionMap;
    foreach (prod; productions) {
        if (prod.result !in productionMap) {productionMap[prod.result] = [];}
        IProduction[] pList = productionMap[prod.result];
        pList ~= prod;
        productionMap[prod.result] = pList;
    }
    return productionMap;
}

GramSymbol[] findFirstSet(GramSymbol x, TreeMap!(NonTerminal, IProduction[]) prodMap) {   
    GramSymbol[] firsts;
    x.match!(
        (NonTerminal nt) {
            foreach (IProduction prod; prodMap[nt]) {
                GramSymbol[] fset;
                foreach (s, symbol; prod) {
                    if (symbol == x) {goto SkipOver;}
                    fset = findFirstSet(symbol, prodMap); // buffer that long-ass shit.
                    if (!fset.canFind(GramSymbol.empty)) { /// 90% of the time this is the only iteration.
                        firsts.insert(fset);
                        goto SkipOver;
                    }
                    else { //add first(that symbol) minus e
                        firsts.insert(fset.filter!(s => s != GramSymbol.empty));
                    }
                }
                firsts.insert(GramSymbol.empty);
                SkipOver: {}
            }
        },
        (_) {firsts = [x];},
    );
    return firsts;
}

auto findFollowSet(T)(T symB, TreeMap!(NonTerminal, IProduction[]) prodMap) {
    return findFollowSet(cast(GramSymbol)symB, prodMap);
}
GramSymbol[] findFollowSet(GramSymbol symB, TreeMap!(NonTerminal, IProduction[]) prodMap) {
    import std.algorithm;
    GramSymbol[] followB;
    import std.stdio;
    // foreach (k, v; prodMap) {writef!"(%s : %s) "(k, v);} writeln();
    // if (prodMap[NonTerminal("'")][0][0] == symB) {
    //     followB.insert(GramSymbol.eoi);
    // }
    
    foreach (k,v; prodMap) foreach (prod; v) {
        foreach (i, sym; prod.symbols) {
            /// It does not continue if it finds itself
            if (sym == symB) {
                // (if i is the last index)
                if (prod.symbols.length == i+1) {
                    /++ If there is a production A → aB, 
                    then FOLLOW(B) ~= FOLLOW(A). +/
                    followB.insert(findFollowSet(prod.result, prodMap));
                } else {
                    GramSymbol b = prod.symbols[i+1];
                    auto firstB = findFirstSet(b, prodMap);
                    if (firstB.canFind(GramSymbol.empty)) {
                        /++ if A → aBb contains ε +/
                        followB.insert(findFollowSet(prod.result, prodMap));
                    }
                    /++ If there is a production A → aBb, 
                    then FOLLOW(B) ~= FIRST(b) sans ε. +/
                    
                    followB.insert(firstB.filter!(a => !a.matches!Empty));
                }
            }
        }
        // if (symB == GramSymbol(prod.result)) {
        //     writeln(prod);
        //     followB.insert(findFollowSet(prod[$-1], prodMap));
        //     write(".");
        // }//bleh!!!
    }
    return followB.dup;
}


Item item(PContext ctx, int prod, int pos) {
    assert(ctx.productions[prod].symbols.length >= pos);
    return Item(
        ctx.productions[prod],
        pos
    );
}


GramSymbol[] genSymbolTable(GramSymbol[] allSymbols) {
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

/+
unittest {
    import metaparse.parsing;
    import std.stdio;
    import std.algorithm;

    writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");

    // auto ctx = PContext.fromString(q{
    //     T -> F -;
    //     F -> () | I id;
    //     I -> id | ;
    // });
    // E {$ ) + }
    auto ctx = PContext.fromString(q{
        E -> E + T;
        E -> T;
        T -> T * F;
        T -> F;
        F -> ( E );
        F -> id;
    });

    /+
    writeln("Prod ", ctx.productions[0]);
    auto prodLookup = genProductionLookup(ctx.productions);

    writeln("Follow E ", findFollowSet(GramSymbol.nonTerminal("E"), prodLookup));
    writeln("Follow id ", findFollowSet(GramSymbol.terminal("id"), prodLookup));
    writeln(prodLookup[NonTerminal("'")]);
    +//+
    auto states = findStateSets(ctx);
    foreach(i,state; states) {
        writefln!"[%s]\n%-(    %s\n%)\n"(i, state);
    +//+
    auto items = [ctx.item(0,0)];
    writefln!"Productions:\n%(    %s\n%)"(ctx.productions);
    auto closure = findItemClosure(ctx.productions, items);
    items = [ctx.item(0,1), ctx.item(1,1)];
    auto goTo = findItemGoto(ctx.productions, items, GramSymbol.terminal("+"));
    writefln!"Closure:\n%(    %s\n%)"(closure);
    writefln!"Goto:\n%s"(goTo);
    writeln(ctx.allSymbols);
    // +/
}// +/
