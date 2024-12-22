// Copyright (c) 2018 Nils Svedmyr, RDC Tools International
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to Use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to Do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in All
// copies or substantial portions of the Software.
//
// THE SOFTWARE is PROVIDED "AS IS", WITHOUT WARRANTY of ANY KIND, EXPRESS or
// IMPLIED, INCLUDING BUT not LIMITED to THE WARRANTIES of MERCHANTABILITY,
// FITNESS for a PARTICULAR PURPOSE and NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS or COPYRIGHT HOLDERS BE LIABLE for ANY CLAIM, DAMAGES or OTHER
// LIABILITY, WHETHER IN an ACTION of CONTRACT, TORT or OTHERWISE, ARISING from,
// OUT of or IN CONNECTION WITH THE SOFTWARE or THE Use OR OTHER DEALINGS IN THE
// SOFTWARE.

Use Windows.pkg
Use DFClient.pkg
Use cFilesystem.pkg

#COMMAND CONSOLE_TYPEFACE _RDN
!A [] $156 !1
#ENDCOMMAND

#COMMAND CONSOLE_FONTSIZE _RD _RD
!A [] $157 !1 !2
#ENDCOMMAND

// Change the terminal fonts.
CONSOLE_TYPEFACE "Times New Roman"
CONSOLE_FONTSIZE 12 8

Enum_List
    Define eSplitUnknown              for 0 
    Define eSplitBySpaceSemiColumn    for 1
    Define eSplitBySemiColumn         for 2
    Define eSplitByBeginEnd           for 3
End_Enum_List

Define CS_SplitBySpaceSemiColumn    for "Split line space and semicolon"
Define CS_SplitBySemiColumn         for "Split line with semicolon"
Define CS_SplitByBeginEnd           for "Add a Begin/End block"

// ToDo: These doesn't feel right! Ask Wil about them
// Aren't modern DD classes named o<tablename>_DataDictionary ?
Enum_List
    Define eDDUnknown       for 0 // style unknown or not yet classified
    Define eDDOldStyle      for 1 // <tablename>_DD
    Define eDDStudioStyle   for 2 // o<tablename>_DD
    Define eDDNewStyle      for 3 // o<tablename>_dd
End_Enum_List

Define CS_DDOldStyle      for "<tablename>_DD"
Define CS_DDLegacyStyle   for "o<tablename>_DD"
Define CS_DDNewStyle      for "o<tablename>_dd"

Struct tFunctionTypes
    Integer iAll_Functions
    Integer iStandard_Function
    Integer iRemove_Function
    Integer iEditor_Function
    Integer iReport_Function   
    Integer iReport_FunctionAll
    Integer iOther_Function
    Integer iOther_FunctionAll
End_Struct   

Enum_List 
   Define eEngineOK         for 0
   Define eEngineUserCancel for 1
   Define eEngineError      for 2  
   Define eEngineSelError   for 3 
   Define eEngineBackupErr  for 4
End_Enum_List

Enum_List
    Define eAll_Functions         for 0 
    Define eStandard_Function     for 1   // One source line at a time will be passed for these functions.
    Define eRemove_Function       for 2   // One source line at a time will be passed for these functions.
    Define eEditor_Function       for 3   // A source file as a string array will be passed
    Define eReport_Function       for 4   // A source file as a string array. Makes no source changes.
    Define eReport_FunctionAll    for 5   // Makes no source changes.
    Define eOther_Function        for 6   // A source file as a string array will be passed.
    Define eOther_FunctionAll     for 7   // All selected files as a string array will be passed. 
End_Enum_List

Define CS_All_Functions             for "No Constrains - Show All"
Define CS_Standard_Function         for "Standard - Line-by-line"
Define CS_Remove_Function           for "Remove - Line-by-line"
Define CS_Editor_Function           for "Editor - One File"
Define CS_Report_Function           for "Report - One File"   // Makes no source changes.
Define CS_Report_FunctionAll        for "Report - All Files"  // Makes no source changes.
Define CS_Other_Function            for "Other - One File"
Define CS_Other_FunctionAll         for "Other - All Files"

