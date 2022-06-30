module metaParse.types;

import std.sumtype;
import std.meta : AliasSeq;


struct InputStreamString {
    ulong inputPosition;
    string fullInput;
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
        return fullInput[inputPosition..$][start .. end];
    }
    ref auto opIndex(size_t index) {
        return fullInput[inputPosition..$][index];
    }
    size_t opDollar() {
        return length;
    }
    size_t length() {
        return fullInput.length - inputPosition;
    }

    string toString() const @safe pure nothrow {
        return fullInput[inputPosition..$];
    }
    
    this(string s) {this.fullInput = s;}
}

struct Context {
    GramSymbol[] symbolTable = [];
    Production[] productions = [];

    InputStreamString input = "";

    uint getSymbolIndex(GramSymbol g) {
        if (g in symbolIndexLookup) {
            return symbolIndexLookup[g];
        } else {
            uint index = cast(uint) symbolTable.length;
            symbolTable ~= g;
            symbolIndexLookup[g] = index;
            return index;
        }
    }
    
    GramSymbol getSymbol(GramSymbol g) {
        if (g !in symbolIndexLookup) {
            symbolTable ~= g;
            symbolIndexLookup[g] = cast(uint) symbolTable.length;
        }
        return g;
    }


    static  /// Factory
    Context* fromString(string s) {
        auto ctx = new Context(
            null,null,
            InputStreamString(s),
            null
        );
        return ctx;
    }

    private:
        uint[GramSymbol] symbolIndexLookup; 
}

struct EndOfInput {
}

struct Empty {
}

struct NonTerminal {
    string str;
}

struct Terminal {
    string str;
}

alias SymbolTypes = AliasSeq!(NonTerminal, Terminal, Empty, EndOfInput);

alias GramSymbol = SumType!(SymbolTypes);

/// Symbolic Production
struct Production {
    GramSymbol result;
    GramSymbol[] symbols;
}
