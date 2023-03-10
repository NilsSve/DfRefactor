// TH3ToolPanes.inc
// Created by Sergey V Natarov (senatc@postman.ru) on 09/03/2017 @ 11:40
//

Use Flexml.pkg
Use cCJToolPanel.pkg
Use Tools\TH3Workspace.pkg

Struct tDFCompileOutput
    String  sFile
    Integer iLine
End_Struct

Struct tDFClassList
  String  sClassName
  String  sImage
  String  sPackage
  String  sLibraryID
End_Struct

Struct tDFClassGroup
    String          sName
    tDFClassList[]  ltDFClassList
End_Struct

Use Tools\TH3ToolPane.dg
Use Tools\TH3OutputPane.dg

//@ RRS Removed
//Procedure Add_Tool_Pane Handle hoCmdBars Handle hoTool String sTitle Integer iLocation Integer bVisible Integer ByRef lhoPane Integer iWidth Integer iHeight
//    Variant vToolPane vCommandBars
//    Handle  hoToolPane
//    Handle  hWnd
//    Get ComAddDialogBar     of hoCmdBars sTitle iLocation         to vToolPane
//    Get Create              of hoCmdBars (RefClass(cTHCJDialogBar)) to hoToolPane
//    //
//    If (hoToolPane) Begin
//        Set Name            of hoToolPane   to ("o"+sTitle+"Pane") // help to ID the pane in the debugger
//        Set pvComObject     of hoToolPane   to vToolPane
//        Set phoChildObject  of hoToolPane   to hoTool
//        Get Window_Handle   of hoTool       to hWnd
//        Set ComChildHandle  of hoToolPane   to hWnd
//        Set ComVisible      of hoToolPane   to bVisible
//        Send ComSetSize     of hoToolPane   iWidth iHeight
//        Move hoToolPane     to lhoPane
//    End
//End_Procedure

//@ RRS Removed
//Procedure mCreateToolPanes Handle hoCmdBars
//    Send Add_Tool_Pane hoCmdBars oToolPane      "Tools"    xtpBarRight  (pbToolsPaneVisible(ghoEditorProperties))    (&ghoToolsPane)   250 500
//    Send Add_Tool_Pane hoCmdBars oOutputPane    "Output"   xtpBarBottom (pbOutputPaneVisible(ghoEditorProperties))   (&ghoOutputPane)  500 150
//End_Procedure


