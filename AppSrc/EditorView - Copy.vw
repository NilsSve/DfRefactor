Use Windows.pkg
Use cRefactorDbView.pkg
Use cScintillaEdit.pkg
Use oEditorProperties.pkg
Use mfiletime.pkg
Use vWin32fh.pkg
Use cRemoveUnusedLocals.pkg
Use cUnusedSourceFiles.pkg
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

    Set phoEditorView of ghoApplication to Self

    Property Handle phoRemoveUnusedLocals 0
    Property Handle phoReportUnusedSource 0
    Property Handle phoBPO 0
    Property String  psLineBreak ""
    Property Boolean pbLastLineBreak False

    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object                  
    
    Set Main_DD to oFunctions_DD
    Set Server  to oFunctions_DD

    Object oRemoveUnusedLocals is a cRemoveUnusedLocals
        Set phoRemoveUnusedLocals to Self
    End_Object

    Object oReportUnusedSourceFiles is a cUnusedSourceFiles
        Set phoReportUnusedSource to Self
    End_Object

    Object oEditor_edt is a cScintillaEdit
        Set Size to 248 473
        Set Location to 8 10
        Set peAnchors to anAll
        Set Enabled_State to False
        Set phoEditor of ghoApplication to (Self)

        Property Boolean piInSetFocus False
        Property DateTime pdtCurrentFileDateTime

        Function RefactorSourceFileInEditor Returns Boolean
            tRefactorActions RefactorActions

            Move False to Err
            Move 0 to LastErr
            Get pRefactorActions to RefactorActions

            If (RefactorActions.bRefactorReIndent = True) Begin
                Send UpdateStatusBar "Reindenting source code..." False
                Set Action_Text of ghoStatusPanel  to "Reindenting source code..."
                Send RefactorReIndent
            End
            If (RefactorActions.bRefactorNormalizeCase = True) Begin
                Send UpdateStatusBar "Making proper casing..." False
                Set Action_Text of ghoStatusPanel  to "Making proper casing..."
                Send RefactorNormalizeCase
            End
            If (RefactorActions.bRefactorDropSelf = True) Begin
                Send RefactorDropSelf
            End

            Function_Return (Err = False)
        End_Function

        Procedure LoadEditorFile String sFileName
            Integer eStatus

            Send Delete_Data
            Get CM_OpenFile sFileName to eStatus
            Send FillFileTimeStamp sFileName // Update the filetime.
        End_Procedure

        Procedure SaveFile
            Boolean bOK

            Send DispatchAnyKey
            Get WriteToDisk to bOK
            If (bOK = False) Begin
                Send Info_Box "An error occured and the file wasn't saved properly. Please see the 'Backup' folder for the original file."
            End
            Else Begin
                Send UpdateStatusBar "Changes saved!" True
            End
        End_Procedure

        Function IsEditorRefactorActions Returns Boolean
            tRefactorActions RefactorActions
            Boolean bChecked

            Move False to bChecked
            Get pRefactorActions to RefactorActions
            Case Begin
                Case (RefactorActions.bRefactorDropSelf = True)
                    Move True to bChecked
                    Case Break
                Case (RefactorActions.bRefactorNormalizeCase = True)
                    Move True to bChecked
                    Case Break
                Case (RefactorActions.bRefactorReIndent = True)
                    Move True to bChecked
                    Case Break
            Case End

            Function_Return bChecked
        End_Function

        Function CharacterCount Returns Integer
            Integer iLineCount iStartPos iEndPos
            Integer iTotalCharacters

            Move 0 to iTotalCharacters
            Get EditorMessage SCI_GETLINECOUNT 0 0 to iLineCount
            If (iLineCount > 0) Begin
                Get EditorMessage SCI_POSITIONFROMLINE 0 0 to iStartPos
                Get EditorMessage SCI_GETLINEENDPOSITION (iLineCount - 1) 0 to iEndPos
                Get EditorMessage SCI_COUNTCHARACTERS iStartPos iEndPos to iTotalCharacters
            End

            Function_Return iTotalCharacters
        End_Function

        Procedure ApplyEditorOptions
            Forward Send ApplyEditorOptions
        End_Procedure

        Procedure FillFileTimeStamp String sFileName
            DateTime dtCurrentFileDateTime
            Get FileModTime sFileName  to dtCurrentFileDateTime
            Set pdtCurrentFileDateTime to dtCurrentFileDateTime
        End_Procedure

        // Returns the DateTime of the passed file name was modified, with seconds (only) precision.
        Function FileModTime String sFileName Returns DateTime
            Date dDate
            Integer iYY iHH iMM iSS
            Boolean bExists
            DateTime dtFileDateTime

            Move (NullDateTime()) to dtFileDateTime
            Get vFilePathExists sFileName to bExists
            If (bExists = True) Begin
                Get_File_Mod_Time sFileName to dDate iHH iMM iSS
                Move dDate            to dtFileDateTime
                Move (DateGetYear       (dtFileDateTime))      to iYY
                Move (DateSetYear       (dtFileDateTime, iYY)) to dtFileDateTime
                Move (DateSetHour       (dtFileDateTime, iHH)) to dtFileDateTime
                Move (DateSetMinute     (dtFileDateTime, iMM)) to dtFileDateTime
                Move (DateSetSecond     (dtFileDateTime, iSS)) to dtFileDateTime
                Move (DateSetMillisecond(dtFileDateTime, 0))   to dtFileDateTime
            End

            Function_Return dtFileDateTime
        End_Function

        Function IsFileTimeNewer String sFileName Returns Boolean
            Boolean bExists bIsNewer
            DateTime dtCurrentFileDateTime dtCompareFileDateTime

            Move False to bIsNewer
            Get vFilePathExists sFileName to bExists
            If (bExists = True) Begin
                Get pdtCurrentFileDateTime to dtCurrentFileDateTime
                Get FileModTime sFileName  to dtCompareFileDateTime
                Move (dtCompareFileDateTime > dtCurrentFileDateTime) to bIsNewer
            End
            Function_Return bIsNewer
        End_Function

        // Note: We need this "intermediate" procedure because the phoMainPanel property
        //       is zero when the program starts - which generates a runtime error.
        Procedure SwitchNextView
            Send Switch_Next_View of (Client_Id(phoMainPanel(ghoApplication)))
        End_Procedure

        { MethodType=Property }
        Procedure Set piTabSize Integer iTabSize
            Send EditorMessage SCI_SETTABWIDTH iTabSize
            Set piTabSize of ghoEditorProperties to iTabSize
            Send SaveIni  of ghoEditorProperties
        End_Procedure

        { MethodType=Property }
        Function piTabSize Returns Integer
            Integer iTabSize
            Send EditorMessage SCI_GETTABWIDTH iTabSize
            Function_Return iTabSize
        End_Function

        // Nils moved the line_count code to OnSetFocus because it made the editor way to slow.
