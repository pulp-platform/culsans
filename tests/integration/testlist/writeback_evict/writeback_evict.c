#include "writeback_evict.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
#define NUM_CACHELINES 256*8
#define NUM_CORES 4
uint128_t data[NUM_CORES*NUM_CACHELINES] __attribute__((section(".cache_share_region")));
uint128_t data1[NUM_CORES*NUM_CACHELINES] __attribute__((section(".cache_share_region")));

int writeback_evict(int cid, int nc)
{
  // initialize the cachelines
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data[cid*NUM_CACHELINES+i] = cid*NUM_CACHELINES+i+1;
    if (data[cid*NUM_CACHELINES+i] != cid*NUM_CACHELINES+i+1)
      exit(cid*NUM_CACHELINES+i+1);
  }

  // modify the cacheline
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data[cid*NUM_CACHELINES+i] *= 10;
    if (data[cid*NUM_CACHELINES+i] != 10*(cid*NUM_CACHELINES+i+1))
      exit(10*(cid*NUM_CACHELINES+i+1));
  }

  // fill the cache with new cachelines
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data1[cid*NUM_CACHELINES+i] = ~(cid*NUM_CACHELINES+i+1);
    if (data1[cid*NUM_CACHELINES+i] != ~(cid*NUM_CACHELINES+i+1))
      exit(~(cid*NUM_CACHELINES+i+1));
  }

  return 0;
}
