﻿Use Windows.pkg
Use cRefactorApplication.pkg
Use cRefactorDbView.pkg
Use cRefactorScintillaEditor.pkg
Use oEditorProperties.pkg
Use vWin32fh.pkg
Use cFunctionsDataDictionary.dd
Use dfClient.pkg

Activate_View Activate_oEditorView_vw For oEditorView_vw
Object oEditorView_vw is a cRefactorDbView
    Set Size to 263 492
    Set Maximize_Icon to True
    Set Label to "Refactoring Editor"
    Set Icon to "Editor.ico"
//    Set pbAutoActivate to True
    Set pbAcceptDropFiles to True

    Set phoEditorView of ghoApplication to Self

    Object oEditorInfo_tb is a TextBox
        Set Size to 10 351
        Set Location to 4 20
        Set Label to "When Single File mode is used, and for functions of type: 'Editor - One File'. Those functions must have an active editor object to work."
        Set FontWeight to fw_Bold
    End_Object

    // Just so the cursor has a focusable object to go to.
    Object oDbInvisible_fm is a Form
        Set Size to 13 25
        Set Location to 3 388
        Set Visible_State to False
    End_Object

    Object oEditor_edt is a cRefactorScintillaEditor
        Set Size to 244 473
        Set Location to 16 10
        Set peAnchors to anAll
        Set Enabled_State to False

        // View property.
        Delegate Set phoEditor to Self
        Set phoEditor of ghoApplication to Self
         
        Property Boolean piInSetFocus False

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
                // Make the editor not visible, because else it is possible to click inside it
                // even when no workspace has been selected.
                // The oDbInvisible_fm object above takes care of the focusable necessity.
                Set Visible_State to (sSWSFile <> "")
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

    Procedure OnSetFocus
        Set piActiveView of ghoApplication to CI_CodeIndenter Self
    End_Procedure

    Object oView_IdleHandler is a cIdleHandler
        Set pbEnabled to True
        Procedure OnIdle
            String sSWSFile  
            Boolean bEnabled
            Get psSWSFile of ghoApplication to sSWSFile
            Move (sSWSFile <> "") to bEnabled
            Set Enabled_State to bEnabled
            Broadcast Recursive Set Enabled_State of (Parent(Self)) to bEnabled
        End_Procedure
    End_Object

    Procedure Activate_View Returns Integer
        String sSourceFilename   

        Forward Send Activate_View

        Get psCurrentSourceFileName of ghoApplication to sSourceFilename
        If (sSourceFilename <> "") Begin
            Send OnFileNameUpdate of ghoApplication sSourceFilename
            Send Top_of_Panel
        End
    End_Procedure

    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        // Define the save procedure for the editor object.
        Send DefineOnKey of (phoEditor(ghoApplication)) CMD_FileSaveAll msg_Request_Save
    End_Procedure
    
    // We con't care about potential data loss here, it is more annoying to be reminded of it...
    Function pbShouldSave Returns Boolean
        Function_Return False
    End_Function
        
End_Object
