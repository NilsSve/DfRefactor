// C:\Projects\DF18\DfRefactor\AppSrc\FunctionMaintenance.vw
// Functions Maintenance
//
Use cRefactorDbView.pkg
Use DFEntry.pkg
Use Dfenrad.pkg
Use DFEnChk.pkg
Use cDbTextEdit.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCDbForm.pkg
Use cRDCDbComboForm.pkg
Use cRDCDbCheckbox.pkg
Use cFunctionsDataDictionary.dd

ACTIVATE_VIEW Activate_oFunctionMaintenance_vw FOR oFunctionMaintenance_vw
Object oFunctionMaintenance_vw is a cRefactorDbView
    Set Location to 5 5
    Set Size to 308 483
    Set piMaxSize to 336 602
    Set Label to "Edit Functions"
    Set Auto_Clear_DEO_State to False
    Set pbAutoActivate to True
    Set Icon to "FunctionEdit.ico"
    Set Verify_Save_msg to (RefFunc(No_Confirmation))

    Procedure Log_Status String sMsg
    End_Procedure
                
    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD To oFunctions_DD
    Set Server  To oFunctions_DD

    Object oStandardFunctions_grp is a cRDCDbHeaderGroup
        Set Size to 289 471
        Set Location to 17 6
        Set piMinSize to 134 248
        Set Label to "Edit Functions"             
        Set psImage to "FunctionEdit.ico"
        Set psNote to "Edit refactoring functions properties."
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
    
        Object oFunctionsFunction_Help is a cDbTextEdit
            Entry_Item Functions.Function_Help
            Set Size to 47 321
            Set Location to 73 112
            Set Label to "Function Help"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_Row_Offset to 0

            // The cDbTextEdit contains a peculiarity in the sense that it 
            // doesn't right trim the buffer value. This results in a really
            // annyoing runtime error when you try to add text to an existing
            // record. The error is triggered becvause the maximal length then
            // gets exceeded. This "ccures" it.
            Procedure Refresh Integer iNotifyMode
                Handle hoServer
                String sVal
                Get Server to hoServer
                Forward Send Refresh iNotifyMode
                If (iNotifyMode = Mode_Find_or_Clear_Set or iNotifyMode = Mode_Save) Begin
                    Get Field_Current_Value of hoServer Field Functions.Function_Help to sVal
                    Move (Rtrim(sVal)) to sVal
                    Set Value to sVal
                    Set Changed_State of hoServer to False
                End
            End_Procedure
            
        End_Object 
    
        Object oFunctionsFunction_Summary is a cRDCDbForm
            Entry_Item Functions.SummaryText
            Set Size to 12 321
            Set Location to 124 112
            Set Label to "Summary Text"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_Row_Offset to 0
        End_Object 
        
        // Can't use cRDCDbComboForm. It has a bug that makes the value not to change
        // when finding records(!).
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

        Object oFunctions_bPrivate is a cRDCDbCheckBox
            Entry_Item Functions.bPrivate
            Set Location to 142 267
            Set Size to 10 60
            Set Label to "Private Function"
        End_Object

        Object oFunctions_bHasParameter is a cRDCDbCheckBox
            Entry_Item Functions.bHasParameter
            Set Location to 177 112
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
            Set Location to 189 112
            Set Size to 12 132
            Set Label to "Default Optional Parameter"
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to JMode_Right
            Set psToolTip to "Optional parameter to be passed to the function, in addition to the source code line/file(s). Enter the default value here, that later can be changed by the user in the DFRefactor program's Function Selection grid."
        End_Object

        Object oFunctions_ParameterValidation is a dbForm
            Entry_Item Functions.ParameterValidation
            Set Location to 203 111
            Set Size to 12 321
            Set Label to "Simple Validation"
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to JMode_Right
            Set psToolTip to "Comma separated list of valid parameter values. When a parameter gets changed by the user in the DFRefactor function selection grid, it will be validated against this list."
        End_Object

        Object oFunctions_ParameterHelp is a cDbTextEdit
            Entry_Item Functions.ParameterHelp
            Set Location to 217 111
            Set Size to 62 321
            Set Label to "Parameter Help"
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to JMode_Right
            Set psToolTip to "Instructions for entering optional parameter values in the DFRefactor program's function selection grid. You may add '\n' to separate help text with a new line (CR+LF)."

            // The cDbTextEdit contains a peculiarity in the sense that it 
            // doesn't right trim the buffer value. This results in a really
            // annyoing runtime error when you try to add text to an existing
            // record. The error is triggered becvause the maximal length then
            // gets exceeded. This "ccures" it.
            Procedure Refresh Integer iNotifyMode
                Handle hoServer
                String sVal
                Get Server to hoServer
                Forward Send Refresh iNotifyMode
                If (iNotifyMode = Mode_Find_or_Clear_Set or iNotifyMode = Mode_Save) Begin
                    Get Field_Current_Value of hoServer Field Functions.ParameterHelp to sVal
                    Move (Rtrim(sVal)) to sVal
                    Set Value to sVal 
                    Set Changed_State of hoServer to False
                End
            End_Procedure
            
        End_Object

        Object oCheckAllFunctions_btn is a Button
            Set Size to 14 77
            Set Location to 41 354
            Set Label to "Check all functions"  
            Set psToolTip to "Makes a call to all functions that has been added to the database. If e.g. a spelling error of the function name has been made, an error message will be shown."
        
            Procedure OnClick
                Integer iFunctionID iRetval
                String sFunctionName sLine sPath sSourceFile sParameter
                Boolean bChanged
                String[] asSource asSourceFiles
                
                Get YesNo_Box "Makes a call to all functions that has been added to the database. If e.g. a spelling error of the function name has been made, an error message will be shown. Each successful function call should return a zero (0). Continue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return
                End

                // Suspend all timers while we are working:
                Send SuspendGUI of Desktop True
                Move False to Err  
                Move False to bChanged

                Showln
                // Sets the output window's font (but setting the size seems weird)
                CONSOLE_TYPEFACE "Consolas"
                //CONSOLE_FONTSIZE 6 0

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
                            Get iFunctionID of ghoRefactorFuncLib (&sLine) sParameter to bChanged
                        End
                        // ToDo: We need a visible pho<Editor object (scintilla) for this to work, so skip for now:
