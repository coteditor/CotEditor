#include <stdio.h>
#include <stdint.h>

#define MAX_COUNT 128
#define SQUARE(x) ((x) * (x))

typedef struct User {
    uint32_t id;
    const char *name;
} User;

typedef enum LogLevel {
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
} LogLevel;

union Value {
    int i;
    double d;
};

static const char *PREFIX = "user";

static int add(int a, int b) {
    return a + b;
}

static void print_user(const User *user) {
    if (user == NULL) {
        puts("(null)");
        return;
    }

    printf("%s:%u:%s\n", PREFIX, user->id, user->name);
}

int main(void) {
    User user = {.id = 42, .name = "alice"};
    int score = SQUARE(add(3, 4));

    print_user(&user);

    for (int i = 0; i < 3; i++) {
        printf("score[%d]=%d\n", i, score + i);
    }

    return 0;
}
