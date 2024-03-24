// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "read_nocache_noshare_overlap.h"
#include <stdint.h>

extern void exit(int);

uint64_t data[4] __attribute__((section(".nocache_noshare_region")));

int read_nocache_noshare_overlap(int cid, int nc)
{

}
