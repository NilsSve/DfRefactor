Use DFAllent.pkg
Use mStrConv.pkg
Use mPointer.pkg
Use tWinStructs.pkg
Use cScintilla.h

#IFNDEF ghoEditorProperties
Global_Variable Integer ghoEditorProperties
#ENDIF

Define CS_CR   For (Character(13))
Define CS_CRLF For (Character(13)+Character(10))
Define CS_LF   For (Character(10))


#IFDEF IS$WIN64
Define CMAX_DLL_NAME For SCILEXER64.DLL
#ELSE
Define CMAX_DLL_NAME For SCILEXER32.DLL
#ENDIF


Define NM_SETFOCUS              For -7
Define NM_KILLFOCUS             For -8

Define WM_CONTEXTMENU           For |CI$007B // 0x007B
Define WM_RBUTTONUP             For |CI$0205 // 0x0205

#IFNDEF GET_CREATEWINDOWEX
  External_Function CreateWindowEx     'CreateWindowExA'      User32.dll  DWord e Pointer c Pointer v DWord w DWord x DWord y DWord wi DWord he Handle hP Handle hm Handle hi Pointer cs Returns Handle
#ENDIF
#IFNDEF GET_GetObject
External_Function GetObject          'GetObjectA'           Gdi32.dll   Handle hGdi Integer iSize Pointer pBuff Returns Integer
#ENDIF
#IFNDEF GET_CREATEFONTINDIRECT
  External_Function CreateFontIndirect 'CreateFontIndirectA'  Gdi32.dll   Pointer pLogfont Returns Integer
#ENDIF
External_Function LockWindowUpdate   'LockWindowUpdate'     USer32.dll  Handle hwnd Returns Integer
#IFNDEF GET_REDRAWWINDOW
  External_Function RedrawWindow       'RedrawWindow'         User32.dll  Handle hwnd Pointer pRect Handle hUpdReg Integer iFlags Returns Integer
#ENDIF
External_Function ReplyMessage       'ReplyMessage'         User32.dll  Integer iResult Returns Integer
#IFNDEF GET_GETFOCUS
  External_Function GetFocus           'GetFocus'             User32.dll  Returns Integer
#ENDIF

// File Dropping from e.g WindowsExplorer.
Define WM_DROPFILES              For |CI$0233
External_Function DragAcceptFiles    'DragAcceptFiles'      Shell32.dll Handle hwnd Integer iFlag Returns Integer
External_Function DragQueryFile      'DragQueryFile'        Shell32.dll Handle hDrop Integer iFileIndex Pointer pFileBuff Integer iBuffSize Returns Integer
External_Function DragFinish         'DragFinish'           Shell32.dll Handle hDrop Returns Integer

// CodeTip Support external Function
External_Function CT_DestroyWindow   'DestroyWindow'        User32.dll  Handle hWnd Returns Integer


Define RDW_INVALIDATE          For |CI$0001
Define RDW_INTERNALPAINT       For |CI$0002
Define RDW_ERASE               For |CI$0004

Define RDW_VALIDATE            For |CI$0008
Define RDW_NOINTERNALPAINT     For |CI$0010
Define RDW_NOERASE             For |CI$0020

Define RDW_NOCHILDREN          For |CI$0040
Define RDW_ALLCHILDREN         For |CI$0080

Define RDW_UPDATENOW           For |CI$0100
Define RDW_ERASENOW            For |CI$0200

Define RDW_FRAME               For |CI$0400
Define RDW_NOFRAME             For |CI$0800


Define COLORREF For DWord


// Is a command that allows to put a string into a structure
// Usage: PUT_POINTER sName  pName  "String..."  to sBuff at TYPE.FIELD
//#COMMAND PUT_POINTER R R R "TO" R "AT" R
//    Local_Buffer !1 !2
//    Move !3 To !1
//    GetAddress Of !1    To !2
//    Put !2  To !5 At !7 !8
//#ENDCOMMAND


//
//
//
//



Define LF_FACESIZE          For 32
Define CODEMAXWNDCLASS      For "Scintilla" //"CodeSense" //"CodeMax"

/////////////////////////////////////////////////////////////
//
// Constants
//
//

// maximum size (TCHARs) of text to find or replace
Define CM_MAX_FINDREPL_TEXT          For 100
// maximum MRU size in find and find/replace dialogs
Define CM_FIND_REPLACE_MRU_MAX       For 10
// required buffer size for pszMRUList argument CMSetFindReplaceMRUList() and CMGetFindReplaceMRUList()
Define CM_FIND_REPLACE_MRU_BUFF_SIZE For ( ( CM_MAX_FINDREPL_TEXT + 1 ) * CM_FIND_REPLACE_MRU_MAX )
// maximum number of keystroke macros supported by CodeMax
Define CM_MAX_MACROS                 For 10
// maximum size of command string returned in pszBuff param of CMGetCommandString() if bDescription is FALSE
Define CM_MAX_CMD_STRING             For 50
// maximum size of command string returned in pszBuff param of CMGetCommandString() if bDescription is TRUE
Define CM_MAX_CMD_DESCRIPTION        For 100
// maximum size of a language name set with CMRegisterLanguage
Define CM_MAX_LANGUAGE_NAME          For 30
// maximum tab size (characters)
Define CM_MAX_TABSIZE                For 100
// minimum tab size (characters)
Define CM_MIN_TABSIZE                For 2
// left margin width (pixels)
Define CM_CXLEFTMARGIN               For 24
// SVN // maximum CodeList tooltip text length
Define CM_MAX_CODELIST_TIP			 For 128

/////////////////////////////////////////////////////////////
//
// CMM_SETLINESTYLE style bits
//
//
Define CML_OWNERDRAW      For |CI$1      // Parent window should receive CMN_DRAWLINE notifications
Define CML_NOTIFY_DEL     For |CI$2      // Parent window should receive CMN_DELETELINE notifications


