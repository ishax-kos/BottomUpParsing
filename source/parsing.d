module scanning;

import templexer;
import context;
import nodetypes;

import std.sumtype;
import std.range;
import std.meta;

import std.stdio;


auto ACTION = tableset.tblAction;
auto GOTO   = tableset.tblGoto;
auto prodResult = tableset.prodResult;
auto prodBody = tableset.prodBody;


struct Stack {

    void push(int state, Node node) {
        this.states ~= state;
        this.nodes ~= node;
    }
    void pop() {
        states.length -= 1;
        nodes.length -= 1;
    }

    int topState() {
        return states[$-1];
    }
    Node topNode() {
        return nodes[$-1];
    }
    Node[] topNode(size_t count) {
        return nodes[$-count..$];
    }

    void popBackExactly(size_t number) {foreach(_;0..number) {pop();}}
    // back()

    private:
    int[] states;
    Node[] nodes;
}
auto stack() {
    return Stack([0], []);
}


auto parse(TokenStream tokenStream) {
    auto stack = stack();
    // auto a = tokenStream.front(); //the first token in the stream;
    // auto s = stack.back();
    MachineLoop: while (1) {
        writeln(stack);
        auto action = ACTION[stack.topState][tokenStream.front()];
        final switch(action.actionType) {
            case (Shift): {
                writeln("Shift");
                ushort state = action.value;
                stack.push(state, Node(tokenStream.front()));
                tokenStream.popFront;
                // a = tokenStream.front();
                
            } break;
            case (Reduce): {
                writeln("Reduce");
                auto prodId = action.value;

                auto stackSlice = stack.topNode(prodBody[prodId].length);
                stack.popBackExactly(prodBody[prodId].length);
                ushort state = GOTO[stack.topState][prodResult[prodId]].state;
                stack.push(state, ntGen[prodId](stackSlice));
                
            } break;
            case (ErrState): {
                //errorHandle();
                writeln("Error", stack.topState,":", tokenStream.front());
                break MachineLoop;
            }
            case (Accept): {
                writeln("Accept");
                break MachineLoop;
            }
        }
    }
    return stack;
}

// match(ushort index)() {
//     AliasSeq[index]
// }

unittest {
    import std.stdio;
    writeln(__FUNCTION__);
    auto ast = parse(tokenStream("id * id + id"));
    // writeln(ast);
}
/++ TODO
    1) Make a lexer generator.
        check! - Maybe for now just make a lexer that matches.
    2) Ensure correctness.
++/