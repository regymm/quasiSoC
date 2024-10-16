ENTRY(_start)
SECTIONS
{
    . = 0x20001000;
    .text : { _start = .; *(.text.boot) }
    .text : { *(.text) }
    .data : { *(.data) }
	.bss : {
		_bss_start = . ;
		*(.bss*)
		*(.sbss*)
		. = ALIGN(8) ;
		. += 4096 ;
		_sp = . - 16;
	}
	. = ALIGN(4);
	_end = . ;
}
