pub const Arch = struct {
    /// 架构人类可读名称
    pub const name: []const u8 = "mips64el";

    /// 架构 ABI 名称（用于日志 / 协议）
    pub const abi_name: []const u8 = "mips64el";

    /// 架构位数
    pub const bits: u8 = 64;

    /// ZirconOS 为 mips64el 分配的内部架构 ID（自定义）
    pub const arch_id: u16 = 0x0364;

    /// ZirconOS 内核架构层接口版本号（主+次）
    pub const api_major: u8 = 0;
    pub const api_minor: u8 = 1;
};

pub export fn _start() callconv(.C) noreturn {
    // TODO: MIPS64EL 启动入口
    unreachable; // 目前为占位实现
}


