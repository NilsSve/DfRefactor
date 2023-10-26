Use Windows.pkg
Use cDbSplitterContainer.pkg
Use Dfenrad.pkg
Use File_dlg.pkg
Use seq_chnl.pkg

Use cRefactorDbView.pkg
Use cRDCDbSpinForm.pkg
Use cRDCDbForm.pkg
Use cRDCDbHeaderGroup.pkg
Use cFileNameForm.pkg
Use cScintillaRefactorEditor.pkg
Use oEditorProperties.pkg
//Use mfiletime.pkg
Use vwin32fh.pkg

Use LogFileDialog.dg
Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd  
Use cFunctionsADataDictionary.dd

Activate_View Activate_oRefactorTestBench for oRefactorTestBench
Object oRefactorTestBench is a cRefactorDbView
    Set Border_Style to Border_Thick
    Set Size to 282 886
    Set Location to 2 7
    Set Label to "Test Bench"
    Set pbAutoActivate to True
    Set Maximize_Icon to True 
    Set pbAcceptDropFiles to True
    Set phoTestView of ghoApplication to Self

    Object oSysFile_DD is a cSysFileDataDictionary
        // We don't care about data-loss in this view.
        // Note that it won't help to try to set the Data_Loss & Exit_Loss
        // messages because the change_state is embedded into almost
        // every db-class, so one change affects in lots of places.
        Function Should_Save Returns Integer
            Function_Return 0
        End_Function

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

Define CS_Splitters              for "Splitters"
Define CS_TestingViewSplitterPos for "TestingViewSplitterPos"

    Object oSplitterContainer is a cDbSplitterContainer
        Set piSplitterLocation to 498
        
        // ToDo: This messes up the dynamic sizing of objects at startup.
        // So this is probably to early to make this kind of manipulation.
        // Research is needed where & when it should be made.
