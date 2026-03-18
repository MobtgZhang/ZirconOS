//! CMD.EXE - Command Prompt Shell
//! Windows-compatible command interpreter with built-in commands.
//! Supports: dir, cd, cls, echo, type, mkdir, del, ver, help, set, exit, etc.

const console = @import("console.zig");
const diskpart = @import("diskpart.zig");
const kernel32 = @import("../../libs/kernel32.zig");
const vfs = @import("../../fs/vfs.zig");
const fat32 = @import("../../fs/fat32.zig");
const ntfs = @import("../../fs/ntfs.zig");
const process = @import("../../ps/process.zig");
const klog = @import("../../rtl/klog.zig");
const scheduler = @import("../../ke/scheduler.zig");

pub const CMD_VERSION = "ZirconOS CMD [Version 10.0.19041.1]";
pub const COPYRIGHT = "(C) ZirconOS Project. All rights reserved.";

const MAX_CMD_LEN: usize = 256;
const MAX_HISTORY: usize = 32;
const MAX_ENV_VARS: usize = 64;
const MAX_ALIASES: usize = 32;

pub const ShellState = enum {
    idle,
    running,
    executing_command,
    exiting,
};

pub const EnvVar = struct {
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    value: [128]u8 = [_]u8{0} ** 128,
    value_len: usize = 0,
};

pub const CmdAlias = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: usize = 0,
    command: [128]u8 = [_]u8{0} ** 128,
    command_len: usize = 0,
};

