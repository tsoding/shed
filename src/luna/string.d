import core.stdc.ctype;
import core.stdc.stdlib;
import core.stdc.string;

Char[] trimLeft(Char)(Char[] s) {
    while (s.length > 0 && isspace(s[0])) {
        s = s[1..$];
    }
    return s;
}

Char[] trimRight(Char)(Char[] s) {
    while (s.length > 0 && isspace(s[$-1])) {
        s = s[0..$-1];
    }
    return s;
}

Char[] trim(Char)(Char[] s) {
    return trimRight(trimLeft(s));
}

Char[] chopByDelim(Char)(ref Char[] s, Char delim) {
    size_t i = 0;
    while (i < s.length && s[i] != delim) i++;
    Char[] result;
    if (i >= s.length) {
        result = s;
        s = s[0..0];
    } else {
        result = s[0..i];
        s = s[i..$];
    }
    return result;
}

char* dupAsCstr(Char)(Char[] s) {
    char* cstr = cast(char*)malloc((s.length + 1)*char.sizeof);
    assert(cstr != null);
    memcpy(cstr, s.ptr, s.length);
    cstr[s.length] = '\0';
    return cstr;
}
