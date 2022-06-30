module testTwo;

import parsing_h;

import std.sumtype;
import std.range;

immutable int[][] ACTION = void;
immutable int[][] GOTO = void;

struct SI {
    uint state;
    uint symbol;
}


version(unittest) {
    struct Production {
        size_t length = 1;
    }
    Production[] productions;
}
else {

void parse(uint[] tokenStream) {
    SI[] stack;
    auto a = tokenStream.front(); //the first token in the stream;
    auto s = stack.back();
    while (
        ACTION[stack.back().state][a].match!(
            (Shift sh) {
                stack ~= SI(sh.amount, a);
                tokenStream.popFront;
                a = tokenStream.front();
                return true;
            },
            (Reduce red) {
                Production prod = productions[red.prod];
                stack.popBackExactly(prod.length);
                stack ~= SI(GOTO[stack.back().state][red.prod], 600000);
                return true;
            },
            (Accept _) => false,
                (ErrorState _) {
                //errorHandle();
                return true;
            },
        )
    ) {}
}
    
}
