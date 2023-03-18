Use Windows.pkg
Use cDbSplitterContainer.pkg
Use Dfenrad.pkg
Use File_dlg.pkg
Use seq_chnl.pkg

Use cRefactorDbView.pkg
Use cRDCDbSpinForm.pkg
Use cRDCDbForm.pkg
Use cFileNameForm.pkg
Use cScintillaRefactorEditor.pkg
Use oEditorProperties.pkg
Use mfiletime.pkg
Use vwin32fh.pkg

Use LogFileDialog.dg
Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd  
Use cFunctionsADataDictionary.dd

Activate_View Activate_oFunctionTableTesting for oFunctionTableTesting
Object oFunctionTableTesting is a cRefactorDbView
    Set Border_Style to Border_Thick
    Set Size to 289 831
    Set Location to 2 7
    Set Label to "Test Bench for Functions"
    Set pbAutoActivate to True
    Set Maximize_Icon to True 
    Set pbAcceptDropFiles to True

    Set phoTestView of ghoApplication to Self
    Property Handle phoEditorLegacy
    Property Handle phoEditorRefactored   
        
    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary
        Procedure Request_Save
            Send Request_Save of oSysFile_DD
            Forward Send Request_Save
        End_Procedure
    End_Object     
    
    Procedure Request_Save
        Send Request_Save of (Main_DD(Self))
        Forward Send Request_Save
    End_Procedure
    
    Set Main_DD to oFunctions_DD
    Set Server to oFunctions_DD

    Object oSplitterContainer is a cDbSplitterContainer
        Set piSplitterLocation to 498

        Object oSplitterContainerChild1 is a cDbSplitterContainerChild

            Object oOpenDialog is a OpenDialog
                Set Dialog_Caption to "Select your file compare application of choice"
                Set Filter_String to "Programs|*.exe|Any file|*.*"
            End_Object

            Object oInfo_tb is a TextBox
                Set Size to 10 251
                Set Location to 5 126
                Set Label to "- You can drag && drop a source file from Windows Explorer to this editor object"
            End_Object

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 74
                Set Location to 4 8
                Set Label to "Legacy Code: (Before)"
                Set FontWeight to fw_Bold
                Set FontPointHeight to 10
            End_Object
        
            Object oLegacyCode_edt is a cScintillaRefactorEditor
                Set Size to 176 481
                Set Location to 17 6
                Delegate Set phoEditorLegacy to (Self)
                Set phoEditorLegacy of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_LegacyCode)

                Property Boolean pbIsFileDropped False
                
                Procedure OnFileDropped String sFileName Boolean bLast
                    Integer iChannel iCount
                    String sTextValue sLine
                    Boolean bSeqEof
                    String[] asLegacyCode    
                    Handle ho
                    
                    If (bLast = True) Begin
                        Set pbIsFileDropped to False
                        Send LoadFile sFileName 
                        Send SaveFile 
                    End 
                    // We use a property to only show info_box once if multiple files are dropped.
                    Else If (pbIsFileDropped(Self) = False) Begin
                        Send Info_Box "Only one source file can be dropped at a time. The last file will be used."
                        Set pbIsFileDropped to True
                    End
                End_Procedure
                
                // Important: Must be after the object has been paged, else the text won't show
                Procedure Page Integer iPageObject
                    String[] asLegacyCode
                    String sFileName                         
                    Handle ho   
                    Integer iLines
                    
                    Forward Send Page iPageObject
                    If (iPageObject) Begin
                        Get Line_Count to iLines
                        If (iLines > 1) Begin
                            Procedure_Return
                        End
//                        Get ReadImageDataToStringArray 1 to asLegacyCode 
                        Move (oLegacyCodeFilename_fm(Self)) to ho
                        Get psCodeFile of (phoEditorLegacy(ghoApplication)) to sFileName