/////////////////////////////////////////////////////////////
//
// Messages - CMM_xxxxxx
// As long as they are listed then they have not yet been migrated to scintilla
// If commented out then it means not in scintilla or it simply works so much different that I have not
// made up my mind on how-to implement or migrate.
//
Define CMM_SETLANGUAGE                For ( WM_USER + 1600 )
Define CMM_GETLANGUAGE                For ( WM_USER + 1601 )
//Define CMM_ENABLECOLORSYNTAX          FOR ( WM_USER + 1610 )
//Define CMM_ISCOLORSYNTAXENABLED       FOR ( WM_USER + 1620 )
//Define CMM_SETCOLORS                  FOR ( WM_USER + 1630 )
//Define CMM_GETCOLORS                  FOR ( WM_USER + 1640 )
Define CMM_ENABLEWHITESPACEDISPLAY    For ( WM_USER + 1800 )
Define CMM_ISWHITESPACEDISPLAYENABLED For ( WM_USER + 1810 )
Define CMM_ENABLETABEXPAND            For ( WM_USER + 1811 )
Define CMM_ISTABEXPANDENABLED         For ( WM_USER + 1812 )
//Define CMM_ENABLESMOOTHSCROLLING      FOR ( WM_USER + 1820 )
//Define CMM_ISSMOOTHSCROLLINGENABLED   FOR ( WM_USER + 1830 )
//Define CMM_ENABLELINETOOLTIPS         FOR ( WM_USER + 1860 )
//Define CMM_ISLINETOOLTIPSENABLED      FOR ( WM_USER + 1870 )
Define CMM_ENABLELEFTMARGIN           For ( WM_USER + 1880 )
Define CMM_ISLEFTMARGINENABLED        For ( WM_USER + 1890 )
Define CMM_ENABLECOLUMNSEL            For ( WM_USER + 1891 )
Define CMM_ISCOLUMNSELENABLED         For ( WM_USER + 1892 )
Define CMM_ENABLEDRAGDROP             For ( WM_USER + 1893 )
Define CMM_ISDRAGDROPENABLED          For ( WM_USER + 1894 )
//Define CMM_SETTOPINDEX                FOR ( WM_USER + 1960 )
//Define CMM_GETTOPINDEX                FOR ( WM_USER + 1970 )
Define CMM_GETVISIBLELINECOUNT        For ( WM_USER + 1980 )
Define CMM_HITTEST                    For ( WM_USER + 1990 )
Define CMM_INSERTFILE                 For ( WM_USER + 2320 )
Define CMM_INSERTTEXT                 For ( WM_USER + 2330 )
Define CMM_REPLACETEXT                For ( WM_USER + 2340 )
Define CMM_GETWORDLENGTH              For ( WM_USER + 2382 )
Define CMM_GETSEL                     For ( WM_USER + 2420 )
Define CMM_GETSELFROMPOINT            For ( WM_USER + 2425 )
Define CMM_SETSEL                     For ( WM_USER + 2430 )
Define CMM_DELETESEL                  For ( WM_USER + 2440 )
Define CMM_REPLACESEL                 For ( WM_USER + 2450 )
Define CMM_SETMODIFIED                For ( WM_USER + 2461 )
Define CMM_ENABLECRLF                 For ( WM_USER + 2470 )
Define CMM_ISCRLFENABLED              For ( WM_USER + 2480 )
//Define CMM_SETFONTOWNERSHIP           FOR ( WM_USER + 2485 )
//Define CMM_GETFONTOWNERSHIP           FOR ( WM_USER + 2486 )
Define CMM_EXECUTECMD                 For ( WM_USER + 2700 )
//Define CMM_SETSPLITTERPOS             FOR ( WM_USER + 2900 )
//Define CMM_GETSPLITTERPOS             FOR ( WM_USER + 2901 )
Define CMM_GETVIEWCOUNT               For ( WM_USER + 3600 )
Define CMM_GETCURRENTVIEW             For ( WM_USER + 3610 )
//Define CMM_ENABLESPLITTER             FOR ( WM_USER + 3720 )
//Define CMM_ISSPLITTERENABLED          FOR ( WM_USER + 3730 )
Define CMM_ISRECORDINGMACRO           For ( WM_USER + 3731 )
Define CMM_ISPLAYINGMACRO             For ( WM_USER + 3732 )
Define CMM_ENABLEGLOBALPROPS          For ( WM_USER + 3740 )
Define CMM_ISGLOBALPROPSENABLED       For ( WM_USER + 3741 )
Define CMM_SETDLGPARENT               For ( WM_USER + 3750 )

// 2.0
Define CMM_ENABLESELBOUNDS            For ( WM_USER + 3760 )
Define CMM_ISSELBOUNDSENABLED         For ( WM_USER + 3770 )
//Define CMM_SETFONTSTYLES              FOR ( WM_USER + 3780 )
//Define CMM_GETFONTSTYLES              FOR ( WM_USER + 3790 )
Define CMM_ENABLEREGEXP               For ( WM_USER + 3800 )
Define CMM_ISREGEXPENABLED            For ( WM_USER + 3810 )
Define CMM_SETITEMDATA                For ( WM_USER + 3820 )
Define CMM_GETITEMDATA                For ( WM_USER + 3830 )
Define CMM_SETLINESTYLE               For ( WM_USER + 3840 )
Define CMM_GETLINESTYLE               For ( WM_USER + 3850 )
Define CMM_SETBOOKMARK                For ( WM_USER + 3860 )
Define CMM_GETBOOKMARK                For ( WM_USER + 3870 )
Define CMM_SETALLBOOKMARKS            For ( WM_USER + 3880 )
Define CMM_GETALLBOOKMARKS            For ( WM_USER + 3890 )
Define CMM_POSFROMCHAR                For ( WM_USER + 3920 )
Define CMM_ENABLEHIDESEL              For ( WM_USER + 3930 )
Define CMM_ISHIDESELENABLED           For ( WM_USER + 3940 )
Define CMM_ENABLENORMALIZECASE        For ( WM_USER + 3970 )
Define CMM_ISNORMALIZECASEENABLED     For ( WM_USER + 3980 )
Define CMM_SETDIVIDER                 For ( WM_USER + 3990 )
Define CMM_GETDIVIDER                 For ( WM_USER + 4000 )
Define CMM_SETFINDTEXT                For ( WM_USER + 4030 )
Define CMM_GETFINDTEXT                For ( WM_USER + 4040 )
Define CMM_SETREPLACETEXT             For ( WM_USER + 4050 )
Define CMM_GETREPLACETEXT             For ( WM_USER + 4060 )
Define CMM_SETIMAGELIST               For ( WM_USER + 4070 )
Define CMM_GETIMAGELIST               For ( WM_USER + 4080 )
Define CMM_SETMARGINIMAGES            For ( WM_USER + 4090 )
Define CMM_GETMARGINIMAGES            For ( WM_USER + 4100 )
Define CMM_ABOUTBOX                   For ( WM_USER + 4110 )
Define CMM_PRINT                      For ( WM_USER + 4120 )
Define CMM_SETCARETPOS                For ( WM_USER + 4130 )
Define CMM_VIEWCOLTOBUFFERCOL         For ( WM_USER + 4140 )
Define CMM_BUFFERCOLTOVIEWCOL         For ( WM_USER + 4150 )

// 2.1
Define CMM_SETBORDERSTYLE             For ( WM_USER + 4160 )
Define CMM_GETBORDERSTYLE             For ( WM_USER + 4170 )
// SVN
Define CMM_SETCURRENTVIEW             For ( WM_USER + 4180 )

Define CMM_GETCURRENTTOKEN            For ( WM_USER + 5000 )
Define CMM_UPDATECONTROLPOSITIONS     For ( WM_USER + 5010 )


// Extensions for Oem/Ansi support
Define CMM_ENABLEOEMCODE              For ( WM_USER + 4300 )
Define CMM_ISOEMCODEENABLED           For ( WM_USER + 4301 )

/////////////////////////////////////////////////////////////
//
// Edit commands
//
//

