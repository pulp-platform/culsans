// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_modify_cache_share_intense.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t start __attribute__((section(".nocache_share_region")));
volatile uint64_t count __attribute__((section(".nocache_share_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  start = 0;
  // core 0 initializes the synchronization variable
  if (cid == 0) {
    count = 0;
    prepare();
    start = 1;
  }
  else
    while(!start);

  // actual test
  read_modify_cache_share_intense(cid, nc);
  count++;

  // cores wait here
  while(cid)
    { asm volatile ("wfi"); }

  // core 0 continues after all cores have finished
  if (cid == 0) {
    while (count != nc)
      { asm volatile ("nop"); }
    exit(check(nc));
  }
}

int main()
{
return 0;
}
