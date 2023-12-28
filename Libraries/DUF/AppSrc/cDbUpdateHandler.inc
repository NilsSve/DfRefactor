// Constant declarations, structs etc. for the cDbUdpateHandler class.
//
Use VdfBase.pkg
Use cApplication.pkg
Use seq_chnl.pkg
Use vWin32fh.pkg
Use DUFLanguageConstants.inc

Define CS_IntFilesTableRootName for "IntFilesTable"
Define CS_FilelistZipFile       for "FilelistBackupFile.zip"
Define CS_FilelistBackupFile    for "FilelistBackupFile.cfg"

Struct tDUFIntFile
    Integer iID
    String sIntFileName
    String sIntLineText
End_Struct

#IFNDEF _struct_tDbVersionInfo
Struct tDbVersionInfo
    Number nVersionNumber
    Handle hObject
End_Struct
#ENDIF

#IFNDEF _struct_tDbUpdateError
Struct tDbUpdateError
    Number nUpdateVersion
    Integer iError
    String  sOrgErrorText
    String  sErrorText
    Integer iErrorLine
    Boolean bError  
    Handle  hTable 
    String  sTableRootName
    Integer iField
    Boolean bShortFormat
End_Struct
#ENDIF

//  DF_FILE_ALIAS_DEFAULT if no master or alias
//  DF_FILE_IS_MASTER if master
//  DF_FILE_IS_ALIAS if alias
#IFNDEF _struct_tDbUpdateHandlerMasterAlias
Struct tDbUpdateHandlerMasterAlias
    Handle hTable
    Integer iMode
End_Struct
#ENDIF

// Used as a start for error handing. Used by Error_Report_Mode property
#IFNDEF DUF_ERROR_REPORT
Enumeration_List
    Define DUF_ERROR_REPORT    // Report Error on screen
    Define DUF_ERROR_NO_REPORT // Show no Error..
End_Enumeration_List
#ENDIF

#IFNDEF DATAFLEX_ID
    Define DATAFLEX_ID for "DATAFLEX"
#ENDIF

// Global handle to a cDatabaseUpdateHandler object that can be used to
// communicate with the object from anywhere in a program.
#IFNDEF ghoDbUpdateHandler
    Global_Variable Handle ghoDbUpdateHandler
    Move 0 to ghoDbUpdateHandler
#ENDIF

// NOTE: If the DbVersion table should _not_ be used and you
// instead set the "Set Data_File_Field to (RefTable(MyTable)) (RefTable(MyTable.DbUpdateVersion))"
// in the cDbUpdateHandler object; Add a "Define DUF_Use_DbVersion" to your code,
// _before_ the "Use cDbUpdateHandler.pkg" line.
//#IFNDEF DUF_Use_Custom_DbVersion
//    Declare_Datafile DbVersion
//#ENDIF
