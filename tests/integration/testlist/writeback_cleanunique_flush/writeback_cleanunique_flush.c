// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "writeback_cleanunique_flush.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
#define NUM_CACHELINES 256*6
uint128_t data[NUM_CACHELINES] __attribute__((section(".cache_share_region")));
uint64_t i __attribute__((section(".nocache_share_region")));

int writeback_cleanunique_flush(int cid, int nc)
{
  // core 0 initializes the cachelines
  if (cid == 0) {
    for (i = 0; i < NUM_CACHELINES; i++) {
      data[i] = i+1;
      if (data[i] != i+1)
        exit(i+1);
    }
  }
  else {
    for (i = 0; i < NUM_CACHELINES; i++) {
      data[i] += cid;
      if (data[i] != (((cid+1)*cid)/2)+i+1) // sum(0..cid) + i + 1
        exit(cid+i+1);
    }
  }

  return 0;
}
