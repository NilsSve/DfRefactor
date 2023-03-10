Use Windows.pkg
Use DFClient.pkg              
Use cSplitterContainer.pkg
Use cTextEdit.pkg 
Use File_dlg.pkg
Use seq_chnl.pkg

Use cRefactorDbView.pkg
Use cRDCButton.pkg
Use cFileNameForm.pkg
Use cScintillaRefactorEditor.pkg
Use oEditorProperties.pkg
Use mfiletime.pkg
Use vwin32fh.pkg

//Use LogFileDialog.dg
Open SysFile
  
// NOTE: The image code below will overwrite the content of the
//       CS_LegacyCode source file for _each_ start of the program.
//


/LegacyCode   
Move (Trim (Customer.Zip) * Trim (Customer.City)) to vData[iRow][2] // Name: ZipCode_City, Length: 100, Datatype: String
Repeat
Until [Seqeof]  

  // From OldFMACCommands.pkg
#IFDEF SELECT
#ELSE
    #Replace SELECT |!C
#ENDIF      
Function _ Global String s Returns String
End_Function

Function wsDoTranslate Integer iTextNo String sMenu Returns String
    Function_Return (_(sMenu))
End_Function

Function kalle returns string
    Function_Return (wsDoTranslate(Self,3713,"January"))
end_function

    Procedure Logg
    End_Procedure
    Procedure Test
        String sErrMess sText sTemp sFileName
        Integer iYesNo  
        
        Append sErrMess ("-" + wsDoTranslate(Self,2941,"You can't book this item.") + "\n")
        Append sText (wsDoTranslate(Self,678,"Credit limit exceeded")) "  " (wsDoTranslate(Self,678,"Continue to order?"))
        Get YesNo_Box (wsDoTranslate(Self,3798,"File exists") + " " + (sTemp + sFileName) + "\n" + wsDoTranslate(Self,3798,"Would you like to replace it") + "?") to iYesNo

        Send Logg (wsDoTranslate(Self,2686,"Customer no missing!"))
        Send Combo_Add_Item  (wsDoTranslate(Self,3319,"0 - Select")) "0"
        Set Value to (wsDoTranslate(Self,538,"1 - Reservdelar")) "1"
    End_Procedure
    
    [FindErr] Set color of ghoApplication to clWhite
    [FindErr] Set color of ghoApplication to clWhite

    [not Seqeof] Repeat
    [not Seqeof] Loop
    While [SeqEof]
    Loop
    
    [Found] Reread // End comment
    Indicate Select as Windowindex Eq Fieldindex // Comment
    [Select] Indicate Select as Windowindex Eq Fieldindex // Comment

integer iPosX iCommasX
string sRowX
    If ((mid(sRowX,1,iPosX)) eq ",") Add 1 to iCommasX
        
        If 1 eq 2 Begin
            If 1 gt 2 Begin
                If 1 ne 2 Begin
                    [Found] Begin
                        If 1 lt 2 Begin
                        End // If Begin
                    End // [Found] Begin

                End // If bTrasig Begin
            End // If  Begin
        End // [Found] Begin

Person_etikett_false:

    // If you set Current_radio you must set this after the
    // radio objects have been created AND after Notify_select_State has been
    // created. i.e. Set in bottom-code at end!!
    //Set Current_Radio to 0

Register_Object oButton

    Procedure One
        Date From_date  
        String sVal
        Address aAddress
        Boolean bState
        String[] asArray
        Integer[] aiArray
         
        [not Seqeof] Begin
        End
        
        Move "Yes" to asArray[0]
        Move "No"  to asArray[1]
        Move 1     to aiArray[0]
        Move aiArray[0] to sVal 
        GetAddress of sVal to aAddress

        Set Shadow_State of (oApplication(Self)) to False // Comment here
        Get Shadow_State to bState // Other comment
        Set Shadow_State of oButton to (Not(bState))
        
        Move True to bState
        Set Shadow_State of ghoapplication to bState // Third comment
        Set Object_Shadow_state to True

        If sVal NE ""  Begin
            Move True to bState
        End   
    
        //*****
        If (Uppercase("a")) EQ (Uppercase("b")) Begin
        End
        If (From_date EQ "" or not(IsDateValid(From_date)) or From_date LT 1/1/1900) Begin
        End
    End_Procedure
    
    [not Seqeof] Repeat
    [not Seqeof] Loop
    While [Seqeof]
    Loop
    [Found] Reread // End comment
    [FindErr] Set color of ghoApplication to clWhite
    [FindErr] Set color of ghoApplication to clWhite
    Repeat
    Until [Seqeof]  
    
    Repeat
    Until [not Found]
    
