module helpers;

// mixin template ConstructThis() {
//     import std.traits;
//     this (T...)(T args) const {
//         static foreach (i, s; FieldNameTuple!(typeof(this))[0..args.length]) {
//             mixin("this.",s) = args[i];
//         }
//     }
// }