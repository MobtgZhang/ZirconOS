// x86_64 内核入口：GRUB Multiboot2 将 magic 放入 EAX，multiboot info 物理地址放入 EBX，
// C 调用约定期望参数在 EDI、ESI。此 trampoline 完成寄存器转换后跳转到 kernel_main。
const kernel_main = @import("main").kernel_main;

pub export fn _start() callconv(.naked) noreturn {
    const target = kernel_main;
    asm volatile (
        \\ mov %%eax, %%edi
        \\ mov %%ebx, %%esi
        \\ jmp *%%r9
        :
        : [dst] "{r9}" (target)
        : .{ .eax = true, .ebx = true, .edi = true, .esi = true }
    );
}
