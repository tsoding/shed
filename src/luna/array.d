// Dynamic Arrays in D
import core.stdc.stdlib;

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

    void append(Range)(Range items) {
        foreach(item; items) append(item);
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
