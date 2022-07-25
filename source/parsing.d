module parsing;

import templexer;
import context;

import std.sumtype;
import std.range;
import std.meta;



auto ACTION = tableset.tblAction;
auto GOTO   = tableset.tblGoto;
auto prodResult = tableset.prodResult;
auto prodBody = tableset.prodBody;


struct SI {
    uint state;
    uint symbol;
}



auto parse(TokenStream tokenStream) {
    SI[] stack;
    auto a = tokenStream.front(); //the first token in the stream;
    auto s = stack.back();
    MachineLoop: while (1) {
        auto action = ACTION[stack.back().state][a];
        final switch(action.actionType) {
            case (Shift): {
                stack ~= SI(action.value, a);
                tokenStream.popFront;
                a = tokenStream.front();
            } break;
            case (Reduce): {
                auto prodId = action.value;

                stack.popBackExactly(prodBody[prodId].length);
                ushort state = GOTO[stack.back().state][prodResult[prodId]].state;
                stack ~= SI(state, prodResult[prodId]);
            } break;
            case (ErrState): {
                //errorHandle();
                break MachineLoop;
            }
            case (Accept): {
                break MachineLoop;
            }
        }
    }
    return stack;
}
    
    
unittest {
    import std.stdio;
    auto ast = parse(tokenStream("1 + 2 * 3"));
    writeln(ast);
}
/++ TODO
    1) Make a lexer generator.
        - Maybe for now just make a lexer that matches.
    2) Ensure correctness.
++/