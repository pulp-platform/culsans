#include "read_nocache_noshare_overlap.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

uint64_t data[NB_CORES] __attribute__((section(".nocache_noshare_region")));

int read_nocache_noshare_overlap(int cid, int nc)
{

}
