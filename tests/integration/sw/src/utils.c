// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#include "utils.h"

// sleep for 'iter' iterations. each iteration is approx 10 cycles
void sleep_busy(volatile int iter)
{
  for (int i=0;i<iter;i++)
    asm volatile ("nop");
}

extern void abort();

void ISR() __attribute__ ((weak));
void ISR(void)
{
    abort();
}

