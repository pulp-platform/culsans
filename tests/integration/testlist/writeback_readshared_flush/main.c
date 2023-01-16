#include "writeback_readshared_flush.h"
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
  writeback_readshared_flush(cid, nc);
  count++;

  // the first n-1 cores flush the cache as the next core finishes executing the test sequence
  if (cid < nc-1) {
    while (count != cid+2)
      { asm volatile ("nop"); }
    // flush the cache
    asm volatile ("fence");
  }

  // cores wait here
  while(cid)
    { asm volatile ("wfi"); }

  // core 0 continues after all cores have finished
  if (cid == 0) {
    while (count != nc)
      { asm volatile ("nop"); }
  }
}

int main()
{
  return 0;
}
