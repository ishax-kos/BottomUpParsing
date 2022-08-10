module metaparse.parsing;

import metaparse.types;
import collections;

import std.range;
import std.algorithm;
import std.array;
import std.sumtype;
import std.typecons;


// alias ArraySet(T) = ArrayMap!(T, void);


alias PContext = immutable ParseContext;
public class ParseContext {
    Production[] productions = [];
    GramSymbol[] allSymbols;
    // mixin ConstructThis;
    static 
    PContext fromString(string s) {
        auto baseCtx = InputContext.fromString(s);
        auto ctx = new ParseContext();
        ctx.productions = baseCtx.productions.dup;
        ctx.allSymbols = baseCtx.allSymbols.dup;
        return cast(immutable) ctx;
    }
}

Production augmentProduction(ref Production startProd) {
    Nonterminal startSym = startProd.result;
    Nonterminal augSym = Nonterminal("'");
    GramSymbol g;
    g.sum = GramSymbol.Sum(startSym);
    return Production(augSym, [g]);
}

class  InputContext {

    string input = "";
    ArraySet!StaticTerminal staticTerminals;

    ArraySet!Production productions;
    ArraySet!LexRule lexRules;


    typeof(this) fromString() {
        Production[] prods = [Production()]; /// The first spot is reserved
        while (!this.input.empty()) {
            consumeWS(this);
            if (this.input.empty())
                break;
            
            string name = parseIdentifier(this);

            if ('A' <= name[0] >= 'Z') {
                parseRule(name);
            }
            else {
                parseLexRule(name);
            }
        }
        this.getSymbol(GramSymbol.eoi);
        this.getSymbol(GramSymbol.empty);
        prods[0] = augmentProduction(prods[1]);
        return prods;
    }


    Production[] parseRule(string namestr) { 
        Nonterminal name = Nonterminal(namestr);
        GramSymbol g; g.sum = GramSymbol.Sum(name);
        consumeWS(this);
        if (this.input[0 .. 2] != "->") {
            throw new Error("Missing arrow at:\n" ~ this.input);
        }

        this.input.popFrontN(2);
        consumeWS(this);

        GramSymbol[][] allSymbols;

        Semi: while (1) {
            GramSymbol[] symbols;
            scope (exit)
                allSymbols ~= symbols;
            Bar: while (1) {
                consumeWS(this);
                switch (this.input[0]) {
                    case 'A': .. case 'Z': {
                        symbols ~= this.getSymbol(
                            GramSymbol.nonTerminal(parseIdentifier(this))
                        );
                        break;
                    }
                    case ' ', '\n', '\r', '\t': {
                        getTailWhiteSpace(this);
                        break;
                    }
                    case ';': {
                        this.input.popFront;
                        break Semi;
                    }
                    case '|': {
                        this.input.popFront;
                        break Bar;
                    }
                    case 'a': .. case 'z': {
                        symbols ~= this.getSymbol(
                            GramSymbol.terminal(parseIdentifier(this))
                        );
                        break;
                    }
                    default: {
                        symbols ~= this.getSymbol(
                            GramSymbol.terminal([this.input[0]])
                        );
                        this.input.popFront;
                        break;
                    }
                }
            }
        }
        Production[] prods;
        foreach (list; allSymbols) {
            prods ~= Production(name, list);
        }
        return prods;
    }

    Production[] parseLexRule(string namestr) { 
        LexRule rule;
        rule.name = namestr;

        consumeWS();
        if (this.input[0 .. 2] != "+>") {
            throw new Error("Missing arrow at:\n" ~ input);
        }
        this.input.popFrontN(2);
        consumeWS();

        GramSymbol[][] allSymbols;

        Semi: while (1) {
            GramSymbol[] symbols;
            scope (exit)
                allSymbols ~= symbols;
            Bar: while (1) {
                consumeWS(this);
                switch (this.input[0]) {
                    case 'A': .. case 'Z': {
                        symbols ~= this.getSymbol(
                            GramSymbol.nonTerminal(parseIdentifier(this))
                        );
                        break;
                    }
                    case ' ', '\n', '\r', '\t': {
                        getTailWhiteSpace(this);
                        break;
                    }
                    case ';': {
                        this.input.popFront;
                        break Semi;
                    }
                    case '|': {
                        this.input.popFront;
                        break Bar;
                    }
                    case 'a': .. case 'z': {
                        symbols ~= this.getSymbol(
                            GramSymbol.terminal(parseIdentifier(this))
                        );
                        break;
                    }
                    default: {
                        symbols ~= this.getSymbol(
                            GramSymbol.terminal([this.input[0]])
                        );
                        this.input.popFront;
                        break;
                    }
                }
            }
        }
        Production[] prods;
        foreach (list; allSymbols) {
            prods ~= Production(name, list);
        }
        return prods;
    }

    string parseIdentifier() {
        int len = 1;
        Loop: foreach (ch; this.input[1 .. $]) {
            switch (ch) {
                case 'a': .. case 'z':
                    goto case '_';
                case 'A': .. case 'Z':
                    goto case '_';
                case '0': .. case '9':
                    goto case '_';
                case '_': {
                    len++;
                }
                break;
                default: {
                    break Loop;
                }
            }
        }
        auto ret = this.input[0 .. len].idup;
        this.input.popFrontN(len);
        return ret;
    }

    void consumeWS(int Start = 0)() {
        int len = Start;
        Loop: foreach (ch; this.input[Start .. $]) {
            switch (ch) {
                case ' ', '\n', '\r', '\t': {
                    len += 1;
                }
                break;
                default: {
                    break Loop;
                }
            }
        }
        this.input.popFrontN(len);
    }

    alias getTailWhiteSpace = consumeWS!1;

    unittest {
        import std.conv;
        // import std.stdio;
        // writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");

        auto this = InputContext.fromString("E -> E + T | T;");
        consumeWS(this);
        parseIdentifier(this);
        consumeWS(this);
        assert(this.input[0 .. 2] == "->", this.input[0 .. 2]);
        
        this = InputContext.fromString("E -> E + T | T;");
        this.parseRule();
        assert(this.allSymbols.length == 3, this.allSymbols.to!string);

        auto parsethis = ParseContext.fromString("E -> E + T | T;");
        assert(parsethis.allSymbols.length == 5, parsethis.allSymbols.to!string);
        
    }
}


unittest {
    import std.conv;
    import std.stdio;
    writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");
    auto ctx = InputContext.fromString(q"{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
        id +> 'a..zA..Z' | id 'a..zA..Z0..9';
    }");
    consumeWS(ctx);
    ctx.parseRule;

    writeln(ctx.allSymbols);
}