Enum_List
    Define cx_RegKeyAlreadyExist
    Define cx_RegKeyCreated
    Define cx_RegkeyFailed
    Define cx_RegKeyDFKeyDoesNotExist
    Define cx_InstalledOkDFUnder16
End_Enum_List

Enum_List
    Define CI_SplitBySpaceAndSemicolon for 1
    Define CI_SplitBySemicolon         for 2
    Define CI_SplitToBeginEndBlock     for 3
End_Enum_List  

{ EnumList="CI_FirstCommand, CI_SecondCommand, CI_ThirdCommand"}
Enum_List
    Define CI_FirstCommand
    Define CI_SecondCommand
    Define CI_ThirdCommand
End_Enum_List

Struct tWorkspace
    String sWorkspace
    String sWorkspaceFull    
End_Struct

Enum_List
    Define cx_DbSelect_All
    Define cx_DbSelect_None
    Define cx_DbSelect_Invert
End_Enum_List

Struct tRefactorCheckbox
    Handle hObject
    Boolean bChecked
    Boolean bReportFunction
    Integer iRefactorFunction
    Integer iMissingAlignment1
End_Struct

Struct tRefactorFiles
    String[] asFolders                  // Path and folder name
    String[] asFullFileNames            // Folder + file name
End_Struct

Struct tRefactorSettings
    Integer iSelectedStandardFunctions  // Are called for each source line.
    Integer iSelectedRemoveFunctions    // Are called for each source line. May remove the source line. Returns True if line should be removed
    Integer iSelectedEditorFunctions    // Using the Scintilla Editor. A Full source file is passed.
    Integer iSelectedReportFunctions    // Makes no source changes. A full source file is passed.
    Integer iSelectedReportAllFunctions // Makes no source changes. All selected files are passed as a string array (including path).
    Integer iSelectedOtherFunctions     // A full source file is passed to functions as a string array.
    Integer iSelectedOtherAllFunctions  // All selected files are passed as a string array (including path).
    //
    Integer iSelectedLineByLineFunctions  // Sum of all line-by-line action functions (not full file or report functions).
    Integer iSelectedFullFileFunctions  // Sum of all functions that should be feed with a string array of _one_ source file.
    Integer iSelectedAllFilesFunctions  // All functions that should be feed with a string array with all selected files (including path).
    Integer iSelectedFunctionTotal      // Number of selections
    //
    Boolean bCountSourceLines           // If we should only count source lines (all other functions will be ignored).
    Boolean bReadOnly                   // Run through the selected refactor functions but *do not* make changes to any source file.
    Boolean bWorkspaceMode              // If true all files that matches the selected file filter and selected folders will be affected by refactoring functions.
    Boolean bShowStartQuestion          // Should the engine show a question before starting the refactoring process
    Boolean bShowSummary                // Should the log/summary dialog be dispalyed automatically after the engine is finished.
    //
    String  sFileFilter                 // File selection filter.
    tRefactorFiles FileData             // Contains three arrays; Paths, FileNames & Path+FileNames
End_Struct

Struct tParseObject
    String sObject
    String sObjectLabel  // short name
    String sClass
    Handle pElement
End_Struct

Struct tCJComboBoxContent
    String sText
    Integer eTheme
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
End_Struct

Struct tBackupFiles
    String sFileName
    String sPath
    DateTime dtFileDate
End_Struct    

{ EnumList="{CI_SingleQuotes, CI_DoubleQuotes}" }
Enum_List
    Define CI_SingleQuotes
    Define CI_DoubleQuotes
End_Enum_List 

{ EnumList="{CI_LeftExpression1, CI_LeftExpression2, CI_OfExpression, CI_ToTexpression}" }
Enum_List
    Define CI_LeftExpression1
    Define CI_LeftExpression2
    Define CI_OfExpression
    Define CI_ToTexpression
End_Enum_List 

{ EnumList="{CI_LeftPart, CI_OfPart, CI_ToPart}" }
Enum_List
    Define CI_LeftPart
    Define CI_OfPart
    Define CI_ToPart
End_Enum_List 

