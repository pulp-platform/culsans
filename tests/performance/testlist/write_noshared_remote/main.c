#include "write_noshared_remote.h"
#include <stdint.h>

void thread_entry(int cid, int nc)
{
  // core 0 initializes the synchronization variable
  if (cid == 0)
    // actual test
    write_noshared_remote(cid, nc);
  else
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
