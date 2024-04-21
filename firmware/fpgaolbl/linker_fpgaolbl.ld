SECTIONS
{
    . = 0xf0000000;
    .text : { *(.text.boot) }
    .text : { *(.text) }
    .data : { *(.data) }
}
