/* linker.ld - Définit où le kernel est placé en mémoire */
ENTRY(kmain)

SECTIONS
{
  . = 0x10000; /* L'adresse où le kernel est chargé (segment 0x1000) */

  .text :
  {
    *(.text)
  }

  .data :
  {
    *(.data)
  }

  .bss :
  {
    *(.bss)
  }
}
