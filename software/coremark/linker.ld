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

/*MEMORY*/
/*{*/
	/*ram (rwxai) : ORIGIN = 0x20000000, LENGTH = 0x400000*/
/*}*/
SECTIONS
{
	/* we want a fixed entry point */
	/*PROVIDE(__boot_address = 0x20000000);*/

	/* stack and heap related settings */
	/*__stack_size = DEFINED(__stack_size) ? __stack_size : 0x1000;*/
	/*PROVIDE(__stack_size = __stack_size);*/
	__heap_size = DEFINED(__heap_size) ? __heap_size : 0x1000;

	/* crt0 init code */
	/*.init (__boot_address):*/
	/*{*/
		/*KEEP (*(SORT_NONE(.init)))*/
		/*KEEP (*(.text.start))*/
	/*} >ram*/

	. = 0x20001000;
	.text : { *(.text.boot) }
	.text : { *(.text) }
	.data : { *(.data) }
	.bss : { *(.bss) }

	/* the bulk of the program: main, libc, functions etc. */
	/*.text           :*/
	/*{*/
		/**(.text.unlikely .text.*_unlikely .text.unlikely.*)*/
		/**(.text.exit .text.exit.*)*/
		/**(.text.startup .text.startup.*)*/
		/**(.text.hot .text.hot.*)*/
		/**(.text .stub .text.* .gnu.linkonce.t.*)*/
		/*[> .gnu.warning sections are handled specially by elf32.em.  <]*/
		/**(.gnu.warning)*/
	/*} >ram*/

	/* data sections for initalized data */
	/*.data           :*/
	/*{*/
		/*__DATA_BEGIN__ = .;*/
		/**(.data .data.* .gnu.linkonce.d.*)*/
		/*SORT(CONSTRUCTORS)*/
	/*} >ram*/

	/* heap: we should consider putting this to the bottom of the address space */
	.heap          :
	{
		PROVIDE(__heap_start = .);
		. = __heap_size;
		PROVIDE(__heap_end = .);
	}
	/*} >ram*/

	/* stack: we should consider putting this further to the top of the address
	space */
	/*.stack         : ALIGN(16) [> this is a requirement of the ABI(?) <]*/
	/*{*/
		/*PROVIDE(__stack_start = .);*/
		/*. = __stack_size;*/
		/*PROVIDE(_sp = .);*/
		/*PROVIDE(__stack_end = .);*/
	/*} >ram*/

	/*/DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }*/
    /*[>/DISCARD/ : { *(.comment) *(.gnu*) *(.note*) *(.eh_frame*) *(.reginfo) *(.MIPS.abiflags) *(.pdr)}<]*/
}
