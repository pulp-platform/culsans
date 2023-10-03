#include "write_shared_busy.h"
#include <stdint.h>

// synchronization variable: non-cached and shared
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
  write_shared_busy(cid, nc);
}

int main()
{
  return 0;
}