//                        Send SaveData of ho asLegacyCode
                        Send LoadFile sFileName   
                        Send OnModified
                    End     
                End_Procedure
            
                Procedure OnModified
                    Integer iLines
                    
                    Forward Send OnModified
                    Get Line_Count to iLines
                    Set Value of oLegacyCode_NoOfLines_fm to iLines                    
                End_Procedure
            
            End_Object

            Object oLegacyCode_NoOfLines_fm is a Form
                Set Size to 10 33
                Set Location to 197 454
                Set Enabled_State to False
                Set Label to "No of Lines:"
                Set Value to "0"
                Set Label_Justification_Mode to JMode_Right
                Set peAnchors to anBottomRight
                Set Form_Datatype to 0 
                Set Label_Col_Offset to 2
                Set Label_Row_Offset to 2
                
                    Procedure Set Value Integer iItem String sValue
                    Integer iValue
                    String sFormatString 
                    Move sValue to iValue
                    Move ",#." to sFormatString
                    Move (FormatValue(iValue, sFormatString)) to sValue
                    Forward Set Value to sValue
                End_Procedure
            End_Object

            Object oSaveFiles_grp is a dbGroup
                Set Size to 71 383
                Set Location to 205 5
                Set Label to "Refactoring Code Sample Files:"
                Set peAnchors to anBottomLeftRight

                Object oLegacyCodeFilename_fm is a cFileNameForm
                    Set Size to 14 368
                    Set Location to 19 7
                    Set Label to "Legacy Code File"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set peAnchors to anBottomLeftRight 

                    Procedure Set Value Integer iItem String sFileName
                        Forward Set Value to sFileName
                        Set psLegacySourceFile of ghoApplication to sFileName
                    End_Procedure
                End_Object

                Object oRefactoredCodeFilename_fm is a cFileNameForm
                    Set Size to 14 368
                    Set Location to 45 6
                    Set Label to "Refactored Code File"
                    Set Label_Col_Offset to 0
                    Set Label_Justification_Mode to JMode_Top
                    Set peAnchors to anBottomLeftRight

                    Procedure Set Value Integer iItem String sFileName
                        Forward Set Value to sFileName
                        Set psRefactoredSourceFile of ghoApplication to sFileName
                    End_Procedure
                End_Object

            End_Object

//            Object oSplitBy_rgp is a dbRadioGroup
//                Entry_Item SysFile.eSplitBy
//                Set Server to oSysFile_DD
//                Set Location to 205 308
//                Set Size to 51 117
//                Set Label to "Split 'If' line to:"
//                Set peAnchors to anBottomRight
//
//                Object oRadio0 is a Radio
//                    Set Label to CS_SplitBySpaceSemiColumn
//                    Set psToolTip to "Break the if/else line with a space followed by a semicolon"
//                    Set Size to 10 119
//                    Set Location to 13 5
//                End_Object
//
//                Object oRadio1 is a Radio
//                    Set Size to 10 119
//                    Set Location to 24 5
//                    Set Label to CS_SplitBySemiColumn
//                    Set psToolTip to "Break the if/else line with a semicolon"
//                End_Object
//
//                Object oRadio2 is a Radio
//                    Set Size to 10 119
//                    Set Location to 36 5
//                    Set Label to CS_SplitByBeginEnd
//                    Set psToolTip to "Break the if/else line by adding a begin / end block"
//                End_Object
//
//                Procedure Notify_Select_State Integer NewId Integer OldId
//                    Forward Send Notify_Select_State NewId OldId
//                End_Procedure
//        
//            End_Object

//            Object oDDOStyle_rgp is a dbRadioGroup
//                Entry_Item SysFile.eDDOStyle
//                Set Server to oSysFile_DD
//                Set Location to 205 183
//                Set Size to 51 120
//                Set Label to "DDO Style:"
//                Set peAnchors to anBottomRight
//
//                Object oRadio0 is a Radio
//                    Set Label to CS_DDOldStyle
//                    Set Size to 10 119
//                    Set Location to 12 5
//                End_Object
//
//                Object oRadio1 is a Radio
//                    Set Size to 10 119
//                    Set Location to 23 5
//                    Set Label to CS_DDLegacyStyle
//                End_Object
//
//                Object oRadio2 is a Radio
//                    Set Size to 10 119
//                    Set Location to 35 5
//                    Set Label to CS_DDNewStyle
//                End_Object
//
//                Procedure Notify_Select_State Integer NewId Integer OldId
//                    Forward Send Notify_Select_State NewId OldId
//                End_Procedure
//        
//            End_Object
            