Declare_Datafile Flexerrs

    Procedure OnConstrain
        Constrain FlexErrs.Recnum gt 10
    End_Procedure
        
    Find Eq Flexerrs by Recnum
    
Procedure Test2
    Date dToday
    Sysdate4 dToday

    Indicate Found as True
    Indicate Found as (windowindex < fieldindex)

    Set piRowToInsert of AvgiftGrid to -1

    Send Stop_box (wsDoTranslate(Self,3837,"Please press the button 'Change Customer Number"))
End_Procedure    

    Object AvgiftGrid is a Grid
        Property Integer piRowToInsert -1
        Property Integer piCallbackObject 0
        Property String psCustomerIDToInsert ""
        Property Boolean pbOpenInEditModeRepeat False
        Property Boolean pbOpenPos False
    End_Object

    // Comment about the procedure
    //    Procedure Deactivating
    //        Forward Send Deactivating
    //        Send Beginning_of_Data 
    //    End_Procedure

Use Windows.pkg
Use DfConfrm.pkg

Function StringFromRightOfChar String sIn String sOut Returns String
End_Function

Object Renames is an Array
End_Object

Register_Object oMain

    //OnChange is called on every changed character
    Procedure OnChange
    End_Procedure
    
    // fires when the button is clicked
    Procedure OnClick
    End_Procedure

Procedure Test3
    String sOutConnStr
    Integer iStart iRetVal

    If (iStart = 1) Begin
        Procedure_Return
    End

    Get Confirm (wsDoTranslate(Self,1986,"Start")) to iRetVal
    Set Value of (oMain(Current_Object))  (Item_Count(Current_Object)) to (Left(sOutConnStr, iStart - 1))
    Set Status_Help to "Enter fields to be renamed in format FILE.OLDFIELD,NEWFIELD, e.g. CUSTOMER.CUST,CUSTNO"
    Set Value to (wsDoTranslate(Self,2686,"Customer number is missing!"))
End_Procedure
    
Function ParseFolderName Global String sFileName Returns String
    String sFile sResult sFolderName sDirSep
    Integer iLength

    ZeroString iLength to sResult

    Move "" to sFolderName
    Move (sysconf(SYSCONF_DIR_SEPARATOR)) To sDirSep
    If sDirSep In sFileName Begin
        Move (StringFromRightOfChar(sFileName,sDirSep)) To sFile
        Move (Replace(sFile,sFileName,"")) to sFolderName
    End
    Else If ":" In sFileName Begin
        Move (StringFromRightOfChar(sFileName,":")) To sFile
        Move (Replace(sFile,sFileName,"")) to sFolderName
    End
    Function_Return sFolderName
