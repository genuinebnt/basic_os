ASM?=nasm

BUILD_DIR?=build/

.PHONY: all clean

all: ${BUILD_DIR}/kernel.bin

${BUILD_DIR}/kernel.bin:
	${ASM} kernel.asm -f bin -o ${BUILD_DIR}/kernel.bin

clean:
	rm -rf ${BUILD_DIR}/kernel.bin