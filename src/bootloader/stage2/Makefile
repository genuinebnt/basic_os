ASM?=nasm

BUILD_DIR?=build/

.PHONY: all clean

all: ${BUILD_DIR}/stage2.bin

${BUILD_DIR}/stage2.bin:
	${ASM} stage2.asm -f bin -o ${BUILD_DIR}/stage2.bin

clean:
	rm -rf ${BUILD_DIR}/stage2.bin