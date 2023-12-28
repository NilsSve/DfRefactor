Use GlobalFunctionsProcedures.pkg
// Sample:
// Get DoSetDefaultPrinter "HP LaserJet 4" to bVoid


// Symbols used by UserCounting
#IFNDEF GENERIC_READ
    Define GENERIC_READ         for |CI$80000000
#ENDIF
#IFNDEF GENERIC_WRITE
    Define GENERIC_WRITE        for |CI$40000000
#ENDIF
#IFNDEF GENERIC_EXECUTE
    Define GENERIC_EXECUTE      for |CI$20000000
#ENDIF
#IFNDEF GENERIC_ALL
    Define GENERIC_ALL          for |CI$10000000
#ENDIF
#IFNDEF CREATE_NEW
    Define CREATE_NEW           for 1
#ENDIF
#IFNDEF CREATE_ALWAYS
    Define CREATE_ALWAYS        for 2
#ENDIF
#IFNDEF OPEN_EXISTING
    Define OPEN_EXISTING        for 3
#ENDIF
#IFNDEF OPEN_ALWAYS
    Define OPEN_ALWAYS          for 4
#ENDIF
#IFNDEF TRUNCATE_EXISTING
    Define TRUNCATE_EXISTING    for 5
#ENDIF
#IFNDEF INVALID_HANDLE_VALUE
    Define INVALID_HANDLE_VALUE for -1
#ENDIF
#IFNDEF FILE_BEGIN
    Define FILE_BEGIN           for 0
#ENDIF
#IFNDEF FILE_CURRENT
    Define FILE_CURRENT         for 1
#ENDIF
#IFNDEF FILE_END
    Define FILE_END             for 2
#ENDIF
#IFNDEF FILE_SHARE_READ
    Define FILE_SHARE_READ      for |CI$00000001
#ENDIF
#IFNDEF FILE_SHARE_WRITE
    Define FILE_SHARE_WRITE     for |CI$00000002
#ENDIF
#IFNDEF FILE_SHARE_DELETE
    Define FILE_SHARE_DELETE    for |CI$00000004
#ENDIF
#IFNDEF FILE_ATTRIBUTE_READONLY
    Define FILE_ATTRIBUTE_READONLY            for |CI$00000001
#ENDIF
#IFNDEF FILE_ATTRIBUTE_HIDDEN
    Define FILE_ATTRIBUTE_HIDDEN              for |CI$00000002
#ENDIF
#IFNDEF FILE_ATTRIBUTE_SYSTEM
    Define FILE_ATTRIBUTE_SYSTEM              for |CI$00000004
#ENDIF
#IFNDEF FILE_ATTRIBUTE_DIRECTORY
    Define FILE_ATTRIBUTE_DIRECTORY           for |CI$00000010
#ENDIF
#IFNDEF FILE_ATTRIBUTE_ARCHIVE
    Define FILE_ATTRIBUTE_ARCHIVE             for |CI$00000020
#ENDIF
#IFNDEF FILE_ATTRIBUTE_ENCRYPTED
    Define FILE_ATTRIBUTE_ENCRYPTED           for |CI$00000040
#ENDIF
#IFNDEF FILE_ATTRIBUTE_NORMAL
    Define FILE_ATTRIBUTE_NORMAL              for |CI$00000080
#ENDIF
#IFNDEF FILE_ATTRIBUTE_TEMPORARY
    Define FILE_ATTRIBUTE_TEMPORARY           for |CI$00000100
#ENDIF
#IFNDEF FILE_ATTRIBUTE_SPARSE_FILE
    Define FILE_ATTRIBUTE_SPARSE_FILE         for |CI$00000200
#ENDIF
#IFNDEF FILE_ATTRIBUTE_REPARSE_POINT
    Define FILE_ATTRIBUTE_REPARSE_POINT       for |CI$00000400
#ENDIF
#IFNDEF FILE_ATTRIBUTE_COMPRESSED
    Define FILE_ATTRIBUTE_COMPRESSED          for |CI$00000800
#ENDIF
#IFNDEF FILE_ATTRIBUTE_OFFLINE
    Define FILE_ATTRIBUTE_OFFLINE             for |CI$00001000
#ENDIF
#IFNDEF FILE_ATTRIBUTE_NOT_CONTENT_INDEXED
    Define FILE_ATTRIBUTE_NOT_CONTENT_INDEXED for |CI$00002000
#ENDIF
#IFNDEF FILE_FLAG_WRITE_THROUGH
    Define FILE_FLAG_WRITE_THROUGH            for |CI$80000000
