#include "writeback_readshared_flush.h"
#include <stdint.h>

extern void exit(int);

#define uint128_t __uint128_t
#define NUM_CACHELINES 256*8
uint128_t data[NUM_CACHELINES] __attribute__((section(".cache_share_region")));

int writeback_readshared_flush(int cid, int nc)
{
  // core 0 initializes the cachelines
  if (cid == 0) {
    for (int i = 0; i < NUM_CACHELINES; i++) {
      data[i] = i+1;
      if (data[i] != i+1)
        exit(i+1);
    }
  }
  else {
    for (int i = 0; i < NUM_CACHELINES; i++) {
      if (data[i] != i+1)
        exit(i+1);
    }
  }

  return 0;
}
