Use DFAllent.pkg
Use mStrConv.pkg
Use mPointer.pkg
Use tWinStructs.pkg


Define CS_CR   For (Character(13))
Define CS_CRLF For (Character(13)+Character(10))
Define CS_LF   For (Character(10))


Define CMAX_DLL_NAME For SCILEXER.DLL


Define NM_SETFOCUS              For -7
Define NM_KILLFOCUS             For -8

Define WM_CONTEXTMENU           For |CI$007B // 0x007B
Define WM_RBUTTONUP             For |CI$0205 // 0x0205

#IFNDEF GET_CREATEWINDOWEX
  External_Function CreateWindowEx     'CreateWindowExA'      User32.dll  DWord e Pointer c Pointer v DWord w DWord x DWord y DWord wi DWord he Handle hP Handle hm Handle hi Pointer cs Returns Handle
#ENDIF
External_Function GetObject          'GetObjectA'           Gdi32.dll   Handle hGdi Integer iSize Pointer pBuff Returns Integer
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
#COMMAND PUT_POINTER R R R "TO" R "AT" R
    Local_Buffer !1 !2
    Move !3 To !1
    GetAddress Of !1    To !2
    Put !2  To !5 At !7 !8
#ENDCOMMAND


//  Basic signed type used throughout interface
// typedef int Sci_Position;
Define Sci_Position For Integer

//  Unsigned variant used for ILexer::Lex and ILexer::Fold
// typedef unsigned int Sci_PositionU;
Define Sci_PositionU For UInteger

// In a future release the type Sci_PositionCR will be redefined to be 64-bits when Scintilla is built for 64-bits on all platforms.
//
// typedef long Sci_PositionCR;
Define Sci_PositionCR For UInteger


//
//  Struct Sci_NotifyHeader {
//  	/* Compatible with Windows NMHDR.
//  	 * hwndFrom is really an environment specific window handle or pointer
//  	 * but most clients of Scintilla.h do not have this type visible. */
//  	void *hwndFrom;
//  	uptr_t idFrom;
//  	unsigned int code;
//  };
Struct tSci_NotifyHeader
  Pointer  hwndFrom
  Pointer  idFrom
  UInteger uCode
End_Struct
//
//  Struct SCNotification {
//  	Sci_NotifyHeader nmhdr;
//  	Sci_Position position;
//  	/* SCN_STYLENEEDED, SCN_DOUBLECLICK, SCN_MODIFIED, SCN_MARGINCLICK, */
//  	/* SCN_NEEDSHOWN, SCN_DWELLSTART, SCN_DWELLEND, SCN_CALLTIPCLICK, */
//  	/* SCN_HOTSPOTCLICK, SCN_HOTSPOTDOUBLECLICK, SCN_HOTSPOTRELEASECLICK, */
//  	/* SCN_INDICATORCLICK, SCN_INDICATORRELEASE, */
//  	/* SCN_USERLISTSELECTION, SCN_AUTOCSELECTION */
//
//  	int ch;
//  	/* SCN_CHARADDED, SCN_KEY, SCN_AUTOCCOMPLETED, SCN_AUTOCSELECTION, */
//  	/* SCN_USERLISTSELECTION */
//  	int modifiers;
//  	/* SCN_KEY, SCN_DOUBLECLICK, SCN_HOTSPOTCLICK, SCN_HOTSPOTDOUBLECLICK, */
//  	/* SCN_HOTSPOTRELEASECLICK, SCN_INDICATORCLICK, SCN_INDICATORRELEASE, */
//
//  	int modificationType;	/* SCN_MODIFIED */
//  	const Char *text;
//  	/* SCN_MODIFIED, SCN_USERLISTSELECTION, SCN_AUTOCSELECTION, SCN_URIDROPPED */
//
//  	Sci_Position length;		/* SCN_MODIFIED */
//  	Sci_Position linesAdded;	/* SCN_MODIFIED */
//  	int message;	/* SCN_MACRORECORD */
//  	uptr_t wParam;	/* SCN_MACRORECORD */
//  	sptr_t lParam;	/* SCN_MACRORECORD */
//  	Sci_Position line;		/* SCN_MODIFIED */
//  	int foldLevelNow;	/* SCN_MODIFIED */
//  	int foldLevelPrev;	/* SCN_MODIFIED */
//  	int margin;		/* SCN_MARGINCLICK */
//  	int listType;	/* SCN_USERLISTSELECTION */
//  	int x;			/* SCN_DWELLSTART, SCN_DWELLEND */
//  	int y;		/* SCN_DWELLSTART, SCN_DWELLEND */
//  	int token;		/* SCN_MODIFIED with SC_MOD_CONTAINER */
//  	Sci_Position annotationLinesAdded;	/* SCN_MODIFIED with SC_MOD_CHANGEANNOTATION */
//  	int updated;	/* SCN_UPDATEUI */
//  	int listCompletionMethod;
//  	/* SCN_AUTOCSELECTION, SCN_AUTOCCOMPLETED, SCN_USERLISTSELECTION, */
//  };
Struct tSCNotification
  tSci_NotifyHeader nmhdr
  Sci_Position      position
  Integer           ch
  Integer           modifiers
  Integer           modificationType
  Address           Text
  Sci_Position      length
  Sci_Position      linesAdded
  Integer           message
  Pointer           wParam
  Pointer           lParam
  Sci_Position      line
  Integer           foldLevelNow
  Integer           foldLevelPrev
  Integer           margin
  Integer           listType
  Integer           x
  Integer           y
  Integer           token
  Sci_Position      annotationLinesAdded
  Integer           updated
  Integer           listCompletionMethod
End_Struct
//
//
//
//


//
//struct Sci_CharacterRange {
//    Sci_PositionCR cpMin;
//    Sci_PositionCR cpMax;
//};
Struct Sci_CharacterRange
  Sci_PositionCR cpMin
  Sci_PositionCR cpMax
End_Struct
//
//struct Sci_TextRange {
//    struct Sci_CharacterRange chrg;
//    char *lpstrText;
//};
Struct Sci_TextRange
  Sci_CharacterRange chrg
  Pointer lpstrText
End_Struct

//
//struct Sci_TextToFind {
//    struct Sci_CharacterRange chrg;     // range to search
//    const char *lpstrText;                // the search pattern (zero terminated)
//    struct Sci_CharacterRange chrgText; // returned as position of matching text
//};
Struct Sci_TextToFind
  Sci_CharacterRange chrg
  Pointer            pszText
  Sci_CharacterRange chrgText
End_Struct


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
Type CM_POSITION
  Field CM_POSITION.nLine                as Integer  // zero-based line number int
  Field CM_POSITION.nCol                 as Integer  // zero-based *buffer* column number int
End_Type

// Erzeugt einen String und eine Pointer variable, wenn diese noch nicht definiert sind!
// Fueltt mit Line und Col und holt die Addresse in the Pointer
#COMMAND Local_CM_POSITION R R "LINE=" R "COL=" R
    DEFINE_STR_PTR !1 !2
    ZeroType CM_POSITION  To !1         // as a little insurance
    Put !4 To !1 At CM_POSITION.nLine   // Set Line
    Put !6 To !1 At CM_POSITION.nCol    // Set Column
    GetAddress Of !1 To !2
#ENDCOMMAND
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


