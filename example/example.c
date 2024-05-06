#include <stdlib.h>

/* returns !0 on error */
int generate_error();

void log_error();

void do_something(int);
void do_something2(int*);

/* return 0 on error */
int func(void) {
    if (generate_error()) {
        log_error();
        return 0;
    }
    int *x = malloc(sizeof(*x));
    if (!x) {
        log_error();
        return 0;
    }
    if ((*x = generate_error())) {
        log_error();
        free(x);
        return 0;
    }
    do_something2(x);
    return *x;
}
