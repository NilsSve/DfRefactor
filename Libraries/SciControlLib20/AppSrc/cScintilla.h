//TH-Header
//*****************************************************************************************
// Copyright (c)  2019 Antwise Solutions
// All rights reserved.
//
// $FileName    : \Pkg\cScintilla.h
// $ProjectName : TheHammer4
// $Authors     : Wil van Antwerpen
// $Created     : 12.06.2019  22:31
//
// Contents:
//   Contains the defines that match the C declarations for the scintilla control that can
//   be found at the scintilla project file scintilla.h
//
// This header is licensed under the 2 clause BSD license as to make it as easy as possible to re-use if needed.
//
// BSD License content start
// *********************************************************************************************************
//
// Copyright (c) 2019, Wil van Antwerpen
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// The views and conclusions contained in the software and documentation are those
// of the authors and should not be interpreted as representing official policies,
// either expressed or implied, of the VDF-Guidance / Hammer Project.
// *********************************************************************************************************
//
//*****************************************************************************************
//TH-RevisionStart
// ********************
// MODIFICATION SUMMARY
// ********************
// ####### DD/MM/YYYY  WHO COMMENT
//TH-RevisionEnd




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
Define SC_MARK_VERTICALBOOKMARK                For 32
Define SC_MARK_CHARACTER                       For 10000
// Hammer Custom
Define SC_MARKNUM_LINEHIGHLIGHT                For 10
Define SC_MARKNUM_BOOKMARK                     For 11
Define SC_MARKNUM_CHANGEDLINE                  For 12
Define SC_MARKNUM_CHANGEDLINESAVED             For 13
Define SC_MARKNUM_DEBUGBREAKPOINT              For 14
Define SC_MARKNUM_DEBUGCURRENTPOSITION         For 15
// Hammer Custom ends
Define SC_MARKNUM_FOLDEREND                    For 25
Define SC_MARKNUM_FOLDEROPENMID                For 26
Define SC_MARKNUM_FOLDERMIDTAIL                For 27
Define SC_MARKNUM_FOLDERTAIL                   For 28
Define SC_MARKNUM_FOLDERSUB                    For 29
Define SC_MARKNUM_FOLDER                       For 30
Define SC_MARKNUM_FOLDEROPEN                   For 31
Define SC_MASK_FOLDERS                         For |CI$FE000000 // 0xFE000000
// Hammer Custom
Define SC_MASK_MARGIN                          For |CI$01000000 // 0x01000000 - allow symbol 24
Define SC_MASK_BOOKMARK                        For |CI$00000800 // 0x00000800 - allow symbol 11, start counting from right, each bit is 1, starting from symbol 0
Define SC_MASK_CHANGEDLINEUNSAVED              For |CI$00001000 // 0x00001000 - allow symbol 12 only
Define SC_MASK_CHANGEDLINE                     For |CI$00003000 // 0x00003000 - allow symbol 12 and 13
Define SC_MASK_DEBUGBREAKPOINT                 For |CI$00004000 // 0x00008000 - allow symbol 14
Define SC_MASK_DEBUGCURRENTPOSITION            For |CI$00008000 // 0x00004000 - allow symbol 15
Define SC_MASK_STATUS                          For |CI$0000C800 // 0x00000800 - allow symbol 11, 14 and 15
// Hammer Custom ends
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
// Hammer Custom
Define STYLE_AUTOCOMPLETE                      For 40
// Hammer Custom ends
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
Define SCI_SETCHARACTERCATEGORYOPTIMIZATION    For 2720
Define SCI_GETCHARACTERCATEGORYOPTIMIZATION    For 2721
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
Define INDIC_GRADIENT                          For 20
Define INDIC_GRADIENTCENTRE                    For 21
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
Define SCI_SETLINESTATE                        For 2092
Define SCI_GETLINESTATE                        For 2093
Define SCI_GETMAXLINESTATE                     For 2094
Define SCI_GETCARETLINEVISIBLE                 For 2095
Define SCI_SETCARETLINEVISIBLE                 For 2096
Define SCI_GETCARETLINEBACK                    For 2097
Define SCI_SETCARETLINEBACK                    For 2098
Define SCI_GETCARETLINEFRAME                   For 2704
Define SCI_SETCARETLINEFRAME                   For 2705
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
// Hammer Custom
Define SCI_AUTOCUSESTYLE                       For 2120
// Hammer Custom Ends
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
Define SCI_COUNTCODEUNITS                      For 2715
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
Define SC_PRINT_SCREENCOLOURS                  For 5
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
Define SCI_FOLDDISPLAYTEXTGETSTYLE             For 2707
Define SCI_SETDEFAULTFOLDDISPLAYTEXT           For 2722
Define SCI_GETDEFAULTFOLDDISPLAYTEXT           For 2723
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
Define SC_WRAPINDENT_DEEPINDENT                For 3
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
Define SC_ACCESSIBILITY_DISABLED               For 0
Define SC_ACCESSIBILITY_ENABLED                For 1
Define SCI_SETACCESSIBILITY                    For 2702
Define SCI_GETACCESSIBILITY                    For 2703
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
Define SCI_LINEREVERSE                         For 2354
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
Define SC_DOCUMENTOPTION_DEFAULT               For 0
Define SC_DOCUMENTOPTION_STYLES_NONE           For |CI$0001  // 0x1
Define SC_DOCUMENTOPTION_TEXT_LARGE            For |CI$0100  // 0x100
Define SCI_CREATEDOCUMENT                      For 2375
Define SCI_ADDREFDOCUMENT                      For 2376
Define SCI_RELEASEDOCUMENT                     For 2377
Define SCI_GETDOCUMENTOPTIONS                  For 2379
Define SCI_GETMODEVENTMASK                     For 2378
Define SCI_SETCOMMANDEVENTS                    For 2717
Define SCI_GETCOMMANDEVENTS                    For 2718
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
Define SCI_POSITIONRELATIVECODEUNITS           For 2716
Define SCI_COPYRANGE                           For 2419
Define SCI_COPYTEXT                            For 2420
Define SC_SEL_STREAM                           For 0
Define SC_SEL_RECTANGLE                        For 1
Define SC_SEL_LINES                            For 2
Define SC_SEL_THIN                             For 3
Define SCI_SETSELECTIONMODE                    For 2422
Define SCI_GETSELECTIONMODE                    For 2423
Define SCI_GETMOVEEXTENDSSELECTION             For 2706
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
Define CARETSTYLE_OVERSTRIKE_BAR               For 0
Define CARETSTYLE_OVERSTRIKE_BLOCK             For 16
Define CARETSTYLE_INS_MASK                     For |CI$0F   // 0xF
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
Define SCI_GETNAMEDSTYLES                      For 4029
Define SCI_NAMEOFSTYLE                         For 4030
Define SCI_TAGSOFSTYLE                         For 4031
Define SCI_DESCRIPTIONOFSTYLE                  For 4032
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
Define SCN_AUTOCSELECTIONCHANGE                For 2032
#IFNDEF SCI_DISABLE_PROVISIONAL
Define SC_BIDIRECTIONAL_DISABLED               For 0
Define SC_BIDIRECTIONAL_L2R                    For 1
Define SC_BIDIRECTIONAL_R2L                    For 2
Define SCI_GETBIDIRECTIONAL                    For 2708
Define SCI_SETBIDIRECTIONAL                    For 2709
Define SC_LINECHARACTERINDEX_NONE              For 0
Define SC_LINECHARACTERINDEX_UTF32             For 1
Define SC_LINECHARACTERINDEX_UTF16             For 2
Define SCI_GETLINECHARACTERINDEX               For 2710
Define SCI_ALLOCATELINECHARACTERINDEX          For 2711
Define SCI_RELEASELINECHARACTERINDEX           For 2712
Define SCI_LINEFROMINDEXPOSITION               For 2713
Define SCI_INDEXPOSITIONFROMLINE               For 2714
#ENDIF