pub const CmdShell = struct {
    state: ShellState = .idle,
    current_dir: [260]u8 = [_]u8{0} ** 260,
    current_dir_len: usize = 0,
    history: [MAX_HISTORY][MAX_CMD_LEN]u8 = [_][MAX_CMD_LEN]u8{[_]u8{0} ** MAX_CMD_LEN} ** MAX_HISTORY,
    history_len: [MAX_HISTORY]usize = [_]usize{0} ** MAX_HISTORY,
    history_count: usize = 0,
    env_vars: [MAX_ENV_VARS]EnvVar = [_]EnvVar{.{}} ** MAX_ENV_VARS,
    env_count: usize = 0,
    aliases: [MAX_ALIASES]CmdAlias = [_]CmdAlias{.{}} ** MAX_ALIASES,
    alias_count: usize = 0,
    echo_on: bool = true,
    exit_code: u32 = 0,
    console_id: u32 = 0,

    pub fn init(self: *CmdShell) void {
        self.state = .running;
        const dir = "C:\\";
        @memcpy(self.current_dir[0..dir.len], dir);
        self.current_dir_len = dir.len;

        self.setEnv("SystemRoot", "C:\\Windows");
        self.setEnv("SystemDrive", "C:");
        self.setEnv("COMPUTERNAME", "ZIRCONOS");
        self.setEnv("USERNAME", "System");
        self.setEnv("USERPROFILE", "C:\\Users\\System");
        self.setEnv("COMSPEC", "C:\\Windows\\System32\\cmd.exe");
        self.setEnv("PATH", "C:\\Windows\\System32;C:\\Windows");
        self.setEnv("PATHEXT", ".COM;.EXE;.BAT;.CMD");
        self.setEnv("PROMPT", "$P$G");
        self.setEnv("OS", "ZirconOS_NT");
        self.setEnv("PROCESSOR_ARCHITECTURE", "AMD64");
        self.setEnv("NUMBER_OF_PROCESSORS", "1");
    }

    pub fn setEnv(self: *CmdShell, name: []const u8, value: []const u8) void {
        for (self.env_vars[0..self.env_count]) |*ev| {
            if (strEqlI(ev.name[0..ev.name_len], name)) {
                const v_copy = @min(value.len, ev.value.len);
                @memcpy(ev.value[0..v_copy], value[0..v_copy]);
                ev.value_len = v_copy;
                return;
            }
        }
        if (self.env_count >= MAX_ENV_VARS) return;
        var ev = &self.env_vars[self.env_count];
        const n_copy = @min(name.len, ev.name.len);
        @memcpy(ev.name[0..n_copy], name[0..n_copy]);
        ev.name_len = n_copy;
        const v_copy = @min(value.len, ev.value.len);
        @memcpy(ev.value[0..v_copy], value[0..v_copy]);
        ev.value_len = v_copy;
        self.env_count += 1;
    }

    pub fn getEnv(self: *CmdShell, name: []const u8) ?[]const u8 {
        for (self.env_vars[0..self.env_count]) |*ev| {
            if (strEqlI(ev.name[0..ev.name_len], name)) {
                return ev.value[0..ev.value_len];
            }
        }
        return null;
    }

    pub fn showBanner(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine(CMD_VERSION);
        con.writeLine(COPYRIGHT);
        con.writeLine("");
    }

    pub fn showPrompt(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        _ = con.writeOutput(self.current_dir[0..self.current_dir_len]);
        _ = con.writeOutput(">");
    }

    pub fn executeCommand(self: *CmdShell, input: []const u8) void {
        if (input.len == 0) return;

        self.addHistory(input);
        self.state = .executing_command;

        var cmd_buf: [MAX_CMD_LEN]u8 = undefined;
        const trimmed = trim(input);
        const cmd_len = @min(trimmed.len, cmd_buf.len);
        @memcpy(cmd_buf[0..cmd_len], trimmed[0..cmd_len]);

        var cmd_name_end: usize = 0;
        while (cmd_name_end < cmd_len and cmd_buf[cmd_name_end] != ' ') {
            cmd_name_end += 1;
        }

        const cmd_name = cmd_buf[0..cmd_name_end];
        const args_start = if (cmd_name_end < cmd_len) cmd_name_end + 1 else cmd_len;
        const args = cmd_buf[args_start..cmd_len];

        if (strEqlI(cmd_name, "dir")) {
            self.cmdDir(args);
        } else if (strEqlI(cmd_name, "cd") or strEqlI(cmd_name, "chdir")) {
            self.cmdCd(args);
        } else if (strEqlI(cmd_name, "cls")) {
            self.cmdCls();
        } else if (strEqlI(cmd_name, "echo")) {
            self.cmdEcho(args);
        } else if (strEqlI(cmd_name, "type")) {
            self.cmdType(args);
        } else if (strEqlI(cmd_name, "mkdir") or strEqlI(cmd_name, "md")) {
            self.cmdMkdir(args);
        } else if (strEqlI(cmd_name, "del") or strEqlI(cmd_name, "erase")) {
            self.cmdDel(args);
        } else if (strEqlI(cmd_name, "ver")) {
            self.cmdVer();
        } else if (strEqlI(cmd_name, "help")) {
            self.cmdHelp();
        } else if (strEqlI(cmd_name, "set")) {
            self.cmdSet(args);
        } else if (strEqlI(cmd_name, "exit")) {
            self.cmdExit();
        } else if (strEqlI(cmd_name, "date")) {
            self.cmdDate();
        } else if (strEqlI(cmd_name, "time")) {
            self.cmdTime();
        } else if (strEqlI(cmd_name, "systeminfo")) {
            self.cmdSystemInfo();
        } else if (strEqlI(cmd_name, "tasklist")) {
            self.cmdTaskList();
        } else if (strEqlI(cmd_name, "hostname")) {
            self.cmdHostname();
        } else if (strEqlI(cmd_name, "whoami")) {
            self.cmdWhoami();
        } else if (strEqlI(cmd_name, "vol")) {
            self.cmdVol();
        } else if (strEqlI(cmd_name, "title")) {
            self.cmdTitle(args);
        } else if (strEqlI(cmd_name, "color")) {
            self.cmdColor(args);
        } else if (strEqlI(cmd_name, "path")) {
            self.cmdPath(args);
        } else if (strEqlI(cmd_name, "shutdown") or strEqlI(cmd_name, "shutdown.exe")) {
            self.cmdShutdown(args);
        } else if (strEqlI(cmd_name, "diskpart")) {
            self.cmdDiskpart();
        } else if (cmd_name.len > 0) {
            const con = console.getConsole(self.console_id) orelse return;
            _ = con.writeOutput("'");
            _ = con.writeOutput(cmd_name);
            con.writeLine("' is not recognized as an internal or external command,");
            con.writeLine("operable program or batch file.");
        }

        self.state = .running;
    }

    fn cmdDir(self: *CmdShell, _: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine(" Volume in drive C is ZIRCONOS");
        con.writeLine(" Volume Serial Number is 1234-5678");
        con.writeLine("");
        _ = con.writeOutput(" Directory of ");
        con.writeLine(self.current_dir[0..self.current_dir_len]);
        con.writeLine("");

        var entries: [32]vfs.DirEntry = [_]vfs.DirEntry{.{}} ** 32;
        var total_files: usize = 0;
        var total_dirs: usize = 0;

        const vol = fat32.getVolume();
        for (vol.root_entries[0..vol.root_entry_count]) |*fat_entry| {
            if (fat_entry.isFree() or fat_entry.isVolumeId()) continue;
            if (total_files + total_dirs >= entries.len) break;

            var e = &entries[total_files + total_dirs];
            e.* = .{};

            var pos: usize = 0;
            for (fat_entry.name) |c| {
                if (c == ' ') break;
                if (pos < e.name.len) {
                    e.name[pos] = c;
                    pos += 1;
                }
            }
            var has_ext = false;
            for (fat_entry.ext) |c| {
                if (c != ' ') {
                    has_ext = true;
                    break;
                }
            }
            if (has_ext) {
                if (pos < e.name.len) {
                    e.name[pos] = '.';
                    pos += 1;
                }
                for (fat_entry.ext) |c| {
                    if (c == ' ') break;
                    if (pos < e.name.len) {
                        e.name[pos] = c;
                        pos += 1;
                    }
                }
            }
            e.name_len = pos;
            e.file_size = fat_entry.file_size;

            if (fat_entry.isDirectory()) {
                e.file_type = .directory;
                total_dirs += 1;
            } else {
                e.file_type = .regular;
                total_files += 1;
            }
        }

        const entry_count = total_files + total_dirs;
        for (entries[0..entry_count]) |*e| {
            _ = con.writeOutput("2024/01/01  00:00    ");
            if (e.file_type == .directory) {
                _ = con.writeOutput("<DIR>          ");
            } else {
                _ = con.writeOutput("               ");
            }
            con.writeLine(e.name[0..e.name_len]);
        }

        con.writeLine("");
        var count_buf: [16]u8 = undefined;
        const file_str = formatUint(&count_buf, total_files);
        _ = con.writeOutput("               ");
        _ = con.writeOutput(file_str);
        con.writeLine(" File(s)");
        const dir_str = formatUint(&count_buf, total_dirs);
        _ = con.writeOutput("               ");
        _ = con.writeOutput(dir_str);
        con.writeLine(" Dir(s)");
    }

    fn cmdCd(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            con.writeLine(self.current_dir[0..self.current_dir_len]);
            return;
        }
        if (trimmed.len == 2 and trimmed[0] == '.' and trimmed[1] == '.') {
            if (self.current_dir_len > 3) {
                var i = self.current_dir_len - 1;
                if (i > 0 and self.current_dir[i - 1] == '\\') i -= 1;
                while (i > 2 and self.current_dir[i - 1] != '\\') i -= 1;
                self.current_dir_len = i;
            }
            return;
        }
        if (trimmed.len < 260) {
            const copy_len = @min(trimmed.len, self.current_dir.len - self.current_dir_len - 1);
            if (self.current_dir_len > 0 and self.current_dir[self.current_dir_len - 1] != '\\') {
                self.current_dir[self.current_dir_len] = '\\';
                self.current_dir_len += 1;
            }
            @memcpy(self.current_dir[self.current_dir_len..][0..copy_len], trimmed[0..copy_len]);
            self.current_dir_len += copy_len;
        }
    }

    fn cmdCls(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.clear();
    }

    fn cmdEcho(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        if (args.len == 0) {
            if (self.echo_on) {
                con.writeLine("ECHO is on.");
            } else {
                con.writeLine("ECHO is off.");
            }
            return;
        }
        if (strEqlI(args, "on")) {
            self.echo_on = true;
            return;
        }
        if (strEqlI(args, "off")) {
            self.echo_on = false;
            return;
        }
        con.writeLine(args);
    }

    fn cmdType(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            con.writeLine("The syntax of the command is incorrect.");
            return;
        }
        con.writeLine("[File content display not yet implemented]");
    }

    fn cmdMkdir(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            con.writeLine("The syntax of the command is incorrect.");
            return;
        }
        const vol = fat32.getVolume();
        if (vol.createDirectory(trimmed)) |_| {
            return;
        }
        con.writeLine("A subdirectory or file already exists.");
    }

    fn cmdDel(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            con.writeLine("The syntax of the command is incorrect.");
            return;
        }
        const vol = fat32.getVolume();
        if (!vol.removeEntry(trimmed)) {
            con.writeLine("Could Not Find ");
        }
    }

    fn cmdVer(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("");
        con.writeLine(CMD_VERSION);
        con.writeLine("");
    }

    fn cmdHelp(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("For more information on a specific command, type HELP command-name");
        con.writeLine("");
        con.writeLine("CD        Displays or changes the current directory.");
        con.writeLine("CLS       Clears the screen.");
        con.writeLine("COLOR     Sets the console colors.");
        con.writeLine("DATE      Displays the date.");
        con.writeLine("DEL       Deletes one or more files.");
        con.writeLine("DIR       Displays a list of files and subdirectories.");
        con.writeLine("DISKPART  Opens the disk partitioning utility.");
        con.writeLine("ECHO      Displays messages, or turns command echoing on or off.");
        con.writeLine("EXIT      Quits the CMD.EXE program.");
        con.writeLine("HELP      Provides help for commands.");
        con.writeLine("HOSTNAME  Prints the name of the host.");
        con.writeLine("MD        Creates a directory.");
        con.writeLine("PATH      Displays or sets a search path for executables.");
        con.writeLine("SET       Displays, sets, or removes environment variables.");
        con.writeLine("SHUTDOWN  Shuts down, restarts, or logs off the system.");
        con.writeLine("SYSTEMINFO Displays system configuration information.");
        con.writeLine("TASKLIST  Displays all currently running processes.");
        con.writeLine("TIME      Displays the system time.");
        con.writeLine("TITLE     Sets the window title.");
        con.writeLine("TYPE      Displays the contents of a text file.");
        con.writeLine("VER       Displays the OS version.");
        con.writeLine("VOL       Displays a disk volume label.");
        con.writeLine("WHOAMI    Displays the current user name.");
    }

    fn cmdSet(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            for (self.env_vars[0..self.env_count]) |*ev| {
                _ = con.writeOutput(ev.name[0..ev.name_len]);
                _ = con.writeOutput("=");
                con.writeLine(ev.value[0..ev.value_len]);
            }
            return;
        }
        var eq_pos: usize = trimmed.len;
        for (trimmed, 0..) |c, i| {
            if (c == '=') {
                eq_pos = i;
                break;
            }
        }
        if (eq_pos < trimmed.len) {
            self.setEnv(trimmed[0..eq_pos], trimmed[eq_pos + 1 ..]);
        } else {
            if (self.getEnv(trimmed)) |val| {
                _ = con.writeOutput(trimmed);
                _ = con.writeOutput("=");
                con.writeLine(val);
            } else {
                con.writeLine("Environment variable not defined.");
            }
        }
    }

    fn cmdExit(self: *CmdShell) void {
        self.state = .exiting;
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("Exiting CMD...");
    }

    fn cmdDate(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("The current date is: 2024/01/01 Mon");
    }

    fn cmdTime(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        var count_buf: [16]u8 = undefined;
        const ticks = scheduler.getTicks();
        const secs = ticks / 100;
        const hrs = secs / 3600;
        const mins = (secs % 3600) / 60;
        const s = secs % 60;
        _ = con.writeOutput("The current time is: ");
        _ = con.writeOutput(formatUint(&count_buf, @intCast(hrs)));
        _ = con.writeOutput(":");
        _ = con.writeOutput(formatUint(&count_buf, @intCast(mins)));
        _ = con.writeOutput(":");
        con.writeLine(formatUint(&count_buf, @intCast(s)));
    }

    fn cmdSystemInfo(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("");
        con.writeLine("Host Name:                 ZIRCONOS");
        con.writeLine("OS Name:                   ZirconOS");
        con.writeLine("OS Version:                10.0.19041 Build 19041");
        con.writeLine("OS Manufacturer:           ZirconOS Project");
        con.writeLine("System Type:               x64-based PC");
        con.writeLine("Processor(s):              1 Processor(s) Installed.");
        con.writeLine("  [01]: AMD64 Family 6");

        var count_buf: [16]u8 = undefined;
        _ = con.writeOutput("Total Processes:           ");
        con.writeLine(formatUint(&count_buf, process.getProcessCount()));

        const heap = @import("../../mm/heap.zig");
        _ = con.writeOutput("Available Physical Memory: ");
        _ = con.writeOutput(formatUint(&count_buf, heap.freeBytes() / 1024));
        con.writeLine(" KB");
        con.writeLine("Boot Device:               \\Device\\HarddiskVolume1");
        con.writeLine("System Directory:          C:\\Windows\\System32");
        con.writeLine("");
    }

    fn cmdTaskList(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("");
        con.writeLine("Image Name                     PID Session Name        Mem Usage");
        con.writeLine("========================= ======== ================ ===========");
        con.writeLine("System                           1 Services                 0 K");
        con.writeLine("smss.exe                         2 Services                 0 K");
        con.writeLine("csrss.exe                        3 Console                  0 K");
        con.writeLine("cmd.exe                          4 Console                  0 K");
        con.writeLine("");
    }

    fn cmdHostname(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("ZIRCONOS");
    }

    fn cmdWhoami(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine("zirconos\\system");
    }

    fn cmdVol(self: *CmdShell) void {
        const con = console.getConsole(self.console_id) orelse return;
        con.writeLine(" Volume in drive C is ZIRCONOS");
        con.writeLine(" Volume Serial Number is 1234-5678");
    }

    fn cmdTitle(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len > 0) {
            con.setTitle(trimmed);
        }
    }

    fn cmdColor(self: *CmdShell, args: []const u8) void {
        _ = self;
        _ = args;
    }

    fn cmdPath(self: *CmdShell, args: []const u8) void {
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);
        if (trimmed.len == 0) {
            if (self.getEnv("PATH")) |val| {
                _ = con.writeOutput("PATH=");
                con.writeLine(val);
            }
        } else {
            self.setEnv("PATH", trimmed);
        }
    }

    fn cmdShutdown(self: *CmdShell, args: []const u8) void {
        const arch = @import("../../arch.zig");
        const con = console.getConsole(self.console_id) orelse return;
        const trimmed = trim(args);

        if (trimmed.len == 0) {
            con.writeLine("Usage: shutdown [/s | /r | /h | /l | /a] [/t xxx] [/f]");
            con.writeLine("  /s  Shutdown the computer.");
            con.writeLine("  /r  Restart the computer.");
            con.writeLine("  /h  Hibernate the local computer.");
            con.writeLine("  /l  Log off the current user.");
            con.writeLine("  /a  Abort a system shutdown.");
            con.writeLine("  /t  Set time-out period before shutdown (in seconds).");
            con.writeLine("  /f  Force running applications to close.");
            return;
        }

        var do_shutdown = false;
        var do_restart = false;
        var do_hibernate = false;
        var do_logoff = false;
        var do_abort = false;
        var do_force = false;
        var timeout: u32 = 0;

        var i: usize = 0;
        while (i < trimmed.len) {
            if (trimmed[i] == '/' or trimmed[i] == '-') {
                i += 1;
                if (i >= trimmed.len) break;
                const flag = if (trimmed[i] >= 'A' and trimmed[i] <= 'Z') trimmed[i] + 32 else trimmed[i];
                switch (flag) {
                    's' => do_shutdown = true,
                    'r' => do_restart = true,
                    'h' => do_hibernate = true,
                    'l' => do_logoff = true,
                    'a' => do_abort = true,
                    'f' => do_force = true,
                    't' => {
                        i += 1;
                        while (i < trimmed.len and trimmed[i] == ' ') i += 1;
                        while (i < trimmed.len and trimmed[i] >= '0' and trimmed[i] <= '9') {
                            timeout = timeout * 10 + @as(u32, trimmed[i] - '0');
                            i += 1;
                        }
                        continue;
                    },
                    else => {
                        con.writeLine("Invalid argument/option - Check the usage with: shutdown /?");
                        return;
                    },
                }
                i += 1;
            } else {
                i += 1;
            }
        }

        if (do_abort) {
            con.writeLine("The scheduled shutdown has been cancelled.");
            return;
        }

        if (do_logoff) {
            con.writeLine("Logging off...");
            klog.info("CMD: User initiated logoff", .{});
            self.state = .exiting;
            return;
        }

        if (do_hibernate) {
            con.writeLine("Hibernating the system...");
            klog.info("CMD: User initiated hibernate", .{});
            con.writeLine("The system is entering hibernation mode.");
            arch.halt();
        }

        if (do_restart) {
            con.writeLine("");
            var buf: [16]u8 = undefined;
            if (timeout > 0) {
                _ = con.writeOutput("The system will restart in ");
                _ = con.writeOutput(formatUint(&buf, timeout));
                con.writeLine(" seconds.");
            }
            con.writeLine("Restarting the system...");
            klog.info("CMD: User initiated restart (timeout=%d, force=%s)", .{
                timeout, if (do_force) "yes" else "no",
            });
            arch.reset();
        }

        if (do_shutdown) {
            con.writeLine("");
            var buf: [16]u8 = undefined;
            if (timeout > 0) {
                _ = con.writeOutput("The system will shut down in ");
                _ = con.writeOutput(formatUint(&buf, timeout));
                con.writeLine(" seconds.");
            }
            con.writeLine("Shutting down the system...");
            klog.info("CMD: User initiated shutdown (timeout=%d, force=%s)", .{
                timeout, if (do_force) "yes" else "no",
            });
            arch.shutdown();
        }

        con.writeLine("No valid shutdown action specified. Use: shutdown /s or shutdown /r");
    }

    fn cmdDiskpart(self: *CmdShell) void {
        diskpart.runInteractive(self.console_id);
    }

    fn addHistory(self: *CmdShell, cmd: []const u8) void {
        if (self.history_count >= MAX_HISTORY) return;
        const copy_len = @min(cmd.len, MAX_CMD_LEN);
        @memcpy(self.history[self.history_count][0..copy_len], cmd[0..copy_len]);
        self.history_len[self.history_count] = copy_len;
        self.history_count += 1;
    }
};

