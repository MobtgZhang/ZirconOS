# Syscall 入口 (int 0x80, vector 128)
# 调用时: rax=syscall_no, rdi,rsi,rdx,r10,r8,r9=args
# 返回: rax=返回值
# 栈布局 (int 同特权): rip, cs, rflags

.global syscall_entry
syscall_entry:
    # 保存 syscall 参数到栈，传递 rsp 给 C 函数
    push %r9
    push %r8
    push %r10
    push %rdx
    push %rsi
    push %rdi
    push %rax
    mov %rsp, %rdi
    call syscall_dispatch
    add $56, %rsp
    iretq
