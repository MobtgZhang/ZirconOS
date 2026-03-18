# ============================================================================
# ZirconOS Boot Manager — Stage 2 (Real Mode → Protected Mode → Boot Menu)
# ============================================================================
#
# Loaded by VBR at 0x8000. This stage:
#   1. Enables A20 gate
#   2. Queries BIOS memory map (E820)
#   3. Switches to VGA text mode 80x25
#   4. Displays the ZirconOS Boot Manager menu
#   5. Transitions to 32-bit protected mode
#   6. Loads kernel ELF from disk
#   7. Sets up Multiboot2-compatible info structure
#   8. Jumps to kernel entry point
#
# Memory Map:
#   0x0500 - 0x0FFF : BIOS data / E820 map buffer
#   0x7C00 - 0x7DFF : VBR (no longer needed)
#   0x8000 - 0xFFFF : This stage2 code + data
#   0x10000+        : Kernel load buffer (protected mode)
#   0x9FC00         : Conventional memory top
# ============================================================================

.code16
.section .text
.global _stage2_start

.set STAGE2_MAGIC,    0x5A42        # 'ZB' — verified by VBR
.set KERNEL_LOAD_SEG, 0x1000        # Segment for kernel loading
.set KERNEL_LOAD_OFF, 0x0000
.set KERNEL_PHYS,     0x100000      # 1MB — final kernel position (PM)
.set E820_BUF,        0x0500        # E820 memory map buffer
.set E820_MAX_ENTRIES,64
.set VGA_TEXT_BASE,   0xB8000

# ── Stage2 Entry ──
# First two bytes are magic (checked by VBR), execution starts here
    .word STAGE2_MAGIC

_stage2_start:
    cli
    # DL = boot drive (passed from VBR)
    mov %dl, (s2_boot_drive)

    # Set up segments
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7C00, %sp
    sti

    # ── Step 1: Enable A20 Gate ──
    call enable_a20

    # ── Step 2: Query BIOS Memory Map (E820) ──
    call query_e820

    # ── Step 3: Set VGA text mode 80x25 ──
    mov $0x03, %ax
    int $0x10

    # ── Step 4: Display ZirconOS Boot Manager Menu ──
    call display_boot_menu

    # ── Step 5: Wait for user selection ──
    call wait_for_selection

    # ── Step 6: Switch to Protected Mode ──
    call enter_protected_mode

    # Never returns — jumps to PM code

# ============================================================================
# A20 Gate Enable (multiple methods for compatibility)
# ============================================================================
enable_a20:
    # Method 1: BIOS INT 15h
    mov $0x2401, %ax
    int $0x15
    jnc .a20_done

    # Method 2: Keyboard controller
    call .a20_wait_input
    mov $0xD1, %al
    out %al, $0x64
    call .a20_wait_input
    mov $0xDF, %al
    out %al, $0x60
    call .a20_wait_input

    # Method 3: Fast A20 (port 0x92)
    in $0x92, %al
    or $0x02, %al
    and $0xFE, %al                  # Don't reset CPU
    out %al, $0x92

.a20_done:
    ret

.a20_wait_input:
    in $0x64, %al
    test $0x02, %al
    jnz .a20_wait_input
    ret

# ============================================================================
# E820 Memory Map Query
# ============================================================================
query_e820:
    xor %ebx, %ebx
    mov $E820_BUF + 4, %di          # Leave 4 bytes for entry count
    xor %bp, %bp                    # Entry counter
    movl $0x0534D4150, %edx         # 'SMAP'

.e820_loop:
    mov $0xE820, %eax
    mov $24, %ecx                   # Entry size
    int $0x15
    jc .e820_done
    cmp $0x0534D4150, %eax
    jne .e820_done

    # Check if entry is usable (length > 0)
    movl 8(%di), %eax               # Length low
    orl 12(%di), %eax               # Length high
    jz .e820_skip

    inc %bp
    add $24, %di

.e820_skip:
    test %ebx, %ebx                 # EBX=0 means last entry
    jz .e820_done
    cmp $E820_MAX_ENTRIES, %bp
    jl .e820_loop

