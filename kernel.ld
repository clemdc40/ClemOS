ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);  /* Read & Execute */
    rodata PT_LOAD FLAGS(4); /* Read-Only */
    data PT_LOAD FLAGS(6);  /* Read & Write */
}

SECTIONS
{
    . = 0x20000; /* Adresse de chargement du kernel */

    .text : ALIGN(4) {
        *(.text.entry)   /* Place _start ici */
        *(.text)
    } : text

    .rodata : ALIGN(4) {
        *(.rodata)
    } : rodata

    .data : ALIGN(4) {
        *(.data)
    } : data

    .bss : ALIGN(4) {
        *(COMMON)
        *(.bss)
    } : data
}
