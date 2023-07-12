ASM?=nasm

BUILD_DIR?=build/

.PHONY: all clean

all: ${BUILD_DIR}/stage1.bin

${BUILD_DIR}/stage1.bin:
	${ASM} stage1.asm -f bin -o ${BUILD_DIR}/stage1.bin

clean:
	rm -rf ${BUILD_DIR}/stage1.bin