#ENDIF
#IFNDEF _MAX_PATH
    Define _MAX_PATH  for 260
#ENDIF
#IFNDEF _MAX_DRIVE
    Define _MAX_DRIVE for 3
#ENDIF
#IFNDEF _MAX_DIR
    Define _MAX_DIR   for 256
#ENDIF
#IFNDEF _MAX_FNAME
    Define _MAX_FNAME for 256
#ENDIF
#IFNDEF _MAX_EXT
    Define _MAX_EXT   for 256
#ENDIF

#IFNDEF get_Win32_CreateFile
External_Function Win32_CreateFile "CreateFileA" KERNEL32.DLL ;
    Pointer lpFileName ;              // file name
    DWord dwDesiredAccess ;           // access mode
    DWord dwShareMode ;               // share mode
    Pointer lpSecurityAttributes ;    // SD
    DWord dwCreationDisposition ;     // how to create
    DWord dwFlagsAndAttributes ;      // file attributes
    Handle hTemplateFile ;            // handle to template file
    Returns Handle
#ENDIF

#IFNDEF get_Win32_ReadFile
External_Function Win32_ReadFile "ReadFile" KERNEL32.DLL ;
    Handle hFile ;                  // handle to file
    Pointer lpBuffer ;              // pointer to the buffer that receives the data
    dWord nNumberOfBytesToRead ;    // number of bytes to read
    Pointer lpNumberOfBytesRead ;   // number of bytes read
    Pointer lpOverlapped ;          // pointer to an overlapped structure
    Returns Integer
#ENDIF

#IFNDEF get_Win32_WriteFile
External_Function Win32_WriteFile "WriteFile" KERNEL32.DLL ;
    Handle hFile ;                      // handle to file
    Pointer lpBuffer ;                  // pointer to buffer containing data to write
    dWord nNumberOfBytesToWrite ;       // number of bytes to write
    Pointer lpNumberOfBytesWritten ;    // number of bytes written
    Pointer lpOverlapped ;              // pointer to an overlapped structure
    Returns Integer
#ENDIF

#IFNDEF get_Win32_LockFile
External_Function Win32_LockFile "LockFile" KERNEL32.DLL ;
    Handle hFile ;                      // handle to file
    dWord dwFileOffsetLow ;             // low-order word of startposition
    dWord dwFileOffsetHigh ;            // high-order word of startposition
    dWord nNumberOfBytesToLockLow ;     // low-order word of length
    dWord nNumberOfBytesToLockHigh ;    // high-order word of length
    Returns Integer
#ENDIF

#IFNDEF get_Win32_UnlockFile
External_Function Win32_UnlockFile "UnlockFile" KERNEL32.DLL ;
    Handle hFile ;                      // handle to file
    dWord dwFileOffsetLow ;             // low-order word of startposition
    dWord dwFileOffsetHigh ;            // high-order word of startposition
    dWord nNumberOfBytesToUnLockLow ;   // low-order word of length
    dWord nNumberOfBytesToUnLockHigh ;  // high-order word of length
    Returns Integer
#ENDIF

#IFNDEF get_Win32_SetFilePointer
External_Function Win32_SetFilePointer "SetFilePointer" KERNEL32.DLL ;
    Handle hFile ;                  // handle to file
    Integer lDistanceToMove ;       // bytes to move pointer (low-order 32-bits)
    Pointer lpDistanceToMoveHigh ;  // bytes to move pointer (high-order 32-bits)
    dWord dwMoveMethod ;            // starting point
    Returns dWord
#ENDIF

#IFNDEF get_Win32_CloseHandle
External_Function Win32_CloseHandle "CloseHandle" KERNEL32.DLL ;
    Handle hObject ;    // handle to object
    Returns Integer
#ENDIF

//#IFNDEF get_SetDefaultPrinterEf
//External_Function SetDefaultPrinterEf "SetDefaultPrinterA" winspool.drv Pointer lpPrinter Returns Boolean
//// Sample:
//// Get DoSetDefaultPrinter "HP LaserJet 4" to bVoid
//Function DoSetDefaultPrinter String sPrinter Returns Boolean
//    Boolean bReturn
//    Move (Utf8ToAnsi(sPrinter)) to sPrinter
//    Move (sPrinter + (Character(0))) to sPrinter
//    Move (SetDefaultPrinterEf(AddressOf(sPrinter))) to bReturn
//    Function_Return bReturn
//End_Function
//#ENDIF
