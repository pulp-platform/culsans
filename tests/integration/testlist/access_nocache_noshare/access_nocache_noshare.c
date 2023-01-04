#include "access_nocache_noshare.h"
#include <stdint.h>

extern void exit(int);

uint64_t data[4] __attribute__((section(".nocache_noshare_region")));

int access_nocache_noshare(int cid, int nc)
{
  // write data
  data[cid] = cid+1;
  // readback and trow an error in case of mismatch
  if (data[cid] != cid+1)
    exit(cid+1);
}
