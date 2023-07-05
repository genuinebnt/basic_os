ASM=nasm
CC=gcc

SRC_DIR=src
BUILD_DIR=build

.PHONY: all floppy_image bootloader kernel clean always tools_fat

all: tools_fat floppy_image

# floppy image 
floppy_image: ${BUILD_DIR}/main_floppy.img

${BUILD_DIR}/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=${BUILD_DIR}/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "BASICOS" ${BUILD_DIR}/main_floppy.img
	dd if=${BUILD_DIR}/bootloader.bin of=${BUILD_DIR}/main_floppy.img conv=notrunc
	mcopy -i ${BUILD_DIR}/main_floppy.img ${BUILD_DIR}/kernel.bin "::kernel.bin"
	mcopy -i ${BUILD_DIR}/main_floppy.img text.txt "::text.txt"
# bootloader
bootloader: ${BUILD_DIR}/bootloader.bin

${BUILD_DIR}/bootloader.bin: always
	${ASM} ${SRC_DIR}/bootloader/bootloader.asm -f bin -o ${BUILD_DIR}/bootloader.bin

# kernel
kernel: ${BUILD_DIR}/kernel.bin

${BUILD_DIR}/kernel.bin: always
	${ASM} ${SRC_DIR}/kernel/kernel.asm -f bin -o ${BUILD_DIR}/kernel.bin

tools_fat: ${BUILD_DIR}/tools/fat

${BUILD_DIR}/tools/fat:
	mkdir -p ${BUILD_DIR}/tools
	${CC} -g -o ${BUILD_DIR}/tools/fat ${SRC_DIR}/tools/fat/fat.c ${SRC_DIR}/tools/fat/utils.c


always: 
	mkdir -p ${BUILD_DIR}

clean:
	rm -rf ${BUILD_DIR}

