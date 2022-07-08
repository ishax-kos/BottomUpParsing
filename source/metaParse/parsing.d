module metaparse.parsing;

import metaparse.types;

import std.range;
import std.algorithm;
import std.array;
import std.sumtype;


struct InputStreamString {
    ulong inputPosition;
    char[] fullInput;
    dchar front() {
        return fullInput[inputPosition];
    }

    void popFrontN(ulong num) {
        inputPosition += num;
    }

    void popFront() {
        popFrontN(1);
    }

    bool empty() {
        return inputPosition == fullInput.length;
    }

    InputStreamString save() {
        return this;
    }

    ref auto opSlice(size_t start, size_t end) {
        return fullInput[inputPosition .. $][start .. end];
    }

    ref auto opIndex(size_t index) {
        return fullInput[inputPosition .. $][index];
    }

    size_t opDollar() {
        return length;
    }

    size_t length() {
        return fullInput.length - inputPosition;
    }

    string toString() const @safe pure nothrow {
        return fullInput[inputPosition .. $].idup;
    }

    this(string s) {
        this.fullInput = s.dup;
    }
}


private class InternalContext {
    InputStreamString input = "";
    GramSymbol[] allSymbols;

    GramSymbol getSymbol(GramSymbol g) {
        if (allSymbols.canFind(g)) {
        } else {
            allSymbols ~= g;
        }
        return g;
    }
    static  /// Factory
    InternalContext fromString(string s) {
        auto ctx = new InternalContext();
        ctx.input = InputStreamString(s);
        return ctx;
    }
}

alias PContext = immutable ParseContext;
public class ParseContext {
    IProduction[] productions = [];
    GramSymbol[] allSymbols;

    static 
    PContext fromString(string s) {
        auto baseCtx = InternalContext.fromString(s);
        auto ctx = new ParseContext();
        ctx.allSymbols = baseCtx.allSymbols;
        ctx.productions = cast(immutable)(parseProductions(baseCtx).dup);
        return cast(immutable) ctx;
    }
}


private:

Production[] parseProductions(InternalContext ctx) {
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


Production augmentProduction(ref Production startProd) {
    NonTerminal startSym = startProd.result;
    NonTerminal augSym = NonTerminal(startSym.str ~ "'");
    return Production(augSym, [GramSymbol(startSym)]);
}


Production[] parseRule(InternalContext ctx) {
    NonTerminal name = ctx.getSymbol(
        GramSymbol(NonTerminal(parseIdentifier(ctx)))
    ).match!(
        (NonTerminal nt) => nt, 
        _ => throw new Error("")
    );
    consumeWS(ctx);
    if (ctx.input[0 .. 2] != "->") {
        throw new Error("Missing arrow at:\n" ~ ctx.input.toString);
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
                        cast(GramSymbol)NonTerminal(parseIdentifier(ctx))
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
                        cast(GramSymbol)Terminal(parseIdentifier(ctx))
                    );
                    break;
                }
                default: {
                    symbols ~= ctx.getSymbol(
                        cast(GramSymbol)Terminal([ctx.input[0]])
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

string parseIdentifier(InternalContext ctx) {
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

void consumeWS(int Start = 0)(InternalContext ctx) {
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
    // import std.stdio;

    auto ctx = InternalContext.fromString("E -> E + T | T;");
    consumeWS(ctx);
    parseIdentifier(ctx);
    consumeWS(ctx);
    assert(ctx.input[0 .. 2] == "->", ctx.input[0 .. 2]);
    ctx.input = cast(InputStreamString)q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    };
}
