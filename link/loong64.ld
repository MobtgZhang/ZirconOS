OUTPUT_FORMAT(elf64-loongarch)
ENTRY(_start)

SECTIONS
{
  . = 0x9000000000200000;
  PROVIDE(_kernel_start = .);

  .text : ALIGN(4K)
  {
    *(.text.boot)
    *(.text .text.*)
  }

  .rodata : ALIGN(4K)
  {
    *(.rodata .rodata.*)
  }

  .data : ALIGN(4K)
  {
    *(.data .data.*)
  }

  .bss : ALIGN(4K)
  {
    *(COMMON)
    *(.bss .bss.*)
  }

  . = ALIGN(4K);
  PROVIDE(_kernel_end = .);
}
