//TH-Header
//*****************************************************************************************
// Copyright (c)  2004 KURANT Project
// All rights reserved.
//
// $FileName    : G:\Projects\vWin32fh\vWin32fh.h
// $ProjectName : Windows 32 bits file handling
// $Authors     : Wil van Antwerpen
// $Created     : 19.02.2004  19:25
// $Type        : BSD (as in do with it whatever you like)
//
// Contents:
//  This file contains the Windows API external function call definitions and
//  constants as they are used in the vWin32fh package.
//*****************************************************************************************
//TH-RevisionStart
//TH-RevisionEnd

Define CS_DDE_ERR_FILE_NOT_FOUND  For "The specified file was not found.\n"
Define CS_DDE_ERR_PATH_NOT_FOUND  For "The specified path was not found.\n"
Define CS_DDE_ERR_BAD_FORMAT      For "The .EXE file is invalid.\n"
Define CS_DDE_ERR_ACCESSDENIED    For "The operating system denied access to the specified file.\n"
Define CS_DDE_ERR_ASSOCINCOMPLETE For "The filename association is incomplete or invalid.\n"
Define CS_DDE_ERR_DDEBUSY         For "The DDE transaction could not be completed because other DDE\ntransactions were being processed.\n"
Define CS_DDE_ERR_DDEFAIL         For "The DDE transaction failed.\n"
Define CS_DDE_ERR_DDETIMEOUT      For "The DDE transaction could not be completed,\nbecause the request timed out.\n"
Define CS_DDE_ERR_DLLNOTFOUND     For "The specified dynamic-link library was not found.\n"
Define CS_DDE_ERR_NOASSOC         For "There is no application associated with the given filename extension.\n"
Define CS_DDE_ERR_OOM             For "There is not enough free memory available to complete the operation.\n"
Define CS_DDE_ERR_PNF             For "The specified path was not found.\n"
Define CS_DDE_ERR_SHARE           For "A sharing violation occurred.\n"
Define CS_DDE_ERR_UNKNOWN_LINE1   For "Unknown DDE-error occurred.\nErrornumber"
Define CS_DDE_ERR_UNKNOWN_LINE2   For ".\n"
Define CS_DDE_ERR_HANDL_PAKTC     For "\nPress a key to continue...\n\n"
Define CS_DDE_ERR_HANDL_CAPTION   For "a DDE-error occurred"


Define vMax_Path     For |CI260
Define vMinChar      For |CI$80
Define vMaxChar      For |CI$7F
Define vMinShort     For |CI$8000
Define vMaxShort     For |CI$7FFF
Define vMinLong      For |CI$80000000
Define vMaxLong      For |CI$7FFFFFFF
Define vMaxByte      For |CI$FF
Define vMaxWord      For |CI$FFFF
Define vMaxDword     For |CI$FFFFFFFF



// For FindFirstFile
Define vINVALID_HANDLE_VALUE   For |CI-1
Define vINVALID_FILE_SIZE      For |CI$FFFFFFFF
Define vERROR_NO_MORE_FILES    For |CI18

// The defines below can be used to find out what kind of error has occurred if
// the API-call ShellExecute is used.
Define vERROR_FILE_NOT_FOUND   For |CI0002
Define vERROR_PATH_NOT_FOUND   For |CI0003
Define vERROR_BAD_FORMAT       For |CI0011
Define vSE_ERR_ACCESSDENIED    For |CI0005
Define vSE_ERR_ASSOCINCOMPLETE For |CI0027
Define vSE_ERR_DDEBUSY         For |CI0030
Define vSE_ERR_DDEFAIL         For |CI0029
Define vSE_ERR_DDETIMEOUT      For |CI0028
Define vSE_ERR_DLLNOTFOUND     For |CI0032
Define vSE_ERR_FNF             For |CI0002
Define vSE_ERR_NOASSOC         For |CI0031
Define vSE_ERR_OOM             For |CI0008
Define vSE_ERR_PNF             For |CI0003
Define vSE_ERR_SHARE           For |CI0026


// C-Structure
//typedef struct _browseinfo {
//    HWND hwndOwner;
//    LPCITEMIDLIST pidlRoot;
//    LPSTR pszDisplayName;
//    LPCSTR lpszTitle;
//    UINT ulFlags;
//    BFFCALLBACK lpfn;
//    LPARAM lParam;
//    int iImage;
//} BROWSEINFO, *PBROWSEINFO, *LPBROWSEINFO;

