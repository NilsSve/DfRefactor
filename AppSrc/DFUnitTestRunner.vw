Use DFClient.pkg
Use cUnitCommandBar.pkg
Use DFUnit\Reporting\ReporterManager.pkg
Use DFUnit\Reporting\Reporters\UIListReporter.pkg

Activate_View Activate_DFUnitTestRunner_vw for DFUnitTestRunner_vw
Object DFUnitTestRunner_vw is a View
    Set Size to 545 271
    Set Location to 0 0
    Set Maximize_Icon to True
    Set Minimize_Icon to False
    Set Sysmenu_Icon to False
    Set Border_Style to Border_None
    Set pbAutoActivate to True

    Delegate Set phoTestView to Self
        
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

    Object oClose_btn is a Button
        Set Size to 30 61
        Set Location to 9 195
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
        Set Size to 490 254
        Set Location to 46 13
        Set peAnchors to anAll
        Set Border_Style to Border_Thick

        Delegate Set phoOutputBox to Self
    End_Object

    Procedure ScaleFont Integer iDirection 
    End_Procedure 

    Procedure End_Construct_Object   
        Forward Send End_Construct_Object
    End_Procedure

    On_Key Key_Ctrl+Key_F4 Send None
    On_Key Key_Escape      Send None
End_Object
