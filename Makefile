ASM=nasm
CC=gcc

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image stage1 stage2 kernel clean always tools_fat

all: tools_fat floppy_image

# floppy image 
floppy_image: ${BUILD_DIR}/main_floppy.img

${BUILD_DIR}/main_floppy.img: stage1 stage2 kernel
	dd if=/dev/zero of=${BUILD_DIR}/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "BASICOS" ${BUILD_DIR}/main_floppy.img
	dd if=${BUILD_DIR}/stage1.bin of=${BUILD_DIR}/main_floppy.img conv=notrunc
	mcopy -i ${BUILD_DIR}/main_floppy.img ${BUILD_DIR}/stage2.bin "::stage2.bin"
	mcopy -i ${BUILD_DIR}/main_floppy.img ${BUILD_DIR}/kernel.bin "::kernel.bin"

# bootloader
bootloader: stage1 stage2

stage1: ${BUILD_DIR}/stage1.bin

${BUILD_DIR}/stage1.bin:
	${MAKE} -C ${SRC_DIR}/bootloader/stage1 BUILD_DIR=$(abspath ${BUILD_DIR})

stage2: ${BUILD_DIR}/stage2.bin

${BUILD_DIR}/stage2.bin:
	${MAKE} -C ${SRC_DIR}/bootloader/stage2 BUILD_DIR=$(abspath ${BUILD_DIR})

# kernel
kernel: ${BUILD_DIR}/kernel.bin

${BUILD_DIR}/kernel.bin: always
	${MAKE} -C ${SRC_DIR}/kernel BUILD_DIR=$(abspath ${BUILD_DIR})

tools_fat: ${BUILD_DIR}/tools/fat

${BUILD_DIR}/tools/fat:
	mkdir -p ${BUILD_DIR}/tools
	${CC} -g -o ${BUILD_DIR}/tools/fat ${SRC_DIR}/tools/fat/fat.c ${SRC_DIR}/tools/fat/utils.c


always: 
	mkdir -p ${BUILD_DIR}

clean:
	${MAKE} -C ${SRC_DIR}/bootloader/stage1 BUILD_DIR=$(abspath ${BUILD_DIR}) clean
	${MAKE} -C ${SRC_DIR}/bootloader/stage2 BUILD_DIR=$(abspath ${BUILD_DIR}) clean
	${MAKE} -C ${SRC_DIR}/kernel BUILD_DIR=$(abspath ${BUILD_DIR}) clean
	rm -rf ${BUILD_DIR}/*

