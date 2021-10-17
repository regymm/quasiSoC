SECTIONS
{
    . = 0x20000000;
    .text : { *(.text.boot) }
    .text : { *(.text) }
    .data : { *(.data) }
}