//declare C structure struct_browseinfo
//as documented in MSDN under Windows Shell API
Struct tvBrowseInfo
  Handle    hWndOwner
  Pointer   pIDLRoot
  Pointer   pszDisplayName
  Pointer   lpszTitle
  DWord     ulFlags
#IFDEF IS$WIN64
    DWord   BrowseInfoMissingAlignment1
#ENDIF
  Pointer   lpfnCallback
  LongPtr   lParam
  DWord     iImage
#IFDEF IS$WIN64
    DWord   BrowseInfoMissingAlignment2
#ENDIF
End_Struct // tvBrowseInfo

// Browsing for directory.
Define vBIF_RETURNONLYFSDIRS   For |CI$0001  // For finding a folder to start document searching
Define vBIF_DONTGOBELOWDOMAIN  For |CI$0002  // For starting the Find Computer
Define vBIF_STATUSTEXT         For |CI$0004  // Includes a status area in the dialog box.
                                            // The callback function can set the status text by
                                            // sending messages to the dialog box.
Define vBIF_RETURNFSANCESTORS  For |CI$0008  // Only returns file system ancestors.

Define vBIF_BROWSEFORCOMPUTER  For |CI$1000  // Browsing for Computers.
Define vBIF_BROWSEFORPRINTER   For |CI$2000  // Browsing for Printers

// message from browser
//Define BFFM_INITIALIZED        1
//Define BFFM_SELCHANGED         2

// messages to browser
//Define BFFM_SETSTATUSTEXT      (WM_USER + 100)
//Define BFFM_ENABLEOK           (WM_USER + 101)
//Define BFFM_SETSELECTION       (WM_USER + 102)


External_function vWin32_SHBrowseForFolder "SHBrowseForFolderW" shell32.dll ;
  Pointer lpsBrowseInfo Returns dWord

External_function vWin32_SHGetPathFromIDList "SHGetPathFromIDListW" shell32.dll ;
  Pointer pidList Pointer lpBuffer Returns dWord

External_function vWin32_CoTaskMemFree "CoTaskMemFree" ole32.dll Pointer pV Returns Integer




Struct tvSecurity_attributes
  DWord   nLength
#IFDEF IS$WIN64
    DWord   Security_attributesMissingAlignment1
#ENDIF
  Pointer lpDescriptor
  Integer bInheritHandle
#IFDEF IS$WIN64
    Integer Security_attributesMissingAlignment2
#ENDIF
End_Struct // tvSecurity_attributes

//nLength:
// Specifies the size, in bytes, of this structure. Set this value to the size of the
// SECURITY_ATTRIBUTES structure.
// Windows NT: Some functions that use the SECURITY_ATTRIBUTES structure do not verify the
// value of the nLength member. However, an application should still set it properly.
// That ensures current, future, and cross-platform compatibility.
//
//lpSecurityDescriptor:
// Points to a security descriptor for the object that controls the sharing of it.
// If NULL is specified for this member, the object may be assigned the default security
// descriptor of the calling process.
//
//bInheritHandle:
// Specifies whether the returned handle is inherited when a new process is created.
// If this member is TRUE, the new process inherits the handle.


// BOOL CreateDirectory(
//    LPCTSTR lpPathName,
//    LPSECURITY_ATTRIBUTES lpSecurityAttributes  // pointer to a security descriptor
//   );
//
// lpPathName
//  Points to a null-terminated string that specifies the path of the directory
//  to be created.
//  There is a default string size limit for paths of MAX_PATH characters.
//  This limit is related to how the CreateDirectory function parses paths.
// lpSecurityAttributes
//  Pointer to a SECURITY_ATTRIBUTES structure als called a security descriptor that
//  determines whether the returned handle can be inherited by child processes.
//  If lpSecurityAttributes is NULL, the handle cannot be inherited.
// Returns:
//  If the function succeeds, the return value is nonzero.
//  If the function fails, the return value is zero. To get extended error information, call GetLastError.
External_function vWin32_CreateDirectory "CreateDirectoryW" kernel32.dll ;
  WString sPathName Pointer lpSecurity_Attributes Returns Integer


// lpPathName
//  Points to a null-terminated string that specifies the path of the directory
//  to be removed.
//  There is a default string size limit for paths of MAX_PATH characters.
// Returns:
//  If the function succeeds, the return value is nonzero.
//  If the function fails, the return value is zero. To get extended error information, call GetLastError.
External_function vWin32_RemoveDirectory "RemoveDirectoryW" kernel32.dll ;
  WString sPathName Returns Integer



