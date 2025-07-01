#include <iostream>
#include <cstring>
#include <iostream>
#include <unistd.h>

const char *__attribute__((noinline)) __begin_pin_roi(const char *s, int *beg, int *end) {
    char *hyphen;
    const char *colon = strrchr(s, ':');
    if (colon == NULL) {
        *beg = 0;
        *end = 0x7fffffff;
        return s + strlen(s);
    }
    return NULL;
}

const char *__attribute__((noinline)) __end_pin_roi(const char *s, int *beg, int *end) {
    char *hyphen;
    const char *colon = strrchr(s, ':');
    if (colon == NULL) {
        *beg = 0;
        *end = 0x7fffffff;
        return s + strlen(s);
    }
    return NULL;
}

#define BEGIN_PIN_ROI __begin_pin_roi(new char[5], new int, new int);
#define END_PIN_ROI   __end_pin_roi(new char[5], new int, new int);

#define N 100000

int main() {

    double a[N];
    double b[N];
    for (int i = 0; i < N; i++) {
        a[i] = i;
        b[i] = 2 * i;
    }
    BEGIN_PIN_ROI
    for (int i = 0; i < N; i++) {
        b[i] -= a[i];
    }
    END_PIN_ROI
    double total = 0;
    for (int i = 0; i < N; i++) {
        total += b[i];
    }
    std::cout << "Total: " << total << std::endl;
    return 0;
}
