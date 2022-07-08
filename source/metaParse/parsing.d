module metaparse.parsing;

import metaparse.types;

import std.range;
import std.algorithm;
import std.array;
import std.sumtype;


private class InputContext {
    string input = "";
    GramSymbol[] allSymbols;

    GramSymbol getSymbol(GramSymbol g) pure {
        if (allSymbols.canFind(g)) {
        } else {
            allSymbols ~= g;
        }
        return g;
    }
    static  /// Factory
    InputContext fromString(string s) pure {
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
    PContext fromString(string s) pure {
        auto baseCtx = InputContext.fromString(s);
        auto ctx = new ParseContext();
        ctx.productions = baseCtx.parseProductions().dup;
        ctx.allSymbols = baseCtx.allSymbols.dup;
        import std.stdio;
        return cast(immutable) ctx;
    }
}


private:

Production[] parseProductions(InputContext ctx) pure {
    ctx.getSymbol(GramSymbol.eoi);
    ctx.getSymbol(GramSymbol.empty);

    Production[] prods;
    while (!ctx.input.empty()) {
        consumeWS(ctx);
        if (ctx.input.empty())
            break;
        prods ~= parseRule(ctx);
    }
    Production aug = augmentProduction(prods[0]);
    // auto newCtx = cast(ParseContext) ctx;
    return aug~prods;
}


Production augmentProduction(ref Production startProd) pure {
    NonTerminal startSym = startProd.result;
    NonTerminal augSym = NonTerminal(startSym.str ~ "'");
    GramSymbol g;
    g.sum = GramSymbol.Sum(startSym);
    return new Production(augSym, [g]);
}


Production[] parseRule(InputContext ctx) pure { 
    NonTerminal name = NonTerminal(parseIdentifier(ctx));
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
        prods ~= new Production(name, list);
    }
    return prods;
}

string parseIdentifier(InputContext ctx) pure {
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

void consumeWS(int Start = 0)(InputContext ctx) pure {
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