// The ShellExecute function opens or prints a specified file. The file can be an
// executable file or a document file.
//
// Operation can be one of the following:
//    "OPEN"  The function opens the file specified by lpFile.
//            The file can be an executable file or a document file.
//            The file can be a folder to open.
//    "PRINT" The function prints the file specified by lpFile.
//            The file should be a document file. If the file is an executable file,
//            the function opens the file, as if "open" had been specified.
//  "EXPLORE" The function explores the folder specified by lpFile.
//
// Return Values:
//
// If the function succeeds, the return value is the instance handle of the application that
// was run, or the handle of a dynamic data exchange (DDE) server application.
// If the function fails, the return value is an error value that is less than or equal to 32.
//
// The following table lists these error values:
// Public Const ERROR_FILE_NOT_FOUND = 2&
// Public Const ERROR_PATH_NOT_FOUND = 3&
// Public Const ERROR_BAD_FORMAT = 11&
// Public Const SE_ERR_ACCESSDENIED = 5
// Public Const SE_ERR_ASSOCINCOMPLETE = 27
// Public Const SE_ERR_DDEBUSY = 30
// Public Const SE_ERR_DDEFAIL = 29
// Public Const SE_ERR_DDETIMEOUT = 28
// Public Const SE_ERR_DLLNOTFOUND = 32
// Public Const SE_ERR_FNF = 2
// Public Const SE_ERR_NOASSOC = 31
// Public Const SE_ERR_OOM = 8
// Public Const SE_ERR_PNF = 3
// Public Const SE_ERR_SHARE = 26



// Code to open the program that is associated with the selected file.
//
// External function call used in Procedure DoStartDocument
External_function vWin32_ShellExecute "ShellExecuteW" shell32.dll ;
  Handle  hWnd ;
  WString wsOperation ;
  WString wsFile ;
  WString wsParameters ;
  WString wsDirectory ;
  Dword   iShowCmd Returns Handle



#IFDEF vFO_MOVE
#ELSE

Define vFO_MOVE                For |CI$0001
Define vFO_COPY                For |CI$0002
Define vFO_DELETE              For |CI$0003
Define vFO_RENAME              For |CI$0004

Define vFOF_MULTIDESTFILES     For |CI$0001
Define vFOF_CONFIRMMOUSE       For |CI$0002
Define vFOF_SILENT             For |CI$0004  // don't create progress/report
Define vFOF_RENAMEONCOLLISION  For |CI$0008
Define vFOF_NOCONFIRMATION     For |CI$0010  // Don't prompt the user.
Define vFOF_WANTMAPPINGHANDLE  For |CI$0020  // Fill in SHFILEOPSTRUCT.hNameMappings
                                          // Must be freed using SHFreeNameMappings
Define vFOF_ALLOWUNDO          For |CI$0040
Define vFOF_FILESONLY          For |CI$0080  // on *.*, do only files
Define vFOF_SIMPLEPROGRESS     For |CI$0100  // means don't show names of files
Define vFOF_NOCONFIRMMKDIR     For |CI$0200  // don't confirm making any needed dirs

Struct tvShFileOpStruct
  Handle   hWnd
  UInteger wFunc
#IFDEF IS$WIN64
    UInteger ShFileOpStructMissingAlignment1
#ENDIF
  Pointer  pFrom
  Pointer  pTo
  Short    fFlags
  Integer  fAnyOperationsAborted
#IFDEF IS$WIN64
    Short  ShFileOpStructMissingAlignment2
#ENDIF
  Pointer  hNameMappings
  Pointer  lpszProgressTitle      // only used if FOF_SIMPLEPROGRESS
End_Struct // tvShFileOpStruct

// hwnd
//   Handle of the dialog box to use to display information about the status of the operation.

// wFunc
//   Operation to perform. This member can be one of the following values:
//     FO_COPY     Copies the files specified by pFrom to the location specified by pTo.
//     FO_DELETE   Deletes the files specified by pFrom (pTo is ignored).
//     FO_MOVE     Moves the files specified by pFrom to the location specified by pTo.
//     FO_RENAME   Renames the files specified by pFrom.

// pFrom
//   Pointer to a buffer that specifies one or more source file names. Multiple names must
//   be null-separated. The list of names must be double null-terminated.

// pTo
//   Pointer to a buffer that contains the name of the destination file or directory. The
//   buffer can contain mutiple destination file names if the fFlags member specifies
//   FOF_MULTIDESTFILES. Multiple names must be null-separated. The list of names must be
//   double null-terminated.

