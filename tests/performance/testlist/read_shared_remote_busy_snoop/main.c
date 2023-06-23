#include "read_shared_remote_busy_snoop.h"
#include <stdint.h>

void thread_entry(int cid, int nc)
{
  // actual test
  read_shared_remote_busy_snoop(cid, nc);
}

int main()
{
  return 0;
}