//                        If (FunctionsA.Type = eEditor_Function or FunctionsA.Type = eReport_Function or FunctionsA.Type = eOther_Function) Begin
//                            Get iFunctionID of ghoRefactorFuncLib (&asSource) sParameter to bChanged
//                        End
                        If (FunctionsA.Type = eOther_FunctionAll or FunctionsA.Type = eReport_FunctionAll) Begin                                    
                            Get iFunctionID of ghoRefactorFuncLib (&asSourceFiles) sParameter to bChanged
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
            
    Procedure OnEnterArea Handle hoFrom
        Boolean bChecked
        Forward Send OnEnterArea hoFrom
        Get Checked_State of oFunctions_bHasParameter to bChecked
        Set Enabled_State of oFunctions_Parameter           to bChecked
        Set Enabled_State of oFunctions_ParameterValidation to bChecked
        Set Enabled_State of oFunctions_ParameterHelp       to bChecked
    End_Procedure

    Procedure Activating            
        Send Clear of oFunctions_DD
        Send Find of oFunctions_DD GT 1   
    End_Procedure

                                                                   
    On_Key Key_Escape Send None
    On_Key Key_Ctrl+Key_S  Send Request_Save
    On_Key Key_Ctrl+Key_F2 Send Request_Save
    On_Key Key_Ctrl+Key_F4 Send None
End_Object 

// Public access method for this view. Pass it a Functions.ID,
// that the view should latch on to.
Procedure ActivateFunctionsView Integer iFunctionID
    Handle ho hoDD  
    
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
