module metaParse.parsing;

import metaParse.types;

import std.range;
import std.algorithm;
import std.array;

alias Unit = int[0];

// void internSymbols() {

//     Production[] retprods;
//     foreach (Production p; prods) {
//         retprods ~= Production(
//             lookup[cast(GramSymbol) p.result],
//             p.symbols.map!(sym => lookup[sym])().array
//         );
//     }
// }

// private struct Return {
//     Production[] prods;
//     uint[GramSymbol] symbolTable;
// }

void parseRuleTable(Context* ctx) {
    import std.stdio;

    Production[] prods;
    while (!ctx.input.empty()) {
        getWhiteSpace(ctx);
        if (ctx.input.empty())
            break;
        Production[] ruleProds = getProductions(ctx);
        prods ~= ruleProds;
    }

    ctx.productions = prods;
}

Production[] getProductions(Context* ctx) {
    GramSymbol name = ctx.getSymbol(
        GramSymbol(NonTerminal(getIdentifier(ctx)))
    );
    getWhiteSpace(ctx);
    if (ctx.input[0 .. 2] != "->") {
        throw new Error("Missing arrow at:\n" ~ ctx.input.toString);
    }

    ctx.input.popFrontN(2);
    getWhiteSpace(ctx);

    GramSymbol[][] allSymbols;

    Semi: while (1) {
        GramSymbol[] symbols;
        scope (exit)
            allSymbols ~= symbols;
        Bar: while (1) {
            getWhiteSpace(ctx);
            switch (ctx.input[0]) {
                case 'A': .. case 'Z': {
                    symbols ~= ctx.getSymbol(
                        cast(GramSymbol)NonTerminal(getIdentifier(ctx))
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
                        cast(GramSymbol)Terminal(getIdentifier(ctx))
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

string getIdentifier(Context* ctx) {
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

void getWhiteSpace(int Start = 0)(Context* ctx) {
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

alias getTailWhiteSpace = getWhiteSpace!1;

unittest {
    import std.stdio;

    auto ctx = Context.fromString("E -> E + T | T;");
    getWhiteSpace(ctx);
    getIdentifier(ctx);
    getWhiteSpace(ctx);
    assert(ctx.input[0 .. 2] == "->", ctx.input[0 .. 2]);
    ctx.input = cast(InputStreamString)q{
        E -> E + T | T;
        T -> T * F | F;
        F -> ( E ) | id;
    };
}
