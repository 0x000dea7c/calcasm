%ifndef STRING_ASM
%define STRING_ASM

%include "syscalls.asm"
%include "constants.asm"

string_length:
        push rbx
        mov rbx, rax

.next_character:
        cmp byte [rax], 0x0
        jz .finished
        inc rax
        jmp .next_character

.finished:
        sub rax, rbx
        pop rbx
        ret

string_print:
        push rdx
        push rcx
        push rbx
        push rax
        call string_length
        mov rdx, rax
        pop rax
        mov rdx, rax
        mov rdi, stdout
        mov rax, sys_write
        syscall

string_print_line:
        call string_print
        push rax
        mov rax, LINE_FEED
        push rax
        mov rax, rsp
        call string_print
        pop rax
        pop rax
        ret

integer_print:
        push rax
        push rcx
        push rdx
        push rdi
        xor rcx, rcx            ; counter of how many bytes we need to print in the end

.divide_loop:
        inc rcx                 ; count each byte
        xor rdx, rdx
        mov rsi, 10
        idiv esi                ; slow
        add rdx, 48
        push rdx
        cmp rax, 0
        jnz .divide_loop

.print_loop:
        dec rcx
        mov rax, rsp
        call string_print
        pop rax
        cmp rcx, 0
        jnz .print_loop
        pop rsi
        pop rdx
        pop rcx
        pop rax
        ret

integer_print_line:
        call integer_print
        push rax
        mov rax, LINE_FEED
        push rax
        mov rax, rsp
        call string_print
        pop rax
        pop rax
        ret

%endif