// fAnyOperationsAborted
//   Value that receives TRUE if the user aborted any file operations before they
//   were completed or FALSE otherwise.

#ENDIF

// Performs a copy, move, rename, or delete operation on a file system object.
// This can be a file or a folder.
// With thanks to Andrew S Kaplan
External_function vWin32_SHFileOperation "SHFileOperationW" Shell32.dll ;
        Pointer lpFileOp Returns Integer


// Thanks To Oliver Nelson for posting this code on the newsgroups
External_function vWin32_GetWindowsDirectory "GetWindowsDirectoryW" kernel32.dll ;
                           Pointer lpBuffer Integer nSize Returns Integer



// Courtesy Of Vincent Oorsprong
//External_Function vWin32_GetTempFileName "GetTempFileNameA" Kernel32.Dll ;
//   Pointer lpPathName ;
//   Pointer lpPrefixString ;
//   Integer uUnique ;
//   Pointer lpTempFileName ;
//   Returns Integer
// **WvA: 28-04-2005 Changed string parameter type into pointers
External_function vWin32_GetTempFileName "GetTempFileNameW" kernel32.dll WString sPath ;
        WString sPrefix Integer iUnique Pointer lpTempFileName Returns Integer

External_function vWin32_GetTempPath "GetTempPathW" Kernel32.Dll ;
   Dword nBufferLength ;
   Pointer lpBuffer ;
   Returns Integer

External_function vWin32_DeleteFile "DeleteFileW" Kernel32.Dll ;
   WString sFileName ;
   Returns Integer

