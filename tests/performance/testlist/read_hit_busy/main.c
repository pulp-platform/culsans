#include "read_hit_busy.h"
#include <stdint.h>

// synchronization variable: non-cached and non-shared
volatile uint64_t count __attribute__((section(".nocache_noshare_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  // actual test
  read_hit_busy(cid, nc);
}

int main()
{
  return 0;
}
