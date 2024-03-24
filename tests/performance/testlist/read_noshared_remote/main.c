// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_noshared_remote.h"
#include <stdint.h>

void thread_entry(int cid, int nc)
{
  // core 0 initializes the synchronization variable
  if (cid == 0)
    // actual test
    read_noshared_remote(cid, nc);
  else
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
