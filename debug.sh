bochs -f bochs_config
#sudo apt install bochs bochs-sdl bochsbios vgabios#

#gdb -ix 'gdb_init_real_mode.txt' -ex 'target remote | qemu-system-i386 -S -gdb stdio -m 32 -fda build/main_floppy.img'  -ex 'break *0x7c00' -ex 'continue'
