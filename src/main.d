import core.stdc.string;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.ctype;
import core.stdc.errno;
import luna;
import readline;

void parseCommand(char[] s, ref Array!(char[]) args) {
    // TODO: string double quotes: echo "Hello, World"
    while (true) {
        s = trimLeft(s);
        if (s.length == 0) break;
        auto arg = chopByDelim(s, ' ');
        args.append(arg);
    }
}

const string HISTORY_NAME = ".shed_history";
Array!char historyPath;

extern(C) void cleanup()
{
    write_history(historyPath.ptr);
}

extern(C) int main(int argc, char **argv) {
    Array!(char[]) args;

    char *home = getenv("HOME");
    assert(home != null);

    historyPath.append(home[0..strlen(home)]);
    historyPath.append("/");
    historyPath.append(HISTORY_NAME);
    historyPath.append(0);

    read_history(historyPath.ptr);
    atexit(&cleanup);

    while (true) {
        const string prompt = "⛺ ";
        auto line = readline.readline(prompt.ptr);
        if (line == null) break; // Ctrl-D
        scope(exit) free(line);

        auto n = strlen(line);
        auto input = line[0..n];

        args.length = 0;
        parseCommand(input, args);
        if (args.length == 0) continue; // empty command

        switch (args[0]) {
        case "exit":
            // TODO: support exit code argument
            exit(0);
        default:
            cmdRunSync(args.slice());
        }

        add_history(line);
    }
    return 0;
}
