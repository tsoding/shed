#!/usr/bin/env rdmd
import std.process;
import std.stdio;

bool cmd(scope const(char[])[] args) {
    writeln("CMD: ", args);
    return wait(spawnProcess(args)) == 0;
}

int main() {
    if (!cmd(["dmd", "-betterC", "-of=shed", "-I=./src/", "-i", "./src/main.d"])) return 1;
    return 0;
}
