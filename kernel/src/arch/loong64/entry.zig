// loong64 内核入口（占位）
const kernel_main = @import("main").kernel_main;

pub export fn _start() callconv(.c) noreturn {
    kernel_main(0, 0);
}