End_Function // ParseFolderName

   Procedure Add_Row string sRow
      local integer bRename
      local Integer iPos
      local integer iCommas
      Move dfTrue to bRename
      if ((left(sRow,1)) ne "#") move dfFalse to bRename
      If (bRename) Begin
         for iPos from 1 to (length(sRow))
            If ((mid(sRow,1,iPos)) eq ",") Add 1 to iCommas
         loop//iPos
         If (iCommas ne 2) Move dfFalse to bRename
      end
      If (bRename) Set Value of (Renames(Self)) Item (Item_Count(Renames(Self))) to (replace("#",sRow,""))
      else Set Value item (Item_Count(self)) to sRow
   End_Procedure//Add_Row

            Object oWorkspace is a cObject
            End_Object
            Object oKey is a cObject
            End_Object
            Object oDFPath is a cObject
            End_Object

            Function PathRow Returns String
                local String  retval
                If ((Current_Radio(Self)) eq 0) Move (Append("W",(Value(oWorkspace(Self),0)))) to retval
                If ((Current_Radio(Self)) eq 1) Move (Append("K",(Value(oKey(Self),0)))) to retval
                If ((Current_Radio(Self)) eq 2) Move (Append("P",(Value(oDFPath(Self),0)))) to retval
                Function_Return retval
            End_Function//PathRow

    Move False to Found
    [Found] Repeat
        Move Windowindex to Fieldindex
    [Found] Loop

    Function ScalaUtpris String Utpris Returns String
        Number L D P  
        String sName

        Trim Utpris to Utpris
        Length Utpris to L
        Pos "," In Utpris to P
        If p ne 0 Begin
            Move (L-P) to D
            If d eq  1 Begin
                Append Utpris "0"
            End
            If d gt  2 Begin
                Move (Left(Utpris, (P+2))) to Utpris
            End
        End
        If p eq  0 Begin
            Append Utpris ".00"
        End
    
        Length UTPRIS to L
        While L lt 13
            Insert " " In UTPRIS At 1
            Length UTPRIS to L
        End
        
        Move (Replace("A", sName, "B")) to sName
        Replace  "A"  In  sName  With "B"
        
        Function_Return Utpris
    End_Function