Define CMD_FIRST                       For 100
Define CMD_WORDUPPERCASE               For ( CMD_FIRST + 0 )
Define CMD_WORDTRANSPOSE               For ( CMD_FIRST + 1 )
Define CMD_WORDRIGHTEXTEND             For ( CMD_FIRST + 2 )
Define CMD_WORDRIGHT                   For ( CMD_FIRST + 3 )
Define CMD_WORDENDRIGHT                For ( CMD_FIRST + 4 )
Define CMD_WORDENDRIGHTEXTEND          For ( CMD_FIRST + 5 )
Define CMD_WORDLOWERCASE               For ( CMD_FIRST + 6 )
Define CMD_WORDLEFTEXTEND              For ( CMD_FIRST + 7 )
Define CMD_WORDLEFT                    For ( CMD_FIRST + 8 )
Define CMD_WORDENDLEFT                 For ( CMD_FIRST + 9 )
Define CMD_WORDENDLEFTEXTEND           For ( CMD_FIRST + 10 )
Define CMD_WORDDELETETOSTART           For ( CMD_FIRST + 11 )
Define CMD_WORDDELETETOEND             For ( CMD_FIRST + 12 )
Define CMD_WORDCAPITALIZE              For ( CMD_FIRST + 13 )
Define CMD_WINDOWSTART                 For ( CMD_FIRST + 14 )
Define CMD_WINDOWSCROLLUP              For ( CMD_FIRST + 15 )
Define CMD_WINDOWSCROLLTOTOP           For ( CMD_FIRST + 16 )
Define CMD_WINDOWSCROLLTOCENTER        For ( CMD_FIRST + 17 )
Define CMD_WINDOWSCROLLTOBOTTOM        For ( CMD_FIRST + 18 )
Define CMD_WINDOWSCROLLRIGHT           For ( CMD_FIRST + 19 )
Define CMD_WINDOWSCROLLLEFT            For ( CMD_FIRST + 20 )
Define CMD_WINDOWSCROLLDOWN            For ( CMD_FIRST + 21 )
Define CMD_WINDOWRIGHTEDGE             For ( CMD_FIRST + 22 )
Define CMD_WINDOWLEFTEDGE              For ( CMD_FIRST + 23 )
Define CMD_WINDOWEND                   For ( CMD_FIRST + 24 )
Define CMD_UPPERCASESELECTION          For ( CMD_FIRST + 25 )
Define CMD_UNTABIFYSELECTION           For ( CMD_FIRST + 26 )
Define CMD_UNINDENTSELECTION           For ( CMD_FIRST + 27 )
Define CMD_UNDOCHANGES                 For ( CMD_FIRST + 28 )
Define CMD_UNDO                        For ( CMD_FIRST + 29 )
Define CMD_TABIFYSELECTION             For ( CMD_FIRST + 30 )
Define CMD_SENTENCERIGHT               For ( CMD_FIRST + 31 )
Define CMD_SENTENCELEFT                For ( CMD_FIRST + 32 )
Define CMD_SENTENCECUT                 For ( CMD_FIRST + 33 )
Define CMD_SELECTSWAPANCHOR            For ( CMD_FIRST + 34 )
Define CMD_SELECTPARA                  For ( CMD_FIRST + 35 )
Define CMD_SELECTLINE                  For ( CMD_FIRST + 36 )
Define CMD_SELECTALL                   For ( CMD_FIRST + 37 )
Define CMD_REDOCHANGES                 For ( CMD_FIRST + 38 )
Define CMD_REDO                        For ( CMD_FIRST + 39 )
Define CMD_PASTE                       For ( CMD_FIRST + 40 )
Define CMD_PARAUP                      For ( CMD_FIRST + 41 )
Define CMD_PARADOWN                    For ( CMD_FIRST + 42 )
Define CMD_PAGEUPEXTEND                For ( CMD_FIRST + 43 )
Define CMD_PAGEUP                      For ( CMD_FIRST + 44 )
Define CMD_PAGEDOWNEXTEND              For ( CMD_FIRST + 45 )
Define CMD_PAGEDOWN                    For ( CMD_FIRST + 46 )
Define CMD_LOWERCASESELECTION          For ( CMD_FIRST + 47 )
Define CMD_LINEUPEXTEND                For ( CMD_FIRST + 48 )
Define CMD_LINEUP                      For ( CMD_FIRST + 49 )
Define CMD_LINETRANSPOSE               For ( CMD_FIRST + 50 )
Define CMD_LINESTART                   For ( CMD_FIRST + 51 )
Define CMD_LINEOPENBELOW               For ( CMD_FIRST + 52 )
Define CMD_LINEOPENABOVE               For ( CMD_FIRST + 53 )
Define CMD_LINEENDEXTEND               For ( CMD_FIRST + 54 )
Define CMD_LINEEND                     For ( CMD_FIRST + 55 )
Define CMD_LINEDOWNEXTEND              For ( CMD_FIRST + 56 )
Define CMD_LINEDOWN                    For ( CMD_FIRST + 57 )
Define CMD_LINEDELETETOSTART           For ( CMD_FIRST + 58 )
Define CMD_LINEDELETETOEND             For ( CMD_FIRST + 59 )
Define CMD_LINEDELETE                  For ( CMD_FIRST + 60 )
Define CMD_LINECUT                     For ( CMD_FIRST + 61 )
Define CMD_INDENTTOPREV                For ( CMD_FIRST + 62 )
Define CMD_INDENTSELECTION             For ( CMD_FIRST + 63 )
Define CMD_HOMEEXTEND                  For ( CMD_FIRST + 64 )
Define CMD_HOME                        For ( CMD_FIRST + 65 )
Define CMD_GOTOMATCHBRACE              For ( CMD_FIRST + 66 )
Define CMD_GOTOINDENTATION             For ( CMD_FIRST + 67 )
Define CMD_GOTOLINE                    For ( CMD_FIRST + 68 )
Define CMD_FINDREPLACE                 For ( CMD_FIRST + 69 )
Define CMD_REPLACE                     For ( CMD_FIRST + 70 )
Define CMD_REPLACEALLINBUFFER          For ( CMD_FIRST + 71 )
Define CMD_REPLACEALLINSELECTION       For ( CMD_FIRST + 72 )
Define CMD_FINDPREVWORD                For ( CMD_FIRST + 73 )
Define CMD_FINDPREV                    For ( CMD_FIRST + 74 )
Define CMD_FINDNEXTWORD                For ( CMD_FIRST + 75 )
Define CMD_FINDNEXT                    For ( CMD_FIRST + 76 )
Define CMD_FINDMARKALL                 For ( CMD_FIRST + 77 )
Define CMD_FIND                        For ( CMD_FIRST + 78 )
Define CMD_SETFINDTEXT                 For ( CMD_FIRST + 79 )
Define CMD_SETREPLACETEXT              For ( CMD_FIRST + 80 )
Define CMD_TOGGLEPRESERVECASE          For ( CMD_FIRST + 81 )
Define CMD_TOGGLEWHOLEWORD             For ( CMD_FIRST + 82 )
Define CMD_TOGGLECASESENSITIVE         For ( CMD_FIRST + 83 )
Define CMD_END                         For ( CMD_FIRST + 84 )
Define CMD_TOGGLEWHITESPACEDISPLAY     For ( CMD_FIRST + 85 )
Define CMD_TOGGLEOVERTYPE              For ( CMD_FIRST + 86 )
Define CMD_SETREPEATCOUNT              For ( CMD_FIRST + 87 )
Define CMD_DOCUMENTSTARTEXTEND         For ( CMD_FIRST + 88 )
Define CMD_DOCUMENTSTART               For ( CMD_FIRST + 89 )
Define CMD_DOCUMENTENDEXTEND           For ( CMD_FIRST + 90 )
Define CMD_DOCUMENTEND                 For ( CMD_FIRST + 91 )
Define CMD_DELETEHORIZONTALSPACE       For ( CMD_FIRST + 92 )
Define CMD_DELETEBLANKLINES            For ( CMD_FIRST + 93 )
Define CMD_DELETEBACK                  For ( CMD_FIRST + 94 )
Define CMD_DELETE                      For ( CMD_FIRST + 95 )
Define CMD_CUTSELECTION                For ( CMD_FIRST + 96 )
Define CMD_CUT                         For ( CMD_FIRST + 97 )
Define CMD_COPY                        For ( CMD_FIRST + 98 )
Define CMD_CHARTRANSPOSE               For ( CMD_FIRST + 99 )
Define CMD_CHARRIGHTEXTEND             For ( CMD_FIRST + 100 )
Define CMD_CHARRIGHT                   For ( CMD_FIRST + 101 )
Define CMD_CHARLEFTEXTEND              For ( CMD_FIRST + 102 )
Define CMD_CHARLEFT                    For ( CMD_FIRST + 103 )
Define CMD_BOOKMARKTOGGLE              For ( CMD_FIRST + 104 )
Define CMD_BOOKMARKPREV                For ( CMD_FIRST + 105 )
Define CMD_BOOKMARKNEXT                For ( CMD_FIRST + 106 )
Define CMD_BOOKMARKCLEARALL            For ( CMD_FIRST + 107 )
Define CMD_BOOKMARKJUMPTOFIRST         For ( CMD_FIRST + 108 )
Define CMD_BOOKMARKJUMPTOLAST          For ( CMD_FIRST + 109 )
Define CMD_APPENDNEXTCUT               For ( CMD_FIRST + 110 )
Define CMD_INSERTCHAR                  For ( CMD_FIRST + 111 )
Define CMD_NEWLINE                     For ( CMD_FIRST + 112 )
Define CMD_RECORDMACRO                 For ( CMD_FIRST + 113 )
Define CMD_PLAYMACRO1                  For ( CMD_FIRST + 114 )
Define CMD_PLAYMACRO2                  For ( CMD_FIRST + 115 )
Define CMD_PLAYMACRO3                  For ( CMD_FIRST + 116 )
Define CMD_PLAYMACRO4                  For ( CMD_FIRST + 117 )
Define CMD_PLAYMACRO5                  For ( CMD_FIRST + 118 )
Define CMD_PLAYMACRO6                  For ( CMD_FIRST + 119 )
Define CMD_PLAYMACRO7                  For ( CMD_FIRST + 120 )
Define CMD_PLAYMACRO8                  For ( CMD_FIRST + 121 )
Define CMD_PLAYMACRO9                  For ( CMD_FIRST + 122 )
Define CMD_PLAYMACRO10                 For ( CMD_FIRST + 123 )
Define CMD_PROPERTIES                  For ( CMD_FIRST + 124 )
Define CMD_BEGINUNDO                   For ( CMD_FIRST + 125 )
Define CMD_ENDUNDO                     For ( CMD_FIRST + 126 )
Define CMD_RESERVED3                   For ( CMD_FIRST + 127 )  // internal use only
// 2.0
Define CMD_TOGGLEREGEXP                For ( CMD_FIRST + 128 )
Define CMD_CLEARSELECTION              For ( CMD_FIRST + 129 )
Define CMD_REGEXPON                    For ( CMD_FIRST + 130 )
Define CMD_REGEXPOFF                   For ( CMD_FIRST + 131 )
Define CMD_WHOLEWORDON                 For ( CMD_FIRST + 132 )
Define CMD_WHOLEWORDOFF                For ( CMD_FIRST + 133 )
Define CMD_PRESERVECASEON              For ( CMD_FIRST + 134 )
Define CMD_PRESERVECASEOFF             For ( CMD_FIRST + 135 )
Define CMD_CASESENSITIVEON             For ( CMD_FIRST + 136 )
Define CMD_CASESENSITIVEOFF            For ( CMD_FIRST + 137 )
Define CMD_WHITESPACEDISPLAYON         For ( CMD_FIRST + 138 )
Define CMD_WHITESPACEDISPLAYOFF        For ( CMD_FIRST + 139 )
Define CMD_OVERTYPEON                  For ( CMD_FIRST + 140 )
Define CMD_OVERTYPEOFF                 For ( CMD_FIRST + 141 )
// SVN
//Define CMD_LAST                        For ( CMD_FIRST + 141 )
// 2.1
Define CMD_CODELIST                    For ( CMD_FIRST + 142 )
Define CMD_CODETIP                     For ( CMD_FIRST + 143 )
Define CMD_LAST                        For ( CMD_FIRST + 143 )

