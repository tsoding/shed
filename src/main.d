import core.stdc.string;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.ctype;
import core.stdc.errno;
import luna;

void parseCommand(char[] s, ref Array!(char[]) args) {
    // TODO: string double quotes: echo "Hello, World"
    while (true) {
        s = trimLeft(s);
        if (s.length == 0) break;
        auto arg = chopByDelim(s, ' ');
        args.append(arg);
    }
}

extern(C) int main(int argc, char **argv) {
    Array!(char[]) args;
    char[1024] inputBuffer;
    while (!feof(stdin)) {
        printf("> ");
        // TODO: readline support
        if (!fgets(inputBuffer.ptr, inputBuffer.length, stdin)) break; // stdin is closed
        auto n = strlen(inputBuffer.ptr);
        auto input = trim(inputBuffer[0..n]);
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
    }
    return 0;
}
