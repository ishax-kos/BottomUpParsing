module metaparse.types;

import metaparse.tablegen : Action;

import std.sumtype;
import std.meta : AliasSeq;
import std.container.rbtree;
import std.typecons;
import std.algorithm;
import std.range;




struct EndOfInput {
}

struct Empty {
}

struct NonTerminal {
    string str;
}

struct Terminal {
    string str;
}

alias SymbolTypes = AliasSeq!(NonTerminal, Terminal, Empty, EndOfInput);

struct GramSymbol {
    SumType!(SymbolTypes) sum;
    alias sum this;
    alias Sum = typeof(sum);
    int opCmp(const GramSymbol g2) const {
        import std.algorithm.comparison : cmp;

        return match!(
            (EndOfInput e, EndOfInput e2) => 0,
            (EndOfInput e, _) => -1,
            (_, EndOfInput e) => 1,

            (Empty e, Empty e2) => 0,
            (Empty e, _) => -1,
            (_, Empty e) => 1,

            (NonTerminal n, Terminal t) => -1,
            (Terminal t, NonTerminal n) => 1,

            (NonTerminal a, NonTerminal b) { return cmp(a.str, b.str); },
            (Terminal a, Terminal b) { return cmp(a.str, b.str); }
        )(this, g2);
    }

    static GramSymbol nonTerminal(string value = "") pure {
        GramSymbol g;
        g.sum = NonTerminal(value);
        return g;
    }

    static GramSymbol terminal(string value = "") pure {
        GramSymbol g;
        g.sum = Terminal(value);
        return g;
    }

    enum GramSymbol empty = GramSymbol(Empty());
    enum GramSymbol eoi = GramSymbol(EndOfInput());

    static foreach (T; SymbolTypes) {
        this(T node) {
            sum = SumType!(SymbolTypes)(node);
        }
    }
    string toString() const pure {
        return toGramString();
    }
    string toGramString() const pure {
        return sum.match!(
            (Empty _) => "_",
            (EndOfInput _) => "$",
            (e) => e.str,
        );
    }
}


GramSymbol sum(T)(T value) pure {
    GramSymbol g;
    g.sum = GramSymbol.Sum(value);
    return g;
}


/// Symbolic IProduction
alias IProduction = immutable Production;
class Production {
    NonTerminal result;
    GramSymbol[] symbols;
    alias symbols this;
    
    this(NonTerminal a, GramSymbol[] b) pure {
        result = a;
        symbols = b;
    }
    // ref auto opIndex(size_t index) const {
    //     return symbols[index];
    // }

    // size_t length() const {
    //     return symbols.length;
    // }
    override
    string toString() const {
        auto sym = symbols.map!(a=>a.toGramString);
        return result.str ~ " -> " ~ sym.join(" ");
    }
}
