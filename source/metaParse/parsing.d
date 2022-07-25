module metaparse.parsing;

import metaparse.types;

import std.range;
import std.algorithm;
import std.array;
import std.sumtype;

import collections.treemap;
alias TreeSet(T) = TreeMap!(T, void);

private class InputContext {
    string input = "";
    GramSymbol[] allSymbols;

    GramSymbol getSymbol(GramSymbol g) {
        if (allSymbols.canFind(g)) {
        } else {
            allSymbols ~= g;
        }
        return g;
    }
    static  /// Factory
    InputContext fromString(string s) {
        auto ctx = new InputContext();
        ctx.input = s;
        return ctx;
    }
}

alias PContext = immutable ParseContext;
public class ParseContext {
    Production[] productions = [];
    GramSymbol[] allSymbols;

    static 
    PContext fromString(string s) {
        auto baseCtx = InputContext.fromString(s);
        auto ctx = new ParseContext();
        ctx.productions = baseCtx.parseProductions().dup;
        // import metaparse.itemsets: genSymbolTable;
        ctx.allSymbols = baseCtx.allSymbols.dup;
        import std.stdio;
        return cast(immutable) ctx;
    }
}


private:

Production[] parseProductions(InputContext ctx) {
    Production[] prods = [Production()]; /// The first spot is reserved
    while (!ctx.input.empty()) {
        consumeWS(ctx);
        if (ctx.input.empty())
            break;
        prods ~= parseRule(ctx);
    }
    ctx.getSymbol(GramSymbol.eoi);
    ctx.getSymbol(GramSymbol.empty);
    prods[0] = augmentProduction(prods[1]);
    return prods;
}


Production augmentProduction(ref Production startProd) {
    Nonterminal startSym = startProd.result;
    Nonterminal augSym = Nonterminal("'");
    GramSymbol g;
    g.sum = GramSymbol.Sum(startSym);
    return Production(augSym, [g]);
}


Production[] parseRule(InputContext ctx) { 
    Nonterminal name = Nonterminal(parseIdentifier(ctx));
    GramSymbol g; g.sum = GramSymbol.Sum(name);
    ctx.getSymbol(g);
    consumeWS(ctx);
    if (ctx.input[0 .. 2] != "->") {
        throw new Error("Missing arrow at:\n" ~ ctx.input);
    }

    ctx.input.popFrontN(2);
    consumeWS(ctx);

    GramSymbol[][] allSymbols;

    Semi: while (1) {
        GramSymbol[] symbols;
        scope (exit)
            allSymbols ~= symbols;
        Bar: while (1) {
            consumeWS(ctx);
            switch (ctx.input[0]) {
                case 'A': .. case 'Z': {
                    symbols ~= ctx.getSymbol(
                        GramSymbol.nonTerminal(parseIdentifier(ctx))
                    );
                    break;
                }
                case ' ', '\n', '\r', '\t': {
                    getTailWhiteSpace(ctx);
                    break;
                }
                case ';': {
                    ctx.input.popFront;
                    break Semi;
                }
                case '|': {
                    ctx.input.popFront;
                    break Bar;
                }
                case 'a': .. case 'z': {
                    symbols ~= ctx.getSymbol(
                        GramSymbol.terminal(parseIdentifier(ctx))
                    );
                    break;
                }
                default: {
                    symbols ~= ctx.getSymbol(
                        GramSymbol.terminal([ctx.input[0]])
                    );
                    ctx.input.popFront;
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

string parseIdentifier(InputContext ctx) {
    int len = 1;
    Loop: foreach (ch; ctx.input[1 .. $]) {
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
    auto ret = ctx.input[0 .. len].idup;
    ctx.input.popFrontN(len);
    return ret;
}

void consumeWS(int Start = 0)(InputContext ctx) {
    int len = Start;
    Loop: foreach (ch; ctx.input[Start .. $]) {
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
    ctx.input.popFrontN(len);
}

alias getTailWhiteSpace = consumeWS!1;

unittest {
    import std.conv;
    // import std.stdio;
    // writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");

    auto ctx = InputContext.fromString("E -> E + T | T;");
    consumeWS(ctx);
    parseIdentifier(ctx);
    consumeWS(ctx);
    assert(ctx.input[0 .. 2] == "->", ctx.input[0 .. 2]);
    
    ctx = InputContext.fromString("E -> E + T | T;");
    ctx.parseRule();
    assert(ctx.allSymbols.length == 3, ctx.allSymbols.to!string);

    auto parseCtx = ParseContext.fromString("E -> E + T | T;");
    assert(parseCtx.allSymbols.length == 5, parseCtx.allSymbols.to!string);
    
}
// unittest {
//     import std.conv;
//     import std.stdio;
//     writeln(" ~~ ~~~~ ~~ ",__FUNCTION__," ~~ ~~~~ ~~ ");
//     auto ctx = InputContext.fromString(q{
//         E -> E + T | T;
//         T -> T * F | F;
//         F -> ( E ) | id;
//     });
//     consumeWS(ctx);
//     ctx.parseRule;

//     writeln(ctx.allSymbols);
// }
