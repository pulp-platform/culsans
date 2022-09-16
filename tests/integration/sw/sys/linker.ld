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
  SRAM (rwx) : ORIGIN = 0x01000000, LENGTH = 1M
  ROM (rx)  : ORIGIN = 0x02000000, LENGTH = 512K
  FLASH (rwx) : ORIGIN = 0x03000000, LENGTH = 2M
}
*/

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{

  /* data segment */
  . = 0x1000000;
  .data : { *(.data) }

  . = 0x1001000;
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

. = 0x2000000;
.text.init : { *(.text.init) }

.text : { *(.text) }

}

