import array;
import string;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.unistd;
import core.sys.posix.sys.wait;

int __WTERMSIG(int status)   { return status & 0x7F;                              }
bool WIFEXITED(int status)   { return __WTERMSIG(status) == 0;                    }
int  WEXITSTATUS(int status) { return (status & 0xFF00) >> 8;                     }
bool WIFSIGNALED(int status) { return (cast(byte)((status & 0x7F) + 1) >> 1) > 0; }
int  WTERMSIG(int status)    { return status & 0x7F;                              }

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
