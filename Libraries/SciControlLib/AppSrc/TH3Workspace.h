// TH3Workspace.h
// on 12/03/2017 by Sergey V. Natarov

Use RegistryAPI.pkg

Global_Variable Integer ghoToolsPane
Global_Variable Integer ghoOutputPane
Global_Variable Integer ghoOutputDialog
Global_Variable Integer ghoEditorPopupMenu
Global_Variable Integer ghoCurrentFileTab
Global_Variable Integer ghoWorkspaceFilesTree
#IFNDEF ghoWorkSpaceHandlerEx
  Global_Variable Integer ghoWorkSpaceHandlerEx
#ENDIF

#IFNDEF gsComputerName
Global_Variable String gsComputerName
#ENDIF
#IFNDEF gsUserName
Global_Variable String gsUserName
#ENDIF
Global_Variable Integer ghoCompilerInfo
Global_Variable Integer ghoBuildMenu
Global_Variable String gsTransferWSFile
Global_Variable String gsTransferDDFile
Global_Variable String[] gILanguage

// The Hammer File Types
Define KPH_FILE_EDITABLE For 0
Define KPH_FILE_MENU     For 1
Define KPH_FILE_FOLDER   For 2

Struct tTHSource
    String  sFile
    String  sBookmarks
    Integer iBookmarkCount
    Integer iCursorLine
    Integer iCursorColumn
End_Struct

Struct tTHWorkspace
    String   sName
    String   sSchema
    Integer  iShowPaths
    String   sFullName
    String   sStudio
    String   sCompiler
    String   sDBEditor
    String   sDBViewer
    String   sFFText
    String   sFFTypes
    String   sFFPath
    Integer  iFFMatchWord
    Integer  iFFMatchCase
    Integer  iFFSubFolders
    Integer  iFFShowAll
    Integer  iFFExcludeComments
    Integer  iFFRegExp
    String[] saFiles
    String[] saFileDesc
    String[] saFolders
    String[] saExclude
    String[] saOpened
    tTHSource[] taSources
End_Struct

Struct tTHCompiler
    String sVersion
    String sProgID
    String sEventId
    Handle hoCompiler
End_Struct


// Language Definition
Struct tTHLanguage
    String      sName
    Integer     iProcedural
    Integer     iCaseSensitive
    String      sLineComments
    String      sStringDelimiter
    String      sMultiLineCommentStart
    String      sMultiLineCommentStop
    String      sEscapeChar
    String      sLineTerminationChar
    String      sMetaStart
    String      sMetaStop
    String[]    saScopeStart
    String[]    saScopeStop
    String[]    saKeywords
    String[]    saOperators
    String[]    saTags
    String[]    saEntities
    String[]    saAttributes
End_Struct

Struct tDFDefaultClasses
    String sCategory
    String sClass
    String sFile
End_Struct

Define TH_SCHEMA_DATAFLEX   for "DataFlex"
Define TH_SCHEMA_DELPHI     for "Delphi"
Define TH_SCHEMA_CCPP       for "C/C++"
Define TH_SCHEMA_PYTHON     for "Python"
Define TH_SCHEMA_WEB        for "Web"
Define TH_SCHEMA_OTHER      for "Other"


Function UCharToSHORT Global UChar[] Buffer Returns Integer
    Integer in1 in2
    
    Move 0 To in1
    If (SizeOfArray(Buffer)=2) Begin
      Move Buffer[0] To in1
      Move Buffer[1] To in2
      Move ( in1 + (in2*256) ) to in1
      If (in2 > 127) ;
          Move (in1 - 65536) to in1
    End
    Function_Return in1
End_Function


Function UCharToDWORD Global UChar[] Buffer Returns Integer
    Integer in1 in2 in3 in4
    
    Move 0 To in1
    If (SizeOfArray(Buffer)=4) Begin
      Move Buffer[0] To in1
      Move Buffer[1] To in2
      Move Buffer[2] To in3
      Move Buffer[3] To in4
      Move (in1 + (in2*256) + (in3*65536) + (in4*16777216)) to in1
    End
    Function_Return in1
End_Function

Function DWORDtoUChar Global Integer aDWORD Returns UChar[]
    UChar[] data
    Move (low(aDWORD) iand 255) To data[0]
    Move (low(aDWORD) / 256)    To data[1]
    Move (hi(aDWORD) iand 255)  To data[2]
    Move (hi(aDWORD) / 256)     To data[3]
    Function_Return data
End_Function

Function SHORTtoUChar Global Integer aSHORT Returns UChar[]
    UChar[] data
    Move ( aSHORT iand 255) To data[0]
    Move ( aSHORT / 256)    To data[1]
    Function_Return data
End_Function

// Upto 256 chars
Function WSReadStr1 Returns String
    String  sValue
    UChar   ucSize
    Integer iSize
    Read_Block ucSize 1
    Move ucSize to iSize
    If iSize ;
        Read_Block sValue iSize
    Function_Return sValue
End_Function

// Upto 65356 chars
Function WSReadStr2 Returns String
    String  sValue
    UChar[] ucaSize
    Integer iSize
    Read_Block ucaSize 2
    Move (UCharToSHORT(ucaSize)) to iSize
    If iSize ;
        Read_Block sValue iSize
    Function_Return sValue
End_Function

// Upto 2G chars
Function WSReadStr4 Returns String
    String  sValue
    UChar[] ucaSize
    Integer iSize
    Read_Block ucaSize 4
    Move (UCharToDWORD(ucaSize)) to iSize
    If iSize ;
        Read_Block sValue iSize
    Function_Return sValue
End_Function

// 0..256
Function WSReadInt1 Returns Integer
    UChar      ucValue
    Read_Block  ucValue 1
    Function_Return ucValue
End_Function

// 0..65536
Function WSReadInt2 Returns Integer
    UChar[]     ucaValue
    Read_Block  ucaValue 2
    Function_Return (UCharToSHORT(ucaValue))
End_Function

// 0..2G
Function WSReadInt4 Returns Integer
    UChar[]     ucaValue
    Read_Block  ucaValue 4
    Function_Return (UCharToDWORD(ucaValue))
End_Function

Procedure WSWriteStr1 String sValue
    UChar ucLen
    Move (Length(sValue)) To ucLen
    Write ucLen
    Write sValue
End_Procedure

Procedure WSWriteStr2 String sValue
    Write (SHORTtoUChar(Length(sValue)))
    Write sValue
End_Procedure

Procedure WSWriteStr4 String sValue
    Write (DWordtoUChar(Length(sValue)))
    Write sValue
End_Procedure

Function CheckType String sFile Returns Integer
    String sTemp sTmp
    Integer iPos
    Integer iType

    Move KPH_FILE_EDITABLE To iType
    Move sFile To sTemp
    While (Pos("\",sTemp)<>0)
        Move (Pos("\",sTemp)) To iPos
        Move (Left(sTemp,iPos)) To sTmp
        Move (Replace(sTmp,sTemp,"")) To sTemp
    Loop
    Move (Pos(".",sTemp)) To iPos
    If (iPos=0) Begin
        Move KPH_FILE_FOLDER To iType
    End  
    Function_Return iType
End_Function