// all register commands must be at or higher than CMD_USER_BASE
Define CMD_USER_BASE                   For ( CMD_FIRST + 900 )

Define CMDERR_FAILURE     For 1     // general failure
Define CMDERR_INPUT       For 2     // bad input
Define CMDERR_SELECTION   For 3     // bad selection
Define CMDERR_NOTFOUND    For 4     // data not found
Define CMDERR_EMPTYBUF    For 5     // buffer is empty
Define CMDERR_READONLY    For 6     // buffer is read-only

////////////////////////////////////////////////////////////////////////////////////////
//
// Language Support for CMM_SETLANGUAGE, RegisterLanguage(), and UnregisterLanguage()
//
//

// stock languages
Define CMLANG_CPP         For "C/C++"
Define CMLANG_PASCAL      For "Pascal"
Define CMLANG_BASIC       For "Basic"
Define CMLANG_SQL         For "SQL"
Define CMLANG_JAVA        For "Java"
Define CMLANG_HTML        For "HTML"
Define CMLANG_XML         For "XML"

//// language styles
//Define CMLS_PROCEDURAL    FOR 0
//Define CMLS_SGML          FOR 1
//
//
//TYPE CM_LANGUAGE
//    Field CM_LANGUAGE.dwStyle                             as Dword    // One of the CMLS_ values DWORD
//    Field CM_LANGUAGE.bIsCaseSensitive                    as Integer  // TRUE if keywords are case sensitive BOOL
//    Field CM_LANGUAGE.pszKeywords                         as Pointer  // The keywords delimited by '\n' LPCTSTR
//    Field CM_LANGUAGE.pszOperators                        as Pointer  // The operators delimited by '\n' LPCTSTR
//    Field CM_LANGUAGE.pszSingleLineComments               as Pointer  // The single line comment tokens (e.g. "//") LPCTSTR
//    Field CM_LANGUAGE.pszMultiLineComments1               as Pointer  // The multiline comment start tokens (e.g. "/*\n{\n(*") LPCTSTR
//    Field CM_LANGUAGE.pszMultiLineComments2               as Pointer  // The multiline comment end tokens (e.g. "*/\n}\n*)") LPCTSTR
//    Field CM_LANGUAGE.pszScopeKeywords1                   as Pointer  // The scoping start tokens (e.g. "{\nbegin") LPCTSTR
//    Field CM_LANGUAGE.pszScopeKeywords2                   as Pointer  // The multiline comment end tokens (e.g. "}\nend") LPCTSTR
//    Field CM_LANGUAGE.pszStringDelims                     as Pointer  // The string literal delimiters (e.g. "\"\n'") -- also includes character literals LPCTSTR
//    Field CM_LANGUAGE.chEscape                            as Char 1   // The escape character TCHAR
//    Field CM_LANGUAGE.chTerminator                        as Char 1   // The statement terminator char (usually ';') TCHAR
//    Field CM_LANGUAGE.pszTagElementNames                  as Pointer  // Tag-based element names delimited by '\n' LPCTSTR
//    Field CM_LANGUAGE.pszTagAttributeNames                as Pointer  // Tag-based attribute names delimited by '\n' LPCTSTR
//    Field CM_LANGUAGE.pszTagEntities                      as Pointer  // Tag-based entities delimited by '\n' LPCTSTR
//END_TYPE
//
//// Color settings for CMM_GETCOLORS and CMM_SETCOLORS
////
//// Note:  Use CLR_INVALID on background colors to specify transparent
////        (text) or appropriate control panel setting
//TYPE CM_COLORS
//    Field CM_COLORS.crWindow                            as COLORREF // window background color
//    Field CM_COLORS.crLeftMargin                        as COLORREF // left margin background color
//    Field CM_COLORS.crBookmark                          as COLORREF // bookmark foreground color
//    Field CM_COLORS.crBookmarkBk                        as COLORREF // bookmark background color
//    Field CM_COLORS.crText                              as COLORREF // plain text foreground color
//    Field CM_COLORS.crTextBk                            as COLORREF // plain text background color
//    Field CM_COLORS.crNumber                            as COLORREF // numeric literal foreground color
//    Field CM_COLORS.crNumberBk                          as COLORREF // numeric literal background color
//    Field CM_COLORS.crKeyword                           as COLORREF // keyword foreground color
//    Field CM_COLORS.crKeywordBk                         as COLORREF // keyword background color
//    Field CM_COLORS.crOperator                          as COLORREF // operator foreground color
//    Field CM_COLORS.crOperatorBk                        as COLORREF // operator background color
//    Field CM_COLORS.crScopeKeyword                      as COLORREF // scope keyword foreground color
//    Field CM_COLORS.crScopeKeywordBk                    as COLORREF // scope keyword background color
//    Field CM_COLORS.crComment                           as COLORREF // comment foreground color
//    Field CM_COLORS.crCommentBk                         as COLORREF // comment background color
//    Field CM_COLORS.crString                            as COLORREF // string foreground color
//    Field CM_COLORS.crStringBk                          as COLORREF // string background color
//    Field CM_COLORS.crTagText                           as COLORREF // plain tag text foreground color
//    Field CM_COLORS.crTagTextBk                         as COLORREF // plain tag text background color
//    Field CM_COLORS.crTagEntity                         as COLORREF // tag entity foreground color
//    Field CM_COLORS.crTagEntityBk                       as COLORREF // tag entity background color
//    Field CM_COLORS.crTagElementName                    as COLORREF // tag element name foreground color
//    Field CM_COLORS.crTagElementNameBk                  as COLORREF // tag element name background color
//    Field CM_COLORS.crTagAttributeName                  as COLORREF // tag attribute name foreground color
//    Field CM_COLORS.crTagAttributeNameBk                as COLORREF // tag attribute name background color
//    Field CM_COLORS.crLineNumber                        as COLORREF // line number foreground color
//    Field CM_COLORS.crLineNumberBk                      as COLORREF // line number background color
//    Field CM_COLORS.crHDividerLines                     as COLORREF // line number separate line color
//    Field CM_COLORS.crVDividerLines                     as COLORREF // left margin separate line color
//    Field CM_COLORS.crHighlightedLine                   as COLORREF // highlighted line color
//END_TYPE
//
//
///////////////////////////////////////////////////////////////
////
//// Font style settings for CMM_GETFONTSTYLES and CMM_SETFONTSTYLES
//// each byte value is one of the CM_FONT_XXX values listed below
//// this declaration
////
//TYPE CM_FONTSTYLES
//    Field CM_FONTSTYLES.byText                              as Char 1   // plain text font style BYTE
//    Field CM_FONTSTYLES.byNumber                            as Char 1   // numeric literal font style BYTE
//    Field CM_FONTSTYLES.byKeyword                           as Char 1   // keyword font style BYTE
//    Field CM_FONTSTYLES.byOperator                          as Char 1   // operator font style BYTE
//    Field CM_FONTSTYLES.byScopeKeyword                      as Char 1   // scope keyword font style BYTE
//    Field CM_FONTSTYLES.byComment                           as Char 1   // comment font style BYTE
//    Field CM_FONTSTYLES.byString                            as Char 1   // string font style BYTE
//    Field CM_FONTSTYLES.byTagText                           as Char 1   // plain tag text font style BYTE
//    Field CM_FONTSTYLES.byTagEntity                         as Char 1   // tag entity font style BYTE
//    Field CM_FONTSTYLES.byTagElementName                    as Char 1   // tag element name font style BYTE
//    Field CM_FONTSTYLES.byTagAttributeName                  as Char 1   // tag attribute name font style BYTE
//    Field CM_FONTSTYLES.byLineNumber                        as Char 1   // line number font style BYTE
//END_TYPE
//
///////////////////////////////////////////////////////////////
////
//// Font style options used in CM_FONTSTYLES
////
////
//Define CM_FONT_NORMAL     For 0   // normal weight
//Define CM_FONT_BOLD       For 1   // bold weight
//Define CM_FONT_ITALIC     For 2   // normal weight, italic
//Define CM_FONT_BOLDITALIC For 3   // bold weight, italic
//Define CM_FONT_UNDERLINE  For 4   // normal weight, underline
//
///////////////////////////////////////////////////////////////
////
// AutoIndent options
//
//
Define CM_INDENT_OFF        For  0    // auto-indent off -- new line begins at column 0
Define CM_INDENT_SCOPE      For  1    // NOT SUPPORTED
Define CM_INDENT_PREVLINE   For  2    // new line has identical indentation of previous line
//
///////////////////////////////////////////////////////////////
////
//// Print option flags used with CMM_PRINT
////
////
//Define CM_PRINT_PROMPTDLG    For |CI$000   // display the print common dialog
//Define CM_PRINT_DEFAULTPRN   For |CI$001   // use default printer (no print dialog displayed)
//Define CM_PRINT_HDC          For |CI$002   // use HDC provided
//Define CM_PRINT_RICHFONTS    For |CI$004   // use bold, italics, underline, etc. when appropriate
//Define CM_PRINT_COLOR        For |CI$008   // print in color
//Define CM_PRINT_PAGENUMS     For |CI$010   // print 'page # of #' at the bottom of the page
//Define CM_PRINT_DATETIME     For |CI$020   // print date and time at top of the page
//Define CM_PRINT_BORDERTHIN   For |CI$040   // surround text with a thin border
//Define CM_PRINT_BORDERTHICK  For |CI$080   // surround text with a thick border
//Define CM_PRINT_BORDERDOUBLE For |CI$100   // surround text with two thin borders
//Define CM_PRINT_SELECTION    For |CI$200   // print the selection rather than entire edit contents
//
///////////////////////////////////////////////////////////////
////
//// Border option flags used with CMM_GETBORDERSTYLE and CMM_SETBORDERSTYLE.
//// Note: this values may be or'd together to achieve different effects.
////
//Define CM_BORDER_NONE        For |CI$0  // no border
//Define CM_BORDER_THIN        For |CI$1  // 1-pixel border
//Define CM_BORDER_CLIENT      For |CI$2  // client edge (WS_EX_CLIENTEDGE)
//Define CM_BORDER_STATIC      For |CI$4  // static edge (WS_EX_STATICEDGE)
//Define CM_BORDER_MODAL       For |CI$8  // modal edge (WS_EX_DLGMODALFRAME)
//Define CM_BORDER_CORRAL      For (CM_BORDER_MODAL Ior CM_BORDER_CLIENT)
//
//
///////////////////////////////////////////////////////////////
////
//// Text position indicators
////
////
//
//Type CM_POSITION
//  Field CM_POSITION.nLine                as Integer  // zero-based line number int
//  Field CM_POSITION.nCol                 as Integer  // zero-based *buffer* column number int
//End_Type
//
//// Erzeugt einen String und eine Pointer variable, wenn diese noch nicht definiert sind!
//// Fueltt mit Line und Col und holt die Addresse in the Pointer
//#COMMAND Local_CM_POSITION R R "LINE=" R "COL=" R
//    DEFINE_STR_PTR !1 !2
//    ZeroType CM_POSITION  To !1         // as a little insurance
//    Put !4 To !1 At CM_POSITION.nLine   // Set Line
//    Put !6 To !1 At CM_POSITION.nCol    // Set Column
//    GetAddress Of !1 To !2
//#ENDCOMMAND
//
//
//    // Erzeugt einen String und eine Pointer variable, wenn diese noch nicht definiert sind!
//    // Fueltt mit Line und Col und holt die Addresse in the Pointer
//
//TYPE CM_RANGE
//    Field CM_RANGE.posStart             as Char CM_POSITION_SIZE    // the anchor CM_POSITION
//    Field CM_RANGE.posEnd               as Char CM_POSITION_SIZE    // the extension (if same as anchor, selection is empty) CM_POSITION
//    Field CM_RANGE.bColumnSel           as Integer                  // TRUE if is a column selection, FALSE if paragragh selection BOOL
//END_TYPE
//
//#COMMAND Local_CM_RANGE R R "START=" R  R "END=" R R
//    DEFINE_STR_PTR !1 !2
//    Zerotype CM_RANGE   to !1
//
//    Local_CM_POSITION sPosStart psPosStart LINE= !4 COL= !5   // Create a String with the StartPosition
//    Local_CM_POSITION sPosEnd   psPosEnd   LINE= !7 COL= !8   // Create a String with the EndPosition
//
//    PUT_STRING sPosStart to !1 AT CM_RANGE.posStart           // Set Start Position
//    PUT_STRING sPosEnd   to !1 AT CM_RANGE.posEnd             // Set End Position
//
//    GetAddress Of !1     to !2                                // Get the Address of the created Structure
//#ENDCOMMAND


