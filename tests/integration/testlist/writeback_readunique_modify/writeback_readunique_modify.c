#include "writeback_readunique_modify.h"
#include <stdint.h>

extern void exit(int);

#define uint128_t __uint128_t
#define NUM_CACHELINES 256*8
#define NUM_CORES 4
uint128_t data0[NUM_CACHELINES] __attribute__((section(".cache_share_region")));
uint128_t data1[NUM_CORES*NUM_CACHELINES] __attribute__((section(".cache_share_region")));

int writeback_readunique_modify(int cid, int nc)
{
  // core 0 initializes the cachelines
  if (cid == 0) {
    for (int i = 0; i < NUM_CACHELINES; i++) {
      data0[i] = i+1;
      if (data0[i] != i+1)
        exit(i+1);
    }
  }
  else {
    // read the shared data
    for (int i = 0; i < NUM_CACHELINES; i++) {
      if (data0[i] != i+1)
        exit(i+1);
    }
    // fill the cache with new data
    for (int i = 0; i < NUM_CACHELINES; i++) {
      data1[cid*NUM_CACHELINES+i] = (cid+1)*i+1;
      if (data1[cid*NUM_CACHELINES+i] != (cid+1)*i+1)
        exit((cid+1)*i+1);
    }
  }

  return 0;
}
