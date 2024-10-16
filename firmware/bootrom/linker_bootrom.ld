ENTRY(_start)

SECTIONS
{
    . = 0xf0000000;
    .text : {
		_start = .;
		*(.text.boot)
		*(.text)
	}
    .data : { *(.data) }

    /DISCARD/ : { *(.comment) *(.gnu*) *(.note*) *(.eh_frame*) *(.reginfo) *(.MIPS.abiflags) *(.pdr)}
}
