module templexer;

import context;
import collections;

import std.range;
import std.format;
import std.algorithm;
import std.conv;


struct Token {
    ushort id;
    alias id this;
    string capture;

    string toString() const {
        string s = tableset.terminals.byKey[id].toString;
        
        if (capture.length > 0) {
            return s ~ "(" ~ capture ~ ")";
        }
        else {
            return s;
        }
    }
}
Token token(ushort id, string capture = "") {
    //// if id is an id that cant have a capture, complain
    return Token(id, capture);
}



struct TokenStream {
    string input;
    int flen;
    // debug size_t begin;
    
    Token _front;

    Token front() {return _front;}

    void popFront() {
        input = input[flen..$];
        input.consumeWS;
        if (!input.empty()) {scan();}
        else {
            _front = Token(cast(ushort) 
                (tableset.terminals.length-1), ""
            );
        }
    }

    bool empty() {
        return input.length == 0;
    }

    void scan() {
        import metaparse.itemsets;
        // enum terminals = ["+", "*", "(", ")", "id"];
        enum terminalMap = (){
            ArrayMap!(dchar, string[]) tree;
            foreach (t; tableset.terminals.byKey.map!(to!string)) {
                if (t[0] in tree) {tree[t[0]] ~= t;}
                else {tree[t[0]] = [t];}
            }
            string[][] ret;
            foreach (k, v; tree) {
                ret ~= v;
            }
            return ret;
        }();
        // terminalMap();
        // if (input.empty) {input = cast(immutable (char[])) [-1, 0]; return;}

        //+
        Switch:
        switch (input.front) {
            static foreach(i, TOKS; terminalMap) {
                case TOKS[0].front: {
                    auto toks = TOKS;
                    foreach (t; toks) {
                        if (input.matchExact(t)) {
                            _front = token(i);
                            flen = cast(int) t.length;
                            break Switch;
                        }
                    }
                    goto default;
                }
            }
            default: throw new Exception("Bad Parse: '%s'".format(input.front));
        }// +/
    }
}

TokenStream tokenStream(string input) {
    TokenStream thi;
    thi.input = input;
    thi.scan;
    return thi;
}

void consumeWS(ref string input) {
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

unittest {
    import std.stdio;
    writeln(__FUNCTION__);
    auto stream = tokenStream("id + id * id");
    writeln(stream);
}