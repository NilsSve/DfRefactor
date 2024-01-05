Use DFClient.pkg
Use cUnitCommandBar.pkg
Use DFUnit\Reporting\ReporterManager.pkg
Use DFUnit\Reporting\Reporters\UIListReporter.pkg
Use cRDCButtonDPI.pkg
Use cRefactorScintillaEditor.pkg
Use cRefactorFuncLib.pkg

Activate_View Activate_DFUnitTestRunner_vw for DFUnitTestRunner_vw
Object DFUnitTestRunner_vw is a View
    Set Size to 323 253
    Set Location to 0 -1
    Set Maximize_Icon to True
    Set Minimize_Icon to False
    Set Sysmenu_Icon to False
    Set Border_Style to Border_None
    Set piMinSize to 250 235 
    Set pbAutoActivate to True
    Set phoRefactorView of ghoApplication to Self   

    Object oRefactorFunctionLibrary is a cRefactorFuncLib
    End_Object

    Object oRunTestsButton is a cRDCButtonDPI
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

    Object oFirstRow_btn is a cRDCButtonDPI
        Set Size to 14 66
        Set Location to 9 105
        Set Label to "View Top" 
        Set piImageSize to 16
        Set psImage to "ViewFirst.ico"

        Procedure OnClick
            Send Beginning_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oLatestRow_btn is a cRDCButtonDPI
        Set Size to 14 66
        Set Location to 24 105
        Set Label to "View Bottom"
        Set piImageSize to 16
        Set psImage to "ViewLast.ico"

        Procedure OnClick
            Send End_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oClose_btn is a cRDCButtonDPI
        Set Size to 30 61
        Set Location to 9 177
        Set Label to "Exit"
        Set psImage to "ActionExit.ico"
        Set piImageSize to 36
        Set peAnchors to anTopRight
        Set piImageMarginLeft to 20
    
        Procedure OnClick
            Send Exit_Application    
        End_Procedure
    
    End_Object

    Object oOutputBox is a cDFUnitUIListReporter
        Set Size to 229 236
        Set Location to 46 13
        Set peAnchors to anAll
        Set Border_Style to Border_Thick
        Delegate Set phoOutputBox to Self 
        
        Procedure Copy
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
                Forward Send Copy
            End
        End_Procedure
        
        On_Key Key_Ctrl+Key_C Send Copy
    End_Object

    Object oEditor_tb is a TextBox
        Set Size to 10 34
        Set Location to 278 13
        Set Label to "Scintilla Test Editor:"
        Set peAnchors to anBottomLeft
    End_Object

    Object oTestCode_edt is a cRefactorScintillaEditor
        Set Size to 30 227
        Set Location to 290 12
        Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_LegacyCode)
        Set peAnchors to anBottomLeftRight
        Set phoEditor of ghoRefactorFuncLib to Self
    End_Object

    Procedure ScaleFont Integer iDirection 
    End_Procedure 

    Procedure End_Construct_Object   
        Forward Send End_Construct_Object
    End_Procedure

    On_Key Key_Ctrl+Key_F4 Send None
    On_Key Key_Escape      Send None
End_Object
