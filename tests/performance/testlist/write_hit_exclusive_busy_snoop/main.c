#include "write_hit_exclusive_busy_snoop.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t count __attribute__((section(".nocache_share_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  // actual test
  write_hit_exclusive_busy_snoop(cid, nc);
}

int main()
{
  return 0;
}
