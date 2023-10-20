#include "write_hit_shared_busy_snoop.h"
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
  write_hit_shared_busy_snoop(cid, nc);

  // cores wait here
  while(cid)
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
