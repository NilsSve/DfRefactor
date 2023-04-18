Use Windows.pkg
Use DFClient.pkg
Use cFilesystem.pkg

Enum_List
    Define cx_RegKeyAlreadyExist
    Define cx_RegKeyCreated
    Define cx_RegkeyFailed
    Define cx_RegKeyDFKeyDoesNotExist
    Define cx_InstalledOkDFUnder16
End_Enum_List

Enum_List
    Define CI_LeftExpression
    Define CI_CommandExpression
    Define CI_OfExpression
    Define CI_ToTexpression
End_Enum_List 

Enum_List
    Define CI_SplitWithSpaceAndSemicolon for 1
    Define CI_SplitWithSemicolon         for 2
    Define CI_SplitAddBeginEndBlock      for 3
End_Enum_List

Struct tWorkspace
    String sWorkspace
    String sWorkspaceFull    
End_Struct

Struct tRefactorCheckbox
    Handle hObject
    Boolean bChecked
    Boolean bReportFunction
    Integer iRefactorFunction
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
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
    //
    Boolean bCountSourceLines           // If we should only count source lines (all other functions will be ignored).
    Boolean bEditorDropSelf             // Scintilla Editor special function that pops up a dialog before each change(!).
    //
    String  sFileFilter                 // File selection filter.
    String[] asFolderNames              // String array with full path to all selected folders.
    Integer eDDOStyle
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
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

Struct tCodeComponents
    String sIndentation
    String sLineStartIndicator
    String sLineEndIndicator
    Boolean bHasIndicateCommand
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
    String sLeftCommand
    String sLeftCommand2
    String sCode   
    String sOfStatement   
    String sToStatement
    String sRightComment 
    Boolean bHasEndSemiColon   
#IFDEF IS$WIN64
    Integer iMissingAlignment2
#ENDIF
End_Struct

Struct tBooleanIndicator
    Boolean bHasBracket  
    Boolean bHasNot
    String sExpression
    String sCode
End_Struct        

Struct tOperatorsInfo
    Boolean bIsOperator
    Boolean bIsLegacy
    Integer iPos
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
    String  sOperator
End_Struct

#IFNDEF clGreenGrey
    Define clGreenGrey              for (RGB(64, 84, 93))
    Define clGreenGreyLight         for (RGB(7, 117, 104))
#ENDIF
Define clDarkGreen                  for (RGB(49, 60, 83))

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
Define CS_OpenWorkspace             for "Select &Workspace"
//Define CS_OpenWorkspace             for "Open &Workspace"
Define CS_CurrentWorkspace          for "Current &Workspace:"
Define CS_NoActiveWorkspaceText     for ""
Define CS_SelectWorkspaceFile       for "Select a DataFlex workspace project file (*.sws)"
Define CS_BrowseSourceFileTxt       for "Select File:"
Define CS_CurrentSourceFileTxt      for "Current File:"
Define CS_NoActiveSourceFileText    for "" 
Define CS_NoWorkspaceSelected       for "- None"
Define CS_WorkspaceFilterString     for "DataFlex Workspace Files (*.sws)|*.sws|Any file (*.*)|*.*"
Define CS_OpenFileStdFilter         for "All files *.*|*.*|Programs *.src|*.src|Views *.vw|*.vw|Report Views *.rv|*.rv|Selection Lists *.sl|*.sl|Packages *.pkg|*.pkg"
Define CS_SourceCodeFilters         for "DataFlex Source *.src;*.vw;*.sl;*.dg;*.rv;*.pkg;*.cl;*.wo;*.dd;*.bp;*.inc;*.nui;*.utl;*.mn;*.mnu|*.src;*.vw;*.sl;*.dg;*.rv;*.pkg;*.cl;*.wo;*.dd;*.bp;*.inc;*.nui;*.utl;*.mn;*.mnu"
Define CS_SourceFileFilters         for "Programs|*.src|Views|*.vw|Dialogs|*.dg|Data Dictionaries|*.dd|Include files|*.inc|Report Views|*.rv|Selection Lists|*.sl|Packages|*.pkg|Business Processes|*.bp|Menus|*.mn|Header Files|*.h|Sture's Files|*.nui;*.utl|Any file|*.*"
Define CS_CreateBackupFiles         for "CreateBackupFiles"
Define CS_SummaryLogfileName        for "DFRefactoringLogFile.txt"

Define CS_VarTypes                  for "STRING;INTEGER;NUMBER;DATE;DATETIME;BOOLEAN;HANDLE;REAL;VARIANT;TIMESPAN;ROWID;DECIMAL;BIGINT;REAL;UCHAR;ADDRESS;CHAR;CURRENCY;DWORD;FLOAT;POINTER;SHORT;TIME;UBIGINT;USHORT" // careful, cannot end on a semicolumn as you will introduce variable type equal to ""
Define CS_VarArrayTypes             for "STRING[];INTEGER[];NUMBER[];DATE[];DATETIME[];BOOLEAN[];HANDLE[];REAL[];VARIANT[];TIMESPAN[];ROWID[];DECIMAL[];BIGINT[];REAL[];UCHAR[];ADDRESS[];CHAR[];CURRENCY[];DWORD[];FLOAT[];POINTER[];SHORT[];TIME[];UBIGINT[];USHORT[];STRING[][];INTEGER[][];NUMBER[][];DATE[][];DATETIME[][];BOOLEAN[][];HANDLE[][];REAL[][];VARIANT[][];TIMESPAN[][];ROWID[][];DECIMAL[][];BIGINT[][];REAL[][];UCHAR[][];ADDRESS[][];CHAR[][];CURRENCY[][];DWORD[][];FLOAT[][];POINTER[][];SHORT[][];TIME[][];UBIGINT[][];USHORT[][]"
Define CS_ValidLeftCharacters       for ("()[];,&+-*<>= " + Character(9)) // Character 9=tab char //"()[];,.&+-*<>= "

Define CS_UnusedSourceLogFile       for "UnusedSourceFiles.txt"
Define CS_CommentSymbol             for ("/"+"/")
Define CS_ImageNameStart            for "/"
Define CS_ImageNameEnd              for "/*"
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

Define CS_BackupFolder              for "DFRefactor Backup"
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
Define CS_Compiler       for "DFComp.exe"
Define CS_TestProgram    for "CompiledRefactoredCode.src"
Define CS_TestErrFile    for "CompiledRefactoredCode.err"
Define CS_CompOptions    for "-e3fv2i0"     
Define CS_SWSFile        for "DFRefactor19.1.sws"
Define CS_DFUnitTest     for "DFUnit_TestRunner"
Define CS_DFRefactor     for "DFRefactor"
Define CS_LegacyCode     for "LegacyCode.pkg"
Define CS_RefactoredCode for "RefactoredCode.pkg"

// Refactor Testing program:
Define CS_Trim           for "Trim"    
Define CS_Length         for "Length"  
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
Define CS_Sysdate4       for "Sysdate4"
Define CS_Constrain      for "Constrain"
Define CS_Until          for "Until"
Define CS_Local          for "Local"
Define CS_GetAddress     for "GetAddress" 
Define CS_AddressOf      for "AddressOf"
Define CS_Function       for "Function"
Define CS_Contains       for "contains"
Define CS_Select         for "[Select]"

// cRegex Expression Constants:
//
