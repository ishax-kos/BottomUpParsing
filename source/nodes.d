module nodes;

import context;

// mixin((){
//     import metaparse.types;
//     import std.format;
//     auto prodLookup = tableset.prodLookup;
//     string ret;
//     foreach (k, prods; prodLookup) {
//         ret ~= "struct %s {\n".format(k.str);
//         string bod;
//         scope(exit) ret ~= "}\n";
//         foreach(prod; prods) {
//             ret ~= "    this (
                
//             ) {\n".format(k.str);
//             foreach(sym; prod) {
//             scope(exit) ret ~= "}\n";
//         }
//     }
// }());