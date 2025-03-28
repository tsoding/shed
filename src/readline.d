extern(C) char *readline(const(char) *prompt);

struct HISTORY_STATE {
    void *entries;  //HIST_ENTRY **entries;        /* Pointer to the entries themselves. */
    int offset;            /* The location pointer within this array. */
    int length;            /* Number of elements within this array. */
    int size;            /* Number of slots allocated to this array. */
    int flags;
}

extern(C) HISTORY_STATE *history_get_history_state();
extern(C) void add_history(const(char) *line);
extern(C) int read_history (const(char) *filename);
extern(C) int write_history (const(char) *filename);
