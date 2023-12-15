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
Use cRefactorScintillaEditor.pkg
Use vwin32fh.pkg

Use cSysFileDataDictionary.dd
Use cFunctionsDataDictionary.dd  
Use cFunctionsADataDictionary.dd
Use cRefactorEngine.pkg

Activate_View Activate_oRefactorTestBench for oRefactorTestBench
Object oRefactorTestBench is a cRefactorDbView
    Set Border_Style to Border_Thick
    Set Size to 282 929
    Set Location to 2 7
    Set Label to "Test Bench"
    Set pbAutoActivate to True
    Set Maximize_Icon to True 
    Set pbAcceptDropFiles to True
    Set phoRefactorView of ghoApplication to Self
    
    Object oSysFile_DD is a cSysFileDataDictionary
        // We don't care about data-loss in this view.
        // Note that it won't help to try to set the Data_Loss & Exit_Loss
        // messages because the change_state is embedded into almost
        // every db-class, so one change affects in lots of places.
        Function Should_Save Returns Integer
            Function_Return 0
        End_Function

    End_Object

    Object oFunctions_DD is a cFunctionsADataDictionary
        // We are actually just interested in saving the SysFile,
        // as the checkbox "Use selected Functions Only" may have been changed.
        // A Request_Save is send automatically when a new refactoring process starts.
        Procedure Request_Save
            Send Request_Save of oSysFile_DD
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
        
            Object oLegacyCode_edt is a cRefactorScintillaEditor
                Set Size to 176 484
                Set Location to 17 6
                Set phoEditorLegacy of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_LegacyCode)

                Property Boolean pbIsFileDropped False
                
                Procedure OnFileDropped String sFileName Boolean bLast
                    Set Value of oLegacyCodeFilename_fm to sFileName 
                    Send LoadFile sFileName 
                    Send Activate
                End_Procedure
                
                // Important: Must be after the object has been paged, else the text won't show
                Procedure Page_Object Boolean bPage
                    String[] asLegacyCode
                    String sFileName                         
                    Handle ho   
                    Integer iLines
                    
                    Forward Send Page_Object bPage
                    If (bPage = True) Begin
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
                Set Label_Row_Offset to 1
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
    
            Object oRefactoredCode_edt is a cRefactorScintillaEditor
                Set Size to 176 418
                Set Location to 17 6
                Delegate Set phoEditor to (Self)
                Set phoEditorRefactored of ghoApplication to (Self)
                Set phoEditor of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_RefactoredCode)
                Set phoCodeMaxEditor to Self
        
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
                Set Label_Row_Offset to 1
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
                Set Size to 10 55
                Set Location to 197 90
                Set Enabled_State to False
                Set Label to "Elapsed Time:"
                Set Label_Col_Offset to 0    
                Set Label_Justification_Mode to JMode_Right
                Set Form_Datatype to Mask_Clock_Window
                Set Label_FontWeight to fw_Bold
                Set FontWeight to fw_Bold
                Set Label_Row_Offset to 1
                Set peAnchors to anBottomLeft
            End_Object

            Object oAction_grp is a cRDCDbHeaderGroup
                Set Size to 66 418
                Set Location to 210 6
                Set Label to "Refactor Code"
                Set psImage to "DFRefactor.ico"
                Set psNote to "Call selected functions"
                Set psToolTip to "Click the 'Start Refactoring!' button to execute selected refactoring functions."
                Set pbUseLargeFontHeight to True
                Set peAnchors to anBottomLeftRight

                Object oNoOfSelectedFunctions_fm is a cRDCDbForm
                    Set Size to 13 30
                    Set Location to 36 170
                    Set Label_Justification_Mode to JMode_Right
                    Set Label to "Selected Functions:"
                    Set psToolTip to "Total number of functions selected."
                    Set Label_Col_Offset to 1
                    Set Label_FontWeight to fw_Bold
                    Set FontWeight to fw_Bold 
                    Set Form_Justification_Mode to Form_DisplayRight
                    Set Enabled_State to False
                    Set peAnchors to anBottomLeft

                    Object oSelectedFunctionsIdleHandler is a cIdleHandler
                        Set pbEnabled to True
                        Procedure OnIdle
                            Integer iSelectedFuncs iTotalFuncs
                            Move SysFile.SelectedFunctionTotal to iSelectedFuncs
                            Get TotalNoOfFunctions of (Main_DD(Self)) to iTotalFuncs
                            Set Value of oNoOfSelectedFunctions_fm to (String(iSelectedFuncs) * "(" + String(iTotalFuncs) + ")")
                        End_Procedure
                    End_Object

                End_Object

                Object oSysFile_CountSourceLines_cb is a dbCheckBox
                    Entry_Item SysFile.bCountSourceLines
                    Set Server to oSysFile_DD
                    Set Location to 13 203
                    Set Size to 8 109
                    Set Label to "Count Source Lines (only)"   
