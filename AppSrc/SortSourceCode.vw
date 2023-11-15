Use Windows.pkg
Use DFClient.pkg
Use File_dlg.pkg
Use cCJGrid.pkg
Use cCJGridColumn.pkg
Use cCJGridColumnRowIndicator.pkg
Use cRDCDbHeaderGroup.pkg
Use cSortSourceCode.pkg 
Use cRDCHeaderGroup.pkg
Use cRDCCJGrid.pkg 
Use cRDCButton.pkg

Activate_View Activate_oSortSourceCode_vw for oSortSourceCode_vw
Object oSortSourceCode_vw is a dbView
    Set Size to 351 522
    Set Location to 2 2
    Set Label to "Sort Class Code"
    Set Border_Style to Border_Thick
    Set Icon to "ActionSort.ico"
    Set pbAutoActivate to True

    Object oSortSourceCode is a cSortSourceCode
    End_Object

    Object oInfo_grp is a cRDCDbHeaderGroup
        Set Size to 56 509
        Set Location to 17 6
        Set Label to "Sort Class Code"
        Set psImage to "ActionAbout.ico"
        Set psNote to "Source Code Sorter"
        Set psToolTip to "How to sort a package file's Classes, Procedures and Functions."
        Set peAnchors to anNone

        Object oInfo_tb is a TextBox
            Set Auto_Size_State to False
            Set Size to 33 423
            Set Location to 29 53
            Set Justification_Mode to JMode_Left
            Set Label to "Info text"
            
            Procedure Page Integer iPageObject  
                String sVal
                Append sVal "Utility to sort any source file's classes, procedures and functions, alphabetically, in that order. "
                Append sVal "Select a source file (F4) and press the 'Save Sorted Source File' button."
                Append sVal (CS_CR + "Note: A backup copy of the selected source file will be created in the AppSrc" * "'" + CS_SortBackupFolder + "'" * "sub-folder.")
                Move (Replaces("\n", sVal, (CS_CR))) to sVal
                Set Label to sVal
                Forward Send Page iPageObject
            End_Procedure
            
        End_Object

    End_Object

    Object oSelectSourceFile_grp is a cRDCHeaderGroup
        Set Size to 58 509
        Set Location to 83 6
        Set Label to "Select Class File"
        Set peAnchors to anNone
        Set psImage to "ActionOpen.ico"
        Set psNote to "Select a package file with Classes, Packages and Functions to sort (F4)."
        
        Object oSourceFileName_fm is a Form
            Set Size to 12 403
            Set Location to 39 40
            Set Label to "File Name:"
            Set Label_Col_Offset to 0
            Set Label_Justification_Mode to JMode_Top
            Set peAnchors to anNone
            
            Procedure Prompt
                String[] asFiles
                String sPath sFileName
                Handle ho
                Boolean bOpen
                
                Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sPath
                Get Create (RefClass(OpenDialog)) to ho
                Set Filter_String  of ho to "Packages|;*.pkg|Include Files|*.inc|All Source|*.src;*.pkg;*.inc|All Files|*.*"
                Set Initial_Folder of ho to sPath
                Get Show_Dialog of ho to bOpen
                If (bOpen = True) Begin
                    Get Selected_Files of ho to asFiles
                    Move asFiles[0] to sFileName
                    Set Value to sFileName
                    Send DisplaySourceFileMetaData sFileName
                End
                
                Send Destroy of ho
            End_Procedure 
            
            Procedure DisplaySourceFileMetaData String sFileName
                Handle ho
                Integer iSize
                String[] asSourceFile
                tSourceCode[] TheData
                
                Move (oSortSourceCode(Self)) to ho
                Set psSourceFile of ho to sFileName
                Set psBackupSourceFile of ho to ""
                Get ReadSourceFile of ho sFileName False (&iSize) to asSourceFile
                If (SizeOfArray(asSourceFile) = 0) Begin
                    Send Info_Box "The selected file was empty!"
                    Procedure_Return
                End                                               
                
                Get FillSourceCodeStruct of ho asSourceFile to TheData
                Get SortClassesAndMethods of ho TheData to TheData
                Send FillData of oSourceFileData_grd TheData
            End_Procedure  
            
            Procedure Clear 
                Set psSourceFile of (oSortSourceCode(Self)) to ""
                Set Value to ""
            End_Procedure
            
            On_Key kClear Send Clear_All
        End_Object
    
        Object oOpen_btn is a Button
            Set Size to 12 53
            Set Location to 39 448
            Set Label to "Select File"
            Set psImage to "ActionOpen.ico"
            Set peAnchors to anNone
            Set Default_State to True
        
            Procedure OnClick
                Send Prompt of oSourceFileName_fm    
            End_Procedure
        
        End_Object

    End_Object

    Object oShowSort_grp is a cRDCHeaderGroup
        Set Size to 154 509
        Set Location to 152 6
        Set Label to "Sort Result"
        Set psImage to "ActionSort.ico"
        Set psNote to "Class Sort Result. Note: Construct_Object/End_Construct_Object are always at top"
        Set psToolTip to "Sorted result for Classes, Procedures and Functions. Note: Construct_Object/End_Construct_Object are always at top"
        Set peAnchors to anNone 

        Object oSourceFileData_grd is a cRDCCJGrid
            Set Size to 115 461
            Set Location to 30 38
            Set pbAllowEdit to False
            Set pbAllowAppendRow to False
            Move 0 to ghoProjectIniFile 
    
            Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
            End_Object
    
            Object oClassData_Col is a cCJGridColumn
                Set piWidth to 100
                Set psCaption to "Class Name (and lines)"
            End_Object
    
            Object oProcData_Col is a cCJGridColumn
                Set piWidth to 100
                Set psCaption to "Procedure Name (and lines)"
            End_Object
    
            Object oFuncData_Col is a cCJGridColumn
                Set piWidth to 100
                Set psCaption to "Function Name (and lines)"
            End_Object  
            
            Procedure FillData tSourceCode[] TheSource
                Integer iClassCol iProcCol iFuncCol iSize iCount iClasses iClassCount iLines iProcs iFuncs iStart
                tDataSourceRow[] TheData
                tMethod[] ProcsArray FuncsArray              
                String sClassName sProcName sFuncName
                
                Move 0 to iProcs
                Move 0 to iFuncs
                Get piColumnId of oClassData_Col to iClassCol
                Get piColumnId of oProcData_Col  to iProcCol
                Get piColumnId of oFuncData_Col  to iFuncCol
                Move (SizeOfArray(TheSource)) to iClasses
                Set psFooterText of oClassData_Col to ("No of Classes" * String(iClasses))
                Move 0 to iStart
                Move 0 to iClassCount
                Decrement iClasses
                While (iClassCount <= iClasses)
                    Move TheSource[iClassCount].sClassName to sClassName
                    Move TheSource[iClassCount].iLines     to iLines
                    Move (sClassName * "(" + String(iLines) + ")") to sClassName
                    
                    Move TheSource[iClassCount].ClassData.ProceduresData to ProcsArray
                    Move (SizeOfArray(ProcsArray)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Move ProcsArray[iCount].sMethodName to sProcName
                        Move ProcsArray[iCount].iLines      to iLines
                        Move (sProcName * "(" + String(iLines) + ")") to sProcName
                        Move sClassName to TheData[iCount + iStart].sValue[iClassCol]
                        Move sProcName  to TheData[iCount + iStart].sValue[iProcCol]
                    Loop
                    Move (iProcs + SizeOfArray(ProcsArray)) to iProcs 
                    
                    Move TheSource[iClassCount].ClassData.FunctionsData to FuncsArray
                    Move (SizeOfArray(FuncsArray)) to iSize
                    Decrement iSize
                    For iCount from 0 to iSize
                        Move FuncsArray[iCount].sMethodName to sFuncName
                        Move FuncsArray[iCount].iLines      to iLines
                        Move (sFuncName * "(" + String(iLines) + ")") to sFuncName
                        Move sClassName to TheData[iCount + iStart].sValue[iClassCol]
                        Move sFuncName  to TheData[iCount + iStart].sValue[iFuncCol]
                    Loop
                    Move (iFuncs + SizeOfArray(FuncsArray)) to iFuncs
                    
                    Move (SizeOfArray(TheData)) to iStart
                    Increment iClassCount
                Loop
                
                Send InitializeData TheData
                Set psFooterText of oProcData_Col to ("Total No of Procedures" * String(iProcs))
                Set psFooterText of oFuncData_Col to ("Total No of Functions" * String(iFuncs))
                Send MoveToFirstRow
            End_Procedure   

//            Function Server Returns Integer  
//                Function_Return Self
//            End_Function         
//                        
//            Function Main_File Returns Integer
//            End_Function         
//            
//            Function FindByRowIndex Returns Integer
//            End_Function         
//            
//            Function Ordering Returns Integer
//            End_Function         
//            
//            Function Request_Read Returns Integer
//            End_Function         
//            
//            Function HasRecord Returns Integer
//            End_Function         
//            
//            Function CurrentRowId  Returns RowID
//            End_Function
//            
//            Function HasRecord  Returns Boolean
//            End_Function
//            
//            Procedure FindByRowId  Integer iFile RowID riRowId
//            End_Procedure
//            
//            Procedure ReadByRowId  Integer iFile RowID riRowId
//            End_Procedure
//            
//            Function ReadByRowIdEx Integer iFile RowID riId Returns Boolean
//            End_Function
//            
//            Function FindByRowIdEx Integer iFile RowID riId Returns Boolean
//            End_Function
//    
//            Procedure Suggested_Ordering
//            End_Procedure               
//
//            Procedure DoSetCurrentRow
//            End_Procedure
            
            Procedure Clear
                Handle hoDataSource
                Get phoDataSource to hoDataSource
                Send ResetAll of hoDataSource
//                Send Clear of oSourceFileName_fm
            End_Procedure
            
            Procedure OnComRowRClick Variant llRow Variant llItem
            End_Procedure

            On_Key kClear Send Clear_All
        End_Object

    End_Object

    Object oSortFunctions_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 10
        Set Label to "Sort Functions"
        Set Checked_State to True 
        Set Visible_State to False
    End_Object

    Object oSortProcedures_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 73
        Set Label to "Sort Procedures"
        Set Checked_State to True
        Set Visible_State to False
    End_Object

    Object oSortWithinClassesOnly_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 144
        Set Label to "Sort methods in Classes Only"
        Set Checked_State to True
        Set Visible_State to False
    End_Object

    Object oSaveSource_btn is a cRDCButton
        Set Size to 28 61
        Set Location to 317 456
        Set Label to "Save Sorted Source File"
        Set psImage to "ActionSave.ico"
        Set MultiLineState to True
        Set piImageSize to 24
    
        Procedure OnClick
            String sFileName sRetVal                          
            Boolean bExists bSortFunction bSortProcedure bSortClassesOnly
            Handle ho
            
            Get Value of oSourceFileName_fm to sFileName
            File_Exist sFileName bExists
            If (bExists = False) Begin
                Send Info_Box ("The file:" * String(sFileName) * "does not exist! Please adjust and try again.")
                Procedure_Return
            End
            
            Move (oSortSourceCode(Self)) to ho  
            
            // ToDo: These properties has not yet been implemented in class code.
            Get Checked_State of oSortFunctions_cb  to bSortFunction
            Get Checked_State of oSortProcedures_cb to bSortProcedure
            Get Checked_State of oSortWithinClassesOnly_cb to bSortClassesOnly
            Set pbSortFunctions   of ho to bSortFunction
            Set pbSortProcedures  of ho to bSortProcedure
            Set pbSortClassesOnly of ho to bSortClassesOnly

            Get MainSortingMethod of ho sFileName to sRetVal
            Send Info_Box sRetVal
        End_Procedure
    
        Function IsEnabled Returns Boolean
            String sSourceFile
            Boolean bExists
            Get psSourceFile of oSortSourceCode to sSourceFile
            Function_Return (sSourceFile <> "")
        End_Function                        
        
    End_Object    

    Object oRestoreSourceFile_btn is a cRDCButton
        Set Size to 28 61
        Set Location to 317 364
        Set Label to "Restore Source File"
        Set psImage to "UndoRefactoring.ico"
        Set MultiLineState to True
        Set piImageSize to 24  
        Set psToolTip to "Restore the newly written file by overwriting it with the backup file (original source file)."
        Set Enabled_State to False
    
        Procedure OnClick
            String sSourceFile sBackupFile sPath sExt sDateStamp
            Boolean bExists bSortFunction bSortProcedure bSortClassesOnly
            Integer iRetval 
            Handle ho
            
            Get YesNo_Box "This will restore the newly sorted source file with the copy from the backup folder.\n\nContinue?" to iRetval
            If (iRetval <> MBR_Yes) Begin
                Procedure_Return
            End
            
            Move (oSortSourceCode(Self)) to ho  
            Get Value of oSourceFileName_fm to sSourceFile
            Get psBackupSourceFile of ho to sBackupFile
            Get psAppSrcPath of (phoWorkspace(ghoApplication)) to sPath
            Get vFolderFormat sPath to sPath
            Get ParseFileName sBackupFile to sSourceFile
            Get ParseFileExtension sSourceFile to sExt
            Move (Replace("." + sExt, sSourceFile, "")) to sSourceFile
            Get ParseFileExtension sSourceFile to sDateStamp
            Move (Replace(sDateStamp, sSourceFile, "")) to sSourceFile
            Append sSourceFile sExt
            
            Get vCopyFile sBackupFile (sPath + sSourceFile) to iRetVal
            If (iRetVal <> 0) Begin
                Send Info_Box "The restore failed! The backup file still exists in the backup folder."
            End                                                                                      
            Else Begin
                Send Info_Box "Success! The backup file was restored."
            End
        End_Procedure
        
        Function IsEnabled Returns Boolean
            String sBackupFile
            Boolean bExists
            Get psBackupSourceFile of oSortSourceCode to sBackupFile
            File_Exist sBackupFile bExists
            Function_Return (bExists = True)
        End_Function                        
        
    End_Object    

    Object oOpenContainingFolder_btn is a cRDCButton
        Set Size to 28 61
        Set Location to 317 300
        Set Label to "Open Containing Folder"
        Set psImage to "ActionOpenContainingFolder.ico"
        Set MultiLineState to True
        Set piImageSize to 24  
        Set psToolTip to "Open the containg folder for the backup file in Windows Explorer."
        Set Enabled_State to False
    
        Procedure OnClick
            String sPath sFileName

            Get psBackupSourceFile of oSortSourceCode to sFileName
            Get ParseFolderName sFileName to sPath

            // We want to have that file to be selected in Windows Explorer
            If (sFileName <> "") Begin
                Move ("/select, " + sFileName) to sPath
            End
            Send vShellExecute "open" "explorer.exe" sPath ""
        End_Procedure
        
        Function IsEnabled Returns Boolean
            String sBackupFile
            Boolean bExists
            Get psBackupSourceFile of oSortSourceCode to sBackupFile
            File_Exist sBackupFile bExists
            Function_Return (bExists = True)
        End_Function                        
        
    End_Object

    Procedure Clear_All
        Broadcast Recursive Send Clear of oSortSourceCode_vw
    End_Procedure
    
    On_Key kClear Send Clear_All
End_Object
