#include "read_modify_cache_share.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
#define NUM_CACHELINES 256*8
uint128_t data[NUM_CACHELINES] __attribute__((section(".cache_share_region")));

int read_modify_cache_share(int cid, int nc)
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
