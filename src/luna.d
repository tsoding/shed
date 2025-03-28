// D library that is closer to Earth
import core.stdc.ctype;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.stdio;
import core.sys.posix.stdlib;
import core.sys.posix.unistd;
import core.sys.posix.sys.wait;

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

inout(char)[] chopByDelim(ref inout(char)[] s, char delim) {
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

int __WTERMSIG(int status )  { return status & 0x7F;                              }
bool WIFEXITED(int status)   { return __WTERMSIG(status) == 0;                    }
int  WEXITSTATUS(int status) { return (status & 0xFF00) >> 8;                     }
bool WIFSIGNALED(int status) { return (cast(byte)((status & 0x7F) + 1) >> 1) > 0; }
int  WTERMSIG(int status)    { return status & 0x7F;                              }

char* dupAsCstr(inout(char)[] s) {
    char* cstr = cast(char*)malloc(s.length + 1);
    assert(cstr != null);
    memcpy(cstr, s.ptr, s.length);
    cstr[s.length] = '\0';
    return cstr;
}

bool waitPid(pid_t proc) {
    if (proc < 0) return false;
    for (;;) {
        int wstatus = 0;
        if (waitpid(proc, &wstatus, 0) < 0) {
            fprintf(stderr, "could not wait on command (pid %d): %s\n", proc, strerror(errno));
            return false;
        }

        if (WIFEXITED(wstatus)) {
            int exit_status = WEXITSTATUS(wstatus);
            if (exit_status != 0) {
                fprintf(stderr, "command exited with exit code %d\n", exit_status);
                return false;
            }

            break;
        }

        if (WIFSIGNALED(wstatus)) {
            fprintf(stderr, "command process was terminated by signal %d\n", WTERMSIG(wstatus));
            return false;
        }
    }
    return true;
}

pid_t cmdRunAsync(inout(char)[][] args) {
    pid_t cpid = fork();

    if (cpid < 0) {
        fprintf(stderr, "ERROR: Could not fork child process: %s\n", strerror(errno));
        return -1;
    }

    if (cpid == 0) {
        // NOTE: This leaks a bit of memory in the child process.
        // But do we actually care? It's a one off leak anyway...
        Array!(char*) argsNull;
        foreach (ref arg; args) argsNull.append(dupAsCstr(arg));
        argsNull.append(null);

        if (execvp(argsNull[0], argsNull.ptr) < 0) {
            fprintf(stderr, "ERROR: Could not exec child process: %s\n", strerror(errno));
            exit(1);
        }
        assert(false, "cmdRunAsync: unreachable");
    }

    return cpid;
}

bool cmdRunSync(inout(char)[][] args)
{
    return waitPid(cmdRunAsync(args));
}
