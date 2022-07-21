module metaparse.tabletypes;


enum {
    ErrState,
    Shift,
    Reduce,
    Accept,
    ACTION_TYPE_MAX
}

struct GoTo {
    this (T) (T value) {
        state = cast(typeof(state)) value;
    }

    private short state = errState__;
    private enum errState__ = cast(typeof(state)) -1;
    string toString() const {
        import std.conv;
        if (state == errState__) return "";
        else return state.to!string;
    }
}

struct Action {
    ushort actionType;
    ushort value;

    this(T1,T2)(T1 at, T2 val) {
        assert(at == Shift || at == Reduce);
        actionType = cast(ushort) at;
        assert(val < ushort.max);
        value = cast(ushort) val;
    }
    this(T)(T at) {
        assert(at == ErrState || at == Accept);
        actionType = cast(ushort) at;
    }

    string toString() const {
        import std.conv;
        final switch(actionType) {
            case ErrState: return "";
            case Shift: return "s" ~ value.to!string;
            case Reduce: return "r" ~ value.to!string;
            case Accept: return "Ac";
        }
    }
}

