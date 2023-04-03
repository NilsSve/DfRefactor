// C:\Projects\DF18\DfRefactor\AppSrc\FunctionExportImport.vw
// Functions Export/Import
//

Use DFClient.pkg
Use DFEntry.pkg
Use oExportImportFunctions.pkg
Use File_dlg.pkg

Use cFunctionsDataDictionary.dd
Use Windows.pkg
Use cRDCCJSelectionGrid.pkg

ACTIVATE_VIEW Activate_oFunctionsExportImport FOR oFunctionsExportImport
Object oFunctionsExportImport is a dbView
    Set Location to 5 5
    Set Size to 292 589
    Set Label to "Export/Import"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True   
    
    Property Handle phoSelection_lst
    Property Handle phoSelection_grd

    Object oFunctions_DD is a cFunctionsDataDictionary
    End_Object 

    Set Main_DD to oFunctions_DD
    Set Server  to oFunctions_DD

    Object oInfo_tb is a TextBox
        Set Auto_Size_State to False
        Set Size to 67 420
        Set Location to 16 66
        Set Justification_Mode to JMode_Left
        Set Label to "Info text"
        
        Procedure Page Integer iPageObject  
            String sVal
            Move "This view is designed so that you can Export/Import refactoring data and source code from one machine to another." to sval
            Append sVal "\n\nSelect the functions to be exported. The data from the Functions table together with the corresponding function code text "
            Append sVal "from the cRefactorFunctionLibrary class will be written to a file that can be copied/send to another machine for import." 
            Append sVal "\n\nNote that each function that has code in the cRefactorFunctionLibrary class *must* also be registrered under the 'Function Maintenance' tab-page."
            Move (Replaces("\n", sVal, (Character(13)))) to sVal
            Set Label to sVal
            Forward Send Page iPageObject
        End_Procedure
        
    End_Object

    Object oExport_grp is a dbGroup
        Set Size to 137 572
        Set Location to 85 8
        Set Label to "Export"

        Object oFunctionsID is a dbForm
            Entry_Item Functions.ID
            Set Size to 12 34
            Set Location to 16 59
            Set Label to "ID"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0
            Set Prompt_Button_Mode to PB_PromptOn
        End_Object 
      
        Object oFunctionsFunction_Name is a dbForm
            Entry_Item Functions.Function_Name
            Set Size to 12 250
            Set Location to 30 59
            Set Label to "Name"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0  
        End_Object 
     
        Object oFunctionsFunction_Description is a dbForm
            Entry_Item Functions.Function_Description
            Set Size to 12 250
            Set Location to 44 59
            Set Label to "Description"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0
        End_Object 
        
        Object oFunctionsFunction_Help is a dbForm
            Entry_Item Functions.Function_Help
            Set Size to 12 250
            Set Location to 58 59
            Set Label to "Help Text"
            Set Label_Justification_mode to jMode_right
            Set Label_Col_Offset to 2
            Set Label_row_Offset to 0
        End_Object 
        
        Object oCopyToRight_btn is a Button
            Set Size to 14 75
            Set Location to 32 320
            Set Label to "Copy to Right >>"
        
            Procedure OnClick
                Handle hoGrid  
                Integer iID
                
                Delegate Get phoSelection_grd to hoGrid
                Get Field_Current_Value of oFunctions_DD Field FunctionsA.ID to iID
                If (iID <> 0) Begin
                    Send AddItem of hoGrid iID
                    Send DoSetCheckboxFooterText of hoGrid
                End
            End_Procedure
        
        End_Object
        
        Object oRemoveFromList_btn is a Button
            Set Size to 14 75
            Set Location to 48 319
            Set Label to "<< Remove from list"
        
            Procedure OnClick
                Send DeleteSelectedItem
            End_Procedure
            
            Procedure DeleteSelectedItem    
                Handle hoGrid 
                Integer iItem iCount
                
                Delegate Get phoSelection_grd to hoGrid
                Get ItemCount of hoGrid to iCount
                If (iCount = 0) Begin
                    Procedure_Return
                End
                Send Request_Delete of hoGrid
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
            
        End_Object

        Object oAddAll_btn is a Button
            Set Size to 14 75
            Set Location to 75 320
            Set Label to "Add All >>"
        
            Procedure OnClick
                Handle hoGrid 
                Integer iID
                
                Delegate Get phoSelection_grd to hoGrid
                Send Request_Clear_All of hoGrid
                Clear FunctionsA
                Repeat
                    Find gt FunctionsA.ID 
                    If (Found = True) Begin
                        Send AddItem of hoGrid FunctionsA.ID
                    End
                Until (Found = False)
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
        
        End_Object

        Object oRemoveAll_btn is a Button
            Set Size to 14 75
            Set Location to 92 319
            Set Label to "<< Remove All"
        
            Procedure OnClick
                Handle hoGrid 
                Delegate Get phoSelection_grd to hoGrid
                Send Request_Clear_All of hoGrid
                Send DoSetCheckboxFooterText of hoGrid
            End_Procedure
                
        End_Object 
        
        Object oSelection_grd is a cRDCCJSelectionGrid
            Set Size to 106 75
            Set Location to 21 405
            Set pbShowInvertSelectionsMenuItem to False
            Delegate Set phoSelection_grd to Self  

            Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
            End_Object

            Object oFunctionID_Col is a cCJGridColumn
                Set piWidth to 105
                Set psCaption to "Selected ID's"    
                Set phoData_Col to Self
            End_Object
            
            Procedure ToggleCurrentItem
            End_Procedure 
            
            Procedure LoadData
                Set pbVisible of (phoCheckbox_Col(Self)) to False 
                Set piWidth of (phoCheckbox_Col(Self)) to 0
            End_Procedure
            
            Procedure AddItem String sDataValue
                Handle hoDataSource
                tDataSourceRow[] TheData
                tsSearchResult[] asFolderArray
                Integer iSize iData_Col iCheckbox_Col
        
                If (not(IsComObjectCreated(Self))) Begin
                    Procedure_Return
                End
        
                Get piColumnId of (phoData_Col(Self)) to iData_Col
                Get piColumnId of (phoCheckbox_Col(Self)) to iCheckbox_Col
                Get phoDataSource to hoDataSource
                Get DataSource of hoDataSource to TheData
                Move (SizeOfArray(TheData)) to iSize
                Move sDataValue to TheData[iSize].sValue[iData_Col]
                Move False      to TheData[iSize].sValue[iCheckbox_Col]

                Send DoSetCheckboxFooterText
                Send ReInitializeData TheData False
                Send MoveToLastRow
            End_Procedure

            Procedure DoSetCheckboxFooterText
                Integer iCol iItems
                Handle hoCol hoCheckbox_Col
        
                If ((phoData_Col(Self) = 0)) Begin
                    Move 1 to iCol
                End
                Else Begin
                    Get piColumnId of (phoData_Col(Self)) to iCol
                End
                Get ItemCount to iItems
                Get ColumnObject iCol to hoCol
                Set psFooterText of hoCol  to ("Count:" * String(iItems))
            End_Procedure

        End_Object
        
        Object oExport_btn is a Button
            Set Size to 14 75
            Set Location to 32 491
            Set Label to "Export Function Data"
            Set psToolTip to "Export selected function ID's data records *and* the corresponding function text(s) from the cRefactorFunctionLibrary repository class."
            Set peAnchors to anNone
        
            Procedure OnClick
                Handle hoGrid 
                Integer iItem iSize iCount iID iRetval
                String[] asFunctions 
                Boolean bOK  
                String sFileName
                
                Delegate Get phoSelection_grd to hoGrid
                Get ItemCount of hoGrid to iSize
                If (iSize = 0) Begin
                    Send Info_Box "No items to process!" 
                    Procedure_Return
                End
                Send SelectAll of hoGrid   
                Get SelectedItems of hoGrid to asFunctions
                
                // Main Export function:
                Get ExportFile of ghoImportExportFunctions asFunctions (&sFileName) to bOK

                If (bOK = True) Begin
                    Send Info_Box (String(iSize) * "selected function(s) was successfully exported to the DFRefactor Export/Import file:\n" + sFileName)
                End 
                Else Begin
                    Send Info_Box "The export of the selected functions failed."
                End
            End_Procedure
    
            Object oExportIdleHandler is a cIdleHandler
                Procedure OnIdle
                    Handle hoGrid           
                    Integer iSize
                    Delegate Get phoSelection_grd to hoGrid
                    Get ItemCount of hoGrid to iSize
                    Delegate Set Enabled_State to (iSize <> 0)
                End_Procedure
            End_Object
        
            Procedure Page Integer iPageObject
               Forward Send Page iPageObject
               Set pbEnabled of oExportIdleHandler to True
            End_Procedure
        
            Procedure Deactivating
               Set pbEnabled of oExportIdleHandler to False
               Forward Send DeActivating 
            End_Procedure    
        
        End_Object   

        Object oViewExportFile_btn is a Button
            Set Size to 14 75
            Set Location to 48 491
            Set Label to "View Export File"
            Set psToolTip to "View the file with the associtated program."
            Set peAnchors to anNone
        
            Procedure OnClick
                Boolean bExists
                String sFileName sPath

                Get psHome of (phoWorkspace(ghoApplication)) to sPath
                Get vFolderFormat sPath to sPath
                Move CS_ImpExpFileJson to sFileName
                File_Exist (sPath + sFileName) bExists
                If (bExists = True) Begin
                    Send vShellExecute "open" sFileName sPath ""
                End 
                Else Begin
                    Send Info_Box ("Export file not found:" * (sPath + sFileName))
                End                   
            End_Procedure
    
            Object oExportIdleHandler is a cIdleHandler
                Procedure OnIdle
                    String sPath sFileName 
                    Boolean bExists
                    Get psHome of (phoWorkspace(ghoApplication)) to sPath
                    Get vFolderFormat sPath to sPath
                    Move (sPath + CS_ImpExpFileJson) to sFileName
                    File_Exist sFileName bExists
                    Delegate Set Enabled_State to (bExists = True)
                End_Procedure                                    
                
            End_Object
        
            Procedure Page Integer iPageObject
               Forward Send Page iPageObject
               Set pbEnabled of oExportIdleHandler to True
            End_Procedure
        
            Procedure Deactivating
               Set pbEnabled of oExportIdleHandler to False
               Forward Send DeActivating 
            End_Procedure    
        
        End_Object 

    End_Object

    Object oImport_grp is a dbGroup
        Set Size to 54 572
        Set Location to 230 8
        Set Label to "Import"

        Object oImportFileName_fm is a Form
            Set Size to 12 393
            Set Location to 19 90
            Set Label to "Select import file name"
            Set Label_Col_Offset to 2
            Set Label_Justification_Mode to JMode_Right
            Set Prompt_Button_Mode to PB_PromptOn  
            Set psToolTip to "Press [F4] to display the Open dialog and select an import file."
            
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
                Set Filter_String of hoOpen to "DFRefactor Import Files|*.json;|All Files|*.*" 
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
                Set Value to asSelectedFiles[0]
            End_Procedure             
            
            On_Key kPrompt Send Prompt
        End_Object

        Object oImport_btn is a Button
            Set Size to 14 75
            Set Location to 19 486
            Set Label to "Import Function Data"
            Set psToolTip to "Imports data from the selected DFRefactor import-file."
            Set peAnchors to anNone
        
            Procedure OnClick
                String sFileName
                Integer iSize iErrors iRetval
                
                Get YesNo_Box "The Json import will make changes to your cRefactorFunctionLibrary.pkg file. Be sure to save any changes before you commence! Continue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return
                End
                Get Value of oImportFileName_fm to sFileName
                // Main Import function:
                Get ImportFile of ghoImportExportFunctions sFileName (&iSize) to iErrors
    
                If (iErrors = 0) Begin
                    Send Info_Box (String(iSize + 1) * "Function(s) was successfully updated/added to the Functions data table and code was updated/added for the cRefactorFunctionLibrary.pkg file!")
                End 
                Else Begin
                    Send Info_Box ("The import failed with:" * String(iErrors) * "errors")
                End
            End_Procedure
    
            Object oImportIdleHandler is a cIdleHandler
                Procedure OnIdle
                    Handle hoForm            
                    String sFileName 
                    Boolean bExists
                    
                    Move oImportFileName_fm to hoForm
                    Get Value of hoForm to sFileName
                    File_Exist sFileName bExists
                    Delegate Set Enabled_State to (bExists = True)
                End_Procedure                                    
                
            End_Object
        
            Procedure Page Integer iPageObject
               Forward Send Page iPageObject
               Set pbEnabled of oImportIdleHandler to True
            End_Procedure
        
            Procedure Deactivating
               Set pbEnabled of oImportIdleHandler to False
               Forward Send DeActivating 
            End_Procedure    
        
        End_Object 

        Object oViewImportFile_btn is a Button
            Set Size to 14 75
            Set Location to 36 486
            Set Label to "View Import File"
            Set psToolTip to "View the file with the associtated program."
            Set peAnchors to anNone
        
            Procedure OnClick
                String sPath sFileName
                Get Value of oImportFileName_fm to sFileName
                Get ParseFolderName sFileName to sPath
                Get ParseFileName sFileName   to sFileName
                Send vShellExecute "open" sFileName sPath ""
            End_Procedure
    
            Object oImportIdleHandler is a cIdleHandler
                Procedure OnIdle
                    Handle hoForm            
                    String sFileName 
                    Boolean bExists
                    
                    Move oImportFileName_fm to hoForm
                    Get Value of hoForm to sFileName
                    File_Exist sFileName bExists
                    Delegate Set Enabled_State to (bExists = True)
                End_Procedure                                    
                
            End_Object
        
            Procedure Page Integer iPageObject
               Forward Send Page iPageObject
               Set pbEnabled of oImportIdleHandler to True
            End_Procedure
        
            Procedure Deactivating
               Set pbEnabled of oImportIdleHandler to False
               Forward Send DeActivating 
            End_Procedure    
        
        End_Object 
        
    End_Object

End_Object 

