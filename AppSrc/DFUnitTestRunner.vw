Use DFClient.pkg
Use cSplitterContainer.pkg
Use oGridCopyMenu.pkg
Use cUnitCommandBar.pkg
Use DFUnit\Reporting\ReporterManager.pkg
Use DFUnit\Reporting\Reporters\UIListReporter.pkg

// Comment out the next Define statement line to *not* use the
// Scintilla Editor window.
Define CS_UseScintillaEditor for "cRefactorScintillaEditor"

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
    Set Size to 346 332
    Set Location to 10 10
    Set Maximize_Icon to True
    Set Border_Style to Border_Thick 
    Set View_Mode to Viewmode_Normal 
    Set pbAutoActivate to True
    Set phoRefactorView of ghoApplication to Self   

    /* cSplitterContainer FILLS ITS PARENT: its Page procedure sets GuiLocation 0 0
       and GuiSize to the parent's WHOLE client area, discarding any design-time
       Location/Size. Placed directly on the view it therefore covered the buttons
       wherever they were moved, and every focus-change repaint wiped them -
       "all the buttons suddenly can disappear" the earlier
       "buttons were overwritten" at the top was the same effect). The class is
       built to be the SOLE occupant of a parent - so give it one: this host
       carries the real geometry, and the splitter fills the host, not the view. */
    Object oSplitterHost is a Container3d
        Set Location to 41 13
        Set Size to 300 315
        Set peAnchors to anAll
        Set Border_Style to Border_None

        Object oSplitContainer is a cSplitterContainer
            Set pbSplitVertical to False
            Set peFixedPanel to fpFixLastPanel
            Set piSplitterLocation to 200 // 226

            Object oOutputPane is a cSplitterContainerChild
    
                Object oOutputBox is a cDFUnitUIListReporter
                    Set Size to 264 313
                    Set Location to 0 0
                    Set peAnchors to anAll
                    Set Border_Style to Border_Thick
                    Delegate Set phoOutputBox to Self
                    // Each line is written as soon as it is finished, so the output fills while the tests run.
                    Set pbShowLinesAsTheyCome to True
            
                    Set Floating_Menu_Object to  (oGridCopyMenu(Self))
            
                    Procedure CopyErrorLineNo
                        String sLine
                        Integer iLine iPos iChar
                        Boolean bOk

                        Get LineFromChar -1 to iLine
                        Get Line iLine to sLine
                        Move (Pos("on line:", sLine)) to iPos
                        If (iPos <> 0) Begin
                            Move (Trim(Mid(sLine, Length(sLine), (iPos + Length("on line:"))))) to sLine
                            Move sLine to iLine 
                            Get rfSetClipboardText (String(iLine)) to bOk
                            If (bOk = False) ;
                                Procedure_Return
                            Set StatusText of (Statusbar_Id(ghoCommandBars)) to ("The number:" * String(iLine) * "was copied to Windows Clipboard. Press Ctrl+G in the studio, to jump to that source line.")
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
    
            End_Object

            Object oEditorPane is a cSplitterContainerChild
    
                Object oEditor_tb is a TextBox
                    Set Size to 10 34
                    Set Location to 1 2
                    Set Label to "Unit Test Output Scintilla Editor:"
                    Set peAnchors to anTopLeft
                End_Object
    
#IFDEF CS_UseScintillaEditor
                Object oTestCode_edt is a cRefactorScintillaEditor
                    Set Size to 70 310 //45 310
                    Set Location to 12 00
                    Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_LegacyCode)
                    Set peAnchors to anAll
                    Set pbExternalModifyCheck to False
                    // ghoFuncLib does not exist yet when this deferred view constructs, so
                    // carry the editor handle on ghoApplication; Startup binds it onto
                    // ghoFuncLib once the single funclib instance exists.
                    Set phoUnitTestEditor of ghoApplication to Self
                    Procedure FindNextError
                        Send FindNextError of oOutputBox
                    End_Procedure
                    On_Key Key_Ctrl+Key_N Send FindNextError
                End_Object
#ENDIF
    
            End_Object

        End_Object

    End_Object
//    Set phoRefactorView of ghoApplication to Self   

    Object oRunTestsButton is a Button
        Set Size to 30 87
        Set Location to 5 12
        Set Label to "Run again"
        Set peAnchors to anTopLeft
        Set psImage to "RunProgram.ico"
        Set piImageSize to 42
        // Set FontPointHeight to 18  
        // We use this instead so we can align in the Studio.
        Set Form_FontWeight to FW_BOLD 
        Set piImageMarginLeft to 15
        Set MultiLineState to True
    
        Procedure OnClick
            Send RunTests
        End_Procedure
    
    End_Object

    Object oFirstRow_btn is a Button
        Set Size to 14 66
        Set Location to 5 105
        Set Label to "View Top" 
        Set piImageSize to 16
        Set psImage to "ActionUp.ico"
        Set peAnchors to anTopLeft

        Procedure OnClick
            Send Beginning_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oLatestRow_btn is a Button
        Set Size to 14 66
        Set Location to 21 105
        Set Label to "View Bottom"
        Set piImageSize to 16
        Set psImage to "ActionDown.ico"
        Set peAnchors to anTopLeft

        Procedure OnClick
            Send End_of_Data to oOutputBox
        End_Procedure

    End_Object

    Object oNextError_btn is a Button
        Set Size to 14 66
        Set Location to 21 175
        Set Label to "Next Error"
        Set piImageSize to 16
        Set psImage to "ActionRigth.ico"
        Set psToolTip to "Find next '[Failed!]' line (Ctrl+N)"
        Set peAnchors to anTopLeft

        Procedure OnClick
            Send FindNextError of oOutputBox
        End_Procedure

    End_Object

    Object oClose_btn is a Button
        Set Size to 30 61
        Set Location to 5 256
        Set Label to "Exit"
        Set psImage to "ActionExit1.ico"
        Set piImageSize to 36
        Set peAnchors to anTopRight
        Set piImageMarginLeft to 20
    
        Procedure OnClick
            Send Exit_Application    
        End_Procedure
    
    End_Object

    /* Output box above, Scintilla editor below, with a DRAGGABLE splitter between
       them (Nils 2026-07-27: "it would help to have a splitter between the top unit
       tests output and the Scintilla editor"). Horizontal split; the editor pane
       keeps its height when the view resizes (fpFixLastPanel), which preserves the
       old anBottomLeftRight feel while letting the user pull the editor as tall as
       the inspection at hand needs. */

    // One run of the tests. The output box fills while they run and lets the window answer the mouse after each
    // line, so "Run again" is greyed meanwhile, and a second run is not started inside the first.
    Property Boolean pbRunning False

    Procedure RunTests
        If (pbRunning(Self)) Begin
            Procedure_Return
        End
        Set pbRunning to True
        Set Enabled_State of oRunTestsButton to False
        Send ManualRunTests of ghoTestApplication
        Set Enabled_State of oRunTestsButton to True
        Set pbRunning to False
    End_Procedure

    Procedure ScaleFont Integer iDirection 
    End_Procedure 

    Procedure End_Construct_Object
        Forward Send End_Construct_Object
    End_Procedure

    On_Key Key_F3          Send FindNextError of oOutputBox
    On_Key Key_Ctrl+Key_F4 Send None
    On_Key Key_Escape      Send None
End_Object
