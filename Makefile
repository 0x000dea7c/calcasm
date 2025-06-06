all:
	nasm -f elf64 -g source/main.asm -i source
	ld source/main.o -o main

run:
	./main

clean:
	rm main source/main.o