//                    Set FontWeight to fw_Bold
//                    Set peAnchors to anBottomRight 
                    Set psToolTip to (String("This function will tell you how large your workspace is by counting the number of 'real' source lines for all selected folders and file extensions.") + String(CS_CR) + String("Note: It will skip blank or comments lines, and it will not count files generated by the Studio from COM components.") + String(CS_CR) + String(CS_CR) + String("This function needs be run in solitude, all other functions will be ignored."))
                    
                    // Weird voodoo(1) for db-controls connected to system files.
                    // They simply does not work the way you would suppose (as they do with other tables)
                    // This is a work-around for having the control auto-save on a change.  
                    // We need this as the "Start refactoring" button relies on properly updated 
                    // values of the Sysfile.
                    // The problem is that the checked_state and DDO field value is "out of sync".
                    // This fixes it:
                    Procedure OnChange
                        Boolean bSelected
                        Get Checked_State to bSelected
                        Set Field_Changed_Value of oSysFile_DD Field SysFile.bCountSourceLines to bSelected
                        Send Request_Save  of oSysFile_DD 
                    End_Procedure    
                    
//                    Procedure Refresh Integer iNotifyMode
//                        Boolean bSelected
//                        Integer iSelectedFunctions
//                        
//                        Forward Send Refresh iNotifyMode
//                        Get Checked_State to bSelected
//                        If (bSelected = True) Begin
//                            Move 1 to iSelectedFunctions
//                        End
//                        Else Begin
//                            Get Field_Current_Value of oSysFile_DD Field SysFile.SelectedFunctionTotal to iSelectedFunctions
//                        End
//                        Set Value of oNoOfSelectedFunctions2_fm to iSelectedFunctions
//                    End_Procedure
        
                End_Object
    
                Object oReadOnly_cb is a dbCheckbox
                    Entry_Item SysFile.bReadOnly
                    Set Server to oSysFile_DD
                    Set Location to 13 303
                    Set Size to 8 109
                    Set Label to "Read Only"
                    Set peAnchors to anBottomLeft
                    Set psToolTip to "If checked, no changes to the source code will be made - only shows statistics."
                End_Object
    
                Object oRefactor_btn is a cRDCButton
                    Set Size to 30 98
                    Set Location to 27 203
                    Set Label to "Start &Refactoring!"
                    Set Default_State to True
                    Set psToolTip to "Refactors the legacy code from the left editor, then saves it to disk. (Ctrl+F5)"
                    // Note: We use Form_FontWeight instead of FontWeight to _not_ make the object larger
                    // because of the bold font.
                    Set Form_FontWeight to FW_BOLD
                    Set psImage to "Start.ico"
                    Set piImageMarginLeft to 7
                    Set piImageSize to 32
                    Set peAnchors to anBottomLeft
                    
                    Procedure OnClick   
//                        Boolean bUseConstraints
//                        Get Checked_State of (phoUseConstraints_cb(ghoApplication)) to bUseConstraints
//                        Delegate Send RefactoreCode bUseConstraints
                        Delegate Send RefactoreCode
                    End_Procedure 
                    
                    Function IsEnabled Returns Boolean   