Struct tExpression
    { EnumList="{CI_LeftExpression1, CI_LeftExpression2, CI_OfExpression, CI_ToTexpression}" }
    String sExpression
    String sExpressionOS // Overstrike expression variant
    String sExpressionNP // No added Paranthesis
    String sExpressionWS // With Spaces (including multiple consequitive spaces, if any)
    Integer eExpressionMode
    Integer iStartPos 
    Integer iLength 
End_Struct   

Struct tQuotedString
    String sOverwrite
    String sContent
    Integer iStartPos
    Integer iEndPos
    Integer iLength
End_Struct

Struct tOperatorsInfo
    Boolean bIsOperator
    Boolean bIsLegacy
    Integer iPos
    String  sOperator
End_Struct

Struct tToken                     // Note: sOverStrikeLine should be used when using this struct (parameter to function)
    Integer iStartPos             // The starting position for a keyword in a source line, except for any indentation.
    String sCode                  // The code in the source line. Can be a single keyword or part of source linee
End_Struct

Struct tBooleanToken              // Note: sOverStrikeLine should be used when using this struct (parameter to function)
    String sCode                  // The boolean parameter within a square bracket e.g. "Found" for: "[Found]"
    Boolean bHasBracket           // If *[Seqeof]*
    Boolean bHasNot               // If the bracket contains a "not" keyword e.g. [Not Found] or tilde "~" symbol.
    Boolean bDoubleBoolean        // [Found ~Found], ie two boolean indicators within the square brackets.
End_Struct

{ EnumList="{CI_FirstBoolean, CI_SecondBoolean, CI_ToBoolean}" }
Enum_List
    Define CI_FirstBoolean
    Define CI_SecondBoolean
    Define CI_ToBoolean           // Part after "to" or "as"
End_Enum_List 

Struct tBooleanIndicator          // Square bracket indicator info:
    Boolean bHasIndicateCommand   // "*Indicate* Found as..." or "If [Found] Indicate Err as (True = bTrue)"
    tBooleanToken FirstBoolean    // First boolean variable info
    tBooleanToken SecondBoolean   // Second boolean variable, if any (left of "to" and "as")
    tBooleanToken ToBoolean       // Boolean info after the "to" 
    tBooleanToken AsBoolean       // Boolean info after the "as" 
End_Struct        

Struct tTokenizer
    Boolean bLineIsReady                // This is set when we don't need to process the line no more, e.g. a blank line or a commented line.
    Boolean bIsBlank                    // It is a blank line (with no or many tabs and/or spaces.
    Boolean bIsInImage                  // Are we within a "/MyPageName" -- "/*" area?
    Boolean bIsComment                  // If the source code line starts with "//"
    Boolean bIsInDF23MultiLineComment   // For DF 23 and up. New comment syntax: Start = /* and End = */
    Boolean bHasEndSemiColon            // If the line ends with a semi-colon (;), indicating there is more code on next line.
    Boolean bIsInDF23MultiLineString    // DF23 -> can e.g. be an SQL statement over several lines. Will not be acted on by the Tokenizier.
    Boolean bIsOpenString               // If bHasEndSemiColon is True, or bIsMultiLineString is True the line can be an "open" string constant.
    Boolean bIsDF23String               // DF23 -> can e.g. be an SQL statement, Javascript code etc. Will not be acted on by the Tokenizier.
    Boolean bIsInFunction               // Are we in a function declaration
    Boolean bIsInProcedure              // Are we in a procedure declaration
    Boolean bIsInClass                  // Are we in a command declaration
    Boolean bIsInCommand                // Are we in a command declaration e.g. #Commmand Move...
    Boolean bIsInStruct                 // Are we in a struct
    Boolean bIsVariableDeclaration      // Is the line a variable declaration
    Boolean bHasIfCommand               // True if at least one "if" on the line.
    
    String sLine                        // The original source line, untouched.
    String sEndComment                  // Move x to y *// This is a right side comment.*
    String sIndentation                 // Line start indentation, one or more tabs or spaces.
    Boolean bHasOverstrikeChars         // True if the sOverstrikeLine has overstriked content. Set by the _OverstrikeStrings function.
    String sOverstrikeLine              // Source line without indentation and string literals overstriked with "_" or '+'.

    tToken LeftStatement                // *Get MyFunction* of oSomeObject. Part before the "of" and "to" keywords.
    tToken OfStatement                  // Get "Function" of *oMyObject*
    tToken ToStatement                  // Move x to *y*

    tToken FirstLeftCommand             // *If* (x = y)... (left side of the "to" clause)
    tToken SecondLeftCommand            // "If (x = y) *Move* A to" or "If (True) *Begin*"

    String sLeftExpression1             // If *((iA * iB > 10) + (iD + iE)* > 100) Move (iA / iB) to
    String sLeftExpression2             // If ((iA * iB > 10) + (iD + iE) > 100) Move *(iA / iB)* to
    String sOfExpression                // Get psAppSrcPath of *(phoWorkspace(ghoApplication))* to
    String sToExpression                // Move (True = False) to *(asMyArray[SizeOfArray(asMyArray)]*
    tExpression[] aExpressions          // Struct array with all expressions within "()" and their position on the source line.
    tQuotedString[] asStringConstant    // Struct string array with original text string constants for the sLine content.
    String[] asLineTokens               // The sOverstrikeLine is broken up by spaces to a string array, but expressions are kept together on one array line even if it contains spaces.
    tBooleanIndicator BooleanIndicator  // [*Select*] Move iA to iB or "*Indicate* x as y" See: Function _ExtractLegacyBooleanContent.
    tOperatorsInfo OperatorsInfo        // Operator info e.g. "eq", "=", "lt", "<" etc.
