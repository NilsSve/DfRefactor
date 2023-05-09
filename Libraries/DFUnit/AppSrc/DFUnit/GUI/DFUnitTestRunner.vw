Use DFClient.pkg
Use cUnitCommandBar.pkg
Use DFUnit\Reporting\ReporterManager.pkg
Use DFUnit\Reporting\Reporters\UIListReporter.pkg

{ Visibility=Private }
Define DFUNIT_UI_WINDOW_HEIGHT for 630 //255
{ Visibility=Private }
Define DFUNIT_UI_WINDOW_WIDTH for 425

{ Visibility=Private }
Class cDFUnitUIRunButton is a Button                
    Procedure OnClick
        Send ManualRunTests of ghoTestApplication
    End_Procedure
End_Class

Class cDFUnitUICloseButton is a Button                
    Procedure OnClick
        Send Exit_Application
    End_Procedure
End_Class

{ Visibility=Private }
Class cDFUnitUIPanel is a Panel
    
    Procedure Construct_Object
        Forward Send Construct_Object
        
        { Visibility=Private }
        Property Handle poMainView
        
        Set Label to "DFUnit TestRunner"
        Set Size to DFUNIT_UI_WINDOW_HEIGHT DFUNIT_UI_WINDOW_WIDTH
        Set piMinSize to DFUNIT_UI_WINDOW_HEIGHT (DFUNIT_UI_WINDOW_WIDTH - 100)
//        Set piMaxSize to DFUNIT_UI_WINDOW_HEIGHT DFUNIT_UI_WINDOW_WIDTH
//        Set Locate_Mode to Center_On_Screen
        Set StatusBar_State to True
        Set Border_Style to Border_Thick 
        Set peAnchors to anAll
        
//        Object oUnitCommandBar is a cUnitCommandBar
//        End_Object
        
        { Visibility=Private }
        Object oClientArea is a ClientArea
            { Visibility=Private }
            Object oDFUnitTestRunner_vw is a View
                Set poMainView to oDFUnitTestRunner_vw
        
                Set Size to DFUNIT_UI_WINDOW_HEIGHT DFUNIT_UI_WINDOW_WIDTH
//                Set piMinSize to DFUNIT_UI_WINDOW_HEIGHT DFUNIT_UI_WINDOW_WIDTH
//                Set piMaxSize to DFUNIT_UI_WINDOW_HEIGHT DFUNIT_UI_WINDOW_WIDTH
                Set Location to 0 0
//                Set Label to "DFUnit TestRunner"
                Set Maximize_Icon to False
                Set Minimize_Icon to False
                Set pbSizeToClientArea to False
                Set Sysmenu_Icon to False
                Set Caption_Bar to False
                Set View_Mode to Viewmode_Zoom
                Set Border_Style to Border_None
                
                { Visibility=Private }
                Object oRunTestsButton is a cDFUnitUIRunButton
                    Set Size to 30 85
//                    Set piMinSize to 30 397
                    Set Location to 5 10 // (DFUNIT_UI_WINDOW_HEIGHT - 55) 10 // 198 10
                    Set Label to "Run tests!"
                    Set Form_FontWeight to FW_BOLD 
                    Set psImage to "RunProgram.ico"
                    Set piImageSize to 42
                    Set piImageMarginLeft to 15
//                    Set peAnchors to anBottomLeftRight
                End_Object 
                
                { Visibility=Private }
                Object oClose_btn is a cDFUnitUICloseButton
                    Set Size to 30 70
//                    Set piMinSize to 30 397
                    Set Location to 5 100 
                    Set Label to "Exit"
                    Set Form_FontWeight to FW_BOLD 
                    Set psImage to "ActionExit.ico"
                    Set piImageSize to 36
                    Set piImageMarginLeft to 15
//                    Set peAnchors to anBottomLeftRight
                End_Object 
                
                { Visibility=Private }
                Object oOutputBox is a cDFUnitUIListReporter
                    Set Size to (DFUNIT_UI_WINDOW_HEIGHT - 70) 400 //187 397
                    Set Location to (6 + (Hi(Size(oRunTestsButton)))) 10 //6 10
                    Set peAnchors to anAll
//                    Set piMinSize to 167 390
                End_Object
                Send AddReporter of ghoTestApplication oOutputBox
            
            End_Object
            
        End_Object
        
    End_Procedure
    
    Procedure End_Construct_Object
        Boolean bAutoRunTests
        
        Forward Send End_Construct_Object
        Send Activate_View of (poMainView(Self))
        Delegate Get pbAutoRunTests to bAutoRunTests
        If (bAutoRunTests) Begin
            Send ManualRunTests of ghoTestApplication
        End
    End_Procedure
End_Class