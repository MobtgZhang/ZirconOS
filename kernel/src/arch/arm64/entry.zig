// aarch64 内核入口：QEMU -kernel 直接跳转到这里，无参数。
const kernel_main = @import("main").kernel_main;

pub export fn _start() callconv(.c) noreturn {
    kernel_main(0, 0);
}
