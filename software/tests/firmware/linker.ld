SECTIONS
{
    . = 0x20001000;
    .text : { *(.text) }
    .data : { *(.data) }
}
