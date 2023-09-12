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

Activate_View Activate_oSortSourceCode for oSortSourceCode
Object oSortSourceCode is a dbView
    Set Size to 345 522
    Set Location to 2 2
    Set Label to "Sort Class Code"
    Set Border_Style to Border_Thick
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
                Append sVal "Utility to sort a source file's classes, procedures and functions. "
                Append sVal "Select the source file of choice and press the 'Save New Source' button."
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
        Set Label to "Sort Info"
        Set psImage to "ActionSort.ico"
        Set psNote to "Class Sort Info. Note: Construct_Object/End_Construct_Object are always at top"
        Set psToolTip to "Sorted result for Classes, Procedures and Functions. Note: Construct_Object/End_Construct_Object are always at top"
        Set peAnchors to anNone

        Object oSourceFileData_grd is a cRDCCJGrid
            Set Size to 115 461
            Set Location to 30 38
            Set pbShowFooter to True
    
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
                
                Get piColumnId of oClassData_Col to iClassCol
                Get piColumnId of oProcData_Col to iProcCol
                Get piColumnId of oFuncData_Col to iFuncCol
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
                    Move (SizeOfArray(ProcsArray)) to iProcs 
                    Set psFooterText of oProcData_Col to ("No of Procedures" * String(iProcs))
                    Decrement iProcs
                    For iCount from 0 to iProcs
                        Move ProcsArray[iCount].sMethodName to sProcName
                        Move ProcsArray[iCount].iLines      to iLines
                        Move (sProcName * "(" + String(iLines) + ")") to sProcName
                        Move sClassName to TheData[iCount + iStart].sValue[iClassCol]
                        Move sProcName  to TheData[iCount + iStart].sValue[iProcCol]
                    Loop
                    
                    Move TheSource[iClassCount].ClassData.FunctionsData to FuncsArray
                    Move (SizeOfArray(FuncsArray)) to iFuncs
                    Set psFooterText of oFuncData_Col to ("No of Functions" * String(iFuncs))
                    Decrement iFuncs
                    For iCount from 0 to iFuncs
                        Move FuncsArray[iCount].sMethodName to sFuncName
                        Move FuncsArray[iCount].iLines      to iLines
                        Move (sFuncName * "(" + String(iLines) + ")") to sFuncName
                        Move sClassName to TheData[iCount + iStart].sValue[iClassCol]
                        Move sFuncName  to TheData[iCount + iStart].sValue[iFuncCol]
                    Loop
                    
                    Move (SizeOfArray(TheData)) to iStart
                    Increment iClassCount
                Loop
                
                Send InitializeData TheData
                Send MoveToFirstRow
            End_Procedure
        End_Object

    End_Object

    Object oSortFunctions_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 61
        Set Label to "Sort Functions"
        Set Checked_State to True 
        Set Visible_State to False
    End_Object

    Object oSortProcedures_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 131
        Set Label to "Sort Procedures"
        Set Checked_State to True
        Set Visible_State to False
    End_Object

    Object oSortWithinClassesOnly_cb is a CheckBox
        Set Size to 10 50
        Set Location to 324 202
        Set Label to "Sort methods in Classes Only"
        Set Checked_State to True
        Set Visible_State to False
    End_Object

    Object oSaveSource_btn is a Button
        Set Size to 23 61
        Set Location to 318 456
        Set Label to "Save New Source"
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
    
    End_Object    

    Object oRestoreSourceFile_btn is a cRDCButton
        Set Size to 23 61
        Set Location to 318 353
        Set Label to "Restore Source File"
        Set psImage to "UndoRefactoring.ico"
        Set MultiLineState to True
        Set piImageSize to 24  
        Set psToolTip to "Restore the newly written file by overwriting it by the backup file (original source file)."
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
    
End_Object
