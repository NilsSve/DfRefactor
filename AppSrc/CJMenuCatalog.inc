// CJMenuCatalog.inc
//
// Spliced into cBaseFuncLib._CreateCJMenuCatalogArray by #Include - it has no meaning on its own.
//
// WHY THIS EXISTS. The legacy DFCreate_Menu system builds a menu out of `On_Item "<caption>" send
// <Message>` lines. The modern CodeJock command-bar system ships a DEDICATED CLASS for each of those
// standard messages - cCJClearMenuItem already knows how to send Request_Clear, carries its own
// localized caption, and handles its own enable/disable. So converting a standard item is not a
// caption-and-Send translation at all: it is a lookup that replaces the whole item with the class
// the install already provides.
//
// KEYED ON THE MESSAGE, NEVER ON THE CAPTION OR THE FILE NAME. The standard pulldowns arrived as
// copyable include files (File_PM.inc, Navi_PM.inc, Win_PM.inc, Help_PM.inc / HelpA_PM.inc) and
// every workspace then edited its copy: captions get translated, items get commented out, whole
// files get renamed. Measured over the DF18/DF19 trees 2026-08-11: 1,394 DFCreate_Menu blocks in
// .src/.mn/.inc/.pkg/.vw/.dg, and the sampled HelpA_PM.INC copies already disagree with each other.
// The MESSAGE is the one part that cannot drift - Request_Clear is Request_Clear in every copy, in
// every language - so that is the key. Caption text is deliberately NOT part of the match.
//
// THE DATA IS THE INSTALL's, VERBATIM. Every pair below was read out of the shipped packages, not
// guessed: each cCJ* class's own OnExecute is what names its message. Sources are
// cCJStandardMenuItemClasses.pkg, cCJDeoMenuItemClasses.pkg, cCJAboutMenuItem.pkg. The canonical
// TARGET shape - what the Studio itself emits for a new Windows project - is
// Pkg\Config\DefaultCommandBarSystem.tpl; read that before changing what the converter writes.
// If a future release renames a class or repoints a message, this file is the single place that
// changes, and the check is mechanical: grep the class for its Send.
//
// CAPTIONS ARE THE CLASS's JOB. Each class sets its own psCaption from a C_$Caption* constant, which
// is localized with the install. The converter therefore emits NO psCaption for a catalogue hit -
// writing the legacy English caption back over it would DE-localize a menu that the framework was
// about to translate for free. A legacy `Set Status_Help` still becomes psToolTip, since that text
// is the developer's own.
//
// WHAT IS DELIBERATELY ABSENT:
//   - cCJMDIWindowsMenuItem, the "&Window" pulldown. It is a CONTAINER that fills itself at runtime,
//     so it replaces the whole DFCreate_Menu "&Window" block rather than matching any single On_Item.
//     The converter special-cases it; a message key would be wrong.
//   - Toggle_ToolBar. cCJStatusbarMenuItem covers Toggle_StatusBar, but the install ships NO
//     toolbar-toggle counterpart, so that item falls through to a generic cCJMenuItem. (Checked
//     2026-08-11 across every cCJ* class in the install Pkg - it is absent, not merely unfound.)
//   - The grid context-menu items (cCJGridFieldChooserMenuItem, cCJGridFreezeColumnMenuItem,
//     cCJGridRestoreLayoutMenuItem). They belong to a grid, never to a legacy pulldown. Note that
//     cCJGridRestoreLayoutMenuItem also sends RestoreLayout: for a MAIN menu that message means
//     cCJRestoreMenusMenuItem, which is why the grid trio is excluded rather than merged.
//
// ONE ENTRY PER LINE, following DeprecatedCommands.inc and WinAPICatalog.inc - see the first of
// those for the continuation-line defect that convention exists to make impossible.
//
// TO EXTEND: add the legacy message and the class that replaces it. Nothing else needs to change.

    // ---- File pulldown (File_PM.inc): the DEO record actions.
    Send _AddCJMenuItem (&asCJMenu) "Request_Clear"              "cCJClearMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Request_Clear_All"          "cCJClearAllMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Request_Save"               "cCJSaveMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Request_Delete"             "cCJDeleteMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Prompt"                     "cCJPromptMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Zoom"                       "cCJZoomMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Exit_Application"           "cCJExitMenuItem"

    // ---- Find family. Find_GE is the plain "Find"; the rest are its directional siblings.
    Send _AddCJMenuItem (&asCJMenu) "Find_GE"                    "cCJFindMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Find_Next"                  "cCJFindNextMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Find_Previous"              "cCJFindPreviousMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Find_First"                 "cCJFindFirstMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Find_Last"                  "cCJFindLastMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "SuperFind"                  "cCJSuperFindMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "SuperFind_Next"             "cCJSuperFindNextMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "SuperFind_Previous"         "cCJSuperFindPreviousMenuItem"

    // ---- Edit pulldown. NOTE "Delete" is the EDIT delete (cut-buffer), NOT Request_Delete's
    //      record delete - two different messages that both read as "delete" to a human eye.
    Send _AddCJMenuItem (&asCJMenu) "Undo"                       "cCJUndoMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Cut"                        "cCJCutMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Copy"                       "cCJCopyMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Paste"                      "cCJPasteMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Delete"                     "cCJDeleteEditMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Select_All"                 "cCJSelectAllMenuItem"

    // ---- Navigate pulldown (Navi_PM.inc): area and view switching.
    Send _AddCJMenuItem (&asCJMenu) "Switch_Next_Area"           "cCJNextAreaMenu"
    Send _AddCJMenuItem (&asCJMenu) "Switch_Prior_Area"          "cCJPriorAreaMenu"
    Send _AddCJMenuItem (&asCJMenu) "Switch_Next_View"           "cCJNextViewMenu"
    Send _AddCJMenuItem (&asCJMenu) "Switch_Prior_View"          "cCJPriorViewMenu"

    // ---- Window pulldown (Win_PM.inc): the MDI arrangement actions. The window LIST itself is the
    //      cCJMDIWindowsMenuItem container - see the note above.
    Send _AddCJMenuItem (&asCJMenu) "Cascade_Windows"            "cCJCascadeMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Tile_Windows_Horizontal"    "cCJTileHorizontally"
    Send _AddCJMenuItem (&asCJMenu) "Tile_Windows_Vertical"      "cCJTileVertically"
    Send _AddCJMenuItem (&asCJMenu) "Minimize_all_Windows"       "cCJMinimizeWindowsMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Restore_all_Windows"        "cCJRestoreWindowsMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Arrange_Icons"              "cCJArrangeIconsMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Toggle_Auto_Arrange_Icons"  "cCJAutoArrangeIconsMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Toggle_StatusBar"           "cCJStatusbarMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "RestoreLayout"              "cCJRestoreMenusMenuItem"

    // ---- Remembered-defaults family (the DD field defaults sub-menu).
    Send _AddCJMenuItem (&asCJMenu) "DDFieldRemember"            "cCJRememberFieldMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "DDFieldUnRemember"          "cCJUnRememberFieldMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "DDFieldRememberLast"        "cCJRememberLastFieldMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "ClearAllRememberedDefaults" "cCJUnRememberFieldAllMenuItem"

    // ---- Help pulldown (Help_PM.inc / HelpA_PM.inc). The legacy WinHelp entry points
    //      (Help_On_Topic, Extended_Help, File_Help, Keys_Help, Help_For_Help) have no shipped
    //      counterpart and fall through to generic items, so nothing is silently dropped.
    Send _AddCJMenuItem (&asCJMenu) "Help"                       "cCJHelpMenuItem"
    Send _AddCJMenuItem (&asCJMenu) "Activate_About"             "cCJAboutMenuItem"
