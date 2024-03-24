// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
uint128_t data[NB_CORES] __attribute__((section(".nocache_noshare_region")));

int raw_spin_lock(int cid, int nc)
{

  int tmp = 1;
  int i,j;

  asm volatile ("li a0, 0x80050000"); // Initialize lock address 0x80001000

  for (i=0; i<100; i++)
  {
    asm volatile ("li        a4,1");           // initialize swap value
    asm volatile ("_raw_spin_lock:");
    asm volatile ("lw        a5, 0(a0)");
    asm volatile ("sext.w    a5, a5");
    asm volatile ("bnez      a5, _raw_spin_lock");
    asm volatile ("amoswap.w a5, a4, (a0)");
    asm volatile ("fence     r, rw");
    asm volatile ("sext.w    a5, a5");
    asm volatile ("bnez      a5, _raw_spin_lock");

/*
    asm volatile ("lw        a5, 32(tp)"); //# 20 <section_count+0x1e>
    asm volatile ("slli      a4, a5, 0x3");
    asm volatile ("auipc     a5, 0x1871");
    asm volatile ("addi      a5, a5, 664"); //# ffffffe001ee0288 <__per_cpu_offset>
    asm volatile ("add       a5, a5, a4");
    asm volatile ("ld        a4, 0(a5)");
    asm volatile ("auipc     a5, 0xff9bb");
    asm volatile ("addi      a5, a5, 932"); //# ffffffe00002a3a0 <__mmiowb_state>
    asm volatile ("add       a5, a5, a4");
    asm volatile ("lhu       a4, 0(a5)");
    asm volatile ("addiw     a4, a4, 1");
    asm volatile ("sh        a4, 0(a5)");
*/

    // waste time
    for (j=0; j<tmp; j++)
      asm volatile ("nop");
    tmp = (tmp + 1) % (17 + 2*cid);

    // unlock
    asm volatile ("fence    rw,w");
    asm volatile ("sw    zero,0(a0)");

    // waste time
    for (j=0; j<tmp; j++)
      asm volatile ("nop");
    tmp = (tmp + 1) % (17 + 2*cid);


  }

  return 0;
}

