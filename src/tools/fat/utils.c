#include "utils.h"

extern BootSector g_BootSector;
extern DirEntry *g_RootDirectory;

void print_bootsector() {
  printf("Bootsector:\n");
  printf("  BytesPerSector: %d\n", g_BootSector.BytesPerSector);
  printf("  SectorsPerCluster: %d\n", g_BootSector.SectorsPerCluster);
  printf("  ReservedSectors: %d\n", g_BootSector.ReservedSectors);
  printf("  FATCount: %d\n", g_BootSector.FATCount);
  printf("  DirEntryCount: %d\n", g_BootSector.DirEntryCount);
  printf("  TotalSectors: %d\n", g_BootSector.TotalSectors);
  printf("  MediaDescriptorType: %d\n", g_BootSector.MediaDescriptorType);
  printf("  SectorsPerFAT: %d\n", g_BootSector.SectorsPerFAT);
  printf("  SectorsPerTrack: %d\n", g_BootSector.SectorsPerTrack);
  printf("  HeadCount: %d\n", g_BootSector.HeadCount);
  printf("  HiddenSectors: %d\n", g_BootSector.HiddenSectors);
  printf("  LargeSectorCount: %d\n", g_BootSector.LargeSectorCount);
  printf("  DriveNumber: %d\n", g_BootSector.DriveNumber);
  printf("  Reserved: %d\n", g_BootSector.Reserved);
  printf("  BootSignature: %d\n", g_BootSector.BootSignature);
  printf("  VolumeID: %d\n", g_BootSector.VolumeID);
}

void print_root_dir_entries() {
  for (uint32_t i = 0; i < 5; i++) {
    DirEntry *entry = &g_RootDirectory[i];
    if ((strncmp("TEXT    TXT", (char *)entry->Name, 11) == 0)) {
      printf("Entry: %d\n", i + 1);
      printf("  FileName: %s\n", entry->Name);
      printf("  Attributes: %d\n", entry->Attributes);
      printf("  Reserved: %d\n", entry->Reserved);
      printf("  CreationTimeinTenth: %d\n", entry->CreationTimeinTenth);
      printf("  CreationTime: %d\n", entry->CreationTime);
      printf("  CreationDate: %d\n", entry->CreationDate);
      printf("  LastAccessedDate: %d\n", entry->LastAccessedDate);
      printf("  FirstClusterHigh: %d\n", entry->FirstClusterHigh);
      printf("  LastModificationTime: %d\n", entry->LastModificationTime);
      printf("  LastModificationDate: %d\n", entry->LastModificationDate);
      printf("  FirstClusterLow: %d\n", entry->FirstClusterLow);
      printf("  Size: %d\n", entry->Size);
    }
  }
}