// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "writeback_cleanunique_flush.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t count __attribute__((section(".nocache_share_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  // core 0 initializes the synchronization variable
  if (cid == 0)
    count = 0;
  else
    while(count != cid);

  // actual test
  writeback_cleanunique_flush(cid, nc);
  count++;

  // wait for all cores to finish
  while (count != nc)
    { asm volatile ("nop"); }

  // flush the cache
  asm volatile ("fence.i");

  // cores > 0 wait here
  while(cid)
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
