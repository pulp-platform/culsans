#include "write_hit_exclusive.h"
#include <stdint.h>

extern void exit(int);

void thread_entry(int cid, int nc)
{
  if (cid == 0)
    // actual test
    write_hit_exclusive(cid, nc);

  while(cid)
    { asm volatile ("wfi"); }
}

int main()
{
  return 0;
}