End_Struct        

#IFNDEF clGreenGrey
    Define clGreenGrey              for (RGB(64, 84, 93))
    Define clGreenGreyLight         for (RGB(7, 117, 104))
    Define clDarkGreen              for (RGB(49, 60, 83)) 
    Define clStatusBarColor         for (RGB(45, 130, 149))     // HTML #2D8295
    Define clEditorBackGround       for (RGB(36, 49, 68))       // HTML 243144
    Define clBaseColor              for (RGB(239, 239, 239))    // HTML #EFEFEF  
    Define clAlternateRowBgColor    for (RGB(216, 217, 227))    // HTML #D8D9E3
    Define clActiveRow              for (RGB(1, 82, 119))       // HTML #015277 
    Define clProgramIconBg          for (RGB(43, 59, 83))       // HTML #2B3B53
#ENDIF
#IFNDEF CI_DarkTheme
    Define clDarkTheme for (RGB(36,36,36)) 
    Define clDarkThemeText for clWhite
#ENDIF

Define CS_StudioTools               for "\Studio\Tools"
Define CS_RegWorkspace              for "<workspace>"
Define CS_RegFileName               for "<file>"
Define CS_SaveAll                   for "<saveall>"
Define CS_CommandLine               for "CommandLine"
Define CS_Command                   for "Command"
Define CS_Name                      for "Name"
Define CS_Separator                 for "Separator"

