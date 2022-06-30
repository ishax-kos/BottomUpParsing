module parsing_h;

import std.sumtype;

struct Symbol {uint index;}

alias Unit = int[0];
struct Shift {uint amount;}
struct Reduce {uint prod;}
struct Accept {}
struct ErrorState {}
alias Action = SumType!(Shift, Reduce, Accept, ErrorState);


struct Context {
    string input;

    static Context* newContext(string input_) {
        auto _this = new Context();
        _this.input = input_;
        return _this;
    }
}
