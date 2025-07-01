#include <string.h>
#include <unistd.h>

const char *__attribute__((noinline)) __begin_pin_roi(const char *s, int *beg,
                                                      int *end) {
  char *hyphen;
  const char *colon = strrchr(s, ':');
  if (colon == NULL) {
    *beg = 0;
    *end = 0x7fffffff;
    return s + strlen(s);
  }
  return NULL;
}

const char *__attribute__((noinline)) __end_pin_roi(const char *s, int *beg,
                                                    int *end) {
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
#define END_PIN_ROI __end_pin_roi(new char[5], new int, new int);