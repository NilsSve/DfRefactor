// C:\Projects\DF18\DfRefactor\AppSrc\FunctionExportImport.vw
// Functions Export/Import
//

Use DFClient.pkg
Use DFEntry.pkg
Use oExportImportFunctions.pkg
Use File_dlg.pkg

Use cFunctionsDataDictionary.dd
Use Windows.pkg

ACTIVATE_VIEW Activate_oFunctionsExportImport FOR oFunctionsExportImport
Object oFunctionsExportImport is a dbView
    Set Location to 5 5
    Set Size to 292 589
    Set Label to "Export/Import"
    Set Border_Style to Border_Thick
    Set pbAutoActivate to True   
    
    Property Handle phoSelection_lst

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
                Handle hoList  
                Integer iID
                
                Delegate Get phoSelection_lst to hoList    
                Get Field_Current_Value of oFunctions_DD Field FunctionsA.ID to iID
                If (iID <> 0) Begin
                    Send Add_Item of hoList msg_None iID
                    Send OnChange of hoList
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
                Handle hoList  
                Integer iItem iCount
                
                Delegate Get phoSelection_lst to hoList    
                Get Item_Count of hoList to iCount
                If (iCount = 0) Begin
                    Procedure_Return
                End
                Get Current_Item of hoList to iItem
                Send Delete_Item of hoList iItem 
            End_Procedure
            
        End_Object

        Object oAddAll_btn is a Button
            Set Size to 14 75
            Set Location to 75 320
            Set Label to "Add All >>"
        
            Procedure OnClick
                Handle hoList  
                Integer iID
                
                Delegate Get phoSelection_lst to hoList    
                Send Delete_Data of hoList
                Clear FunctionsA
                Repeat
                    Find gt FunctionsA.ID 
                    If (Found = True) Begin
                        Send Add_Item of hoList msg_None FunctionsA.ID
                    End
                Until (Found = False)
                Send OnChange of hoList
            End_Procedure
        
        End_Object

        Object oRemoveAll_btn is a Button
            Set Size to 14 75
            Set Location to 92 319
            Set Label to "<< Remove All"
        
            Procedure OnClick
                Handle hoList  
                Delegate Get phoSelection_lst to hoList    
                Send Delete_Data of hoList
                Send OnChange of hoList
            End_Procedure
                
        End_Object 
        
        Object oSelection_lst is a List
            Set Size to 94 75
            Set Location to 31 405
            Set peAnchors to anNone
            Set Label to "Selected Function ID's"
            Set Label_Justification_Mode to JMode_Top
            Set Label_Col_Offset to 0
            Set Label_Row_Offset to 1 
            Delegate Set phoSelection_lst to Self  
            
            Procedure DeleteID
                Send DeleteSelectedItem of oRemoveFromList_btn 
            End_Procedure   
            
            Procedure OnChange
                Integer iCount
                Get Item_Count to iCount
                Set Value of oCountSelection_fm to iCount
            End_Procedure 
            
            Procedure Delete_Item Integer iItem
                Forward Send Delete_Item iItem 
                Send OnChange       
                If (iItem > 0) Begin
                    Set Current_Item to iItem
                End
            End_Procedure
            
            On_Key kDelete_Character Send DeleteID
        End_Object

        Object oCountSelection_fm is a Form
            Set Size to 12 18
            Set Location to 121 405
            Set Label to "Selections:"
            Set Label_Justification_Mode to JMode_Right
            Set Label_Col_Offset to 0
            Set Enabled_State to False
        End_Object
        
        Object oExport_btn is a Button
            Set Size to 14 75
            Set Location to 32 486
            Set Label to "Export Function Data"
            Set psToolTip to "Export selected function ID's data records *and* the corresponding function text(s) from the cRefactorFunctionLibrary repository class."
            Set peAnchors to anNone
        
            Procedure OnClick
                Handle hoList  
                Integer iItem iSize iCount iID iRetval
                Integer[] aiFunctions 
                Boolean bOK  
                String sFileName
                
                Delegate Get phoSelection_lst to hoList    
                Get Item_Count of hoList to iSize
                If (iSize = 0) Begin
                    Send Info_Box "No items to process!" 
                    Procedure_Return
                End
                Decrement iSize
                For iCount from 0 to iSize
                    Get Value of hoList Item iCount to iID
                    Move iID to aiFunctions[SizeOfArray(aiFunctions)]    
                Loop  
                
                // Main Export function:
                Get ExportFile of ghoImportExportFunctions aiFunctions (&sFileName) to bOK
    
                If (bOK = True) Begin
                    Get YesNo_Box (String(iSize + 1) * "selected function(s) was successfully exported to the ini-file:\n" + sFileName + "\n\nDo you want to locate the file in Windows Explorer?") to iRetval
                    If (iRetval = MBR_Yes) Begin
                        // We want to have that file to be selected in Windows Explorer
                        Move ("/select, " + sFileName) to sFileName
                        Send vShellExecute "open" "explorer.exe" sFileName ""
                    End
                End 
                Else Begin
                    Send Info_Box "The export of the selected functions failed."
                End
    
            End_Procedure
    
            Object oExportIdleHandler is a cIdleHandler
                Procedure OnIdle
                    Handle hoList            
                    Integer iSize
                    
                    Delegate Get phoSelection_lst to hoList
                    Get Item_Count of hoList to iSize
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
            Set psToolTip to "Import from a selected import-file."
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