Define CPC_OpenFile                 for 1 // perfcounter on open file
Define CS_Settings                  for "Settings"
Define CS_GridFontSize              for "GridFontSize"
Define CS_GridTheme                 for "GridTheme"
Define CS_GridCaptionColor          for "GridCaptionColor"
Define CS_TabPosition               for "TabPosition"
Define CS_StarZenSourceExplorer     for "StarZenSourceExplorer"
Define CS_FileCompareProgram        for "FileCompareProgram"
Define CS_ToolbarIconSize           for "ToolbarIconSize"
Define CS_GridRowBackgroundColor    for "GridRowBackgroundColor"
Define CS_MaxBlankLineSize          for "MaxBlankLineSize"
Define CS_SplitByPreference         for "SplitByPreference"
Define CS_DataFlexVersionText       for "DataFlex Version:"
Define CS_SelectWorkspaceText       for "Select Workspace:"
Define CS_CurrentWorkspaceText      for "Current Workspace:"
Define CS_WorkspacesKey             for "Workspaces"
Define CS_WorkspacePaths            for "WorkspacePaths"
Define CS_ConfigFile                for "ConfigFile"
Define CS_WorkspaceRecentKey        for "Recent"
Define CS_PropertiesKeyWord         for "Properties"
Define CS_ThemeKeyWord              for "Theme"
Define CS_VersionKeyWord            for "Version"
Define CS_Projects                  for "Projects"
Define CS_Project                   for "Project"
Define CS_Application               for "Application" 
Define CS_Icon                      for "Icon"
Define CS_AppSrcPath                for "AppSrcPath"
Define CS_BitmapPath                for "BitmapPath" 
Define CS_Workspace                 for "Workspace"
Define CS_OpenWorkspace             for "Select &Workspace"
//Define CS_OpenWorkspace             for "Open &Workspace"
Define CS_CurrentWorkspace          for "Current &Workspace:"
Define CS_NoActiveWorkspaceText     for ""
Define CS_SelectWorkspaceFile       for "Select a DataFlex workspace project (*.sws) or (*.ws) file"
Define CS_BrowseSourceFileTxt       for "Select File:"
Define CS_CurrentSourceFileTxt      for "Current File:"
Define CS_NoActiveSourceFileText    for "" 
Define CS_NoWorkspaceSelected       for "- Recent Workspaces"
Define CS_WorkspaceFilterString     for "DataFlex Workspace Files (*.sws)|*.sws|(*.ws)|*.ws|Any file (*.*)|*.*"
Define CS_OpenFileStdFilter         for "All files *.*|*.*|Programs *.src|*.src|Views *.vw|*.vw|Report Views *.rv|*.rv|Selection Lists *.sl|*.sl|Packages *.pkg|*.pkg"
Define CS_SourceCodeFilters         for "DataFlex Source *.src;*.vw;*.sl;*.dg;*.rv;*.pkg;*.cl;*.wo;*.dd;*.bp;*.inc;*.nui;*.utl;*.mn;*.mnu|*.src;*.vw;*.sl;*.dg;*.rv;*.pkg;*.cl;*.wo;*.dd;*.bp;*.inc;*.nui;*.utl;*.mn;*.mnu"
Define CS_SourceFileFilters         for "Programs|*.src|Views|*.vw|Dialogs|*.dg|Data Dictionaries|*.dd|Include files|*.inc|Report Views|*.rv|Selection Lists|*.sl|Packages|*.pkg|Business Processes|*.bp|Menus|*.mn|Header Files|*.h|Sture's Files|*.nui;*.utl|Any file|*.*"
Define CS_CreateBackupFiles         for "CreateBackupFiles"
Define CS_SummaryLogfileName        for "DFRefactorLogFile.txt"

// Careful, these cannot end on a semicolumn as you will introduce variable type equal to ""
Define CS_VarTypes                  for "INDICATOR;STRING;INTEGER;NUMBER;DATE;DATETIME;BOOLEAN;HANDLE;REAL;VARIANT;TIMESPAN;ROWID;DECIMAL;BIGINT;REAL;UCHAR;ADDRESS;CHAR;CURRENCY;DWORD;FLOAT;POINTER;SHORT;TIME;UBIGINT;USHORT;WSTRING;LONGPTR;ULONGPTR;UINTEGER;XMLHANDLE"

Define CS_ValidLeftCharacters       for ("()[];,&+-*<>= " + Character(9)) // Character 9=tab char //"()[];,.&+-*<>= "
Define CS_CommentSymbol             for ("//")
Define CS_ImageNameStart            for "/"
Define CS_ImageNameEnd              for "/*"
Define CS_DF23CommentStart          for "/*"
Define CS_DF23CommentEnd            for "*/"
Define CS_StudioToolsPathStart      for "Software\Data Access Worldwide\DataFlex Tools\"
Define CS_StudioToolsPathEnd        for "\Studio\Preferences\File Extensions"
Define CS_StudioCodeEditorPath      for "\Studio\Code-Editor"
Define CS_StudioFontName            for "FontName"
Define CS_StudioFontSize            for "FontSize"
Define CS_StudioExpandTabs          for "ExpandTabs"
Define CS_StudioIndentStyle         for "IndentStyle"
Define CS_StudioTabSize             for "TabSize"
Define CS_StudioEditorSettingsStart for "DataFlex Studio"
Define CS_StudioEditorSettingsEnd   for "Code Editor Settings"
Define CS_StudioEditorSettingsExtra for "(Will be applied when indenting code)"
Define CS_IdleText                  for "Idle..."
Define CS_WorkingText               for "Working..."
Define CS_ReadyText                 for "Ready!"