///////////////////////////////////////////////////////////////
////
//// Hot key descriptor
////
////
//TYPE CM_HOTKEY
//    Field CM_HOTKEY.byModifiers1         as Integer //Char 1   // 1st keystroke's modifiers (combination of HOTKEYF_ALT, HOTKEYF_SHIFT, HOTKEYF_CONTROL) BYTE
//    Field CM_HOTKEY.nVirtKey1            as Integer  // 1st keystroke's virtkey (e.g. Ctrl + 'A') UINT
//    Field CM_HOTKEY.byModifiers2         as Integer //Char 1   // 2nd keystroke's modifiers (combination of HOTKEYF_ALT, HOTKEYF_SHIFT, HOTKEYF_CONTROL) BYTE
//    Field CM_HOTKEY.nVirtKey2            as Integer  // 2nd keystroke's virtkey (e.g. Ctrl + 'A') UINT
//END_TYPE

//
///////////////////////////////////////////////////////////////
////
//// CMN_CMDFAILURE notification data passed to parent window
////
////
//TYPE CM_CMDFAILUREDATA
//    Field CM_CMDFAILUREDATA.hdr                  as Char NMHDR_SIZE // standard notification data NMHDR
//    Field CM_CMDFAILUREDATA.wCmd                 as WORD            // CMD_XXX command that failed WORD
//    Field CM_CMDFAILUREDATA.dwErr                as Dword           // CMDERR_XXX failure code DWORD
//END_TYPE


