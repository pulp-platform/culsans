#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
uint128_t data[NB_CORES] __attribute__((section(".nocache_noshare_region")));

int amo_mutex(int cid, int nc)
{

  // implement the example code of mutual exclusion from RISC-V spec section 8.4
  int tmp = 1;
  int i,j;

  asm volatile ("li t0, 1");                   // Initialize swap value.
  asm volatile ("li a0, 0x0000000080060000");  // Initialize lock address 0x80001000

  for (i=0; i<100; i++)
  {
    asm volatile ("again:");                    // label
    asm volatile ("lw t1, (a0)");               // Check if lock is held.
    asm volatile ("bnez t1, again");            // Retry if held.
    asm volatile ("amoswap.w.aq t1, t0, (a0)"); // Attempt to acquire lock.
    asm volatile ("bnez t1, again");            // Retry if held.

    // waste time,
    for (j=0; j<tmp; j++) {
      asm volatile ("nop");
    }

    tmp = (tmp + 1 + cid) % (17 + 2*cid);

    asm volatile ("amoswap.w.rl x0, x0, (a0)"); // Release lock by storing 0.
  }

  return 0;
}