//        Procedure Page_Delete 
//            Integer iLocation
//            Get piGuiSplitterLocation to iLocation
//            Send WriteDword of ghoApplication CS_Splitters CS_TestingViewSplitterPos iLocation
//            Forward Send Page_Delete
//        End_Procedure 
//        
//        Procedure Page Integer iPageObject
//            Integer iLocation
//            
//            Get ReadDword of ghoApplication CS_Splitters CS_TestingViewSplitterPos 0 to iLocation
//            If (iLocation <> 0) Begin
//                Set piGuiSplitterLocation to iLocation
//            End
//            Forward Send Page iPageObject
//        End_Procedure

        Object oSplitterContainerChild1 is a cDbSplitterContainerChild

            Object oOpenDialog is a OpenDialog
                Set Dialog_Caption to "Select your file compare application of choice"
                Set Filter_String to "Programs|*.exe|Any file|*.*"
            End_Object

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 74
                Set Location to 4 8
                Set Label to "Legacy Code: (Before)"
                Set FontWeight to fw_Bold
                Set FontPointHeight to 10
            End_Object

            Object oInfo_tb is a TextBox
                Set Size to 10 251
                Set Location to 5 126
                Set Label to "- You can drag && drop a source file from Windows Explorer to this editor object"
            End_Object
        
            Object oLegacyCode_edt is a cScintillaRefactorEditor
                Set Size to 176 484
                Set Location to 17 6
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
                        Set Value of oLegacyCodeFilename_fm to sFileName 
                        Send LoadFile sFileName 
                        Send Activate
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
                        Move (oLegacyCodeFilename_fm(Self)) to ho
                        Get psCodeFile of (phoEditorLegacy(ghoApplication)) to sFileName
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
                Set Size to 10 20
                Set Location to 197 470
                Set Enabled_State to False
                Set Label to "No of Lines:"
                Set Value to "0"
                Set Label_Col_Offset to 0 
                Set Label_Justification_Mode to JMode_Right
                Set Form_Datatype to 0 
                Set Label_FontWeight to fw_Bold
                Set Label_Row_Offset to 2
                Set FontWeight to fw_Bold
                Set peAnchors to anBottomRight
                
                Procedure Set Value Integer iItem String sValue
                    Integer iValue
                    String sFormatString 
                    Move sValue to iValue
                    Move ",#." to sFormatString
                    Move (FormatValue(iValue, sFormatString)) to sValue
                    Forward Set Value to sValue
                End_Procedure
            End_Object
        
            Object oSaveFiles_grp is a cRDCDbHeaderGroup
                Set Size to 66 483
                Set Location to 210 7
                Set Label to "Input/Output Files:"
                Set psImage to "InputOutput.ico"
                Set psNote to "Fixed names for input/output files"
                Set psToolTip to "These two file names are used by the TEST-BENCH. The names are fixed and cannot be changed."
                Set peAnchors to anBottomLeftRight

                Object oLegacyCodeFilename_fm is a cFileNameForm
                    Set Size to 13 344
                    Set Location to 28 129
                    Set Label to "Legacy Code (left editor)"
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set peAnchors to anBottomLeftRight 
                    Set Label_FontWeight to fw_Bold
                End_Object

                Object oRefactoredCodeFilename_fm is a cFileNameForm
                    Set Size to 13 343
                    Set Location to 43 129
                    Set Label to "Refactored Code (right editor)"
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set peAnchors to anBottomLeftRight
                    Set Label_FontWeight to fw_Bold
                End_Object

            End_Object

        End_Object

        Object oSplitterContainerChild2 is a cDbSplitterContainerChild

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 84
                Set Location to 4 5
                Set Label to "Refactored Code: (After)"
                Set FontWeight to fw_Bold
            End_Object
    
            Object oRefactoredCode_edt is a cScintillaRefactorEditor
                Set Size to 176 377
                Set Location to 17 6
                Delegate Set phoEditor to (Self)
                Set phoEditorRefactored of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_RefactoredCode)
        
                Procedure OnModified
                    Integer iLines
                    Get Line_Count to iLines
                    Set Value of oRefactoredCode_NoOfLines_fm to iLines                    
                End_Procedure          
                
                On_Key Key_Ctrl+Key_E Send Execute of (oErrorLog_ToolItem(ghoCommandBars))
            End_Object

            Object oRefactoredCode_NoOfLines_fm is a Form
                Set Size to 10 20
                Set Location to 197 16
                Set Enabled_State to False
                Set Value to "0"
                Set Form_Datatype to 0 
                Set FontWeight to fw_Bold
                Set peAnchors to anBottomLeft
                
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
                Set Location to 197 72
                Set Enabled_State to False
                Set Label to "Elapsed:"
                Set Label_Col_Offset to 0    
                Set Label_Justification_Mode to JMode_Right
                Set Form_Datatype to Mask_Clock_Window
                Set Label_FontWeight to fw_Bold
                Set Label_Row_Offset to 2
                Set FontWeight to fw_Bold
                Set peAnchors to anBottomLeft
            End_Object

            Object oAction_grp is a cRDCDbHeaderGroup
                Set Size to 66 374
                Set Location to 210 6
                Set Label to "Refactor Code"
                Set psImage to "DFRefactor.ico"
                Set psNote to "Select actions"
                Set psToolTip to "Click buttons to perform various refactoring actions."
                Set pbUseLargeFontHeight to True
                Set peAnchors to anBottomLeftRight

                Object oNoOfSelectedFunctions2_fm is a cRDCDbForm
                    Entry_Item SysFile.SelectedFunctionTotal
                    Set Server to oSysFile_DD
                    Set Size to 13 13
                    Set Location to 30 141
                    Set Label_Justification_Mode to JMode_Right
                    Set Label to "Number of Selected Functions:"
                    Set psToolTip to "Total number of functions selected."
                    Set Enabled_State to False
                    Set peAnchors to anBottomLeft
                    Set Label_Col_Offset to 1
                    Set Label_FontWeight to fw_Bold
                    Set FontWeight to fw_Bold 
                End_Object
    
                Object oUseConstraints_cb is a dbCheckbox
                    Entry_Item SysFile.bConstrainFunctionCalls
                    Set Server to oSysFile_DD
                    Set Location to 44 40
                    Set Size to 8 109
                    Set Label to "Use selected Functions only"
                    Set peAnchors to anBottomLeft
                    Set psToolTip to "If checked only Functions selected for the 'Function List' tab-page will be called."
                    Set phoUseConstraints_cb of ghoApplication to Self
                    
                    Procedure OnChange
                        Boolean bState  
                        Integer iFunctions    
                        Send Request_Save
                        Get Checked_State to bState
                        If (bState = False) Begin                                
                            Get_Attribute DF_FILE_RECORDS_USED of Functions.File_Number to iFunctions
                        End
                        Else Begin
                            Move SysFile.SelectedFunctionTotal to iFunctions
                        End
                        Set Value of oNoOfSelectedFunctions2_fm to iFunctions 
                    End_Procedure 
                    
                End_Object
    
                Object oRefactor_btn is a cRDCButton
                    Set Size to 30 98
                    Set Location to 27 156
                    Set Label to "Start &Refactoring!"
                    Set peAnchors to anBottomLeft
                    Set Default_State to True
                    // Note: We use Form_FontWeight instead of FontWeight to _not_ make the object larger
                    // because of the bold font.
                    Set Form_FontWeight to FW_BOLD
                    Set psImage to "Start.ico"
                    Set psToolTip to "Refactors the legacy code from the left editor, then saves it to disk. (Ctrl+F5)"
                    Set piImageSize to 32
                    
                    Procedure OnClick   
                        String sPath sErrFile                               
                        Integer iRetval
                        Boolean bUseConstraints
                        Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sPath
                        Get vFolderFormat sPath to sPath
                        Move CS_TestProgram to sErrFile
                        Move (Replace(".src", sErrFile, ".err")) to sErrFile
                        Get vDeleteFile (sPath + sErrFile) to iRetval
                        Get Checked_State of (phoUseConstraints_cb(ghoApplication)) to bUseConstraints
                        Delegate Send RefactoreCode bUseConstraints
                    End_Procedure 
                    
                    Function IsEnabled Returns Boolean   
                        Boolean bChecked
                        Integer iFunctions
                        Get Checked_State of oUseConstraints_cb to bChecked
                        Function_Return (SysFile.SelectedFunctionTotal > 0 or bChecked = False)
                    End_Function
                
                End_Object
        
                Object oCompareProgram_btn is a cRDCButton
                    Set Size to 14 53
                    Set Location to 27 258
                    Set Label to "Co&mpare"
                    Set peAnchors to anBottomLeft
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
    
                Object oTestCompileRefactoredCode_btn is a cRDCButton
                    Set Size to 14 53
                    Set Location to 43 258
                    Set Label to "Compile"
                    Set peAnchors to anBottomLeft
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
                    Set Size to 23 53
                    Set Location to 31 315
                    Set Label to "Compile &Errors"
                    Set peAnchors to anBottomLeft
                    Set psImage to "CompileErrors.ico"
                    Set psToolTip to "Show compilation errors (Ctrl+E)"
                    Set MultiLineState to True
                
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

            End_Object
            
        End_Object

    End_Object

    Procedure OnSetFocus
        Set Value of (oLegacyCodeFilename_fm(Self))     to (psCodeFile(phoEditorLegacy(ghoApplication)))
        Set Value of (oRefactoredCodeFilename_fm(Self)) to (psCodeFile(phoEditorRefactored(ghoApplication)))
        Send OnChange of oUseConstraints_cb 
    End_Procedure

    // *** MAIN REFACTORING ROUTINE ***  
    //
    // Testing of refactor functions.
    // Can be all or a selection of functions.
    Procedure RefactoreCode Boolean bUseConstraints
        String[] asLegacyCode asRefactoredCode asSourceFiles
        String sLine sLegacyFileName sRefactoredFileName sFunctionName sParameter
        Handle hoLegacyEditor hoRefactoredEditor ho
        Integer iSize iCount iTabSize iRetval iFunctionID eSplitMode
        Boolean bChanged bLoopFound bisCOMProcxy bWriteLine bOK
        DateTime dtStart dtEnd

        Get Checked_State of oUseConstraints_cb to bOK
        If (SysFile.SelectedFunctionTotal = 0 and bOK = True) Begin
            Send Info_Box "You need to select at least one function first. Or unselect the checkbox 'Use selected Functions only'"
            Procedure_Return
        End
        
        Move (CurrentDateTime()) to dtStart
        Set Value of (oRefactoredCode_Time_fm(Self)) to ""
        Move False to bLoopFound
        Send Activate_oRefactorTestBench
        
        Get phoEditorLegacy of ghoApplication to hoLegacyEditor
        Get psCodeFile      of hoLegacyEditor to sLegacyFileName
        Get _IsDataFlexCOMProxyClassesFile of ghoRefactorFunctionLibrary sLegacyFileName to bisCOMProcxy
        If (bisCOMProcxy = True) Begin
            Send Info_Box "This file is marked as a Studio COM Proxy classes auto generated file and will _not_ be refactored!"
            Procedure_Return
        End

        Send UpdateStatusBar of hoLegacyEditor "" True
        Get EditorDataAsStringArray of hoLegacyEditor to asLegacyCode
        Move (SizeOfArray(asLegacyCode)) to iSize
        Decrement iSize  

        Get phoEditorRefactored of ghoApplication to hoRefactoredEditor        
        Get psCodeFile of hoRefactoredEditor      to sRefactoredFileName
        If (iSize > 0) Begin
            Send Delete_Data of hoRefactoredEditor
        End        
        Else Begin
            Send Info_Box "No Legacy code found."
            Procedure_Return
        End
        
        Send InitializeInterface of ghoRefactorFunctionLibrary
        // Suspend all timers while we work.
        Send SuspendGUI of Desktop True
        Set pbIsRefactoring of ghoApplication to True   
        Send Cursor_Wait of Cursor_Control

        If (SysFile.SelectedStandardFunctions > 0 or bUseConstraints = False) Begin
            For iCount from 0 to iSize
                // Need this to show "Number of lines:" changes
                Send PumpMsgQueue of Desktop   
                // Read next source line
                Move asLegacyCode[iCount] to sLine
                Send InitializeTokenizer of ghoRefactorFunctionLibrary sLine
                
                // eRemove_Functions
                // These are functions that may potentially remove the line (Sets bWriteLIne to False),
                // so we execute them first.
                Move True to bWriteLine
                Constraint_Set (Self + 1) Clear  
                Constrained_Clear eq FunctionsA by Index.4   
                If (bUseConstraints = True) Begin
                    Constrain FunctionsA.Selected eq True
                End
                Constrain FunctionsA.Type eq eRemove_Function
                Constrained_Find First FunctionsA by Index.4
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
                
                // eStandard_Function - Line-by-line
                If (bWriteLine = True) Begin
                    Constraint_Set (Self + 2) Clear  
                    Constrained_Clear eq FunctionsA by Index.4
                    If (bUseConstraints = True) Begin
                        Constrain FunctionsA.Selected eq True
                    End
                    Constrain FunctionsA.Type eq eStandard_Function
                    Constrained_Find First FunctionsA by Index.4
                    While (Found)
                        Move (Trim(FunctionsA.Parameter)) to sParameter
                        Move (Trim(FunctionsA.Function_Name)) to sFunctionName 
                        Move (Eval("get_" - (sFunctionName))) to iFunctionID
                        Get iFunctionID of ghoRefactorFunctionLibrary (&sLine) sParameter to bChanged
                        Constrained_Find Next
                    Loop
                    
                    Move sLine to asRefactoredCode[iCount]
                End
            Loop  
            
            If (SizeOfArray(asRefactoredCode) <> 0) Begin
                Get WriteStringArrayToDisk of hoRefactoredEditor asRefactoredCode to bOK
                If (bOK = True) Begin
                    Send LoadFile of hoRefactoredEditor sRefactoredFileName
                End
            End
            Send PumpMsgQueue of Desktop  
            If (SysFile.SelectedEditorFunctions <> 0) Begin
                Get EditorDataAsStringArray of hoRefactoredEditor to asRefactoredCode
            End
        End

        // eEditor_Function
        Send UpdateStatusBar of hoRefactoredEditor "Executing Editor functions..." True  
        // If no "eStandard_Function" calls were made, we need to load the source file
        // into the refactor editor.
        If (SizeOfArray(asRefactoredCode) = 0) Begin
            Move asLegacyCode to asRefactoredCode
            Send LoadFile of hoRefactoredEditor sLegacyFileName  
            Set psCodeFile of hoRefactoredEditor to sRefactoredFileName
            Get WriteToDisk of hoRefactoredEditor to bOK
        End
        Move False to bChanged
        Constraint_Set (Self + 3) Clear  
        Constrained_Clear eq FunctionsA by Index.4
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eEditor_Function
        Constrained_Find First FunctionsA by Index.4
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
            Get EditorDataAsStringArray of hoRefactoredEditor to asRefactoredCode
            Get WriteStringArrayToDisk  of hoRefactoredEditor asRefactoredCode to bOK
            If (bOK = True) Begin
                Send LoadFile of hoRefactoredEditor sRefactoredFileName
            End
        End
        Send UpdateStatusBar of hoRefactoredEditor "" True

        // eOther_Function - One source file as a string array is passed.
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.4
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eOther_Function
        Constrained_Find First FunctionsA by Index.4
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
            Get WriteStringArrayToDisk of hoRefactoredEditor asRefactoredCode to bOK
            If (bOK = True) Begin
                Send LoadFile of hoRefactoredEditor sRefactoredFileName
            End
        End
        
        // eOther_FunctionAll - All source files with full pathing is passed to these functions as a string array.
        Move sRefactoredFileName to asSourceFiles[0]
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.4
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eOther_FunctionAll
        Constrained_Find First FunctionsA by Index.4
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
            Get WriteStringArrayToDisk of hoRefactoredEditor asRefactoredCode to bOK
            If (bOK = True) Begin
                Send LoadFile of hoRefactoredEditor sRefactoredFileName
            End
        End
        
        // eReport_Function - A source file as a string array is passed.
        // Makes no source code changes
        Move False to bChanged
        Constraint_Set (Self + 4) Clear  
        Constrained_Clear eq FunctionsA by Index.4
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eReport_Function
        Constrained_Find First FunctionsA by Index.4
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
        Constrained_Clear eq FunctionsA by Index.4
        If (bUseConstraints = True) Begin
            Constrain FunctionsA.Selected eq True
        End
        Constrain FunctionsA.Type eq eReport_FunctionAll
        Constrained_Find First FunctionsA by Index.4
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
//            Get WriteStringArrayToDisk of hoRefactoredEditor asRefactoredCode to bOK
//            If (bOK = True) Begin
                Send LoadFile of hoRefactoredEditor sRefactoredFileName
//            End
        End

        Move (CurrentDateTime()) to dtEnd
        Set Value of (oRefactoredCode_Time_fm(Self)) to (dtEnd - dtStart)
        Set pbIsRefactoring of ghoApplication to False
        Send UpdateStatusBar of hoRefactoredEditor "Ready!" True
        Send Cursor_Ready of Cursor_Control
        // Re-enable timers:
        Send SuspendGUI of Desktop False
    End_Procedure

End_Object

Procedure JumpToSourceLine Integer iLine
    Handle hoEdit
    Move (phoEditorRefactored(ghoApplication)) to hoEdit
    Send Activate_oRefactorTestBench
    Send JumpToSourceLine of hoEdit iLine    
End_Procedure
            