///////////////////////////////////////////////////////////////
////
//// CMN_KEYDOWN, CMN_KEYUP, CMN_KEYPRESS notification
//// data passed to parent window
////
////
Define CM_KEY_NOEXT      For |CI$0
Define CM_KEY_SHIFT      For |CI$1
Define CM_KEY_CTRL       For |CI$2
Define CM_KEY_ALT        For |CI$4
//TYPE CM_KEYDATA
//    Field CM_KEYDATA.hdr                  as Char NMHDR_SIZE    // standard notification data NMHDR
//    Field CM_KEYDATA.nKeyCode             as Integer            // virtkey if CMN_KEYUP or CMN_KEYDOWN.  Ascii code if CMN_KEYPRESS int
//    Field CM_KEYDATA.nKeyModifier         as Integer            // bitfield of: CM_KEY_SHIFT, CM_KEY_CTRL, and/or CM_KEY_ALT int
//END_TYPE

// Just converts the ID to the name.
Function CMKeymodifierIDToName Global Integer iModifier Returns String
  String sRet
  If (iModifier Iand CM_KEY_SHIFT) ;
    Append sRet (If(sRet Eq "","","+")) "Shift"
  If (iModifier Iand CM_KEY_CTRL) ;
    Append sRet (If(sRet Eq "","","+")) "Ctrl"
  If (iModifier Iand CM_KEY_ALT) ;
    Append sRet (If(sRet Eq "","","+")) "Alt"
  Function_Return sRet
End_Function

///////////////////////////////////////////////////////////////
////
//// CMN_MOUSEDOWN, CMN_MOUSEUP, CMN_MOUSEPRESS notification
//// data passed to parent window
////
////
//Define CM_BTN_LEFT      For |CI$1
//Define CM_BTN_RIGHT     For |CI$2
//Define CM_BTN_MIDDLE    For |CI$4
//
//TYPE CM_MOUSEDATA
//    Field CM_MOUSEDATA.hdr                  as Char NMHDR_SIZE  // standard notification data NMHDR
//    Field CM_MOUSEDATA.pt                   as Char tPOINT_SIZE // position of mouse (client coordinates) POINT
//    Field CM_MOUSEDATA.nButton              as Integer  // bitfield of: CM_BTN_LEFT, CM_BTN_RIGHT, and/or CM_BTN_MIDDLE int
//    Field CM_MOUSEDATA.nKeyModifier         as Integer  // bitfield of: CM_KEY_SHIFT, CM_KEY_CTRL, and/or CM_KEY_ALT int
//END_TYPE
//
///////////////////////////////////////////////////////////////
////
//// CMN_FINDWRAPPED notification data passed to parent window
////
////
//TYPE CM_FINDWRAPPEDDATA
//    Field CM_FINDWRAPPEDDATA.hdr                  as Char NMHDR_SIZE // standard notification data NMHDR
//    Field CM_FINDWRAPPEDDATA.wCmd                 as WORD     // the command being executed WORD
//    Field CM_FINDWRAPPEDDATA.bForward             as Integer  // TRUE if wrapped while searching forward, FALSE if searching backward BOOL
//END_TYPE

///////////////////////////////////////////////////////////////
////
//// Tooltip window styles specified as return value from
//// CMN_CODETIP notifications
////
//Define CM_TIPSTYLE_NONE				    For 0	// don't display a tooltip
//Define CM_TIPSTYLE_NORMAL				  For 1	// standard tooltip window
//Define CM_TIPSTYLE_HIGHLIGHT			for 2	// tooltip with text highlighting
//Define CM_TIPSTYLE_FUNCHIGHLIGHT	for 3	// tooltip with function highlighting
//Define CM_TIPSTYLE_MULTIFUNC			for 4	// highlighting for multiple functions

Define C_TIPTYPE_UNDEFINED        For 0
Define C_TIPTYPE_EXPRESSION       For 1
Define C_TIPTYPE_FUNCTION         For 2
Define C_TIPTYPE_PROCEDURE        For 3
//
//
//// -----------------------------------------------------------------------------------------
//// END - SVN
//

/////////////////////////////////////////////////////////////
//
// data passed to CMM_SETLINENUMBERING
//
//
Define CM_BINARY            For 2  // not supported
Define CM_OCTAL             For 8  // not supported
Define CM_DECIMAL           For 10
Define CM_HEXADECIMAL       For 16 // not supported


/////////////////////////////////////////////////////////////
//
// Error codes
//
//
//typedef LRESULT CME_CODE;

Define CME_SUCCESS        For 1        // function or method completed successfully
Define CME_FAILURE        For 0        // function or method did not complete because of an error
Define CME_BADARGUMENT    For -1       // function or method did not complete because an invalid argument was passed in

/////////////////////////////////////////////////////////////
//
// CMM_HITTEST return codes
//
//

