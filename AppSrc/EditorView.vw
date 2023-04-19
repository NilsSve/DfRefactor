Use Windows.pkg
Use cRefactorDbView.pkg
Use cScintillaRefactorEditor.pkg
Use oEditorProperties.pkg
Use mfiletime.pkg
Use vWin32fh.pkg
Use cFunctionsDataDictionary.dd

Activate_View Activate_oEditorView_vw For oEditorView_vw
Object oEditorView_vw is a cRefactorDbView
    Set Size to 263 492
    Set Border_Style to Border_Thick
    Set Maximize_Icon to True
    Set Label to "Refactoring Editor"
    Set pbAutoActivate to True
    Set pbAcceptDropFiles to True
    Set Icon to "Editor.ico"
    Set Label to "Editor used by 'Editor Function' types"
    Set phoEditorView of ghoApplication to Self

    Object oEditor_edt is a cScintillaRefactorEditor
        Set Size to 246 473
        Set Location to 13 10
        Set peAnchors to anAll
        Set Enabled_State to False

        Delegate Set phoEditor to (Self)
        Set phoEditor of ghoApplication to (Self) 
        Property Boolean piInSetFocus False

        Function RefactorSourceFileInEditor  String[] ByRef asSourceFile Returns Boolean
            Integer iFunctionsSelected iFunctionID
            Boolean bFound bChanged bOK
            String sFunctionName sParameter 
            String[] asSourceFileNew 
                                                                  
            Move False to Err
            Move 0 to LastErr
            Move False to bChanged
            
            Send UpdateStatusBar "Updating source code in editor..." False
            Get WriteDataToEditor asSourceFile to bOK
            Send Activate
            
            Constraint_Set Self Clear  
            Constrained_Clear eq FunctionsA by Index.4
            Constrain FunctionsA.Selected eq True
            Constrain FunctionsA.Type eq eEditor_Function
            Constrained_Find First FunctionsA by Index.4
            
            While (Found = True)
                Move (Trim(FunctionsA.Parameter)) to sParameter
                Move (Lowercase(Trim(FunctionsA.Function_Name))) to sFunctionName 
                Move (Eval("get_" - (sFunctionName))) to iFunctionID             
                If (sFunctionName = CS_EditorDropSelf) Begin
                    Send Stop_StatusPanel of ghoStatusPanel
                End
                Get iFunctionID of ghoRefactorFunctionLibrary asSourceFile sParameter to bChanged
                If (sFunctionName = CS_EditorDropSelf) Begin
                    Send Start_StatusPanel of ghoStatusPanel
                End
                If (bChanged = True) Begin                        
                    Reread FunctionsA
                        Add 1 to FunctionsA.Count  
                        SaveRecord FunctionsA
                    Unlock
                End
                Constrained_Find Next
            Loop

            Get EditorDataAsStringArray to asSourceFileNew
            Move (not(IsSameArray(asSourceFileNew, asSourceFile))) to bChanged
            If (bChanged = True) Begin
                Move asSourceFileNew to asSourceFile
            End
            
            // To not get an "Editor change" data loss message when exiting program.
            Set Changed_State to False
            Function_Return bChanged
        End_Function

        // We con't care about potential data loss here.
        Function pbShouldSave Returns Boolean
            Function_Return False
        End_Function

        // Note: We need this "intermediate" procedure because the phoMainPanel property
        //       is zero when the program starts - which generates a runtime error.
        Procedure SwitchNextView
            Send Switch_Next_View of (Client_Id(phoMainPanel(ghoApplication)))
        End_Procedure

        Object oIdleHandler is a cIdleHandler 
            Procedure OnIdle
                String sSWSFile
                Get psSWSFile of ghoApplication to sSWSFile
                Set Enabled_State to (sSWSFile <> "")
            End_Procedure
        End_Object

        Procedure Activating
            Forward Send Activating
            Set pbEnabled of oIdleHandler to True
        End_Procedure
    
        Procedure Deactivating
            Set pbEnabled of oIdleHandler to False
            Forward Send DeActivating 
        End_Procedure

        // This short-cut key will keep the UI consistent, as the editor was "grabbing" this
        // key combination and did nothing, but everywhere else it flips through the views/tab-pages.
        On_Key Key_Ctrl+Key_Tab Send SwitchNextView
        On_Key Key_Ctrl+Key_S   Send Request_Save
    End_Object

    // Allow a .sws file, source file or folder to be dropped on the view:
    Procedure OnFileDropped String sFilename Boolean bLast
        String sFileExt sSWSFile
        Boolean bFile bFolder bSWSFile
        Handle hoEditor

        Get phoEditor of ghoApplication to hoEditor
        Forward Send OnFileDropped sFilename bLast

        // Try to find out if a file or a folder name
        // was dropped on the view:
        If (bLast = True) Begin
            Get ParseFileExtension sFilename to sFileExt
            Move (Lowercase(sFileExt)) to sFileExt
            Move (sFileExt = "")    to bFolder
            Move (sFileExt = "sws") to bSWSFile
            Move (bSWSFile = False and bFolder = False) to bFile
            If (bFile = True) Begin
                Get psSWSFile of ghoApplication to sSWSFile
                If (sSWSFile = "") Begin
                    Send Info_Box "You need to select a workspace first."
                    Procedure_Return
                End
                Send UpdateSourceFileNameDisplay of ghoApplication sFileName
                Send LoadFile of hoEditor sFilename
                Send Activate_oEditorView_vw
                Set pbWorkspaceMode of ghoApplication to False
            End
            Else Begin
                Send UpdateWorkspaceSelectorDisplay of ghoApplication sFilename
                Set pbWorkspaceMode of ghoApplication to True
            End
        End
        Else Begin
            Send Info_Box "Only one file can be dropped on the view. The last file will be used."
        End
    End_Procedure

    Procedure OnSetFocus
        Set piActiveView of ghoApplication to CI_CodeIndenter Self
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle
            String sSWSFile
            Get psSWSFile of ghoApplication to sSWSFile
            Set Enabled_State to (sSWSFile <> "")
        End_Procedure
    End_Object

    Object oEditorInfo_tb is a TextBox
        Set Size to 10 132
        Set Location to 2 20
        Set Label to "Editor object used by Scintilla Editor's build in refactoring functions"
    End_Object

    Procedure Activate_View Returns Integer
        String sSourceFilename   

        Forward Send Activate_View

        Get psCurrentSourceFileName of ghoApplication to sSourceFilename
        If (sSourceFilename <> "") Begin
            Send UpdateSourceFileNameDisplay of ghoApplication sSourceFilename
            Send Top_of_Panel
        End

    End_Procedure

    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        // Define the save procedure for the editor object.
        Send DefineOnKey of (phoEditor(ghoApplication)) CMD_FileSaveAll msg_Request_Save
    End_Procedure
    
    // We con't care about potential data loss here.
    Function pbShouldSave Returns Boolean
        Function_Return False
    End_Function
        
End_Object