// from:
// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/enums/csidl.asp
//
Define vCSIDL_FLAG_CREATE       For |CI$8000 // IE5+, use this to create a special folder
Define vCSIDL_ADMIN_TOOLS       For |CI$0030 // IE5+, The file system directory that is used to store administrative tools for an individual user
Define vCSIDL_ALT_STARTUP       For |CI$001D // The file system directory that corresponds to the user's nonlocalized Startup program group
Define vCSIDL_APPDATA           For |CI$001A // Version 4.71. The file system directory that serves as a common repository for application-specific data. A typical path is C:\Documents and Settings\<username>\Application Data
Define vCSIDL_BITBUCKET         For |CI$000A // The virtual folder containing the objects in the user's Recycle Bin
Define vCSIDL_CDBURN_AREA       For |CI$003B // IE6+ The file system directory acting as a staging area for files waiting to be written to CD. A typical path is C:\Documents and Settings\<username>\Local Settings\Application Data\Microsoft\CD Burning
Define vCSIDL_COMMON_ADMINTOOLS For |CI$002F // IE5+ The file system directory containing administrative tools for all users of the computer
Define vCSIDL_COMMON_ALTSTARTUP For |CI$001E // The file system directory that corresponds to the nonlocalized Startup program group for all users
Define vCSIDL_COMMON_APPDATA    For |CI$0023 // IE5+ The file system directory containing application data for all users. A typical path is C:\Documents and Settings\All Users\Application Data
Define vCSIDL_COMMON_DESKTOPDIRECTORY for |CI$0019 // WinNT+ Only, The file system directory that contains files and folders that appear on the desktop for all users. A typical path is C:\Documents and Settings\All Users\Desktop
Define vCSIDL_COMMON_DOCUMENTS  For |CI$002E // IE5+ The file system directory that contains documents that are common to all users. A typical paths is C:\Documents and Settings\All Users\Documents
Define vCSIDL_COMMON_FAVORITES  For |CI$001F // The file system directory that serves as a common repository for favorite items common to all users
Define vCSIDL_COMMON_MUSIC      For |CI$0035 // IE6+ The file system directory that serves as a repository for music files common to all users. A typical path is C:\Documents and Settings\All Users\Documents\My Music
Define vCSIDL_COMMON_PICTURES   For |CI$0036 // The file system directory that serves as a repository for image files common to all users. A typical path is C:\Documents and Settings\All Users\Documents\My Pictures
Define vCSIDL_COMMON_PROGRAMS   For |CI$0017 // WinNT+ The file system directory that contains the directories for the common program groups that appear on the Start menu for all users. A typical path is C:\Documents and Settings\All Users\Start Menu\Programs
Define vCSIDL_COMMON_STARTMENU  For |CI$0016 // WinNT+ The file system directory that contains the programs and folders that appear on the Start menu for all users. A typical path is C:\Documents and Settings\All Users\Start Menu
Define vCSIDL_COMMON_STARTUP    For |CI$0018 // WinNT+ The file system directory that contains the programs that appear in the Startup folder for all users. A typical path is C:\Documents and Settings\All Users\Start Menu\Programs\Startup
Define vCSIDL_COMMON_TEMPLATES  For |CI$002D // WinNT+ The file system directory that contains the templates that are available to all users. A typical path is C:\Documents and Settings\All Users\Templates
Define vCSIDL_COMMON_VIDEO      For |CI$0037 // IE6+ The file system directory that serves as a repository for video files common to all users. A typical path is C:\Documents and Settings\All Users\Documents\My Videos
Define vCSIDL_COMPUTERSNEARME   For |CI$003D // The folder representing other machines in your workgroup
Define vCSIDL_CONNECTIONS       For |CI$0031 // The virtual folder representing Network Connections, containing network and dial-up connections
Define vCSIDL_CONTROLS          For |CI$0003 // The virtual folder containing icons for the Control Panel applications
Define vCSIDL_COOKIES           For |CI$0021 // The file system directory that serves as a common repository for Internet cookies. A typical path is C:\Documents and Settings\username\Cookies
Define vCSIDL_DESKTOP           For |CI$0000 // The virtual folder representing the Windows desktop, the root of the namespace
Define vCSIDL_DESKTOPDIRECTORY  For |CI$0010 // The file system directory used to physically store file objects on the desktop (not to be confused with the desktop folder itself). A typical path is C:\Documents and Settings\username\Desktop
Define vCSIDL_DRIVES            For |CI$0011 // The virtual folder representing My Computer, containing everything on the local computer: storage devices, printers, and Control Panel. The folder may also contain mapped network drives
Define vCSIDL_FAVORITES         For |CI$0006 // The file system directory that serves as a common repository for the user's favorite items. A typical path is C:\Documents and Settings\username\Favorites
Define vCSIDL_FONTS             For |CI$0014 // A virtual folder containing fonts. A typical path is C:\Windows\Fonts
Define vCSIDL_HISTORY           For |CI$0022 // The file system directory that serves as a common repository for Internet history items
Define vCSIDL_INTERNET          For |CI$0001 // A virtual folder representing the Internet
Define vCSIDL_INTERNET_CACHE    For |CI$0020 // Comctl4.72+, The file system directory that serves as a common repository for temporary Internet files. A typical path is C:\Documents and Settings\username\Local Settings\Temporary Internet Files
Define vCSIDL_LOCAL_APPDATA     For |CI$001C // IE5+ The file system directory that serves as a data repository for local (nonroaming) applications. A typical path is C:\Documents and Settings\username\Local Settings\Application Data
Define vCSIDL_MYDOCUMENTS       For |CI$000C // IE6+ The virtual folder representing the My Documents desktop item
Define vCSIDL_MYMUSIC           For |CI$000D // The file system directory that serves as a common repository for music files. A typical path is C:\Documents and Settings\User\My Documents\My Music
Define vCSIDL_MYPICTURES        For |CI$0027 // IE5+ The file system directory that serves as a common repository for image files. A typical path is C:\Documents and Settings\username\My Documents\My Pictures
Define vCSIDL_MYVIDEO           For |CI$000E // IE6+ The file system directory that serves as a common repository for video files. A typical path is C:\Documents and Settings\username\My Documents\My Videos
Define vCSIDL_NETHOOD           For |CI$0013 // A file system directory containing the link objects that may exist in the My Network Places virtual folder. It is not the same as CSIDL_NETWORK, which represents the network namespace root. A typical path is C:\Documents and Settings\username\NetHood
Define vCSIDL_NETWORK           For |CI$0012 // A virtual folder representing Network Neighborhood, the root of the network namespace hierarchy
Define vCSIDL_PERSONAL          For |CI$0005 // (Documents folder) IE6 The virtual folder representing the My Documents desktop item.
                                             // This is equivalent to CSIDL_MYDOCUMENTS. Previous to Version 6.0. The file system directory used to physically store a user's common repository of documents. A typical path is C:\Documents and Settings\username\My Documents
