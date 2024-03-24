// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_shared_busy.h"
#include <stdint.h>

// synchronization variable: non-cached and non-shared
volatile uint64_t count __attribute__((section(".nocache_noshare_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  count = 0;
  if (cid == 0) {
    while(count == 0);
  }

  if (cid == nc-1) {
    prepare();
    count++;
  }

  // actual test
  read_shared_busy(cid, nc);
}

int main()
{
  return 0;
}
