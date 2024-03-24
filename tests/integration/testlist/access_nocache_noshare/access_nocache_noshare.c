// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "access_nocache_noshare.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
uint128_t data[NB_CORES] __attribute__((section(".nocache_noshare_region")));

int access_nocache_noshare(int cid, int nc)
{
  // write data
  data[cid] = cid+1;
  // readback and throw an error in case of mismatch
  if (data[cid] != cid+1)
    exit(cid+1);

  return 0;
}