Define CM_NOWHERE        For 0        // Not over the CodeMax control
Define CM_HSPLITTER      For 1        // Over the horizontal splitter bar
Define CM_VSPLITTER      For 2        // Over the vertical splitter bar
Define CM_HVSPLITTER     For 3        // Over the intersection of the horizontal and vertical splitter bar
Define CM_EDITSPACE      For 4        // Over the buffer contents (code)
Define CM_HSCROLLBAR     For 5        // Over the horizontal scrollbar
Define CM_VSCROLLBAR     For 6        // Over the vertical scrollbar
Define CM_SIZEBOX        For 7        // Over the sizebox visible when both scrollbars are visible
Define CM_LEFTMARGIN     For 8        // Over the left margin area


/////////////////////////////////////////////////////////////
//
// CMM_GETCURRENTTOKEN return codes
//
//

Define CM_TOKENTYPE_KEYWORD					For |CI$1 // 0x01
Define CM_TOKENTYPE_OPERATOR				For |CI$2 //0x02
Define CM_TOKENTYPE_STRING					For |CI$3 //0x03
Define CM_TOKENTYPE_SINGLELINECOMMENT		For |CI$4 //0x04
Define CM_TOKENTYPE_MULTILINECOMMENT		For |CI$5 //0x05
Define CM_TOKENTYPE_NUMBER					For |CI$6 //0x06
Define CM_TOKENTYPE_SCOPEBEGIN				For |CI$7 //0x07
Define CM_TOKENTYPE_SCOPEEND				For |CI$8 //0x08
Define CM_TOKENTYPE_TEXT					For |CI$FF //0xff
Define CM_TOKENTYPE_LAST                    For |CI$FFFFFFFF
Define CM_TOKENTYPE_UNKNOWN					For (CM_TOKENTYPE_LAST-1) //(DWORD)-1


/////////////////////////////////////////////////////////////
//
// Exported functions
//
//

Define SCLEX_NULL                       For 1
Define SCLEX_PYTHON                     For 2
Define SCLEX_CPP                        For 3
Define SCLEX_HTML                       For 4
Define SCLEX_XML                        For 5
Define SCLEX_PERL                       For 6
Define SCLEX_SQL                        For 7
Define SCLEX_VB                         For 8
Define SCLEX_PROPERTIES                 For 9
Define SCLEX_PASCAL                     For 18
Define SCLEX_PHPSCRIPT                  For 69
Define SCLEX_DATAFLEX                   For 129

Define SCE_NOTUSED                      For -1

// Text
Define SCE_TEXT_DEFAULT                 For 0

// DataFlex
Define SCE_DF_DEFAULT                   For 0
Define SCE_DF_IDENTIFIER                For 1
Define SCE_DF_METATAG                   For 2
Define SCE_DF_IMAGE                     For 3
Define SCE_DF_COMMENTLINE               For 4
Define SCE_DF_PREPROCESSOR              For 5
Define SCE_DF_PREPROCESSOR2             For 6
Define SCE_DF_NUMBER                    For 7
Define SCE_DF_HEXNUMBER                 For 8
Define SCE_DF_WORD                      For 9
Define SCE_DF_STRING                    For 10
Define SCE_DF_STRINGEOL                 For 11
Define SCE_DF_SCOPEWORD                 For 12
Define SCE_DF_OPERATOR                  For 13
Define SCE_DF_ICODE                     For 14

// C/C++
Define SCE_C_DEFAULT                    For 0
Define SCE_C_COMMENT                    For 1
Define SCE_C_COMMENTLINE                For 2
Define SCE_C_COMMENTDOC                 For 3
Define SCE_C_NUMBER                     For 4
Define SCE_C_WORD                       For 5
Define SCE_C_STRING                     For 6
Define SCE_C_CHARACTER                  For 7
Define SCE_C_UUID                       For 8
Define SCE_C_PREPROCESSOR               For 9
Define SCE_C_OPERATOR                   For 10
Define SCE_C_IDENTIFIER                 For 11
Define SCE_C_STRINGEOL                  For 12
Define SCE_C_VERBATIM                   For 13
Define SCE_C_REGEX                      For 14
Define SCE_C_COMMENTLINEDOC             For 15
Define SCE_C_WORD2                      For 16
Define SCE_C_COMMENTDOCKEYWORD          For 17
Define SCE_C_COMMENTDOCKEYWORDERROR     For 18
Define SCE_C_GLOBALCLASS                For 19
Define SCE_C_STRINGRAW                  For 20
Define SCE_C_TRIPLEVERBATIM             For 21
Define SCE_C_HASHQUOTEDSTRING           For 22
Define SCE_C_PREPROCESSORCOMMENT        For 23
Define SCE_C_PREPROCESSORCOMMENTDOC     For 24
Define SCE_C_USERLITERAL                For 25
Define SCE_C_TASKMARKER                 For 26
Define SCE_C_ESCAPESEQUENCE             For 27

// Pascal
Define SCE_PAS_DEFAULT                  For 0
Define SCE_PAS_IDENTIFIER               For 1
Define SCE_PAS_COMMENT                  For 2
Define SCE_PAS_COMMENT2                 For 3
Define SCE_PAS_COMMENTLINE              For 4
Define SCE_PAS_PREPROCESSOR             For 5
Define SCE_PAS_PREPROCESSOR2            For 6
Define SCE_PAS_NUMBER                   For 7
Define SCE_PAS_HEXNUMBER                For 8
Define SCE_PAS_WORD                     For 9
Define SCE_PAS_STRING                   For 10
Define SCE_PAS_STRINGEOL                For 11
Define SCE_PAS_CHARACTER                For 12
Define SCE_PAS_OPERATOR                 For 13
Define SCE_PAS_ASM                      For 14

