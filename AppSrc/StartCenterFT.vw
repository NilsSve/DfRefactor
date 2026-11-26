// START CENTER - the screen before a workspace is open (Nils 2026-08-06).
//
// WHY IT EXISTS. DF 26's Studio splits its screen by workspace state: a Start Center with
// nothing loaded, a Workspace Dashboard once something is, and a command that toggles between
// them. DFRefactor had only the second half - the boards - so with no workspace loaded the
// guided trail rendered one workspace card above four bands whose builders all short-circuit
// to an empty wrap. A screen with one live control on it, and one line of guidance ("Run a
// Check to see findings") naming a button that does not exist until a workspace AND a program
// are picked.
//
// THIS IS NOT A FOURTH BOARD. The trail and the Manual board GIVE UP their workspace tile as
// this view takes it on (they carry a crumb instead - WorkspaceCrumbHtml, which names the
// loaded .sws and comes back here). Nothing is duplicated, each screen has one job, and the
// old oDashboard_vw cockpit - whose remaining job was to offer the GUIDED|MANUAL split that
// now happens at the door - has nothing left to do.
//
// WHAT IS DELIBERATELY ABSENT: the Studio's news feed. Its StartCenterContents.xml is 2.4 MB of
// News / Events / Getting Started / Experienced items with base64 JPEGs behind it, which needs a
// publishing pipeline, a URL, fetch-cache-offline handling and content discipline forever. The
// tab strip is real and takes a second page whenever that changes its mind. Also absent: "New
// Workspace" - DFRefactor does not create workspaces, so "Make a workspace copy" is the honest
// local equivalent and earns that slot.
//
// ONE HOST TILE, TWO COLUMNS. Two span-6 tiles do NOT level their heights - the host does not
// stretch separate tiles - so the sidebar and the main area are flex children of ONE span-12
// tile, exactly like the Dashboard's own two-column card. That also gives the sidebar's darker
// ground a full-height column to paint.
//
// CLICK ISOLATION: a cWebHtmlBox click fires EVERY ancestor's ServerOnClick, so the board div
// carries no data-ServerOnClick at all - only the individual controls do. Nesting a button
// inside a clickable card is how a chip ends up firing the card's action too.
//
// RENDER NOTE: the psHtml builders run at construct/first-paint, so they stay LIGHTWEIGHT - no
// recursive folder walks (that is what hung the trail's first build blank). Everything here
// reads ghoApplication or the Functions table and returns.
// ==========================================================================================
Use Windows.pkg
Use DFClient.pkg
Use cRDCDbView.pkg
Use cFTDeferTimer.pkg
Use FTAllWebControlClasses.pkg          // FT web controls (cFTWebHtmlBox)
Use cFTDbLocalWebControlHost.pkg        // hosts the web content in this view
Use cSysFileDataDictionary.dd
Use RefactorConstants.h.pkg
Use FTDashIcons.pkg                     // DashIcon() - the shared glyph set
Use RDCRunProgram.pkg                    // RDCOpenUrl - the "watch it work" destination
Use FTMarkupBuilders.pkg                // the HTML vocabulary - OpenHtml, IconLabel, the builders
Use cFTTileMarkup.pkg                   // ghoTileMarkup - the shared tiles + the workspace crumb
Use cFTBoardActions.pkg                 // ghoBoardActions - Compare / Revert, offered by every board
Use WorkspaceCopyRecord.pkg             // which side of a copy the open workspace is - the copy card
Use cLibraryInventory.pkg               // SwsFormatOf / IsVersionBelow - the workspace file row
Use cDfCliPackages.pkg                  // DfCliPath - the conversion needs df-cli
Use FTMessageBox.pkg                    // FTStopBox - no df-cli to convert with

/* The "Watch DFRefactor in action" destination - a page that SHIPS WITH THE PRODUCT.

   Help\DFRefactorTour.html is a self-contained walkthrough of one lap: no network, no fonts, no
   scripts from anywhere, so it works on a machine that has never been online and cannot rot when
   something external moves. It opens in the user's own browser through RDCOpenHelpPage, which
   refuses anything that is not an existing .htm/.html file (see RDCRunProgram.pkg).

   THE CARD IS GATED ON THE FILE BEING THERE, not on a constant being non-blank. A missing page and
   a page that is present are genuinely different states, and only the filesystem knows which one
   this is - somebody deploying a trimmed Help folder gets an honest "not installed" rather than a
   link that opens nothing. The check is one existence probe per render, which is cheap enough for
   a builder that must stay light (no folder walks - that is what hung the trail's first build). */
#IFNDEF CS_SCTourFile
    Define CS_SCTourFile for "DFRefactorTour.html"
#ENDIF

// The board's own deferred work, on oSCDeferTimer's tick. The page clicks have run in oTile_Board's
// OnHtmlClick, after the web click has returned, since 2026-10-07 - their codes went with them.
Define CI_SCRefresh         for 10   // repaint the board
Define CI_SCSelectFolders   for 11   // a load that left NOTHING selected -> Select Folders

