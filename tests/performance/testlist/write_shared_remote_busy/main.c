#include "write_shared_remote_busy.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
volatile uint64_t count __attribute__((section(".nocache_noshare_region")));

extern void exit(int);

void thread_entry(int cid, int nc)
{
  // actual test
  write_shared_remote_busy(cid, nc);
}

int main()
{
  return 0;
}