Define CS_Default_Dialog_Caption    for "Select a source file"
Define CS_Folder_Dialog_Caption     for "Select a Filename - Only the foldername will be returned"
Define CS_Default_Filter_String     for "All Files *.*|*.*|Programs *.src|*.src|Views *.vw|*.vw|Report Views *.rv|*.rv|Selection Lists *.sl|*.sl|Packages *.pkg|*.pkg"
Define CS_Folder_Filter_String      for "All files|*.*"

Define CS_BackupFolder              for "DFRefactor_Backup"
Define CS_NoFolderList              for (".|..|.svn|.git|.hg|apphtml|data|bitmaps|help|idesrc|programs|.cab|install")
//Define CS_NoFolderList              for (".|..|.svn|.git|.hg|apphtml|data|bitmaps|help|idesrc|programs|.cab|install" + "|" + CS_BackupFolder)
Define CS_DefaultSourceFolders      for "appsrc|ddsrc|libraries|pkg"
Define CS_LF                        for (Character(10))
Define CS_CR                        for (Character(13))
Define CS_CRLF                      for (Character(13) + Character(10))
Define CS_DirSeparator              for (SysConf(SYSCONF_DIR_SEPARATOR))
Define CI_EOL                       for 2048


// Note: the "Visual" will automatically be replace if a more recent DF version is used.
Define CS_StudioPath                for "Software\Data Access Worldwide\Visual DataFlex Tools\"
Define CS_StudioPathEnd             for  "\Studio\Preferences\File Extensions"
Define CS_WebFileExtensions         for ".wo;.html;.asa;.asp;.css;.js"
Define CS_StdExtensions             for "*.src;*.vw;*.sl;*.dg;*.rv;*.pkg;*.cl;*.wo;*.dd;*.bp;*.inc;*.nui;*.utl;*.mn;*.mnu"
Define CS_DFAndTemplExt             for "*.src;*.vw;*.sl;*.dg;*.rv;*.bp;*.pkg;*.wo;*.dd;*.inc;*.dfo;*.tpl"
Define CS_DDDEFExt                  for "*.dd"
Define CS_PkgIncExt                 for "*.pkg;*.inc;*.mac"
Define CS_SrcPkgExt                 for "*.src;*.pkg"
Define CS_AllExt                    for "*.*"
Define CS_DFExtensionsKey           for "DFExtension"

Define CS_DFCOMProxyClasses         for "DataFlex COM proxy classes generated from"
Define CS_ProjectObjectStructure    for "Project Object Structure"
Define CS_RegisterAllObjects        for "Register all objects"
Define CS_RegisterObject            for "Register_Object "

// Special function names:
Define CS_CountSourceLines              for "CountSourceLines"
Define CS_EditorReIndent                for "EditorReIndent"
Define CS_EditorDropSelf                for "EditorDropSelf"
Define CS_RemoveProjectObjectStructure  for "RemoveProjectObjectStructure"
//Define CS_RemoveBlankLines              for "RemoveBlankLines"
Define CS_UnusedSourceFiles             for "ReportUnusedSourceFiles"

// Refactor Testing program:             
Define CS_TestProgram    for "CompiledRefactoredCode.src"
Define CS_TestErrFile    for "CompiledRefactoredCode.err"
Define CS_Compiler       for "DFComp.exe"
Define CS_DFCompiler     for "DFCompiler"
Define CS_Build_Options  for "Build_Options"
Define CS_CompOptions    for "-e0fv2i0"     
Define CS_Splitters      for "Splitters"
Define CS_TestBenchViewSplitterPos for "TestBenchViewSplitterPos"

#IF (!@ = 230)
    Define CS_SWSFile        for "DFRefactor23.0.sws"
#ENDIF
#IF (!@ = 240)
    Define CS_SWSFile        for "DFRefactor24.0.sws"
#ENDIF
    
