module main;

import tablegen;
import collections;


void main() {
    immutable tableset = cast(immutable) buildTables(q{
        E -> E "+" T | T;
        T -> T "*" F | F;
        F -> "(" E ")" | "id";
    });
    // File file_action = File("action.table", "wb");
    // File file_goto = File("action.table", "wb");
    // File file_production_result = File("production_result.table", "wb");
    // File file_production_body = File("production_body.table", "wb");

    // file_action.rawWrite

    auto ACTION = tableset.tblAction;
    auto GOTO   = tableset.tblGoto;
    auto prodResult = tableset.prodResult;
    auto prodBody = tableset.prodBody;



    Unit[string] string_table;
    string_table.add();
}



void add(Unit[string] table, string input) {
    table.require(input, []);
}