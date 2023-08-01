// C:\Projects\DF18\DfRefactor\AppSrc\FunctionMaintenance.vw
// Functions Maintenance
//
Use cRefactorDbView.pkg
Use DFEntry.pkg
Use cDbScrollingContainer.pkg
Use Dfenrad.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbComboForm.pkg
Use cRDCDbCheckbox.pkg
Use cFunctionsDataDictionary.dd
Use dfEnRad.pkg
Use DFEnChk.pkg

ACTIVATE_VIEW Activate_oFunctionMaintenance_vw FOR oFunctionMaintenance_vw
Object oFunctionMaintenance_vw is a cRefactorDbView
    Set Location to 5 5
    Set Size to 265 483
    Set piMaxSize to 273 602
    Set Label to "Function Maintenance"
    Set Auto_Clear_DEO_State to False

    Procedure Log_Status String sMsg
    End_Procedure
                
    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

//    Object oScrollingContainer is a cDbScrollingContainer
//        
//        Object oScrollingClientArea is a cDbScrollingClientArea

            Object oStandardFunctions_grp is a cRDCDbHeaderGroup
                Set Size to 243 471
                Set Location to 17 6
                Set piMinSize to 134 248
                Set Label to "Functions Maintenance"             
                Set psImage to "FunctionLibrary.ico"
                Set psNote to "Edit functions properties."
                Set psToolTip to "To add a function, the name entered must be EXACTLY the same as the function name itself. Then the code must be added to the cRefactorDbView class (cRefactorDbView.pkg). See class code for standard function parameters."
                Set Border_Style to Border_Normal
                Set peAnchors to anNone

                Object oFunctionsID is a cRDCDbForm
                    Entry_Item Functions.ID
                    Set Size to 12 42
                    Set Location to 44 112
                    Set Label to "ID"
                    Set Label_Justification_mode to jMode_right
                    Set Label_Col_Offset to 2
                    Set Label_row_Offset to 0
                End_Object 
            
                Object oFunctionsFunction_Name is a cRDCDbForm
                    Entry_Item Functions.Function_Name
                    Set Size to 12 321
                    Set Location to 57 112
                    Set Label to "Function Name"
                    Set Label_Justification_mode to jMode_right
                    Set Label_Col_Offset to 2
                    Set Label_Row_Offset to 0
                End_Object 
            
                Object oFunctionsFunction_Description is a cRDCDbForm
                    Entry_Item Functions.Function_Description
                    Set Size to 12 321
                    Set Location to 71 112
                    Set Label to "Function Description"
                    Set Label_Justification_mode to jMode_right
                    Set Label_Col_Offset to 2
                    Set Label_Row_Offset to 0
                End_Object 
            
                Object oFunctionsFunction_Help is a cDbTextEdit
                    Entry_Item Functions.Function_Help
                    Set Size to 35 321
                    Set Location to 85 112
                    Set Label to "Function Help"
                    Set Label_Justification_mode to jMode_right
                    Set Label_Col_Offset to 2
                    Set Label_Row_Offset to 0
                End_Object 
            
                Object oFunctionsFunction_Summary is a cRDCDbForm
                    Entry_Item Functions.Function_Summary
                    Set Size to 12 321
                    Set Location to 124 112
                    Set Label to "Function Summary"
                    Set Label_Justification_mode to jMode_right
                    Set Label_Col_Offset to 2
                    Set Label_Row_Offset to 0
                End_Object 
                                        // Can't use cRDCDbComboForm. It has a bug that makes the value not to change when finding records(!).
                Object oFunctionsType is a DbComboForm 
                    Entry_Item Functions.Type
                    Set Size to 12 133
                    Set Location to 140 112
                    Set Label to "Type"                
                    Set Label_Justification_Mode to JMode_Right
                    Set Label_Col_Offset to 2
                    Set Label_Row_Offset to 0
                    Set Entry_State to False
                    Set Combo_Sort_State to False   
                    Set psToolTip to ("Determines how data is passed to the function." + CS_CRLF + ;
                                      "Standard - Line-by-line" + CS_CRLF + ;
                                      "Remove - Line-by-line" + CS_CRLF + ;
                                      "Editor One - A source file as a string array." + CS_CRLF + ;
                                      "Other One - A source file as a string array." + CS_CRLF + ;
                                      "Other All - All source files as a string array with full path." + CS_CRLF + ;
                                      "Report One - A source file as a string array." + CS_CRLF + ;
                                      "Report All - All source files as a string array with full path.")
                End_Object 

                Object oFunctions_bPrivateFunction is a cRDCDbCheckBox
                    Entry_Item Functions.bPrivateFunction
                    Set Location to 142 267
                    Set Size to 10 60
                    Set Label to "Private Function"
                End_Object

