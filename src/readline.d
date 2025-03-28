extern(C) char *readline(const(char) *prompt);
extern(C) void add_history(const(char) *line);
extern(C) int read_history (const(char) *filename);
extern(C) int write_history (const(char) *filename);
