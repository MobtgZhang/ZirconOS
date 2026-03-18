# x86_64 kernel entry point
# GRUB Multiboot2 places magic in EAX and info pointer in EBX.
# SystemV ABI expects first two args in EDI and ESI.
# This trampoline converts registers and jumps to kernel_main.

.section .text
.global _start
_start:
    mov %eax, %edi
    mov %ebx, %esi
    call kernel_main
1:
    hlt
    jmp 1b
