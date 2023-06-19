boot.img: boot
	cp build/boot.bin build/boot.img

boot:
	nasm src/boot.asm -f bin -o build/boot.bin