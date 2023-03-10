// The Hammer.h
#IFDEF DFERR_COMP_NEED_DF19_1_MINIMUM
#ELSE
  #REPLACE DFERR_COMP_NEED_DF19_1_MINIMUM    |CI14329
#ENDIF

#IF (!@ < 191)
  #ERROR DFERR_COMP_NEED_DF19_1_MINIMUM YOU NEED AT MINIMUM DATAFLEX19_1 IN ORDER TO COMPILE THEHAMMER4
#ENDIF

// The Hammer Name & Version
Define CTH_Project_Name     for "KURANT Project"
Define CTH_Programm_Name    for "The Hammer"
Define CTH_Version_No       for "4.0"

// For a better readable code.
Define CM_NewFileName       For "Untitled"
Define TO_EDIT              For True
Define TO_VIEW              For False

Global_Variable String gsCurrentProgramFile     255
Global_Variable String gsCurrentCommandLinePara 255
Global_Variable Integer ghoFileTabs             // Define a global integer for the file-tab window 03.03.2003 BP
Global_Variable Integer ghoElementsTree


// Constants for the AppToolBarItems.
Enum_List
    Define TBItem_New       For 0
    Define TBItem_Open
    Define TBItem_Open_Pkg
    Define TBItem_Open_DD
    Define TBItem_Save
    Define TBItem_SaveAll
    Define TBItem_Print
    Define TBItem_Cut
    Define TBItem_Copy
    Define TBItem_Paste
    Define TBItem_Undo
    Define TBItem_Redo
    Define TBItem_Find
    Define TBItem_Replace
    Define TBItem_Compile
    Define TBItem_Run
    Define TBItem_Debug
    Define TBItem_Execute
    Define TBItem_Todo
End_Enum_List

Define WM_MDIACTIVATE For |CI$0222
