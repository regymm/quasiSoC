ENTRY(_start)
SECTIONS
{
	. = 0x20001000;
	/*. = 0xf0000000;*/
    .text : { _start = .; *(.text) }
    .data : { *(.data) }
}