// Basic signed type used throughout interface (see scintilla source Sci_Position.h)
// typedef ptrdiff_t Sci_Position;
Define Sci_Position For Longptr

// Unsigned variant used for ILexer::Lex and ILexer::Fold
// typedef size_t Sci_PositionU;
Define Sci_PositionU For ULongptr

// For Sci_CharacterRange  which is defined as long to be compatible with Win32 CHARRANGE
// typedef long Sci_PositionCR;
Define Sci_PositionCR For integer


//struct Sci_CharacterRange {
//    Sci_PositionCR cpMin;
//    Sci_PositionCR cpMax;
//};
Struct tSci_CharacterRange
  Sci_PositionCR cpMin
  Sci_PositionCR cpMax
End_Struct

//struct Sci_TextRange {
//    struct Sci_CharacterRange chrg;
//    char *lpstrText;
//};
Struct tSci_TextRange
  tSci_CharacterRange chrg
  Pointer lpstrText
End_Struct

//struct Sci_TextToFind {
//    struct Sci_CharacterRange chrg;     // range to search
//    const char *lpstrText;              // the search pattern (zero terminated)
//    struct Sci_CharacterRange chrgText; // returned as position of matching text
//};
Struct tSci_TextToFind
  tSci_CharacterRange chrg
  Pointer            pszText
  tSci_CharacterRange chrgText
End_Struct

//struct Sci_Rectangle {
//	int left;
//	int top;
//	int right;
//	int bottom;
//};
Struct tSci_Rectangle
  Integer left
  Integer top
  Integer right
  Integer bottom
End_Struct


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
  Handle   hwndFrom
  ULongptr idFrom
  UInteger uCode
#IFDEF IS$WIN64
    Integer tSciNotifyHeaderMissingAlignment
#ENDIF
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
#IFDEF IS$WIN64
    Integer tSCNotificationMissingAlignment1
#ENDIF
  Address           Text
  Sci_Position      length
  Sci_Position      linesAdded
  Integer           message
#IFDEF IS$WIN64
    Integer tSCNotificationMissingAlignment2
#ENDIF
  ULongptr          wParam
  Longptr           lParam
  Sci_Position      line
  Integer           foldLevelNow
  Integer           foldLevelPrev
  Integer           margin
  Integer           listType
  Integer           x
  Integer           y
  Integer           token
#IFDEF IS$WIN64
    Integer tSCNotificationMissingAlignment3
#ENDIF
  Sci_Position      annotationLinesAdded
  Integer           updated
  Integer           listCompletionMethod
  //Integer           characterSource  // not in the current scintilla YET
End_Struct
