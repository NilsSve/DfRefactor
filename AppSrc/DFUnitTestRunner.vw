Use DFClient.pkg
Use oGridCopyMenu.pkg
Use cUnitCommandBar.pkg
Use DFUnit\Reporting\ReporterManager.pkg
Use DFUnit\Reporting\Reporters\UIListReporter.pkg

// Comment out the next Define statement line to *not* use the
// Scintilla Editor window.
//Define CS_UseScintillaEditor for "cRefactorScintillaEditor"

#IFDEF CS_UseScintillaEditor
    Use cRefactorScintillaEditor.pkg
#ELSE
    Register_Procedure LoadFile String sFileName 
    Register_Function IsFileTimeNewer String sFileName Returns Boolean 
    Register_Function WriteDataToEditor String[] asCode Returns Boolean 
    Register_Function EditorDataAsStringArray Returns String[]
    Register_Function EditorFormatToUtf8 String sLine Returns String
    Register_Function pbHasUtf8BOM Returns Boolean
    Register_Function pbUtf8Mode Returns Boolean 
    Register_Function Utf8ToEditorFormat String sLine Returns Boolean 
    Register_Procedure Set pbHasUtf8BOM Boolean bState 
    Register_Procedure Set pbUtf8Mode Boolean bState 
    Register_Procedure Set pbOemMode Boolean bState 
    Register_Procedure ShowTextEncoding Integer iEncoding
    Register_Procedure ChangeTextEncoding 
    Register_Procedure RefactorNormalizeCase 
    Register_Procedure RefactorReIndent
    Register_Procedure GotoLine Integer iLine
    Register_Procedure RefactorReIndent
    Register_Procedure SetAdjustments Boolean bState
    Register_Procedure ApplyEditorOptions 
    Register_Procedure OnPropsChange 
#ENDIF

Activate_View Activate_DFUnitTestRunner_vw for DFUnitTestRunner_vw
Object DFUnitTestRunner_vw is a View
    Set Size to 381 332
    Set Location to 10 10
    Set Maximize_Icon to True
    Set Border_Style to Border_Thick 
    Set View_Mode to Viewmode_Normal 
    Set pbAutoActivate to True

    Object oRunTestsButton is a Button
        Set Size to 30 87
        Set Location to 9 12
        Set Label to "Run again"
        Set peAnchors to anNone
        Set psImage to "RunProgram.ico"
        Set piImageSize to 42
        // Set FontPointHeight to 18  
        // We use this instead so we can align in the Studio.
        Set Form_FontWeight to FW_BOLD 
        Set piImageMarginLeft to 15
        Set MultiLineState to True
    
        Procedure OnClick
            Send ManualRunTests of ghoTestApplication
        End_Procedure
    
    End_Object

    Object oFirstRow_btn is a Button
        Set Size to 14 66
        Set Location to 9 105
        Set Label to "View Top" 
        Set piImageSize to 16
        Set psImage to "ViewFirst.ico"

        Procedure OnClick
            Send Beginning_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oLatestRow_btn is a Button
        Set Size to 14 66
        Set Location to 24 105
        Set Label to "View Bottom"
        Set piImageSize to 16
        Set psImage to "ViewLast.ico"

        Procedure OnClick
            Send End_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oNextError_btn is a Button
        Set Size to 14 66
        Set Location to 24 175
        Set Label to "Next Error"
        Set piImageSize to 16
        Set psImage to "ActionFind.ico"
        Set psToolTip to "Find next '[Failed!]' line (Ctrl+N)"

        Procedure OnClick
            Send FindNextError of oOutputBox
        End_Procedure

    End_Object

    Object oClose_btn is a Button
        Set Size to 30 61
        Set Location to 9 256
        Set Label to "Exit"
        Set psImage to "ActionExit.ico"
        Set piImageSize to 36
        Set peAnchors to anTopRight
        Set piImageMarginLeft to 20
    
        Procedure OnClick
            Send Exit_Application    
        End_Procedure
    
    End_Object
    Set phoRefactorView of ghoApplication to Self   

    Object oOutputBox is a cDFUnitUIListReporter
        Set Size to 272 315
        Set Location to 46 13
        Set peAnchors to anAll
        Set Border_Style to Border_Thick
        Delegate Set phoOutputBox to Self 
        
        Set Floating_Menu_Object to  (oGridCopyMenu(Self))  

        Procedure CopyErrorLineNo
            String sLine
            Integer iLine iPos iChar
            Get LineFromChar -1 to iLine
            Get Line iLine to sLine
            Move (Pos("on line:", sLine)) to iPos
            If (iPos <> 0) Begin
                Move (Trim(Mid(sLine, Length(sLine), (iPos + Length("on line:"))))) to sLine
                Move sLine to iLine 
                Direct_Output channel 9 "Clipboard:"
                Write channel 9 iLine
                Close_Output channel 9
                Set StatusText of (StatusBar_Id(ghoCommandBars)) to ("The number:" * String(iLine) * "was copied to Windows Clipboard. Press Ctrl+G in the studio, to jump to that source line.")
            End 
            Else Begin
                Send Copy of (Focus(Self))
            End
        End_Procedure
        
        Procedure Add_Focus Handle hoParent Returns Integer
            Forward Send Add_Focus hoParent
            Set phInvokingObject of (oGridCopyMenu(Self)) to Self
        End_Procedure
        
        Procedure FindNextError
            Integer iSelStart iSelEnd
            String sSearchText
            
            Move CS_FailedClause to sSearchText
            Get FindText sSearchText 0 to iSelStart
            If (iSelStart = -1) Begin
                Send Beginning_of_Data
                Get FindText sSearchText 0 to iSelStart
            End
            If (iSelStart <> -1) Begin
                Move (Length(sSearchText) + iSelStart) to iSelEnd
                Send SetSel iSelStart iSelEnd
            End
        End_Procedure

        On_Key Key_Ctrl+Key_C Send Copy
        On_Key Key_Ctrl+Key_N Send FindNextError
    End_Object

    Object oEditor_tb is a TextBox
        Set Size to 10 34
        Set Location to 323 13
        Set Label to "Unit Test Output Scintilla Editor:"
        Set peAnchors to anBottomLeft
    End_Object

#IFDEF CS_UseScintillaEditor
    Object oTestCode_edt is a cRefactorScintillaEditor
        Set Size to 45 306
        Set Location to 333 12
        Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_LegacyCode)
        Set peAnchors to anBottomLeftRight     
        Set pbExternalModifyCheck to False
        Set phoEditor of ghoRefactorFuncLib to Self 
        Procedure FindNextError
            Send FindNextError of oOutputBox
        End_Procedure
        On_Key Key_Ctrl+Key_N Send FindNextError
    End_Object
#ENDIF

    Procedure ScaleFont Integer iDirection 
    End_Procedure 

    Procedure End_Construct_Object
        Forward Send End_Construct_Object
    End_Procedure

    On_Key Key_Ctrl+Key_F4 Send None
    On_Key Key_Escape      Send None
End_Object