/*

Activate_View Activate_oRefactorTesting for oRefactorTesting
Object oRefactorTesting is a cRefactorDbView
    Set Border_Style to Border_Thick
    Set Size to 278 756
    Set Location to 2 7
    Set Label to "Testing of Refactor Functions"
    Set pbAutoActivate to True
    Set Maximize_Icon to True 
    Set pbAcceptDropFiles to True

    Set phoTestView of ghoApplication to Self
    Property Handle phoEditorLegacy
    Property Handle phoEditorRefactored   
    
    Object oSplitterContainer is a cSplitterContainer
        Set piSplitterLocation to 498

        Object oSplitterContainerChild1 is a cSplitterContainerChild

            Object oOpenDialog is a OpenDialog
                Set Dialog_Caption to "Select your file compare application of choice"
                Set Filter_String to "Programs|*.exe|Any file|*.*"
            End_Object

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 74
                Set Location to 5 8
                Set Label to "Legacy Code: (Before)"
                Set FontWeight to fw_Bold
            End_Object
        
            Object oLegacyCode_edt is a cScintillaRefactorEditor
                Set Size to 176 481
                Set Location to 17 6         
                // we have two because of test with two similar refactortesting views.
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
                        Get ReadImageDataToStringArray 1 to asLegacyCode 
                        Move (oLegacyCodeFilename_fm(Self)) to ho
                        Get psCodeFile of (phoEditorLegacy(ghoApplication)) to sFileName
                        Send SaveData of ho asLegacyCode
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

            Object oSaveFiles_grp is a Group
                Set Size to 63 401
                Set Location to 198 5
                Set Label to "Refactoring Code Sample Files:"
                Set peAnchors to anBottomLeftRight

                Object oLegacyCodeFilename_fm is a cFileNameForm
                    Set Size to 14 264
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
                    Set Size to 14 264
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

//                Object oOpenLocation_btn is a Button
//                    Set Size to 14 98
//                    Set Location to 19 275
//                    Set Label to "&Open Containing Folder"
//                    Set peAnchors to anBottomRight
//                    Set psImage to "ActionOpen.ico"
//                    Set psToolTip to "Open source location in Windows Explorer (Ctrl+O)"
//                
//                    Procedure OnClick 
//                        Send OpenContainingContainer of ghoApplication
//                    End_Procedure
//                
//                End_Object
                
            End_Object

            Object oInfo_tb is a TextBox
                Set Size to 10 251
                Set Location to 5 126
                Set Label to "(You can drag && drop a source file from Windows Explorer to this editor object)"
            End_Object

        End_Object

        Object oSplitterContainerChild2 is a cSplitterContainerChild

            Object oLegacyEditor_tb is a TextBox
                Set Size to 10 84
                Set Location to 5 5
                Set Label to "Refactored Code: (After)"
                Set FontWeight to fw_Bold
            End_Object
    
            Object oRefactoredCode_edt is a cScintillaRefactorEditor
                Set Size to 176 476
                Set Location to 17 6
                Delegate Set phoEditorRefactored to (Self)
                Set phoEditorRefactored of ghoApplication to (Self)
                Set psCodeFile to (psAppSrcPath(phoWorkspace(ghoApplication)) + "\" + CS_RefactoredCode)
        
                Procedure OnModified
                    Integer iLines
                    
                    Forward Send OnModified
                    Get Line_Count to iLines
                    Set Value of oRefactoredCode_NoOfLines_fm to iLines                    
                End_Procedure          
                
                Procedure JumpToSourceLine Integer iLine
                    Handle hoEdit
                    Get phoCodeMaxEditor to hoEdit
                    Send GotoLine of hoEdit iLine    
                End_Procedure
            
                On_Key Key_Ctrl+Key_E Send Execute of (oErrorLog_ToolItem(ghoCommandBars))
            End_Object

            Object oRefactoredCode_NoOfLines_fm is a Form
                Set Size to 10 33
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
                Set Location to 208 48
                Set Enabled_State to False
                Set Label to "Elapsed:"
                Set Label_Col_Offset to 2
                Set Label_Justification_Mode to JMode_Right
                Set peAnchors to anBottomLeft
                Set Form_Datatype to Mask_Clock_Window
            End_Object

            Object oRefactor_btn is a Button
                Set Size to 26 94
                Set Location to 197 151
                Set Label to "&Refactor Legacy Code"
                Set peAnchors to anBottomRight
                Set Default_State to True
                Set FontWeight to fw_Bold
                Set psImage to "Start.ico"
                Set psToolTip to "Refactors the legacy code from the left editor, then saves it to disk. (Ctrl+R)"
                Set piImageSize to 24
                
                Procedure OnClick      
                    Delegate Send RefactoreCode
                End_Procedure
            
            End_Object
    
            Object oCompareProgram_btn is a cRDCButton
                Set Size to 14 100
                Set Location to 230 151
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
                    Get CM_GetLineCount of (phoEditorRefactored(ghoApplication)) to iLines
                    Function_Return (iLines > 1)
                End_Function
        
            End_Object

            Object oCompareprogram_fm is a Form
                Set Size to 12 140
                Set Location to 231 7
                Set Label_Col_Offset to 0
                Set Label_Row_Offset to 1
                Set Label_Justification_Mode to JMode_Top
                Set Label to "Select Compare Program:"
                Set psToolTip to "Select a file comparison tool, such as 'Beyond Compare', 'WinMerge', 'Araxis Merge' etc.. (Press F4)"
                Set peAnchors to anBottomLeftRight                                                                              
                Set Prompt_Button_Mode to pb_PromptOn
        
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
                
                Procedure Activating                      
                    String sFileName
                    Get psFileCompareApp of ghoApplication to sFileName
                    Set Value to sFileName
                End_Procedure
        
            End_Object

            Object oTestCompileRefactoredCode_btn is a cRDCButton
                Set Size to 14 100
                Set Location to 247 151
                Set Label to "Compile Refactored Code"
                Set peAnchors to anBottomRight
                Set psImage to "CompileProject.ico"
                Set psToolTip to "Compiles 'CompiledRefactoredCode.src' a test program where the refactored code file is Use'd. (F5)"
            
                Procedure OnClick
                    Send CompileRefactoredCode of ghoApplication
                End_Procedure
        
                Function IsEnabled Returns Boolean
                    Integer iLines
                    Get CM_GetLineCount of (phoEditorRefactored(ghoApplication)) to iLines
                    Function_Return (iLines > 1)
                End_Function
        
            End_Object

        End_Object

    End_Object

//    Procedure UpdateStatusBar String sText Boolean bIdleTextOnly Integer iLi Integer iChrs
//        Handle hoStatusBar
//        Integer iLines iCharacters
//
//        Move (StatusBar_Id(Self)) to hoStatusBar   
//        If (num_arguments > 2) Begin
//            Move iChrs to iCharacters
//            If (iCharacters = 0) Begin
//                Move 0 to iLines
//            End                 
//            Else Begin
//                Move iLi to iLines
//            End
//            Set NumberOfEditorLines      of hoStatusBar to iLines
//            Set NumberOfEditorCharacters of hoStatusBar to iCharacters
//        End
//        Else Begin
//            If (bIdleTextOnly = True) Begin
//                Set psIdleText of hoStatusBar to sText
//                Set ActionText of hoStatusBar to ""
//            End
//            Else Begin
//                Set ActionText of hoStatusBar to sText
//            End
//        End
//    End_Procedure
//
    Procedure Activating
        Set Value of (oLegacyCodeFilename_fm(Self))     to (psCodeFile(phoEditorLegacy(ghoApplication)))
        Set Value of (oRefactoredCodeFilename_fm(Self)) to (psCodeFile(phoEditorRefactored(ghoApplication)))
    End_Procedure

    // *** MAIN REFACTORING ROUTINE ***
    // Testing of various refactor functions:
    Procedure RefactoreCode
        String[] asLegacyCode asRefactoredCode
        String sLine sLegacyFileName
        Handle hoEditor ho
        Integer iSize iCount iTabSize iRetval
        Boolean bChanged bLoopFound bisCOMProcxy bWriteLine
        DateTime dtStart dtEnd
        
        Move (CurrentDateTime()) to dtStart
        Set Value of (oRefactoredCode_Time_fm(Self)) to ""
        Move False to bLoopFound
        Set piTabSize  of ghoRefactorFunctionLibrary to SysFile.TabSize
        Set peSplitBy  of ghoRefactorFunctionLibrary to SysFile.eSplitBy
        Set peDDOStyle of ghoRefactorFunctionLibrary to SysFile.eDDOStyle
        
        Get phoEditorLegacy  to hoEditor
        Get psCodeFile of hoEditor to sLegacyFileName
        Get IsDataFlexCOMProxyClassesFile of ghoRefactorFunctionLibrary sLegacyFileName to bisCOMProcxy
        If (bisCOMProcxy = True) Begin
            Send Info_Box "This file is marked as a Studio COM Proxy classes auto generated file and will _not_ be refactored!"
            Procedure_Return
        End

        Send UpdateStatusBar of hoEditor "" True                
        Get EditorDataAsStringArray of hoEditor to asLegacyCode
        Move (SizeOfArray(asLegacyCode)) to iSize

        Get phoEditorRefactored to hoEditor
        If (iSize > 0) Begin
            Send Delete_Data of hoEditor
        End        
        Else Begin
            Send Info_Box "No input code found."
            Procedure_Return
        End
        Decrement iSize  
        Set pbIsRefactoring of ghoApplication to True 
            
        For iCount from 0 to iSize
            // Need this to show "Number of lines:" changes
            Send PumpMsgQueue of Desktop   
            
            // Read next source line
            Move asLegacyCode[iCount] to sLine
           
            Move True to bWriteLine
            Get RemoveStudioGeneratedComments               of ghoRefactorFunctionLibrary (&sLine) to bChanged 
            If (bChanged = True) Begin
                Move False to bWriteLine
            End
            Get RemoveOldStudioMarkers                      of ghoRefactorFunctionLibrary (&sLine) to bChanged
            If (bChanged = True) Begin
                Move False to bWriteLine
            End
            Get RemoveSansSerif                             of ghoRefactorFunctionLibrary (&sLine) to bChanged
            If (bChanged = True) Begin
                Move False to bWriteLine
            End                       
            
            If (bWriteLine = True) Begin
                // Asolvi specific function:
                Get ChangewsDoTranslateTo_                  of ghoRefactorFunctionLibrary (&sLine) to bChanged // Done!
                Get ChangeLegacyShadow_State                of ghoRefactorFunctionLibrary (&sLine) to bChanged

                Get ChangeFoundAndFindErrIndicators         of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeIndicateFoundToMoveTrueToFound    of ghoRefactorFunctionLibrary (&sLine) to bChanged     
                Get ChangeIndicatorToMoveStateToVariable    of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeIndicatorToIfBegin                of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeLegacyOperators                   of ghoRefactorFunctionLibrary (&sLine) to bChanged

                Get SplitInlineIfElseLine                   of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeUntilAndWhileIndicators           of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeIndicatorRepeatToWhile            of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeFoundLoopIndicator                of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeSysdate4                          of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeDfTrueDfFalse                     of ghoRefactorFunctionLibrary (&sLine) to bChanged
    
                Get ChangeInToContains                      of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeReplaceCommandToFunction          of ghoRefactorFunctionLibrary (&sLine) to bChanged  
                Get ChangeGetAddress                        of ghoRefactorFunctionLibrary (&sLine) to bChanged 
                            
                Get ChangeTrimCommandToFunction             of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangeLengthCommandToFunction           of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get ChangePosCommandToFunction              of ghoRefactorFunctionLibrary (&sLine) to bChanged  
                Get ChangeInsertCommandToFunction           of ghoRefactorFunctionLibrary (&sLine) to bChanged  

                Get ChangeZeroStringCommandToFunction       of ghoRefactorFunctionLibrary (&sLine) to bChanged  
                Get ChangeCurrent_ObjectToSelf              of ghoRefactorFunctionLibrary (&sLine) to bChanged
                
                Get ChangeUClassToRefClass                  of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get RemoveTrailingSpaces                    of ghoRefactorFunctionLibrary (&sLine) to bChanged    
                Get RemoveLocalKeyWord                      of ghoRefactorFunctionLibrary (&sLine) to bChanged  
                Get ReplaceCalcWithMoveStatement            of ghoRefactorFunctionLibrary (&sLine) to bChanged   
                Get RemovePropertyPublic                    of ghoRefactorFunctionLibrary (&sLine) to bChanged
                Get RemoveEndComments                       of ghoRefactorFunctionLibrary (&sLine) to bChanged 
                
                Get RemovePropertyPrivate                   of ghoRefactorFunctionLibrary (&sLine) to bChanged   
                Get RemovePropertyPublic                    of ghoRefactorFunctionLibrary (&sLine) to bChanged   
                
                If (iCount < iSize) Begin
                    Move (sLine + CS_CRLF) to sLine
                End            
                Send AppendText of hoEditor sLine
            End
        Loop  

        Send PumpMsgQueue of Desktop  
        Send Cursor_Wait of (Cursor_Control(Self)) 
        
        // Remove multiple empty lines
        Send UpdateStatusBar of hoEditor "Removing empty lines..." True
//        Get EditorDataAsStringArray of hoEditor to asRefactoredCode
//        
//        // Reindent code
//        Send UpdateStatusBar "Reindenting..." True
//        Send RefactorReIndent of hoEditor
//        Send PumpMsgQueue of Desktop  
//        
//        // Fix Upper/Lowercase
//        Send UpdateStatusBar "Normalizing casing..." True
//        Send RefactorNormalizeCase  of hoEditor
//        Send PumpMsgQueue of Desktop  
        
        Send SaveFile of hoEditor        
        Send Cursor_Ready of (Cursor_Control(Self))        
        Move (CurrentDateTime()) to dtEnd
        Set Value of (oRefactoredCode_Time_fm(Self)) to (dtEnd - dtStart)
        Set pbIsRefactoring of ghoApplication to False
    End_Procedure

End_Object

Procedure JumpToSourceLine Integer iLine
    Handle ho
    Get phoEditorRefactored of ghoApplication to ho
    Send JumpToSourceLine of ho iLine
End_Procedure 
