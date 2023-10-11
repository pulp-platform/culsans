#include "write_cache_noshare.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
uint128_t data[NB_CORES] __attribute__((section(".cache_noshare_region")));

int write_cache_noshare(int cid, int nc)
{
  // initialize the cacheline
  data[cid] = cid+1;
  if (data[cid] != cid+1)
    exit(cid+1);

  // modify the cacheline
  data[cid] *= 10;
  if (data[cid] != 10*(cid+1))
    exit(10*(cid+1));

  // writeback
  asm volatile("fence.i");

  return 0;
}