// Html/XML/PHP
Define SCE_H_DEFAULT                    For 0
Define SCE_H_TAG                        For 1
Define SCE_H_TAGUNKNOWN                 For 2
Define SCE_H_ATTRIBUTE                  For 3
Define SCE_H_ATTRIBUTEUNKNOWN           For 4
Define SCE_H_NUMBER                     For 5
Define SCE_H_DOUBLESTRING               For 6
Define SCE_H_SINGLESTRING               For 7
Define SCE_H_OTHER                      For 8
Define SCE_H_COMMENT                    For 9
Define SCE_H_ENTITY                     For 10
Define SCE_H_TAGEND                     For 11
Define SCE_H_XMLSTART                   For 12
Define SCE_H_XMLEND                     For 13
Define SCE_H_SCRIPT                     For 14
Define SCE_H_ASP                        For 15
Define SCE_H_ASPAT                      For 16
Define SCE_H_CDATA                      For 17
Define SCE_H_QUESTION                   For 18
Define SCE_H_VALUE                      For 19
Define SCE_H_XCCOMMENT                  For 20
Define SCE_H_SGML_DEFAULT               For 21
Define SCE_H_SGML_COMMAND               For 22
Define SCE_H_SGML_1ST_PARAM             For 23
Define SCE_H_SGML_DOUBLESTRING          For 24
Define SCE_H_SGML_SIMPLESTRING          For 25
Define SCE_H_SGML_ERROR                 For 26
Define SCE_H_SGML_SPECIAL               For 27
Define SCE_H_SGML_ENTITY                For 28
Define SCE_H_SGML_COMMENT               For 29
Define SCE_H_SGML_1ST_PARAM_COMMENT     For 30
Define SCE_H_SGML_BLOCK_DEFAULT         For 31
Define SCE_HJ_START                     For 40
Define SCE_HJ_DEFAULT                   For 41
Define SCE_HJ_COMMENT                   For 42
Define SCE_HJ_COMMENTLINE               For 43
Define SCE_HJ_COMMENTDOC                For 44
Define SCE_HJ_NUMBER                    For 45
Define SCE_HJ_WORD                      For 46
Define SCE_HJ_KEYWORD                   For 47
Define SCE_HJ_DOUBLESTRING              For 48
Define SCE_HJ_SINGLESTRING              For 49
Define SCE_HJ_SYMBOLS                   For 50
Define SCE_HJ_STRINGEOL                 For 51
Define SCE_HJ_REGEX                     For 52
Define SCE_HJA_START                    For 55
Define SCE_HJA_DEFAULT                  For 56
Define SCE_HJA_COMMENT                  For 57
Define SCE_HJA_COMMENTLINE              For 58
Define SCE_HJA_COMMENTDOC               For 59
Define SCE_HJA_NUMBER                   For 60
Define SCE_HJA_WORD                     For 61
Define SCE_HJA_KEYWORD                  For 62
Define SCE_HJA_DOUBLESTRING             For 63
Define SCE_HJA_SINGLESTRING             For 64
Define SCE_HJA_SYMBOLS                  For 65
Define SCE_HJA_STRINGEOL                For 66
Define SCE_HJA_REGEX                    For 67
Define SCE_HB_START                     For 70
Define SCE_HB_DEFAULT                   For 71
Define SCE_HB_COMMENTLINE               For 72
Define SCE_HB_NUMBER                    For 73
Define SCE_HB_WORD                      For 74
Define SCE_HB_STRING                    For 75
Define SCE_HB_IDENTIFIER                For 76
Define SCE_HB_STRINGEOL                 For 77
Define SCE_HBA_START                    For 80
Define SCE_HBA_DEFAULT                  For 81
Define SCE_HBA_COMMENTLINE              For 82
Define SCE_HBA_NUMBER                   For 83
Define SCE_HBA_WORD                     For 84
Define SCE_HBA_STRING                   For 85
Define SCE_HBA_IDENTIFIER               For 86
Define SCE_HBA_STRINGEOL                For 87
Define SCE_HP_START                     For 90
Define SCE_HP_DEFAULT                   For 91
Define SCE_HP_COMMENTLINE               For 92
Define SCE_HP_NUMBER                    For 93
Define SCE_HP_STRING                    For 94
Define SCE_HP_CHARACTER                 For 95
Define SCE_HP_WORD                      For 96
Define SCE_HP_TRIPLE                    For 97
Define SCE_HP_TRIPLEDOUBLE              For 98
Define SCE_HP_CLASSNAME                 For 99
Define SCE_HP_DEFNAME                   For 100
Define SCE_HP_OPERATOR                  For 101
Define SCE_HP_IDENTIFIER                For 102
Define SCE_HPHP_COMPLEX_VARIABLE        For 104
Define SCE_HPA_START                    For 105
Define SCE_HPA_DEFAULT                  For 106
Define SCE_HPA_COMMENTLINE              For 107
Define SCE_HPA_NUMBER                   For 108
Define SCE_HPA_STRING                   For 109
Define SCE_HPA_CHARACTER                For 110
Define SCE_HPA_WORD                     For 111
Define SCE_HPA_TRIPLE                   For 112
Define SCE_HPA_TRIPLEDOUBLE             For 113
Define SCE_HPA_CLASSNAME                For 114
Define SCE_HPA_DEFNAME                  For 115
Define SCE_HPA_OPERATOR                 For 116
Define SCE_HPA_IDENTIFIER               For 117
Define SCE_HPHP_DEFAULT                 For 118
Define SCE_HPHP_HSTRING                 For 119
Define SCE_HPHP_SIMPLESTRING            For 120
Define SCE_HPHP_WORD                    For 121
Define SCE_HPHP_NUMBER                  For 122
Define SCE_HPHP_VARIABLE                For 123
Define SCE_HPHP_COMMENT                 For 124
Define SCE_HPHP_COMMENTLINE             For 125
Define SCE_HPHP_HSTRING_VARIABLE        For 126
Define SCE_HPHP_OPERATOR                For 127

// SQL
Define SCE_SQL_DEFAULT                  For 0
Define SCE_SQL_COMMENT                  For 1
Define SCE_SQL_COMMENTLINE              For 2
Define SCE_SQL_COMMENTDOC               For 3
Define SCE_SQL_NUMBER                   For 4
Define SCE_SQL_WORD                     For 5
Define SCE_SQL_STRING                   For 6
Define SCE_SQL_CHARACTER                For 7
Define SCE_SQL_SQLPLUS                  For 8
Define SCE_SQL_SQLPLUS_PROMPT           For 9
Define SCE_SQL_OPERATOR                 For 10
Define SCE_SQL_IDENTIFIER               For 11
Define SCE_SQL_SQLPLUS_COMMENT          For 13
Define SCE_SQL_COMMENTLINEDOC           For 15
Define SCE_SQL_WORD2                    For 16
Define SCE_SQL_COMMENTDOCKEYWORD        For 17
Define SCE_SQL_COMMENTDOCKEYWORDERROR   For 18
Define SCE_SQL_USER1                    For 19
Define SCE_SQL_USER2                    For 20
Define SCE_SQL_USER3                    For 21
Define SCE_SQL_USER4                    For 22
Define SCE_SQL_QUOTEDIDENTIFIER         For 23
Define SCE_SQL_QOPERATOR                For 24

// Properties
Define SCE_PROPS_DEFAULT                For 0
Define SCE_PROPS_COMMENT                For 1
Define SCE_PROPS_SECTION                For 2
Define SCE_PROPS_ASSIGNMENT             For 3
Define SCE_PROPS_DEFVAL                 For 4
Define SCE_PROPS_KEY                    For 5


//Define MARGIN_SCRIPT_FOLD_INDEX For 1 // don't use this strange code word for "code folder margin" use below constants
Define MARGIN_STATUS       For 0  // bookmarks, breakpoints, debug line pointer
Define MARGIN_CHANGED_LINE For 1
Define MARGIN_LINE_NUMBERS For 2
Define MARGIN_CODE_FOLDING For 3


Procedure DevTest String sMethod
  //Send Info_box sMethod "DevTest"
End_Procedure

Function CMSetFindReplaceMRUList Global Pointer pszMRUList Integer bFind Returns Integer
  Send DevTest "CMSetFindReplaceMRUList"
  Function_Return 0
End_Function
Function CMGetFindReplaceMRUList Global Pointer pszMRUList Integer bFind Returns Integer
  Send DevTest "CMGetFindReplaceMRUList"
  Function_Return 0
End_Function
Function CMRegisterLanguage Global Pointer pszName Pointer pLang Returns Integer
  Send DevTest "CMRegisterLanguage"
  Function_Return 0
End_Function
Function CMUnregisterLanguage Global Pointer pszName Returns Integer
  Send DevTest "CMUnregisterLanguage"
  Function_Return 0
End_Function
Function CMGetMacro Global Integer nMacro Pointer pMacroBuff   Returns Integer
  Send DevTest "CMGetMacro"
  Function_Return 0
End_Function
Function CMSetMacro Global Integer nMacro Pointer pMacroBuff  Returns Integer
  Send DevTest "CMSetMacro"
  Function_Return 0
End_Function

// 2.0
Function CMUnregisterAllLanguages Global  Returns Integer
  Send DevTest "CMUnregisterAllLanguages"
  Function_Return 0
End_Function
Function CMGetLanguageDef Global Pointer pszName Pointer pLang   Returns Integer
  Send DevTest "CMGetLanguageDef"
  Function_Return 0
End_Function


// Possible values for piFindWrapMode
Define FindWrapMode_NoWrap      For 1
Define FindWrapMode_NoWrapMsg   For 2
Define FindWrapMode_WrapSilent  For 3
Define FindWrapMode_WrapAsk     For 4