Define vCSIDL_PHOTOALBUMS       For |CI$0045 // Vista+ The virtual folder used to store photo albums, typically username\My Pictures\Photo Albums
Define vCSIDL_PLAYLISTS         For |CI$003F // Vista+ The virtual folder used to store play albums, typically username\My Music\Playlists
Define vCSIDL_PRINTERS          For |CI$0004 // The virtual folder containing installed printers
Define vCSIDL_PRINTHOOD         For |CI$001B // The file system directory that contains the link objects that can exist in the Printers virtual folder. A typical path is C:\Documents and Settings\username\PrintHood
Define vCSIDL_PROFILE           For |CI$0028 // IE5+ The user's profile folder. A typical path is C:\Documents and Settings\username
Define vCSIDL_PROGRAM_FILES     For |CI$0026 // IE5+ The Program Files folder. A typical path is C:\Program Files
Define vCSIDL_PROGRAM_FILESx86  for |CI$002A // The Program Files folder for x86 programs. A typical path is C:\Program Files (x86)
Define vCSIDL_PROGRAM_FILES_COMMON For |CI$002B // IE5+, WinNT+ A folder for components that are shared across applications. A typical path is C:\Program Files\Common
Define vCSIDL_PROGRAMS          For |CI$0002 // The file system directory that contains the user's program groups (which are themselves file system directories). A typical path is C:\Documents and Settings\username\Start Menu\Programs
Define vCSIDL_RECENT            For |CI$0008 // The file system directory that contains shortcuts to the user's most recently used documents. A typical path is C:\Documents and Settings\username\My Recent Documents
Define vCSIDL_RESOURCES         For |CI$0038 // undocumented
Define vCSIDL_SAMPLE_MUSIC      For |CI$0040 // Vista+, The file system directory that contains sample music. A typical path is C:\Documents and Settings\username\My Documents\My Music\Sample Music
Define vCSIDL_SAMPLE_PLAYLISTS  For |CI$0041 // Vista+, The file system directory that contains sample playlists. A typical path is C:\Documents and Settings\username\My Documents\My Music\Sample Playlists
Define vCSIDL_SAMPLE_PICTURES   For |CI$0042 // Vista+, The file system directory that contains sample pictures. A typical path is C:\Documents and Settings\username\My Documents\My Pictures\Sample Pictures
Define vCSIDL_SAMPLE_VIDEOS     For |CI$0043 // Vista+, The file system directory that contains sample videos. A typical path is C:\Documents and Settings\username\My Documents\My Videos\Sample Videos
Define vCSIDL_SENDTO            For |CI$0009 // The file system directory that contains Send To menu items. A typical path is C:\Documents and Settings\username\SendTo
Define vCSIDL_STARTMENU         For |CI$000B // The file system directory containing Start menu items. A typical path is C:\Documents and Settings\username\Start Menu
Define vCSIDL_STARTUP           For |CI$0007 // The file system directory that corresponds to the user's Startup program group. The system starts these programs whenever any user logs onto Windows NT or starts Windows 95. A typical path is C:\Documents and Settings\username\Start Menu\Programs\Startup
Define vCSIDL_SYSTEM            For |CI$0025 // The Windows System folder. A typical path is C:\Windows\System32
Define vCSIDL_SYSTEMX86         For |CI$0029 //
Define vCSIDL_TEMPLATES         For |CI$0015 // The file system directory that serves as a common repository for document templates. A typical path is C:\Documents and Settings\username\Templates
Define vCSIDL_WINDOWS           For |CI$0024 // The Windows directory or SYSROOT. This corresponds to the %windir% or %SYSTEMROOT% environment variables. A typical path is C:\Windows


//HRESULT SHGetFolderPath(
//    HWND hwndOwner,
//    int nFolder,
//    HANDLE hToken,
//    DWORD dwFlags,
//    LPTSTR pszPath
//);
// This function is a superset of SHGetSpecialFolderPath, included with earlier versions of
// the shell. It is implemented in a redistributable DLL, SHFolder.dll, that also simulates
// many of the new shell folders on older platforms such as Windows 95, Windows 98, and
// Windows NT 4.0. This DLL always calls the current platform's version of this function.
// If that fails, it will try to simulate the appropriate behavior.
//
External_function vWin32_SHGetFolderPath "SHGetFolderPathW" SHFolder.Dll ;
   Pointer hWnd ;
   Integer nFolder ;
   Pointer hToken ;
   DWord   dwFlags ;
   Pointer lpszPath ;
   Returns Integer



Struct tvWin32FindData
 Dword            dwFileAttributes
 Dword            ftCreationLowDateTime
 Dword            ftCreationHighDateTime
 dword            ftLastAccessLowDateTime
 Dword            ftLastAccessHighDateTime
 Dword            ftLastWriteLowDateTime
 Dword            ftLastWriteHighDateTime
 Dword            nFileSizeHigh
 Dword            nFileSizeLow
 Dword            dwReserved0
 Dword            dwReserved1
 Short[vMax_Path] cFileName
 Short[14]        cAlternateFileName
