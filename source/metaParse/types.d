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

    static GramSymbol nonTerminal(string value = "") {
        return GramSymbol(NonTerminal(value));
    }

    static GramSymbol terminal(string value = "") {
        return GramSymbol(Terminal(value));
    }

    static GramSymbol empty = GramSymbol(Empty());
    static GramSymbol eoi = GramSymbol(EndOfInput());

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
            (nt) => nt.str,
            (Empty _) => "_",
            (EndOfInput _) => "$"
        );
    }
}

// insert

/// Symbolic IProduction
alias IProduction = immutable Production;
struct Production {
    NonTerminal result;
    GramSymbol[] symbols;
    alias symbols this;
}