// Note that the following defines come from the Scintilla.h file in the scintilla project
// These files are generated from the Scintilla.iface file, so we will have to compare that
// file every time!
Define INVALID_POSITION                        For -1
Define SCI_START                               For 2000
Define SCI_OPTIONAL_START                      For 3000
Define SCI_LEXER_START                         For 4000
Define SCI_ADDTEXT                             For 2001
Define SCI_ADDSTYLEDTEXT                       For 2002
Define SCI_INSERTTEXT                          For 2003
Define SCI_CHANGEINSERTION                     For 2672
Define SCI_CLEARALL                            For 2004
Define SCI_DELETERANGE                         For 2645
Define SCI_CLEARDOCUMENTSTYLE                  For 2005
Define SCI_GETLENGTH                           For 2006
Define SCI_GETCHARAT                           For 2007
Define SCI_GETCURRENTPOS                       For 2008
Define SCI_GETANCHOR                           For 2009
Define SCI_GETSTYLEAT                          For 2010
Define SCI_REDO                                For 2011
Define SCI_SETUNDOCOLLECTION                   For 2012
Define SCI_SELECTALL                           For 2013
Define SCI_SETSAVEPOINT                        For 2014
Define SCI_GETSTYLEDTEXT                       For 2015
Define SCI_CANREDO                             For 2016
Define SCI_MARKERLINEFROMHANDLE                For 2017
Define SCI_MARKERDELETEHANDLE                  For 2018
Define SCI_GETUNDOCOLLECTION                   For 2019
Define SCWS_INVISIBLE                          For 0
Define SCWS_VISIBLEALWAYS                      For 1
Define SCWS_VISIBLEAFTERINDENT                 For 2
Define SCWS_VISIBLEONLYININDENT                For 3
Define SCI_GETVIEWWS                           For 2020
Define SCI_SETVIEWWS                           For 2021
Define SCTD_LONGARROW                          For 0
Define SCTD_STRIKEOUT                          For 1
Define SCI_GETTABDRAWMODE                      For 2698
Define SCI_SETTABDRAWMODE                      For 2699
Define SCI_POSITIONFROMPOINT                   For 2022
Define SCI_POSITIONFROMPOINTCLOSE              For 2023
Define SCI_GOTOLINE                            For 2024
Define SCI_GOTOPOS                             For 2025
Define SCI_SETANCHOR                           For 2026
Define SCI_GETCURLINE                          For 2027
Define SCI_GETENDSTYLED                        For 2028
Define SC_EOL_CRLF                             For 0
Define SC_EOL_CR                               For 1
Define SC_EOL_LF                               For 2
Define SCI_CONVERTEOLS                         For 2029
Define SCI_GETEOLMODE                          For 2030
Define SCI_SETEOLMODE                          For 2031
Define SCI_STARTSTYLING                        For 2032
Define SCI_SETSTYLING                          For 2033
Define SCI_GETBUFFEREDDRAW                     For 2034
Define SCI_SETBUFFEREDDRAW                     For 2035
Define SCI_SETTABWIDTH                         For 2036
Define SCI_GETTABWIDTH                         For 2121
Define SCI_CLEARTABSTOPS                       For 2675
Define SCI_ADDTABSTOP                          For 2676
Define SCI_GETNEXTTABSTOP                      For 2677
Define SC_CP_UTF8                              For 65001
Define SCI_SETCODEPAGE                         For 2037
Define SC_IME_WINDOWED                         For 0
Define SC_IME_INLINE                           For 1
Define SCI_GETIMEINTERACTION                   For 2678
Define SCI_SETIMEINTERACTION                   For 2679
Define MARKER_MAX                              For 31
Define SC_MARK_CIRCLE                          For 0
Define SC_MARK_ROUNDRECT                       For 1
Define SC_MARK_ARROW                           For 2
Define SC_MARK_SMALLRECT                       For 3
Define SC_MARK_SHORTARROW                      For 4
Define SC_MARK_EMPTY                           For 5
Define SC_MARK_ARROWDOWN                       For 6
Define SC_MARK_MINUS                           For 7
Define SC_MARK_PLUS                            For 8
Define SC_MARK_VLINE                           For 9
Define SC_MARK_LCORNER                         For 10
Define SC_MARK_TCORNER                         For 11
Define SC_MARK_BOXPLUS                         For 12
Define SC_MARK_BOXPLUSCONNECTED                For 13
Define SC_MARK_BOXMINUS                        For 14
Define SC_MARK_BOXMINUSCONNECTED               For 15
Define SC_MARK_LCORNERCURVE                    For 16
Define SC_MARK_TCORNERCURVE                    For 17
Define SC_MARK_CIRCLEPLUS                      For 18
Define SC_MARK_CIRCLEPLUSCONNECTED             For 19
Define SC_MARK_CIRCLEMINUS                     For 20
Define SC_MARK_CIRCLEMINUSCONNECTED            For 21
Define SC_MARK_BACKGROUND                      For 22
Define SC_MARK_DOTDOTDOT                       For 23
Define SC_MARK_ARROWS                          For 24
Define SC_MARK_PIXMAP                          For 25
Define SC_MARK_FULLRECT                        For 26
Define SC_MARK_LEFTRECT                        For 27
Define SC_MARK_AVAILABLE                       For 28
Define SC_MARK_UNDERLINE                       For 29
Define SC_MARK_RGBAIMAGE                       For 30
Define SC_MARK_BOOKMARK                        For 31
Define SC_MARK_CHARACTER                       For 10000
Define SC_MARKNUM_LINEHIGHLIGHT                For 10
Define SC_MARKNUM_BOOKMARK                     For 11
Define SC_MARKNUM_CHANGEDLINE                  For 12
Define SC_MARKNUM_CHANGEDLINESAVED             For 13
Define SC_MARKNUM_DEBUGBREAKPOINT              For 14
Define SC_MARKNUM_DEBUGCURRENTPOSITION         For 15
Define SC_MARKNUM_FOLDEREND                    For 25
Define SC_MARKNUM_FOLDEROPENMID                For 26
Define SC_MARKNUM_FOLDERMIDTAIL                For 27
Define SC_MARKNUM_FOLDERTAIL                   For 28
Define SC_MARKNUM_FOLDERSUB                    For 29
Define SC_MARKNUM_FOLDER                       For 30
Define SC_MARKNUM_FOLDEROPEN                   For 31
Define SC_MASK_FOLDERS                         For |CI$FE000000 // 0xFE000000
Define SC_MASK_MARGIN                          For |CI$01000000 // 0x01000000 - allow symbol 24
Define SC_MASK_BOOKMARK                        For |CI$00000800 // 0x00000800 - allow symbol 11, start counting from right, each bit is 1, starting from symbol 0
Define SC_MASK_CHANGEDLINEUNSAVED              For |CI$00001000 // 0x00001000 - allow symbol 12 only
Define SC_MASK_CHANGEDLINE                     For |CI$00003000 // 0x00003000 - allow symbol 12 and 13
Define SC_MASK_DEBUGBREAKPOINT                 For |CI$00004000 // 0x00008000 - allow symbol 14
Define SC_MASK_DEBUGCURRENTPOSITION            For |CI$00008000 // 0x00004000 - allow symbol 15
Define SC_MASK_STATUS                          For |CI$0000C800 // 0x00000800 - allow symbol 11, 14 and 15
Define SCI_MARKERDEFINE                        For 2040
Define SCI_MARKERSETFORE                       For 2041
Define SCI_MARKERSETBACK                       For 2042
Define SCI_MARKERSETBACKSELECTED               For 2292
Define SCI_MARKERENABLEHIGHLIGHT               For 2293
Define SCI_MARKERADD                           For 2043
Define SCI_MARKERDELETE                        For 2044
Define SCI_MARKERDELETEALL                     For 2045
Define SCI_MARKERGET                           For 2046
Define SCI_MARKERNEXT                          For 2047
Define SCI_MARKERPREVIOUS                      For 2048
Define SCI_MARKERDEFINEPIXMAP                  For 2049
Define SCI_MARKERADDSET                        For 2466
Define SCI_MARKERSETALPHA                      For 2476
Define SC_MAX_MARGIN                           For 4
Define SC_MARGIN_SYMBOL                        For 0
Define SC_MARGIN_NUMBER                        For 1
Define SC_MARGIN_BACK                          For 2
Define SC_MARGIN_FORE                          For 3
Define SC_MARGIN_TEXT                          For 4
Define SC_MARGIN_RTEXT                         For 5
Define SC_MARGIN_COLOUR                        For 6
Define SCI_SETMARGINTYPEN                      For 2240
Define SCI_GETMARGINTYPEN                      For 2241
Define SCI_SETMARGINWIDTHN                     For 2242
Define SCI_GETMARGINWIDTHN                     For 2243
Define SCI_SETMARGINMASKN                      For 2244
Define SCI_GETMARGINMASKN                      For 2245
Define SCI_SETMARGINSENSITIVEN                 For 2246
Define SCI_GETMARGINSENSITIVEN                 For 2247
Define SCI_SETMARGINCURSORN                    For 2248
Define SCI_GETMARGINCURSORN                    For 2249
Define SCI_SETMARGINBACKN                      For 2250
Define SCI_GETMARGINBACKN                      For 2251
Define SCI_SETMARGINS                          For 2252
Define SCI_GETMARGINS                          For 2253
Define STYLE_DEFAULT                           For 32
Define STYLE_LINENUMBER                        For 33
Define STYLE_BRACELIGHT                        For 34
Define STYLE_BRACEBAD                          For 35
Define STYLE_CONTROLCHAR                       For 36
Define STYLE_INDENTGUIDE                       For 37
Define STYLE_CALLTIP                           For 38
Define STYLE_FOLDDISPLAYTEXT                   For 39
Define STYLE_AUTOCOMPLETE                      For 40
Define STYLE_LASTPREDEFINED                    For 40
Define STYLE_MAX                               For 255
Define SC_CHARSET_ANSI                         For 0
Define SC_CHARSET_DEFAULT                      For 1
Define SC_CHARSET_BALTIC                       For 186
Define SC_CHARSET_CHINESEBIG5                  For 136
Define SC_CHARSET_EASTEUROPE                   For 238
Define SC_CHARSET_GB2312                       For 134
Define SC_CHARSET_GREEK                        For 161
Define SC_CHARSET_HANGUL                       For 129
Define SC_CHARSET_MAC                          For 77
Define SC_CHARSET_OEM                          For 255
Define SC_CHARSET_RUSSIAN                      For 204
Define SC_CHARSET_OEM866                       For 866
Define SC_CHARSET_CYRILLIC                     For 1251
Define SC_CHARSET_SHIFTJIS                     For 128
Define SC_CHARSET_SYMBOL                       For 2
Define SC_CHARSET_TURKISH                      For 162
Define SC_CHARSET_JOHAB                        For 130
Define SC_CHARSET_HEBREW                       For 177
Define SC_CHARSET_ARABIC                       For 178
Define SC_CHARSET_VIETNAMESE                   For 163
Define SC_CHARSET_THAI                         For 222
Define SC_CHARSET_8859_15                      For 1000
Define SCI_STYLECLEARALL                       For 2050
Define SCI_STYLESETFORE                        For 2051
Define SCI_STYLESETBACK                        For 2052
Define SCI_STYLESETBOLD                        For 2053
Define SCI_STYLESETITALIC                      For 2054
Define SCI_STYLESETSIZE                        For 2055
Define SCI_STYLESETFONT                        For 2056
Define SCI_STYLESETEOLFILLED                   For 2057
Define SCI_STYLERESETDEFAULT                   For 2058
Define SCI_STYLESETUNDERLINE                   For 2059
Define SC_CASE_MIXED                           For 0
Define SC_CASE_UPPER                           For 1
Define SC_CASE_LOWER                           For 2
Define SC_CASE_CAMEL                           For 3
Define SCI_STYLEGETFORE                        For 2481
Define SCI_STYLEGETBACK                        For 2482
Define SCI_STYLEGETBOLD                        For 2483
Define SCI_STYLEGETITALIC                      For 2484
Define SCI_STYLEGETSIZE                        For 2485
Define SCI_STYLEGETFONT                        For 2486
Define SCI_STYLEGETEOLFILLED                   For 2487
Define SCI_STYLEGETUNDERLINE                   For 2488
Define SCI_STYLEGETCASE                        For 2489
Define SCI_STYLEGETCHARACTERSET                For 2490
Define SCI_STYLEGETVISIBLE                     For 2491
Define SCI_STYLEGETCHANGEABLE                  For 2492
Define SCI_STYLEGETHOTSPOT                     For 2493
Define SCI_STYLESETCASE                        For 2060
Define SC_FONT_SIZE_MULTIPLIER                 For 100
Define SCI_STYLESETSIZEFRACTIONAL              For 2061
Define SCI_STYLEGETSIZEFRACTIONAL              For 2062
Define SC_WEIGHT_NORMAL                        For 400
Define SC_WEIGHT_SEMIBOLD                      For 600
Define SC_WEIGHT_BOLD                          For 700
Define SCI_STYLESETWEIGHT                      For 2063
Define SCI_STYLEGETWEIGHT                      For 2064
Define SCI_STYLESETCHARACTERSET                For 2066
Define SCI_STYLESETHOTSPOT                     For 2409
Define SCI_SETSELFORE                          For 2067
Define SCI_SETSELBACK                          For 2068
Define SCI_GETSELALPHA                         For 2477
Define SCI_SETSELALPHA                         For 2478
Define SCI_GETSELEOLFILLED                     For 2479
Define SCI_SETSELEOLFILLED                     For 2480
Define SCI_SETCARETFORE                        For 2069
Define SCI_ASSIGNCMDKEY                        For 2070
Define SCI_CLEARCMDKEY                         For 2071
Define SCI_CLEARALLCMDKEYS                     For 2072
Define SCI_SETSTYLINGEX                        For 2073
Define SCI_STYLESETVISIBLE                     For 2074
Define SCI_GETCARETPERIOD                      For 2075
Define SCI_SETCARETPERIOD                      For 2076
Define SCI_SETWORDCHARS                        For 2077
Define SCI_GETWORDCHARS                        For 2646
Define SCI_BEGINUNDOACTION                     For 2078
Define SCI_ENDUNDOACTION                       For 2079
Define INDIC_PLAIN                             For 0
Define INDIC_SQUIGGLE                          For 1
Define INDIC_TT                                For 2
Define INDIC_DIAGONAL                          For 3
Define INDIC_STRIKE                            For 4
Define INDIC_HIDDEN                            For 5
Define INDIC_BOX                               For 6
Define INDIC_ROUNDBOX                          For 7
Define INDIC_STRAIGHTBOX                       For 8
Define INDIC_DASH                              For 9
Define INDIC_DOTS                              For 10
Define INDIC_SQUIGGLELOW                       For 11
Define INDIC_DOTBOX                            For 12
Define INDIC_SQUIGGLEPIXMAP                    For 13
Define INDIC_COMPOSITIONTHICK                  For 14
Define INDIC_COMPOSITIONTHIN                   For 15
Define INDIC_FULLBOX                           For 16
Define INDIC_TEXTFORE                          For 17
Define INDIC_POINT                             For 18
Define INDIC_POINTCHARACTER                    For 19
Define INDIC_IME                               For 32
Define INDIC_IME_MAX                           For 35
Define INDIC_MAX                               For 35
Define INDIC_CONTAINER                         For 8
Define INDIC0_MASK                             For |CI$20  // 0x20
Define INDIC1_MASK                             For |CI$40  // 0x40
Define INDIC2_MASK                             For |CI$80  // 0x80
Define INDICS_MASK                             For |CI$E0  // 0xE0
Define SCI_INDICSETSTYLE                       For 2080
Define SCI_INDICGETSTYLE                       For 2081
Define SCI_INDICSETFORE                        For 2082
Define SCI_INDICGETFORE                        For 2083
Define SCI_INDICSETUNDER                       For 2510
Define SCI_INDICGETUNDER                       For 2511
Define SCI_INDICSETHOVERSTYLE                  For 2680
Define SCI_INDICGETHOVERSTYLE                  For 2681
Define SCI_INDICSETHOVERFORE                   For 2682
Define SCI_INDICGETHOVERFORE                   For 2683
Define SC_INDICVALUEBIT                        For |CI$1000000  // 0x1000000
Define SC_INDICVALUEMASK                       For |CI$FFFFFF   // 0xFFFFFF
Define SC_INDICFLAG_VALUEFORE                  For 1
Define SCI_INDICSETFLAGS                       For 2684
Define SCI_INDICGETFLAGS                       For 2685
Define SCI_SETWHITESPACEFORE                   For 2084
Define SCI_SETWHITESPACEBACK                   For 2085
Define SCI_SETWHITESPACESIZE                   For 2086
Define SCI_GETWHITESPACESIZE                   For 2087
Define SCI_SETSTYLEBITS                        For 2090
Define SCI_GETSTYLEBITS                        For 2091
Define SCI_SETLINESTATE                        For 2092
Define SCI_GETLINESTATE                        For 2093
Define SCI_GETMAXLINESTATE                     For 2094
Define SCI_GETCARETLINEVISIBLE                 For 2095
Define SCI_SETCARETLINEVISIBLE                 For 2096
Define SCI_GETCARETLINEBACK                    For 2097
Define SCI_SETCARETLINEBACK                    For 2098
Define SCI_STYLESETCHANGEABLE                  For 2099
Define SCI_AUTOCSHOW                           For 2100
Define SCI_AUTOCCANCEL                         For 2101
Define SCI_AUTOCACTIVE                         For 2102
Define SCI_AUTOCPOSSTART                       For 2103
Define SCI_AUTOCCOMPLETE                       For 2104
Define SCI_AUTOCSTOPS                          For 2105
Define SCI_AUTOCSETSEPARATOR                   For 2106
Define SCI_AUTOCGETSEPARATOR                   For 2107
Define SCI_AUTOCSELECT                         For 2108
Define SCI_AUTOCSETCANCELATSTART               For 2110
Define SCI_AUTOCGETCANCELATSTART               For 2111
Define SCI_AUTOCSETFILLUPS                     For 2112
Define SCI_AUTOCSETCHOOSESINGLE                For 2113
Define SCI_AUTOCGETCHOOSESINGLE                For 2114
Define SCI_AUTOCSETIGNORECASE                  For 2115
Define SCI_AUTOCGETIGNORECASE                  For 2116
Define SCI_USERLISTSHOW                        For 2117
Define SCI_AUTOCSETAUTOHIDE                    For 2118
Define SCI_AUTOCGETAUTOHIDE                    For 2119
Define SCI_AUTOCUSESTYLE                       For 2120
Define SCI_AUTOCSETDROPRESTOFWORD              For 2270
Define SCI_AUTOCGETDROPRESTOFWORD              For 2271
Define SCI_REGISTERIMAGE                       For 2405
Define SCI_CLEARREGISTEREDIMAGES               For 2408
Define SCI_AUTOCGETTYPESEPARATOR               For 2285
Define SCI_AUTOCSETTYPESEPARATOR               For 2286
Define SCI_AUTOCSETMAXWIDTH                    For 2208
Define SCI_AUTOCGETMAXWIDTH                    For 2209
Define SCI_AUTOCSETMAXHEIGHT                   For 2210
Define SCI_AUTOCGETMAXHEIGHT                   For 2211
Define SCI_SETINDENT                           For 2122
Define SCI_GETINDENT                           For 2123
Define SCI_SETUSETABS                          For 2124
Define SCI_GETUSETABS                          For 2125
Define SCI_SETLINEINDENTATION                  For 2126
Define SCI_GETLINEINDENTATION                  For 2127
Define SCI_GETLINEINDENTPOSITION               For 2128
Define SCI_GETCOLUMN                           For 2129
Define SCI_COUNTCHARACTERS                     For 2633
Define SCI_SETHSCROLLBAR                       For 2130
Define SCI_GETHSCROLLBAR                       For 2131
Define SC_IV_NONE                              For 0
Define SC_IV_REAL                              For 1
Define SC_IV_LOOKFORWARD                       For 2
Define SC_IV_LOOKBOTH                          For 3
Define SCI_SETINDENTATIONGUIDES                For 2132
Define SCI_GETINDENTATIONGUIDES                For 2133
Define SCI_SETHIGHLIGHTGUIDE                   For 2134
Define SCI_GETHIGHLIGHTGUIDE                   For 2135
Define SCI_GETLINEENDPOSITION                  For 2136
Define SCI_GETCODEPAGE                         For 2137
Define SCI_GETCARETFORE                        For 2138
Define SCI_GETREADONLY                         For 2140
Define SCI_SETCURRENTPOS                       For 2141
Define SCI_SETSELECTIONSTART                   For 2142
Define SCI_GETSELECTIONSTART                   For 2143
Define SCI_SETSELECTIONEND                     For 2144
Define SCI_GETSELECTIONEND                     For 2145
Define SCI_SETEMPTYSELECTION                   For 2556
Define SCI_SETPRINTMAGNIFICATION               For 2146
Define SCI_GETPRINTMAGNIFICATION               For 2147
Define SC_PRINT_NORMAL                         For 0
Define SC_PRINT_INVERTLIGHT                    For 1
Define SC_PRINT_BLACKONWHITE                   For 2
Define SC_PRINT_COLOURONWHITE                  For 3
Define SC_PRINT_COLOURONWHITEDEFAULTBG         For 4
Define SCI_SETPRINTCOLOURMODE                  For 2148
Define SCI_GETPRINTCOLOURMODE                  For 2149
Define SCFIND_WHOLEWORD                        For |CI$02    // 0x2
Define SCFIND_MATCHCASE                        For |CI$04    // 0x4
Define SCFIND_WORDSTART                        For |CI$00100000 // 0x00100000
Define SCFIND_REGEXP                           For |CI$00200000 // 0x00200000
Define SCFIND_POSIX                            For |CI$00400000 // 0x00400000
Define SCFIND_CXX11REGEX                       For |CI$00800000 // 0x00800000
Define SCI_FINDTEXT                            For 2150
Define SCI_FORMATRANGE                         For 2151
Define SCI_GETFIRSTVISIBLELINE                 For 2152
Define SCI_GETLINE                             For 2153
Define SCI_GETLINECOUNT                        For 2154
Define SCI_SETMARGINLEFT                       For 2155
Define SCI_GETMARGINLEFT                       For 2156
Define SCI_SETMARGINRIGHT                      For 2157
Define SCI_GETMARGINRIGHT                      For 2158
Define SCI_GETMODIFY                           For 2159
Define SCI_SETSEL                              For 2160
Define SCI_GETSELTEXT                          For 2161
Define SCI_GETTEXTRANGE                        For 2162
Define SCI_HIDESELECTION                       For 2163
Define SCI_POINTXFROMPOSITION                  For 2164
Define SCI_POINTYFROMPOSITION                  For 2165
Define SCI_LINEFROMPOSITION                    For 2166
Define SCI_POSITIONFROMLINE                    For 2167
Define SCI_LINESCROLL                          For 2168
Define SCI_SCROLLCARET                         For 2169
Define SCI_SCROLLRANGE                         For 2569
Define SCI_REPLACESEL                          For 2170
Define SCI_SETREADONLY                         For 2171
Define SCI_NULL                                For 2172
Define SCI_CANPASTE                            For 2173
Define SCI_CANUNDO                             For 2174
Define SCI_EMPTYUNDOBUFFER                     For 2175
Define SCI_UNDO                                For 2176
Define SCI_CUT                                 For 2177
Define SCI_COPY                                For 2178
Define SCI_PASTE                               For 2179
Define SCI_CLEAR                               For 2180
Define SCI_SETTEXT                             For 2181
Define SCI_GETTEXT                             For 2182
Define SCI_GETTEXTLENGTH                       For 2183
Define SCI_GETDIRECTFUNCTION                   For 2184
Define SCI_GETDIRECTPOINTER                    For 2185
Define SCI_SETOVERTYPE                         For 2186
Define SCI_GETOVERTYPE                         For 2187
Define SCI_SETCARETWIDTH                       For 2188
Define SCI_GETCARETWIDTH                       For 2189
Define SCI_SETTARGETSTART                      For 2190
Define SCI_GETTARGETSTART                      For 2191
Define SCI_SETTARGETEND                        For 2192
Define SCI_GETTARGETEND                        For 2193
Define SCI_SETTARGETRANGE                      For 2686
Define SCI_GETTARGETTEXT                       For 2687
Define SCI_TARGETFROMSELECTION                 For 2287
Define SCI_TARGETWHOLEDOCUMENT                 For 2690
Define SCI_REPLACETARGET                       For 2194
Define SCI_REPLACETARGETRE                     For 2195
Define SCI_SEARCHINTARGET                      For 2197
Define SCI_SETSEARCHFLAGS                      For 2198
Define SCI_GETSEARCHFLAGS                      For 2199
Define SCI_CALLTIPSHOW                         For 2200
Define SCI_CALLTIPCANCEL                       For 2201
Define SCI_CALLTIPACTIVE                       For 2202
Define SCI_CALLTIPPOSSTART                     For 2203
Define SCI_CALLTIPSETPOSSTART                  For 2214
Define SCI_CALLTIPSETHLT                       For 2204
Define SCI_CALLTIPSETBACK                      For 2205
Define SCI_CALLTIPSETFORE                      For 2206
Define SCI_CALLTIPSETFOREHLT                   For 2207
Define SCI_CALLTIPUSESTYLE                     For 2212
Define SCI_CALLTIPSETPOSITION                  For 2213
Define SCI_VISIBLEFROMDOCLINE                  For 2220
Define SCI_DOCLINEFROMVISIBLE                  For 2221
Define SCI_WRAPCOUNT                           For 2235
Define SC_FOLDLEVELBASE                        For |CI$000400  // $0x400
Define SC_FOLDLEVELWHITEFLAG                   For |CI$001000  // $0x1000
Define SC_FOLDLEVELHEADERFLAG                  For |CI$002000  // $0x2000
Define SC_FOLDLEVELNUMBERMASK                  For |CI$000FFF  // $0x0FFF
Define SCI_SETFOLDLEVEL                        For 2222
Define SCI_GETFOLDLEVEL                        For 2223
Define SCI_GETLASTCHILD                        For 2224
Define SCI_GETFOLDPARENT                       For 2225
Define SCI_SHOWLINES                           For 2226
Define SCI_HIDELINES                           For 2227
Define SCI_GETLINEVISIBLE                      For 2228
Define SCI_GETALLLINESVISIBLE                  For 2236
Define SCI_SETFOLDEXPANDED                     For 2229
Define SCI_GETFOLDEXPANDED                     For 2230
Define SCI_TOGGLEFOLD                          For 2231
Define SCI_TOGGLEFOLDSHOWTEXT                  For 2700
Define SC_FOLDDISPLAYTEXT_HIDDEN               For 0
Define SC_FOLDDISPLAYTEXT_STANDARD             For 1
Define SC_FOLDDISPLAYTEXT_BOXED                For 2
Define SCI_FOLDDISPLAYTEXTSETSTYLE             For 2701
Define SC_FOLDACTION_CONTRACT                  For 0
Define SC_FOLDACTION_EXPAND                    For 1
Define SC_FOLDACTION_TOGGLE                    For 2
Define SCI_FOLDLINE                            For 2237
Define SCI_FOLDCHILDREN                        For 2238
Define SCI_EXPANDCHILDREN                      For 2239
Define SCI_FOLDALL                             For 2662
Define SCI_ENSUREVISIBLE                       For 2232
Define SC_AUTOMATICFOLD_SHOW                   For |CI$0001  // $0x0001
Define SC_AUTOMATICFOLD_CLICK                  For |CI$0002  // $0x0002
Define SC_AUTOMATICFOLD_CHANGE                 For |CI$0004  // $0x0004
Define SCI_SETAUTOMATICFOLD                    For 2663
Define SCI_GETAUTOMATICFOLD                    For 2664
Define SC_FOLDFLAG_LINEBEFORE_EXPANDED         For |CI$0002  // $0x0002
Define SC_FOLDFLAG_LINEBEFORE_CONTRACTED       For |CI$0004 // $0x0004
Define SC_FOLDFLAG_LINEAFTER_EXPANDED          For |CI$0008  // $0x0008
Define SC_FOLDFLAG_LINEAFTER_CONTRACTED        For |CI$0010  // $0x0010
Define SC_FOLDFLAG_LEVELNUMBERS                For |CI$0040  // $0x0040
Define SC_FOLDFLAG_LINESTATE                   For |CI$0080  // $0x0080
Define SCI_SETFOLDFLAGS                        For 2233
Define SCI_ENSUREVISIBLEENFORCEPOLICY          For 2234
Define SCI_SETTABINDENTS                       For 2260
Define SCI_GETTABINDENTS                       For 2261
Define SCI_SETBACKSPACEUNINDENTS               For 2262
Define SCI_GETBACKSPACEUNINDENTS               For 2263
Define SC_TIME_FOREVER                         For 10000000
Define SCI_SETMOUSEDWELLTIME                   For 2264
Define SCI_GETMOUSEDWELLTIME                   For 2265
Define SCI_WORDSTARTPOSITION                   For 2266
Define SCI_WORDENDPOSITION                     For 2267
Define SCI_ISRANGEWORD                         For 2691
Define SC_IDLESTYLING_NONE                     For 0
Define SC_IDLESTYLING_TOVISIBLE                For 1
Define SC_IDLESTYLING_AFTERVISIBLE             For 2
Define SC_IDLESTYLING_ALL                      For 3
Define SCI_SETIDLESTYLING                      For 2692
Define SCI_GETIDLESTYLING                      For 2693
Define SC_WRAP_NONE                            For 0
Define SC_WRAP_WORD                            For 1
Define SC_WRAP_CHAR                            For 2
Define SC_WRAP_WHITESPACE                      For 3
Define SCI_SETWRAPMODE                         For 2268
Define SCI_GETWRAPMODE                         For 2269
Define SC_WRAPVISUALFLAG_NONE                  For |CI$0000  // $0x0000
Define SC_WRAPVISUALFLAG_END                   For |CI$0001  // $0x0001
Define SC_WRAPVISUALFLAG_START                 For |CI$0002  // $0x0002
Define SC_WRAPVISUALFLAG_MARGIN                For |CI$0004  // $0x0004
Define SCI_SETWRAPVISUALFLAGS                  For 2460
Define SCI_GETWRAPVISUALFLAGS                  For 2461
Define SC_WRAPVISUALFLAGLOC_DEFAULT            For |CI$0000  // $0x0000
Define SC_WRAPVISUALFLAGLOC_END_BY_TEXT        For |CI$0001  // $0x0001
Define SC_WRAPVISUALFLAGLOC_START_BY_TEXT      For |CI$0002  // $0x0002
Define SCI_SETWRAPVISUALFLAGSLOCATION          For 2462
Define SCI_GETWRAPVISUALFLAGSLOCATION          For 2463
Define SCI_SETWRAPSTARTINDENT                  For 2464
Define SCI_GETWRAPSTARTINDENT                  For 2465
Define SC_WRAPINDENT_FIXED                     For 0
Define SC_WRAPINDENT_SAME                      For 1
Define SC_WRAPINDENT_INDENT                    For 2
Define SCI_SETWRAPINDENTMODE                   For 2472
Define SCI_GETWRAPINDENTMODE                   For 2473
Define SC_CACHE_NONE                           For 0
Define SC_CACHE_CARET                          For 1
Define SC_CACHE_PAGE                           For 2
Define SC_CACHE_DOCUMENT                       For 3
Define SCI_SETLAYOUTCACHE                      For 2272
Define SCI_GETLAYOUTCACHE                      For 2273
Define SCI_SETSCROLLWIDTH                      For 2274
Define SCI_GETSCROLLWIDTH                      For 2275
Define SCI_SETSCROLLWIDTHTRACKING              For 2516
Define SCI_GETSCROLLWIDTHTRACKING              For 2517
Define SCI_TEXTWIDTH                           For 2276
Define SCI_SETENDATLASTLINE                    For 2277
Define SCI_GETENDATLASTLINE                    For 2278
Define SCI_TEXTHEIGHT                          For 2279
Define SCI_SETVSCROLLBAR                       For 2280
Define SCI_GETVSCROLLBAR                       For 2281
Define SCI_APPENDTEXT                          For 2282
Define SCI_GETTWOPHASEDRAW                     For 2283
Define SCI_SETTWOPHASEDRAW                     For 2284
Define SC_PHASES_ONE                           For 0
Define SC_PHASES_TWO                           For 1
Define SC_PHASES_MULTIPLE                      For 2
Define SCI_GETPHASESDRAW                       For 2673
Define SCI_SETPHASESDRAW                       For 2674
Define SC_EFF_QUALITY_MASK                     For |CI$0F  // $0xF
Define SC_EFF_QUALITY_DEFAULT                  For 0
Define SC_EFF_QUALITY_NON_ANTIALIASED          For 1
Define SC_EFF_QUALITY_ANTIALIASED              For 2
Define SC_EFF_QUALITY_LCD_OPTIMIZED            For 3
Define SCI_SETFONTQUALITY                      For 2611
Define SCI_GETFONTQUALITY                      For 2612
Define SCI_SETFIRSTVISIBLELINE                 For 2613
Define SC_MULTIPASTE_ONCE                      For 0
Define SC_MULTIPASTE_EACH                      For 1
Define SCI_SETMULTIPASTE                       For 2614
Define SCI_GETMULTIPASTE                       For 2615
Define SCI_GETTAG                              For 2616
Define SCI_LINESJOIN                           For 2288
Define SCI_LINESSPLIT                          For 2289
Define SCI_SETFOLDMARGINCOLOUR                 For 2290
Define SCI_SETFOLDMARGINHICOLOUR               For 2291
Define SCI_LINEDOWN                            For 2300
Define SCI_LINEDOWNEXTEND                      For 2301
Define SCI_LINEUP                              For 2302
Define SCI_LINEUPEXTEND                        For 2303
Define SCI_CHARLEFT                            For 2304
Define SCI_CHARLEFTEXTEND                      For 2305
Define SCI_CHARRIGHT                           For 2306
Define SCI_CHARRIGHTEXTEND                     For 2307
Define SCI_WORDLEFT                            For 2308
Define SCI_WORDLEFTEXTEND                      For 2309
Define SCI_WORDRIGHT                           For 2310
Define SCI_WORDRIGHTEXTEND                     For 2311
Define SCI_HOME                                For 2312
Define SCI_HOMEEXTEND                          For 2313
Define SCI_LINEEND                             For 2314
Define SCI_LINEENDEXTEND                       For 2315
Define SCI_DOCUMENTSTART                       For 2316
Define SCI_DOCUMENTSTARTEXTEND                 For 2317
Define SCI_DOCUMENTEND                         For 2318
Define SCI_DOCUMENTENDEXTEND                   For 2319
Define SCI_PAGEUP                              For 2320
Define SCI_PAGEUPEXTEND                        For 2321
Define SCI_PAGEDOWN                            For 2322
Define SCI_PAGEDOWNEXTEND                      For 2323
Define SCI_EDITTOGGLEOVERTYPE                  For 2324
Define SCI_CANCEL                              For 2325
Define SCI_DELETEBACK                          For 2326
Define SCI_TAB                                 For 2327
Define SCI_BACKTAB                             For 2328
Define SCI_NEWLINE                             For 2329
Define SCI_FORMFEED                            For 2330
Define SCI_VCHOME                              For 2331
Define SCI_VCHOMEEXTEND                        For 2332
Define SCI_ZOOMIN                              For 2333
Define SCI_ZOOMOUT                             For 2334
Define SCI_DELWORDLEFT                         For 2335
Define SCI_DELWORDRIGHT                        For 2336
Define SCI_DELWORDRIGHTEND                     For 2518
Define SCI_LINECUT                             For 2337
Define SCI_LINEDELETE                          For 2338
Define SCI_LINETRANSPOSE                       For 2339
Define SCI_LINEDUPLICATE                       For 2404
Define SCI_LOWERCASE                           For 2340
Define SCI_UPPERCASE                           For 2341
Define SCI_LINESCROLLDOWN                      For 2342
Define SCI_LINESCROLLUP                        For 2343
Define SCI_DELETEBACKNOTLINE                   For 2344
Define SCI_HOMEDISPLAY                         For 2345
Define SCI_HOMEDISPLAYEXTEND                   For 2346
Define SCI_LINEENDDISPLAY                      For 2347
Define SCI_LINEENDDISPLAYEXTEND                For 2348
Define SCI_HOMEWRAP                            For 2349
Define SCI_HOMEWRAPEXTEND                      For 2450
Define SCI_LINEENDWRAP                         For 2451
Define SCI_LINEENDWRAPEXTEND                   For 2452
Define SCI_VCHOMEWRAP                          For 2453
Define SCI_VCHOMEWRAPEXTEND                    For 2454
Define SCI_LINECOPY                            For 2455
Define SCI_MOVECARETINSIDEVIEW                 For 2401
Define SCI_LINELENGTH                          For 2350
Define SCI_BRACEHIGHLIGHT                      For 2351
Define SCI_BRACEHIGHLIGHTINDICATOR             For 2498
Define SCI_BRACEBADLIGHT                       For 2352
Define SCI_BRACEBADLIGHTINDICATOR              For 2499
Define SCI_BRACEMATCH                          For 2353
Define SCI_GETVIEWEOL                          For 2355
Define SCI_SETVIEWEOL                          For 2356
Define SCI_GETDOCPOINTER                       For 2357
Define SCI_SETDOCPOINTER                       For 2358
Define SCI_SETMODEVENTMASK                     For 2359
Define EDGE_NONE                               For 0
Define EDGE_LINE                               For 1
Define EDGE_BACKGROUND                         For 2
Define EDGE_MULTILINE                          For 3
Define SCI_GETEDGECOLUMN                       For 2360
Define SCI_SETEDGECOLUMN                       For 2361
Define SCI_GETEDGEMODE                         For 2362
Define SCI_SETEDGEMODE                         For 2363
Define SCI_GETEDGECOLOUR                       For 2364
Define SCI_SETEDGECOLOUR                       For 2365
Define SCI_MULTIEDGEADDLINE                    For 2694
Define SCI_MULTIEDGECLEARALL                   For 2695
Define SCI_SEARCHANCHOR                        For 2366
Define SCI_SEARCHNEXT                          For 2367
Define SCI_SEARCHPREV                          For 2368
Define SCI_LINESONSCREEN                       For 2370
Define SC_POPUP_NEVER                          For 0
Define SC_POPUP_ALL                            For 1
Define SC_POPUP_TEXT                           For 2
Define SCI_USEPOPUP                            For 2371
Define SCI_SELECTIONISRECTANGLE                For 2372
Define SCI_SETZOOM                             For 2373
Define SCI_GETZOOM                             For 2374
Define SCI_CREATEDOCUMENT                      For 2375
Define SCI_ADDREFDOCUMENT                      For 2376
Define SCI_RELEASEDOCUMENT                     For 2377
Define SCI_GETMODEVENTMASK                     For 2378
Define SCI_SETFOCUS                            For 2380
Define SCI_GETFOCUS                            For 2381
Define SC_STATUS_OK                            For 0
Define SC_STATUS_FAILURE                       For 1
Define SC_STATUS_BADALLOC                      For 2
Define SC_STATUS_WARN_START                    For 1000
Define SC_STATUS_WARN_REGEX                    For 1001
Define SCI_SETSTATUS                           For 2382
Define SCI_GETSTATUS                           For 2383
Define SCI_SETMOUSEDOWNCAPTURES                For 2384
Define SCI_GETMOUSEDOWNCAPTURES                For 2385
Define SCI_SETMOUSEWHEELCAPTURES               For 2696
Define SCI_GETMOUSEWHEELCAPTURES               For 2697
Define SC_CURSORNORMAL                         For 1
Define SC_CURSORARROW                          For 2
Define SC_CURSORWAIT                           For 4
Define SC_CURSORREVERSEARROW                   For 7
Define SCI_SETCURSOR                           For 2386
Define SCI_GETCURSOR                           For 2387
Define SCI_SETCONTROLCHARSYMBOL                For 2388
Define SCI_GETCONTROLCHARSYMBOL                For 2389
Define SCI_WORDPARTLEFT                        For 2390
Define SCI_WORDPARTLEFTEXTEND                  For 2391
Define SCI_WORDPARTRIGHT                       For 2392
Define SCI_WORDPARTRIGHTEXTEND                 For 2393
Define VISIBLE_SLOP                            For |CI$01  // $0x01
Define VISIBLE_STRICT                          For |CI$04  // $0x04
Define SCI_SETVISIBLEPOLICY                    For 2394
Define SCI_DELLINELEFT                         For 2395
Define SCI_DELLINERIGHT                        For 2396
Define SCI_SETXOFFSET                          For 2397
Define SCI_GETXOFFSET                          For 2398
Define SCI_CHOOSECARETX                        For 2399
Define SCI_GRABFOCUS                           For 2400
Define CARET_SLOP                              For |CI$01  // $0x01
Define CARET_STRICT                            For |CI$04  // $0x04
Define CARET_JUMPS                             For |CI$10  // $0x10
Define CARET_EVEN                              For |CI$08  // $0x08
Define SCI_SETXCARETPOLICY                     For 2402
Define SCI_SETYCARETPOLICY                     For 2403
Define SCI_SETPRINTWRAPMODE                    For 2406
Define SCI_GETPRINTWRAPMODE                    For 2407
Define SCI_SETHOTSPOTACTIVEFORE                For 2410
Define SCI_GETHOTSPOTACTIVEFORE                For 2494
Define SCI_SETHOTSPOTACTIVEBACK                For 2411
Define SCI_GETHOTSPOTACTIVEBACK                For 2495
Define SCI_SETHOTSPOTACTIVEUNDERLINE           For 2412
Define SCI_GETHOTSPOTACTIVEUNDERLINE           For 2496
Define SCI_SETHOTSPOTSINGLELINE                For 2421
Define SCI_GETHOTSPOTSINGLELINE                For 2497
Define SCI_PARADOWN                            For 2413
Define SCI_PARADOWNEXTEND                      For 2414
Define SCI_PARAUP                              For 2415
Define SCI_PARAUPEXTEND                        For 2416
Define SCI_POSITIONBEFORE                      For 2417
Define SCI_POSITIONAFTER                       For 2418
Define SCI_POSITIONRELATIVE                    For 2670
Define SCI_COPYRANGE                           For 2419
Define SCI_COPYTEXT                            For 2420
Define SC_SEL_STREAM                           For 0
Define SC_SEL_RECTANGLE                        For 1
Define SC_SEL_LINES                            For 2
Define SC_SEL_THIN                             For 3
Define SCI_SETSELECTIONMODE                    For 2422
Define SCI_GETSELECTIONMODE                    For 2423
Define SCI_GETLINESELSTARTPOSITION             For 2424
Define SCI_GETLINESELENDPOSITION               For 2425
Define SCI_LINEDOWNRECTEXTEND                  For 2426
Define SCI_LINEUPRECTEXTEND                    For 2427
Define SCI_CHARLEFTRECTEXTEND                  For 2428
Define SCI_CHARRIGHTRECTEXTEND                 For 2429
Define SCI_HOMERECTEXTEND                      For 2430
Define SCI_VCHOMERECTEXTEND                    For 2431
Define SCI_LINEENDRECTEXTEND                   For 2432
Define SCI_PAGEUPRECTEXTEND                    For 2433
Define SCI_PAGEDOWNRECTEXTEND                  For 2434
Define SCI_STUTTEREDPAGEUP                     For 2435
Define SCI_STUTTEREDPAGEUPEXTEND               For 2436
Define SCI_STUTTEREDPAGEDOWN                   For 2437
Define SCI_STUTTEREDPAGEDOWNEXTEND             For 2438
Define SCI_WORDLEFTEND                         For 2439
Define SCI_WORDLEFTENDEXTEND                   For 2440
Define SCI_WORDRIGHTEND                        For 2441
Define SCI_WORDRIGHTENDEXTEND                  For 2442
Define SCI_SETWHITESPACECHARS                  For 2443
Define SCI_GETWHITESPACECHARS                  For 2647
Define SCI_SETPUNCTUATIONCHARS                 For 2648
Define SCI_GETPUNCTUATIONCHARS                 For 2649
Define SCI_SETCHARSDEFAULT                     For 2444
Define SCI_AUTOCGETCURRENT                     For 2445
Define SCI_AUTOCGETCURRENTTEXT                 For 2610
Define SC_CASEINSENSITIVEBEHAVIOUR_RESPECTCASE For 0
Define SC_CASEINSENSITIVEBEHAVIOUR_IGNORECASE  For 1
Define SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR    For 2634
Define SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR    For 2635
Define SC_MULTIAUTOC_ONCE                      For 0
Define SC_MULTIAUTOC_EACH                      For 1
Define SCI_AUTOCSETMULTI                       For 2636
Define SCI_AUTOCGETMULTI                       For 2637
Define SC_ORDER_PRESORTED                      For 0
Define SC_ORDER_PERFORMSORT                    For 1
Define SC_ORDER_CUSTOM                         For 2
Define SCI_AUTOCSETORDER                       For 2660
Define SCI_AUTOCGETORDER                       For 2661
Define SCI_ALLOCATE                            For 2446
Define SCI_TARGETASUTF8                        For 2447
Define SCI_SETLENGTHFORENCODE                  For 2448
Define SCI_ENCODEDFROMUTF8                     For 2449
Define SCI_FINDCOLUMN                          For 2456
Define SCI_GETCARETSTICKY                      For 2457
Define SCI_SETCARETSTICKY                      For 2458
Define SC_CARETSTICKY_OFF                      For 0
Define SC_CARETSTICKY_ON                       For 1
Define SC_CARETSTICKY_WHITESPACE               For 2
Define SCI_TOGGLECARETSTICKY                   For 2459
Define SCI_SETPASTECONVERTENDINGS              For 2467
Define SCI_GETPASTECONVERTENDINGS              For 2468
Define SCI_SELECTIONDUPLICATE                  For 2469
Define SC_ALPHA_TRANSPARENT                    For 0
Define SC_ALPHA_OPAQUE                         For 255
Define SC_ALPHA_NOALPHA                        For 256
Define SCI_SETCARETLINEBACKALPHA               For 2470
Define SCI_GETCARETLINEBACKALPHA               For 2471
Define CARETSTYLE_INVISIBLE                    For 0
Define CARETSTYLE_LINE                         For 1
Define CARETSTYLE_BLOCK                        For 2
Define SCI_SETCARETSTYLE                       For 2512
Define SCI_GETCARETSTYLE                       For 2513
Define SCI_SETINDICATORCURRENT                 For 2500
Define SCI_GETINDICATORCURRENT                 For 2501
Define SCI_SETINDICATORVALUE                   For 2502
Define SCI_GETINDICATORVALUE                   For 2503
Define SCI_INDICATORFILLRANGE                  For 2504
Define SCI_INDICATORCLEARRANGE                 For 2505
Define SCI_INDICATORALLONFOR                   For 2506
Define SCI_INDICATORVALUEAT                    For 2507
Define SCI_INDICATORSTART                      For 2508
Define SCI_INDICATOREND                        For 2509
Define SCI_SETPOSITIONCACHE                    For 2514
Define SCI_GETPOSITIONCACHE                    For 2515
Define SCI_COPYALLOWLINE                       For 2519
Define SCI_GETCHARACTERPOINTER                 For 2520
Define SCI_GETRANGEPOINTER                     For 2643
Define SCI_GETGAPPOSITION                      For 2644
Define SCI_INDICSETALPHA                       For 2523
Define SCI_INDICGETALPHA                       For 2524
Define SCI_INDICSETOUTLINEALPHA                For 2558
Define SCI_INDICGETOUTLINEALPHA                For 2559
Define SCI_SETEXTRAASCENT                      For 2525
Define SCI_GETEXTRAASCENT                      For 2526
Define SCI_SETEXTRADESCENT                     For 2527
Define SCI_GETEXTRADESCENT                     For 2528
Define SCI_MARKERSYMBOLDEFINED                 For 2529
Define SCI_MARGINSETTEXT                       For 2530
Define SCI_MARGINGETTEXT                       For 2531
Define SCI_MARGINSETSTYLE                      For 2532
Define SCI_MARGINGETSTYLE                      For 2533
Define SCI_MARGINSETSTYLES                     For 2534
Define SCI_MARGINGETSTYLES                     For 2535
Define SCI_MARGINTEXTCLEARALL                  For 2536
Define SCI_MARGINSETSTYLEOFFSET                For 2537
Define SCI_MARGINGETSTYLEOFFSET                For 2538
Define SC_MARGINOPTION_NONE                    For 0
Define SC_MARGINOPTION_SUBLINESELECT           For 1
Define SCI_SETMARGINOPTIONS                    For 2539
Define SCI_GETMARGINOPTIONS                    For 2557
Define SCI_ANNOTATIONSETTEXT                   For 2540
Define SCI_ANNOTATIONGETTEXT                   For 2541
Define SCI_ANNOTATIONSETSTYLE                  For 2542
Define SCI_ANNOTATIONGETSTYLE                  For 2543
Define SCI_ANNOTATIONSETSTYLES                 For 2544
Define SCI_ANNOTATIONGETSTYLES                 For 2545
Define SCI_ANNOTATIONGETLINES                  For 2546
Define SCI_ANNOTATIONCLEARALL                  For 2547
Define ANNOTATION_HIDDEN                       For 0
Define ANNOTATION_STANDARD                     For 1
Define ANNOTATION_BOXED                        For 2
Define ANNOTATION_INDENTED                     For 3
Define SCI_ANNOTATIONSETVISIBLE                For 2548
Define SCI_ANNOTATIONGETVISIBLE                For 2549
Define SCI_ANNOTATIONSETSTYLEOFFSET            For 2550
Define SCI_ANNOTATIONGETSTYLEOFFSET            For 2551
Define SCI_RELEASEALLEXTENDEDSTYLES            For 2552
Define SCI_ALLOCATEEXTENDEDSTYLES              For 2553
Define UNDO_MAY_COALESCE                       For 1
Define SCI_ADDUNDOACTION                       For 2560
Define SCI_CHARPOSITIONFROMPOINT               For 2561
Define SCI_CHARPOSITIONFROMPOINTCLOSE          For 2562
Define SCI_SETMOUSESELECTIONRECTANGULARSWITCH  For 2668
Define SCI_GETMOUSESELECTIONRECTANGULARSWITCH  For 2669
Define SCI_SETMULTIPLESELECTION                For 2563
Define SCI_GETMULTIPLESELECTION                For 2564
Define SCI_SETADDITIONALSELECTIONTYPING        For 2565
Define SCI_GETADDITIONALSELECTIONTYPING        For 2566
Define SCI_SETADDITIONALCARETSBLINK            For 2567
Define SCI_GETADDITIONALCARETSBLINK            For 2568
Define SCI_SETADDITIONALCARETSVISIBLE          For 2608
Define SCI_GETADDITIONALCARETSVISIBLE          For 2609
Define SCI_GETSELECTIONS                       For 2570
Define SCI_GETSELECTIONEMPTY                   For 2650
Define SCI_CLEARSELECTIONS                     For 2571
Define SCI_SETSELECTION                        For 2572
Define SCI_ADDSELECTION                        For 2573
Define SCI_DROPSELECTIONN                      For 2671
Define SCI_SETMAINSELECTION                    For 2574
Define SCI_GETMAINSELECTION                    For 2575
Define SCI_SETSELECTIONNCARET                  For 2576
Define SCI_GETSELECTIONNCARET                  For 2577
Define SCI_SETSELECTIONNANCHOR                 For 2578
Define SCI_GETSELECTIONNANCHOR                 For 2579
Define SCI_SETSELECTIONNCARETVIRTUALSPACE      For 2580
Define SCI_GETSELECTIONNCARETVIRTUALSPACE      For 2581
Define SCI_SETSELECTIONNANCHORVIRTUALSPACE     For 2582
Define SCI_GETSELECTIONNANCHORVIRTUALSPACE     For 2583
Define SCI_SETSELECTIONNSTART                  For 2584
Define SCI_GETSELECTIONNSTART                  For 2585
Define SCI_SETSELECTIONNEND                    For 2586
Define SCI_GETSELECTIONNEND                    For 2587
Define SCI_SETRECTANGULARSELECTIONCARET        For 2588
Define SCI_GETRECTANGULARSELECTIONCARET        For 2589
Define SCI_SETRECTANGULARSELECTIONANCHOR       For 2590
Define SCI_GETRECTANGULARSELECTIONANCHOR       For 2591
Define SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE  For 2592
Define SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE  For 2593
Define SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE For 2594
Define SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE For 2595
Define SCVS_NONE                               For 0
Define SCVS_RECTANGULARSELECTION               For 1
Define SCVS_USERACCESSIBLE                     For 2
Define SCVS_NOWRAPLINESTART                    For 4
Define SCI_SETVIRTUALSPACEOPTIONS              For 2596
Define SCI_GETVIRTUALSPACEOPTIONS              For 2597
Define SCI_SETRECTANGULARSELECTIONMODIFIER     For 2598
Define SCI_GETRECTANGULARSELECTIONMODIFIER     For 2599
Define SCI_SETADDITIONALSELFORE                For 2600
Define SCI_SETADDITIONALSELBACK                For 2601
Define SCI_SETADDITIONALSELALPHA               For 2602
Define SCI_GETADDITIONALSELALPHA               For 2603
Define SCI_SETADDITIONALCARETFORE              For 2604
Define SCI_GETADDITIONALCARETFORE              For 2605
Define SCI_ROTATESELECTION                     For 2606
Define SCI_SWAPMAINANCHORCARET                 For 2607
Define SCI_MULTIPLESELECTADDNEXT               For 2688
Define SCI_MULTIPLESELECTADDEACH               For 2689
Define SCI_CHANGELEXERSTATE                    For 2617
Define SCI_CONTRACTEDFOLDNEXT                  For 2618
Define SCI_VERTICALCENTRECARET                 For 2619
Define SCI_MOVESELECTEDLINESUP                 For 2620
Define SCI_MOVESELECTEDLINESDOWN               For 2621
Define SCI_SETIDENTIFIER                       For 2622
Define SCI_GETIDENTIFIER                       For 2623
Define SCI_RGBAIMAGESETWIDTH                   For 2624
Define SCI_RGBAIMAGESETHEIGHT                  For 2625
Define SCI_RGBAIMAGESETSCALE                   For 2651
Define SCI_MARKERDEFINERGBAIMAGE               For 2626
Define SCI_REGISTERRGBAIMAGE                   For 2627
Define SCI_SCROLLTOSTART                       For 2628
Define SCI_SCROLLTOEND                         For 2629
Define SC_TECHNOLOGY_DEFAULT                   For 0
Define SC_TECHNOLOGY_DIRECTWRITE               For 1
Define SC_TECHNOLOGY_DIRECTWRITERETAIN         For 2
Define SC_TECHNOLOGY_DIRECTWRITEDC             For 3
Define SCI_SETTECHNOLOGY                       For 2630
Define SCI_GETTECHNOLOGY                       For 2631
Define SCI_CREATELOADER                        For 2632
Define SCI_FINDINDICATORSHOW                   For 2640
Define SCI_FINDINDICATORFLASH                  For 2641
Define SCI_FINDINDICATORHIDE                   For 2642
Define SCI_VCHOMEDISPLAY                       For 2652
Define SCI_VCHOMEDISPLAYEXTEND                 For 2653
Define SCI_GETCARETLINEVISIBLEALWAYS           For 2654
Define SCI_SETCARETLINEVISIBLEALWAYS           For 2655
Define SC_LINE_END_TYPE_DEFAULT                For 0
Define SC_LINE_END_TYPE_UNICODE                For 1
Define SCI_SETLINEENDTYPESALLOWED              For 2656
Define SCI_GETLINEENDTYPESALLOWED              For 2657
Define SCI_GETLINEENDTYPESACTIVE               For 2658
Define SCI_SETREPRESENTATION                   For 2665
Define SCI_GETREPRESENTATION                   For 2666
Define SCI_CLEARREPRESENTATION                 For 2667
Define SCI_STARTRECORD                         For 3001
Define SCI_STOPRECORD                          For 3002
Define SCI_SETLEXER                            For 4001
Define SCI_GETLEXER                            For 4002
Define SCI_COLOURISE                           For 4003
Define SCI_SETPROPERTY                         For 4004
Define KEYWORDSET_MAX                          For 8
Define SCI_SETKEYWORDS                         For 4005
Define SCI_SETLEXERLANGUAGE                    For 4006
Define SCI_LOADLEXERLIBRARY                    For 4007
Define SCI_GETPROPERTY                         For 4008
Define SCI_GETPROPERTYEXPANDED                 For 4009
Define SCI_GETPROPERTYINT                      For 4010
Define SCI_GETSTYLEBITSNEEDED                  For 4011
Define SCI_GETLEXERLANGUAGE                    For 4012
Define SCI_PRIVATELEXERCALL                    For 4013
Define SCI_PROPERTYNAMES                       For 4014
Define SC_TYPE_BOOLEAN                         For 0
Define SC_TYPE_INTEGER                         For 1
Define SC_TYPE_STRING                          For 2
Define SCI_PROPERTYTYPE                        For 4015
Define SCI_DESCRIBEPROPERTY                    For 4016
Define SCI_DESCRIBEKEYWORDSETS                 For 4017
Define SCI_GETLINEENDTYPESSUPPORTED            For 4018
Define SCI_ALLOCATESUBSTYLES                   For 4020
Define SCI_GETSUBSTYLESSTART                   For 4021
Define SCI_GETSUBSTYLESLENGTH                  For 4022
Define SCI_GETSTYLEFROMSUBSTYLE                For 4027
Define SCI_GETPRIMARYSTYLEFROMSTYLE            For 4028
Define SCI_FREESUBSTYLES                       For 4023
Define SCI_SETIDENTIFIERS                      For 4024
Define SCI_DISTANCETOSECONDARYSTYLES           For 4025
Define SCI_GETSUBSTYLEBASES                    For 4026
Define SC_MOD_INSERTTEXT                       For |CI$01  // $0x1
Define SC_MOD_DELETETEXT                       For |CI$02  // $0x2
Define SC_MOD_CHANGESTYLE                      For |CI$04  // $0x4
Define SC_MOD_CHANGEFOLD                       For |CI$08  // $0x8
Define SC_PERFORMED_USER                       For |CI$010  // $0x10
Define SC_PERFORMED_UNDO                       For |CI$020  // $0x20
Define SC_PERFORMED_REDO                       For |CI$040  // $0x40
Define SC_MULTISTEPUNDOREDO                    For |CI$080  // $0x80
Define SC_LASTSTEPINUNDOREDO                   For |CI$0100  // $0x100
Define SC_MOD_CHANGEMARKER                     For |CI$0200  // $0x200
Define SC_MOD_BEFOREINSERT                     For |CI$0400  // $0x400
Define SC_MOD_BEFOREDELETE                     For |CI$0800  // $0x800
Define SC_MULTILINEUNDOREDO                    For |CI$01000  // $0x1000
Define SC_STARTACTION                          For |CI$2000  // $0x2000
Define SC_MOD_CHANGEINDICATOR                  For |CI$4000  // $0x4000
Define SC_MOD_CHANGELINESTATE                  For |CI$8000  // $0x8000
Define SC_MOD_CHANGEMARGIN                     For |CI$10000  // $0x10000
Define SC_MOD_CHANGEANNOTATION                 For |CI$20000  //$0x20000
Define SC_MOD_CONTAINER                        For |CI$40000  // $0x40000
Define SC_MOD_LEXERSTATE                       For |CI$80000  // $0x80000
Define SC_MOD_INSERTCHECK                      For |CI$100000  // $0x100000
Define SC_MOD_CHANGETABSTOPS                   For |CI$200000  // $0x200000
Define SC_MODEVENTMASKALL                      For |CI$3FFFFF  // $0x3FFFFF
Define SC_UPDATE_CONTENT                       For |CI$01  // $0x1
Define SC_UPDATE_SELECTION                     For |CI$02  // $0x2
Define SC_UPDATE_V_SCROLL                      For |CI$04  // $0x4
Define SC_UPDATE_H_SCROLL                      For |CI$08  // $0x8
Define SCEN_CHANGE                             For 768
Define SCEN_SETFOCUS                           For 512
Define SCEN_KILLFOCUS                          For 256
Define SCK_DOWN                                For 300
Define SCK_UP                                  For 301
Define SCK_LEFT                                For 302
Define SCK_RIGHT                               For 303
Define SCK_HOME                                For 304
Define SCK_END                                 For 305
Define SCK_PRIOR                               For 306
Define SCK_NEXT                                For 307
Define SCK_DELETE                              For 308
Define SCK_INSERT                              For 309
Define SCK_ESCAPE                              For 7
Define SCK_BACK                                For 8
Define SCK_TAB                                 For 9
Define SCK_RETURN                              For 13
Define SCK_ADD                                 For 310
Define SCK_SUBTRACT                            For 311
Define SCK_DIVIDE                              For 312
Define SCK_WIN                                 For 313
Define SCK_RWIN                                For 314
Define SCK_MENU                                For 315
Define SCMOD_NORM                              For 0
Define SCMOD_SHIFT                             For 1
Define SCMOD_CTRL                              For 2
Define SCMOD_ALT                               For 4
Define SCMOD_SUPER                             For 8
Define SCMOD_META                              For 16
Define SC_AC_FILLUP                            For 1
Define SC_AC_DOUBLECLICK                       For 2
Define SC_AC_TAB                               For 3
Define SC_AC_NEWLINE                           For 4
Define SC_AC_COMMAND                           For 5
Define SCN_STYLENEEDED                         For 2000   // SCN - Notifications
Define SCN_CHARADDED                           For 2001
Define SCN_SAVEPOINTREACHED                    For 2002
Define SCN_SAVEPOINTLEFT                       For 2003
Define SCN_MODIFYATTEMPTRO                     For 2004
Define SCN_KEY                                 For 2005
Define SCN_DOUBLECLICK                         For 2006
Define SCN_UPDATEUI                            For 2007
Define SCN_MODIFIED                            For 2008
Define SCN_MACRORECORD                         For 2009
Define SCN_MARGINCLICK                         For 2010
Define SCN_NEEDSHOWN                           For 2011
Define SCN_PAINTED                             For 2013
Define SCN_USERLISTSELECTION                   For 2014
Define SCN_URIDROPPED                          For 2015
Define SCN_DWELLSTART                          For 2016
Define SCN_DWELLEND                            For 2017
Define SCN_ZOOM                                For 2018
Define SCN_HOTSPOTCLICK                        For 2019
Define SCN_HOTSPOTDOUBLECLICK                  For 2020
Define SCN_CALLTIPCLICK                        For 2021
Define SCN_AUTOCSELECTION                      For 2022
Define SCN_INDICATORCLICK                      For 2023
Define SCN_INDICATORRELEASE                    For 2024
Define SCN_AUTOCCANCELLED                      For 2025
Define SCN_AUTOCCHARDELETED                    For 2026
Define SCN_HOTSPOTRELEASECLICK                 For 2027
Define SCN_FOCUSIN                             For 2028
Define SCN_FOCUSOUT                            For 2029
Define SCN_AUTOCCOMPLETED                      For 2030
Define SCN_MARGINRIGHTCLICK                    For 2031

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
Define SCLEX_DATAFLEX                   For 122

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


