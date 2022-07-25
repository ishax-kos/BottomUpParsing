module context;

import metaparse.types;
import metaparse.tablegen;
public import metaparse.tabletypes;

immutable tableset = cast(immutable) buildTables(q{
    E -> E + T | T;
    T -> T * F | F;
    F -> ( E ) | id;
});

struct Symbol(string str) {};
struct Value(string name) {string str;}