//        Procedure OnModified
//            Forward Send OnModified
//        End_Procedure

        // Used for checking if the file in editor has changed externally and
        // if so reload it.
        Procedure OnSetFocus
            Integer iRet iCurrentLine
            String  sMsg  sFileName
            Handle  hoMain
            Boolean bUserModified bHasChangedExternal bDoReloadFile
            Handle hoEditor
            Integer iLines iSize

            Send OnSelChange
            Send OnOvertypeChange
            Move False to bDoReloadFile

            Get phoEditor of ghoApplication to hoEditor
            Get Line_Count of hoEditor to iLines
            Get CharacterCount of hoEditor to iSize
            Send UpdateStatusBar "" False iLines iSize

            Get Main_Panel_Id to hoMain
            If (not(piInSetFocus(Self))) Begin // recursive protection
                Set piInSetFocus to True
                Get psCurrentSourceFileName of ghoApplication to sFileName
                Get IsFileTimeNewer sFileName to bHasChangedExternal
                Get CM_IsModified to bUserModified
                If (bHasChangedExternal and bUserModified) Begin
                    If (bUserModified) Begin
                        Append sMsg "The file has been changed by another program.\n\n"
                    End
                    Append sMsg "Do you want to reload it?\n"
                    If (bUserModified) Begin
                        Append sMsg "Pressing YES will discard any changes made.\n"
                    End

                    Get YesNo_Box sMsg (Label(hoMain)) to iRet
                    If (iRet = MBR_Yes) Begin
                        Move True to bDoReloadFile
                    End
                    Else Begin
                        Send FillFileTimeStamp sFileName // Update the file modified datetime.
                    End
                End

                // If file has changed externally, but we didn't edit, then do not ask, just refresh
                If (bHasChangedExternal and bUserModified = False) Begin
                    Move True to bDoReloadFile
                End
                If (bDoReloadFile = True) Begin
                    Get CurrentLine to iCurrentLine
                    Get CM_OpenFile sFileName to iRet
                    Send EditorMessage SCI_SETSAVEPOINT
                    If (iCurrentLine <> 0) Begin
                        Send EditorMessage SCI_GOTOLINE iCurrentLine
                    End
                    Send FillFileTimeStamp sFileName // Update the file modified datetime.
                End
                Set piInSetFocus to False
            End
        End_Procedure

        // This short-cut key will keep the UI consistent, as the editor was "grabbing" this
        // key combination and did nothing, but everywhere else it flippes through the views/tab-pages.
        On_Key Key_Ctrl+Key_Tab Send SwitchNextView
        On_Key Key_Ctrl+Key_S   Send Request_Save
    End_Object

    Object oBPO is a BusinessProcess
        Delegate Set phoBPO to Self

        Property Boolean pbOk
        Property String[] pasFolderNames
        Property String psFileFilter

        Procedure OnProcess
            String  sFolderName sFileName
            Boolean bOk bExists bIsFileInFilter bStop bIsCOM bIsCountNoOfLines
            Boolean bIsRefactorFunctions bBackUpState
            String[] asFolderNames
            String sFileFilter
            Integer iCount iSize iItems iNoOfLines iTotNoOfLines
            Handle hoReportUnusedSource
            tRefactorActions RefactorActions
            tsSearchResult[] asSearchResult

            Move (SysFile.StandardFunctionsSelected + SysFile.EditorFunctionsSelected + SysFile.NullFunctionsSelected) to iItems
            // If any other than report functions was selected.
            Move (iItems <> 0) to bIsRefactorFunctions

            Move False to bOk
            Send SetProgressBarText
            Get pRefactorActions to RefactorActions
            Get pasFolderNames to asFolderNames
            Get psFileFilter   to sFileFilter
            Get AllSourceFiles of ghoApplication asFolderNames sFileFilter to asSearchResult
            Move (SizeOfArray(asSearchResult)) to iSize
            Decrement iSize

            // If at least one refactoring function was selected (and not only report functions)
            If (bIsRefactorFunctions = True) Begin
                Move (RefactorActions.bCountNumberOfLines = True) to bIsCountNoOfLines

                For iCount from 0 to iSize
                    Move asSearchResult[iCount].sAlternateFileName to sFolderName
                    Move asSearchResult[iCount].sFilename          to sFileName

                    Set Title_Text of ghoStatusPanel to ("Folder:" * String(sFolderName))
                    Set Message_Text of ghoStatusPanel to ("File:" * String(sFileName))
                    Send Update_status ("File No:" * String(iCount + 1) * "of:" * String(iSize + 1))

                    Get IsFileInFilter of ghoApplication sFileName sFileFilter to bIsFileInFilter
                    If (bIsFileInFilter = True) Begin

                        // Fix for Bug #158 "Refactoring COM wrapper files can be really time consuming"
                        Get vFolderFormat sFolderName to sFolderName                   
                        Get IsDataFlexCOMProxyClassesFile (sFolderName + sFileName) to bIsCOM

                        // *** Process File line by line ***
                        If (bIsCOM = False and bIsCountNoOfLines = False) Begin
                            Get ProcessFile (sFolderName + sFileName) False to bOK
                        End

                        If (bIsCountNoOfLines = True) Begin
                            Get CountNumberOfLines (sFolderName + sFileName) to iNoOfLines
                            Add iNoOfLines to iTotNoOfLines
                        End
                    End
                    Get Cancel_Check to bStop
                    If (bStop = True) Begin
                        Procedure_Return
                    End
                Loop

                If (bIsCountNoOfLines = True) Begin   
                    Get pRefactorActions to RefactorActions
                    Move (iSize + 1)   to RefactorActions.Counters.iCountNumberOfFiles
                    Move iTotNoOfLines to RefactorActions.Counters.iCountNumberOfLines 
                    Set pRefactorActions to RefactorActions
                    Move True to bOk
                End
            End

            Get IsBackupFolder of ghoApplication to bExists
            If (bExists = False) Begin
                Get BackupFolder of ghoApplication "" to sFolderName
            End
            // bUnusedSource needs to be treated a bit differently because we need to "feed" the logic
            // with all workspace folders we've found. (Can't use the file by file approach)
            If (RefactorActions.bUnusedSourceFiles = True) Begin
                If (SizeOfArray(asFolderNames) <> 0) Begin
                    Get phoReportUnusedSource   to hoReportUnusedSource
                    Get psFileFilter            to sFileFilter
                    Set psFileFilter            of hoReportUnusedSource to sFileFilter
                    Set pasAllFolders           of hoReportUnusedSource to asFolderNames
                    Set Action_Text             of ghoStatusPanel to ""
                    Send DoProcess              to hoReportUnusedSource
                    Get piNoOfUnusedSourceFiles of hoReportUnusedSource to RefactorActions.Counters.iUnusedSourceFiles
                    Get pbOK                    of hoReportUnusedSource to bOk
                End
            End          
            
            Set pbOk to bOk
        End_Procedure

        Procedure Update_Status String sProgress
            String  sPath
            Boolean bWorkspaceMode

            Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
            If (bWorkspaceMode = True) Begin
                Get psHomePath of ghoApplication to sPath
                If (sPath <> "") Begin
                    // Strip out the path, so we can see the filename without it being cut off.
                    Move (Replace(sPath, sProgress, "..")) to sProgress
                End
            End
            Forward Send Update_Status sProgress
        End_Procedure

        Procedure SetProgressBarText
            String  sMessage
            Move "Processing file:" to sMessage
            Set Process_Caption to (Label(phoMainPanel(ghoApplication)))
            Set Process_Message to sMessage
            Set Process_Title to "Refactoring Source Code"
        End_Procedure

        Set Display_Error_State to True
        Set Allow_Cancel_State to True
    End_Object

    // Returns True if at least one of the refactor action has been selected, _except_ for report functions
    Function IsActionsExceptReports Returns Boolean
        Integer iCheckboxFunctions

        Move (SysFile.StandardFunctionsSelected + SysFile.EditorFunctionsSelected + SysFile.NullFunctionsSelected) to iCheckboxFunctions
        Function_Return (iCheckboxFunctions > 0)
    End_Function

    Function WriteToDisk Returns Boolean
        String sFileName
        Integer eResult
        Boolean bOK
        Handle hoEditor

        Get phoEditor of ghoApplication to hoEditor
        Get psCurrentSourceFileName of ghoApplication to sFileName
        Get SaveBackupFile of ghoApplication sFileName to bOK

        If (bOK = False) Begin
            Send Info_Box "Sorry, the backup failed due to a problem. Process was interupted."
            Function_Return False
        End

        Get CM_SaveFile of hoEditor sFileName False to eResult
        Send FillFileTimeStamp of hoEditor sFileName

        Function_Return (eResult = CME_SUCCESS)
    End_Function

    Procedure LoadFile String sFileName
        If (sFileName = "") Begin
            Procedure_Return
        End
        Send LoadEditorFile of (phoEditor(ghoApplication)) sFileName
    End_Procedure

    Procedure RemoveReportLogFiles String sPath
        Boolean bOK
        tRefactorActions RefactorActions

        Get pRefactorActions to RefactorActions
        Get vFolderFormat sPath to sPath
        If (RefactorActions.bUnusedSourceFiles = True) Begin
            Get vDeleteFile (sPath + CS_BackupFolder + CS_DirSeparator + CS_UnusedSourceLogFile) to bOK
        End
    End_Procedure

    // Checks the counters to see if the file was changed   
    // ToDo: REDO with new counters!
    Function FileCountersChanged Returns Boolean
        Boolean bChanged         
        tRefactorActions RefactorActions

        Get pRefactorActions to RefactorActions
        Move False to bChanged
        Case Begin
            Case (RefactorActions.Counters.iChangeCurrent_ObjectToSelf <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeDfTrueDfFalse <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeFoundLoopIndicator <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeFoundAndFindErrIndicators <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeGetAddress <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeIndicateFoundToMoveTrueToFound <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeIndicatorRepeatToWhile <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeIndicatorToIfBegin <> 0)
                Move True to bChanged
                Case Break          
            Case (RefactorActions.Counters.iChangeIndicatorToMoveStateToVariable <> 0)
                Move True to bChanged
                Case Break                          
            Case (RefactorActions.Counters.iChangeInsertCommandToFunction <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeInToContains <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeLegacyOperators <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeLengthCommandToFunction <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangePosCommandToFunction <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeReplaceCommandToFunction <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeSysdate4 <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeZeroStringCommandToFunction <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeUntilAndWhileIndicators <> 0)
                Move True to bChanged
            Case (RefactorActions.Counters.iChangeUClassToRefClass <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iReplaceCalcWithMoveStatement <> 0)
                Move True to bChanged
                Case Break

            Case (RefactorActions.Counters.iReplaceCalcWithMoveStatement <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveBlankLines <> 0)
                Move True to bChanged
                Case Break                                  
            Case (RefactorActions.Counters.iRemoveLocalKeyWord <> 0)
                Move True to bChanged
                Case Break    
            Case (RefactorActions.Counters.iRemovePropertyPrivate <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemovePropertyPublic <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveEndComments <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveOldStudioMarkers <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveSansSerif <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveStudioGeneratedComments <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRemoveTrailingSpaces <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iSplitInlineIfElseLine <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRefactorDropSelf <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRefactorNormalizeCase <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iRefactorReIndent <> 0)
                Move True to bChanged
                Case Break

            Case (RefactorActions.Counters.iRemoveUnusedLocals <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iCountNumberOfLines <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iCountNumberOfFiles <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iUnusedSourceFiles <> 0)
                Move True to bChanged
                Case Break                                      
            // Asolvi Functions:                
            Case (RefactorActions.Counters.iChangewsDoTranslateTo_ <> 0)
                Move True to bChanged
                Case Break
            Case (RefactorActions.Counters.iChangeLegacyShadow_State <> 0)
                Move True to bChanged
                Case Break                
        Case End

        Function_Return bChanged
    End_Function

    Procedure IncrementChangedFiles
        Integer iCount
        Get piChangedFileCount of ghoApplication to iCount
        Increment iCount
        Set piChangedFileCount of ghoApplication to iCount
    End_Procedure

    Procedure IncrementFileCount
        Integer iCount

        Get piFileCount of ghoApplication to iCount
        Increment iCount
        Set piFileCount of ghoApplication to iCount
    End_Procedure

    //
    // *** MAIN PROCESS ***
    //
    Procedure MAIN_PROCESS tRefactorActions ReFactorActions tRefactorCheckbox[] aRefactorCheckboxes
        String[] asFolderNames
        String sFileFilter sPath sFileName sText sTotalTime
        Handle hoEditor hoBPO
        Boolean bOK bWorkspaceMode bActionsExceptReports bIsEditorRefactorActions
        Integer eResponse
        DateTime dtExecStart dtExecEnd
        TimeSpan tsTotalTime

        Set pRefactorActions to ReFactorActions
        Set paRefactorCheckboxes to aRefactorCheckboxes
        Get pbWorkspaceMode of ghoApplication to bWorkspaceMode
        Get phoEditor of ghoApplication to hoEditor
        Get IsEditorRefactorActions of hoEditor to bIsEditorRefactorActions
        Get IsActionsExceptReports to bActionsExceptReports

        // We only switch to this view if any refactoring functions have been choosen
        // that is dependent of the editor object.
        If (bIsEditorRefactorActions = True) Begin
            // Switch view!
            Send Switch_Next_View of (Client_Id(phoMainPanel(ghoApplication)))
            Send Activate of hoEditor
        End

        If (bActionsExceptReports = True) Begin
            If (bWorkspaceMode = True) Begin   
                If (ReFactorActions.bCountNumberOfLines = False) Begin
                    Get StartWarning bWorkspaceMode "" to eResponse
                    If (eResponse <> MBR_Yes) Begin
                        Procedure_Return
                    End
                End
            End

            Else If (bWorkspaceMode = False) Begin
                Get psCurrentSourceFileName of ghoApplication to sFileName
                Get StartWarning bWorkspaceMode sFileName to eResponse
                If (eResponse <> MBR_Yes) Begin
                    Procedure_Return
                End
                Get psCurrentSourceFileName of ghoApplication to sFileName
                Send Start_StatusPanel to ghoStatusPanel
                Set Title_Text of ghoStatusPanel to ("Folder:" * String(ReFactorActions.Settings.asFolderNames[0]))
                Set Message_Text of ghoStatusPanel to ("File:" * String(sFileName))
                Set Action_Text of ghoStatusPanel  to ("File No:" * String("1") * "of:" * String("1"))
            End
        End

        Move (CurrentDateTime()) to dtExecStart

        Get phoBPO         to hoBPO
        Set pasFolderNames of hoBPO to ReFactorActions.Settings.asFolderNames
        Set psFileFilter   of hoBPO to ReFactorActions.Settings.sFileFilter
        Send InitializeCounters
        Move False to Err
        Move 0 to LastErr

        Get psHomePath of ghoApplication to sPath
        Send RemoveReportLogFiles sPath

        If (bWorkspaceMode = True) Begin
            Send DoProcess of hoBPO
            Get pbOk of hoBPO to bOk
        End
        Else Begin
            Get psCurrentSourceFileName of ghoApplication to sFileName
            Get ProcessFile sFileName True to bOK   
            Send Stop_StatusPanel of ghoStatusPanel
        End

        If (bOK = True) Begin
            Move (CurrentDateTime()) to dtExecEnd
            Move (dtExecEnd - dtExecStart) to tsTotalTime
            Get TimeSpanToString tsTotalTime to sTotalTime
            Send UpdateStatusBar ("Process completed. Elapsed Time:" * sTotalTime) True
            Get vFolderFormat sPath to sPath

            Get SummaryText True to sText
            // Send Info_Box (sText + "\n\nProcess completed. Elapsed Time:" * sTotalTime) (psProduct(ghoApplication))
            Send ActivateLogFile

            If (RefactorActions.bUnusedSourceFiles = True) Begin
                If (RefactorActions.Counters.iUnusedSourceFiles <> 0) Begin
                    Send DisplayUnusedSourceFilesDialog of (Client_Id(ghoCommandBars))
                End
            End
        End
        Else Begin
            Send Info_Box "The Process was unsuccessful." (psProduct(ghoApplication))
        End

    End_Procedure

    // Processes the file passed (with path) and performs the actions that have been chosen on it.
    // This function will always create a backup file and then call parsefile
    // for the actual work.
    Function ProcessFile String sFileName Boolean bFileMode Returns Boolean
        Boolean bSuccess bSaveBak bChanged bExists
        String sBackupFile
        Integer iRetval

        Move True to bSuccess
        Get pbShouldBackupFile of ghoApplication to bSaveBak
        If (bSaveBak = True) Begin
            Get SaveBackupFile of ghoApplication sFileName to bSuccess
        End

        If (bSuccess = True) Begin
            Send UpdateStatusBar sFileName True
            Set Action_Text of ghoStatusPanel  to sFileName

            Get ParseFile sFileName bFileMode to bSuccess

            Send IncrementFileCount
            Get FileCountersChanged to bChanged
            If (bChanged = True) Begin
                Send IncrementChangedFiles
            End

            // If no changes were made; move the file back its original place
            Else Begin
                Get BackupFileName of ghoApplication sFileName to sBackupFile  
                File_Exist sBackupFile bExists
                If (bExists = True) Begin
                    Get vMoveFile sBackupFile sFileName to iRetval
                    If (iRetval <> 0) Begin
                        Showln "Error moving file: " sBackupFile
                    End
                End
            End
        End

        Function_Return bSuccess
    End_Function

    // If bFileMode = True, only one source file is operated on.
    Function ParseFile String sSourceFile Boolean bFileMode Returns Boolean
        Boolean bParseOK bChanged bWriteOK bWebAppFile bFound
        Boolean bIsEditorRefactorActions bSaved bIsSame
        Boolean bProjectObjectStructureStart bProjectObjectStructureEnd bRegisterAllObjectsStart bRegisterAllObjectsEnd bWriteLine
        Integer iLine eSplitBy iTabSize iNoOfEmptyLines iMaxNoOfEmptyLines iSize
        String  sLine sBasePath sFileNameOnly sExtension
        Handle hoRemoveUnusedLocals hoEditor
        String[] asSourceFile asNewSourceFile asObjectNames
        tRefactorActions RefactorActions

        Move False to Err
        Move False to bParseOK
        Move False to bProjectObjectStructureStart
        Move False to bProjectObjectStructureEnd
        Move False to bRegisterAllObjectsStart
        Move False to bRegisterAllObjectsEnd      
        Get phoEditor of ghoApplication to hoEditor    
        
        Get pRefactorActions to RefactorActions
        Move RefactorActions.Settings.iTabSize       to iTabSize
        Move RefactorActions.Settings.iMaxBlankLines to iMaxNoOfEmptyLines

        Get ParseFileExtension sSourceFile to sExtension
        Move (".wo;.html;.asp;.css;.js" contains lowercase(sExtension)) to bWebAppFile
        // We don't want to remove any "Register_Object" if this is a WebApp file.
        If (bWebAppFile = True) Begin
            Move False to RefactorActions.bProjectObjectStructure
        End

        Get ReadSourceFileToArray sSourceFile to asSourceFile
        Get ParseFileName sSourceFile to sFileNameOnly

        Move (SizeOfArray(asSourceFile)) to iSize
        Set Message_Text of ghoStatusPanel to ("Parsing:" * String(sFileNameOnly) * "Lines:" * String(iSize))
        Decrement iSize

        If (RefactorActions.bCountNumberOfLines = False) Begin

            For iLine from 0 to iSize
                Move True  to bWriteLine
                Send UpdateStatusBar ("Refactoring line:" * String(iLine) * "of:" * String(iSize)) True
                Set Action_Text of ghoStatusPanel  to ("Refactoring line:" * String(iLine) * "of:" * String(iSize))
    
                // Read a line from the source file's string array.
                // This is the same string that potentially gets changed by several
                // refactoring functions, as it is passed as ByRef.
                Move asSourceFile[iLine] to sLine
    
                // If one of the following two sets bWriteLine to false,
                // the read source line will not be written to disk.
                If (RefactorActions.bRemoveOldStudioMarkers = True) Begin
                    Get RemoveOldStudioMarkers sLine to bFound
                    If (bFound = True) Begin
                        Move False to bWriteLine
                        Increment RefactorActions.Counters.iRemoveOldStudioMarkers
                    End
                End
                If (RefactorActions.bRemoveStudioGeneratedComments = True) Begin
                    Get RemoveStudioGeneratedComments sLine to bFound
                    If (bFound = True) Begin
                        Move False to bWriteLine
                        Increment RefactorActions.Counters.iRemoveStudioGeneratedComments
                    End
                End
                If (RefactorActions.bRemoveSansSerif = True and bWriteLine = True) Begin
                    Get RemoveSansSerif sLine to bFound
                    If (bFound = True) Begin
                        Move False to bWriteLine
                        Increment RefactorActions.Counters.iRemoveSansSerif
                    End
                End
    
                If (bWriteLine = True) Begin
                    If (RefactorActions.bProjectObjectStructure = True) Begin
                        // Do checking in reverse order; from bottom to top.
                        If (bRegisterAllObjectsEnd = False) Begin
                            If (bRegisterAllObjectsStart = False) Begin
                                Get IsRegisterAllObjectsStart sLine to bRegisterAllObjectsStart
                            End
                            If (bRegisterAllObjectsStart = True) Begin
                                Get IsRegisterObjectInArray sLine asObjectNames to bWriteLine
                                Move False to bProjectObjectStructureStart
                            End
                            If (bRegisterAllObjectsStart = False and bProjectObjectStructureEnd = False and bProjectObjectStructureStart = False) Begin
                                Get IsProjectObjectStructureStart sLine to bProjectObjectStructureStart
                            End
                            If (bProjectObjectStructureStart = True) Begin
                                Get IsProjectObjectStructureLine sLine (&asObjectNames) to bWriteLine
                            End
                            Get IsRegisterAllObjectsEnd sLine to bRegisterAllObjectsEnd
                            If (bWriteLine = False) Begin
                                Increment RefactorActions.Counters.iProjectObjectStructure
                            End
                        End
                    End
                    // The list of function calls have mostly been placed in alphabetical order,
                    // to make it easier to follow the struct variables and check that
                    // all are called properly. Some functions must be placed before
                    // this If-Begin construct, and some are called later as they work
                    // on the whole source file in one go.
                    If (RefactorActions.bChangeCurrent_ObjectToSelf = True) Begin
                        Get ChangeCurrent_ObjectToSelf (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeCurrent_ObjectToSelf
                        End
                    End
                    If (RefactorActions.bChangeDfTrueDfFalse = True) Begin
                        Get ChangeDfTrueDfFalse (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeDfTrueDfFalse
                        End
                    End
                    If (RefactorActions.bChangeFoundLoopIndicator = True) Begin
                        Get ChangeFoundLoopIndicator (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeFoundLoopIndicator
                        End
                    End
                    If (RefactorActions.bChangeFoundAndFindErrIndicators = True) Begin
                        Get ChangeFoundAndFindErrIndicators (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeFoundAndFindErrIndicators
                        End
                    End
                    If (RefactorActions.bChangeGetAddress = True) Begin
                        Get ChangeGetAddress (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeGetAddress
                        End
                    End
                    If (RefactorActions.bChangeIndicateFoundToMoveTrueToFound = True) Begin
                        Get ChangeIndicateFoundToMoveTrueToFound (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeIndicateFoundToMoveTrueToFound
                        End
                    End
                    If (RefactorActions.bChangeIndicatorRepeatToWhile = True) Begin
                        Get ChangeIndicatorRepeatToWhile (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeIndicatorRepeatToWhile
                        End
                    End
                    If (RefactorActions.bChangeIndicatorToIfBegin = True) Begin
                        Get ChangeIndicatorToIfBegin (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeIndicatorToIfBegin
                        End
                    End
                    If (RefactorActions.bChangeIndicatorToMoveStateToVariable = True) Begin
                        Get ChangeIndicatorToMoveStateToVariable (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeIndicatorToMoveStateToVariable
                        End
                    End
                    If (RefactorActions.bChangeInsertCommandToFunction = True) Begin
                        Get ChangeInsertCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeInsertCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangeInToContains = True) Begin
                        Get ChangeInToContains (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeInToContains
                        End
                    End
                    If (RefactorActions.bChangeLegacyOperators = True) Begin
                        Get ChangeLegacyOperators (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeLegacyOperators
                        End
                    End
                    If (RefactorActions.bChangeLengthCommandToFunction = True) Begin
                        Get ChangeLengthCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeLengthCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangePosCommandToFunction = True) Begin
                        Get ChangePosCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangePosCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangeReplaceCommandToFunction = True) Begin
                        Get ChangeReplaceCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeReplaceCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangeSysdate4 = True) Begin
                        Get ChangeSysdate4 (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeSysdate4
                        End
                    End
                    If (RefactorActions.bChangeTrimCommandToFunction = True) Begin
                        Get ChangeTrimCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeTrimCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangeZeroStringCommandToFunction = True) Begin
                        Get ChangeZeroStringCommandToFunction (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeZeroStringCommandToFunction
                        End
                    End
                    If (RefactorActions.bChangeUntilAndWhileIndicators = True) Begin
                        Get ChangeUntilAndWhileIndicators (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeUntilAndWhileIndicators
                        End
                    End
                    If (RefactorActions.bChangeUClassToRefClass = True) Begin
                        Get ChangeUClassToRefClass (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeUClassToRefClass
                        End
                    End

                    If (RefactorActions.bReplaceCalcWithMoveStatement = True) Begin
                        Get ReplaceCalcWithMoveStatement (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iReplaceCalcWithMoveStatement
                        End
                    End
                    // The RemoveBlankLines function must _not_ be placed here,
                    // because it needs to "digest" the whole source file in one go.
                    // Instead it is called below this loop.
                    //If (RefactorActions.bRemoveBlankLines = True) Begin
                    //    Get RemoveBlankLines (&sLine) to bChanged
                    //    If (bChanged = True) Begin
                    //        Increment RefactorActions.Counters.iRemoveBlankLines
                    //    End
                    //End
                    If (RefactorActions.bRemoveLocalKeyWord = True) Begin
                        Get RemoveLocalKeyWord (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iRemoveLocalKeyWord
                        End
                    End
                    If (RefactorActions.bRemovePropertyPrivate = True) Begin
                        Get RemovePropertyPrivate (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iRemovePropertyPrivate
                        End
                    End
                    If (RefactorActions.bRemovePropertyPublic = True) Begin
                        Get RemovePropertyPublic (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iRemovePropertyPublic
                        End
                    End
                    If (RefactorActions.bRemoveEndComments = True) Begin
                        Get RemoveEndComments (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iRemoveEndComments
                        End
                    End
                    If (RefactorActions.bRemoveTrailingSpaces = True) Begin
                        // Note! Must be after remove end comments
                        Get RemoveTrailingSpaces (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iRemoveTrailingSpaces
                        End
                    End

                    // Asolvi functions
                    If (RefactorActions.bChangewsDoTranslateTo_ = True) Begin
                        // Note! Must be after remove end comments
                        Get ChangewsDoTranslateTo_ (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangewsDoTranslateTo_
                        End
                    End
                    If (RefactorActions.bChangeLegacyShadow_State = True) Begin
                        // Note! Must be after remove end comments
                        Get ChangeLegacyShadow_State (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iChangeLegacyShadow_State
                        End
                    End
                    
                    // Note: MUST be the _last_ operation performed on the source line. Why?
                    //       Because it inserts carriage returrns & line feeds into the string.
                    //       If that string is passed to any other function, that function will mostly fail.
                    If (RefactorActions.bSplitInlineIfElseLine = True) Begin
                        Move RefactorActions.Settings.eSplitBy to eSplitBy
                        Get SplitInlineIfElseLine (&sLine) to bChanged
                        If (bChanged = True) Begin
                            Increment RefactorActions.Counters.iSplitInlineIfElseLine
                        End
                    End
    
                    // NOTE: Here the changed line is saved back to the array.
                    If (bWriteLine = True) Begin
                        Move sLine to asNewSourceFile[SizeOfArray(asNewSourceFile)]
                    End
                End
            Loop
        End
        Else If (RefactorActions.bCountNumberOfLines = True) Begin
            Get CountNumberOfLines sSourceFile to RefactorActions.Counters.iCountNumberOfLines
        End
        
        If (RefactorActions.bRemoveUnusedLocals = True) Begin
            Get phoRemoveUnusedLocals to hoRemoveUnusedLocals
            Get psHomePath of ghoApplication   to sBasePath
            Move (sBasePath + CS_BackupFolder) to sBasePath
            Get MainProcedure of hoRemoveUnusedLocals (&asNewSourceFile) to bParseOK
            If (bParseOK = True) Begin
                Get piNoOfUnusedLocalVariables of hoRemoveUnusedLocals to RefactorActions.Counters.iRemoveUnusedLocals
                Set piNoOfUnusedLocalVariables of hoRemoveUnusedLocals to 0
            End
        End  
        
        // This must go before we write the soure file back and the editor refactoring functions.
        If (RefactorActions.bRemoveBlankLines = True) Begin
            Get RemoveBlankLines (&asNewSourceFile) iMaxNoOfEmptyLines to iNoOfEmptyLines
            Move iNoOfEmptyLines to RefactorActions.Counters.iRemoveBlankLines
        End

        // We need to write the changes back to the source file before we call any Editor refactor function.
        Move (IsSameArray(asSourceFile, asNewSourceFile)) to bIsSame
        If (bIsSame = False) Begin
            Get WriteArrayToSourceFile sSourceFile asNewSourceFile to bWriteOK
            If (bWriteOK = False) Begin
                Function_Return False
            End
        End

        If (bFileMode = True) Begin
            Send UpdateSourceFileNameDisplay of ghoApplication sSourceFile
        End

        // Is there any refactor action that should be performed by the editor?
        Get IsEditorRefactorActions of hoEditor to bIsEditorRefactorActions
        If (bIsEditorRefactorActions = True) Begin
            // It seems it can be a bit to soon to try to load the newly edited file above,
            // because Windows haven't finished writing/releasing it yet.
            //            Sleep 1
            Send WaitForFileToGetWritten sSourceFile

            // This will display the file in the toolbar _and_ load it in the editor.
            If (bFileMode = False) Begin
                Send UpdateSourceFileNameDisplay of ghoApplication sSourceFile
            End
            // Tell the editor to perform refactor function(s) on the source file.
            Get RefactorSourceFileInEditor of hoEditor to bChanged
            If (bChanged = True) Begin
                If (RefactorActions.bRefactorDropSelf = True) Begin
                    Increment RefactorActions.Counters.iRefactorDropSelf
                End
                If (RefactorActions.bRefactorNormalizeCase = True) Begin
                    Increment RefactorActions.Counters.iRefactorNormalizeCase
                End
                If (RefactorActions.bRefactorReIndent = True) Begin
                    Increment RefactorActions.Counters.iRefactorReIndent
                End
                Get WriteToDisk of hoEditor to bSaved
            End
        End

        Set pRefactorActions to RefactorActions

        If (Err = False) Begin
            Move True to bParseOK
        End

        Function_Return bParseOK
    End_Function

    Procedure WaitForFileToGetWritten String sFile
        Integer iCh iMaxSec
        Boolean bOK bExist
        DateTime dtStart dtStartCheck
        TimeSpan tsTime

        Move False to bOK
        Move 3 to iMaxSec
        Get vFilePathExists sFile to bExist
        If (bExist = False) Begin
            Procedure_Return
        End
        Move (CurrentDateTime()) to dtStart
        Get Seq_New_Channel to iCh   
        // No channel available 
        If (iCh = DF_SEQ_CHANNEL_NOT_AVAILABLE) Begin
            Error "No Channel Available for Process: Procedure 'WaitForFileToGetWritten'"
            Procedure_Return
        End
        
        Repeat
            Direct_Input channel iCh
            Move (SeqEof = False) to bOK
            If (bOK = False) Begin
                Close_Input channel iCh
            End
            Move (CurrentDateTime()) to dtStartCheck
            Move (dtStartCheck - dtStart) to tsTime
            If (SpanSeconds(tsTime) > iMaxSec) Begin
                Move True to bOK
            End
        Until (bOK = True)

        Close_Input channel iCh
        Send Seq_Release_Channel iCh
    End_Procedure

    Function ReadSourceFileToArray String sSourceFile Returns String[]
        Boolean bLastLineBreak bEndOfFile bFirstLine
        Integer iLine iChannel iFileSize
        String sLine sLastLine sLineBreak sFileNameOnly
        String[] asSourceFile

        Move 0 to iLine
        Move True  to bFirstLine
        Move False to bEndOfFile
        Move False to bLastLineBreak
        Move ""    to sLastLine

        Get Seq_New_Channel to iChannel
        If (iChannel = DF_SEQ_CHANNEL_NOT_AVAILABLE) Begin
            Error "No Channel Available for Process: Procedure 'ReadSourceFileToArray'"
            Function_Return asSourceFile
        End

        Get ParseFileName sSourceFile to sFileNameOnly
        Set Message_Text of ghoStatusPanel to ("Reading:" * String(sFileNameOnly))
        Get vWin32_APIFileSize sSourceFile to iFileSize
        Move (ResizeArray(asSourceFile, iFileSize)) to asSourceFile

        // Need to use binary read mode if we want to preserve tab characters and not have automatic tab replacement
        // filemode options don't seem to work as documented, not sure why.
        // Direct_Input channel iInChannel ("binary: "+"cr: 13: "+"eof: 26: "+sSourceFile)
        // Direct_Input channel iInChannel ("binary: "+"cr: 13:"+"eof: 26:"+sSourceFile)
        Direct_Input channel iChannel ("binary:" + sSourceFile)

        While (bEndOfFile = False)
            Readln channel iChannel sLine
            Move (SeqEof) to bEndOfFile
            If (bEndOfFile and Length(sLastLine) > 0) Begin
                If (Right(sLastLine, 1) = CS_CR) Begin
                    Move True to bLastLineBreak
                End
            End
            Move sLine to sLastLine
            If (bFirstLine = True) Begin
                Move False to bFirstLine
                // Determine the linebreak character to use for the file based on what is in the first line
                // The readline automatically reads Until LF, but does not report LF back in the string
                If (Length(sLine) > 0 and Right(sLine, 1) = CS_CR) Begin
                    Move CS_CRLF to sLineBreak
                End
                Else Begin
                    Move CS_LF to sLineBreak
                End
                Set psLineBreak to sLineBreak
            End
            If (sLineBreak = CS_CRLF) Begin
                If (Right(sLine, 1) = CS_CR) Begin
                    Move (Left(sLine, Length(sLine) - 1)) to sLine
                End
            End
            If (bEndOfFile = False) Begin
                Move sLine to asSourceFile[iLine]
                Increment iLine
            End
        Loop

        Move (ResizeArray(asSourceFile, iLine)) to asSourceFile
        Set pbLastLineBreak to bLastLineBreak
        Close_Input channel iChannel
        Send Seq_Release_Channel iChannel

        Function_Return asSourceFile
    End_Function

    Function WriteArrayToSourceFile String sSourceFile String[] asNewSourceFile Returns Boolean
        Boolean bLastLineBreak
        Integer iOutChannel iSize iCount
        String  sLineBreak

        Move False to Err
        Get psLineBreak     to sLineBreak
        Get pbLastLineBreak to bLastLineBreak
        Get Seq_New_Channel to iOutChannel
        If (iOutChannel = DF_SEQ_CHANNEL_NOT_AVAILABLE) Begin
            Error "No Channel Available for Process: Procedure 'WriteArrayToSourceFile'"
            Function_Return False
        End

        Direct_Output channel iOutChannel sSourceFile
        Move (SizeOfArray(asNewSourceFile)) to iSize
        Decrement iSize   
        If (iSize >= 0) Begin
            For iCount from 0 to (iSize-1)
                Write channel iOutChannel asNewSourceFile[iCount] sLineBreak
            Loop
            If (bLastLineBreak=True) Begin
                Write channel iOutChannel asNewSourceFile[iSize] sLineBreak
            End
            Else Begin
                Write channel iOutChannel asNewSourceFile[iSize]
            End
        End

        Close_Input channel iOutChannel
        Send Seq_Release_Channel iOutChannel
        Function_Return (Err = False)
    End_Function  
    
    Function StartWarning Boolean bWorkspaceMode String sFileName Returns Integer
        Boolean bSaveBak
        Integer eResponse iSelectedFunctionsCount
        String  sMessage

        Get SelectedFunctions of oFunctions_DD to iSelectedFunctionsCount
        If (bWorkspaceMode) Begin
            Append sMessage "Prior running these routines you should ALWAYS have checked in the source code with a version control system and/or "
            Append sMessage "make a backup!\n\n"
            Append sMessage ("You have selected" * String(iSelectedFunctionsCount) * "refactoring functions that will be applied ")
            Append sMessage "to all files for the selected folders and subfolders that matches "
            Append sMessage "the 'File Extensions Filter' drop-down list.\n\nContinue?"
        End
        Else Begin
            Append sMessage ("You have selected" * String(iSelectedFunctionsCount) * "refactoring functions that will be applied to this source file:\n ")
            Append sMessage sFileName
            Append sMessage "\n\nContinue?"
        End
        // We now do this mandatory, so no need to ask.
//        Get pbShouldBackupFile of ghoApplication to bSaveBak
//        If (bSaveBak=False) Begin
//            Append sMessage "\n\nAttention: Please note that you did not enable the 'Create backup files' option in the Settings dialog"
//        End
        Get YesNo_Box sMessage "" MB_DEFBUTTON2 to eResponse

        Function_Return eResponse
    End_Function

    Function SummaryText Boolean bWriteLogFile Returns String
        String sText sLogText sLogFile sPath sTimeText sProgram sFormatString sValue
        Integer iChangedFiles
        Integer iFileCount iChannel
        tRefactorActions RefactorActions
        DateTime dtToday
        Boolean bExists
        
        Get pRefactorActions   to RefactorActions
        Get piChangedFileCount of ghoApplication to iChangedFiles
        Get piFileCount        of ghoApplication to iFileCount
        Move ("Total number of files changed:" * String(iChangedFiles) * "out of" * String(iFileCount) * "Files.\n") to sText
        Move (sText + "\nStatistics:\n===========") to sText
        
        If (RefactorActions.bProjectObjectStructure = True) ; 
            Append sText ("\no Removed 'Project Object Structure' lines:" * String(RefactorActions.Counters.iProjectObjectStructure))
        If (RefactorActions.bChangeCurrent_ObjectToSelf = True) ;
            Append sText ("\no Current_Object:" * String(RefactorActions.Counters.iChangeCurrent_ObjectToSelf) * "lines")
        If (RefactorActions.bChangeDfTrueDfFalse = True) ;
            Append sText ("\no DFTrue/DFFalse:" * String(RefactorActions.Counters.iChangeDfTrueDfFalse) * "lines")
        If (RefactorActions.bChangeFoundLoopIndicator = True) ;
            Append sText ("\no [Found] Loop:" * String(RefactorActions.Counters.iChangeFoundLoopIndicator) * "lines")
        If (RefactorActions.bChangeFoundAndFindErrIndicators = True) ;
            Append sText ("\no [Find FindErr] indicators:" * String(RefactorActions.Counters.iChangeFoundAndFindErrIndicators) * "lines")
        If (RefactorActions.bChangeGetAddress = True) ;
            Append sText ("\no Replaced 'GetAddress of' command:" * String(RefactorActions.Counters.iChangeGetAddress))
        If (RefactorActions.bChangeIndicateFoundToMoveTrueToFound = True) ;
            Append sText ("\no Indicate [Found] as True -> Move True to Found:" * String(RefactorActions.Counters.iChangeIndicateFoundToMoveTrueToFound))
        If (RefactorActions.bChangeIndicatorRepeatToWhile = True) ;
            Append sText ("\no [indicator] Repeat -> While (indicator):" * String(RefactorActions.Counters.iChangeIndicatorRepeatToWhile))
        If (RefactorActions.bChangeIndicatorToIfBegin = True) ;
            Append sText ("\no [Found] Begin -> If (Found) Begin:" * String(RefactorActions.Counters.iChangeIndicatorToIfBegin))
        If (RefactorActions.bChangeIndicatorToMoveStateToVariable = True) ;
            Append sText ("\no Windowindex Eq Fieldindex --> If (Select) Move (Windowindex = Fieldindex) to Select:" * String(RefactorActions.Counters.iChangeIndicatorToMoveStateToVariable))
        If (RefactorActions.bChangeInsertCommandToFunction = True) ;
            Append sText ("\no Insert command to function" * String(RefactorActions.Counters.iChangeInsertCommandToFunction))
        If (RefactorActions.bChangeInToContains = True) ;
            Append sText ("\no Replaced 'IN' with 'Contains':" * String(RefactorActions.Counters.iChangeInToContains))
        If (RefactorActions.bChangeLegacyOperators = True) ;
            Append sText ("\no Replaced 'If sTmp Ne '' Begin':" * String(RefactorActions.Counters.iChangeLegacyOperators))
        If (RefactorActions.bChangeLengthCommandToFunction = True) ;
            Append sText ("\no Length command to function" * String(RefactorActions.Counters.iChangeLengthCommandToFunction))
        If (RefactorActions.bChangePosCommandToFunction = True) ;
            Append sText ("\no Pos command to function" * String(RefactorActions.Counters.iChangePosCommandToFunction))
        If (RefactorActions.bChangeReplaceCommandToFunction = True) ;
            Append sText ("\no Replace command to function" * String(RefactorActions.Counters.iChangeReplaceCommandToFunction))
        If (RefactorActions.bChangeSysdate4 = True) ;
            Append sText ("\no Sysdate4 -> Sysdate" * String(RefactorActions.Counters.iChangeSysdate4))
        If (RefactorActions.bChangeTrimCommandToFunction = True) ;
            Append sText ("\no Trim command to function" * String(RefactorActions.Counters.iChangeTrimCommandToFunction))
        If (RefactorActions.bChangeZeroStringCommandToFunction = True) ;
            Append sText ("\no ZeroString command to function" * String(RefactorActions.Counters.iChangeZeroStringCommandToFunction))
        If (RefactorActions.bChangeUntilAndWhileIndicators = True) ;
            Append sText ("\no Until/While [indicator]" * String(RefactorActions.Counters.iChangeUntilAndWhileIndicators))
        If (RefactorActions.bChangeUClassToRefClass = True) ;
            Append sText ("\no Change 'U_class' style to 'RefClass':" * String(RefactorActions.Counters.iChangeUClassToRefClass))
        If (RefactorActions.bReplaceCalcWithMoveStatement = True) ;
            Append sText ("\no Replaced to use 'Move' command:" * String(RefactorActions.Counters.iReplaceCalcWithMoveStatement))
        If (RefactorActions.bRemoveBlankLines = True) ;
            Append sText ("\no Removed number of empty lines:" * String(RefactorActions.Counters.iRemoveBlankLines))
        If (RefactorActions.bRemoveLocalKeyWord = True) ;
            Append sText ("\no Removed number of 'Local' key word:" * String(RefactorActions.Counters.iRemoveLocalKeyWord))
        If (RefactorActions.bRemovePropertyPrivate = True) ;
            Append sText ("\no Private keywords removed:" * String(RefactorActions.Counters.iRemovePropertyPrivate))
        If (RefactorActions.bRemovePropertyPublic = True) ;
            Append sText ("\no Public keywords removed:" * String(RefactorActions.Counters.iRemovePropertyPublic))
        If (RefactorActions.bRemoveEndComments = True) ;
            Append sText ("\no End Comments removed:" * String(RefactorActions.Counters.iRemoveEndComments))
        If (RefactorActions.bRemoveOldStudioMarkers = True) ;
            Append sText ("\no Markers removed:" * String(RefactorActions.Counters.iRemoveOldStudioMarkers))
        If (RefactorActions.bRemoveSansSerif = True) ;
            Append sText ("\no Static fonts removed:" * String(RefactorActions.Counters.iRemoveSansSerif))
        If (RefactorActions.bRemoveStudioGeneratedComments = True) ;
            Append sText ("\no Studio generated comments:" * String(RefactorActions.Counters.iRemoveStudioGeneratedComments))
        If (RefactorActions.bRemoveTrailingSpaces = True) ;
            Append sText ("\no Right trimmed lines:" * String(RefactorActions.Counters.iRemoveTrailingSpaces) * "lines")
        If (RefactorActions.bSplitInlineIfElseLine = True) ;
            Append sText ("\no If/Else lines changed:" * String(RefactorActions.Counters.iSplitInlineIfElseLine))
        If (RefactorActions.bRefactorDropSelf = True) ;
            Append sText ("\no Dropping 'Self':" * String(RefactorActions.Counters.iRefactorDropSelf))
        If (RefactorActions.bRefactorNormalizeCase = True) ;
            Append sText ("\no Making proper Upper/Lowercase Source Code:" * String(RefactorActions.Counters.iRefactorNormalizeCase))
        If (RefactorActions.bRefactorReIndent = True) ;
            Append sText ("\no Reindent Source Code:" * String(RefactorActions.Counters.iRefactorReIndent))
        If (RefactorActions.bRemoveUnusedLocals = True) ;
            Append sText ("\no Removed number of unused Local variables:" * String(RefactorActions.Counters.iRemoveUnusedLocals))
        If (RefactorActions.bUnusedSourceFiles = True) ;
            Append sText ("\no Number of files unused by source program(s):" * String(RefactorActions.Counters.iUnusedSourceFiles))
        If (RefactorActions.bCountNumberOfLines = True) Begin
            Move ",#." to sFormatString
            Move (FormatValue(RefactorActions.Counters.iCountNumberOfLines, sFormatString)) to sValue
            Append sText ("\no Count of lines. Number of files:" * String(RefactorActions.Counters.iCountNumberOfFiles) * "Total Number of Lines:" * String(sValue))
        End

        // Asolvi functions
        If (RefactorActions.bChangewsDoTranslateTo_ = True) ;
            Append sText ("\no wsDoTranslate -> _:" * String(RefactorActions.Counters.iChangewsDoTranslateTo_))
        If (RefactorActions.bChangeLegacyShadow_State = True) ;
            Append sText ("\no Shadow_State -> Enabled_State:" * String(RefactorActions.Counters.iChangeLegacyShadow_State))

        If (bWriteLogFile = True) Begin
            Get psIdleText of (phoStatusBar(ghoCommandBars)) to sTimeText
            Get psHomePath of ghoApplication to sPath
            Get vFolderFormat sPath to sPath
            Get vFolderExists (sPath + CS_BackupFolder) to bExists
            If (bExists = False) Begin
                Send Info_Box ("Backup folder doesn't exist! Cannot write to logfile:" * String(sPath + CS_BackupFolder))
                Function_Return ""
            End
            Move (sPath + CS_BackupFolder + CS_DirSeparator + CS_SummaryLogfileName) to sLogFile
            Get Seq_New_Channel to iChannel
            // No channel available 
            If (iChannel = DF_SEQ_CHANNEL_NOT_AVAILABLE) Begin
                Error "No Channel Available for Process: Procedure 'SummaryText'"
                Function_Return ""
            End
            Append_Output channel iChannel sLogFile
            Move (Replaces("\n", sText, (Character(13) + Character(10)))) to sLogText
            Get psProduct of ghoApplication to sProgram
            Move (CurrentDateTime()) to dtToday
            Writeln channel iChannel "====================================================================================="
            Writeln channel iChannel "Created by: " sProgram " -- " dtToday
            Writeln channel iChannel sLogText
            Writeln channel iChannel sTimeText
            Writeln channel iChannel
            Close_Input channel iChannel
            Send Seq_Release_Channel iChannel
        End

        Function_Return sText
    End_Function

    Procedure InitializeCounters
        Set piChangedFileCount of ghoApplication to 0
        Set piFileCount        of ghoApplication to 0
        Set piNoOfUnusedLocalVariables of (phoRemoveUnusedLocals(Self)) to 0
    End_Procedure

    // Allow a .sws file, source file or folder to be dropped on the view:
    Procedure OnFileDropped String sFilename Boolean bLast
        String sFileExt
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
                Send UpdateSourceFileNameDisplay of ghoApplication sFileName
                Send LoadFile sFilename
                Set pbWorkspaceMode of ghoApplication to False
            End
            Else If (bSWSFile = True) Begin
                Send UpdateWorkspaceSelectorDisplay of ghoApplication sFilename
                Set pbWorkspaceMode of ghoApplication to True
            End
            Else If (bFolder = True) Begin
                Send Info_Box "You cannot drop a folder on this view."
            End
        End
        Else Begin
            Send Info_Box "Only one file can be dropped on the view. The last file will be used."
        End
    End_Procedure

    Function pbShouldSave Returns Boolean
        Boolean bChanged bIsReadOnly
        Handle hoEditor

        Get phoEditor of ghoApplication to hoEditor
        Get CM_IsModified of hoEditor to bChanged
        Get CM_IsReadOnly of hoEditor to bIsReadOnly
        Function_Return (bChanged = True and bIsReadOnly = False)
    End_Function

    Procedure Request_Save
        Handle hoEditor
        Boolean bChanged

        Get phoEditor of ghoApplication to hoEditor
        Get pbShouldSave to bChanged
        If (bChanged = True) Begin
            Send SaveFile of hoEditor
        End
    End_Procedure

    Procedure Request_Clear
        Handle hoEditor
        Get phoEditor of ghoApplication to hoEditor
        Send Delete_Data of hoEditor
        Send UpdateStatusBar "" False
    End_Procedure

    Procedure Request_Clear_All
        Handle hoEditor
        Get phoEditor of ghoApplication to hoEditor
        Send Delete_Data of hoEditor
        Send UpdateStatusBar "" False
    End_Procedure

    Procedure UpdateStatusBar String sText Boolean bIdleTextOnly Integer iLi Integer iChrs
        Handle hoStatusBar
        Integer iLines iCharacters

        Move (StatusBar_Id(Self)) to hoStatusBar
        If (num_arguments > 2) Begin
            Move iChrs to iCharacters
            If (iCharacters = 0) Begin
                Move 0 to iLines
            End                 
            Else Begin
                Move iLi to iLines
            End
            Set NumberOfEditorLines      of hoStatusBar to iLines
            Set NumberOfEditorCharacters of hoStatusBar to iCharacters
        End
        Else Begin
            If (bIdleTextOnly = True) Begin
                Set psIdleText of hoStatusBar to sText
                Set ActionText of hoStatusBar to ""
            End
            Else Begin
                Set ActionText of hoStatusBar to sText
            End
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

    Procedure Activate_View Returns Integer
        String sSourceFilename

        Forward Send Activate_View

        Get psCurrentSourceFileName of ghoApplication to sSourceFilename
        If (sSourceFilename <> "") Begin
            Send UpdateSourceFileNameDisplay of ghoApplication sSourceFilename
            Send LoadFile sSourceFilename
            Send Top_of_Panel
        End
        Send Switch_Next_View of (Client_Id(phoMainPanel(ghoApplication)))

    End_Procedure

    Procedure End_Construct_Object
        Forward Send End_Construct_Object
        // Define the save procedure for the editor object.
        Send DefineOnKey of (phoEditor(ghoApplication)) CMD_FileSaveAll msg_Request_Save
    End_Procedure

End_Object
