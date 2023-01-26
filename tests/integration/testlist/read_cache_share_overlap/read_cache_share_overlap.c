#include "read_cache_share_overlap.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
// cache is 32kB: 16B cachelines x 256 entries x 8 ways
uint128_t data[256*6] __attribute__((section(".cache_share_region")));

int read_cache_share_overlap(int cid, int nc)
{
  // core 0 fill the cache
  if (cid == 0) {
    for (int i = 0; i < sizeof(data)/sizeof(data[0]); i++)
      data[i] = i+1;
  }
  // the other cores read the same cachelines
  else {
    for (int i = 0; i < sizeof(data)/sizeof(data[0]); i++)
      if (data[i] != i+1)
        exit(cid*(i+1));
  }

  return 0;
}