End_Struct

// Courtesy Of Vincent Oorsprong
// lpFileName      : address of name of file to search for
// lpFindFileData  : address of returned information
External_function vWin32_FindFirstFile "FindFirstFileW"  Kernel32.dll WString sFileName ;
          Pointer lpFindFileData Returns Handle

// Courtesy Of Vincent Oorsprong
// hFindFile       : handle of search
// lpFindFileData  : address of structure for data on found file
External_function vWin32_FindNextFile "FindNextFileW" Kernel32.dll Handle hFindFile ;
          Pointer lpFindFileData Returns Integer


// Courtesy Of Vincent Oorsprong
//  hFindFile      : file search handle
External_function vWin32_FindClose "FindClose" Kernel32.dll Handle hFindFile Returns Integer



Struct tvFileTime
  DWord dwLowDateTime
  DWord dwHighDateTime
End_Struct


Struct tvSystemTime
  UShort wYear
  UShort wMonth
  UShort wDayOfWeek
  UShort wDay
  UShort wHour
  UShort wMinute
  UShort wSecond
  UShort wMilliSeconds
End_Struct


// Courtesy Of Vincent Oorsprong
//  lpFileTime     : pointer to file time to convert
//  lpSystemTime   : pointer to structure to receive system time
External_function vWin32_FileTimeToSystemTime "FileTimeToSystemTime" Kernel32.Dll ;
          Pointer lpFileTime Pointer lpsystemTime Returns Integer

// Courtesy Of Vincent Oorsprong
// This function formats the time in a picture-string passed
//
// Picture      Meaning
//    h         Hours with no leading zero for single-digit hours; 12-hour clock
//    hh        Hours with leading zero for single-digit hours; 12-hour clock
//    H         Hours with no leading zero for single-digit hours; 24-hour clock
//    HH        Hours with leading zero for single-digit hours; 24-hour clock
//    m         Minutes with no leading zero for single-digit minutes
//    mm        Minutes with leading zero for single-digit minutes
//    s         Seconds with no leading zero for single-digit seconds
//    ss        Seconds with leading zero for single-digit seconds
//    t         One character time marker string, such as A or P
//    tt        Multicharacter time marker string, such as AM or PM
//
// For example, to get the time string  "11:29:40 PM"
//    use the following picture string: "hh" : "mm" : "ss tt"

External_function vWin32_GetTimeFormat "GetTimeFormatW" Kernel32.Dll ;
  Dword LCID Dword dwFlags Pointer lpsSystemTime Pointer lpFormat Pointer lpTimeStr ;
  Integer cchTime Returns Integer


// Courtesy Of Vincent Oorsprong
// This function formats the date in a picture-string passed
//
// Picture      Meaning
//    d         Day of month as digits with no leading zero for single-digit days.
//    dd        Day of month as digits with leading zero for single-digit days.
//    ddd       Day of week as a three-letter abbreviation. The function uses the
//              LOCALE_SABBREVOAYMAME value associated with the specified locale.
//    dddd      Day of week as its full name. The function uses the LOCALE_SDAYNAME
//              value associated with the specified locale.
//    M         Month as digits with no leading zero for single-digit months.
//    MM        Month as digits with leading zero for single-digit months.
//    MMM       Month as a three-letter abbreviation. The function uses the
//              LOCALE_SABBREVMONTHNAME value associated with the specified locale.
//    MMMM      Month as its full name. The function uses the LOCALE_SMONTHNAME value
//              associated with the specified locale.
//    y         Year as last two digits, but with no leading zero for years less than 10.
//    yy        Year as last two digits, but with leading zero for years less than 10.
//    yyyy      Year represented hy full four digits.
//    gg        Period/era string. The function uses the CAL_SERASTRING value associated
//              with the specified locale. This element is ignored if the date to be formatted
//              does not have an associated era or period string.
// For example, to get the date string  "Wed, Aug 31 94"
// use the following picture string:    "ddd","MMM dd yy"

External_function vWin32_GetDateFormat "GetDateFormatW" Kernel32.Dll ;
  Dword LCID Dword dwFlags Pointer lpsSystemTime Pointer lpFormat Pointer lpDateStr ;
  Integer cchDate Returns Integer

