SECTIONS
{
    . = 0xf0000000;
    .text : { *(.text.boot) }
    .text : { *(.text) }
    .data : { *(.data) }

    /DISCARD/ : { *(.comment) *(.gnu*) *(.note*) *(.eh_frame*) *(.reginfo) *(.MIPS.abiflags) *(.pdr)}
}
