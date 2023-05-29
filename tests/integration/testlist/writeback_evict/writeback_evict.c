#include "writeback_evict.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
#define NUM_CACHELINES 256*6
#define NUM_CACHELINES1 256*2

uint128_t data[NB_CORES*NUM_CACHELINES] __attribute__((section(".cache_share_region")));
uint128_t data1[NB_CORES*NUM_CACHELINES1] __attribute__((section(".cache_share_region")));
uint64_t counters[NB_CORES] __attribute__((section(".nocache_share_region")));

int writeback_evict(int cid, int nc)
{
  // initialize the cachelines
  for (counters[cid] = 0; counters[cid] < NUM_CACHELINES; counters[cid]++) {
    data[cid*NUM_CACHELINES+counters[cid]] = cid*NUM_CACHELINES+counters[cid]+1;
    if (data[cid*NUM_CACHELINES+counters[cid]] != cid*NUM_CACHELINES+counters[cid]+1)
      exit(cid*NUM_CACHELINES+counters[cid]+1);
  }

  // modify the cacheline
  for (counters[cid] = 0; counters[cid] < NUM_CACHELINES; counters[cid]++) {
    data[cid*NUM_CACHELINES+counters[cid]] *= 10;
    if (data[cid*NUM_CACHELINES+counters[cid]] != 10*(cid*NUM_CACHELINES+1+counters[cid]))
      exit(10*(cid*NUM_CACHELINES+counters[cid]+1));
  }

  // fill the cache with new cachelines
  for (counters[cid] = 0; counters[cid] < NUM_CACHELINES1; counters[cid]++) {
    data1[cid*NUM_CACHELINES1+counters[cid]] = ~(cid*NUM_CACHELINES1+counters[cid]+1);
    if (data1[cid*NUM_CACHELINES1+counters[cid]] != ~(cid*NUM_CACHELINES1+counters[cid]+1))
      exit(~(cid*NUM_CACHELINES1+counters[cid]+1));
  }

  return 0;
}
