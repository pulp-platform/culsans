#include "write_shared_remote.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t count __attribute__((section(".nocache_noshare_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  if (cid == 0)
    // actual test
    write_shared_remote(cid, nc);
  // cores wait here
  else
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
