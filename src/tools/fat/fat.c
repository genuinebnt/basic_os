#include "fat.h"
#include "utils.h"
#include <ctype.h>

BootSector g_BootSector;
DirEntry *g_RootDirectory = NULL;
uint8_t *g_FAT = NULL;
uint32_t g_RootDirectoryEnd;

bool read_bootsector(FILE *disk) {
  bool ok = true;
  ok = ok && fread(&g_BootSector, sizeof(BootSector), 1, disk) == 1;
  return ok;
}

bool read_sectors(FILE *disk, uint32_t lba, uint32_t count,
                  void *outputBuffer) {
  bool ok = true;
  ok = ok && fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0;
  ok = ok &&
       fread(outputBuffer, g_BootSector.BytesPerSector, count, disk) == count;

  return ok;
}

bool read_root_directory(FILE *disk) {
  bool ok = true;

  uint32_t rootDirStart = g_BootSector.ReservedSectors +
                          (g_BootSector.FATCount * g_BootSector.SectorsPerFAT);

  uint32_t sectorCount = (sizeof(DirEntry) * g_BootSector.DirEntryCount +
                          (g_BootSector.BytesPerSector - 1)) /
                         g_BootSector.BytesPerSector;
  printf("%d\n", sectorCount);

  g_RootDirectoryEnd = rootDirStart + sectorCount;

  g_RootDirectory =
      (DirEntry *)malloc(sectorCount * g_BootSector.BytesPerSector);
  ok = ok && read_sectors(disk, rootDirStart, sectorCount, g_RootDirectory);
  return ok;
}

bool read_FAT(FILE *disk) {
  bool ok = true;

  g_FAT = (uint8_t *)malloc(g_BootSector.SectorsPerFAT *
                            g_BootSector.BytesPerSector);

  ok = ok && read_sectors(disk, g_BootSector.ReservedSectors,
                          g_BootSector.SectorsPerFAT, g_FAT);

  return ok;
}

DirEntry *findFile(FILE *disk, char *fileName) {
  for (uint32_t i = 0; i < g_BootSector.DirEntryCount; i++) {
    DirEntry *entry = &g_RootDirectory[i];
    if (strncmp((char *)entry->Name, fileName, 11) == 0) {
      return entry;
    }
  }

  return NULL;
}

bool readFile(FILE *disk, DirEntry *entry, uint8_t *outputBuffer) {
  bool ok = true;

  uint32_t currentCluster = entry->FirstClusterLow;

  do {
    uint32_t lba = g_RootDirectoryEnd +
                   ((currentCluster - 2) * g_BootSector.SectorsPerCluster);
    ok = ok &&
         read_sectors(disk, lba, g_BootSector.SectorsPerCluster, outputBuffer);
    outputBuffer +=
        g_BootSector.SectorsPerCluster * g_BootSector.BytesPerSector;

    uint32_t fatIndex = currentCluster + (currentCluster / 2);
    if (currentCluster & 0x0001) {
      currentCluster = (*(uint16_t *)&g_FAT[fatIndex]) >> 4;
    } else {
      currentCluster = (*(uint16_t *)&g_FAT[fatIndex]) & 0x0FFF;
    }

  } while (ok && currentCluster < 0x0FF8);

  return ok;
}

int main(int argc, char **argv) {
  if (argc < 3) {
    printf("Usage: <fat> <disk> <file>\n");
    return -1;
  }

  FILE *disk = fopen(argv[1], "rb");
  if (!disk) {
    printf("Could not open disk %s\n", argv[1]);
    return -2;
  }

  if (!read_bootsector(disk)) {
    printf("Could not read bootsector\n");
    return -3;
  } else {
    print_bootsector();
  };

  if (!read_root_directory(disk)) {
    printf("Could not read root directory\n");
    free(g_RootDirectory);
    return -4;
  } else {
    print_root_dir_entries();
  }

  if (!read_FAT(disk)) {
    printf("Could not read File allocation table\n");
    free(g_FAT);
    free(g_RootDirectory);
    return -5;
  }

  DirEntry *entry = findFile(disk, argv[2]);
  if (!entry) {
    printf("Cannot find file: %s\n", argv[2]);
    free(g_FAT);
    free(g_RootDirectory);
    return -6;
  }

  uint8_t *outputBuffer =
      (uint8_t *)malloc(entry->Size + g_BootSector.BytesPerSector);

  if (!readFile(disk, entry, outputBuffer)) {
    printf("Cannot read file");
    free(outputBuffer);
    free(g_FAT);
    free(g_RootDirectory);
    return -7;
  }

  for (uint32_t i = 0; i < entry->Size; i++) {
    if (isprint(outputBuffer[i])) {
      printf("%c", outputBuffer[i]);
    } else {
      printf("<%02x>", outputBuffer[i]);
    }
  }
  printf("\n");

  free(outputBuffer);
  free(g_FAT);
  free(g_RootDirectory);
  fclose(disk);
  return 0;
}