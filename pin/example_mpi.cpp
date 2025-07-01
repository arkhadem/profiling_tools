#include <iostream>
#include <cstring>
#include <mpi.h>
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

#define N 10000000000

int main(int argc, char **argv) {

    MPI_Init(&argc, &argv);

    int world_size, my_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

    if (my_rank == 0) {
        pid_t pid = getpid();
        std::cout << "Process ID: " << pid << std::endl;
    }

    double *a = new double[N / world_size];
    double *b = new double[N / world_size];
    for (int i = 0; i < N / world_size; i++) {
        a[i] = i;
        b[i] = 2 * i;
    }
    if (my_rank == 0) {
        std::cout << "Running ROI..." << std::endl;
        BEGIN_PIN_ROI
    }
    for (int i = 0; i < N / world_size; i++) {
        b[i] -= a[i];
    }
    if (my_rank == 0) {
        END_PIN_ROI
    }
    double total = 0;
    for (int i = 0; i < N / world_size; i++) {
        total += b[i];
    }
    std::cout << "Total: " << total << std::endl;
    MPI_Finalize();

    return 0;
}