Define LOCALE_NOUSEROVERRIDE    For |CI$80000000  //  do not use user overrides
Define TIME_NOMIHUTESORSECONDS  For |CI$00000001  //  do not use minutes or seconds
Define TIME_NOSECONDS           For |CI$00000002  //  do not use seconds
Define TIME_NOTIMEMARKER        For |CI$00000004  //  do not use time marker
Define TIME_FORCE24HOURFORMAT   For |CI$00000008  //  always use 24 hour format

//  Date Flags for GetDateFormatW.
//
Define DATE_SHORTDATE           For |CI$00000001  //  use short date picture
Define DATE_LONGDATE            For |CI$00000002  //  use long date picture
Define DATE_USE_ALT_CALENDAR    For |CI$00000004  //  use alternate calendar (if any)


External_function vWin32_SetLastError "SetLastError" Kernel32.Dll Dword dwLastError Returns Integer


// **WvA: 20-02-2004
// While i was testing the format capabilities i stumbled over a very
// weird problem where it looks like that the integer value gets somehow translated
// incorrectly into an unsigned integer.
// I don't have the time to dive into this.. so added a workaround (and removed it again)
// It does smell a bit fishy though
// Tested it with the same results on both VDF7 and VDF9.1

Define SHFMT_ID_DEFAULT        For |CI$0000FFFF // The default format ID
Define SHFMT_OPT_DEFAULT       For |CI$00000000 // The default "Quick Format" option.
Define SHFMT_OPT_FULL          For |CI$00000001 // Deselects the "Quick Format" option, providing a full format instead. This is useful when an unformatted disk is detected.
Define SHFMT_OPT_SYSONLY       For |CI$00000002 // Selects the "Create an MS-DOS startup disk" option, creating a system boot disk.

// Possible errors that can be returned by the shellformat function
Define SHFMT_ERROR             For (|CI$FFFFFFFF+1) // An error occurred during the last format or no drive parameter passed. This does not indicate that the disk is unformatable.
Define SHFMT_CANCEL            For (|CI$FFFFFFFE+1) // The last format was canceled.
Define SHFMT_NOFORMAT          For (|CI$FFFFFFFD+1) // The drive cannot be formatted.


 // Courtesy Of Steve Walter,
 // USA Software, Inc
 // Format a disk
 // Called By:  Move (vWin32_ShFormatDrive(hWnd,0,$FFFF,1)) To dwReturn
External_function vWin32_ShFormatDrive "SHFormatDrive" shell32.dll Handle hWnd ;
         Integer iDrive Integer iFormatID Integer iOptions Returns DWORD

// Michael Mullan.  I Wanted to create all the folders in one statement...

// SHCreateDirectoryEx

//    Note  This function is available through Microsoft Windows XP Service Pack 2 (SP2) and Windows Server 2003.
//    It might be altered or unavailable in subsequent versions of Windows.
//
//    This function creates a file system folder whose fully qualified path is given by pszPath. If one or more
//    of the intermediate folders do not exist, they are created as well. SHCreateDirectoryEx also verifies that
//    the files are visible. If they are not visible, expect one of the following:
//
//        * If hwnd is set to a valid window handle, a message box is displayed warning the user that he or she
//        might not be able to access the files. If the user chooses not to proceed, the function returns
//        ERROR_CANCELLED.
//        * If hwnd is set to NULL, no user interface is displayed and the function returns ERROR_CANCELLED.

//        Returns ERROR_SUCCESS if successful. If the operation fails, other error codes can be returned,
//        including those listed here. For values not specifically listed, see System Error Codes.
//      161  ERROR_BAD_PATHNAME                The pszPath parameter was set to a relative path.
//      206  ERROR_FILENAME_EXCED_RANGE     The path pointed to by pszPath is too long.
//      3    ERROR_PATH_NOT_FOUND            The system cannot find the path pointed to by pszPath. The path may contain an invalid entry.
//      80   ERROR_FILE_EXISTS                The directory exists.
//      183  ERROR_ALREADY_EXISTS            The directory exists.
//      1223 ERROR_CANCELLED                The user canceled the operation.

//        int SHCreateDirectoryEx(
//            HWND hwnd,
//            LPCTSTR pszPath,
//            const SECURITY_ATTRIBUTES *psa
//        );

External_function vWin32_SHCreateDirectoryEx "SHCreateDirectoryExW" shell32.dll Handle hWnd;
                  WString wPath  Pointer lpSecurity_Attributes Returns Integer

#IFNDEF GET_vWin32_PathIsDirectory
 External_Function vWin32_PathIsDirectory "PathIsDirectoryW" SHLWAPI.DLL WString wPath Returns Integer
#ENDIF
