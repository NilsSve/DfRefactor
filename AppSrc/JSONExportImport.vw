// C:\Projects\DF18\DfRefactor\AppSrc\FunctionExportImport.vw
// Functions Export/Import
//
Use DFClient.pkg                                  
//Use cRefactorDbView.pkg
Use cRDCDbView.pkg
Use DFEntry.pkg
Use File_dlg.pkg
Use cDbTextEdit.pkg
Use cCJGridColumn.pkg
Use cRDCCJSelectionGrid.pkg
Use cRDCDbHeaderGroup.pkg
Use cRDCButton.pkg                             
Use cExportImportFunctions.pkg

Use cFunctionsDataDictionary.dd

Activate_View Activate_oJSONExportImport for oJSONExportImport
Object oJSONExportImport is a cRDCDbView
    Set Location to 5 5
    Set Size to 372 650
    Set Label to "JSON Export/Import"
    Set Border_Style to Border_Thick
    Set Icon to "Export.ico"
    Set pbAutoActivate to True   
    
    Property Handle phoSelection_lst
    Property Handle phoSelection_grd

    Object oImportExportFunctions is a cImportExportFunctions
        Move Self to ghoImportExportFunctions 
    End_Object

    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD to oFunctions_DD
    Set Server  to oFunctions_DD

    Object oInfo_grp is a cRDCDbHeaderGroup
        Set Size to 103 637
        Set Location to 17 6
        Set Label to "Info"
        Set psImage to "ActionAbout.ico"
        Set psNote to "Info about Export/Import"
        Set psToolTip to "How to Export/Import function data to/from Json file."
        Set peAnchors to anNone
        Set Color to clEditorBackGround
        Set piLabelColor to clWhite

        Object oInfo_tb is a TextBox
            Set Auto_Size_State to False
            Set Size to 67 419
            Set Location to 29 45
            Set Justification_Mode to JMode_Left
            Set Label to "How it works"
            Set TextColor to clWhite
            
            Procedure Page Integer iPageObject  
                String sVal
                Append sVal "This view is designed to enable you to Export/Import refactoring data and source code from one machine to another."
                Append sVal "\n\nSelect the functions to be exported. The data from the Functions table together with the corresponding function code text "
                Append sVal "from the oRefactorFuncLib- and oUnit_Tests objects, will be exported to a Json file that can be copied/sent to another machine for import, in alphabetical order by function name."
                Move (Replaces("\n", sVal, (CS_CR))) to sVal
                Set Label to sVal
                Forward Send Page iPageObject
            End_Procedure
            
        End_Object

    End_Object

    Object oExport_grp is a cRDCDbHeaderGroup
        Set Size to 150 637
        Set Location to 131 8
        Set Label to "Export"
        Set psImage to "Export.ico"
        Set psNote to "Export Functions to Json."
        Set psToolTip to ("Export function data from the Functions table, function code from:" * String(CS_FunctionLibraryFile) * "and Unit testing from:" * String(CS_UnitTestsFile) + ", to Json file:" * String(CS_ImpExpFileJson))
        Set peAnchors to anNone

        Object oFunctionsID is a dbForm
            Entry_Item Functions.ID
            Set Size to 12 34
            Set Location to 33 59
            Set Label to "ID"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0
            Set Prompt_Button_Mode to PB_PromptOn
        End_Object 
      
        Object oFunctionsFunction_Name is a dbForm
            Entry_Item Functions.Function_Name
            Set Size to 12 250
            Set Location to 46 59
            Set Label to "Name"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0  
        End_Object 
     
        Object oFunctionsFunction_SummaryText is a dbForm
            Entry_Item Functions.SummaryText
            Set Size to 12 250
            Set Location to 61 59
            Set Label to "Summary Text"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0
            Set Enabled_State to False
        End_Object 
        
        Object oFunctionsFunction_Help is a cDbTextEdit
            Entry_Item Functions.Function_Help
            Set Size to 37 250
            Set Location to 75 59
            Set Label to "Help Text"
            Set Label_Justification_Mode to JMode_Right
            Set Label_Col_Offset to 2
            Set Label_Row_Offset to 0
            Set Read_Only_State to True
            Set Border_Style to Border_WindowEdge

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
                End
            End_Procedure
            
        End_Object 

        Object oCopyToRight_btn is a cRDCButton
            Set Size to 12 55
            Set Location to 46 317
            Set Label to "Add >>"
            Set Default_State to True
        
            Procedure OnClick
                Handle hoGrid hoDD 
                Integer iID iItem
                String sFunctionName
                tFolderData[] asDataArray
                tFolderData FunctionData
                
                Delegate Get phoSelection_grd to hoGrid
                Move (Main_DD(Self)) to hoDD
                Get Field_Current_Value of hoDD Field FunctionsA.ID to iID
                Get Field_Current_Value of hoDD Field FunctionsA.Function_Name to sFunctionName
                
                // We guard against the same function is added more than once.
                Get AllItems of oSelection_grd to asDataArray 
                Move -1 to iItem
                If (SizeOfArray(asDataArray) > 0) Begin
                    Move sFunctionName to FunctionData.sFolderName
                    Move (SearchArray(FunctionData, asDataArray)) to iItem 
                    // This is weird, but the following line always returns = 0(!)
                    // That doesn't matter to us in this case as the casing should always be the same.
                    // Move (SearchArray(FunctionData, asDataArray, Desktop, RefFunc(DFSTRICMP))) to iItem
                End
                If (iItem <> -1) Begin
                    Send Info_Box "Function already selected."
                    Procedure_Return
                End
                If (iID <> 0) Begin
                    Send AddItem of hoGrid iID sFunctionName
                    Send DoSetCheckboxFooterText of hoGrid
                End
            End_Procedure
        
        End_Object
        
        Object oRemoveFromList_btn is a cRDCButton
            Set Size to 12 55
            Set Location to 61 316
            Set Label to "<< Remove"
            
            Procedure OnClick
                Send DeleteSelectedItem
            End_Procedure
            
            Procedure DeleteSelectedItem    
                Handle hoGrid 
                Integer iCount
                
                Delegate Get phoSelection_grd to hoGrid
                Get ItemCount of hoGrid to iCount
                If (iCount = 0) Begin
                    Procedure_Return
                End
                Send Request_Delete of hoGrid
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
            
        End_Object

        Object oAddAll_btn is a cRDCButton
            Set Size to 14 55
            Set Location to 83 317
            Set Label to "Add All >>"
            
            Procedure OnClick
                Handle hoGrid 
                
                Delegate Get phoSelection_grd to hoGrid
                Send Request_Clear_All of hoGrid
                Clear FunctionsA
                Repeat
                    Find gt FunctionsA.ID 
                    If (Found = True) Begin
                        Send AddItem of hoGrid FunctionsA.ID FunctionsA.Function_Name
                    End
                Until (Found = False)
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
        
        End_Object

        Object oRemoveAll_btn is a cRDCButton
            Set Size to 14 55
            Set Location to 98 316
            Set Label to "<< Remove All"
        
            Procedure OnClick
                Handle hoGrid 
                Delegate Get phoSelection_grd to hoGrid
                Send Request_Clear_All of hoGrid
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
                
        End_Object 
        
        Object oSelection_grd is a cRDCCJSelectionGrid
            Set Size to 91 178
            Set Location to 21 379
            Set pbShowInvertSelectionsMenuItem to False
            Set psNoItemsText to "No data yet..."
            Delegate Set phoSelection_grd to Self  
            
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set phoContextMenu to 0
            End_Procedure

            Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
                Set piWidth to 25
            End_Object

            Object oFunctionID_Col is a cCJGridColumn
                Set piWidth to 30
                Set psCaption to "ID"    
                Set peDataType to Mask_Numeric_Window
            End_Object

            Object oFunctionName_Col is a cCJGridColumn
                Set piWidth to 241
                Set psCaption to "Function Name"
                Set phoData_Col to Self
            End_Object
            
            Procedure ToggleCurrentItem
            End_Procedure 
            
            Procedure LoadData
                Set pbVisible of (phoCheckbox_Col(Self)) to False 
                Set piWidth of (phoCheckbox_Col(Self)) to 0
            End_Procedure
            
            Procedure AddItem String sDataValue String sFunctionName
                Handle hoDataSource
                tDataSourceRow[] TheData
                tsSearchResult[] asFolderArray
                Integer iSize iData_Col iCheckbox_Col iID_Col
        
                If (not(IsComObjectCreated(Self))) Begin
                    Procedure_Return
                End
                Move (Trim(sDataValue)) to sDataValue
                Move (Trim(sFunctionName)) to sFunctionName
        
                Get piColumnId of (oFunctionID_Col(Self)) to iID_Col
                Get piColumnId of (phoData_Col(Self))     to iData_Col
                Get piColumnId of (phoCheckbox_Col(Self)) to iCheckbox_Col
                Get phoDataSource to hoDataSource
                Get DataSource of hoDataSource to TheData
                Move (SizeOfArray(TheData)) to iSize
                Move sDataValue    to TheData[iSize].sValue[iID_Col]
                Move sFunctionName to TheData[iSize].sValue[iData_Col]
                Move False         to TheData[iSize].sValue[iCheckbox_Col]

                Send DoSetCheckboxFooterText
                Send ReInitializeData TheData False
                Send MoveToLastRow
            End_Procedure

            Procedure DoSetCheckboxFooterText
                Integer iCol iItems
                Handle hoCol hoCheckbox_Col
                Get piColumnId of (oFunctionName_Col(Self)) to iCol
                Get ItemCount to iItems
                Get ColumnObject iCol to hoCol
                Set psFooterText of hoCol  to ("Count:" * String(iItems))
            End_Procedure

            Procedure DoChangeFontSize
            End_Procedure
            
        End_Object
        
        Object oExport_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 33 564
            Set Label to "Export Data"
            Set psToolTip to "Export selected function ID's data records *and* the corresponding function text(s) from the oRefactorFuncLib repository class."
            Set peAnchors to anNone 
            Set psImage to "JsonFile.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                Handle hoGrid 
                Integer iSize iRetval
                String[] asFunctions 
                Boolean bOK bExists
                String sFileName sFolder
                
                Delegate Get phoSelection_grd to hoGrid
                Get ItemCount of hoGrid to iSize
                If (iSize = 0) Begin
                    Send Info_Box "No items to process!" 
                    Procedure_Return
                End
                Send SelectAll of hoGrid   
                Get SelectedItems of hoGrid to asFunctions
                Move (SortArray(asFunctions)) to asFunctions             
                Get psExpFileJson of ghoApplication to sFileName
                Get ParseFolderName sFileName to sFolder
                Get vFolderExists sFolder to bExists
                If (bExists = False) Begin
                    Send Info_Box ("The folder:\n" * String(sFolder) * "\ndoesn't exist. Please adjust and try again.")
                    Procedure_Return
                End
                
                // Main Export function:
                Get ExportFile of ghoImportExportFunctions asFunctions sFileName to bOK

                If (bOK = True) Begin
                    Send Info_Box (String(iSize) * "selected function(s) was successfully exported to the Export/Import file:\n" + sFileName)
                End 
                Else Begin
                    Send Info_Box "The export of the selected functions failed."
                End
            End_Procedure
    
            Function IsEnabled Returns Boolean
                Integer iSize
                Handle hoGrid
                Delegate Get phoSelection_grd to hoGrid
                Get ItemCount of hoGrid to iSize
                Function_Return (iSize <> 0)
            End_Function
        
        End_Object   

        Object oViewExportFile_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 58 564
            Set Label to "View Json File"
            Set psToolTip to "View the Json file with the associated program."
            Set psImage to "ViewJson.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                Boolean bExists
                String sFileName sPath

                Get Value of oExportFileName_fm to sFileName
                Get ParseFolderName sFileName   to sPath
                Get ParseFileName sFileName     to sFileName
                
                File_Exist (sPath + sFileName) bExists
                If (bExists = True) Begin
                    Send vShellExecute "open" sFileName sPath ""
                End 
                Else Begin
                    Send Info_Box ("Export file not found:" * (sPath + sFileName))
                End                   
            End_Procedure
    
            Function IsEnabled Returns Boolean
                String sPath sFileName 
                Boolean bExists
                Get Value of oExportFileName_fm to sFileName
                File_Exist sFileName bExists
                Function_Return  (bExists = True)
            End_Function
        
        End_Object 

        Object oOpenContainingFolder_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 88 564
            Set Label to "Containing Folder"
            Set psToolTip to "Open Containing Folder"
            Set psImage to "ActionOpenContainingFolder.ico"
            Set piImageSize to 32
            Set MultiLineState to True

            Procedure OnClick
                String sPath sFile

                Get psHome of (phoWorkspace(ghoApplication)) to sPath
                Move CS_ImpExpFileJson to sFile

                // We want to have that file to be selected in Windows Explorer
                If (sFile <> "") Begin
                    Move ("/select, " + sFile) to sPath
                End
                Send vShellExecute "open" "explorer.exe" sPath ""
            End_Procedure

            Function IsEnabled Returns Boolean
                String sPath sFile
                Boolean bExists
                Get psHome of (phoWorkspace(ghoApplication)) to sPath
                Get vFolderFormat sPath to sPath
                Move CS_ImpExpFileJson to sFile
                Get vFilePathExists (sPath + sFile) to bExists
                Function_Return (bExists = True)
            End_Function

        End_Object

        Object oExportFileName_fm is a Form
            Set Size to 14 360
            Set Location to 127 59
            Set Label to "Json export file:"
            Set Label_Col_Offset to 0
            Set Label_Justification_Mode to JMode_Top
            Set psToolTip to "Press [F4] to display the Open dialog to select an export file."
            Set Label_Row_Offset to 1 
            
            Procedure Prompt
                String sPath sFileName
                String[] asSelectedFiles
                Handle hoOpen 
                Integer iSize 
                Boolean bOpen
                
                Get Create (RefClass(OpenDialog)) to hoOpen
                Get psHome of (phoWorkspace(ghoApplication)) to sPath
                Set Initial_Folder of hoOpen to sPath       
                Set MultiSelect_State of hoOpen to False   
                Set Dialog_Caption of hoOpen to "Select a refactor export file:"
                Set Filter_String of hoOpen to "DFRefactor Export Files (.json)|*.json;|All Files|*.*" 
                Set ShowFileTitle_State of hoOpen to True
                Set File_Title of hoOpen to CS_ImpExpFileJson 
                Set FileMustExist_State of hoOpen to True
                Get Show_Dialog of hoOpen to bOpen
                If (bOpen = True) Begin 
                    Get Selected_Files of hoOpen to asSelectedFiles
                End
                Send Destroy of hoOpen  
                Move (SizeOfArray(asSelectedFiles)) to iSize 
                If (iSize = 0) Begin
                    Function_Return False
                End                      
                Move asSelectedFiles[0] to sFileName
                Set Value to sFileName
                Set psExpFileJson of ghoApplication to sFileName
            End_Procedure
            
            Procedure Activating 
                String sPath sFileName

                Get psExpFileJson of ghoApplication to sFileName  
                Get ExtractFilePath sFileName to sPath
                If (sPath = "") Begin
                    Get psHome of (phoWorkspace(ghoApplication)) to sPath
                    Get vFolderFormat sPath to sPath   
                    Move (CS_ExportJsonFile + ".json") to sFileName
                    Move (sPath + String(sFileName)) to sFileName  
                End
                Set Value to sFileName
            End_Procedure

            Procedure Exiting Handle hoDestination Returns Integer
                Integer iRetVal
                String sFileName
                
                Forward Get msg_Exiting hoDestination to iRetVal
                Get Value to sFileName
                Set psExpFileJson of ghoApplication to sFileName
                Procedure_Return iRetVal
            End_Procedure
            
            On_Key kPrompt Send Prompt
        End_Object

        Object oSelectExportFile_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 122 425
            Set Label to "Select File"  
            Set psToolTip to "Select Json file to export"
            Set psImage to "ActionOpen.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                Send Prompt of oExportFileName_fm    
            End_Procedure
        
        End_Object

    End_Object

    Object oImport_grp is a cRDCDbHeaderGroup
        Set Size to 65 637
        Set Location to 297 8
        Set Label to "Import" 
        Set psNote to "Import Functions from Json."
        Set psToolTip to ("Import function data to the Functions table, function code to:" * String(CS_FunctionLibraryFile) * "and Unit testing to:" * String(CS_UnitTestsFile) + ", from Json file:" * String(CS_ImpExpFileJson))
        Set psImage to "Import.ico"
        Set peAnchors to anNone

        Object oImportFileName_fm is a Form
            Set Size to 14 360
            Set Location to 37 59
            Set Label to "Json import file:"
            Set Label_Col_Offset to 0
            Set Label_Justification_Mode to JMode_Top
            Set psToolTip to "Press [F4] to display the Open dialog and select an import file."
            Set Label_Row_Offset to 1
            
            Procedure Prompt
                String sPath
                String[] asSelectedFiles
                Handle hoOpen 
                Integer iSize 
                Boolean bOpen
                
                Get Create (RefClass(OpenDialog)) to hoOpen
                Get psHome of (phoWorkspace(ghoApplication)) to sPath
                Set Initial_Folder of hoOpen to sPath       
                Set MultiSelect_State of hoOpen to False   
                Set Dialog_Caption of hoOpen to "Select a DFRefactor export/import file:"
                Set Filter_String of hoOpen to "DFRefactor Import Files (.json)|*.json;|All Files|*.*" 
                Set ShowFileTitle_State of hoOpen to True
                Set FileMustExist_State of hoOpen to True
                Get Show_Dialog of hoOpen to bOpen
                If (bOpen = True) Begin 
                    Get Selected_Files of hoOpen to asSelectedFiles
                End
                Send Destroy of hoOpen  
                Move (SizeOfArray(asSelectedFiles)) to iSize 
                If (iSize = 0) Begin
                    Function_Return False
                End                      
                Set Value to asSelectedFiles[0]
            End_Procedure
            
            Procedure Activating 
                String sPath sFileName

                Get psImpFileJson of ghoApplication to sFileName  
                Get ExtractFilePath sFileName to sPath
                If (sPath = "") Begin
                    Get psHome of (phoWorkspace(ghoApplication)) to sPath
                    Get vFolderFormat sPath to sPath
                    Move (CS_ImportJsonFile + ".json") to sFileName
                    Move (sPath + String(sFileName)) to sFileName  
                End
                Set Value to sFileName
            End_Procedure

            Procedure Exiting Handle hoDestination Returns Integer
                Integer iRetVal
                String sFileName
                
                Forward Get msg_Exiting hoDestination to iRetVal
                Get Value to sFileName
                Set psImpFileJson of ghoApplication to sFileName
                Procedure_Return iRetVal
            End_Procedure
            
            On_Key kPrompt Send Prompt
        End_Object

        Object oSelectFile_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 32 425
            Set Label to "Select File"  
            Set psToolTip to "Select Json file to import"
            Set psImage to "ActionOpen.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                Send Prompt of oImportFileName_fm    
            End_Procedure
        
        End_Object

        Object oImport_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 32 564
            Set Label to "Import Data"
            Set psToolTip to "Imports data from the selected DFRefactor Json import-file."
            Set psImage to "JsonFile.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                String sFileName
                Integer iSize iErrors iRetval 
                Boolean bExists
                
                Get YesNo_Box ("The Json import will make changes to your" * CS_FunctionLibraryFile * "and" * CS_UnitTestsFile * "files, but a backup copy will first be created in the" * CS_ImportBackupFolder * "folder.\n\nBe sure to Save any changes in the Studio before you commence!\nContinue?") to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return
                End
                Get Value of oImportFileName_fm to sFileName
                Get vFilePathExists sFileName to bExists
                If (bExists = False) Begin
                    Send Info_Box ("The file:\n" * String(sFileName) * "\ndoesn't exist. Please adjust and try again.")
                    Procedure_Return    
                End 
                
                // Main Import function:
                Get ImportFile of ghoImportExportFunctions sFileName (&iSize) to iErrors
    
                If (iErrors = 0) Begin
                    Send Info_Box (String(iSize + 1) * "Records in the 'Functions' data table was successfully updated/added.\n\nCode was updated/added for these files:\n" + "- AppSrc\" + CS_FunctionLibraryFile * "and\n" + "- AppSrc\" + CS_UnitTestsFile)
                End 
                Else Begin
                    Send Info_Box ("The import failed with:" * String(iErrors) * "errors")
                End
            End_Procedure
    
            Function IsEnabled Returns Boolean
                String sFileName 
                Boolean bExists
                
                Get Value of oImportFileName_fm to sFileName
                File_Exist sFileName bExists
                Function_Return (bExists = True)
            End_Function
        
        End_Object 

        Object oViewImportFile_btn is a cRDCButton
            Set Size to 24 66
            Set Location to 32 493
            Set Label to "View Json File"
            Set psToolTip to "View the Json file with the associated program."
            Set psImage to "ViewJson.ico"
            Set piImageSize to 32
            Set MultiLineState to True
        
            Procedure OnClick
                String sPath sFileName
                Get Value of oImportFileName_fm to sFileName
                Get ParseFolderName sFileName to sPath
                Get ParseFileName sFileName   to sFileName
                Send vShellExecute "open" sFileName sPath ""
            End_Procedure
    
            Function IsEnabled Returns Boolean
                String sFileName 
                Boolean bExists
                
                Get Value of oImportFileName_fm to sFileName
                File_Exist sFileName bExists
                Function_Return (bExists = True)
            End_Function
                
        End_Object 
        
    End_Object

End_Object
