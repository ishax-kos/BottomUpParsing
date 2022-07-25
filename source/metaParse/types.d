module metaparse.types;


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


struct Nonterminal {
    string str = "";

    int opCmp(R)(const R other) const {
        return cmp(this.str, other.str);
    }
}

struct Terminal {
    string str;
}

alias SymbolTypes = AliasSeq!(Nonterminal, Terminal, Empty, EndOfInput);

struct GramSymbol {
    SumType!(SymbolTypes) sum;
    alias sum this;
    alias Sum = typeof(sum);
    int opCmp(const GramSymbol g2) const pure @safe nothrow @nogc {
        import std.algorithm.comparison : cmp;

        return match!(
            (EndOfInput e, EndOfInput e2) => 0,
            (EndOfInput e, _) => -1,
            (_, EndOfInput e) => 1,

            (Empty e, Empty e2) => 0,
            (Empty e, _) => -1,
            (_, Empty e) => 1,

            (Nonterminal n, Terminal t) => -1,
            (Terminal t, Nonterminal n) => 1,

            (Nonterminal a, Nonterminal b) { return cmp(a.str, b.str); },
            (Terminal a, Terminal b) { return cmp(a.str, b.str); }
        )(this, g2);
    }

    auto opAssign(T)(T value) @trusted {
        this.sum = cast(SumType!(SymbolTypes)) value;
        return this;
    }

    static GramSymbol nonTerminal(string value = "") {
        GramSymbol g;
        g.sum = Nonterminal(value);
        return g;
    }

    static GramSymbol terminal(string value = "") {
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
    string toString() const {
        return toGramString();
    }
    string toGramString() const {
        return sum.match!(
            (Empty _) => "_",
            (EndOfInput _) => "$",
            (e) => e.str,
        );
    }

    static bool less(GramSymbol a, GramSymbol b) {
        return a.opCmp(b) == -1;
    }
    bool opEquals(R)(R other) const {
        return this.opCmp(other) == 0;
    }
}


GramSymbol sum(T)(T value) {
    GramSymbol g;
    g.sum = GramSymbol.Sum(value);
    return g;
}


bool matches(T, S)(S sum) if (isSumType!S && __traits(compiles, S(T.init))) {
    return sum.match!(
        (T _) => true,
        (_) => false
    );
}


/// Symbolic IProduction
alias IProduction = immutable Production;
struct Production {
    Nonterminal result;
    GramSymbol[] symbols;
    alias symbols this;
    
    this(Nonterminal a, GramSymbol[] b) {
        result = a;
        symbols = b;
    }
    
    int opCmp(const Production other) const {
        int comp = result.opCmp(other.result);
        if (comp == 0) {
            comp = cmp(symbols, other.symbols);
        }
        return comp;
    }
    bool opEquals(R)(R other) const {
        return this.opCmp(other) == 0;
    }

    // override
    string toString() const {
        auto sym = symbols.map!(a=>a.toGramString);
        return result.str ~ " -> " ~ sym.join(" ");
    }
}
