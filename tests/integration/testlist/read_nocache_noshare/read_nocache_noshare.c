#include "read_nocache_noshare.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
uint128_t data[NB_CORES] __attribute__((section(".nocache_noshare_region")));

int read_nocache_noshare(int cid, int nc)
{
  // core 0 initializes the data
  if (cid == 0) {
    for (int i = 0; i < sizeof(data)/sizeof(data[0]); i++)
      data[i] = i+1;
  }

  if (data[cid] != cid+1)
    exit(cid+1);

  return 0;
}
