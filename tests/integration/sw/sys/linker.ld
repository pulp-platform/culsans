/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c */

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Memory layout                                                        */
/*----------------------------------------------------------------------*/

/*
MEMORY
{
  SRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}
*/

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{
  /* set the base address at the beginnning of the RAM */
  . = 0x80000000;

  /* data segment */
  .data : { *(.data) }

  . = 0x80001000;
  .tohost : { *(.tohost) }

  .sdata : {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  /* bss segment */
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .bss : { *(.bss) }

  /* thread-local data segment */
  .tdata :
  {
    _tls_data = .;
    *(.tdata.begin)
    *(.tdata)
    *(.tdata.end)
  }
  .tbss :
  {
    *(.tbss)
    *(.tbss.end)
  }

  /* End of uninitalized data segement */
  _end = .;

. = 0x80002000;

.text.init : { *(.text.init) }

.text : { *(.text) }

}