//            Object oTabSize_sf is a cRDCDbSpinForm
//                Entry_Item SysFile.TabSize
//                Set Server to oSysFile_DD
//                Set Size to 13 27
//                Set Location to 240 460
//                Set Label to "Tab Size"
//                Set Label_Col_Offset to 2
//                Set Label_Justification_Mode to JMode_Right
//                Set psToolTip to "Select the indent size you want to use when indenting code and when breaking a line on rewriting a single line to multiple lines. It is the same value that can be set on the Editor Settings dialog tab size."
//                Set peAnchors to anBottomRight
//            End_Object

//            Object oMaxBlankLines_sf is a cRDCDbSpinForm
//                Entry_Item SysFile.MaxBlankLines
//                Set Server to oSysFile_DD
//                Set Size to 13 27
//                Set Location to 261 460
//                Set Label to "Max blank lines"
//                Set Label_Col_Offset to 2
//                Set Label_Justification_Mode to JMode_Right
//                Set psToolTip to "Select the maximum number of consecutive blank lines that is allowed in a source file. If more empty lines are encountered, they will be removed."
//                Set Maximum_Position to 6
//                Set Minimum_Position to 1
//                Set peAnchors to anBottomRight
//            End_Object

        End_Object

        Object oSplitterContainerChild2 is a cDbSplitterContainerChild

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 84
                Set Location to 4 5
                Set Label to "Refactored Code: (After)"
                Set FontWeight to fw_Bold
                Set FontPointHeight to 10
            End_Object
    
            Object oRefactoredCode_edt is a cScintillaRefactorEditor
                Set Size to 176 476
                Set Location to 17 6
                Delegate Set phoEditorRefactored to (Self)  
                Delegate Set phoEditor to (Self)
                Set phoEditorRefactored of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_RefactoredCode)
        
                Procedure OnModified
                    Integer iLines
                    
                    Forward Send OnModified
                    Get Line_Count to iLines
                    Set Value of oRefactoredCode_NoOfLines_fm to iLines                    
                End_Procedure          
                
                On_Key Key_Ctrl+Key_E Send Execute of (oErrorLog_ToolItem(ghoCommandBars))
            End_Object

            Object oRefactoredCode_NoOfLines_fm is a Form
                Set Size to 10 28
                Set Location to 197 48
                Set Enabled_State to False
                Set Label to "No of Lines:"
                Set Value to "0"
                Set Label_Col_Offset to 2
                Set Label_Justification_Mode to JMode_Right
                Set peAnchors to anBottomLeft
                Set Form_Datatype to 0 
                Set Label_Row_Offset to 2
                Procedure Set Value Integer iItem String sValue
                    Integer iValue
                    String sFormatString 
                    Move sValue to iValue
                    Move ",#." to sFormatString
                    Move (FormatValue(iValue, sFormatString)) to sValue
                    Forward Set Value to sValue
                End_Procedure
            End_Object

            Object oRefactoredCode_Time_fm is a Form
                Set Size to 10 33
                Set Location to 197 113
                Set Enabled_State to False
                Set Label to "Elapsed:"
                Set Label_Col_Offset to 2
                Set Label_Justification_Mode to JMode_Right
                Set peAnchors to anBottomLeft
                Set Form_Datatype to Mask_Clock_Window
                Set Label_Row_Offset to 2
            End_Object

            Object oRefactor_btn is a Button
                Set Size to 26 100
                Set Location to 213 225
                Set Label to "&Refactor Legacy Code"
                Set peAnchors to anBottomRight
                Set Default_State to True
                // Note: We use Form_FontWeight instead of FontWeight to _not_ make the object larger
                // because of the bold font.
                Set Form_FontWeight to FW_BOLD
                Set psImage to "Start.ico"
                Set psToolTip to "Refactors the legacy code from the left editor, then saves it to disk. (Ctrl+R)"
                Set piImageSize to 24
                
                Procedure OnClick                          
                    Boolean bUseConstraints
                    Get Checked_State of (phoUseConstraints_cb(ghoApplication)) to bUseConstraints
                    Delegate Send RefactoreCode bUseConstraints
                End_Procedure
            
            End_Object
    
            Object oCompareProgram_btn is a cRDCButton
                Set Size to 14 100
                Set Location to 242 225
                Set Label to "Co&mpare Before && After"
                Set peAnchors to anBottomRight
                Set psImage to "Compare.ico"
                Set psToolTip to "Starts the selected compare program and passes the two source files (Ctrl+M). It automatically saves the source files first."
            
                Procedure OnClick
                    String sCompareApp
                    Send Execute of (oSave_ToolItem(ghoCommandBars))
                    Get psFileCompareApp of ghoApplication to sCompareApp
                    Send CompareFiles of ghoApplication sCompareApp
                End_Procedure
        
                Function IsEnabled Returns Boolean
                    Integer iLines
                    Get SC_LineCount of (phoEditor(Self)) to iLines
                    Function_Return (iLines > 1)
                End_Function
        
            End_Object

            Object oCompareprogram_fm is a dbForm
                Entry_Item SysFile.PathSourceCompareTool
                Set Server to oSysFile_DD
                Set Size to 12 140
                Set Location to 249 7
                Set Label_Col_Offset to 0
                Set Label_Row_Offset to 1
                Set Label_Justification_Mode to JMode_Top
                Set Label to "Select Compare Program:"
                Set psToolTip to "Select a file comparison tool, such as 'Beyond Compare', 'WinMerge', 'Araxis Merge' etc.. (Press F4)"
                Set peAnchors to anBottomLeftRight                                                                              
        
                Procedure Prompt
                    Integer bOpen
                    String sFileName
        
                    Get Show_Dialog of oOpenDialog to bOpen
                    If (bOpen) Begin
                        Get File_Name of oOpenDialog to sFileName
                        Set Value to sFileName
                        Set Changed_State to True
                        Set psFileCompareApp of ghoApplication to sFileName
                    End
                End_Procedure  
                
            End_Object

            Object oSelectCompareProgram_btn is a cRDCButton
                Set Size to 14 41
                Set Location to 248 151
                Set Label to "Select"
                Set peAnchors to anBottomRight
                Set psImage to "ActionOpen.ico"
                Set psToolTip to "Select a file comparison tool, such as 'Beyond Compare', 'WinMerge', 'Araxis Merge' etc.. (Press F4)"
            
                Procedure OnClick
                    Send Prompt of oCompareprogram_fm
                End_Procedure
            End_Object    
            
            Object oSourceExplorerProgram_fm is a dbForm
                Entry_Item SysFile.PathStarZen
                Set Server to oSysFile_DD
                Set Size to 12 140
                Set Location to 273 7
                Set Prompt_Button_Mode to pb_PromptOn
                Set Label_Row_Offset to 1
                Set Label_Col_Offset to 0
                Set Label_Justification_Mode to JMode_Top
                Set Label to "StarZen's Source Code Explorer:"
                Set peAnchors to anBottomLeftRight                                                                              
    
                Procedure Prompt
                    Integer bOpen
                    String sFileName
    
                    Get Show_Dialog of oOpenDialog to bOpen
                    If (bOpen) Begin
                        Get File_Name of oOpenDialog to sFileName
                        Set Changed_Value Item 0 to sFileName
                        Set private.psStarZenSourceExplorer of ghoApplication to sFileName
                    End
                End_Procedure
    
            End_Object

            Object oSelectSourceExplorerProgram_btn is a cRDCButton
                Set Size to 14 41
                Set Location to 272 151
                Set Label to "Select"
                Set peAnchors to anBottomRight
                Set psImage to "ActionOpen.ico"
                Set psToolTip to "Select a file comparison tool, such as 'Beyond Compare', 'WinMerge', 'Araxis Merge' etc.. (Press F4)"
            
                Procedure OnClick
                    Send Prompt of oSourceExplorerProgram_fm
                End_Procedure
            End_Object    

            

            Object oTestCompileRefactoredCode_btn is a cRDCButton
                Set Size to 14 100
                Set Location to 257 225
                Set Label to "Compile Refactored Code"
                Set peAnchors to anBottomRight
                Set psImage to "CompileProject.ico"
                Set psToolTip to "Compiles a test program (CompiledRefactoredCode.src) where the refactored code file is Use'd. (F5)"
            
                Procedure OnClick
                    Send CompileRefactoredCode of ghoApplication
                End_Procedure  
                
                Function IsEnabled Returns Boolean
                    Integer iLines
                    Get SC_LineCount of (phoEditor(Self)) to iLines
                    Function_Return (iLines > 1)
                End_Function
        
            End_Object

            Object oShowErrorLog_btn is a cRDCButton
                Set Size to 14 100
                Set Location to 272 225
                Set Label to "Show &Error Log"
                Set peAnchors to anBottomRight
                Set psImage to "CompileProjectErrors.ico"
                Set psToolTip to "Show Error log from compilation (Ctrl+E)"
            
                Procedure OnClick
                    String sAppSrcPath
                    Boolean bExists

                    Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sAppSrcPath
                    Get vFolderFormat sAppSrcPath to sAppSrcPath
                    Get vFilePathExists (sAppSrcPath + CS_TestErrFile) to bExists
                    If (bExists = True) Begin
                        Send ActivateErrorDialog of (Client_Id(phoMainPanel(ghoApplication))) (sAppSrcPath + CS_TestErrFile)
                    End
                End_Procedure  
                
                Function IsEnabled Returns Boolean
                    Boolean bExists
                    String sAppSrcPath
                    Integer iLines

                    Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sAppSrcPath
                    Get vFolderFormat sAppSrcPath to sAppSrcPath
                    Get vFilePathExists (sAppSrcPath + CS_TestErrFile) to bExists
                    Get SC_LineCount of (phoEditorRefactored(ghoApplication)) to iLines
                    Function_Return (bExists = True and iLines > 1)
                End_Function
        
            End_Object

            Object oUseConstraints_cb is a CheckBox
                Set Location to 222 128
                Set Size to 8 109
                Set Label to "Constrain Function Calls"
                Set peAnchors to anBottomRight
                Set psToolTip to "If checked only Functions selected on the 'Function List' tab-page will be called."
                Set phoUseConstraints_cb of ghoApplication to Self
                
                Procedure OnChange
                    Boolean bState
                    Get Checked_State to bState
                    Set Visible_State of oNoOfSelectedFunctions2_fm to (bState = True)
                End_Procedure
            End_Object

            Object oNoOfSelectedFunctions2_fm is a cRDCDbForm
                Entry_Item SysFile.SelectedFunctionTotal
                Set Server to oSysFile_DD
                Set Size to 13 15
                Set Location to 221 106
                Set Label_Justification_Mode to JMode_Right
                Set Label to "Tot No of Selected Functions"
                Set psToolTip to "Total number of functions selected."
                Set Enabled_State to False
                Set peAnchors to anBottomRight
                Set Label_Col_Offset to 3
                Set Label_FontWeight to fw_Bold
                Set FontWeight to fw_Bold
                Set Visible_State to False
            End_Object

        End_Object

    End_Object

    Procedure OnSetFocus
        Set Value of (oLegacyCodeFilename_fm(Self))     to (psCodeFile(phoEditorLegacy(ghoApplication)))
        Set Value of (oRefactoredCodeFilename_fm(Self)) to (psCodeFile(phoEditorRefactored(ghoApplication)))
        Set Value of oNoOfSelectedFunctions2_fm to SysFile.SelectedFunctionTotal
    End_Procedure

    // *** MAIN REFACTORING ROUTINE ***
    // Testing of various refactor functions:
    Procedure RefactoreCode Boolean bUseConstraints
        String[] asLegacyCode asRefactoredCode asSourceFiles
        String sLine sLegacyFileName sRefactoredFileName sFunctionName sParameter
        Handle hoEditor ho
        Integer iSize iCount iTabSize iRetval iFunctionID eSplitMode
        Boolean bChanged bLoopFound bisCOMProcxy bWriteLine bOK
        DateTime dtStart dtEnd
        
        Move (CurrentDateTime()) to dtStart
        Set Value of (oRefactoredCode_Time_fm(Self)) to ""
        Move False to bLoopFound
        Send Activate_oFunctionTableTesting
        
        Get phoEditorLegacy to hoEditor
        Get psCodeFile of hoEditor to sLegacyFileName
        Get IsDataFlexCOMProxyClassesFile of ghoRefactorFunctionLibrary sLegacyFileName to bisCOMProcxy
        If (bisCOMProcxy = True) Begin
            Send Info_Box "This file is marked as a Studio COM Proxy classes auto generated file and will _not_ be refactored!"
            Procedure_Return
        End

        Send UpdateStatusBar of hoEditor "" True
        Get EditorDataAsStringArray of hoEditor to asLegacyCode
        Move (SizeOfArray(asLegacyCode)) to iSize
        Decrement iSize  

        Get phoEditorRefactored to hoEditor
        Get psCodeFile of hoEditor to sRefactoredFileName
        Set phoEditor to hoEditor
        If (iSize > 0) Begin
            Send Delete_Data of hoEditor
        End        
        Else Begin
            Send Info_Box "No Legacy code found."
            Procedure_Return
        End
        
        // Suspend all timers while we work.
        Send SuspendGUI of Desktop True
        Set pbIsRefactoring of ghoApplication to True   
        Send Cursor_Wait of Cursor_Control
        
        For iCount from 0 to iSize
            // Need this to show "Number of lines:" changes
            Send PumpMsgQueue of Desktop   
            // Read next source line
            Move asLegacyCode[iCount] to sLine
            
            // These are functions that may potentially remove the line (Sets bWriteLIne to False)
            // eRemove_Functions
            Move True to bWriteLine
            Constraint_Set (Self + 1) Clear  
            Constrained_Clear eq FunctionsA by Index.2   
            If (bUseConstraints = True) Begin
                Constrain FunctionsA.Selected eq True
            End
            Constrain FunctionsA.Type eq eRemove_Function
            Constrained_Find First FunctionsA by Index.2
            While (Found)                          
                Move (Trim(FunctionsA.Parameter)) to sParameter
                Move (Trim(FunctionsA.Function_Name)) to sFunctionName
                Move (Eval("get_" - (sFunctionName))) to iFunctionID
                Get iFunctionID of ghoRefactorFunctionLibrary (&sLine) sParameter to bChanged
                If (bChanged = True) Begin
                    Move False to bWriteLine
                End
                Constrained_Find Next
            Loop
            
            If (bWriteLine = True) Begin
                
                // eStandard_Function
                Constraint_Set (Self + 2) Clear  
                Constrained_Clear eq FunctionsA by Index.2
                If (bUseConstraints = True) Begin
                    Constrain FunctionsA.Selected eq True
                End
                Constrain FunctionsA.Type eq eStandard_Function
                Constrained_Find First FunctionsA by Index.2
                While (Found)
                    Move (Trim(FunctionsA.Parameter)) to sParameter
                    Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
                    Move (Eval("get_" - (sFunctionName))) to iFunctionID
                    Get iFunctionID of ghoRefactorFunctionLibrary (&sLine) sParameter to bChanged
                    Constrained_Find Next
                Loop
                
                If (iCount < iSize) Begin
                    Move (sLine + CS_CRLF) to sLine
                End            
                Send AppendText of hoEditor sLine
            End
        Loop  

        Send PumpMsgQueue of Desktop  
        Send UpdateStatusBar of hoEditor "Executing Editor functions..." True
        Get EditorDataAsStringArray of hoEditor to asRefactoredCode
        
        // eEditor_Function
        Move False to bChanged
        Constraint_Set (Self + 3) Clear  
        Constrained_Clear eq FunctionsA by Index.2
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eEditor_Function
        Constrained_Find First FunctionsA by Index.2
        While (Found)
            Move (Trim(FunctionsA.Parameter)) to sParameter
            Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
            If (Lowercase(sFunctionName) <> Lowercase(CS_EditorDropSelf)) Begin
                Move (Eval("get_" - (sFunctionName))) to iFunctionID
                Get iFunctionID of ghoRefactorFunctionLibrary (&asRefactoredCode) sParameter to bOK
                If (bOK = True) Begin
                    Move True to bChanged
                End
            End
            Constrained_Find Next
        Loop
        If (bChanged = True) Begin
            Send SaveFile of hoEditor                    
            Get EditorDataAsStringArray of hoEditor to asRefactoredCode
        End
        Send UpdateStatusBar of hoEditor "" True

        // eOther_Function - A source file as a string array is passed.
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.2
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eOther_Function
        Constrained_Find First FunctionsA by Index.2
        While (Found)
            Move (Trim(FunctionsA.Parameter)) to sParameter
            Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
            Move (Eval("get_" - (sFunctionName))) to iFunctionID
            Get iFunctionID of ghoRefactorFunctionLibrary (&asRefactoredCode) sParameter to bOK
            If (bOK = True) Begin
                Move True to bChanged
            End
            Constrained_Find Next
        Loop
        If (bChanged = True) Begin
            Get WriteDataToEditor of hoEditor asRefactoredCode to bOK
        End
        
        // eOther_FunctionAll - All source files with full pathing is passed to these functions as a string array.
        Move sRefactoredFileName to asSourceFiles[0]
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.2
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eOther_FunctionAll
        Constrained_Find First FunctionsA by Index.2
        While (Found)
            Move (Trim(FunctionsA.Parameter)) to sParameter
            Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
            Move (Eval("get_" - (sFunctionName))) to iFunctionID
            Get iFunctionID of ghoRefactorFunctionLibrary (&asSourceFiles) sParameter to bOK
            If (bOK = True) Begin
                Move True to bChanged
            End
            Constrained_Find Next
        Loop
        If (bChanged = True) Begin
            Send LoadFile of hoEditor sRefactoredFileName
        End
        
        // eReport_Function - A source file as a string array is passed.
        // Makes no source code changes
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.2
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eReport_Function
        Constrained_Find First FunctionsA by Index.2
        While (Found)
            Move (Trim(FunctionsA.Parameter)) to sParameter
            Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
            Move (Eval("get_" - (sFunctionName))) to iFunctionID
            Get iFunctionID of ghoRefactorFunctionLibrary (&asRefactoredCode) sParameter to bOK
            If (bOK = True) Begin
                Move True to bChanged
            End            
            Constrained_Find Next
        Loop
        
        // eReport_FunctionAll - All source files with full pathing is passed to these functions as an array.
        // Makes no source code changes
        Move sLegacyFileName to asSourceFiles[0]
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.2
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eReport_FunctionAll
        Constrained_Find First FunctionsA by Index.2
        While (Found)
            Move (Trim(FunctionsA.Parameter)) to sParameter
            Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
            Move (Eval("get_" - (sFunctionName))) to iFunctionID
            Get iFunctionID of ghoRefactorFunctionLibrary (&asSourceFiles) sParameter to bOK
            If (bOK = True) Begin
                Move True to bChanged
            End
            Constrained_Find Next
        Loop
        
        Move (CurrentDateTime()) to dtEnd
        Set Value of (oRefactoredCode_Time_fm(Self)) to (dtEnd - dtStart)
        Set pbIsRefactoring of ghoApplication to False
        Send UpdateStatusBar of hoEditor "Ready!" True
        Send Cursor_Ready of Cursor_Control
        // Re-enable timers:
        Send SuspendGUI of Desktop False
    End_Procedure
    
End_Object

Procedure JumpToSourceLine Integer iLine
    Handle hoEdit
    Move (phoEditorRefactored(oFunctionTableTesting(Self))) to hoEdit
    Send Activate_oFunctionTableTesting
    Send JumpToSourceLine of hoEdit iLine    
End_Procedure
            