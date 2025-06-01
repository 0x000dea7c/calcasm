%ifndef STRING_ASM
%define STRING_ASM

%include "syscalls.asm"
%include "constants.asm"

minus_sign db '-', 0

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
        push rsi
        push rax                ; push the character that we want to print onto the stack
        call string_length
        mov rdx, rax            ; save the length into rdx
        pop rsi                 ; get the address of the character back
        mov rdi, stdout
        mov rax, sys_write
        syscall
        pop rsi
        pop rbx
        pop rcx
        pop rdx
        ret

integer_print:
        push rax                ; RAX contains the value that we want to print
        push rcx
        push rdx
        push rdi
        push rsi
        xor rcx, rcx            ; counter of how many bytes we need to print in the end
        cmp rax, 0              ; first of all, check if it's a negative number
        jl .handle_minus
        jge .divide_loop

.handle_minus:
        push rax
        mov rax, minus_sign
        call string_print
        pop rax
        neg rax                 ; make the number positive now
        jmp .divide_loop

.divide_loop:
        inc rcx                 ; count each byte
        xor rdx, rdx
        mov rsi, 10
        idiv rsi                ; slow
        add rdx, 48             ; add '0' to the digit that we just extracted
        push rdx
        cmp rax, 0              ; did we finish?
        jnz .divide_loop

.print_loop:
        dec rcx
        mov rax, rsp
        call string_print
        pop rax
        cmp rcx, 0
        jnz .print_loop
        pop rsi
        pop rdi
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
