module collections;

template ArrayMap(K, V) {
    struct ArrayMap {
        import core.exception; import std.conv;
        V opIndex(K key) {
            foreach (i, ref k; klist) {
                if (k == key) {return vlist[i];}
            }
            throw new RangeError("Could not find key: '" ~ key.to!string ~ "'");
        }

        void opIndexAssign(V value, K key) {
            opIndexAssign!(V, K)(value, key);
        }
        void opIndexAssign(VV, KK)(VV nvalue, KK nkey) {
            foreach (i; 0..length) {
                if (klist[i] == nkey) {vlist[i] = nvalue; return;}
            }
            vlist ~= nvalue;
            klist ~= nkey;
        }

        auto opIndexOpAssign(string op, VV, KK)(VV value, KK index) {
            return this[index] = mixin(`this[index] `,op,` value`);
        }


        int opApply(scope int delegate(K, ref V) dg) {
            int result = 0;
        
            foreach (i; 0..length) {
                result = dg(klist[i], vlist[i]);
                if (result) {break;}
            }
        
            return result;
        }
        bool opBinaryRight(string op)(const K checkkey) const if (op == "in") {
            foreach (key; klist) {
                if (key == checkkey) {return true;}
            }
            return false;
        }
        // bool opBinary(string op)(const K key) const if (op == "!in") {
        //     return !opBinary!"in"(key);
        // }

        size_t length() const {return klist.length;}

        auto byKey() const {return klist;}
        auto byValue() const {return vlist;}


        private K[] klist;
        private V[] vlist;
    }
    // private struct Item {
    //     K key;
    //     alias key this;
    //     V val;
    // }
}