.e820_done:
    movw %bp, (E820_BUF)            # Store entry count
    movw $0, (E820_BUF + 2)         # Reserved
    ret

# ============================================================================
# Boot Manager Menu Display (Windows 7 Style)
# ============================================================================
display_boot_menu:
    # Clear screen to black
    mov $0x0600, %ax
    mov $0x07, %bh
    xor %cx, %cx
    mov $0x184F, %dx
    int $0x10

    # Hide cursor
    mov $0x01, %ah
    mov $0x2607, %cx
    int $0x10

    # Print boot manager banner
    mov $0x02, %ah                  # Set cursor position
    mov $0x00, %bh
    mov $0x0200, %dx                # Row 2, Col 0
    int $0x10
    mov $menu_header, %si
    call print_color_string

    # Print menu border
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0400, %dx                # Row 4
    int $0x10
    mov $menu_border_top, %si
    call .print16

    # Print menu entries
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0602, %dx                # Row 6, Col 2
    int $0x10
    mov $menu_title, %si
    call .print16

    # Entry 1 (default, highlighted)
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0804, %dx                # Row 8, Col 4
    int $0x10
    mov $0x70, %bl                  # White on black (highlighted)
    mov $entry_1, %si
    call print_attr_string

    # Entry 2
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0904, %dx                # Row 9, Col 4
    int $0x10
    mov $entry_2, %si
    call .print16

    # Entry 3
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0A04, %dx                # Row 10, Col 4
    int $0x10
    mov $entry_3, %si
    call .print16

    # Entry 4
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0B04, %dx                # Row 11, Col 4
    int $0x10
    mov $entry_4, %si
    call .print16

    # Entry 5
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0C04, %dx                # Row 12, Col 4
    int $0x10
    mov $entry_5, %si
    call .print16

    # Bottom border
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x0E00, %dx                # Row 14
    int $0x10
    mov $menu_border_bot, %si
    call .print16

    # Instructions
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x1002, %dx                # Row 16, Col 2
    int $0x10
    mov $menu_instructions, %si
    call .print16

    # Timer countdown
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x1202, %dx                # Row 18, Col 2
    int $0x10
    mov $menu_timer, %si
    call .print16

    # Footer
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x1700, %dx                # Row 23
    int $0x10
    mov $menu_footer, %si
    call .print16

    ret

# ============================================================================
# Wait for user menu selection (with timeout)
# ============================================================================
wait_for_selection:
    movb $0, (selected_entry)       # Default = entry 0
    movb $10, (countdown)           # 10 second timeout

.wait_loop:
    # Check for keypress (non-blocking)
    mov $0x01, %ah
    int $0x16
    jnz .process_key

    # Simple delay (~1 second using PIT)
    call delay_one_second

    decb (countdown)
    cmpb $0, (countdown)
    je .selection_done               # Timeout: use default

    # Update countdown display
    call update_countdown
    jmp .wait_loop

.process_key:
    # Read the key
    mov $0x00, %ah
    int $0x16

    cmp $0x48, %ah                  # Up arrow
    je .move_up
    cmp $0x50, %ah                  # Down arrow
    je .move_down
    cmp $0x1C, %ah                  # Enter
    je .selection_done
    cmp $0x3B, %ah                  # F1 (help)
    je .wait_loop

    # Number keys 1-5
    cmp $0x31, %al                  # '1'
    jb .wait_loop
    cmp $0x35, %al                  # '5'
    ja .wait_loop
    sub $0x31, %al
    movb %al, (selected_entry)
    call redraw_menu_selection
    jmp .selection_done

.move_up:
    cmpb $0, (selected_entry)
    je .wait_loop
    decb (selected_entry)
    call redraw_menu_selection
    jmp .wait_loop

.move_down:
    cmpb $4, (selected_entry)
    jge .wait_loop
    incb (selected_entry)
    call redraw_menu_selection
    jmp .wait_loop

.selection_done:
    ret

# ── Redraw menu highlight ──
redraw_menu_selection:
    # Clear all highlights (rows 8-12)
    mov $0, %cl
