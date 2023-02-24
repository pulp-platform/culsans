#include "read_modify_cache_share_intense.h"
#include "../../sw/include/nb_cores.h"
#include <stdint.h>

extern void exit(int);

// cachelines are 128bit long
#define uint128_t __uint128_t
#define NUM_CACHELINES 16*8
uint128_t data[NUM_CACHELINES] __attribute__((section(".cache_share_region")));

#define LOOPS 32

void prepare()
{
  for (int i = 0; i < NUM_CACHELINES; i++) {
    data[i] = i+1;
    if (data[i] != i+1)
      exit(i+1);
  }
}

int read_modify_cache_share_intense(int cid, int nc)
{
  for (int i = 0; i < LOOPS; i++)
    for (int j = 0; j < NUM_CACHELINES; j++)
      data[j] += (cid+1)*10;
}

int check(int nc)
{
  int exp_base = 0;
  for (int i = 0; i < nc; i++)
    exp_base += i+1;

  for (int i = 0; i < NUM_CACHELINES; i++) {
    if (data[i] != i+1 + LOOPS*exp_base*10)
      return i+1;
  }
}
