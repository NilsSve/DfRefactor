// DeprecatedCommands.inc
//
// Spliced into cBaseFuncLib._CreateDeprecatedCommandsArray by #Include - it has no meaning on
// its own. The array it fills, pasRemovedCommands, is merged into pasCommands, which is one of
// the four lists _IsListedWord searches. So a word missing HERE makes the funclib treat that
// word as an ordinary identifier.
//
// This is knowledge DFRefactor owns and nothing upstream can confirm: these commands were
// REMOVED from DataFlex without leaving a compiler warning behind. Checked 2026-08-04 - of a
// 28-entry sample, the DF25 install declares only three of them obsolete, and says nothing
// about Indicate or Indicator. There is no catalogue to harvest, so the list is curated.
//
// ONE ENTRY PER LINE, on purpose. This was a single comma-separated literal broken across nine
// ";" continuations, and DataFlex keeps the leading whitespace of a continued line - so the
// first entry after each continuation carried its indentation and could never match the exact
// SearchArray lookup. Nine of seventy-five were silently dead: enterend, format, outclose,
// screen_optimize, dfbeginheader, dfheaderwrap, dfwritebmp, report_breaks, set_file_owner.
// One line per word makes that class of defect structurally impossible.

    Send _AddListWord (&asRemovedCommands) "accept"
    Send _AddListWord (&asRemovedCommands) "backfield"
    Send _AddListWord (&asRemovedCommands) "calc"
    Send _AddListWord (&asRemovedCommands) "clear_option"
    Send _AddListWord (&asRemovedCommands) "compiler_desktop_method_warnings"
    Send _AddListWord (&asRemovedCommands) "compute_screen_crc"
    Send _AddListWord (&asRemovedCommands) "dfbeginheader"
    Send _AddListWord (&asRemovedCommands) "dfbottommargin"
    Send _AddListWord (&asRemovedCommands) "dfendheader"
    Send _AddListWord (&asRemovedCommands) "dffont"
    Send _AddListWord (&asRemovedCommands) "dffontsize"
    Send _AddListWord (&asRemovedCommands) "dfheaderframe"
    Send _AddListWord (&asRemovedCommands) "dfheaderlinecheck"
    Send _AddListWord (&asRemovedCommands) "dfheadermargin"
    Send _AddListWord (&asRemovedCommands) "dfheaderpos"
    Send _AddListWord (&asRemovedCommands) "dfheaderwrap"
    Send _AddListWord (&asRemovedCommands) "dfleftmargin"
    Send _AddListWord (&asRemovedCommands) "dflinecheck"
    Send _AddListWord (&asRemovedCommands) "dfrightmargin"
    Send _AddListWord (&asRemovedCommands) "dfsetmargins"
    Send _AddListWord (&asRemovedCommands) "dftopmargin"
    Send _AddListWord (&asRemovedCommands) "dfwrite"
    Send _AddListWord (&asRemovedCommands) "dfwritebmp"
    Send _AddListWord (&asRemovedCommands) "dfwriteellip"
    Send _AddListWord (&asRemovedCommands) "dfwriteline"
    Send _AddListWord (&asRemovedCommands) "dfwriteln"
    Send _AddListWord (&asRemovedCommands) "dfwritelnpos"
    Send _AddListWord (&asRemovedCommands) "dfwritepos"
    Send _AddListWord (&asRemovedCommands) "dfwriterect"
    Send _AddListWord (&asRemovedCommands) "dfwritexyline"
    Send _AddListWord (&asRemovedCommands) "endgroup"
    Send _AddListWord (&asRemovedCommands) "entagain"
    Send _AddListWord (&asRemovedCommands) "entdisplay"
    Send _AddListWord (&asRemovedCommands) "enter"
    Send _AddListWord (&asRemovedCommands) "enterend"
    Send _AddListWord (&asRemovedCommands) "entergroup"
    Send _AddListWord (&asRemovedCommands) "entermode"
    Send _AddListWord (&asRemovedCommands) "entfind"
    Send _AddListWord (&asRemovedCommands) "entry"
    Send _AddListWord (&asRemovedCommands) "entsfind"
    Send _AddListWord (&asRemovedCommands) "entupdate"
    Send _AddListWord (&asRemovedCommands) "file$mode"
    Send _AddListWord (&asRemovedCommands) "find$page"
    Send _AddListWord (&asRemovedCommands) "format"
    Send _AddListWord (&asRemovedCommands) "format$range"
    Send _AddListWord (&asRemovedCommands) "get_cursor_visible"
    Send _AddListWord (&asRemovedCommands) "get_file_owner"
    Send _AddListWord (&asRemovedCommands) "get_video_mode"
    Send _AddListWord (&asRemovedCommands) "getxy"
    Send _AddListWord (&asRemovedCommands) "help"
    Send _AddListWord (&asRemovedCommands) "indicate"
    Send _AddListWord (&asRemovedCommands) "indicator"
    Send _AddListWord (&asRemovedCommands) "inherit_screen"
    Send _AddListWord (&asRemovedCommands) "inkey"
    Send _AddListWord (&asRemovedCommands) "inkey$"
    Send _AddListWord (&asRemovedCommands) "moveint"
    Send _AddListWord (&asRemovedCommands) "movenum"
    Send _AddListWord (&asRemovedCommands) "movereal"
    Send _AddListWord (&asRemovedCommands) "movestr"
    Send _AddListWord (&asRemovedCommands) "os$call"
    Send _AddListWord (&asRemovedCommands) "outclose"
    Send _AddListWord (&asRemovedCommands) "outfile"
    Send _AddListWord (&asRemovedCommands) "page"
    Send _AddListWord (&asRemovedCommands) "report"
    Send _AddListWord (&asRemovedCommands) "report_breaks"
    Send _AddListWord (&asRemovedCommands) "report_data_set"
    Send _AddListWord (&asRemovedCommands) "report_index"
    Send _AddListWord (&asRemovedCommands) "report_main_file"
    Send _AddListWord (&asRemovedCommands) "reportend"
    Send _AddListWord (&asRemovedCommands) "screen_optimize"
    Send _AddListWord (&asRemovedCommands) "section"
    Send _AddListWord (&asRemovedCommands) "set_cursor_visible"
    Send _AddListWord (&asRemovedCommands) "set_file_owner"
    Send _AddListWord (&asRemovedCommands) "set_option"
    Send _AddListWord (&asRemovedCommands) "set_video_mode"
    Send _AddListWord (&asRemovedCommands) "setchange"
    Send _AddListWord (&asRemovedCommands) "sub_page"