// ── Global CMD instance ──

var cmd_shell: CmdShell = .{};
var cmd_initialized: bool = false;

pub fn init() void {
    cmd_shell.init();
    cmd_initialized = true;
    klog.info("CMD: Command shell initialized", .{});
}

pub fn getShell() *CmdShell {
    return &cmd_shell;
}

pub fn runBootSequence() void {
    if (!cmd_initialized) init();

    cmd_shell.showBanner();
    cmd_shell.showPrompt();

    const demo_commands = [_][]const u8{
        "ver",
        "systeminfo",
        "dir",
        "set",
    };

    for (demo_commands) |cmd_str| {
        cmd_shell.executeCommand(cmd_str);
        cmd_shell.showPrompt();
    }
}

pub fn runInteractiveShell() noreturn {
    const arch = @import("../../arch.zig");

    if (!cmd_initialized) init();

    cmd_shell.showBanner();
    cmd_shell.showPrompt();

    var line_buf: [MAX_CMD_LEN]u8 = undefined;
    var line_len: usize = 0;

    while (true) {
        const ch_opt = arch.readInputChar();
        if (ch_opt) |ch| {
            switch (ch) {
                '\n', '\r' => {
                    const con = console.getConsole(cmd_shell.console_id);
                    if (con) |c| {
                        c.writeLine("");
                    }
                    if (line_len > 0) {
                        cmd_shell.executeCommand(line_buf[0..line_len]);
                    }
                    if (cmd_shell.state == .exiting) {
                        klog.info("CMD: Shell exited", .{});
                        break;
                    }
                    cmd_shell.showPrompt();
                    line_len = 0;
                },
                0x08, 0x7F => {
                    if (line_len > 0) {
                        line_len -= 1;
                        const con = console.getConsole(cmd_shell.console_id);
                        if (con) |c| {
                            _ = c.writeOutput("\x08 \x08");
                        }
                    }
                },
                0x03 => {
                    const con = console.getConsole(cmd_shell.console_id);
                    if (con) |c| {
                        c.writeLine("^C");
                    }
                    line_len = 0;
                    cmd_shell.showPrompt();
                },
                else => {
                    if (ch >= 0x20 and ch < 0x7F and line_len < MAX_CMD_LEN - 1) {
                        line_buf[line_len] = ch;
                        line_len += 1;
                        const con = console.getConsole(cmd_shell.console_id);
                        if (con) |c| {
                            _ = c.writeOutput(&[_]u8{ch});
                        }
                    }
                },
            }
        } else {
            arch.waitForInterrupt();
        }
    }
    arch.halt();
}

pub fn isInitialized() bool {
    return cmd_initialized;
}

// ── Utility Functions ──

fn strEqlI(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| {
        const ax = if (x >= 'A' and x <= 'Z') x + 32 else x;
        const by = if (y >= 'A' and y <= 'Z') y + 32 else y;
        if (ax != by) return false;
    }
    return true;
}

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    while (start < s.len and (s[start] == ' ' or s[start] == '\t')) start += 1;
    var end: usize = s.len;
    while (end > start and (s[end - 1] == ' ' or s[end - 1] == '\t' or s[end - 1] == '\r' or s[end - 1] == '\n')) end -= 1;
    return s[start..end];
}

fn formatUint(buf: []u8, value: usize) []const u8 {
    const digits = "0123456789";
    var tmp: [20]u8 = undefined;
    var len: usize = 0;
    var n = value;

    if (n == 0) {
        tmp[0] = '0';
        len = 1;
    } else {
        while (n > 0) {
            tmp[len] = digits[n % 10];
            len += 1;
            n /= 10;
        }
    }

    var pos: usize = 0;
    var i = len;
    while (i > 0) {
        i -= 1;
        if (pos < buf.len) {
            buf[pos] = tmp[i];
            pos += 1;
        }
    }
    return buf[0..pos];
}
