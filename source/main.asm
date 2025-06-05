%include "syscalls.asm"
%include "constants.asm"
%include "string.asm"

%define ASCII_0 0x30
%define ASCII_9 0x39
%define NULL_BYTE 0x00
%define WHITESPACE 0x20
%define SYMBOL_ADD 0x2B
%define SYMBOL_MINUS 0x2D
%define SYMBOL_MULTIPLY 0x2A
%define SYMBOL_DIVIDE 0x2F
%define NEW_LINE 0x0A

SECTION .data
        prompt_character db ">>> ", 0h
        prompt_character_length equ $-prompt_character
        input_buffer times 256 db 0
        input_size equ 256
SECTION .bss
        is_negative resb 1      ; flag to know if the current number is negative or not
SECTION .text
global _start
_start:
        mov rax, sys_write      ; TODO: put this inside a loop.
        mov rdi, stdout
        mov rsi, prompt_character
        mov rdx, prompt_character_length
        syscall

        mov rax, sys_read       ; read user input (TODO: sanitize)
        mov rdi, stdin
        mov rsi, input_buffer
        mov rdx, input_size
        syscall

        xor rax, rax          ; accumulator
        xor rsi, rsi          ; base address of input buffer
        xor rcx, rcx          ; counter
        mov rsi, input_buffer ; position at the beginning of the buffer

.read_loop:
        xor rbx, rbx            ; we store the current digit here
        mov bl, [rsi + rcx]     ; move the current byte to BL

        cmp bl, NULL_BYTE       ; did we finish? aka hit a null terminator or newline
        je .finished
        cmp bl, NEW_LINE
        je .finished
        cmp bl, WHITESPACE      ; if there is a space, go to the next digit
        je .push_number         ; push current number onto the stack

        cmp bl, SYMBOL_ADD
        je .push_add_operator
        cmp bl, SYMBOL_MINUS ; we encountered a minus sign, need to be careful here
        je .handle_minus_sign
        cmp bl, SYMBOL_MULTIPLY
        je .push_multiply_operator
        cmp bl, SYMBOL_DIVIDE
        je .push_divide_operator

        cmp bl, ASCII_0         ; if the character isn't between [0-9] after checking operators then we finish (?)
        jl .finished
        cmp bl, ASCII_9
        jg .finished

        sub bl, ASCII_0         ; grab the decimal digit
        mov rdx, rax            ; save contents of rax
        mov rax, 10
        mul rdx                 ; rax *= 10 (123 = 1 * 100 + 2 * 20 + 3 * 1)
        movzx rbx, bl
        add rax, rbx
        inc rcx                 ; increment the counter
        jmp .read_loop

.handle_minus_sign:
        cmp rcx, 0              ; if it's at the start, then we know it's a number, so we just set the flag
        je .set_negative
        mov bl, [rsi + rcx - 2] ; get two bytes before, skipping the whitespace assuming it's well formed ofc
        cmp bl, SYMBOL_ADD
        je .push_minus_operator
        cmp bl, SYMBOL_MINUS
        je .push_minus_operator
        cmp bl, SYMBOL_MULTIPLY
        je .push_minus_operator
        cmp bl, SYMBOL_DIVIDE
        je .push_minus_operator
        ; TODO: I don't think this is a good idea
        mov bl, [rsi + rcx + 1] ; let's fetch the next byte and see if it's the end
        cmp bl, NEW_LINE
        je .push_minus_operator
        jmp .set_negative       ; this already increments the counter and jumps back to read loop

.set_negative:
        mov byte [is_negative], 1
        inc rcx
        jmp .read_loop

.push_add_operator:
        pop rax
        pop rbx
        add rax, rbx
        push rax
        inc rcx
        jmp .read_loop

.push_minus_operator:
        pop rbx
        pop rax
        sub rax, rbx            ; the second operand from the first one, aka, rax - rbx
        push rax
        inc rcx
        jmp .read_loop

.push_multiply_operator:
        pop rax
        pop rbx
        mul rbx
        push rax
        inc rcx
        jmp .read_loop

.push_divide_operator:          ; TODO: check division by zero
        pop rbx
        pop rax
        div rbx
        push rax
        inc rcx
        jmp .read_loop

.push_number:                   ; we can clean up this routine and push positive to avoid writing extra code I think
        cmp byte [is_negative], 1
        jne .push_positive
        neg rax
        mov byte [is_negative], 0
        push rax
        xor rax, rax
        inc rcx
        jmp .read_loop

.push_positive:
        push rax
        xor rax, rax
        inc rcx
        jmp .read_loop

.finished:
        pop rax
        call integer_print_line

        mov rax, sys_exit
        mov rdi, EXIT_SUCCESS
        syscall
