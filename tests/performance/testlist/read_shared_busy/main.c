#include "read_shared_busy.h"
#include <stdint.h>

// synchronization variable: non-cached and non-shared
volatile uint64_t start __attribute__((section(".nocache_noshare_region")));
volatile uint64_t count __attribute__((section(".nocache_noshare_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  count = 0;start = 0;
  // core 0 initializes the synchronization variable
  if (cid == 0) {
    start = 0;
    start = 1;
  }
  else
    while(start == 0);

  if (cid == 0)
    prepare();

  // actual test
  read_shared_busy(cid, nc);
  count++;

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