//                Object oFunctions_bWriteProtected is a cRDCDbCheckBox
//                    Entry_Item Functions.bWriteProtected
//                    Set Location to 157 79
//                    Set Size to 10 60
//                    Set Label to "Write Protected (This is a system type function and cannot be changed)"
//                    Set Enabled_State to False
//                End_Object

                Object oFunctions_bHasParameter is a cRDCDbCheckBox
                    Entry_Item Functions.bHasParameter
                    Set Location to 155 112
                    Set Size to 10 60
                    Set Label to "bHasParameter" 
                    Set psToolTip to "If an extra parameter in addition to the source line/file needs to be passed to the function you can enter details about it by selecting this checkbox." 
                    
                    Procedure OnChange
                        Boolean bChecked
                        Get Checked_State to bChecked
                        Set Enabled_State of oFunctions_Parameter           to bChecked
                        Set Enabled_State of oFunctions_ParameterValidation to bChecked
                        Set Enabled_State of oFunctions_ParameterHelp       to bChecked
                    End_Procedure

                End_Object

                Object oFunctions_Parameter is a dbForm
                    Entry_Item Functions.Parameter
                    Set Location to 167 112
                    Set Size to 12 132
                    Set Label to "Optional Parameter"
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set psToolTip to "Optional parameter to be passed to the function, in addition to the source code line/file(s). Enter the default value here, that later can be changed by the user in the DFRefactor program's Function Selection grid."
                End_Object

                Object oFunctions_ParameterValidation is a dbForm
                    Entry_Item Functions.ParameterValidation
                    Set Location to 181 111
                    Set Size to 12 321
                    Set Label to "Validation"
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set psToolTip to "Comma separated list of valid parameter values. When a parameter gets changed by the user in the DFRefactor function selection grid, it will be validated against this list."
                End_Object

                Object oFunctions_ParameterHelp is a cDbTextEdit
                    Entry_Item Functions.ParameterHelp
                    Set Location to 195 112
                    Set Size to 35 321
                    Set Label to "Parameter Help"
                    Set Label_Col_Offset to 2
                    Set Label_Justification_Mode to JMode_Right
                    Set psToolTip to "Instructions for entering optional parameter values in the DFRefactor program's function selection grid. You may add '\n' to separate help text with a new line (CR+LF)."
                End_Object

                Object oCheckAllFunctions_btn is a Button
                    Set Size to 14 101
                    Set Location to 41 332
                    Set Label to "Check all functions"  
                    Set psToolTip to "Makes a call to all functions that has been added to the database. If e.g. a spelling error of the function name has been made, an error message will be shown."
//                    Set peAnchors to anTopRight
                
                    Procedure OnClick
                        Integer iFunctionID iRetval
                        String sFunctionName sLine sPath sSourceFile sParameter
                        Boolean bChanged
                        String[] asSource asSourceFiles
                        
                        // Suspend all timers while we are working:
                        Send SuspendGUI of Desktop True
                        Move False to Err  
                        Move False to bChanged
                        Move "    [Found] Reread // End comment" to sLine
                        Move sLine to asSource[0]                   
                        Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sPath
                        Get vFolderFormat sPath to sPath
                        Move CS_LegacyCode to sSourceFile
                        Move (sPath + String(sSourceFile)) to asSourceFiles[0]
                        Constraint_Set (Self) Clear  
                        Constrained_Clear eq FunctionsA by Index.1
                        Constrained_Find First FunctionsA by Index.1
                        While (Found)
                            Move (Trim(FunctionsA.Parameter)) to sParameter
                            Move (Trim(FunctionsA.Function_Name)) to sFunctionName
                            If (Lowercase(sFunctionName) <> Lowercase(CS_EditorDropSelf)) Begin
                                Move (Eval("get_" - (sFunctionName))) to iFunctionID   
                                If (FunctionsA.Type = eAll_Functions or FunctionsA.Type = eStandard_Function or FunctionsA.Type = eRemove_Function) Begin
                                    Get iFunctionID of ghoRefactorFunctionLibrary (&sLine) sParameter to bChanged
                                End
                                // ToDo: We need a visible pho<Editor object (scintilla) for this to work:
//                                If (FunctionsA.Type = eEditor_Function or FunctionsA.Type = eReport_Function or FunctionsA.Type = eOther_Function) Begin                                    
//                                    Get iFunctionID of ghoRefactorFunctionLibrary (&asSource) sParameter to bChanged
//                                End
                                If (FunctionsA.Type = eOther_FunctionAll or FunctionsA.Type = eReport_FunctionAll) Begin                                    
                                    Get iFunctionID of ghoRefactorFunctionLibrary (&asSourceFiles) sParameter to bChanged
                                End

                                Showln FunctionsA.ID "  " sFunctionName " sLine = " sLine " bChanged = " bChanged
                                If (Err = True) Begin
                                    Get YesNo_Box "An error occured. Do you want to quite?" to iRetval
                                    If (iRetval = MBR_Yes) Begin
                                        Send SuspendGUI of Desktop False
                                        Procedure_Return
                                    End
                                    Else Begin
                                        Move False to Err
                                    End
                                End
                            End
                            Constrained_Find Next  
                        Loop
                        Send Info_Box "Done! All functions were run. Check the Output Window (DataFlex Console Window)"
                        Send SuspendGUI of Desktop False
                    End_Procedure
                
                End_Object
            
            End_Object
            
//        End_Object
//    
//    End_Object        
    
    Procedure Activating            
        Send Clear of oFunctions_DD
        Send Find of oFunctions_DD GT 1   
    End_Procedure
                                                                   
//    Procedure OnSetFocus
//        Set pbVisible of (oFindToolBar(ghoCommandBars)) to True
//        Send ComRecalcLayout of ghoCommandBars
//    End_Procedure
//                                                                   
//    Procedure Exiting_Scope Handle hoNewScope
//        Forward Send Exiting_Scope hoNewScope
//        Set pbVisible of (oFindToolBar(ghoCommandBars)) to False
//        Send ComRecalcLayout of ghoCommandBars
//    End_Procedure

    On_Key Key_Escape Send None
    On_Key Key_Ctrl+Key_S Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object 

Procedure ActivateFunctionsView Integer iFunctionID
    Handle ho hoDD  
    Boolean bDone
    
    Move (oFunctionMaintenance_vw(Self)) to ho
    Get Main_DD of ho to hoDD
    Clear Functions
    Move iFunctionID to Functions.ID
    Find eq Functions by Index.1
    If (Found = True) Begin
        Send Request_Assign of hoDD
        Send Activate_oFunctionMaintenance_vw 
        Send Activate of (oFunctionsID(ho))
    End
End_Procedure
