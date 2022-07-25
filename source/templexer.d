module templexer;

import collections.treemap;

import std.range;


struct Token {
    ushort id;
    alias id this;
    string capture;
}
Token token(ushort id, string capture = "") {
    //// if id is an id that cant have a capture, complain
    return Token(id, capture);
}



struct TokenStream {
    string input;
    
    Token _front;

    Token front() {return _front;}

    void popFront() {
        import metaparse.itemsets;
        enum terminals = ["+", "*", "(", ")", "id"];
        enum terminalMap = (){
            TreeMap!(dchar, string[]) tree;
            foreach (t; terminals) {
                auto arr = tree[t[0]];
                arr ~= t;
                tree[t[0]] = arr;
            }
            string[][] ret;
            foreach (k, v; tree) {
                ret ~= v;
            }
            return ret;
        }();
        
        Switch: switch (input.front) {
            static foreach(i, TOKS; terminalMap) {
                case TOKS[0].front: {
                    auto toks = TOKS;
                    foreach (t; toks) {
                        if (input.matchExact(t)) {
                            input.popFrontN(t.length);
                            input.consumeWS;
                            _front = token(i);
                            break Switch;
                        }
                    }
                    goto default;
                }
            }
            default: throw new Error("Bad Parse");
        }
    }

    bool empty() {
        return input.length == 0;
    }
}

TokenStream tokenStream(string input) {
    TokenStream thi;
    thi.input = input;
    thi.popFront;
    return thi;
}

void consumeWS(string input) {
    int len = 0;
    Loop: foreach (ch; input[0 .. $]) {
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
    input.popFrontN(len);
}

bool matchExact(string input, string predicate) {
    foreach(ch; 0..predicate.length) {
        if (input[ch] != predicate[ch]) {return false;}
    }
    return true;
}