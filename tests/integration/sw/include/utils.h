// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>

//typedef enum { false, true } bool;

/**
 * @brief Write to CSR.
 * @param CSR register to write.
 * @param Value to write to CSR register.
 * @return void
 *
 * Function to handle CSR writes.
 *
 */
#define csrw(csr, value)  asm volatile ("csrw\t\t" #csr ", %0" : /* no output */ : "r" (value));

/**
 * @brief Read from CSR.
 * @param void
 * @return 32-bit unsigned int
 *
 * Function to handle CSR reads.
 *
 */
#define csrr(csr, value)  asm volatile ("csrr\t\t%0, " #csr "": "=r" (value));

/**
 * \brief Enables interrupts globally.
 * \param void
 * \return void
 *
 * By writing 1 to the ie (interruptenable) bit
 * interrupts are globally enabled.
 */
static inline void int_enable(void) 
{
  // read-modify-write
  uint64_t mstatus;
  uint64_t mie;
    
  // enable MSIP, timer_irq, irq[1]
  asm volatile ("csrr %0, mie": "=r" (mie));
  mie |= 0x288; // mie[3]=MSIP, mie[7]=timer, mie[9]=irq[1]
  asm volatile ("csrw mie, %0" : /* no output */ : "r" (mie));

  //enable MSTATUS.MIE
  asm volatile ("csrr %0, mstatus": "=r" (mstatus));
  mstatus |= 0x8;
  asm volatile ("csrw mstatus, %0" : /* no output */ : "r" (mstatus));
}

/**
 * \brief Disables interrupts globally.
 * \param void
 * \return void
 *
 * By writing 0 to the ie (interruptenable) bit
 * interrupts are globally disabled.
 */
static inline void int_disable(void) {
  // read-modify-write
  uint64_t mstatus;
  uint64_t mie;
  asm volatile ("csrr %0, mstatus": "=r" (mstatus));
  mstatus &= ~(0x88);
  asm volatile ("csrw mstatus, %0" : /* no output */ : "r" (mstatus));

  mie = 0;
  asm volatile ("csrw mie, %0" : /* no output */ : "r" (mie));
}

/**
 * @brief Request to put the core to sleep.
 * @param void
 *
 * Set the core to sleep state and wait for events/interrupt to wake up.
 *
 */
static inline void sleep(void) {
  asm volatile ("wfi");
}

// sleep some cycles
void sleep_busy(volatile int);

// 
static inline void pmp_allow_all(void) {
  uint64_t pmpaddr;
  pmpaddr = 0x800000000; // match all
  asm volatile ("csrw pmpaddr0, %0" : /* no output */ : "r" (pmpaddr));

  uint64_t pmpcfg;
  // for PMP0: A=TOR, W=1, X=1, R=1
  pmpcfg = 0xF;
  asm volatile ("csrw pmpcfg0, %0" : /* no output */ : "r" (pmpcfg));
}

#endif
