#pragma once

#ifdef _WIN32
    // Windows-specific includes
    #include <windows.h>
    #include <io.h>
    #include <fcntl.h>
    #include <sys/stat.h>
    
    // Windows equivalents for Unix functions
    #define open _open
    #define close _close
    #define read _read
    #define write _write
    #define lseek _lseek
    #define stat _stat
    
    // Memory mapping on Windows
    #include <memoryapi.h>
    #define PROT_READ PAGE_READONLY
    #define MAP_PRIVATE FILE_MAP_COPY
    #define MAP_SHARED FILE_MAP_READ
    
    // Windows doesn't have mmap, so we'll use file mapping
    void* mmap(void* addr, size_t length, int prot, int flags, int fd, off_t offset) {
        HANDLE fileHandle = (HANDLE)_get_osfhandle(fd);
        if (fileHandle == INVALID_HANDLE_VALUE) {
            return MAP_FAILED;
        }
        
        HANDLE mappingHandle = CreateFileMapping(fileHandle, NULL, PAGE_READONLY, 0, 0, NULL);
        if (mappingHandle == NULL) {
            return MAP_FAILED;
        }
        
        void* mappedData = MapViewOfFile(mappingHandle, FILE_MAP_READ, 0, offset, length);
        CloseHandle(mappingHandle);
        
        return mappedData ? mappedData : MAP_FAILED;
    }
    
    int munmap(void* addr, size_t length) {
        return UnmapViewOfFile(addr) ? 0 : -1;
    }
    
    #define MAP_FAILED ((void*)-1)
    
#else
    // Unix/Linux/macOS includes
    #include <sys/mman.h>
    #include <sys/stat.h>
    #include <sys/types.h>
    #include <fcntl.h>
    #include <unistd.h>
#endif

#include <string>
#include <vector>
#include <unordered_map> 