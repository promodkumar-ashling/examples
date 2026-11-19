
/*
 Linker script
*/

OUTPUT_ARCH( "riscv" )

ENTRY( _startup )

MEMORY
{
  ram  (wxa!ri) : ORIGIN = 0x67001000, LENGTH = 1M
}

/*----------------------------------------------------------------------*/
/* Sections                            */
/*----------------------------------------------------------------------*/
SECTIONS
{
  __stack_size = 1K;
  __heap_size = 1K;

  .text.init :
  {
    *(.text.init)
    . = ALIGN(8);
  } > ram

  .text :
  {
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
    . = ALIGN(4);
  } >ram

  .preinit_array  :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } > ram

  .init_array     :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  } > ram

  .fini_array     :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } > ram
	  
  .rodata :
  {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    . = ALIGN(4);
  } > ram

  .lalign : 
  {
    . = ALIGN(4);
    PROVIDE( _data_lma = . );
  } > ram
  
  .dalign :
  {
    . = ALIGN(4);
    PROVIDE( _data = . );
  } > ram
  
  .data :
  {
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN(8); 
  } > ram

  .sdata :
  {
    . = ALIGN(8);
    __global_pointer$ = . + 0x800;
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
    . = ALIGN(8);
    *(.srodata .srodata.*)
   . = ALIGN(8);
  } > ram
  
  . = ALIGN(4);
  PROVIDE( _edata = . );
  PROVIDE( edata = . );

  PROVIDE( _fbss = . );
  PROVIDE( __bss_start = . );
  
  .bss :
  {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    *(.bss .bss.*) 
    . = ALIGN(8);
  } > ram
  _end = .;
  
  .stack :
  {
    . = __stack_size;
	PROVIDE( _sp = . );
  } >ram
  
  .heap :
  {
    . = __heap_size;
    PROVIDE( _heap_end = . );
  } >ram
}
