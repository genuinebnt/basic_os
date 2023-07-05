#include <assert.h>
#include <ctype.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t bool;
#define true 1
#define false 0

typedef struct {
    uint8_t BootJumpInstruction[3];
    uint8_t OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint16_t RootDirectoryEntryCount;
    uint16_t TotalSectorsInVolume;
    uint8_t MediaDescriptorType;
    uint16_t SectorCountPerFAT;
    uint16_t SectorCountPerTrack;
    uint16_t HeadCount;
    uint32_t HiddenSectorCount;
    uint32_t LargeSectorCount;
    uint8_t DriveNumberExt;
    uint8_t WindowsNTFlagsExt;
    uint8_t SignatureExt;
    uint8_t VolumeID;
    uint8_t PartitionNameExt[11];
    uint8_t SystemIDExt[8];
} __attribute__((packed)) BootSector;

typedef struct {
    uint8_t FileName[11];
    uint8_t Attributes;
    uint8_t Reserved;
    uint8_t CreationTimeInSecond;
    uint16_t CreatedTime;
    uint16_t CreatedDate;
    uint16_t AccessDate;
    uint16_t FirstClusterHigh;
    uint16_t ModificationTime;
    uint16_t ModificationDate;
    uint16_t FirstClusterLow;
    uint32_t SizeOfFile;
} __attribute__((packed)) DirectoryEntry;

BootSector g_BootSector;
DirectoryEntry* g_RootDirectory = NULL;
uint8_t* g_FAT = NULL;
uint32_t g_RootDirectoryEnd;

bool readBootSector(FILE* disk) {
    return fread(&g_BootSector, sizeof(BootSector), 1, disk) > 0;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* buffer) {
    bool ok = true;
    ok = ok && (fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(buffer, g_BootSector.BytesPerSector, count, disk) == count);
    return ok;
}

bool readFAT(FILE* disk) {
    g_FAT = (uint8_t*) malloc(g_BootSector.SectorCountPerFAT * g_BootSector.BytesPerSector);
    return readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorCountPerFAT, g_FAT);
}

bool readRootDirectory(FILE* disk) {
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.FatCount * g_BootSector.SectorCountPerFAT;;
    uint32_t size = sizeof(DirectoryEntry) * g_BootSector.RootDirectoryEntryCount;
    uint32_t sectors = (size + g_BootSector.BytesPerSector - 1) / g_BootSector.BytesPerSector;

    g_RootDirectoryEnd = lba + sectors;
    g_RootDirectory = (DirectoryEntry *) malloc(sectors * g_BootSector.BytesPerSector);
    
    return readSectors(disk, lba, sectors, g_RootDirectory);
}

DirectoryEntry* findFile(FILE* disk, char* fileName) {

    for (size_t i = 0; i < g_BootSector.RootDirectoryEntryCount; i++) {
        DirectoryEntry* entry = &g_RootDirectory[i];
        if (strncmp((char*)entry->FileName, fileName, 11) == 0) {
            return entry;
        }
    }

   return NULL;
}

bool readFile(FILE* disk, DirectoryEntry* entry, uint8_t* outputBuffer) {
    bool ok = true;
    uint16_t currentCluster = entry->FirstClusterLow;
    
    do{
        uint32_t lba = g_RootDirectoryEnd + (currentCluster - 2) * g_BootSector.SectorPerCluster;
        ok = ok && readSectors(disk, lba, g_BootSector.SectorPerCluster, outputBuffer);
        outputBuffer += g_BootSector.BytesPerSector * g_BootSector.SectorPerCluster;

        uint32_t fatIndex = (currentCluster * 3) / 2;
        if(currentCluster % 2 == 0) {
            currentCluster = (*(uint16_t*)(g_FAT + fatIndex)) & 0x0FFF;
        } else {
            currentCluster = (*(uint16_t*)(g_FAT + fatIndex)) >> 4;
        }

    } while(ok && currentCluster < 0x0FF8);

    return ok;
}

int main(int argc, char** argv) {
    if(argc < 3) {
        fprintf(stderr, "Usage: <script> <disk> <filename>");
        return -1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if(!disk) {
        fprintf(stderr, "Could not open disk file %s\n", argv[1]);
        return -2;
    }

    bool isSuccess = readBootSector(disk);
    if(!isSuccess) {
        fprintf(stderr, "Could not read boot sector");
        return -3;
    }

    if(!readRootDirectory(disk)) {
        fprintf(stderr, "Cannot read root directory");
        free(g_RootDirectory);
        free(g_FAT);
        return -4;
    }

    if(!readFAT(disk)) {
        fprintf(stderr, "Cannot read FAT");
        free(g_FAT);
        return -5;
    }

    DirectoryEntry* entry = findFile(disk, argv[2]);
    if(!entry) {
        fprintf(stderr, "File not found");
        free(g_RootDirectory);
        free(g_FAT);
        return -6;
    }

    uint8_t* outputBuffer = (uint8_t*) malloc(entry->SizeOfFile + g_BootSector.BytesPerSector);

    if(!readFile(disk, entry, outputBuffer)) {
        fprintf(stderr, "Cannot read file %s", argv[2]);
        free(outputBuffer);
        free(g_RootDirectory);
        free(g_FAT);
        return -7;
    }

    for(size_t i = 0; i < entry->SizeOfFile; i++) {
        if(isprint(outputBuffer[i])) fputc(outputBuffer[i], stdout);
        else printf("<%02x>", outputBuffer[i]);
    }

    free(outputBuffer);
    free(g_RootDirectory);
    free(g_FAT);
    return 0;
}