//                        Integer iFunctions
//                        Boolean bUseConstraints
//                        Get Checked_State of (phoUseConstraints_cb(ghoApplication)) to bUseConstraints
                        Function_Return (SysFile.SelectedFunctionTotal > 0 or SysFile.bCountSourceLines = True)
                    End_Function
                
                End_Object

                Object oCompileRefactoredCode_btn is a cRDCButton
                    Set Size to 14 53
                    Set Location to 29 303
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

                Object oShowCompileErrors_btn is a cRDCButton
                    Set Size to 14 53
                    Set Location to 43 303
                    Set Label to "&Errors"
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
        
                Object oStartCompareProgram_btn is a cRDCButton
                    Set Size to 23 53
                    Set Location to 32 363
                    Set Label to "Co&mpare Code"
                    Set peAnchors to anBottomLeft
                    Set psImage to "Compare.ico"
                    Set psToolTip to "Starts the selected compare program and passes the two source files (Ctrl+M). It automatically saves the source files first."
                    Set MultiLineState to True
                
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

            End_Object
            
        End_Object

    End_Object

    Procedure OnSetFocus
        Set Value of (oLegacyCodeFilename_fm(Self))     to (psCodeFile(phoEditorLegacy(ghoApplication)))
        Set Value of (oRefactoredCodeFilename_fm(Self)) to (psCodeFile(phoEditorRefactored(ghoApplication))) 
    End_Procedure
    
    //
    // ToDo: *** MAIN FUNCTION CALL ***
    //
    Procedure RefactoreCode //Boolean bUseConstraints
        String sLegacyFileName sRefactoredFileName
        Handle hoLegacyEditor hoRefactoredEditor
        Integer iRetval
        Boolean bOK
        tRefactorFiles RefactorFiles
        
        Move False to Err
        Get DeleteCompileErrorsFile to iRetval
        If (iRetval <> 0) Begin
            Get YesNo_Box "Could not delete the compiler's error file. Continue?" to iRetval
            If (iRetval <> MBR_Yes) Begin
                Procedure_Return
            End
        End 
        
        Set Value of oRefactoredCode_Time_fm to ""
        Get phoEditorLegacy     of ghoApplication     to hoLegacyEditor
        Get psCodeFile          of hoLegacyEditor     to sLegacyFileName
        Get phoEditorRefactored of ghoApplication     to hoRefactoredEditor        
        Get psCodeFile          of hoRefactoredEditor to sRefactoredFileName
        // We need to copy the legacy file to the refactor file before we start our work,
        // because else the ghoRefactorEngine would overwrite the sLegacyFileName with
        // changes:
        Get vCopyFile sLegacyFileName sRefactoredFileName to bOK
        Set psCurrentSourceFileName of ghoApplication to sRefactoredFileName
        
        Get CollectFileData of ghoApplication to RefactorFiles
        If (Err = True) Begin
            Procedure_Return
        End

        // Start the Engine!
        Send StartRefactoringEngine of ghoRefactorEngine RefactorFiles hoRefactoredEditor
        // Save the result
        Send SaveFile of hoRefactoredEditor
        Set Value of oRefactoredCode_Time_fm to (psTotalTime(ghoRefactorEngine))
    End_Procedure

    // Delete the .err file if exists.
    Function DeleteCompileErrorsFile Returns Integer
        String sPath sErrFile
        Integer iRetval  
        Boolean bExists
        
        Move 0 to iRetval
        Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sPath
        Get vFolderFormat sPath to sPath
        Move CS_TestProgram to sErrFile
        Move (Replace(".src", sErrFile, ".err")) to sErrFile
        File_Exist  (sPath + sErrFile) bExists
        If (bExists = True) Begin
            Get vDeleteFile (sPath + sErrFile) to iRetval
        End            
        Function_Return iRetval
    End_Function
        
    Procedure Activating
        Send Request_Assign of oSysFile_DD
        Send Refind_Records of oSysFile_DD
    End_Procedure
End_Object

Procedure JumpToSourceLine Integer iLine
    Handle hoEdit
    Move (phoEditorRefactored(ghoApplication)) to hoEdit
    Send Activate_oRefactorTestBench
    Send JumpToSourceLine of hoEdit iLine    
End_Procedure
            