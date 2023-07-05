#ifndef FAT_H
#define FAT_H

#include <stdint.h>
#include <stdio.h>

typedef char bool;
#define true 1
#define false 0

typedef struct {
  uint8_t BootJmpInstruction[3];
  uint8_t OEMVersion[8];
  uint16_t BytesPerSector;
  uint8_t SectorsPerCluster;
  uint16_t ReservedSectors;
  uint8_t FATCount;
  uint16_t DirEntryCount;
  uint16_t TotalSectors;
  uint8_t MediaDescriptorType;
  uint16_t SectorsPerFAT;
  uint16_t SectorsPerTrack;
  uint16_t HeadCount;
  uint32_t HiddenSectors;
  uint32_t LargeSectorCount;
  uint8_t DriveNumber;
  uint8_t Reserved;
  uint8_t BootSignature;
  uint32_t VolumeID;
  uint8_t VolumeLabel[11];
  uint8_t SystemID[8];
} __attribute__((packed)) BootSector;

typedef struct {
  uint8_t Name[11];
  uint8_t Attributes;
  uint8_t Reserved;
  uint8_t CreationTimeinTenth;
  uint16_t CreationTime;
  uint16_t CreationDate;
  uint16_t LastAccessedDate;
  uint16_t FirstClusterHigh;
  uint16_t LastModificationTime;
  uint16_t LastModificationDate;
  uint16_t FirstClusterLow;
  uint32_t Size;
} __attribute__((packed)) DirEntry;

bool read_bootsector(FILE *disk);
bool read_sectors(FILE *disk, uint32_t lba, uint32_t count, void *outputBuffer);
bool read_root_directory(FILE *disk);
bool read_FAT(FILE* disk);
DirEntry* findFile(FILE* disk, char* fileName);
bool readFile(FILE* disk, DirEntry* entry, uint8_t* outputBuffer);

#endif