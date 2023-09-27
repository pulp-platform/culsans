#include "write_noshared_remote_busy_snoop.h"
#include <stdint.h>

void thread_entry(int cid, int nc)
{
  // actual test
  write_noshared_remote_busy_snoop(cid, nc);
}

int main()
{
  return 0;
}
