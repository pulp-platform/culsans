#include "utils.h"

// sleep for 'iter' iterations. each iteration is approx 10 cycles
void sleep_busy(volatile int iter)
{
  for (int i=0;i<iter;i++)
    asm volatile ("nop");
}

extern void abort();

void ISR() __attribute__ ((weak));
void ISR(void)
{
    abort();
}