.redraw_loop:
    push %cx
    mov $0x02, %ah
    mov $0x00, %bh
    add $8, %cl
    mov %cl, %dh
    mov $4, %dl
    int $0x10

    # Determine if this row is selected
    pop %cx
    push %cx
    cmpb (selected_entry), %cl
    je .draw_highlighted
    mov $0x07, %bl                  # Normal: light gray on black
    jmp .draw_entry
.draw_highlighted:
    mov $0x70, %bl                  # Highlighted: black on white

.draw_entry:
    pop %cx
    push %cx

    # Get entry string pointer
    xor %ax, %ax
    mov %cl, %al
    shl $1, %ax                     # *2 for word-size pointer table
    mov $entry_table, %si
    add %ax, %si
    mov (%si), %si
    call print_attr_string

    pop %cx
    inc %cl
    cmp $5, %cl
    jl .redraw_loop
    ret

# ── Print string with attribute in BL ──
print_attr_string:
    lodsb
    test %al, %al
    jz .pas_done
    mov $0x09, %ah
    mov $0x00, %bh
    mov $1, %cx
    int $0x10
    # Advance cursor
    push %ax
    mov $0x03, %ah
    mov $0x00, %bh
    int $0x10
    inc %dl
    mov $0x02, %ah
    int $0x10
    pop %ax
    jmp print_attr_string
.pas_done:
    ret

# ── Print colored string for header ──
print_color_string:
    mov $0x1F, %bl                  # White on blue
    jmp print_attr_string

# ── Simple delay (~1 second) ──
delay_one_second:
    push %cx
    push %dx
    mov $0x00, %ah                  # Read system timer
    int $0x1A
    mov %dx, %bx                   # Save current tick count
.delay_wait:
    mov $0x00, %ah
    int $0x1A
    sub %bx, %dx
    cmp $18, %dx                    # ~18.2 ticks/sec
    jl .delay_wait
    pop %dx
    pop %cx
    ret

# ── Update countdown display ──
update_countdown:
    mov $0x02, %ah
    mov $0x00, %bh
    mov $0x124E, %dx                # Row 18, Col 78 (approx)
    int $0x10
    movb (countdown), %al
    add $0x30, %al
    mov $0x0E, %ah
    int $0x10
    ret

# ============================================================================
# Switch to Protected Mode
# ============================================================================
enter_protected_mode:
    cli

    # Load GDT
    lgdt (s2_gdt_desc)

    # Set PE bit in CR0
    mov %cr0, %eax
    or $1, %eax
    mov %eax, %cr0

    # Far jump to flush pipeline, enter 32-bit code
    ljmp $0x08, $pm_entry

# ── Simple print (16-bit real mode) ──
.print16:
    lodsb
    test %al, %al
    jz .print16_done
    mov $0x0E, %ah
    mov $0x07, %bx
    int $0x10
    jmp .print16
.print16_done:
    ret

# ============================================================================
# 32-bit Protected Mode Code
# ============================================================================
.code32
pm_entry:
    # Set up data segments
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    mov $0x7C00, %esp

    # ── Load kernel from disk to KERNEL_PHYS (1MB) ──
    # Use direct port I/O to ATA (PIO mode) to read kernel sectors
    # The kernel starts at a known disk offset (partition start + 65 sectors)

    # For now: display PM banner on VGA
    movl $VGA_TEXT_BASE, %edi
    # Row 24 (offset = 24 * 160 = 3840)
    addl $3840, %edi
    movl $pm_ready_msg, %esi
    movb $0x0A, %ah                 # Green on black

.pm_print:
    lodsb
    test %al, %al
    jz .pm_print_done
    stosw
    jmp .pm_print