Activate_View Activate_oStartCenter_vw for oStartCenter_vw
Object oStartCenter_vw is a cRDCDbView
    Set Border_Style to Border_Thick
    Set Size to 502 653
    Set Location to 2 2
    Set Label to "Start Center"
    Set Icon to "StartCenter.ico"
    /* NOT via pbAutoActivate, for the reason the other three boards carry the same note:
       AppPanel.Add_Focus replays the WHOLE phoAutoActivateViews list every time focus returns to
       the panel, and focus returns every time a modal closes - so an auto-activated view re-takes
       the screen after every dialog. oMain.Add_Focus names the startup view ONCE instead. */
    Set pbAutoActivate to False
    /* And the other way a view takes the screen unasked: Request_Clear_All ends with
       "If (Auto_Top_Panel_State(Self)) Send beginning_of_panel", and opening a workspace
       Broadcasts Request_Clear_All to every Client_Area child. This is a board of HTML, not a
       data-entry panel; there is no cursor to put at the top of it. */
    Set Auto_Top_Panel_State to False

    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    // The .sws we have already opened the folder picker for. Session-scoped on purpose - see
    // OnWorkspaceLoaded. "" = none this session.
    Property String psFolderPromptedWS ""

    // Minimal HTML escape. Windows paths cannot hold < > | ", but a folder name may legally
    // contain "&" - and one unescaped ampersand silently truncates the rest of a recent row.
    Function ScEscaped String sText Returns String
        String sOut
        Move (Replaces("&", sText, "&amp;")) to sOut
        Move (Replaces("<", sOut, "&lt;"))   to sOut
        Function_Return sOut
    End_Function

    /* The shipped tour page, or "" when it is not on disk.
       psHelpPath comes off phoWorkspace(ghoApplication) - DFRefactor's OWN workspace, never the
       one the user has loaded. That distinction has bitten before (the migration copy took the
       wrong home from exactly this property), and it matters doubly here: the page ships with the
       tool, so reading psHelpPath of the user's workspace would look for our Help file inside
       their application. DFRefactor's own Config.ws declares HelpPath=Help. */
    Function TourPagePath Returns String
        String sHelp sFile
        Get psHelpPath of (phoWorkspace(ghoApplication)) to sHelp
        If (sHelp = "") ;
            Function_Return ""
        Move (vFolderFormat(sHelp) + CS_SCTourFile) to sFile
        If ((vFilePathExists(sFile)) = False) ;
            Function_Return ""
        Function_Return sFile
    End_Function

    // The folder a .sws sits in - what tells a copy from its original, since from DataFlex 26 a copy's
    // .sws keeps the original's name.
    Function ScFolderOf String sPath Returns String
        Integer iPos
        Move (RightPos("\", sPath)) to iPos
        If (iPos > 1) ;
            Function_Return (Left(sPath, (iPos - 1)))
        Function_Return sPath
    End_Function

    /* THE SIDEBAR - Target, then Workspaces, then Recent.

       TARGET LEADS (Nils 2026-08-06: "as it is so important, move it to the top"). It is the
       right order for a first run, where choosing a target genuinely is the first thing that has
       to happen - and it gates both the copy card and the guided lane, so a missing one needs to
       be seen before anything else is attempted.

       It is ONE choice, not two: Set psCompiler calls ResolveTargetDataFlex, which reads the
       version and the Pkg folder straight off the compiler path. "DataFlex 26.0" is the readout
       of the compiler, never a separate setting - which is also why this belongs here rather than
       inside the copy card. It is global (SysFile.CompilerPath, restored at startup), so it is
       already true before any workspace is open and does not change when one opens.

       The set state wears the boards' own .dash-tile.t-target amber, unchanged. It was briefly
       toned down for its new top position, on the grounds that a satisfied prerequisite should
       not outshout the primary button below it; Nils chose consistency, and he is right - one
       setting that looks the same everywhere costs a reader less than a slightly loud row. */

    /* THE MASTHEAD - "DFRefactor" over a code comment (Nils 2026-08-06: "it reminds of the Studio").
       The Studio's Start Center opens with a product wordmark, and that recognition is the point:
       this screen should read as the front door of a named tool rather than as another board. It
       also gives the wordmark a proper home - it was a cramped 24px line in the sidebar, where it
       stole 48px from the column that most needed the height.

       The second line renders the words START CENTER wrapped in block-comment delimiters, and that
       is the joke that earns its place: this is a source-code refactoring tool, so its own front
       page announcing itself in comment syntax says what the product does before a word of copy is
       read.

       THE DELIMITERS ARE Character()-BUILT, never written literally - 47 is a slash, 42 a star.
       DataFlex has had block comments since DF23, so a literal opener inside a string is a bet on
       the lexer preferring string semantics to comment semantics, and the losing side of that bet
       is not an error message but a comment that swallows the rest of the line. Same defence
       oRefactorFuncLib uses for emitted # and ! (FMAC evaluates those before string semantics).

       This very comment proved the point while being written: spelling the closing delimiter out
       in the prose above ENDED the comment block early and error 4396 landed on the next sentence.
       The hazard is real at both ends - in emitted strings and in the notes describing them. */

    /* WHICH LANES ARE OPEN - computed ONCE and read by both places that offer them (Nils
       2026-08-08, adding the masthead's quick links). The band at the foot of the main column has
       always gated these carefully: no workspace shuts both doors, and a workspace with no target
       leaves MANUAL live while guided greys, because a Check compiles and a manual run never does.

       The masthead links are a second surface on the same decision, not a second decision. If they
       re-derived it they could disagree with the band three feet below them - one lit, one grey,
       for the same lane - which is worse than not having them at all. One function, both callers.

         0 = no workspace: both shut
         1 = workspace, no target: manual only
         2 = both live                                                                          */
    Function LaneState Returns Integer
        String sWS sComp
        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Function_Return 0
        Get psCompiler of ghoApplication to sComp
        If (sComp = "") ;
            Function_Return 1
        Function_Return 2
    End_Function

    /* THE LOADED WORKSPACE IS NAMED BESIDE THE TITLE (Nils 2026-08-06: "a clear visual clue what
       workspace is open"). Baseline-aligned after the wordmark, so the eye reads
       "DFRefactor <name>" as one line rather than as two stacked headings.

       Nothing is shown when none is loaded. The absence is already stated three times over - both
       lanes grey with "Open a workspace first", the copy card says the same, and the Scope readout
       below the button is absent - so a fourth "no workspace" in the masthead would be noise, and
       an empty slot beside a 40px title looks like a bug rather than a state. */
    Function MastheadHtml Returns String
        String sOpen sClose sWS sName sTCls sGuided sManual
        Integer iLane

        Move (Character(47) + Character(42)) to sOpen
        Move (Character(42) + Character(47)) to sClose
        Get psSWSFile of ghoApplication to sWS
        /* "CURRENT WORKSPACE" between the wordmark and the name (Nils 2026-08-08). A bare name
           beside a product title reads as part of the title - "DFRefactor Order_Entry" - rather
           than as a statement about what is loaded. The label is what turns it into a readout.

           CURRENT, not OPEN, and the difference matters here: the sidebar's button is already
           called "Open workspace...", so labelling this one "Open workspace" would give the same
           two words to an action and to a state on the same screen. */
        Move "" to sName
        Move "" to sTCls
        If (sWS <> "") Begin
            /* The file line is out of flow, so the title line has to be told to leave room for it -
               otherwise it lands on the START CENTER comment line beneath. Applied ONLY when a
               workspace is loaded, so the masthead with none keeps the spacing it has today.
               (Do not write that comment line's literal text here - a block comment inside a block
               comment ends at the FIRST close, and this one compiled as code: error 4298.) */
            Move " sc-mast-t-ws" to sTCls
            /* THE FILE NAME, under the WORKSPACE NAME - not under the wordmark (Nils 2026-08-12).

               Which means the two have to be one stacked block, because the name's left edge is not
               a fixed offset: it sits after the wordmark and the "Current workspace" label, both of
               which are text whose rendered width nobody here can know. An indent guessed in CSS
               would be right on one machine and wrong on the next. Wrapping them makes the file
               line inherit the name's position instead of restating it.

               The wrapper holds the NAME in flow and positions the file line absolutely beneath it,
               so the wrapper's own baseline stays the name's - which is what keeps the 40px
               wordmark sitting on the same line it always did. A second line IN flow would move the
               wrapper's baseline to that line and drop the title around it.

               THE FULL PATH (Nils 2026-08-12), not just the file name: the folder is half the
               answer when the same workspace exists in several places, which on this machine it
               routinely does. Truncated from the right with an ellipsis when it will not fit - the
               same treatment .sc-rc-path gives the Recent rows - and the whole path is the tooltip,
               where length costs nothing. */
            Move ((SpanOpen("sc-mast-k")) + 'Current workspace' + CS_SpanEnd ;
                  + (SpanOpen("sc-mast-wsblock")) ;
                  + (SpanOpen("sc-mast-ws")) + (ScEscaped(Self, WorkspaceShortName(ghoTileMarkup, sWS))) + CS_SpanEnd ;
                  + (SpanOpenTip("sc-mast-file", sWS)) ;
                  + (ScEscaped(Self, sWS)) + (CS_SpanEnd + CS_SpanEnd)) to sName
        End
        /* THE PRODUCT MARK, in front of the wordmark (Nils 2026-08-08). It is the application's own
           icon - the infinity loop with an arrowhead, a cycle WITH DIRECTION, which is the same
           idea the walkthrough calls "the lap" and the step rail draws with its teal bracket. The
           mark and the product's central idea already agree; nothing had to be invented.

           NOT the icon's own tile. DFRefactor.ico is navy #2b3b53 on a filled square, and a cool
           blue block on this warm var(--dfr-bg-sunken, #211f1e) topbar reads as a foreign object. The square is a Windows
           requirement - the OS needs a filled tile - and a masthead has no such need, so the glyph
           was lifted out of it and the badge here is the app's OWN card colour instead.

           The asset is the REAL artwork, not a redrawing: the glyph's coverage was taken off the
           768px frame as an alpha mask, so it keeps its true geometry and anti-aliased edges, and
           was painted var(--dfr-mint, #5fd3a6). That colour is BAKED IN because an <img> cannot be recoloured by
           CSS - to change it, regenerate the PNG from Bitmaps\DFRefactor.ico rather than reaching
           for a filter. */

        /* QUICK LINKS, top right (Nils 2026-08-08, after the DF26 Studio, which puts "Package
           Manager" and "Dashboard" in the same corner). The masthead's right side was empty, and
           a returning user who already knows which lane they want should not have to read three
           teaching cards to reach it.

           They do NOT duplicate the band - they are the express route to it. Same click ids,
           "guided" and "manual", so both surfaces run the same action, and the same LaneState, so
           they can never contradict the band's own lit/grey verdict. The band still teaches (what
           each lane is, why one needs a target); these are for people past needing that, exactly
           as Recent is the express route past "Open workspace...".

           A shut lane renders WITHOUT data-ServerOnClick and says why in its tooltip, matching
           the band's wording. Making them always live and popping the .sws dialog is the one thing
           that would be wrong here: it is the "two places that open a workspace" problem the band
           was designed to remove. */
        Move (LaneState(Self)) to iLane
        If (iLane = 0) Begin
            Move (((SpanOpenTip("sc-mast-lnk sc-mast-lnk-off", "Open a workspace first. Both dashboards work on the workspace that is open.")) + 'Guided dashboard ') + (DashIcon(CS_GlyphChevron)) + CS_SpanEnd) to sGuided
            Move (((SpanOpenTip("sc-mast-lnk sc-mast-lnk-off", "Open a workspace first. Both dashboards work on the workspace that is open.")) + 'Manual dashboard ') + (DashIcon(CS_GlyphChevron)) + CS_SpanEnd) to sManual
        End
        Else Begin
            Move ((ClickableHtml("span", "sc-mast-lnk sc-mast-lnk-m", "manual", "", ('Manual dashboard ' + (DashIcon(CS_GlyphChevron))), "You choose the files or folders and the refactoring functions yourself. The compiler is not used, and the source code is not analyzed first. Not suggested unless you already know exactly what needs to be changed."))) to sManual
            If (iLane = 1) ;
                Move (((SpanOpenTip("sc-mast-lnk sc-mast-lnk-off", "The guided dashboard compiles the program. Choose the target DataFlex version first.")) + 'Guided dashboard ') + (DashIcon(CS_GlyphChevron)) + CS_SpanEnd) to sGuided
            Else ;
                Move ((ClickableHtml("span", "sc-mast-lnk sc-mast-lnk-g", "guided", "", ('Guided dashboard ' + (DashIcon(CS_GlyphChevron))), "The recommended choice. DFRefactor compiles the program and runs an advanced analysis of the source code to find what needs to be changed, then suggests a plan. You approve the plan before anything runs."))) to sGuided
        End
        Function_Return (((DivOpen("sc-mast")) + (DivOpen("sc-mast-left")) + (DivOpen(("sc-mast-t" + sTCls)))) ;
                         + (((SpanOpen("sc-mast-logo")) + '<img src="Images/DFRefactorMark.png" alt="">') + CS_SpanEnd) ;
                         + 'DFRefactor' + sName + (CS_DivEnd + (DivOpen("sc-mast-c"))) + sOpen + 'START CENTER' + sClose + (CS_DivEnd + CS_DivEnd) ;
                         + (DivOpen("sc-mast-nav")) + sGuided + sManual + (CS_DivEnd + CS_DivEnd))
    End_Function

    /* THE TARGET STRIP - full width, above both columns (Nils 2026-08-06).
       It used to head the sidebar. That was the right PRIORITY and the wrong PLACE: with the
       wordmark, its own label and block, and two dividers stacked above "Open workspace", the
       button that has to be pressed first sat 147px below the top of the card it enables - 55% of
       the way down it - while the main column had only a 34px tab strip above the same row.
       Measured on the real stylesheet; trimming recovered 88 of those 147 at best, because the
       block simply could not fit above the button. Moving it out is what makes them line up.

       Full width is also what it IS. The target is global - SysFile.CompilerPath, restored at
       startup and unchanged by opening a workspace - so it was never a peer of Workspaces and
       Recent, which are per-session. A strip spanning both columns says "this applies to
       everything below"; a first item in the left column said "this is the first of three
       workspace things". And it loses no prominence: the top of the screen outranks the top of a
       column.

       ONE choice, not two: Set psCompiler calls ResolveTargetDataFlex, which reads the version and
       the Pkg folder off the compiler path, so "DataFlex 26.0" is the compiler's readout and never
       a separate setting. The set state wears the boards' own .dash-tile.t-target amber, unchanged
       - one setting, one look, wherever it appears. */
    Function TargetStripHtml Returns String
        String sHtml sVer sComp sCompBase sBits sTgtClass sTgtV sTgtS
        Integer iPos

        Get psTargetDfVersion of ghoApplication to sVer
        Get psCompiler        of ghoApplication to sComp
        Move (RightPos("\", sComp)) to iPos
        If (iPos > 0) ;
            Move (Right(sComp, (Length(sComp) - iPos))) to sCompBase
        Else ;
            Move sComp to sCompBase
        Get psCompilerBitness of ghoApplication to sBits
        If (sBits <> "") ;
            Move (" (" + sBits + ")") to sBits
        /* THE TILE HOLDS ONLY THE VERSION; the compiler sits BESIDE it (Nils 2026-08-06).

           The block used to carry version over compiler-path as a two-line stack, which made it as
           wide as its longest path and left the strip looking like one long bar. Splitting them
           narrows the tile to the width of the Open workspace button below it - the two prerequisite
           controls now read as the same kind of thing at the same size - and the compiler text takes
           the position the "Global..." hint had.

           That hint is GONE, deliberately: it existed to justify a full-width strip back when the
           strip was the argument being made. The layout now says it without prose - a band across
           both columns is already "this applies to everything below". */
        If (sComp = "") Begin
            // Coral IS correct here, unlike on the old workspace banner: a prerequisite really is
            // missing, and this is the only place it can be fixed.
            Move "sc-tgt sc-tgt-wide sc-tgt-warn" to sTgtClass
            Move "No version chosen" to sTgtV
            Move "Choose the DataFlex version the code is moving to" to sTgtS
        End
        Else Begin
            Move "sc-tgt sc-tgt-wide" to sTgtClass
            If (sVer = "") ;
                Move "DataFlex (version unknown)" to sTgtV
            Else ;
                Move ("DataFlex" * sVer) to sTgtV
            Move (sCompBase + sBits + " " + CS_MidDot + " click to change") to sTgtS
        End
        Move (((DivOpen("sc-topbar")) + (DivOpen("sc-topbar-k")) + 'Target DataFlex version') + CS_DivEnd) to sHtml
        Move (sHtml + (DivOpen("sc-topbar-row"))) to sHtml
        Move (sHtml + (ClickableHtml("div", (sTgtClass), "target", "", ((SpanOpen("sc-tgt-ico")) + (DashIcon(CS_GlyphSettings)) + (CS_SpanEnd + (SpanOpen("sc-tgt-v"))) + sTgtV + CS_SpanEnd), (CS_SetupTileTip)))) to sHtml
        Move (sHtml + (SpanOpen("sc-topbar-comp")) + sTgtS + CS_SpanEnd) to sHtml
        Move (sHtml + (CS_DivEnd + CS_DivEnd)) to sHtml
        Function_Return sHtml
    End_Function

    /* SCOPE - how many source folders the loaded workspace has selected (Nils 2026-08-06).

       It sits under the Open-workspace button because it describes the workspace that IS loaded,
       and it is absent entirely when none is - there is no scope to report yet.

       WHY IT EARNS A PERMANENT SLOT. Folder selection is what the manual flow collects files from,
       so with none picked ActionRowHtml refuses to start a run at all; and for the guided Check the
       scan silently falls back to WholeWorkspaceSourceFolders, which is a legitimate answer but an
       INVISIBLE one. Either way the number decides what gets looked at, and until now it was only
       visible from inside the folder grid.

       "0 of 0" is the fresh case, not an error: TotalFolders returns 0 when no FolderSelHea record
       exists for this workspace yet, i.e. the folder list has never been enumerated. Opening the
       picker builds it. Both zero states get the same coral treatment because both need the same
       click. */
    Function ScopeHtml Returns String
        String sWS sCls sTxt
        Integer iSel iTot

        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Function_Return ""
        Get TotalSelectedFolders of (phoFolderSelHeaDD(ghoApplication)) to iSel
        Get TotalFolders         of (phoFolderSelHeaDD(ghoApplication)) to iTot
        If (iSel = 0) Begin
            Move "sc-scope sc-scope-warn" to sCls
            Move "None selected" to sTxt
        End
        Else Begin
            Move "sc-scope" to sCls
            Move (String(iSel) + " of " + String(iTot) + " selected") to sTxt
        End
        Function_Return (((DivOpen("sc-k sc-k-scope")) + 'Source folders' + CS_DivEnd) + (ClickableHtml("div", (sCls), CS_IdSelFolders, "", ((SpanOpen("sc-scope-ico")) + (DashIcon(CS_GlyphFolder)) + (CS_SpanEnd + (SpanOpen("sc-scope-t"))) + sTxt + CS_SpanEnd), "Choose which source folders DFRefactor works on. With none selected, a manual run cannot start, and the guided dashboard looks at every source folder in the workspace.")))
    End_Function

    /* THE WORKSPACE FILE'S FORMAT, while it still needs converting (Nils 2026-10-07: "how can the user
       convert an ini-file type .sws to JSON? There should at least be a clear option somewhere"). Shown
       only while it matters: a workspace is open, its .sws is still INI, and the target is DataFlex 26
       or later - the JSON format is a DataFlex 26 one. The click runs the same df-cli conversion dialog
       the Libraries dialog uses. One small file read per render, which a light builder can afford. */
    Function SwsFormatHtml Returns String
        String sWS sTarget
        Integer iFormat
        Boolean bBelow
        Handle hoInv

        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Function_Return ""
        Get psTargetDfVersion of ghoApplication to sTarget
        If (Trim(sTarget) = "") ;
            Function_Return ""
        Get Create (RefClass(cLibraryInventory)) to hoInv
        Get SwsFormatOf of hoInv sWS to iFormat
        Get IsVersionBelow of hoInv (Trim(sTarget)) "26.0" to bBelow
        Send Destroy of hoInv
        If (iFormat <> eSwsIni or bBelow = True) ;
            Function_Return ""
        Function_Return (((DivOpen("sc-k sc-k-scope")) + 'Workspace file' + CS_DivEnd) + (ClickableHtml("div", "sc-scope sc-scope-warn", "scconvert", "", ((SpanOpen("sc-scope-ico")) + (DashIcon(CS_GlyphFile)) + (CS_SpanEnd + (SpanOpen("sc-scope-t"))) + 'Older INI format ' + CS_MidDot + ' Convert to JSON' + CS_SpanEnd), "This workspace file is still in the older INI format. DataFlex 26 uses the JSON format, which is also the only format that can hold packages. Click to convert it - df-cli does it, and the libraries keep working.")))
    End_Function

    Function SideHtml Returns String
        String[] asRecent
        String sHtml sPath sName sRows
        Integer i iCount

        Move (DivOpen("sc-side")) to sHtml
        Move (sHtml + (((DivOpen("sc-k")) + 'Workspaces') + CS_DivEnd)) to sHtml
        // The OPEN folder (Nils 2026-10-05) - the glyph Program Setup's browse buttons carry. The closed one
        // stays on the Scope row below, where it stands for the folders themselves.
        Move (sHtml + (ClickableHtml("div", "sc-btn", "openws", "", ((DashIcon(CS_GlyphFolderOpen)) + 'Open workspace' + CS_Ellipsis), ""))) to sHtml
        Move (sHtml + (((DivOpen("sc-btn-sub")) + 'Choose the application' + CS_AposEntity + 's workspace file (.sws).') + CS_DivEnd)) to sHtml
        Move (sHtml + (ScopeHtml(Self))) to sHtml
        Move (sHtml + (SwsFormatHtml(Self))) to sHtml

        Move (sHtml + ((DivOpen("sc-div")) + CS_DivEnd)) to sHtml
        Move (sHtml + (((DivOpen("sc-k")) + 'Recent') + CS_DivEnd)) to sHtml
        Get ReadWorkspaceKeysFromRegistry of ghoApplication to asRecent
        Move (SizeOfArray(asRecent)) to iCount
        Move "" to sRows
        For i from 0 to (iCount - 1)
            Move asRecent[i] to sPath
            Get WorkspaceShortName of ghoTileMarkup sPath to sName
            /* The name LOADS it, the "x" REMOVES it, and they are SIBLINGS - the row wrapper
               carries no data-ServerOnClick, so the x resolves to its own id and never falls
               through to the load. Same arrangement the recent chips have always used. */
            Move (sRows + (DivOpen("sc-rc")) ;
                + (SpanOpenClick("sc-rc-txt", "recent", (String(i)), (ScEscaped(Self, sPath)))) ;
                + (SpanOpen("sc-rc-name")) + (ScEscaped(Self, sName)) + CS_SpanEnd ;
                + (SpanOpen("sc-rc-path")) + (ScEscaped(Self, sPath)) + CS_SpanEnd ;
                + CS_SpanEnd ;
                + (SpanOpenClick("sc-rc-x", "removerecent", (String(i)), "Remove from the recent list")) ;
                + CS_Times + CS_SpanEnd + CS_DivEnd) to sRows
        Loop
        If (iCount = 0) ;
            Move (((DivOpen("sc-rc-empty")) + 'Nothing yet ') + CS_EmDash + (' the workspaces you open appear here.' + CS_DivEnd)) to sRows
        Move (sHtml + (DivOpen("sc-rc-list")) + sRows + CS_DivEnd) to sHtml

        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    /* One Getting Started card. sAction "" renders the card INERT (no click anywhere on it) with
       sFoot as a plain reason line instead of a link - the grey-when-blocked, teaching-tip,
       never-clickable-but-dead rule the boards already follow, applied here.

       bInnerTargets moves the click INSIDE the card, for a card whose own contents are the doors.

       That is not a style choice, it is the framework's rule (Nils 2026-08-07, wiring the library
       card's per-group rows): a cWebHtmlBox click fires EVERY ancestor's ServerOnClick, so a row
       carrying "fnlibmod" inside a card carrying "fnlib" fires both, and whichever lands second
       overwrites the click waiting on the relay - the filtered jump silently becomes the unfiltered
       one, or the other way round, depending on walk order. Targets have to be SIBLINGS. The boards' stats
       card has always been built this way: .dash-stat itself carries no handler, and its five
       figures each carry their own.

       So the card div loses its handler and the FOOTER LINK takes it - the footer is the "all
       groups" door the card used to be, and it is the one part that already reads as a link. The
       card also loses cursor:pointer via .sc-card-tgt, because a card that looks clickable
       everywhere but only answers in four places is worse than one that never claimed to.

       CardHtmlEx is declared FIRST because CardHtml calls it: the function-style call compiles to
       a message lookup, and a message not yet compiled is err 4328. */
    Function CardHtmlEx String sId String sAccent String sIcon String sTitle String sBody String sExtra String sFoot String sAction Boolean bInnerTargets Returns String
        String sHtml

        If (sAction = "") ;
            Move (DivOpen(("sc-card sc-card-off sc-card-" + sAccent))) to sHtml
        Else If (bInnerTargets = True) ;
            Move (DivOpen(("sc-card sc-card-tgt sc-card-" + sAccent))) to sHtml
        Else ;
            Move (DivOpenClick(("sc-card sc-card-" + sAccent), sAction, "", "")) to sHtml
        Move (sHtml + (DivOpen("sc-card-ico")) + sIcon + CS_DivEnd) to sHtml
        Move (sHtml + (DivOpen("sc-card-h")) + sTitle + CS_DivEnd) to sHtml
        // A blank body renders NOTHING, not an empty <div>: the paragraph carries margins, so an
        // empty one would keep the space it was supposed to give back.
        If (sBody <> "") ;
            Move (sHtml + (DivOpen("sc-card-p")) + sBody + CS_DivEnd) to sHtml
        Move (sHtml + sExtra) to sHtml
        If (sAction = "") ;
            Move (sHtml + ((DivOpen("sc-card-foot")) + (SpanOpen("sc-card-none"))) + sFoot + (CS_SpanEnd + CS_DivEnd)) to sHtml
        Else Begin
            // sFootClick was an attribute built into a string, so the opening tag ended one
            // statement and the ">" arrived in the next. The branch that decides the attribute is
            // the branch that decides the tag, so it decides the tag.
            Move (sHtml + (DivOpen("sc-card-foot"))) to sHtml
            If (bInnerTargets = True) ;
                Move (sHtml + (SpanOpenClick("sc-lnk", sAction, "", ""))) to sHtml
            Else ;
                Move (sHtml + (SpanOpen("sc-lnk"))) to sHtml
            Move (sHtml + sFoot + ' ' + (DashIcon(CS_GlyphChevron)) + CS_SpanEnd + CS_DivEnd) to sHtml
        End
        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    // The plain card: every existing caller, unchanged - the click stays on the card itself.
    Function CardHtml String sId String sAccent String sIcon String sTitle String sBody String sExtra String sFoot String sAction Returns String
        Function_Return (CardHtmlEx(Self, sId, sAccent, sIcon, sTitle, sBody, sExtra, sFoot, sAction, False))
    End_Function

    /* One row of the function-library breakdown: name, count, and a bar whose width is the
       group's share of the library. The shape of the toolbox reads before any of the words do.

       AND THE ROW IS ITS OWN DOOR (Nils 2026-08-07: "the Dashboard's Function Library links
       constrains the grid depending on which function group is clicked - the same for the Start
       Center"). sAction is the id the board's OnClick maps to an FnGroup; blank leaves the row
       inert, which is what a zero-count group deserves - a filter that lands on an empty grid is
       a worse answer than no link.

       Why the row and not a separate link: the count IS the link on the boards' stats card, and a
       figure you can already read is a better target than a word added beside it. */

    /* THE TOUR'S POSTER FRAME - a still of the walkthrough, dressed as an embedded video (Nils
       2026-08-08: "a snap-shot of the animation in the middle, embedded so it looks like a video").

       DRAWN, NOT CAPTURED. A real screenshot would mean a binary asset that silently goes stale the
       first time the tour is edited - and the tour is a self-contained HTML page with no images in
       it at all, so there is nothing to capture that is not already markup. Rebuilding the frame in
       the same vocabulary keeps the card weightless, crisp at any DPI, and correct in the app's own
       colours: the tour's palette variables ARE application.css's values, the same hexes.

       THE FRAME IS THE CHECK SCENE - the tour's step 7, from the Check button DOWN (Nils
       2026-08-08). Only the centre of the scene is copied: the button, the two halves it starts,
       and the verdict. The heading, lede and note that surround it in the tour are the tour's
       furniture, not the picture.

       Why this frame and not the findings list or the plan: it is the only one containing the
       thing you PRESS. A poster showing a readout says "here is a report"; this one says "here is
       a button, and here is what it does" - which is the whole product in one still. It also
       carries the product's own Check button, so the first thing a new user sees on this card is
       the thing they will be looking for on the board.

       The compile half is red on purpose. A failing Check is the normal start of a version move,
       and it is what the rest of the lap exists to clear.

       NO CLICK TARGET OF ITS OWN. The whole card already carries data-ServerOnClick="watch", and a
       handler in here would fire alongside it - every ancestor's handler runs (see CardHtmlEx).
       This is decoration on a card that is already one big button.

       The window chrome, the centred play button and the part-filled scrubber are what make it read
       as a video rather than as one more readout; without the scrubber it is just a screenshot. */
    /* One row of the poster: a label, a state, and the coloured track under them. Written twice,
       differing only in the four words and which colour the fill wears. */
    Function _TourHalfHtml String sKey String sState String sStateCls String sFillCls Returns String
        Function_Return ((DivOpen("sc-vid-half")) ;
            + (SpanOpen("sc-vid-hk")) + sKey + CS_SpanEnd ;
            + (SpanOpen(sStateCls)) + sState + CS_SpanEnd ;
            + (SpanOpen("sc-vid-track")) + (ShapeHtml(sFillCls)) + CS_SpanEnd ;
            + CS_DivEnd)
    End_Function

    /* The Start Center's tour poster - a still of the guided dashboard mid-Check. Every class here
       is in application.css under .sc-vid*; nothing is styled from this side. */
    /* A lane's "why it is off" note: a warning sign, then the reason. Written out three times,
       differing only in the sentence - and the sentence is the only part worth reading. */
    Function _LaneWhyHtml String sWhy Returns String
        Function_Return ((DivOpen("sc-lane-why")) ;
            + CS_SpanOpen + CS_WarnSign + CS_SpanEnd ;
            + CS_SpanOpen + sWhy + CS_SpanEnd ;
            + CS_DivEnd)
    End_Function

    Function TourPosterHtml Returns String
        String sHtml

        // The chrome bar: three dots and the crumb.
        Move ((DivOpen("sc-vid")) + (DivOpen("sc-vid-bar")) ;
            + (SpanOpen("sc-vid-dots")) + (ShapeHtml("")) + (ShapeHtml("")) + (ShapeHtml("")) + CS_SpanEnd ;
            + (SpanOpen("sc-vid-crumb")) + 'Guided dashboard ' + CS_EmDash + ' Check' + CS_SpanEnd ;
            + CS_DivEnd) to sHtml

        Move (sHtml + (DivOpen("sc-vid-scene"))) to sHtml

        // The product's Check button, same hues as CheckWorkspaceFT's .cbtn - word on top, the
        // "compile + analyze" sub-label under it, exactly as the board draws it.
        Move (sHtml + (DivOpen("sc-vid-cbtn")) ;
            + CS_SpanOpen + CS_PlayTriangle + ' Check' + CS_SpanEnd ;
            + (SpanOpen("sc-vid-cbtn-sm")) + 'compile + analyze' + CS_SpanEnd ;
            + CS_DivEnd) to sHtml

        Move (sHtml + (_TourHalfHtml(Self, "Compile", ;
            ('failed ' + CS_MidDot + ' 4 errors'), "sc-vid-hv sc-vid-bad", "sc-vid-fill-bad"))) to sHtml
        Move (sHtml + (_TourHalfHtml(Self, "Source analyze", ;
            ('done ' + CS_MidDot + ' 251 findings'), "sc-vid-hv", "sc-vid-fill-scan"))) to sHtml

        Move (sHtml + (DivOpen("sc-vid-merged")) + CS_Check + ' merged into one list' + CS_DivEnd) to sHtml

        // INSIDE the scene, not beside it: the button has to centre on the FRAME, and the frame is
        // not the block - the chrome bar above and the scrubber below drag the block's midpoint
        // about 10px up from the picture's. Absolute, so it costs the bands no space.
        Move (sHtml + (DivOpen("sc-vid-play")) + (DashIcon(CS_GlyphPlayFilled)) + CS_DivEnd) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml

        // The scrubber under the frame.
        Move (sHtml + (DivOpen("sc-vid-prog")) + (ShapeHtml("")) + CS_DivEnd + CS_DivEnd) to sHtml

        Function_Return sHtml
    End_Function

    // sBarCls names one of the .sc-fg-bar i.fgb-* colours in application.css. It used to be the whole
    // CSS declaration, passed in as a string and pasted into a style= - the bar's colour is fixed per
    // group, so it was never a value; only the width is.
    Function FnRowHtml String sName Integer iCount Integer iTotal String sBarCls String sAction Returns String
        Integer iPct
        String sOpen
        Move 0 to iPct
        If (iTotal > 0) ;
            Move ((iCount * 100) / iTotal) to iPct
        If (sAction = "") ;
            Move (DivOpen("sc-fg-row")) to sOpen
        Else ;
            Move (DivOpenClick("sc-fg-row sc-fg-row-on", sAction, "" ;
                , ("Show only the " + sName + " functions"))) to sOpen
        Function_Return (sOpen + (SpanOpen("sc-fg-n")) + sName + (CS_SpanEnd + (SpanOpen("sc-fg-v"))) + String(iCount) + (CS_SpanEnd + (SpanOpen("sc-fg-bar"))) ;
            + '<i class="' + sBarCls + '" style="--w:' + String(iPct) + '%"></i>' ;
            + CS_SpanEnd + CS_DivEnd)
    End_Function

    /* THE MAIN AREA - one Getting Started tab, three cards, and the lane band beneath them.
       Three cards, not four (Nils 2026-08-06). The lanes were tried as a fourth column and it was
       the wrong weighting twice over: three of these are prepare / understand / watch and the
       lanes are begin, so four equal columns claimed four equal choices; and measured, the fourth
       column cost every card 54px of extra height while leaving each lane a quarter of the width
       its description needs. The band is where the row arrives.

       The lane descriptions are the point, not decoration. The old two-path flow diagram was
       dropped because the difference between the paths was hard to explain and users could not
       tell them apart - and the honest one-line separator is "no compile required": guided needs
       a compiler and a program, manual needs neither. That is also why the guided lane is the one
       that greys with no target, and the manual lane stays live: the screen never becomes a wall. */
    Function MainHtml Returns String
        String sHtml sComp sVer sNeeds sGuidedClass sGuidedWhy sExtra sWatchFoot sWatchAction
        String sWS sCopyFoot sCopyAction sManualClass sManualWhy sBandSub sTourPath
        String sCopyRec sCopiedRec sDay
        Integer iMod iTidy iU64 iOther iTotal

        Get psCompiler of ghoApplication to sComp
        Get psTargetDfVersion of ghoApplication to sVer
        Get psSWSFile of ghoApplication to sWS

        Move (DivOpen("sc-main")) to sHtml
        // A real tab with no dead siblings. It carries the shape and the underline, so a second
        // page drops in without a redesign; a greyed sibling would just be another dead control.
        Move (sHtml + (((DivOpen("sc-tabs")) + (DivOpen("sc-tab")) + 'Getting started') + CS_DivEnd + CS_DivEnd)) to sHtml
        Move (sHtml + (DivOpen("sc-cards"))) to sHtml

        /* (a) MAKE A WORKSPACE COPY - TWO prerequisites, not one (Nils 2026-08-06).
          It copies THE LOADED WORKSPACE: RunWorkspaceCopy opens with
          "Get psSWSFile ... If (sSws = "") Function_Return False", so with none open the card
          was offering an action that returns immediately - the dead-button pattern, in the
          screen written to remove it. The first cut gated on the target alone.

          The two are named in the order they BLOCK, not the order they appear in the sidebar:
          with no workspace there is nothing to copy at all, while with no target there is
          something to copy and only the derived .sws is missing. So the workspace is asked for
          first even though Target sits above it.

          It deliberately does NOT mention retargeting libraries - the copy and the derived .sws
          are built and live-verified, that is not. */
        Move "copy" to sCopyAction
        Move "Choose what to copy" to sCopyFoot
        Move "" to sCopyRec
        Move "" to sCopiedRec
        If (sWS <> "") Begin
            Get WorkspaceCopyOriginRecord of ghoApplication sWS to sCopyRec
            If (sCopyRec = "") ;
                Get WorkspaceCopyMadeRecord of ghoApplication sWS to sCopiedRec
        End
        If (sWS = "") Begin
            Move (((DivOpen("sc-needs sc-needs-off")) + 'Open a workspace first. This copies the workspace that is open. ') + (BoldText("Use Open workspace on the left.")) + CS_DivEnd) to sNeeds
            Move "" to sCopyAction
            Move "Open a workspace first" to sCopyFoot
        End
        /* A COPY IS NOT OFFERED A COPY (Nils 2026-10-07: "It doesn't make much sense to copy a copy, does
           it? ... it can be confusing to see the suggestion to copy when it already has been done").
           RecordWorkspaceCopy remembers each copy made here, so the card can tell which side of a copy
           the open workspace is. The COPY gets the fact and no action. The ORIGINAL gets its copy and
           "Open the copy" - refactoring the original by mistake is the risk this card exists for, and a
           second copy beside the first helps nobody. Both come before the target test, because neither
           needs a target. A copy deleted or moved since is not believed (WorkspaceCopyMadeRecord), and
           the card offers a copy as before. The FOLDER is named, not the .sws: from DataFlex 26 a copy's
           .sws keeps the original's name, so the folder is what tells the two apart. */
        Else If (sCopyRec <> "") Begin
            Move (WorkspaceCopyRecordDateText(sCopyRec)) to sDay
            If (sDay <> "") ;
                Move (", made on " + sDay) to sDay
            Move ((DivOpen("sc-needs")) + 'This workspace is a copy of the one in ' ;
                + (BoldText(ScFolderOf(Self, WorkspaceCopyRecordPath(sCopyRec)))) ;
                + sDay + '. The original is untouched, so work on this one directly.' + CS_DivEnd) to sNeeds
            Move "" to sCopyAction
            Move "Already a copy" to sCopyFoot
        End
        Else If (sCopiedRec <> "") Begin
            Move (WorkspaceCopyRecordDateText(sCopiedRec)) to sDay
            If (sDay <> "") ;
                Move (" on " + sDay) to sDay
            Move ((DivOpen("sc-needs")) + 'A copy of this workspace was made' + sDay + ', in ' ;
                + (BoldText(ScFolderOf(Self, WorkspaceCopyRecordPath(sCopiedRec)))) ;
                + '. Work on the copy, so that this original stays as it is.' + CS_DivEnd) to sNeeds
            Move "opencopy" to sCopyAction
            Move "Open the copy" to sCopyFoot
        End
        Else If (sComp = "") Begin
            Move (((DivOpen("sc-needs sc-needs-off")) + 'Choose the target DataFlex version first. The copy gets its own workspace file (.sws) for that version. ') + (BoldText("Choose it at the top.")) + CS_DivEnd) to sNeeds
            Move "" to sCopyAction
            Move "Choose a DataFlex version first" to sCopyFoot
        End
        Else ;
            Move ((DivOpen("sc-needs")) + 'The copy gets its own workspace file (.sws) for ' ;
                + (BoldHtml('DataFlex' * sVer)) + '.' + CS_DivEnd) to sNeeds
        Move (sHtml + (CardHtml(Self, "copy", "copy", (DashIcon(CS_GlyphStack)), "Make a workspace copy", "DFRefactor changes the source files directly. Copy the workspace first and work on the copy. The original stays as it is, so you can still build from it.", sNeeds, sCopyFoot, sCopyAction))) to sHtml

        // (b) THE LIBRARY. Counted live through the same CountFnGroup the boards' stats card uses,
        //     so this figure and that one cannot drift.
        Get CountFnGroup of ghoTileMarkup eFnGroupModernization to iMod
        Get CountFnGroup of ghoTileMarkup eFnGroupCleanup       to iTidy
        Get CountFnGroup of ghoTileMarkup eFnGroupUnicode64     to iU64
        Get CountFnGroup of ghoTileMarkup eFnGroupOther         to iOther
        Move (iMod + iTidy + iU64 + iOther) to iTotal
        /* Each row opens the library FILTERED to its own group, exactly as the boards' figures do
           - same four ids, so both screens meet the grid through the one SetFnGroupFilterEx path.
           A zero-count group passes "" and stays inert rather than offering a link to an empty
           grid. The footer keeps the unfiltered door. */
        Move (DivOpen("sc-fg")) to sExtra
        Move (sExtra + (FnRowHtml(Self, "Modernization", iMod,   iTotal, "fgb-mod"  , (If(iMod   > 0, "fnlibmod",   ""))))) to sExtra
        Move (sExtra + (FnRowHtml(Self, "Tidy Up",       iTidy,  iTotal, "fgb-tidy" , (If(iTidy  > 0, "fnlibtidy",  ""))))) to sExtra
        Move (sExtra + (FnRowHtml(Self, "x64 + Unicode", iU64,   iTotal, "fgb-u64"  , (If(iU64   > 0, "fnlibu64",   ""))))) to sExtra
        Move (sExtra + (FnRowHtml(Self, "Other",         iOther, iTotal, "fgb-other", (If(iOther > 0, "fnlibother", ""))))) to sExtra
        Move (sExtra + CS_DivEnd) to sExtra
        Move (sHtml + (CardHtmlEx(Self, "fnlib", "fns", (DashIcon(CS_GlyphListcheck)), (String(iTotal) + " refactoring functions"), "Each one makes one kind of change to the source code and has been developed meticulously. More than 3,000 unit tests check them and run again after every change to DFRefactor, so a change that breaks something is caught before a release.", sExtra, "Show all functions", "fnlib", True))) to sHtml

        // (c) WATCH IT WORK - live only when the shipped page is actually on disk. See CS_SCTourFile.
        Get TourPagePath to sTourPath
        If (sTourPath = "") Begin
            Move "" to sWatchAction
            Move "The walkthrough page is missing" to sWatchFoot
        End
        Else Begin
            Move "watch" to sWatchAction
            Move ("Play " + CS_EmDash + " opens in your browser") to sWatchFoot
        End
        /* NO BODY LINE on this card (Nils 2026-08-08). It read "One lap end to end: pick a program,
           Check, run the plan, tidy up, done" - which stopped being true when the walkthrough grew
           its setup half: the lap now opens with the target, the workspace copy and the folder
           scope, none of which that sentence mentions. Rather than restate twelve steps in one
           line, the card says nothing: the poster below it IS the description, and the two lines
           it gives back are the tallest card's height, which all three cards inherit. */
        Move (sHtml + (CardHtml(Self, "watch", "watch", (DashIcon(CS_GlyphVideo)), "Watch DFRefactor in action", "", (TourPosterHtml(Self)), sWatchFoot, sWatchAction))) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml

        /* ---- THE TWO DOORS. BOTH REQUIRE A WORKSPACE (Nils 2026-08-06) ----

           A lane used to ask for a workspace and then go: with none open it popped the .sws dialog
           and carried on into the board. That reads as helpful and is not - it means the screen has
           two places that open a workspace, and the one you did not use is the one on the left with
           the recent list beside it. Requiring it instead makes the sequence single-file: choose a
           target, open a workspace, then pick a lane - each step lit only once the one before it is
           satisfied, which is the same rule the copy card follows.

           GUIDED needs BOTH, MANUAL needs only the workspace. That is not an inconsistency, it is
           the difference between the lanes stated in behaviour: a Check compiles, so it needs a
           compiler; a manual run never compiles, so it does not. The band's own subtitle says so
           when the target is what is missing, and the manual lane stays live in that state - the
           screen offers a working way in rather than locking both doors. */
        // Driven by LaneState, the same function the masthead's quick links read - so the band and
        // the links cannot disagree about which doors are open. (The literal sWS/sComp tests that
        // used to live here are what LaneState now holds.)
        Move "" to sGuidedWhy
        Move "" to sManualWhy
        If ((LaneState(Self)) = 0) Begin
            Move "sc-lane sc-lane-guided sc-lane-off" to sGuidedClass
            Move "sc-lane sc-lane-manual sc-lane-off" to sManualClass
            Move (_LaneWhyHtml(Self, 'Open a workspace first.')) to sGuidedWhy
            Move (_LaneWhyHtml(Self, 'Open a workspace first.')) to sManualWhy
            Move "Open a workspace on the left. Both dashboards work on the workspace that is open." to sBandSub
        End
        Else Begin
            Move "sc-lane sc-lane-manual" to sManualClass
            If ((LaneState(Self)) = 1) Begin
                Move "sc-lane sc-lane-guided sc-lane-off" to sGuidedClass
                Move (_LaneWhyHtml(Self, 'It compiles the program. Choose the target DataFlex version first.')) to sGuidedWhy
                Move "Manual refactoring is ready. Guided refactoring compiles the program, so it needs the target DataFlex version first." to sBandSub
            End
            Else Begin
                Move "sc-lane sc-lane-guided" to sGuidedClass
                Move ("Both work on " + (BoldHtml((ScEscaped(Self, WorkspaceShortName(ghoTileMarkup, sWS))))) + ". You can switch between them at any time.") to sBandSub
            End
        End
        Move (sHtml + (DivOpen("sc-band")) + (DivOpen("sc-band-head")) ;
                + (SpanOpen("sc-band-h")) + 'Ready to start' + CS_SpanEnd ;
                + (SpanOpen("sc-band-s")) + sBandSub + CS_SpanEnd ;
                + CS_DivEnd + (DivOpen("sc-band-lanes"))) to sHtml

        // The lane opens clickable only when there is somewhere to go. It used to be built in
        // three steps - tag, maybe an attribute, then the ">" on the NEXT statement - which is why
        // the opening tag was split across three lines of DataFlex and a literal.
        If (sWS <> "" and sComp <> "") ;
            Move (sHtml + (DivOpenClick(sGuidedClass, "guided", "", ""))) to sHtml
        Else ;
            Move (sHtml + (DivOpen(sGuidedClass))) to sHtml
        // The sparkles, as the toolbar's Guided Dashboard button (2026-10-04). It was the ticked list, which is
        // the refactoring list's glyph - the function-library card above uses it - so it said two things.
        Move (sHtml + (DivOpen("sc-lane-t")) + (DashIcon(CS_GlyphSparkles)) + ('Guided refactor' + CS_DivEnd + ((DivOpen("sc-lane-s")) + (BoldText("The recommended choice.")) + ' A Check compiles the program and runs an advanced analysis of the source code to find what needs to be changed. You get one list, the most serious first, and a plan to fix it. You approve the plan and the DFRefactor engine runs it.') + CS_DivEnd) + sGuidedWhy) to sHtml
        // "Dashboard..." on BOTH lanes (Nils 2026-08-06). It names the DESTINATION rather than
        // the act, which is what the two links actually differ in - and they do not need to
        // differ in wording, because the lane title directly above already says which one.
        If (sWS <> "" and sComp <> "") ;
            Move (sHtml + ((DivOpen("sc-lane-foot")) + (SpanOpen("sc-lane-go")) + 'Dashboard') + CS_Ellipsis + ' ' + (DashIcon(CS_GlyphChevron)) + (CS_SpanEnd + CS_DivEnd)) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml

        // The lane opens clickable only when there is somewhere to go. It used to be built in
        // three steps - tag, maybe an attribute, then the ">" on the NEXT statement - which is why
        // the opening tag was split across three lines of DataFlex and a literal.
        If (sWS <> "") ;
            Move (sHtml + (DivOpenClick(sManualClass, "manual", "", ""))) to sHtml
        Else ;
            Move (sHtml + (DivOpen(sManualClass))) to sHtml
        // The Manual Dashboard's own hand (2026-10-04) - CS_GlyphManual, the toolbar button's artwork traced into a
        // glyph - so the lane, the button and the board's tab show one picture.
        Move (sHtml + (DivOpen("sc-lane-t")) + (DashIcon(CS_GlyphManual)) + ('Manual refactor' + CS_DivEnd + ((DivOpen("sc-lane-s")) + (BoldText("Not suggested")) + ' unless you already know exactly what needs to be changed. You pick the files or folders and the refactoring functions and run them. The compiler is not used, and the source code is not analyzed first. Useful for one function on one file or folder, or for running a function again after a change made by hand.')) + CS_DivEnd + sManualWhy) to sHtml
        If (sWS <> "") ;
            Move (sHtml + ((DivOpen("sc-lane-foot")) + (SpanOpen("sc-lane-go")) + 'Dashboard') + CS_Ellipsis + ' ' + (DashIcon(CS_GlyphChevron)) + (CS_SpanEnd + CS_DivEnd)) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml

        Move (sHtml + (CS_DivEnd + CS_DivEnd)) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    /* The whole board. ONE tile, because two span-6 tiles do not level their heights - see the
       header note. The wrapper carries NO data-ServerOnClick; every control carries its own.

       Masthead and Target strip are FULL WIDTH, above the two columns, so they cost the sidebar
       and the main area exactly the same height and cannot skew the two against each other - the
       defect that moving the target out of the sidebar was fixing. */
    Function BoardHtml Returns String
        Function_Return ((DivOpen("sc-wrap")) + (MastheadHtml(Self)) + (TargetStripHtml(Self)) ;
                         + (DivOpen("sc")) + (SideHtml(Self)) + (MainHtml(Self)) + (CS_DivEnd + CS_DivEnd))
    End_Function

    /* The board's own deferred work, on a native tick: the repaint that several Activate fires per tab switch
       coalesce into (CI_SCRefresh), and the trip to Select Folders after a load that left nothing selected
       (CI_SCSelectFolders) - OnWorkspaceLoaded runs on a broadcast during the load, and a view activated from
       inside that is how a screen ends up half-painted over a board that is still clearing. The page clicks run
       in oTile_Board's OnHtmlClick, after the web click has returned (the library's click relay), since
       2026-10-07. */
    Object oSCDeferTimer is a cFTDeferTimer
        Procedure OnDeferredAction Integer iAction String sParam
            If (iAction = CI_SCRefresh) ;
                Send RefreshBoard of (oStartCenter_vw(Self))
            If (iAction = CI_SCSelectFolders) ;
                Send Activate_oSelectFoldersView of (Client_Id(phoMainPanel(ghoApplication)))
        End_Procedure
    End_Object

    Object oWebHost is a cFTDbLocalWebControlHost
        Set Size to 500 649
        Set Location to 0 2
        Set piColumnCount to 12
        Set peAnchors to anAll

        Set Main_DD to oSysFile_DD
        Set Server  to oSysFile_DD

        Object oTile_Board is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // Bare Self, matching the trail's proven construct-time seeds (StepsTileHtml(Self) /
            // BodyTileHtml(Self) on its own tiles). The oStartCenter_vw(Self) form is what the
            // OnClick handlers use, but that is a RUNTIME lookup - this one runs while the view is
            // still constructing, and there is no reason to make first paint depend on a name
            // resolution when the builder is reachable directly.
            
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. It is the board the runtime seeds (no workspace loaded), trimmed to
            // fit the compiler: the recent list is two made-up entries rather than this machine's own,
            // the hover titles and the click wiring (data-ServerOnClick) are left out, and the icons'
            // five shared stroke attributes are given once in a style rule; the Designer shows the same
            // board. ONE icon is not drawn here: the Manual lane's hand is traced artwork, 1.9 KB written
            // out, so its place is a span naming a class (sc-ico-manual, application.css) that lays the
            // glyph file on as a mask. Written as a multi-line string - one line per block and icon, about 200 columns,
            // indented by nesting, broken only between two tags or at a space (the compiler strips the
            // indent and keeps the line breaks, which HTML and SVG path data read as whitespace). The
            // compiler's 4319 limit ("Macro buffer exceeded") is on the whole statement, indentation
            // included - measured: 12.2 KB compiles, 13.0 KB does not; this one is 11.4 KB. The runtime
            // expression sits in End_Construct_Object below. Regenerated by hand (the Tools script skips
            // this view: the dump carries the machine's own workspace paths).
            Set psHtml to """
            <style>.sc-wrap svg{fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}</style>
            <div class="sc-wrap">
                <div class="sc-mast">
                    <div class="sc-mast-left">
                        <div class="sc-mast-t"><span class="sc-mast-logo"><img src="Images/DFRefactorMark.png" alt=""></span>DFRefactor</div>
                        <div class="sc-mast-c">&#47;*START CENTER*&#47;</div></div>
                    <div class="sc-mast-nav"><span class="sc-mast-lnk sc-mast-lnk-off">Guided dashboard <svg width="24" height="24" viewBox="0 0 24 24">
                            <path d="M9 6l6 6l-6 6"/></svg></span><span class="sc-mast-lnk sc-mast-lnk-off">Manual dashboard <svg width="24" height="24" viewBox="0 0 24 24">
                            <path d="M9 6l6 6l-6 6"/></svg></span></div></div>
                <div class="sc-topbar">
                    <div class="sc-topbar-k">Target DataFlex version</div>
                    <div class="sc-topbar-row">
                        <div class="sc-tgt sc-tgt-wide"><span class="sc-tgt-ico">
                            <svg width="24" height="24" viewBox="0 0 24 24">
                                <path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924
                                    0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573
                                    -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31
                                    2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6
                                    0"/></svg></span><span class="sc-tgt-v">DataFlex 26.0</span></div><span class="sc-topbar-comp">df-cli.exe (x64) &middot; click to change</span></div></div>
                <div class="sc">
                    <div class="sc-side">
                        <div class="sc-k">Workspaces</div>
                        <div class="sc-btn">
                            <svg width="24" height="24" viewBox="0 0 24 24">
                                <path d="M5 19l2.757 -7.351a1 1 0 0 1 .936 -.649h12.307a1 1 0 0 1 .986 1.164l-.996 5.211a2 2 0 0 1 -1.964 1.625h-14.026a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3
                                    3h7a2 2 0 0 1 2 2v2"/></svg>Open workspace&hellip;</div>
                        <div class="sc-btn-sub">Choose the application&#39;s workspace file (.sws).</div>
                        <div class="sc-div"></div>
                        <div class="sc-k">Recent</div>
                        <div class="sc-rc-list">
                            <div class="sc-rc"><span class="sc-rc-txt"><span class="sc-rc-name">Order Entry</span><span class="sc-rc-path">C:\DataFlex 26.0 Examples\Order Entry\Order
                                Entry.sws</span></span><span class="sc-rc-x">&times;</span></div>
                            <div class="sc-rc"><span class="sc-rc-txt"><span class="sc-rc-name">Inventory</span><span class="sc-rc-path">C:\Projects\Inventory\Inventory.sws</span></span><span class="sc-rc-x">&times;</span></div></div></div>
                    <div class="sc-main">
                        <div class="sc-tabs">
                            <div class="sc-tab">Getting started</div></div>
                        <div class="sc-cards">
                            <div class="sc-card sc-card-off sc-card-copy">
                                <div class="sc-card-ico">
                                    <svg width="24" height="24" viewBox="0 0 24 24"><path d="M12 4l-8 4l8 4l8 -4l-8 -4 M4 12l8 4l8 -4 M4 16l8 4l8 -4"/></svg></div>
                                <div class="sc-card-h">Make a workspace copy</div>
                                <div class="sc-card-p">DFRefactor changes the source files directly. Copy the workspace first and work on the copy. The original stays as it is, so you can still build from it.</div>
                                <div class="sc-needs sc-needs-off">Open a workspace first. This copies the workspace that is open. <b>Use Open workspace on the left.</b></div>
                                <div class="sc-card-foot"><span class="sc-card-none">Open a workspace first</span></div></div>
                            <div class="sc-card sc-card-tgt sc-card-fns">
                                <div class="sc-card-ico">
                                    <svg width="24" height="24" viewBox="0 0 24 24"><path d="M3.5 5.5l1.5 1.5l2.5 -2.5 M3.5 11.5l1.5 1.5l2.5 -2.5 M3.5 17.5l1.5 1.5l2.5 -2.5 M11 6l9 0 M11 12l9 0 M11 18l9 0"/></svg></div>
                                <div class="sc-card-h">132 refactoring functions</div>
                                <div class="sc-card-p">Each one makes one kind of change to the source code and has been developed meticulously. More than 3,000 unit tests check them and run again
                                    after every change to DFRefactor, so a change that breaks something is caught before a release.</div>
                                <div class="sc-fg">
                                    <div class="sc-fg-row sc-fg-row-on"><span class="sc-fg-n">Modernization</span><span class="sc-fg-v">99</span><span class="sc-fg-bar"><i class="fgb-mod" style="--w:75%"></i></span></div>
                                    <div class="sc-fg-row sc-fg-row-on"><span class="sc-fg-n">Tidy Up</span><span class="sc-fg-v">14</span><span class="sc-fg-bar"><i class="fgb-tidy" style="--w:10%"></i></span></div>
                                    <div class="sc-fg-row sc-fg-row-on"><span class="sc-fg-n">x64 + Unicode</span><span class="sc-fg-v">18</span><span class="sc-fg-bar"><i class="fgb-u64" style="--w:13%"></i></span></div>
                                    <div class="sc-fg-row sc-fg-row-on"><span class="sc-fg-n">Other</span><span class="sc-fg-v">1</span><span class="sc-fg-bar"><i class="fgb-other" style="--w:0%"></i></span></div></div>
                                <div class="sc-card-foot"><span class="sc-lnk">Show all functions <svg width="24" height="24" viewBox="0 0 24 24">
                                        <path d="M9 6l6 6l-6 6"/></svg></span></div></div>
                            <div class="sc-card sc-card-watch">
                                <div class="sc-card-ico">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke-linecap="round" stroke-linejoin="round"><g
                                        transform="translate(12 12) scale(1.22) translate(-12 -12)"><rect x="3" y="6" width="12" height="12" rx="2" fill="rgb(99,102,241)"/>
                                        <path d="M15 10l4.553 -2.276a1 1 0 0 1 1.447 .894v6.764a1 1 0 0 1 -1.447 .894l-4.553 -2.276v-4z" fill="rgb(167,139,250)"/><circle cx="8" cy="12" r="2.2"
                                            fill="rgb(255,255,255)" opacity="0.92"/></g></svg></div>
                                <div class="sc-card-h">Watch DFRefactor in action</div>
                                <div class="sc-vid">
                                    <div class="sc-vid-bar"><span class="sc-vid-dots"><i></i><i></i><i></i></span><span class="sc-vid-crumb">Guided dashboard &mdash; Check</span></div>
                                    <div class="sc-vid-scene">
                                        <div class="sc-vid-cbtn"><span>&#9654; Check</span><span class="sc-vid-cbtn-sm">compile + analyze</span></div>
                                        <div class="sc-vid-half"><span class="sc-vid-hk">Compile</span><span class="sc-vid-hv sc-vid-bad">failed &middot; 4 errors</span><span class="sc-vid-track"><i class="sc-vid-fill-bad"></i></span></div>
                                        <div class="sc-vid-half"><span class="sc-vid-hk">Source analyze</span><span class="sc-vid-hv">done &middot; 251 findings</span><span class="sc-vid-track"><i class="sc-vid-fill-scan"></i></span></div>
                                        <div class="sc-vid-merged">&#10003; merged into one list</div>
                                        <div class="sc-vid-play">
                                            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg></div></div>
                                    <div class="sc-vid-prog"><i></i></div></div>
                                <div class="sc-card-foot"><span class="sc-lnk">Play &mdash; opens in your browser <svg width="24" height="24" viewBox="0 0 24 24">
                                        <path d="M9 6l6 6l-6 6"/></svg></span></div></div></div>
                        <div class="sc-band">
                            <div class="sc-band-head"><span class="sc-band-h">Ready to start</span><span class="sc-band-s">Open a workspace on the left. Both dashboards work on the workspace that is open.</span></div>
                            <div class="sc-band-lanes">
                                <div class="sc-lane sc-lane-guided sc-lane-off">
                                    <div class="sc-lane-t">
                                        <svg width="24" height="24" viewBox="0 0 24 24">
                                            <path d="M16 18a2 2 0 0 1 2 2a2 2 0 0 1 2 -2a2 2 0 0 1 -2 -2a2 2 0 0 1 -2 2zm0 -12a2 2 0 0 1 2 2a2 2 0 0 1 2 -2a2 2 0 0 1 -2 -2a2 2 0 0 1 -2 2zm-7 12a6 6 0 0 1 6
                                                -6a6 6 0 0 1 -6 -6a6 6 0 0 1 -6 6a6 6 0 0 1 6 6z"/></svg>Guided refactor</div>
                                    <div class="sc-lane-s"><b>The recommended choice.</b> A Check compiles the program and runs an advanced analysis of the source code to find what
                                        needs to be changed. You get one list, the most serious first, and a plan to fix it. You approve the plan and the DFRefactor engine runs it.</div>
                                    <div class="sc-lane-why"><span>&#9888;</span><span>Open a workspace first.</span></div>
                                    <div class="sc-lane-foot"><span class="sc-lane-go">Dashboard&hellip; <svg width="24" height="24" viewBox="0 0 24 24">
                                            <path d="M9 6l6 6l-6 6"/></svg></span></div></div>
                                <div class="sc-lane sc-lane-manual sc-lane-off">
                                    <div class="sc-lane-t"><span class="sc-ico-manual"></span>Manual refactor</div>
                                    <div class="sc-lane-s"><b>Not suggested</b> unless you already know exactly what needs to be changed. You pick the files or folders and the refactoring functions and
                                        run them. The compiler is not used, and the source code is not analyzed first. Useful for one function on one file or folder, or for running a function
                                        again after a change made by hand.</div>
                                    <div class="sc-lane-why"><span>&#9888;</span><span>Open a workspace first.</span></div></div></div></div></div></div></div>
            """

            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (BoardHtml(Self))
            End_Procedure

            /* Every click's work runs here, after the web click has returned (the library's click relay) - a
               dialog, a load, a view switch. Written as a Case rather than a ladder of Else Ifs (Nils
               2026-08-25) - the ids then read as a list of what this board answers, which is the useful thing
               about it. */
            Procedure OnHtmlClick String sId String sParam
                Integer iIdx eGroup
                String sFile sWS sTarget
                String[] asRecent
                Boolean bOk bBelow
                Handle hoInv

                Case Begin
                    Case (sId = "recent")
                        Move sParam to iIdx
                        Get ReadWorkspaceKeysFromRegistry of ghoApplication to asRecent
                        // UpdateWorkspaceSelectorDisplay records the workspace in the recent list itself (2026-09-03).
                        If (iIdx >= 0 and iIdx < (SizeOfArray(asRecent))) ;
                            Send UpdateWorkspaceSelectorDisplay of ghoApplication asRecent[iIdx]
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "removerecent")
                        Move sParam to iIdx
                        Send RemoveRecentWorkspace of ghoBoardActions iIdx
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "openws")
                        Get SelectWorkspaceFile of ghoApplication to sFile
                        If (sFile <> "") ;
                            Send UpdateWorkspaceSelectorDisplay of ghoApplication sFile
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "target")
                        // Modal, so it has closed by the time we repaint: the target version, the copy
                        // card's gate and the guided lane's gate all move together with it.
                        Send OpenCompilerSettings of ghoBoardActions
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "copy")
                        /* The migration copy-scope dialog, which lives on oMain (DFRefactorFT.src) and was
                           reachable only by the Alt+P development shortcut before this card gave it a home.
                           Reached the same way the Split View toolbar button reaches SplitViewWorkspace. */
                        Send ActivateCopyScopeDialog of (phoMainPanel(ghoApplication))
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "opencopy")
                        /* The original's copy, read again at click time rather than carried from the render:
                           the copy could have been deleted between paint and click, and then there is nothing
                           to open - the repaint shows the card offering a copy instead. Loaded the way a Recent
                           row is. */
                        Get psSWSFile of ghoApplication to sWS
                        Get WorkspaceCopyMadeRecord of ghoApplication sWS to sFile
                        Move (WorkspaceCopyRecordPath(sFile)) to sFile
                        If (sFile <> "") ;
                            Send UpdateWorkspaceSelectorDisplay of ghoApplication sFile
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    Case (sId = "scconvert")
                        /* The workspace file row (Nils 2026-10-07). The same df-cli conversion dialog the
                           Libraries dialog uses - it shows df-cli's output and judges by the FILE. The target is
                           floored at 26.0 the way the Libraries dialog floors it: the JSON format is a DataFlex
                           26 one. With no df-cli beside the selected compiler there is nothing to run it with,
                           so the box says what to do instead. */
                        Get psSWSFile of ghoApplication to sWS
                        If (sWS <> "") Begin
                            If (DfCliPath() = "") Begin
                                Send FTStopBox ("This workspace file is in the older INI format. Converting it needs df-cli.exe, and none was found beside the selected compiler. Choose a DataFlex 26 compiler as the target DataFlex version, or convert it by hand:" + Character(10) + "   df-cli convert --df 26.0 " + '"' + sWS + '"') "Converting needs df-cli"
                            End
                            Else Begin
                                Get psTargetDfVersion of ghoApplication to sTarget
                                Move (Trim(sTarget)) to sTarget
                                Get Create (RefClass(cLibraryInventory)) to hoInv
                                Get IsVersionBelow of hoInv sTarget "26.0" to bBelow
                                Send Destroy of hoInv
                                If (sTarget = "" or bBelow = True) ;
                                    Move "26.0" to sTarget
                                Get ConvertWorkspaceToJson sWS sTarget to bOk
                            End
                        End
                        Send RefreshBoard of (oStartCenter_vw(Self))
                        Case Break
                    /* The library, all groups or one - Select Functions in browse mode (the True): inspect
                       the toolbox, no Run button. The same two lines the Manual board's library figures run. */
                    Case (sId = CS_IdFnLib or sId = "fnlibmod" or sId = "fnlibtidy" ;
                          or sId = "fnlibu64" or sId = "fnlibother")
                        Case Begin
                            Case (sId = "fnlibmod")
                                Move eFnGroupModernization to eGroup
                                Case Break
                            Case (sId = "fnlibtidy")
                                Move eFnGroupCleanup to eGroup
                                Case Break
                            Case (sId = "fnlibu64")
                                Move eFnGroupUnicode64 to eGroup
                                Case Break
                            Case (sId = "fnlibother")
                                Move eFnGroupOther to eGroup
                                Case Break
                            Case Else
                                Move eFnGroupAll to eGroup
                                Case Break
                        Case End
                        Send Activate_oSelectFunctionsView of (Client_Id(phoMainPanel(ghoApplication)))
                        Send SetFnGroupFilterEx of oSelectFunctionsView eGroup True
                        Case Break
                    Case (sId = "watch")
                        /* The shipped walkthrough, opened in the user's own browser. The path is re-resolved
                           here rather than carried from the render: the card was drawn from a probe that may
                           be a tick old, and RDCOpenHelpPage refuses a path that is not an existing .htm/.html
                           anyway - so a page deleted between paint and click is a no-op, not a fault. */
                        Get TourPagePath of (oStartCenter_vw(Self)) to sFile
                        If (sFile <> "") ;
                            Send RDCOpenHelpPage sFile
                        Case Break
                    Case (sId = "guided" or sId = "manual")
                        /* THE TWO DOORS. A workspace must already be loaded (Nils 2026-08-06), so this no
                           longer pops the .sws dialog on the way through - a lane with none open renders inert
                           and cannot reach here. The guard stays as a backstop, not as a second route in: a
                           render can be a tick behind the state that produced it (the workspace could close
                           between paint and click), and the honest answer to that race is to do nothing rather
                           than to open a dialog the user did not ask this control for. */
                        Get psSWSFile of ghoApplication to sWS
                        If (sWS = "") ;
                            Send RefreshBoard of (oStartCenter_vw(Self))
                        Else If (sId = "guided") ;
                            Send Activate_oDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Else ;
                            Send Activate_oManualDashboard_vw of (Client_Id(phoMainPanel(ghoApplication)))
                        Case Break
                    Case (sId = CS_IdSelFolders)
                        Send Activate_oSelectFoldersView of (Client_Id(phoMainPanel(ghoApplication)))
                        Case Break
                Case End
            End_Procedure
        End_Object
    End_Object

    Procedure RefreshBoard
        Send PushHtml of (oTile_Board(oWebHost(Self))) (BoardHtml(Self))
    End_Procedure

    /* A workspace opened anywhere repaints this screen - the recent list has just moved, and the
       crumb the boards carry was rendered from the same state.

       AND IF IT ARRIVED WITH NOTHING SELECTED, THE FOLDER PICKER OPENS (Nils 2026-08-06: choosing
       folders is essential after a workspace is opened or copied). Both routes land here: the
       Start Center's own open, and the migration copy, whose oCopyDeferTimer finishes with
       UpdateWorkspaceSelectorDisplay - which is what broadcasts this.

       ONE-SHOT PER WORKSPACE PER SESSION, keyed on the .sws (psFolderPromptedWS), the same shape as
       the Test Compile bar's Deep Scan suggestion. Without it this is a nag rather than a prompt:
       zero selected is a LEGITIMATE resting state - the guided Check reads it as "every source
       folder" - so someone who deliberately leaves it empty would be dragged into the grid on every
       single load. Latched BEFORE the navigation, so a cancelled trip does not re-arm it.

       Deferred, never called straight from here: this runs on a broadcast during a workspace load,
       and activating a view from inside that is how a screen ends up half-painted over a board that
       is still clearing. */
    /* A change made elsewhere repaints this screen too - a conversion (the Libraries dialog's offer on
       closing), a folder ticked in Select Folders - through the broadcast the boards already answer.
       Deferred like every repaint here, and never over an action that is already waiting: that
       action repaints when it has run. */
    Procedure RequestTileRefresh
        If (piPendingAction(oSCDeferTimer(Self)) = 0) ;
            Send ArmAction of oSCDeferTimer CI_SCRefresh
        Else ;
            Send Arm of oSCDeferTimer
    End_Procedure

    Procedure OnWorkspaceLoaded
        String sWS sPrompted
        Integer iSel

        Send RefreshBoard
        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Procedure_Return
        Get psFolderPromptedWS to sPrompted
        If (sWS = sPrompted) ;
            Procedure_Return
        Get TotalSelectedFolders of (phoFolderSelHeaDD(ghoApplication)) to iSel
        If (iSel <> 0) ;
            Procedure_Return
        Set psFolderPromptedWS to sWS
        Send ArmAction of oSCDeferTimer CI_SCSelectFolders
    End_Procedure

    // Repaint on entry: the target may have been changed from a board, and the recent list may
    // have grown. Deferred so the several Activate fires per tab switch coalesce into one.
    Procedure Activate Returns Integer
        Integer iRetVal

        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            Send ArmAction of oSCDeferTimer CI_SCRefresh
            /* The Start Center is a SURFACE too, and the only one that is not a board - which is the
               whole reason piLastSurface exists apart from piLastBoardView. Select Folders is reached
               straight from here (open or copy a workspace that ends up with no folders selected) and
               its crumb has to come back HERE, not to a board the user has not opened.

               Deliberately NOT stamping piLastBoardView: the Start Center is not a board, and
               claiming one would make the Editor's crumb and the Test Compile bar's guided gate
               follow a surface the user left. */
            Set piLastSurface of ghoApplication to eSurfaceStartCenter
        End
        Procedure_Return iRetVal
    End_Procedure

    Procedure Close_Panel
    End_Procedure

End_Object