Define CS_DFUnitTest     for "DFUnit_TestRunner"
Define CS_DFRefactor     for "DFRefactor"
Define CS_LegacyCode     for "LegacyCode.pkg"
Define CS_RefactoredCode for "RefactoredCode.pkg"
Define CS_ImpExpFileJson for "DFRefactorImportExportFile.json" 
Define CS_ExportJsonFile for "ExportJsonFile"
Define CS_ImportJsonFile for "ImportJsonFile"
Define CS_ShowQuestion   for "ShowQuestion"
Define CS_ShowSummary    for "ShowSummary"

// Refactor Testing program:
Define CS_Trim           for "Trim"    
Define CS_Length         for "Length"  
Define CS_Left           for "Left"
Define CS_Right          for "Right"
Define CS_Pos            for "Pos"   
Define CS_Replace        for "Replace"
Define CS_In             for "In" 
Define CS_If             for "If"   
Define CS_Else           for "Else"
Define CS_Begin          for "Begin"
Define CS_With           for "With" 
Define CS_At             for "At"   
Define CS_As             for "As"  
Define CS_To             for "to"
Define CS_Of             for "of"
Define CS_ZeroString     for "ZeroString"  
Define CS_Insert         for "Insert" 
Define CS_Repeat         for "Repeat"
Define CS_While          for "While" 
Define CS_Loop           for "Loop"
Define CS_Current_Object for "Current_Object"
Define CS_Self           for "Self"
Define CS_Move           for "Move"
Define CS_Indicate       for "Indicate"  
Define CS_Not            for "Not"
Define CS_Tilde          for "~"
Define CS_True           for "True"   
Define CS_False          for "False"
Define CS_DfTrue         for "DfTrue"
Define CS_DfFalse        for "DfFalse"
Define CS_Set            for "Set"
Define CS_Get            for "Get"
Define CS_Enabled_State  for "Enabled_State" 
Define CS_Find           for "Find"   
Define CS_Send           for "Send"
Define CS_Found          for "Found"
Define CS_Finderr        for "Finderr"
Define CS_Err            for "Err"
Define CS_Sysdate4       for "Sysdate4"
Define CS_Constrain      for "Constrain"
Define CS_Until          for "Until"
Define CS_Reread         for "Reread"
Define CS_Lock           for "Lock"
Define CS_Local          for "Local"
Define CS_GetAddress     for "GetAddress" 
Define CS_AddressOf      for "AddressOf"
Define CS_Function       for "Function"
Define CS_FunctionEnd    for "End_Function"
Define CS_Procedure      for "Procedure"
Define CS_ProcedureEnd   for "End_Procedure"
Define CS_Contains       for "contains"
Define CS_Select         for "[Select]" 
Define CS_Shadow_State   for "Shadow_State"
Define CS_Object_Shadow_State for "Object_Shadow_State"  

// Various DataFlex language text constants:
Define CS_EndClass       for "End_Class"
Define CS_EndObject      for "End_Object"
Define CS_EndFunction    for "End_Function"
Define CS_EndProcedure   for "End_Procedure"

// Struct that mimics the Functions data table:
Struct tFunctionData
    String ID   
    String Function_Name
    String Function_Description
    String Function_Help
    String SummaryText 
    Boolean Selected
    Integer Type
    Boolean bHasParameter
    String Parameter
    String ParameterValidation
    String ParameterHelp
    Boolean bPrivate  
    Number Counter
End_Struct

Struct tFunctionCode  
    String  sFunctionName
    Integer iSourceLines
    String[] CodeArray
End_Struct

Struct tUnitTestCode
    String  sFunctionName
    Integer iSourceLines
    String[] UnitArray
End_Struct

Struct tExportImport
    Integer iNoOfFunctions
    tFunctionData[] Data
    tFunctionCode[] Code
    tUnitTestCode[] Unit
End_Struct

Define CS_FunctionLibraryFile       for "cRefactorFuncLib.pkg"
Define CS_UnitTestsFile             for "oUnit_Tests.pkg"
Define CS_UnitTestsTokenizerFunc    for "Tokenizer"
Define CS_ImportBackupFolder        for "ImportBackup"
Define CS_FunctionLibraryClassStart for "Class cRefactorFuncLib is a cBaseFuncLib"
Define CS_Comment1                  for '// NOTE: Do *not* add any code after this "End_Class"!'
Define CS_Comment2                  for '//       It will be removed by the Export/Import logic.'
