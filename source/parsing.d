module testTwo;

import parsing_h__;
import metaparse.tablegen;

import std.sumtype;
import std.range;
import std.meta;

//+
auto tableset = buildTables(q{
    E -> E + T | T;
    T -> T * F | F;
    F -> ( E ) | id;
});

alias ACTION = Alias!(tableset.tblAction);
alias GOTO = Alias!(tableset.tblGoto);
// +/

// struct SI {
//     uint state;
//     uint symbol;
// }


// version(unittest) {
//     struct Production {
//         size_t length = 1;
//     }
// }
// else {

// void parse(Context* ctx, uint[] tokenStream) {
//     SI[] stack;
//     auto a = tokenStream.front(); //the first token in the stream;
//     auto s = stack.back();
//     while (
//         ACTION[stack.back().state][a].match!(
//             (Shift sh) {
//                 stack ~= SI(sh.amount, a);
//                 tokenStream.popFront;
//                 a = tokenStream.front();
//                 return true;
//             },
//             (Reduce red) {
//                 Production prod = productions[red.prod];

//                 stack.popBackExactly(prod.length);
//                 stack ~= SI(GOTO[stack.back().state][red.prod], prod.result);
//                 return true;
//             },
//             (Accept _) => false,
//                 (ErrorState _) {
//                 //errorHandle();
//                 return true;
//             },
//         )
//     ) {}
// }
    
// }
