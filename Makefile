all:
	nasm -f elf64 source/main.asm -g -i source
	ld source/main.o -o main

run:
	./main

clean:
	rm main
