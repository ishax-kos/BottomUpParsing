module nodetypes;

import context;
import templexer;

import std.format;
import std.algorithm;
import std.sumtype;
import std.array;
import std.range;
import std.typecons;
import std.conv;
import std.meta;


mixin((){
    import metaparse.types;
    import std.format;
    string ret;
    foreach (nt; tableset.nonterminals.byKey) {
        ret ~= "struct %s {}\n".format(nt.typeString);
    }
    return ret;
}());


alias Node = SumType!(Token, NtTypes);

alias NtTypes = mixin(
    "AliasSeq!(",
    tableset
        .nonterminals
        .byKey
        .typeString
        .join(", "),
    ")"
);

alias GenT = Node function(Node[]);
GenT[] ntGen = (){
    GenT[] ret;
    static foreach (prodList; tableset.prodLookup.byValue[1..$]) {
        static foreach (prod; prodList) {
        ret ~= mixin("(Node[] slice){return Node(", prod.result.typeString, "());}" );
        }
    }
    return ret;
}();

import metaparse.types;
string typeString(Nonterminal nt) {
    return format!"_nt_%s"(nt.str);
}

auto typeString(T)(T list) {
    return list.map!(nt=>typeString(nt));
}

// alias GenT = void function(Node[]);
// GenT[] ntGen = 
//     staticMap!((Node[] slice){return Node()}, NtTypes);
