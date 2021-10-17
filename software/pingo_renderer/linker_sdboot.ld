/* Script for -z combreloc: combine and sort reloc sections */
/* Copyright (C) 2014-2018 Free Software Foundation, Inc.
   Copyright (C) 2019 ETH Zürich and University of Bologna
   Copying and distribution of this script, with or without modification,
   are permitted in any medium without royalty provided the copyright
   notice and this notice are preserved.  */

/* This linker script is derived from the default linker script of the RISC-V
   gcc compiler. We have made a few changes to make it suitable for linking bare
   metal programs. These are mostly removing dynamic linking related sections and
   putting sections into our memory regions. */

SECTIONS
{
	__heap_size = DEFINED(__heap_size) ? __heap_size : 0x1000;

	. = 0x20001000;
	.text : { *(.text.boot) }
	.text : { *(.text) }
	.data : { *(.data) }
	.bss : { *(.bss) }
	.heap          :
	{
		PROVIDE(__heap_start = .);
		. = __heap_size;
		PROVIDE(__heap_end = .);
	}
	_edata = .; PROVIDE (edata = .);
	__global_pointer$ = 0x0;
	_end = .; PROVIDE (end = .);
}
