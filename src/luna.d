// D library that is closer to Earth
import core.stdc.ctype;
import core.stdc.stdlib;

inout(char)[] trimLeft(inout(char)[] s) {
    while (s.length > 0 && isspace(s[0])) {
        s = s[1..$];
    }
    return s;
}

inout(char)[] trimRight(inout(char)[] s) {
    while (s.length > 0 && isspace(s[$-1])) {
        s = s[0..$-1];
    }
    return s;
}

inout(char)[] trim(inout(char)[] s) {
    return trimRight(trimLeft(s));
}

inout(char)[] chopBy(ref inout(char)[] s, char delim) {
    size_t i = 0;
    while (i < s.length && s[i] != delim) i++;
    inout(char)[] result;
    if (i >= s.length) {
        result = s;
        s = s[0..0];
    } else {
        result = s[0..i];
        s = s[i..$];
    }
    return result;
}

struct Array(T, ulong INIT_CAPACITY = 256) {
    T* ptr;
    ulong length;
    ulong capacity;

    void append(T item) {
        if (length >= capacity) {
            if (capacity == 0) capacity = INIT_CAPACITY;
            else capacity *= 2;
            ptr = cast(T*)realloc(ptr, T.sizeof*capacity);
        }
        ptr[length++] = item;
    }

    T opIndex(size_t i) {
        assert(i < length);
        return ptr[i];
    }

    T opIndexAssign(T value, size_t i) {
        assert(i < length);
        ptr[i] = value;
        return value;
    }

    void opIndexOpAssign(string op)(T value, size_t i) {
        assert(i < length);
        mixin("ptr[i] "~op~"= value;");
    }

    int opApply(scope int delegate(size_t i, ref T) dg) {
        for (size_t i = 0; i < length; ++i) {
            int result = dg(i, ptr[i]);
            if (result) return result;
        }
        return 0;
    }

    int opApply(scope int delegate(ref T) dg) {
        for (size_t i = 0; i < length; ++i) {
            int result = dg(ptr[i]);
            if (result) return result;
        }
        return 0;
    }

    T[] slice() {
        return ptr[0..length];
    }
}