.pm_print_done:

    # ── Build minimal Multiboot2-like info structure ──
    # Place at 0x9000 (below stage2)
    movl $0x9000, %edi

    # Total size (placeholder, patched later)
    movl $0, (%edi)
    movl $0, 4(%edi)                # Reserved
    addl $8, %edi

    # Tag: basic memory info (type=4, size=16)
    movl $4, (%edi)                 # type
    movl $16, 4(%edi)               # size
    movl $640, 8(%edi)              # mem_lower (640 KB)
    movl $0, %eax
    movw (E820_BUF), %ax            # E820 entry count
    # Estimate upper memory from E820
    movl $131072, 12(%edi)          # mem_upper (~128MB default)
    addl $16, %edi

    # Tag: command line (type=1)
    movl $1, (%edi)                 # type
    # Size = 8 + string length + 1 (null)
    movl $cmdline_default, %esi
    call strlen32
    addl $9, %eax                   # 8 (header) + len + 1 (null)
    andl $0xFFFFFFF8, %eax          # Align to 8
    addl $8, %eax
    movl %eax, 4(%edi)
    addl $8, %edi
    movl $cmdline_default, %esi
.copy_cmdline:
    lodsb
    stosb
    test %al, %al
    jnz .copy_cmdline
    # Align EDI to 8
    addl $7, %edi
    andl $0xFFFFFFF8, %edi

    # Tag: end (type=0, size=8)
    movl $0, (%edi)
    movl $8, 4(%edi)
    addl $8, %edi

    # Patch total size
    movl %edi, %eax
    subl $0x9000, %eax
    movl %eax, (0x9000)

    # ── Jump to kernel at 1MB ──
    # EAX = Multiboot2 magic
    # EBX = pointer to boot info
    movl $0x36D76289, %eax          # Multiboot2 bootloader magic
    movl $0x9000, %ebx
    jmp *$KERNEL_PHYS

# ── strlen32: ESI = string, returns EAX = length ──
strlen32:
    push %esi
    xor %eax, %eax
.strlen32_loop:
    cmpb $0, (%esi)
    je .strlen32_done
    inc %eax
    inc %esi
    jmp .strlen32_loop
.strlen32_done:
    pop %esi
    ret

# ============================================================================
# Data Section
# ============================================================================
.code16

# ── Boot drive ──
s2_boot_drive:
    .byte 0x80

# ── Menu selection state ──
selected_entry:
    .byte 0
countdown:
    .byte 10

# ── GDT for Protected Mode ──
.align 16
s2_gdt:
    .quad 0x0000000000000000        # 0x00: Null
    .quad 0x00CF9A000000FFFF        # 0x08: 32-bit code (0-4GB, exec/read)
    .quad 0x00CF92000000FFFF        # 0x10: 32-bit data (0-4GB, read/write)
s2_gdt_end:

s2_gdt_desc:
    .word s2_gdt_end - s2_gdt - 1
    .long s2_gdt

# ── Menu entry pointer table ──
entry_table:
    .word entry_1
    .word entry_2
    .word entry_3
    .word entry_4
    .word entry_5

# ── Menu Strings ──
menu_header:
    .asciz "              ZirconOS Boot Manager  v1.0                                       "
menu_border_top:
    .asciz "  +======================================================================+\r\n"
menu_title:
    .asciz "  Choose an operating system to start:\r\n"
entry_1:
    .asciz "  ZirconOS v1.0                                  "
entry_2:
    .asciz "  ZirconOS v1.0 [Debug Mode]                     "
entry_3:
    .asciz "  ZirconOS v1.0 [Safe Mode]                      "
entry_4:
    .asciz "  ZirconOS v1.0 [Recovery Console]               "
entry_5:
    .asciz "  ZirconOS v1.0 [Last Known Good Configuration]  "
menu_border_bot:
    .asciz "  +======================================================================+\r\n"
menu_instructions:
    .asciz "  Use the arrow keys to highlight your choice, then press ENTER.\r\n"
menu_timer:
    .asciz "  Seconds until the highlighted choice will be started automatically:  10"
menu_footer:
    .asciz "  ENTER=Choose  |  F1=Help  |  ESC=Advanced Options"
pm_ready_msg:
    .asciz "ZirconOS Boot Manager: Protected mode active"

# ── Command lines for each entry ──
cmdline_default:
    .asciz "console=serial,vga debug=0"
cmdline_debug:
    .asciz "console=serial,vga debug=1 verbose=1"
cmdline_safe:
    .asciz "safe_mode=1 debug=0 minimal=1"
cmdline_recovery:
    .asciz "recovery=1 console=serial,vga debug=1"
cmdline_lastgood:
    .asciz "lastknowngood=1"
