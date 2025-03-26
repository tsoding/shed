import core.stdc.string;
import core.stdc.ctype;
import core.stdc.errno;

import core.sys.posix.stdio;
import core.sys.posix.stdlib;
import core.sys.posix.unistd;
import core.sys.posix.sys.wait;
import luna;

extern (D) int __WTERMSIG( int status ) { return status & 0x7F; }
extern (D) bool WIFEXITED( int status ) { return __WTERMSIG( status ) == 0;  }
extern (D) int  WEXITSTATUS( int status )  { return ( status & 0xFF00 ) >> 8;   }
extern (D) bool WIFSIGNALED( int status )
{
    return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
}
extern (D) int  WTERMSIG( int status )     { return status & 0x7F;              }

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
            fprintf(stderr, "could not wait on command (pid %d): %s", proc, strerror(errno));
            return false;
        }

        if (WIFEXITED(wstatus)) {
            int exit_status = WEXITSTATUS(wstatus);
            if (exit_status != 0) {
                fprintf(stderr, "command exited with exit code %d", exit_status);
                return false;
            }

            break;
        }

        if (WIFSIGNALED(wstatus)) {
            fprintf(stderr, "command process was terminated by signal %d", WTERMSIG(wstatus));
            return false;
        }
    }
    return true;
}

pid_t cmdRunAsync(inout(char)[][] args) {
    pid_t cpid = fork();

    if (cpid < 0) {
        fprintf(stderr, "ERROR: Could not fork child process: %s", strerror(errno));
        return -1;
    }

    if (cpid == 0) {
        // NOTE: This leaks a bit of memory in the child process.
        // But do we actually care? It's a one off leak anyway...
        Array!(char*) argsNull;
        foreach (ref arg; args) argsNull.append(dupAsCstr(arg));
        argsNull.append(null);

        if (execvp(argsNull[0], argsNull.ptr) < 0) {
            fprintf(stderr, "ERROR: Could not exec child process: %s", strerror(errno));
            exit(1);
        }
        assert(false, "cmdRunAsync: unreachable");
    }

    return cpid;
}

extern(C) int main(int argc, char **argv) {
    Array!(char[]) args;
    char[1024] promptBuffer;
    bool quit = false;
    while (!quit && !feof(stdin)) {
        printf("> ");
        if (fgets(promptBuffer.ptr, promptBuffer.length, stdin)) {
            auto n = strlen(promptBuffer.ptr);
            auto prompt = trim(promptBuffer[0..n]);
            switch (prompt) {
            case "exit":
                quit = true;
                break;
            default:
                args.length = 0;
                auto s = prompt;
                s = trimLeft(s);
                while (s.length > 0) {
                    auto arg = trimLeft(chopBy(s, ' '));
                    args.append(arg);
                    s = trimLeft(s);
                }
                waitPid(cmdRunAsync(args.slice()));
            }
        }
    }
    return 0;
}
