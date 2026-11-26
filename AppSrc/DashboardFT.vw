Use Windows.pkg
Use DFClient.pkg
Use cRDCDbView.pkg
Use cFTDeferTimer.pkg
Use FTPageIsUp.pkg                      // FTHostPageIsUp - can the host's page take a live push now? (RDCFlexTron)
Use FTAllWebControlClasses.pkg          // FT web controls (cFTWebHtmlBox, cFTWebCombo)
Use cFTDbLocalWebControlHost.pkg        // hosts the web content in this view
Use cSysFileDataDictionary.dd
Use RefactorConstants.h.pkg
Use FTInputBox.dg                       // FTInputBox - the prompt that asks for a name (RDCFlexTron; ConfirmDialogFT.dg until 2026-09-29)
Use FTMessageBox.dg                     // the box FTInfoBox / FTStopBox / FTYesNoBox / FTHtmlMessage show (RDCFlexTron; MessageBoxFT.dg until 2026-09-29)
Use BrowsePackagesFT.dg                 // ghoBrowsePackages - the click-to-install package picker, its own dialog (2026-08-16)
Use FTMarkupBuilders.pkg                // the HTML vocabulary - OpenHtml, IconLabel, the builders
Use RefactorFileIO.pkg                  // rfOpenOutput / rfCloseOutput - channel file I/O
Use cEncodingHelpers.pkg                // rfHtmlEscape and the encoding helpers
Use cFTLibraryReport.pkg                // ghoLibraryReport - the library data behind the Libraries tile
Use cDfCliPackages.pkg                  // PackageUpdateCheckEnabled / PublishWorkspaceUpdateScan - the package update scan
Use cFTTileMarkup.pkg                   // ghoTileMarkup - the shared tiles + the workspace crumb
Use cFTDeepScanDriver.pkg               // ghoDeepScanDriver - the scan lane, driven by this board and the manual one
Use cFTBoardActions.pkg                 // ghoBoardActions - Compare / Revert, offered by every board

// ==========================================================================================
// Check Workspace - the redesigned guided trail (branch guided-flow-redesign, Nils 2026-07-20).
// Replaces the old two-path dashboard with ONE trail: Select Program -> Check (compile + analyze)
// -> ONE severity-ranked findings list -> Run fix plan -> Tidy Up. (The mockup's separate
// "Clean" stage was dropped 2026-07-29: it never had a meaning, and its name said the same as
// Tidy Up, which is the one with a function group behind it.)
// See the agreed mock-up (artifact e08429f4). This increment renders the STEP-1 anchor as bands:
//   workspace  : the EXACT dashboard workspace tile (banner + recent chips) - see below
//   steps      : the stepper + "Main program" label
//   combo      : the main-program COMBO (shares CS_LastCompileKeyPrefix with Test Compile)
//   body       : scope + Check + a placeholder where the findings list will grow
// Web-hosted (cDbLocalWebControlHost + tiles). A page click's work runs in its box's OnHtmlClick, after the
// web click has returned (the library's click relay), and reaches the dispatcher through RunClickAction -
// queued on oChkDeferTimer while a board render is in flight. A Broadcast, an analyze tail or the combo's
// change arms the timer, whose OnTimer works natively off the WebView2 pump (err 4410 otherwise).
//
// SHARED TILES: the Workspace, Target-version, Progress and action-row tiles come from ghoTileMarkup
// (cFTTileMarkup.pkg), so this board and the dashboard render the SAME markup with no drift. That used
// to be a borrow off oDashboard_vw; since 2026-07-31 it is a package neither view owns, which is what
// lets the dashboard be stripped or retired without this one going dark. The recent load/remove
// ACTIONS are still replicated here (they only call ghoApplication).
// COLOUR NOTE: the framework's application.css sets a DARK default text colour, so every text element in
// the OTHER tiles sets its colour explicitly (inheriting left "Scope" unreadable). RENDER NOTE: the
// psHtml builders run at first-paint, so they stay LIGHTWEIGHT - no recursive folder walks (that hung
// the tile blank); the workspace tile is seeded with a placeholder and rendered on Activate.
// ==========================================================================================

/* No Register_Object oDashboard_vw any more (2026-08-02). This view referenced that board for the
   four utility chips - which now run on its own timer through ghoBoardActions - and for a courtesy
   Progress repaint that the board does for itself on entry. The trail no longer names another
   screen, which is what the untangle was for. */
// The modal Compiler Settings picker (CompilerSetupFT.dg, Used before this view).
Register_Object oCompilerSetup_dg

/* The board's deferred-action selectors - which action the armed oChkDeferTimer should run.

   An Enum_List since 2026-08-10 (Nils): they were 26 hand-numbered Defines, and hand-numbering had
   already left a hole - a3b908a deleted "CI_ChkDashboard for 5" with the Old-dashboard link and the
   list jumped 4 -> 9. Now only the first carries a number, adding one is a line with no arithmetic,
   and deleting one leaves no gap to explain.

   SAFE TO RENUMBER because these values never leave the process: piPendingAction is only ever set
   from this family, nothing else shares the number space, and no value is written to the registry,
   a JSON file or the database. That last clause is the condition - if one of these is ever
   persisted, it stops being an enum member and has to be frozen at its value, the way
   CS_ModProgressDeepScanLabel is. */
Enum_List
    Define CI_ChkRefresh          for 1  // re-render the tiles + re-prime the combo
    Define CI_ChkAdjustScope             // "Select Folders" -> the Select Folders view
    Define CI_ChkResetScope              // Reset -> restore the whole-workspace scope (stub this increment)
    Define CI_ChkRunCheck                // Check -> Deep Scan (quiet, merged) + compile; analyze folds both lanes
    Define CI_ChkCompilerSetup           // Target-version tile -> pop the modal Compiler Settings picker
    Define CI_ChkRenderFindings          // guided Check done -> render the findings list + bring this view forward
    Define CI_ChkViewCollisions          // findings "Check declarations" -> FunctionReturnMismatchReport over the CURRENT scope
    Define CI_ChkGuardGlobals            // findings "Guard them"  -> run GuardRedundantGlobalFunctions (WRITES source)
    Define CI_ChkOpenSource              // findings file cell -> open the editor at "<file>|<line>"
    Define CI_ChkRunPlan                 // findings "Run the refactoring plan" -> the panel's StartAutoSelect
    Define CI_ChkClearBoard              // findings "Clear board" -> wipe the grid; then ask about the saved Check
    Define CI_ChkAskDeleteSavedCheck     // the SECOND Clear-board question, on its own tick - the box cannot nest
    /* Bulk dismissal, by FUNCTION (Nils 2026-07-28). A board can settle with well over a thousand
       report-only rows and no way to dispose of any of them, so every later Check re-presents the lot.
       Per-ROW ignore does not solve that - "if the dashboard has maybe close to a 100 lines it is not
       feasible to click them one-by-one" - and the analyzer grid's answer (sort by function, multi-select,
       Ignore Row(s)) needs a grid. Here the GROUPING is the selection: one action row per distinct
       function, so a whole family goes in one click. Writes the SAME per-workspace ignore list the
       analyzer grid uses (cModAnalyzer ReadIgnored/WriteIgnored), so the two surfaces cannot disagree.

       THREE GROUP KINDS, because a group is only dismissable by something every one of its rows
       carries. "F" = the refactor function (Review). "M" = the message (Needs-hand-migration, whose
       rows have no converter by definition). "U" = the install package's own file, for an obsolete-
       package row re-pointed at the user's Use line: it has neither a converter NOR a message worth
       grouping by - 4536 covers packages that DO have a fix - and being a judgement call it leaves
       no trace in the source, so nothing else would ever clear it (Nils 2026-08-30). */
    Define CI_ChkIgnoreFn                // findings "Ignore all N" -> ignore every row of that group (function / message / package)
    Define CI_ChkClearIgnored            // findings header "Clear" -> empty the ignore list (bring them all back)
    Define CI_ChkRefreshLight            // re-Activate -> refresh the tiles but LEAVE the findings list (and its folds) alone
    /* Fill the board from the SAVED plan instead of re-running Check (Nils 2026-07-28: "it is a bit
       annoying to each time after a restart needing to go through the compile+analyze cycle each time
       to see the dashboard list(s)"). The Dashboard's own "View/Run last plan" link has always done
       this - it just lands you on the analyzer TAB; here the trail's own findings list fills and you
       stay put. Deliberate click, never automatic: entering saved-plan mode silently at startup is how
       someone ends up acting on findings older than their source without knowing it. */
    Define CI_ChkShowLastPlan            // findings header "Show last Check" -> load the frozen plan onto the board
    Define CI_ChkFinishLastPlan          // ...and the cold-show follow-up one tick later (see ShowLastCheckOnBoard)
    Define CI_ChkTidyUp                  // findings footer "Open Tidy Up" -> the Tidy Up function group (stage 4)
    Define CI_ChkViewProgress            // progress readout -> the Modernization Progress History modal
    Define CI_ChkDeepScanRules           // "Analyze rules" -> the source-analyze rule-selection dialog
    Define CI_ChkLibraries               // Target-version tile, "Libraries" chip -> the library report
    /* The after-a-run utilities. The trail used to arm the DASHBOARD's timer with ITS constants for
       these four - the last markup-adjacent borrow left after the untangle, and the reason this view
       still needed oDashboard_vw to exist. The work now lives in ghoBoardActions (shared with both
       boards); these are the trail's own arming codes. (Nils 2026-08-02.) */
    Define CI_ChkReadLog                 // action row "Read log"
    Define CI_ChkReadOtherLogs           // action row "Read other logs"
    Define CI_ChkCompare                 // action row "Compare Source"
    Define CI_ChkUndo                    // action row "Revert"
    Define CI_ChkStartCenter             // crumb "Start Center" -> back to the pre-workspace screen
    Define CI_ChkUpdateScan              // after the first paint -> ask each remote what is newer (read-only)
    Define CI_ChkShowSkipped             // findings header "Which ones?" -> name the dead-dependency files left out
    Define CI_ChkRenameGlobal            // findings E 4390 row "Rename it..." -> the whole-scope global rename offer (WRITES source)
    Define CI_ChkRenameCalls             // findings E 4546 sub-row "Rename the calls..." -> point the calls at the renamed wrapper (WRITES source)
    Define CI_ChkObjCallToGet            // findings E 4379 sub-row "Rewrite as Get..." -> Name(Self,...) to the Get form (WRITES source)
    Define CI_ChkRunFnScope              // findings cause row "Convert them..." -> run the class's own converter over the compiled set (WRITES source)
    Define CI_ChkFixShadow               // sys-override line "Rename them" -> retire the workspace copies shadowing install files (RENAMES files)
    Define CI_ChkShowShadowFiles         // sys-override line "Which files?" -> list the overriding copies and what each shadows
    Define CI_ChkUnkeepShadows           // sys-override line "N kept" -> offer the copies the user decided to keep again
    Define CI_ChkRestoreLanguage         // sys-override line "Rename it back..." -> a retired language setting goes back to Language_Current.inc (RENAMES a file)
    Define CI_ChkKeepInstallLanguage     // sys-override line "Stay in <language>" -> record that the retired language setting stays retired
    Define CI_ChkGuardExternal           // findings E 4390 External_Function row "Guard it" -> the wide guard's Use-arm over the declaring files, else the same-width guard (WRITES source)
    Define CI_ChkRenameClass             // findings E 4345 class row "Rename the class..." -> RenameCollidingClass over the compiled scope (WRITES source)
    Define CI_ChkFixDecl                 // findings E 4544 name row "Fix it..." -> the mismatch harvest for that name, silent, then the rename / align / rewrite offers (WRITES source on Yes)
    Define CI_ChkDropSurplus             // findings E 4379 arity row "Drop the surplus argument..." -> DropSurplusCallArguments over that one file (WRITES source)
    Define CI_ChkIgnoreRow               // findings Review row "Ignore" -> hide that ONE file's finding (the same per-workspace list as Ignore all)
    Define CI_ChkCharModeInventory       // findings notice "Show the inventory" -> CharacterModeInventoryReport over the Check's scope, then its log
End_Enum_List

// Long tooltips for this board. Prose, not markup: these are the strings most likely to be
// re-read and re-worded, and buried inside a span they are the hardest in the app to find.
// Same convention as the 19 tip constants at the top of cFTTileMarkup.pkg. Only the STATIC
// ones live here - eight more interpolate a count or a file name and stay at their site,
// because a constant with a hole in it is harder to read than the sentence it replaced.
Define CS_DashTidyDoneTip       for "Check found nothing left for the tool to fix, and Tidy Up has run over this workspace. Nothing further is required - Tidy Up can still be run again whenever you want."
Define CS_DashTidyAlwaysTip     for "Tidy Up is the tidy-and-remove group - re-indent, trailing spaces, unused locals and Use statements. It never reads the compile output and only acts on what it still finds, so it is always available; the line above is sequencing advice, not a restriction."
Define CS_DashLibraryScopeTip   for "Library code is maintained elsewhere. Refactoring it here is allowed and is not undone by anything - but the next update to the library will overwrite or conflict with the changes."
Define CS_DashTimingTip         for "Where the time went. The scan runs BEFORE the compile; analyze includes building this board."
Define CS_DashSystemClassTip    for "The compiler raises these inside DataFlex&rsquo;s own classes and macro commands - the View / ReportView deferred-view machinery and the like. Nothing in the workspace&rsquo;s source can reach them, so they are not listed as work. The Analyzer grid still holds every one."
Define CS_DashDismissedTip      for "This workspace has dismissed findings saved from an earlier session. Run a Check to see them counted, or bring them all back now."
Define CS_DashUnwritableTip     for "These sit in DataFlex's own installation - files DFRefactor does not write and that are not to be changed, so they are listed here and not offered as work. (Findings in read-only PACKAGE checkouts get their own band on this list instead.) The Analyzer grid shows every such row with a System (read-only) badge."
Define CS_DashScanBadgeTip      for "Found by scanning the selected folders &mdash; covers every file there, whatever the selected program is."

Activate_View Activate_oDashboard_vw for oDashboard_vw
Object oDashboard_vw is a cRDCDbView
    Set Border_Style to Border_Thick
    Set Size to 440 600     // tall enough for the anchor tiles + the guided-Check findings list below
    Set Location to 2 2
    // The tab-page text. "Dashboard (WIP)" until a better name lands (Nils 2026-08-01) - this view is
    // the dashboard now, and the tab reading "Check workspace" while the toolbar button said something
    // else made the pair hard to tell apart. The toolbar item carries the same caption.
    Set Label to "Guided Dashboard"
    Set Icon to "GuidedDashboard.ico"   // the toolbar button's picture - the sparkles (2026-10-04)
    Set pbAutoActivate to False

    /* AND the other way a view takes the screen without being asked: Request_Clear_All ends with
       "If (Auto_Top_Panel_State(Self)) Send beginning_of_panel" (Enclient.pkg). Opening a workspace
       Broadcasts Request_Clear_All to every Client_Area child, so each view yanked FOCUS to the top of
       its own panel - and this one, being the last child, won. Focus alone displays a view without any
       Activate_<view> message, so the CodeJock tab strip stayed on whatever the user had picked: the
       Dashboard tab lit, this view's content underneath (Nils 2026-08-01).

       This is a board of HTML tiles and one combo, not a data-entry panel - "put the cursor at the top
       of the panel after a clear" means nothing here. The clear itself still runs. */
    Set Auto_Top_Panel_State to False

    Object oSysFile_DD is a cSysFileDataDictionary
    End_Object

    // A run that changed NOTHING must not leave its button pressable - pressing it again cannot do
    // anything until the code or the analysis changes (Nils 2026-07-21). Set when a run reports zero,
    // cleared whenever a new Check is started or fresh findings arrive, since either can make the
    // action worth trying again. A guardable name can still yield zero - one already guarded, say.
    Property Boolean pbGuardFoundNothing False
    Property Boolean pbConvertFoundNothing False
    // The last Check found a CHARACTER-MODE main program (Use UI, no Windows base) and ran the
    // source scan only - see _RunCharacterModeCheck. Rendered as the board's notice; cleared with
    // the rest of the board state. (Nils 2026-09-20.)
    Property Boolean pbCharModeCheck False
    // True while RunGuidedPlan is inside StartAutoSelect - RefreshAfterRun reads it (2026-09-23).
    Property Boolean pbPlanRunInFlight False
    /* COMPILED-SCOPE CACHES, keyed by the .prn's own identity (2026-08-19, after Nils: "the loading
       time for the Winserv workspace has gone up rather drastically").

       Measured on his WinServ before this: the compiled scope is 1716 files / 40.3 MB, and a single
       findings render was reading about 242 MB of it - the 53.6 MB .prn re-parsed by every one of
       CompiledScopeFiles' eight callers, the whole 40.3 MB scanned once PER cause class by
       FindDefinitionSite (four times there, every line lowercased and word-split), and 25.3 MB more
       for the 533 cause-attribution reads. None of it ran before, because a restored plan had no
       .prn to reach and the evidence tests bailed early; teaching it to find one turned the whole
       cost on at once. The work was always this expensive - it was simply never being done.

       psScopeStamp is "<path>|<size>|<write time>", so a recompile invalidates both caches on its
       own and a stale listing can never be believed. */
    Property String   psScopeStamp ""
    Property String[] pasScopeFiles
    /* The DEFINITION INDEX: every "Class <name> is a <parent>" and "#COMMAND <name>" in the compiled
       scope, collected in ONE pass and reused for every lookup. It replaces FindDefinitionSite's
       scan-per-name, and it carries the PARENT too - which also retires the second read the cause
       loop did to find out what a class descended from. Keys are "c|<name>" / "m|<name>", lowercased;
       first definition wins, matching what the scan-per-name did. */
    Property String   psIdxStamp ""
    Property String[] pasIdxKey
    Property String[] pasIdxParent
    Property String[] pasIdxSite
    /* The 4536 Use-site INDEX (a per-package memo from 2026-08-29, an index since 2026-09-02),
       keyed by the SAME .prn identity as the two scope caches above: every 'Use <package>' in the
       head of every workspace file, base name -> "file|line", built in ONE pass by
       _BuildUseSiteIndex the first time a 4536 row asks. A package with no entry is one no
       workspace file Uses, so the negative answer costs nothing either - the per-package sweep
       this replaced read every head again for each such package (124 s on WinServ, Nils
       2026-09-02). No built-latch: an unbuilt index and one built from no listing are both
       empty, so the stamp alone decides. */
    Property String   psUseSiteMemoStamp ""
    Property String[] pasUseSiteMemoKey
    Property String[] pasUseSiteMemoVal
    /* WHICH COPY THE BUILD COMPILED, per file name (2026-09-11; a count of file names under the
       home from 2026-08-30 until then). pasShadowLeaf holds every file name the current listing
       compiled, lowercased and sorted for BinarySearchArray; pasShadowBuilt, at the same index, the
       path(s) compiled under it; psShadowProgram, the program the listing is for. A row asks "is
       the file I am about to send you to the copy the build compiled?" with one binary search - see
       _ShadowNoteForFile and CompiledLeafIndex.

       It exists because the answer was reachable only by running a report nobody runs (Nils
       2026-08-30: "if the discoverability is hidden in a report only, it will not be noticed by
       most users"). The finding row is where the attention already is. */
    Property String    psShadowMemoStamp ""
    Property String[]  pasShadowLeaf
    Property String[]  pasShadowBuilt
    Property String    psShadowProgram ""
    /* Its key is the listing stamp AND the workspace home (2026-09-02). The home keeps workspace A's
       memo from answering for B after an in-process switch; the two actions that MOVE copies on
       disk - [Rename them], and a Revert that puts them back - clear the key outright, as they do
       the sys-override memo. "Offer them again" moves nothing on disk, so it leaves this key alone
       (it still clears the sys-override memo, whose record it edits). With no listing the memo is
       EMPTY - no note without a build behind the row. See _EnsureShadowMemo. */
    /* The DataFlex system files this workspace overrides - name, the copy that won, the shipped one
       it hid. Memoed on the same scope stamp as the shadow tally above, and for the same reason:
       both read the compiler listing, which only changes when the scope does. */
    Property String    psSysOverrideStamp ""
    // One tShadowCopy per copy, both kinds (a DataFlex system file, a file one of the workspace's own
    // libraries ships): the copy, the file it stands in front of, whether this build compiled it,
    // whether the two are identical. The line, [Which files?] and the Rename dialog all read this.
    Property tShadowCopy[] paSysOverride
    Property Boolean   pbSysOverrideBuilt False
    // Copies THIS listing named that are no longer on disk - renamed by [Rename them], or removed
    // by hand. Not live overrides (nothing to rename, and they cannot win another build), but not
    // nothing either: they are the proof the board predates the fix. Memoed with the pair above.
    Property Integer   piSysOverrideGone 0
    // A language setting [Rename them] retired, when renaming it back would change the language
    // (cShadowedPackageFiles.RetiredLanguageSettingIn): the file, the language it picks and the one
    // the install picks. Memoed with the rows above, "" when there is nothing to offer.
    Property String    psRetiredLanguageFile ""
    Property String    psRetiredLanguage ""
    Property String    psInstallLanguage ""
    /* The last findings render's verdict, written by FindingsListHtml (the ONE classifier - the steps
       tile must never re-derive it, or the trail and the list can disagree). piChkActionable counts
       every VISIBLE row still to be dealt with, by the tool or by a person: blocking errors +
       auto-fixable rows + every Review row (2026-09-04) + every by-hand row (2026-09-13). Hidden
       rows do not count - dismissing is a deliberate "this is fine" - so a board that shows nothing
       means step 2 is finished, and only that board does. -1 = no render yet. */
    Property Integer piChkActionable -1
    Property Integer piChkListed     -1
    // The listed count's SPLIT, published with it so the Check-done dialog says what the bands say
    // (see tFindingsCtx.iReviewPkg). Read by AnnounceCheckStageDone only.
    Property Integer piChkReviewRows   0
    Property Integer piChkReviewPkg    0
    Property Integer piChkHandRows     0
    Property Integer piChkHiddenReport 0
    Property Integer piChkHiddenFn     0
    // Compile ERRORS sitting in the read-only packages band of the same render (2026-08-29). The
    // verdict dialog reads it so "the compiler is clean" is never claimed over a build that failed
    // inside a pool package - those errors are real, just not the tool's to fix.
    Property Integer piChkOutsideErr  0
    // How many findings the ignore list is holding back, published by the same render for the same
    // reason: the Ready stage has to name what is still outstanding, and a stage tile that counted
    // the list itself could disagree with the board that produced it.
    Property Integer piChkHidden      0
    // Set when the board was filled from the SAVED plan rather than a Check this session; the
    // header then says so, with the plan's own date. Cleared by a real Check (RenderGuidedFindings).
    Property String  psLastPlanStamp ""

    /* TRUE while a board render is in flight - the whole point of which is that the render PUMPS.
       Nils 2026-08-31: after a first Check on a large workspace the analyzer grid finished, the
       status bar said "Ready. Analyzed in Ns." and the wait cursor went back to an arrow - and then
       the program sat there, apparently hung, while this board built its findings list (file reads
       per cause-attribution row). It was working; it just said nothing. BoardBusyOn/Off wrap that
       stretch in a wait cursor + a status note, and BoardRenderBeat keeps both alive from inside
       the row loop.
       The latch is what makes the pumping safe: oChkDeferTimer's OnTimer would otherwise dispatch a
       QUEUED action on our pump - starting a compile, popping a dialog, or a second render on top of
       the one in flight. It re-arms itself instead and fires once this render is done. */
    Property Boolean pbBoardRendering False
    // When the render started, for the elapsed it reports when it finishes. The bar cannot be READ
    // back (StatusText is write-only), so a render cannot restore what it overwrote - it states its
    // own cost instead, which is the number the user was missing anyway.
    Property Integer piBoardBusyTick 0

    /* ---- Moved here from the retired split board, 2026-08-10 ----
       State for the standalone source-analyze pass below. Its home board was DashboardFT.vw (the
       split cockpit); when that left the build these went with it, and the Test Compile bar's own
       analyze chip - still live on the MANUAL board - was left broadcasting to nobody. */

    // The folders the LAST scan actually ran over (captured AFTER the scope confirm, so the AppSrc
    // fallback form is included and a cancelled confirm never lands here). Session-only. Lets the
    // post-plan VERIFY re-scan reuse the confirmed scope verbatim (Nils 2026-07-16).
    Property String[] pasLastScanFolders
    // ...and whether that scope was ONE FILE rather than folders (the single-file door, 2026-09-17):
    // pasLastScanFolders then holds the file's full path, and the verify re-scan replays it as a file.
    Property Boolean pbLastScanWasFile False

    // One-shot: the NEXT RunDeepScan is the automatic post-plan VERIFY pass - reuse
    // pasLastScanFolders and skip the scope confirms (the user confirmed that scope when the lap
    // started; this is the same lap, not a new scan). Set by RunDeepScanVerify, consumed and
    // cleared at the top of RunDeepScan.
    Property Boolean pbVerifyRescanOnce False

    // CAMPAIGN pass bookkeeping (Nils 2026-07-17: users must learn that ONE scan+plan cycle is
    // rarely enough - staged conversions unlock in order, so the loop narrates itself). The pass
    // number of the last COMPLETED scan (0 = no campaign yet) + that pass's finding count, so the
    // next pass's result line can show the shrink ("down from N"). A CHANGED folder scope starts a
    // new campaign at pass 1 (a delta across different scopes misleads - the 2026-07-11 AppSrcNils
    // "keeps finding new rows" lesson); an exhausted scan (nothing actionable left in the raw hits)
    // ends the campaign and resets to 0. Session-only, like the scan cache.
    Property Integer piDeepScanPassNo 0
    Property Integer piDeepScanLastFindings 0

    // The .sws we have already offered an automatic restore for, so arriving at the view a second
    // time does not undo a board the user has since cleared. Re-arms when the workspace changes.
    Property String  psAutoPlanTriedWS ""
    // The main program the LAST findings render described. Only so the board can say out loud when
    // it changes - the compiler half of the list is scoped to that program's include chain, so a
    // different program means a different half of the list. "" = no render yet.
    Property String  psLastFindingsProgram ""
    // (pbChkDockWasHidden lived here briefly on 2026-07-29: the silent restore opened the output dock
    //  to realize the grid, then closed it again. Wrong cure - a bottom bar claims its stacking slot
    //  when it DOCKS, not when it shows, so the tabs stayed wedged above the Test Compile bar for the
    //  rest of the session. The silent path no longer opens anything; see RestoreLastCheck.)
    // One-shot: the "stage 2 is finished" message is said ONCE per Check, not on every tile refresh.
    // Cleared when a Check starts.
    Property Boolean pbChkDoneAnnounced False
    // The name whose row opened the report, so it can be narrowed to that one instead of dumping the
    // whole workspace listing from every row. "" = the full report.
    Property String psPendingDeclName ""
    // ONE-SHOT context intro for RunHoistAmbiguous's confirm: OfferCallRewrite sets it (the
    // trade-off / only-fix paragraphs) instead of asking its OWN question first - the report path
    // then shows ONE dialog carrying both the context and the how-it-works body, and the engine
    // runs with the question pre-answered (Nils 2026-07-24: the rewrite asked twice in a row).
    Property String psHoistIntroHtml ""
    // A per-name "Fix it..." narrows the call rewrite to THAT name (one-shot, set around the offer chain);
    // blank = the whole ambiguous set, as the report path has always run it.
    Property String psHoistOnlyName ""
    // Where Convert to Get declined a call, as "<file>|<line>|<reason>". A count alone leaves the user
    // with a number and no way to walk the work; these become rows that open the editor at the line.
    // Kept on the view so the list survives the re-render that follows the run.
    Property String[] pasDeclinedCalls
    // The .sws this board was last rendered for, so OnWorkspaceLoaded can tell a real workspace
    // CHANGE (throw the findings away) from a re-load of the same one (just repaint). See there.
    Property String psBoardWS ""

    /* The board stylesheet. It lives in AppHtml/CssStyle/tiles.css now - 108 rules that were written
       out here as one <style> block, none of them ever interpolated, because the theming was already
       done by the var(--dfr-*) tokens palette.css defines. The rules and the reasoning behind them
       moved together; this returns the links that pull them in.

       ORDER IS THE CONTRACT: tiles.css is linked after palette/buttons/bars, so a tile rule still
       wins a tie against a shared one exactly as the inline block used to. Anything a caller adds in
       its own <style> is later still, and wins over both. */
    Function TileCss Returns String
        Function_Return (CS_PaletteCssLink + CS_TilesCssLink)
    End_Function

    /* A HINT CELL SAYS ITS WHOLE TEXT IN A TOOLTIP (Nils 2026-10-05, on the Auto-fixable band's lead: "the
       text is chopped off, so it needs a tooltip"). The cell (.fhint, tiles.css) is one line, cut with an
       ellipsis at 46% of the row - and the tail is where the instruction lives. The ordinary finding rows
       have carried a title since 2026-07-23 and the Ignore-all groups since 2026-07-29 ("the rest is
       chopped off, and no tooltip to show the full text"); the 22 other hint cells of this board did not,
       because the library's FindingHint writes none. Those 22 are built through one of these two now.
       (The ordinary rows keep TagTipText, which escapes its text; these two take the cell's markup as it
       is.)

       The title is the cell's own text with its tags taken out. Entities stay as they are - an attribute
       value decodes them, so an em dash reads as one - and a double quote is the one character that must
       not reach the attribute raw. */
    Function _HintTitle String sInner Returns String
        String  sOut
        Integer iOpen iClose

        Move sInner to sOut
        Move (Pos("<", sOut)) to iOpen
        While (iOpen > 0)
            Move (Pos(">", (Mid(sOut, Length(sOut), iOpen)))) to iClose
            If (iClose = 0) ;
                Move (Left(sOut, (iOpen - 1))) to sOut
            Else ;
                Move (Left(sOut, (iOpen - 1)) + Mid(sOut, Length(sOut), (iOpen + iClose))) to sOut
            Move (Pos("<", sOut)) to iOpen
        Loop
        Function_Return (Replaces('"', sOut, "&quot;"))
    End_Function

    // The whole hint cell: sInner is its markup, and its own text is the tooltip.
    Function HintCell String sInner Returns String
        Function_Return ('<span class="fhint" title="' + (_HintTitle(Self, sInner)) + '">' + sInner + CS_SpanEnd)
    End_Function

    // The hint cell's opening tag alone, for a cell that is put together inside a longer expression:
    // sTitle is its text in plain words; the caller writes the content and closes the span.
    Function HintOpen String sTitle Returns String
        Function_Return ('<span class="fhint" title="' + (Replaces('"', sTitle, "&quot;")) + '">')
    End_Function

    /* THE SAME SENTENCE, SEVEN TIMES. Every path that invalidates the findings list - a plan
       run, a revert, a scope change, a tidy-up - repaints the tile with this note, and each one
       spelled it out. One place to say it now, so the wording cannot drift between the routes
       that lead to the same state. */
    Function StaleFindingsNote Returns String
        Function_Return (TileCss(Self) + ((DivOpen("tnote")) + 'Source may have changed ') + CS_EmDash + ((' run ' + (BoldText("Check")) + ' again to see current findings.') + CS_DivEnd))
    End_Function

    // The plan's own wording of the same state - it KNOWS the source changed. Pushed twice: by
    // RefreshAfterRun before the summary dialog, and by RunGuidedPlan's tail after it.
    Function PlanRanFindingsNote Returns String
        Function_Return (TileCss(Self) + ((DivOpen("tnote")) + 'The plan has run and source changed ') + CS_EmDash + ((' run ' + (BoldText("Check")) + ' again to see current findings.') + CS_DivEnd))
    End_Function

    /* WHAT THE LIST SAYS WHILE A CHECK IS RUNNING (Nils 2026-09-15, on a fresh migration copy:
       "It would be good if a Check button click would clear the grid. Else it is confusing to see
       the grid items - and even possible to click them, while the compiler is running").

       Both halves of that are real. The rows on screen were produced by the PREVIOUS compile, so
       from the moment a Check starts they describe a build that is being replaced. And they stay
       LIVE while it runs: every row action here writes source or opens the report that leads to
       one, and the scan half pumps the message loop for as long as it takes, so a click during a
       Check reached a remedy built from findings that were already history.

       The wording has to hold for a Check that does NOT finish, too - a stopped compile never
       reaches the render that would replace this - so it names the control that starts over. */
    Function CheckRunningNote Returns String
        Function_Return (TileCss(Self) + (DivOpen("tnote")) ;
            + 'Check is running ' + CS_EmDash + ' the findings that were here came from the last ' ;
            + 'compile and have been cleared. The new list appears when the Check finishes; if you ' ;
            + 'stop it, run ' + (BoldText("Check")) + ' again.' + CS_DivEnd)
    End_Function

    // Returns True when the stepper's stage 2 ("Check & fix") counts as DONE for the picked program.
    Function _StepsStage2Done Boolean bHaveProg Returns Boolean
        Integer iAnalyzed
        Boolean bStage2Done

        /* Step 2 is DONE once a Check has completed and left NOTHING VISIBLE on the board - no blocking
           errors, no auto-fixes, no Review row, and since 2026-09-13 no by-hand row either: a change a
           person still has to make is not a finished stage. Before that the trail used to sit on
           "2 Check & fix" for ever with only report rows showing, giving the user no sign the stage
           was finished (Nils 2026-07-26); after 09-04 it closed over Review rows, after 09-13 over
           by-hand rows. The verdict comes from the findings render (piChkActionable), so the trail
           and the list can never disagree; piChkTickAnalyze proves a Check actually ran this session
           rather than the counters merely being unset. */
        /* A LOADED SAVED CHECK COUNTS AS EVIDENCE TOO (Nils 2026-07-29: "the trail seems to always
           stay on 'Check & fix' after a program restart"). piChkTickAnalyze is 0 until a Check runs
           in THIS session - deliberately, because source can change between sessions and yesterday's
           verdict proves nothing about today - so after a restart the stepper could never show
           progress, whatever had been done.

           The way out is the one the user asks for explicitly: "Show last Check" restores the board
           from the frozen plan, and now restores the stage state with it. Nothing is claimed
           silently - the findings header carries "Last Check - <date> - run Check to refresh" the
           whole time it is showing, which is what keeps a restored stepper honest. A real Check
           clears the stamp and the live verdict takes over. */
        Move False to bStage2Done
        If (bHaveProg = True) Begin
            Get piChkTickAnalyze of ghoApplication to iAnalyzed
            If ((iAnalyzed <> 0 or Trim(psLastPlanStamp(Self)) <> "") and piChkActionable(Self) = 0) ;
                Move True to bStage2Done
        End
        Function_Return bStage2Done
    End_Function

    // Returns the stepper's stage-4 "Ready" box - reached or not, never "now" - tooltip included.
    Function _StepsReadyBoxHtml Returns String
        String sHtml sReadyTip
        Boolean bReady
        Integer iHidden

        Move "" to sHtml
        /* STAGE 4: READY - the ending the trail did not have. See GuidedStageReady for what has to be
           true first; the point here is that it is never "now", only reached or not. A step the user
           is standing ON is one they have to act on, and there is nothing to do at the finish line. */
        Get GuidedStageReady to bReady
        Move (piChkHidden(Self)) to iHidden
        If (bReady = True) Begin
            /* ALWAYS a tooltip, not only when something is hidden (Nils 2026-07-30). "Ready" is the
               one word on the strip that invites "ready for WHAT?" - the footer answers it, but the
               stepper box did not, and a stage nobody can read is barely better than no stage. The
               hidden count is appended when there is one rather than replacing the explanation. */
            Move CS_DashTidyDoneTip to sReadyTip
            If (iHidden > 0) ;
                Move ('Check found nothing left for the tool to fix, and Tidy Up has run over this workspace. ' + String(iHidden) + ' finding(s) are still hidden - the work behind them stays outstanding.') to sReadyTip
            /* A CHARACTER-MODE PROGRAM IS NOT FINISHED HERE (Nils 2026-09-20). "Nothing further is
               required" is true of this tool and false of the program: DataFlex 26 cannot build it
               until its screen handling has been rewritten by hand, which the inventory on the
               findings board counts. The tooltip says both, hidden count included. */
            If (pbCharModeCheck(Self) = True) ;
                Move ('Check found nothing left for this tool to fix, and Tidy Up has run over this workspace. This is a character-mode program: its screen handling still has to be rewritten by hand before DataFlex 26 can build it - the inventory on the findings board counts that work.' + (If((iHidden > 0), (' ' + String(iHidden) + ' finding(s) are still hidden - the work behind them stays outstanding.'), ''))) to sReadyTip
            Move (sHtml + (DivOpenTip("st done rdy", sReadyTip)) + (StepMarker(CS_Check)) + 'Ready') to sHtml
            If (iHidden > 0) ;
                Move (sHtml + (SpanOpen("rdyn")) + String(iHidden) + CS_Nbsp + ('hidden' + CS_SpanEnd)) to sHtml
            Move (sHtml + CS_DivEnd) to sHtml
        End
        Else ;
            Move (sHtml + (DivOpen("st")) + (StepMarker("4")) + ('Ready' + CS_DivEnd)) to sHtml
        Function_Return sHtml
    End_Function

    // Band: the stepper + "Main program" label. The Program step ticks once a main program is picked.
    Function StepsTileHtml Returns String
        String sTidyWS sReadyBox
        Boolean bTidyDone
        String sHtml sWS sMain
        Boolean bHaveWS bHaveProg bStage2Done
        
        Get psSWSFile of ghoApplication to sWS
        Move (sWS <> "") to bHaveWS
        Get MainProgram of ghoApplication to sMain
        Move (sMain <> "") to bHaveProg
        Move (TileCss(Self) + (DivOpen("wrap"))) to sHtml
        If (bHaveWS = False) Begin
            Move (sHtml + CS_DivEnd) to sHtml
            Function_Return sHtml
        End
        Move (sHtml + (DivOpen("step"))) to sHtml
        If (bHaveProg = True) ;
            Move (sHtml + ((DivOpen("st done")) + (StepMarker(CS_Check)) + 'Select' + CS_Nbsp + ('Program' + CS_DivEnd))) to sHtml
        Else ;
            Move (sHtml + (DivOpen("st now")) + (StepMarker("1")) + 'Select' + CS_Nbsp + ('Program' + CS_DivEnd)) to sHtml
        Move (sHtml + ((SpanOpen("bar")) + CS_SpanEnd)) to sHtml
        Get _StepsStage2Done bHaveProg to bStage2Done
        If (bStage2Done = True) ;
            Move (sHtml + (DivOpen("st done")) + (StepMarker(CS_Check)) + ('Check &amp; fix' + CS_DivEnd)) to sHtml
        Else If (bHaveProg = True) ;
            Move (sHtml + (DivOpen("st now")) + (StepMarker("2")) + ('Check &amp; fix' + CS_DivEnd)) to sHtml
        Else ;
            Move (sHtml + (DivOpen("st")) + (StepMarker("2")) + ('Check &amp; fix' + CS_DivEnd)) to sHtml
        /* THREE STAGES, NOT FOUR (Nils 2026-07-29: "I think you're right that we should skip 3
           Clean"). The mockup's fourth box never got a meaning: "Clean" had no handler, no view and
           no action, and its name meant the same as "Tidy Up" - which is the one with a real
           function group (eFnGroupCleanup) behind it. Reaching a board where only hand-migration
           rows remain used to park the user ON that empty step, with the only real next action
           sitting in the findings footer below it. A stage that does nothing is worse than one that
           does not exist.

           Step 3 marks DONE once a Tidy Up the trail routed to has actually run for this workspace
           this session, and is CURRENT once stage 2 is done. Not terminal: a Tidy Up that CHANGED
           files sends you back to Check, so the loop can light 2 again afterwards - the trail is a
           cycle and that display is the cycle, not a contradiction. */
        // Per-workspace and PERSISTED (Nils 2026-07-29 asked for it to survive a restart): the stamp
        // is keyed by the same <wskey> as the analyze snapshot, so it can only ever describe the
        // workspace now loaded. "" = no trail Tidy Up has ever finished here.
        Get ReadTidyUpStamp of ghoApplication to sTidyWS
        Move (Trim(sTidyWS) <> "") to bTidyDone
        Move (sHtml + ((SpanOpen("bar")) + CS_SpanEnd)) to sHtml
        If (bTidyDone = True) ;
            Move (sHtml + ((DivOpen("st done")) + (StepMarker(CS_Check)) + 'Tidy' + CS_Nbsp + ('Up' + CS_DivEnd))) to sHtml
        Else If (bStage2Done = True) ;
            Move (sHtml + (DivOpen("st now")) + (StepMarker("3")) + 'Tidy' + CS_Nbsp + ('Up' + CS_DivEnd)) to sHtml
        Else ;
            Move (sHtml + (DivOpen("st")) + (StepMarker("3")) + 'Tidy' + CS_Nbsp + ('Up' + CS_DivEnd)) to sHtml
        Move (sHtml + ((SpanOpen("bar")) + CS_SpanEnd)) to sHtml
        Get _StepsReadyBoxHtml to sReadyBox
        Move (sHtml + sReadyBox) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml
        // (The "1 Main program" sub-label was dropped - the Program combo sits beside the Target tile above,
        //  so the label is redundant.)
        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    // Returns the OPENING of the .scope row: the "Workspace: <name>" lead-in plus the folder-count stat.
    // The caller closes the row (after the .acts buttons).
    Function _BodyScopeOpenHtml String sWS Returns String
        String sHtml sScopeV sFoldChip sFoldTip sFoldLbl
        Integer iSelFold iTotFold

        Move "" to sHtml
        /* THE FOLDER COUNT, replacing the hardcoded "incl. libraries" (Nils 2026-07-30: "show the
           selected number of folders").

           Asking for the number exposed a lie that had been sitting here since the tile was built:
           BOTH halves of "Whole workspace / incl. libraries" were string constants, printed whatever
           the user had picked. The Check's scan lane is folder-scoped - line ~1865 and ~2996 both
           run on pasSelectedFolders - so a workspace narrowed to 3 of 40 folders still read "Whole
           workspace", and every finding count under it was quietly scoped to those 3. A tile whose
           job is to say what the scan covers cannot be the one place that guesses.

           The fix is to stop the bold lead making the claim at all. It is a LABEL now - "Workspace:"
           in every state (Nils 2026-07-30: "Part of the workspace ... just looks odd") - and the
           counts beside it carry the whole truth:
             0 selected      -> "every source folder". Not a special case: with nothing picked the
                                scan falls back to WholeWorkspaceSourceFolders, which is every source
                                root plus the library folders.
             all selected    -> "40 of 40 folders"
             some selected   -> "3 of 40 folders"

           A sentence fragment set in bold at the head of a row of counts reads as a heading and then
           fails to behave like one. A label does not have that problem, and it also removes the last
           place where the strip stated coverage in prose that could drift from the numbers.

           The all-selected case is "40 of 40", not a bare "40": with the lead-in no longer saying
           "whole", the plain count would not tell anyone whether 40 was all of them. "N of M" says it
           in every state, and matches the scan-rules chip sitting two positions along.

           Counted through TotalSelectedFolders / TotalFolders, which self-find on the FolderSelHeaA
           ALIAS and disturb no buffer. NOT through WholeWorkspaceSourceFolders: that one reaches
           RecursiveSearchFolders and walks the disk, which is fine once per scan and indefensible on
           every tile repaint - hence "every source folder" as words rather than a fabricated number. */
        Get TotalSelectedFolders of (phoFolderSelHeaDD(ghoApplication)) to iSelFold
        Get TotalFolders of (phoFolderSelHeaDD(ghoApplication)) to iTotFold
        /* THE BAND NAMES ITS SUBJECT (Nils 2026-08-09: "there are plenty of space after the last
           statistic and the Select Folders button ... that gives plenty of space to add the
           workspace name after the Workspace:").

           The slack is real and structural: .acts carries margin-left:auto, so every pixel the
           stats do not use shows up as a gap in front of the buttons. Stacking the stats freed
           117px of it, and a bare "Workspace:" with nothing after it was reading as an unfinished
           label anyway.

           Through the shared WorkspaceShortName rather than a fourth private copy of the basename
           logic - the crumb above this card derives the very same name, and the two must not be
           able to disagree about what the workspace is called. */
        Move "" to sScopeV
        If (sWS <> "") ;
            Get WorkspaceShortName of ghoTileMarkup sWS to sScopeV
        If (sScopeV = "") ;
            Move "no workspace" to sScopeV
        // The NAME in its own span so it can be quieter than the title that introduces it (Nils
        // 2026-08-09). Nested inside .v, so the nowrap and the trailing margin still govern the
        // pair as one lead-in.
        Move (('Workspace: ' + (SpanOpen("vn"))) + sScopeV + CS_SpanEnd) to sScopeV
        Move (String(iSelFold) + " of " + String(iTotFold)) to sFoldChip
        Move "folders" to sFoldLbl
        If (iSelFold = 0) Begin
            Move "all"            to sFoldChip
            Move "source folders" to sFoldLbl
            Move "No folders are picked, so a Check scans the whole workspace - every source root plus the library folders." to sFoldTip
        End
        Else If (iSelFold >= iTotFold) Begin
            Move "Every folder in the workspace is picked, so the scan covers all of it." to sFoldTip
        End
        Else Begin
            Move ("The source analyze and the refactoring passes only open files in the " + String(iSelFold) + " picked folders - every finding count below is scoped to them. The compile half of a Check follows the selected program instead, whatever is picked here.") to sFoldTip
        End
        /* EACH VALUE IS A TWO-ROW STAT - number over label (Nils 2026-08-09: "it actually looks
           really neat with two text rows ... that balance better with the buttons").

           It already looked like that on his screen, but by ACCIDENT: the enlarged buttons took
           enough width that each chip's text wrapped inside itself. Measured across widths, that
           wrap is a ladder - 110 / 94 / 78 / 62 px - and which rung you land on depends on how many
           chips the workspace produces. Pick a library folder or set a file filter and the same
           board re-shapes: at 520px wide it is 78px tall with four chips and 62px with two.

           Stacking them deliberately fixes the shape at every width and chip count, and it makes
           each stat NARROWER than the sentence it replaces - so the row that was overflowing into a
           wrap now fits with room to spare. The number leads because the numbers are what the band
           is for; the label under it in the muted colour the sentence used to carry. */
        Move (sHtml + (DivOpen("scope")) ;
            + (SpanOpen("v")) + sScopeV + CS_SpanEnd ;
            + (SpanOpenTip("cav", sFoldTip)) + (BoldText(sFoldChip)) ;
            + (SpanOpen("cl")) + sFoldLbl + CS_SpanEnd ;
            + CS_SpanEnd) to sHtml
        Function_Return sHtml
    End_Function

    // Returns the "are libraries" and "file types" stats of the .scope row ("" when neither applies).
    Function _BodyLibFilterHtml String sMain Returns String
        String sHtml sFilter sFilterEsc
        String[] asSelFolders asSelLibs
        Integer iFilterCount
        Handle hoLib

        Move "" to sHtml
        /* THE FILE FILTER IS PART OF THE SCOPE AND WAS NEVER SHOWN (Nils 2026-07-30, after Adjust:
           "it is not only folders that can be selected, also the file filter"). It is honoured by
           everything that collects files itself - the Deep Scan, refactoring runs and the guided row
           actions all reach AllSourceFiles(folders, SysFile.FileExtensionFilter) - so a narrowed
           filter silently narrows every finding count, and the tile that exists to say what "scope"
           means said nothing about it.

           The list is far too long for the strip (15 extensions on his workspace), so the count sits
           on the tile and the list itself is the tooltip. It does NOT constrain the compiler half of
           a Check: that follows the selected program's include chain, and a file the filter excludes
           is still compiled if the program includes it - the same lane split the row badges carry. */
        Move (Trim(SysFile.FileExtensionFilter)) to sFilter
        Move (SizeOfArray(StrSplitToArray(sFilter, ";"))) to iFilterCount
        Get HtmlEscaped sFilter to sFilterEsc
        /* LIBRARY FOLDERS IN THE SELECTION - stated, not acted on (Nils 2026-07-31: "if the user
           selects a library folder, we act on it. We don't want to prohibit the user from it").
           Nothing is excluded, so the wording must not imply skipping; this is a fact about what is
           picked, shown here so the pre-run warning is a reminder rather than a surprise. Silent
           when no library folder is selected, which is the common case. */
        Get pasSelectedFolders of ghoApplication to asSelFolders
        If (SizeOfArray(asSelFolders) > 0) Begin
            Get Create (RefClass(cLibraryInventory)) to hoLib
            Get LibrariesInFolders of hoLib sMain (&asSelFolders) to asSelLibs
            Send Destroy of hoLib
            // "N / are libraries" keeps the 07-31 wording as the label row - it is still a
            // statement about what is picked, not a verb.
            If (SizeOfArray(asSelLibs) > 0) ;
                Move (sHtml + (SpanOpenTip("cav", CS_DashLibraryScopeTip)) ;
                    + (BoldHtml(String(SizeOfArray(asSelLibs)))) ;
                    + (SpanOpen("cl")) + 'are libraries' + CS_SpanEnd + CS_SpanEnd) to sHtml
        End
        If (sFilter <> "") ;
                Move (sHtml + (SpanOpenTipHtml("cav", ("The source analyze and the refactoring passes only open" ;
                    + " files matching this filter - the compiler half of a Check follows the selected program" ;
                    + (" instead, whatever the filter says." + CS_NlEntity + CS_NlEntity) + sFilterEsc))) ;
                    + (BoldText(String(iFilterCount))) ;
                    + (SpanOpen("cl")) + 'file types' + CS_SpanEnd ;
                    + CS_SpanEnd) to sHtml
        Function_Return sHtml
    End_Function

    // Returns the "N of M / analyze rules" stat of the .scope row ("" when no rules could be loaded).
    Function _BodyRulesChipHtml Returns String
        String sHtml
        Integer iRuleTotal iRuleOn iRule
        Handle hoDS
        tDeepScanRule[] aRules

        Move "" to sHtml
        /* THE THIRD SCAN INPUT (Nils 2026-07-30, asking where a Deep Scan rule button belongs).

           The dashboard hangs a gear off its Deep Scan chip - beside the thing it configures. The
           trail has no separate Deep Scan action to hang one on, because Check runs both lanes, so
           the analogue is this tile: it is the only place that describes what the scan looks at.
           Folders say WHERE, the filter says WHICH FILES, the rules say WHAT TO LOOK FOR. Two of
           the three were already here.

           Shown as a COUNT rather than a bare gear, because the count tells the user something a
           gear cannot: that rules are switched off at all. Nine ship disabled (the common-English-
           word ones - Required, Status, Group, Fill...) and more get retired over time - FindErr and
           WindowIndex both went this week - so "194 of 205" is the only hint on the trail that the
           scan is deliberately narrower than the catalog.

           It is a STATEMENT, not a control - the "Analyze rules" button in the action group opens the
           dialog. Values left, verbs right, the same split the rest of the strip already keeps. */
        Get Create (RefClass(cDeepScanner)) to hoDS
        If (hoDS <> 0) Begin
            Get LoadDeepScanRules of hoDS (DeepScanRulesJsonPath(hoDS)) to aRules
            Send Destroy of hoDS
            Move (SizeOfArray(aRules)) to iRuleTotal
            Move 0 to iRuleOn
            For iRule from 0 to (iRuleTotal - 1)
                If (aRules[iRule].bEnabled = True) ;
                    Increment iRuleOn
            Loop
            /* PLAIN TEXT, not a link (Nils 2026-07-30: "should stay at that - as a text only").
               It sits with the other VALUES - whole workspace, incl. libraries, file types - and
               reads as one. A value chip that is secretly clickable is a hidden affordance: the
               only thing marking it would be a colour, and the button below now says the same thing
               out loud. Facts on the left, verbs on the right. */
            If (iRuleTotal > 0) ;
                Move (sHtml + (SpanOpenTip("cav", ("Which obsolete symbols the source analyze searches for. " ;
                    + String(iRuleTotal - iRuleOn) + " of the " + String(iRuleTotal) ;
                    + " rules are switched off - some ship that way because they match common English words," ;
                    + " others were retired as false positives."))) ;
                    + (BoldText(String(iRuleOn) + " of " + String(iRuleTotal))) ;
                    + (SpanOpen("cl")) + 'analyze rules' + CS_SpanEnd ;
                    + CS_SpanEnd) to sHtml
        End
        Function_Return sHtml
    End_Function

    // Returns the .checkrow: the Check button with its state-dependent sub-caption, plus the progress readout beside it.
    Function _BodyCheckRowHtml Boolean bHaveProg Boolean bCompiler Returns String
        String sHtml sCheckSub

        Move "" to sHtml
        // (The one-time teaching texts - the scope hint paragraph and the "Check does both" explainer -
        // were trimmed 2026-07-25 (Nils: vertical space); the button's "compile + analyze" caption keeps the essence.)
        Move (sHtml + (DivOpen("checkrow"))) to sHtml
        /* The Check button, and the ONE thing that varies between its three states: the sub-caption.
           It used to be three near-identical 130-character spans differing in that phrase and in
           whether the chip carried data-ServerOnClick - which meant the interesting part, what the
           button says when it cannot run, was the least visible thing on screen. */
        If (bHaveProg = False) ;
            Move "pick a program first" to sCheckSub
        Else If (bCompiler = False) ;
            Move "choose a compiler first" to sCheckSub
        Else ;
            Move "compile + analyze" to sCheckSub
        Move (sHtml + (ChipHtml("cbtn", "cbtn off", "check", "", ;
                                ((CS_SpanOpen + CS_PlayTriangle) + CS_Nbsp + (' Check' + CS_SpanEnd + (SpanOpen("sm"))) + sCheckSub + CS_SpanEnd), ;
                                "", (bHaveProg and bCompiler)))) to sHtml
        /* MODERNIZATION PROGRESS RIDES THIS ROW, far right (Nils 2026-08-09).

           It used to sit three tiles further up, under the stepper - and nothing on screen said the
           "Cycle N" pill in its header counted the presses of the button it was separated from. Side
           by side, the causal chain is visible without a word of explanation: press Check, the Cycle
           ticks and the figures beside it move. The row was one button and a band of empty space; the
           readout was a full-width strip with an empty right half. Merging them recovers a band of
           vertical space in a view that has twice had content trimmed for height.

           The SHARED builder, unchanged, so the Dashboard's copy stays identical and the pill stays
           clickable exactly as it was. It is a SIBLING of the Check button here, never a wrapper: a
           cWebHtmlBox fires every ANCESTOR's ServerOnClick, so nesting the two carriers would make
           one click do both things. Both ids route from oTile_Body's single OnClick - the same
           one-host-many-ids model as the dashboard's oTile_Columns.

           The .prog wrapper is what pushes the block right; it deliberately carries NO
           data-ServerOnClick, so the framework leaves it alone and it stays a direct child of the
           row - see the .prog rule in TileCss for why that matters. */
        Move (sHtml + (SpanOpen("prog")) + (ProgressTileHtml(ghoTileMarkup)) + CS_SpanEnd) to sHtml
        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    /* THE PROGRAMS THE COMBO LEFT OUT, NAMED (Nils 2026-09-23). The Program combo now lists only
       the programs whose .src is on disk; a name that is in the workspace file and not in the
       combo has to be accounted for somewhere the user looks, or the combo reads as having lost
       it. One quiet line under the Check row, three names and a count. "" when every listed
       program is on disk, which is every healthy workspace. */
    Function _BodyMissingProgramsHtml String sWS Returns String
        String[] asMissing
        String sNames sName
        Integer i iMax iNamed

        Get WorkspaceProgramsNotOnDisk of ghoApplication sWS to asMissing
        Move (SizeOfArray(asMissing) - 1) to iMax
        If (iMax < 0) ;
            Function_Return ""
        Move "" to sNames
        Move 0 to iNamed
        For i from 0 to iMax
            If (iNamed < 3) Begin
                If (sNames <> "") ;
                    Move (sNames + ", ") to sNames
                // Escaped inline: HtmlEscaped is defined further down this view.
                Move (Replaces("&", asMissing[i], "&amp;")) to sName
                Move (Replaces("<", sName, "&lt;")) to sName
                Move (sNames + sName) to sNames
                Increment iNamed
            End
        Loop
        If (iMax + 1 > iNamed) ;
            Move (sNames + " and " + String(iMax + 1 - iNamed) + " more") to sNames
        Function_Return ((DivOpen("hint")) + 'Not offered as a program: ' + sNames + ' - listed in the workspace file, but the file is not in its source folders.' + CS_DivEnd)
    End_Function

    // Band: scope + Check + findings placeholder.
    Function BodyTileHtml Returns String
        String sHtml sMain sWS sComp sGapChip sScopeRow sLibFilter sRules sCheckRow sMissing
        Boolean bHaveWS bHaveProg bCompiler
        
        // sWS is the WORKSPACE, sMain the PROGRAM. They used to share sMain - read as the .sws,
        // tested, then overwritten two lines later - which is a trap for anything added below that
        // wants the workspace: it silently gets the program instead. (It got the scope band's name
        // exactly that way, Nils 2026-08-09: "instead of showing the program, it should be the
        // Workspace name".) sMain keeps its meaning, so the sMain handed to _BodyLibFilterHtml
        // (LibrariesInFolders) is untouched.
        Get psSWSFile of ghoApplication to sWS
        Move (sWS <> "") to bHaveWS
        Get MainProgram of ghoApplication to sMain
        Move (sMain <> "") to bHaveProg
        Get psCompiler of ghoApplication to sComp   // Check compiles - it needs a compiler as well as a program
        Move (sComp <> "") to bCompiler
        /* 6px top instead of .wrap's 12px, so Scope starts level with where the Dashboard's GUIDED
           tile starts - that card's top edge is its own 6px margin, and both boards sit the same
           distance under Modernization progress, so the 6px was the whole difference (Nils
           2026-08-01). Overridden INLINE: .wrap is shared by every band in this view, and the ones
           above are already where they should be.
        */
        Move (TileCss(Self) + (DivOpen("wrap wrap-pt"))) to sHtml
        If (bHaveWS = False) Begin
            Move (sHtml + CS_DivEnd) to sHtml
            Function_Return sHtml
        End
        Move (sHtml + (DivOpen("k")) + 'Scope ' ;
            + (SpanOpen("sub")) + '— what the scan &amp; manual passes cover' + CS_SpanEnd ;
            + CS_DivEnd) to sHtml
        Get _BodyScopeOpenHtml sWS to sScopeRow
        Move (sHtml + sScopeRow) to sHtml
        Get _BodyLibFilterHtml sMain to sLibFilter
        Move (sHtml + sLibFilter) to sHtml
        Get _BodyRulesChipHtml to sRules
        Move (sHtml + sRules) to sHtml
        /* RESET IS GONE (Nils 2026-08-09). It was a stub - CI_ChkResetScope has always been
           "Delegate Send RefreshTiles" with a "lands in the next increment" note beside it - and
           on 2026-07-30 it was dressed as unavailable rather than removed, "because the capability
           is wanted, not abandoned".

           What that missed is the cost of parking it HERE. It sat in a row of three near-identical
           chips, so a third of the verb row was noise and the eye had to read all three to find the
           one it wanted - which is most of why Select Folders was hard to spot on this board at all
           (Nils, comparing it to the Manual dashboard's folders pill). A dead control is cheap in a
           menu and expensive in a three-item row.

           The capability is not abandoned by deleting the chip: its own tooltip already said the job
           is done today by opening Select Folders and using Select None, and that is one click from
           the button now sitting where Reset used to draw the eye. When a real scope reset is built
           it comes back - as a working control, next to the values it resets. */
        /* NAMED VERBS, IN THE VALUES' OWN ORDER, AS REAL BUTTONS.

           Named, because "Adjust..." is what made Nils ask for a tooltip in the first place - it
           never said WHAT it adjusted, and a tooltip whose job is to explain a button's own name
           means the name is wrong.

           Ordered folders -> rules to mirror the values on the left, which read folders, file types,
           scan rules (Nils 2026-07-30: "as the info shows ... swap places"). When a row of verbs runs
           opposite to the row of nouns it acts on, the eye has to re-map every time; matching them
           costs nothing and the pairing becomes free.

           Buttons rather than tinted text, matching the "Cycle N" pill in the progress tile below
           (.dash-cyc-count) - and since 2026-08-09 in its amber too, not just its geometry, so the
           two bands offer the same pill rather than a family resemblance. A bare colour change was
           the only thing marking these as clickable, which is exactly the hidden affordance the
           rule COUNT was just demoted for having.

           Reset kept the .off skin while it existed - it was a stub, and the whole point of giving the
           other two real button chrome is that chrome now means "this does something". Dressing a dead control
           the same way would spend that meaning immediately. */
        Move (sHtml + (SpanOpen("acts")) + (ChipHtml("sbtn", "sbtn off", "adjust", "", "Select Folders", CS_AdjustFoldersTip, True))) to sHtml
        Move (sHtml + (ChipHtml("sbtn", "sbtn off", "dsrules", "", "Analyze rules", CS_AnalyzeRulesTip, True)) + (CS_SpanEnd + CS_DivEnd)) to sHtml
        Get _BodyCheckRowHtml bHaveProg bCompiler to sCheckRow
        Move (sHtml + sCheckRow) to sHtml
        Get _BodyMissingProgramsHtml sWS to sMissing
        Move (sHtml + sMissing) to sHtml
        // (No findings placeholder here - the findings tile below carries its own when empty, and
        // after a Check this paragraph was dead space between the button and the list; Nils 2026-07-25.)
        Move (sHtml + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    /* The Check's phase split, for the findings header (Nils 2026-07-26: "64s to compile, 83s before
       everything is ready - does that seem reasonable?"). Check is four phases and only ONE of them is
       the compiler, so a single total cannot be judged: the SCAN runs before the compile, and the
       analyze + grid fill run after it. Reading the split turns the question into a measurement -
       and shows at a glance which phase to attack if a number looks wrong.
       Renders nothing unless a Check produced all four stamps (a dock-driven analyze leaves them 0). */
    Function CheckPhaseHtml Returns String
        Integer iT0 iT1 iT2 iT3
        Get piChkTickStart   of ghoApplication to iT0
        Get piChkTickScan    of ghoApplication to iT1
        Get piChkTickCompile of ghoApplication to iT2
        Get piChkTickAnalyze of ghoApplication to iT3
        If (iT0 = 0 or iT1 = 0 or iT2 = 0 or iT3 = 0) ;
            Function_Return ""
        Function_Return (((SpanOpenTip("fphase", CS_DashTimingTip)) + 'scan ') + ;
            String((iT1 - iT0) / 1000) + 's ' + CS_MidDot + ' compile ' + String((iT2 - iT1) / 1000) + ;
            ('s ' + CS_MidDot + ' analyze ') + String((iT3 - iT2) / 1000) + 's ' + CS_MidDot + ' total ' + String((iT3 - iT0) / 1000) + ('s' + CS_SpanEnd))
    End_Function

    // One severity band as a native <details> (foldable, no JS). Open only when sOpen = " open" (the first
    // non-empty band); collapsed shows a count + a one-line peek. An empty band renders nothing.
    Function BandHtml String sClass String sName Integer iCount String sPeek String sOpen String sRows Returns String
        If (iCount = 0) ;
            Function_Return ""
        Function_Return ('<details class="band ' + sClass + '"' + sOpen + (('><summary>' + (SpanOpen("tw")) + CS_PlayTriangle) + CS_SpanEnd) + sName + (SpanOpen("bpeek")) + sPeek + (CS_SpanEnd + (SpanOpen("bcount"))) + String(iCount) + (CS_SpanEnd + ('</summary>' + (DivOpen("brows")))) + sRows + (CS_DivEnd + '</details>'))
    End_Function

    // The guided Check result: ONE severity-ranked findings list built from the analyzer grid's classified
    // rows (BuildSavedPlanRows - ALL categories, compiler + Deep Scan combined). Four foldable bands, first
    // non-empty open. Each row carries a source badge (compiler / scan) + a severity dot. Reports-as-rows and
    // row actions (Run plan / View report / jump-to-source) are the next increment.
    // Minimal HTML escape for row text that goes into the findings list markup - the hint both as
    // the visible cell AND as its title tooltip (attribute context, so quotes must be neutral too).
    // Recipe hints are plain prose, but some carry literal angle brackets ("<TABLE>.<column>" in the
    // 4313 hint) that a raw span would swallow as a tag. Ampersand first, or it re-escapes the rest.
    Function HtmlEscaped String sText Returns String
        Move (Replaces("&", sText, "&amp;"))  to sText
        Move (Replaces('"', sText, "&quot;")) to sText
        Move (Replaces("<", sText, "&lt;"))   to sText
        Function_Return sText
    End_Function

    /* True when this row yields at least one function a PLAN RUN would actually execute: a
       non-empty name that is not a REPORT-only function. Reports are filtered out when the plan is
       built (they change nothing, and a worksheet written mid-run describes a half-refactored
       workspace), so a Review band whose rows name only reports is NOT plan-runnable. Offering the
       plan for it produced a closed loop: empty plan -> a dialog blaming a stale list -> "run Check
       again" -> the identical screen (Nils 2026-07-26).
       The Fn cell may hold a ", "-joined list; split it exactly as PlanFromSavedRows does so this
       predicate and the plan builder can never disagree about what is runnable. */
    Function RowHasRunnableFunction Handle hoDD String sFns Returns Boolean
        String  sFn
        Integer iPos
        Boolean bIsReport

        Move (Trim(sFns)) to sFns
        While (sFns <> "")
            Move (Pos(", ", sFns)) to iPos
            If (iPos > 0) Begin
                Move (Trim(Left(sFns, iPos - 1)))                  to sFn
                Move (Trim(Mid(sFns, (Length(sFns)), (iPos + 2)))) to sFns
            End
            Else Begin
                Move sFns to sFn
                Move ""   to sFns
            End
            If (sFn <> "") Begin
                Get IsReportOnlyFunction of hoDD sFn to bIsReport
                If (bIsReport = False) ;
                    Function_Return True
            End
        Loop
        Function_Return False
    End_Function

    /* STAGE 4: READY. A trail whose last box is a task you can always run again never tells you you
       have finished, and Nils asked for the ending (2026-07-29: "there should be one last stop for
       the trail and that is Ready ... in theory the refactoring for that program should be done").

       WHY THIS IS NOT THE "CLEAN" BOX WE DELETED. Clean was a stage of WORK with no work behind it -
       no handler, no view, nothing to press - and parking the user on an inert step was worse than
       having no step. Ready is not work: it is a terminal STATE, never clicked, lit only by
       evidence. A stepper is allowed to end in one; what it may not do is end in a chore.

       AND NOT "TIDY UP HAS RUN", WHICH IS NILS'S OWN "in theory". Three conditions, because the
       trail must not claim more than it knows - the exact failure the board was fixed for this
       morning, where a verdict outstripped the evidence behind it:

         1. A Tidy Up the trail routed to has finished for THIS workspace (ReadTidyUpStamp).
         2. The last Check left nothing visible on the board - nothing for the tool AND nothing for a
            person (piChkActionable = 0, which also excludes -1, "no Check has been looked at yet").
         3. Nothing has changed since that Check (ReadSourceUnverified). A Tidy Up that rewrote 40 files
            leaves a build nobody has compiled since; declining the verify offer is the user's
            right, but the answer then is "one Check away", not "Ready".

       Conditions 1 and 3 PERSIST per workspace in the registry (Nils 2026-07-29: "Yes" to surviving
       a restart), keyed by the same <wskey> as the analyze snapshot so they can only ever describe
       the .sws now loaded. Condition 2 does not, and that asymmetry is the point: after a restart
       the board is refilled from the SAVED Check, whose header says "Last Check - <date> - run Check
       to refresh" the whole time it is showing. So a restored Ready rests on a restored verdict, and
       the screen never stops saying which.

       Hidden findings do NOT block it - dismissing is a deliberate "these are fine", and forcing
       them back on screen to earn the badge would punish the feature. They are NAMED on it instead
       (piChkHidden), because the board already promises that hiding leaves the work outstanding and
       a bare "Ready" beside that sentence would be the contradiction all over again. */
    Function GuidedStageReady Returns Boolean
        String sStamp
        Boolean bDirty
        Get ReadTidyUpStamp of ghoApplication to sStamp
        If (Trim(sStamp) = "") ;
            Function_Return False
        If (piChkActionable(Self) <> 0) ;
            Function_Return False
        Get ReadSourceUnverified of ghoApplication to bDirty
        If (bDirty = True) ;
            Function_Return False
        Function_Return True
    End_Function

    /* Said ONCE per band, not on every group row. Repeating it turned the only informative part of
       each row - what those findings ARE - into the smallest thing on the line. */
    Function DismissNoteHtml Returns String
        Function_Return (((DivOpen("fnote")) + 'Ignoring a group only takes it off this board ') + CS_EmDash + ((' the work stays outstanding, and ' + (BoldText("Show them again")) + ' in the header brings it all back.') + CS_DivEnd))
    End_Function

    /* The board's ending - the "what now" block. A FUNCTION, and emitted on EVERY path out of
       FindingsListHtml, because the empty-state branches used to return BEFORE it: hide the last
       findings and the Tidy Up button vanished with them (Nils 2026-07-29: "there is no button to
       'Tidy up' again?"). An empty board is exactly when the next stage matters most - there is
       nothing else on screen to act on. */
    /* TIDY UP IS ALWAYS CLICKABLE (Nils 2026-08-31: "for some faulty reason the 'Tidy up' is
       disabled. It should probably always be available?"). It is, now, on every branch below.
       The gate used to be piChkActionable: -1 (no Check this session) and > 0 (fixes still
       outstanding) both greyed it. That reads as a safety rule and is not one - the group is
       re-indent, trailing spaces, end comments, unused locals and Use statements. None of it
       reads the compile output, none of it needs a clean build, and the pass is idempotent.
       What the gate actually encoded is CHURN ADVICE ("tidying code that is about to change
       again just moves the work around") - true, and a sentence's job, not a dead button's.
       And it could lock the user out: the day this was written, ONE un-fixable finding held
       piChkActionable above 0 and took Tidy Up down with it. A stage unreachable because of a
       row the tool cannot fix is the same defect twice. The headline still sequences ("Then:"
       muted against "Next:"), so the recommendation survives without the lockout. */
    Function NextStepHtml Returns String
        String sOut
        Boolean bReady bDirty
        Integer iHidden
        
        Move (DivOpen("fnext")) to sOut
        /* NO VERDICT YET IS NOT A CLEAN ONE. -1 means nothing has been examined in this session (see
           the piChkActionable block), and the muted "finish the fixes above first" wording below is
           written for a board that HAS fixes on it. Saying it over an empty board sends the user
           looking for work that is not on screen. */
        If (piChkActionable(Self) = -1) Begin
            Move (sOut + (((DivOpen("fnext-t fnext-off")) + 'Then: Tidy Up') + CS_DivEnd)) to sOut
            Move (sOut + ((DivOpen("fnext-s")) + ('Run ' + (BoldText("Check")) + ' first ')) + CS_EmDash + (' nothing has been examined in this session yet, so there is no verdict to tidy up after.' + CS_DivEnd)) to sOut
            Move (sOut + (ChipHtml("fact", "fact off", "tidyup", "", "Open Tidy Up", CS_DashTidyAlwaysTip, True))) to sOut
            Function_Return (sOut + CS_DivEnd)
        End
        If (piChkActionable(Self) = 0) Begin
            Get GuidedStageReady to bReady
            Move (piChkHidden(Self)) to iHidden
            /* THE FINISH LINE, and it still offers Tidy Up (Nils 2026-07-29: "It would still be good
               if the 'Open Tidy up' button be available, in case more tidy up work is wanted"). The
               pass is idempotent by design - it only acts on what it still finds - so the honest
               ending is "nothing further is required", never "nothing further is permitted". And a
               run that DOES change something drops Ready back to a Check, which is the loop working
               rather than the badge being wrong. */
            If (bReady = True) Begin
                Move (sOut + ((DivOpen("fnext-t")) + CS_Check + CS_Nbsp + (' Ready' + CS_DivEnd))) to sOut
                Move (sOut + ((DivOpen("fnext-s")) + 'The compiler is clean, the tool has run everything it can, nothing is left to change by hand, and Tidy Up has been through. DFRefactor has nothing further to offer this program.')) to sOut
                If (iHidden > 0) ;
                    Move (sOut + ' ' + (BoldHtml(String(iHidden) + ' finding(s) are still hidden')) + ' ' + CS_EmDash + ' the work behind them stays outstanding.') to sOut
                Move (sOut + (' Tidy Up can be run again whenever you want; it only acts on what it still finds.' + CS_DivEnd)) to sOut
                Move (sOut + (ChipHtml("fact", "fact off", "tidyup", "", "Open Tidy Up", "", True))) to sOut
                Function_Return (sOut + CS_DivEnd)
            End
            /* A RUN THAT CHANGED FILES OWES A CHECK. The board's verdict was reached before those
               rewrites existed, so it cannot be the last word on them - and this is the one place the
               user can be told so, having already declined the offer the run itself made. Worded for
               ANY rewrite, not just Tidy Up: every guided row action sets this now. */
            Get ReadSourceUnverified of ghoApplication to bDirty
            If (bDirty = True) Begin
                Move (sOut + (((DivOpen("fnext-t")) + ('Next: ' + (BoldText("Check")))) + CS_DivEnd)) to sOut
                Move (sOut + (((DivOpen("fnext-s")) + 'Source has changed since this board was built, so its verdict does not describe it. One Check confirms it still compiles - and finishes the trail.') + CS_DivEnd)) to sOut
                Move (sOut + (ChipHtml("fact", "fact off", "verifycheck", "", "Run Check", "", True))) to sOut
                Function_Return (sOut + CS_DivEnd)
            End
            Move (sOut + (((DivOpen("fnext-t")) + ('Next: ' + (BoldText("Tidy Up")))) + CS_DivEnd)) to sOut
            Move (sOut + (((DivOpen("fnext-s")) + 'Nothing left on the board - for the tool or for you. The Tidy Up group holds the tidy-and-remove passes that follow modernization. Safe to run again - it only acts on what it still finds.') + CS_DivEnd)) to sOut
            Move (sOut + (ChipHtml("fact", "fact off", "tidyup", "", "Open Tidy Up", "", True))) to sOut
        End
        Else Begin
            Move (sOut + (((DivOpen("fnext-t fnext-off")) + 'Then: Tidy Up') + CS_DivEnd)) to sOut
            Move (sOut + (((DivOpen("fnext-s")) + 'Finish the fixes and the by-hand changes above first - tidying code that is about to change again just moves the work around.') + CS_DivEnd)) to sOut
            Move (sOut + (ChipHtml("fact", "fact off", "tidyup", "", "Open Tidy Up", CS_DashTidyAlwaysTip, True))) to sOut
        End
        Function_Return (sOut + CS_DivEnd)
    End_Function
    /* The 4544 "declared with more than one return type" family: ONE lead row carrying the ONE
       "Check declarations" chip, then one plain clickable sub-row per colliding name.

       Lifted out of FindingsListHtml 2026-08-21; reshaped 2026-09-03 (Nils: the band read as "a
       series of Check declarations" - five identical chips, one per name, each opening the same
       report on one name). The report over ALL names is the chip's job now; a name's own report
       is still one click away, the whole sub-row being the target (the 4390 site-row pattern).
       ONE ACTION, NOT TWO still holds (Nils 2026-07-22: "it still is confusing with both the Show
       declarations and Rewrite the calls instead buttons... Which one should be clicked?"): the
       report is the cheap, read-only click that produces the numbers, and the rewrite is offered
       by name and by count once the report is closed (OfferCallRewrite). With no names parsed (an
       unexpected message shape) the lead row stands alone rather than dropping the errors from
       the list - the lump row that used to live in _AddCollisionRows.

       sPeekBreak and iBreak are ByRef because the band peek and the band count are shared with the
       4390 rows that follow. The NAMES count toward the band (they are the findings); the lead row
       does not - except when it is all there is. */
    /* The 4544 "declared with more than one return type" family: ONE lead row that names the whole
       family and carries the outlined "Show the report", then one sub-row per colliding name with a
       FILLED "Fix it...".

       Lifted out of FindingsListHtml 2026-08-21; reshaped twice on 2026-09-03. First the five
       identical per-name "Check declarations" chips became one whole-scope chip - which LOST the
       per-name fix offers (rename / align only work for a named function), so the band "checked
       something instead of doing something about the problem" (Nils). Now the name row's chip is
       the fix: RunFixDeclarationOffer runs the same harvest the report makes - silently, no viewer -
       and goes straight to the offers the report used to reach only after its viewer closed. ONE
       ACTION PER ROW still holds (Nils 2026-07-22): the offer chain chooses rename, align or rewrite
       on the harvest's numbers, never the user before them. With no names parsed (an unexpected
       message shape) the lead row stands alone rather than dropping the errors from the list.

       sPeekBreak and iBreak are ByRef because the band peek and the band count are shared with the
       4390 rows that follow. The NAMES count toward the band (they are the findings); the lead row
       does not - except when it is all there is. */
    // "" unless the name at index i has NO reported site this workspace can write; then the leaf of
    // the first DataFlex-owned (or write-protected) file it was reported in. Out-of-range = "".
    Function _AmbiguousForeignLeaf Integer i Integer[] aiOwnSites String[] asForeignFile Returns String
        If (i < 0 or i >= SizeOfArray(aiOwnSites) or i >= SizeOfArray(asForeignFile)) ;
            Function_Return ""
        If (aiOwnSites[i] > 0) ;
            Function_Return ""
        Function_Return asForeignFile[i]
    End_Function

    Function _AmbiguousNameRowsHtml String[] asAmbNames Integer[] aiAmbCounts Integer[] aiOwnSites String[] asForeignFile ;
                                    String[] asFirstFile Integer[] aiFirstLine Integer iRetType ;
                                    String ByRef sPeekBreak Integer ByRef iBreak Returns String
        String  sAmbRows sCountText sHint sForeign sOpen
        Integer i iLastName iNames

        Move "" to sAmbRows
        Move (SizeOfArray(asAmbNames)) to iNames
        If (iNames = 0 and iRetType = 0) ;
            Function_Return ""
        Move (sAmbRows + (FindingRepOpen("e")) + ('compiler' + CS_SpanEnd) + (FindingMsg("E 4544"))) to sAmbRows
        If (iNames > 0) ;
            Move (String(iNames) + ' name(s) declared with more than one return type (' + String(iRetType) + ' error(s))') to sCountText
        Else ;
            Move ('Return-type mismatches (' + String(iRetType) + ')') to sCountText
        Move (sAmbRows + (SpanOpen("ffile")) + sCountText + CS_SpanEnd) to sAmbRows
        Move (sAmbRows + (HintCell(Self, (('A few declarations cause all of these ' + CS_EmDash) + ' fix them name by name below. The report shows the whole picture, and writes nothing.')))) to sAmbRows
        Move (sAmbRows + (ChipHtml("fact alt", "fact alt off", "collreport", "", "Show the report", "Runs the return-type mismatch report over the whole scope and opens it: every contested name, its declarations, who calls them.", True)) + CS_DivEnd) to sAmbRows
        Move (iNames - 1) to iLastName
        For i from 0 to iLastName
            // A chip inside a clickable row fires both handlers - so the sub-row is a plain div, not a target.
            /* THE HINT SAYS WHERE THE SITES ARE (2026-09-20). A name whose every reported call sits
               inside DataFlex's own packages has no call the rewrite can reach, so "or rewrite the
               calls" was a promise the offer chain then broke (a live Rewrite button, then "none of
               the 3 file(s) the compiler named can be written"). The chip stays: the scan is still
               what tells whether a declaration HERE causes it - that one is renameable - and when
               nothing here declares it, the offer says so instead of offering the rewrite. */
            Get _AmbiguousForeignLeaf i aiOwnSites asForeignFile to sForeign
            /* The NAME is the link (Nils 2026-09-20: "missing a link that can be clicked so the file
               can be shown in the editor", then "more logical to have it like all the other rows,
               where it is the file name that has the link"): the name span carries the opensrc jump
               to the first reported call. A chip inside a clickable ROW fires both handlers, so the
               row stays a plain div and only the span is the target - the chip is its sibling. */
            If (i < SizeOfArray(asFirstFile) and i < SizeOfArray(aiFirstLine) and asFirstFile[i] <> "") Begin
                Move ((SpanOpenClick("ffile", "opensrc", (asFirstFile[i] + '|' + String(aiFirstLine[i])), ("Opens the editor at the first reported call: " + (HtmlEscaped(Self, asFirstFile[i])) + " line " + String(aiFirstLine[i]) + "."))) + asAmbNames[i] + ' (' + String(aiAmbCounts[i]) + (')' + CS_SpanEnd)) to sOpen
            End
            Else Begin
                Move ((SpanOpen("ffile")) + asAmbNames[i] + ' (' + String(aiAmbCounts[i]) + (')' + CS_SpanEnd)) to sOpen
            End
            If (sForeign <> "") Begin
                /* OUTLINED "Check declarations", not a filled "Fix it..." (Nils 2026-09-20: "Is it
                   correct that the Fix it... button is shown?"). With no call to rewrite, the scan can
                   only find a workspace declaration to rename, or confirm there is none - a look, not
                   a fix, and the chip says which it is. Same action underneath (RunFixDeclarationOffer):
                   a declaration found here gets the rename offer; none gets the "nothing to rewrite"
                   box with the build's first error. */
                Move ("Every reported call is inside DataFlex's own packages (" + sForeign + "), where nothing is rewritten. Nothing on this row is fixed from here; what remains is to check whether this workspace declares the name (a minute or two) - when nothing here does, the error is a symptom of an earlier failure in this build, not of this name.") to sHint
                Move (sAmbRows + (DivOpen("fnd sub")) + (SpanOpen("fdot e inv")) + CS_SpanEnd + (FindingBadge("name")) + sOpen + (HintCell(Self, sHint)) + (ChipHtml("fact alt", "fact alt off", "fixdecl", (asAmbNames[i]), "Check declarations", "Scans the compiled scope for a declaration of this name here (a minute or two). One found: the rename offer follows. None: nothing on this row can be fixed, and the box says where to look instead. Nothing is written before you say so.", True)) + CS_DivEnd) to sAmbRows
            End
            Else Begin
                Move "A scan finds its declarations (a minute or two), then the fix is offered: rename them, align the odd return type, or rewrite the calls." to sHint
                Move (sAmbRows + (DivOpen("fnd sub")) + (SpanOpen("fdot e inv")) + CS_SpanEnd + (FindingBadge("name")) + sOpen + (HintCell(Self, sHint)) + (ChipHtml("fact", "fact off", "fixdecl", (asAmbNames[i]), ("Fix it" + CS_Ellipsis), "Scans the compiled scope for this name's declarations, then offers the fix - rename, align the return type, or rewrite the calls. Nothing is written before you say so.", True)) + CS_DivEnd) to sAmbRows
            End
            // The peek names what leads the band - the first 4544 name.
            If (i = 0) ;
                Move (asAmbNames[i] * "declared with different return types") to sPeekBreak
            Increment iBreak
        Loop
        If (iNames = 0) ;
            Increment iBreak
        Function_Return sAmbRows
    End_Function


    /* The declared-site sub-rows under ONE 4390 name row. Returns the sub-rows html for name
       index i, or "" when that name has no site list. Split out of _BackportNameRowsHtml
       2026-09-02 (structural only - the loop, its cap and its rationale moved here verbatim).
       The two-level site arrays are ByRef so the per-name call does not deep-copy them; i
       indexes both. */
    Function _BackportSiteRowsHtml Integer i String[][] ByRef asSiteFiles Integer[][] ByRef aiSiteLines Returns String
        String  sSiteBase sSiteRows
        Integer iPos iSite iSiteMax iSiteShown

        /* THE DECLARATION ITSELF, ONE CLICK AWAY (Nils 2026-08-16: "This line in the dashboard
           grid helps nobody ... the SQLEXECUTE - or a sub-line - was clickable to load the
           offending file into the editor so it could be renamed/commented out ... The 'Show
           declarations' do list the files, but ... one has to manually go through that list").

           The 4390 fires AT the declaration, so the grid knows exactly where each name is
           declared. One sub-row per site, and the WHOLE sub-row is the click target - the same
           opensrc jump every ordinary finding row has - opening the editor at that line, where
           the rename / comment-out / guard is done. Siblings of the name row, never nested inside
           it (a cWebHtmlBox click fires every ancestor's handler). Capped: past eight, the report
           chip on the name row is the list. Sub-rows are detail, not findings: they do not count
           toward the header. */
        Move "" to sSiteRows
        Move 0  to iSiteShown
        If (i < SizeOfArray(asSiteFiles)) Begin
            Move (SizeOfArray(asSiteFiles[i]) - 1) to iSiteMax
            For iSite from 0 to iSiteMax
                If (iSiteShown < 8) Begin
                    Move asSiteFiles[i][iSite] to sSiteBase
                    Move (RightPos("\", sSiteBase)) to iPos
                    If (iPos > 0) ;
                        Move (Right(sSiteBase, (Length(sSiteBase) - iPos))) to sSiteBase
                    Move (sSiteRows + (ClickableHtml("div", "fnd sub", "opensrc", (asSiteFiles[i][iSite] + '|' + String(aiSiteLines[i][iSite])), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("declared")) + (SpanOpen("ffile")) + sSiteBase + ' (' + String(aiSiteLines[i][iSite]) + ((')' + CS_SpanEnd + ((HintOpen(Self, "Opens the editor at this declaration - rename it, comment it out or guard it right there.")) + 'Opens the editor at this declaration ')) + CS_EmDash + (' rename it, comment it out or guard it right there.' + CS_SpanEnd))), ((HtmlEscaped(Self, asSiteFiles[i][iSite])))))) to sSiteRows
                    Increment iSiteShown
                End
            Loop
            If (iSiteMax + 1 > iSiteShown) ;
                Move (sSiteRows + (((DivOpen("fnd sub")) + (SpanOpen("fdot e inv"))) + CS_SpanEnd + (SpanOpen("ffile"))) + CS_Ellipsis + ' and ' + String(iSiteMax + 1 - iSiteShown) + (' more' + CS_SpanEnd) + (HintCell(Self, "Show declarations lists them all.")) + CS_DivEnd) to sSiteRows
        End
        Function_Return sSiteRows
    End_Function

    /* The 4390 "name DataFlex already uses" rows, with their per-site sub-rows.

       Lifted out of FindingsListHtml 2026-08-21 (Nils: "way too complicated and should be broken up").
       Verbatim - the parameters keep the caller's names so nothing inside had to be rewritten.

       The seven site/scratch locals (iPos, iSite, iSiteMax, iSiteShown, sSiteBase, sSiteRows,
       iLastName) became locals rather than parameters: each is checked dead after the block in
       the caller, so nothing downstream can see the values this leaves behind. (2026-09-02: the
       five per-site ones now live in _BackportSiteRowsHtml; sSiteRows and iLastName stay here.)
       sPeekBreak and iBreak stay ByRef - they are the band peek and the band count, shared with
       the 4544 rows. */
    Function _BackportNameRowsHtml String[] asBackNames Integer[] aiBackCounts ;
                                   Boolean[] abGuardable Boolean[] abExternal ;
                                   String[][] asSiteFiles Integer[][] aiSiteLines ;
                                   String[] asAmbNames ;
                                   String ByRef sPeekBreak Integer ByRef iBreak Returns String
        String  sRepRow sSiteRows
        Integer i iLastName
        String[][]  asSites
        Integer[][] aiLines

        // REPORTS ARE FIRST-CLASS ROWS (the agreed shape): ONE row at the top of Breaks-the-build carrying the
        // collision COUNT and a "Check declarations" action running FunctionReturnMismatchReport over the CURRENT scope -
        // ("Check", not "Show" - the button RUNS the declaration scan, it does not display something
        // already known; Nils 2026-07-23, and it matches the view's own "Check" verb.)
        // no Folders detour, no hunting it among ~95 functions. This is what replaces the old post-analyze
        // YesNo nudge, which the guided path deliberately suppresses (see StartAnalyze's guided branch).
        // ONE ROW PER COLLIDING NAME, not a lump sum. The user's question was "what do I try next?" and a
        // row saying "Return-type mismatches (220)" cannot answer it - the cause is a handful of
        // DECLARATIONS, and naming them turns 220 errors into a short list of lines to look at.
        // Accumulated in order and prepended ONCE; prepending each separately would reverse them.
        Move "" to sRepRow
        // Local copies for the ByRef hand-off to _BackportSiteRowsHtml: a function's own by-value
        // parameter must not be forwarded by reference (copy it to a local first), and copying ONCE
        // here, not once per name, is what keeps the per-name call from deep-copying the site arrays.
        Move asSiteFiles to asSites
        Move aiSiteLines to aiLines
        Move (SizeOfArray(asBackNames) - 1) to iLastName
        For i from 0 to iLastName
            Move (sRepRow + (FindingRepOpen("e")) + ('compiler' + CS_SpanEnd) + (FindingMsg("E 4390"))) to sRepRow
            Move (sRepRow + (SpanOpen("ffile")) + asBackNames[i] + ' (' + String(aiBackCounts[i]) + (')' + CS_SpanEnd)) to sRepRow
            // Offer the one-click guard ONLY when it can actually work for this name (a global function
            // DataFlex's Pkg source also declares). Where DataFlex owns the name from its runtime or a
            // class method, a version guard would compile cleanly while quietly changing behaviour -
            // there the honest fix is a rename. The EXTERNAL_FUNCTION flavor is different again: both
            // sides declare the same Windows API, so the fix is deleting or hand-guarding the duplicate
            // declaration - Check declarations names both sides (harvest extended 2026-07-23; before
            // that it opened a report that named nothing, "takes us back to the same spot").
            If (abGuardable[i] = True) Begin
                Move (sRepRow + (HintCell(Self, "DataFlex provides this too. The workspace's copy can be kept for older releases."))) to sRepRow
                If (pbGuardFoundNothing(Self) = True) ;
                    Move (sRepRow + (ChipHtml("fact", "fact off", "", "", "Nothing to change", "", False)) + CS_DivEnd) to sRepRow
                Else ;
                    Move (sRepRow + (ChipHtml("fact", "fact off", "guardglobals", "", "Guard them", "", True)) + CS_DivEnd) to sRepRow
            End
            Else Begin
                If (abExternal[i] = True) ;
                    Move (sRepRow + (HintCell(Self, (('DataFlex now declares this same Windows API itself ' + CS_EmDash) + " Guard it keeps the workspace's declaration for older releases and reads DataFlex's own from the target version on. Nothing is deleted.")))) to sRepRow
                Else ;
                    Move (sRepRow + (HintCell(Self, (('DataFlex uses this name for something else ' + CS_EmDash) + ' rename the one in the workspace. Guarding it would change behaviour.')))) to sRepRow
                /* OUTLINED AND WORDED AS WHAT IT IS (Nils 2026-08-16: "Why is the Check declarations
                   button dark with a light font for SQLEXECUTE, while the other buttons have a
                   light color with a dark text?"). The distinction was always deliberate - a
                   FILLED chip fixes something (Guard them; the 4544 report where the report IS the
                   next step), an OUTLINED chip only shows you, because the fix here is by hand -
                   but a convention nobody is told reads as a mistake. So the outlined chip now
                   SAYS it: "Show declarations" - it opens the same report, and the verb tells the
                   truth about what pressing it does for this row. */
                /* THE RENAME, ON THE ROW (Nils 2026-08-16: "should perhaps a suggestion be asked to
                   auto-rename the SQLEXECUTE function and everywhere it is currently used? We already
                   have logic to do that, right?"). We do - RenameCollidingGlobalFunction, offered by
                   OfferHandRenameWorklist - but only AFTER the declaration report closed, so a user
                   who took the sub-row to the editor never met it and renamed by hand. Now the filled
                   chip on the row: the new name is entered next (default <name>X), the declaration,
                   expression calls and of-less Gets rename across the whole selected scope, and
                   Get/Send ... of <object> forms are left alone. The External_Function flavor keeps
                   its own fix (the guard, below) - a rename is not its fix. */
                /* THE FIX ON THE ROW FOR THIS FLAVOUR TOO (Nils 2026-09-03: the two WinServ rows offered
                   only text and "Show declarations", while their fix - the Use-arm the wide guard
                   writes - sat as a Review row behind a non-empty Auto-fixable band, found by
                   accident). The filled chip runs it over THIS name's declaring files; a same-width
                   duplicate falls to GuardDuplicateExternalFunctions (RunGuardExternalForName). */
                If (abExternal[i] = False) ;
                    Move (sRepRow + (ChipHtml("fact", "fact off", "renamename", (asBackNames[i]), ("Rename it" + CS_Ellipsis), "Renames the declaration and every call site across the selected scope - you enter the new name next. Get/Send ... of <object> forms are never touched.", True))) to sRepRow
                Else ;
                    Move (sRepRow + (ChipHtml("fact", "fact off", "guardext", (asBackNames[i]), "Guard it", "Version-guards this declaration in the file(s) declaring it: it stays for older releases, the target DataFlex reads its own. No call site changes; nothing is deleted.", True))) to sRepRow
                Move (sRepRow + (ChipHtml("fact alt", "fact alt off", "collreport", (asBackNames[i]), "Show declarations", "Opens the declaration report for this name - both sides of the clash, and every use.", True)) + CS_DivEnd) to sRepRow
            End
            // The declared-site sub-rows for this name (the rationale travels with them, in the helper).
            Get _BackportSiteRowsHtml i (&asSites) (&aiLines) to sSiteRows
            Move (sRepRow + sSiteRows) to sRepRow
            If (i = 0 and SizeOfArray(asAmbNames) = 0) ;
                Move (asBackNames[i] * "and other names DataFlex already uses") to sPeekBreak
            Increment iBreak
        Loop

        Function_Return sRepRow
    End_Function

    /* The opening of a compiler finding row - dot, badge, message. Two branches of the findings
       loop built it, character for character the same, 56 lines apart. */
    Function _CompilerRowHtml String sMsg Returns String
        Function_Return ((DivOpen("fnd")) + (SpanOpen("fdot e")) + CS_SpanEnd ;
            + (FindingBadge("compiler")) ;
            + (SpanOpen("fmsg")) + sMsg + CS_SpanEnd)
    End_Function

    /* Decides whether one cause group is DataFlex's own and therefore NOT LISTED. Hands back
       bCauseSilent (True = leave it out of the band) and sCauseDef - the "file|line" definition
       site off the compile index, "" when the name is defined nowhere in the compiled source.
       The index arrays arrive ByRef: they are read for every cause and must not be copied per
       call. Split out of _CauseGroupRowsHtml 2026-09-02, verbatim. */
    Procedure _CauseIsSilent String sCauseName Integer iCauseKind String[] ByRef asCauseScope ;
                             String[] ByRef asIdxKey String[] ByRef asIdxParent String[] ByRef asIdxSite ;
                             Boolean ByRef bCauseSilent String ByRef sCauseDef
        String  sCauseLow sCauseParent sIdxKey
        Integer iIdx

        /* NOT EVERY CAUSE IS A FINDING (Nils 2026-08-19, on 3x "class ReportView"): "there is a
           piece of old legacy strange code inside the DataFlex system View class ... The special
           logic handles deferred views, a technique Data Access developed to speed up the start of
           a program ... these are false flagged incidences we can be silent about. That also counts
           for the ReportView class and subclasses."

           He is right, and the test is EVIDENCE, not a name list: when the class's definition is
           nowhere in the compiled source it is DataFlex's own, so nothing in this workspace can
           change what is inside it - there is no work to show. The view family is named as well,
           because a SUBCLASS of it (his cTrDbView, cTrReportView) does live in his source while
           the deferred-view machinery it inherits still does not: one level of parent lookup catches
           those without silencing every class that merely descends from cObject.

           Silent means NOT LISTED, not "hidden": the Analyzer grid still holds every row, so it
           keeps matching the compiler, and the count is stated once under the band below. */
        Move False to bCauseSilent
        Move (Lowercase(Trim(sCauseName))) to sCauseLow
        If (sCauseLow = "view" or sCauseLow = "reportview" or sCauseLow = "dbview" ;
            or sCauseLow = "dbreportview" or sCauseLow = "basereportview") ;
            Move True to bCauseSilent
        /* Where is it defined? "" = nowhere in the compiled set, i.e. DataFlex's own.

           OFF THE INDEX, not by scanning (2026-08-19). This used to call FindDefinitionSite,
           which reads and word-splits every file in the compiled scope ONCE PER NAME - four
           times over 40.3 MB on Nils's workspace, on every render, which is what made opening
           WinServ and closing the Libraries dialog crawl. The index is built once per compile
           and answers every name from memory. */
        Move "" to sCauseDef
        Move -1 to iIdx
        If (SizeOfArray(asCauseScope) > 0 and bCauseSilent = False) Begin
            If (iCauseKind = eMacroCauseClass) ;
                Move ("c|" + sCauseLow) to sIdxKey
            Else ;
                Move ("m|" + sCauseLow) to sIdxKey
            Move (SearchArray(sIdxKey, asIdxKey)) to iIdx
            If (iIdx >= 0) ;
                Move asIdxSite[iIdx] to sCauseDef
        End
        // Defined nowhere in the compiled source -> DataFlex's own -> nothing here to act on.
        If (sCauseDef = "" and bCauseSilent = False and SizeOfArray(asCauseScope) > 0) ;
            Move True to bCauseSilent
        /* A SUBCLASS of the view family: its own definition IS in the source, but the technique it
           inherits is not. One level up - "Class cTrDbView is a dbView" - which is enough for the
           real shapes and cannot silence an ordinary class descending from cObject.

           The parent comes off the index too. It used to mean RE-READING the definition file to
           look at one line - a second full file read per cause, on top of the scan that found it.
           The index recorded the parent while it was already on that line. */
        If (bCauseSilent = False and iCauseKind = eMacroCauseClass and iIdx >= 0) Begin
            Move asIdxParent[iIdx] to sCauseParent
            If (sCauseParent = "view" or sCauseParent = "reportview" or sCauseParent = "dbview" ;
                or sCauseParent = "dbreportview" or sCauseParent = "basereportview") ;
                Move True to bCauseSilent
        End
    End_Procedure

    /* One LISTED cause row - the count, "class"/"macro" name, the hint, the action chip and a
       clickable sample use. Returns the row's HTML; the caller prepends it to the hand-review
       band. Takes the scalars for cause i plus its definition site (sCauseDef, "" = not in the
       compiled source) and the caller's own analyzer object (hoCause, 0 = none). Split out of
       _CauseGroupRowsHtml 2026-09-02, verbatim. */
    Function _CauseRowHtml String sCauseName String sCauseFile Integer iCauseKind ;
                           Integer iCauseLine Integer iCauseCount String sCauseDef ;
                           Handle hoCause Returns String
        String sRow sMacroHint sCauseFn

        Move ((FindingRepOpen("w")) + String(iCauseCount) + CS_Times + CS_SpanEnd) to sRow
        If (iCauseKind = eMacroCauseClass) ;
            Move (sRow + ((SpanOpen("fmsg")) + 'class ') + sCauseName + CS_SpanEnd) to sRow
        Else ;
            Move (sRow + ((SpanOpen("fmsg")) + 'macro ') + sCauseName + CS_SpanEnd) to sRow
        If (iCauseKind = eMacroCauseClass) ;
            Move ("The obsolete technique is inside this class, so the compiler repeats it at every object declared from it. Nothing on those lines can change it.") to sMacroHint
        Else ;
            Move ("The obsolete construct is inside this macro command's body, so the compiler repeats it at every invocation. Nothing on those lines can change it.") to sMacroHint
        If (sCauseDef = "") ;
            Move (sMacroHint + " Its definition is not in the compiled source - it belongs to DataFlex or to a library you do not build, so there is nothing here to fix.") to sMacroHint
        Move (sRow + (SpanOpenTip("fhint", sMacroHint)) + sMacroHint + CS_SpanEnd) to sRow
        /* THE ACTION. A class DFRefactor can migrate gets its converter (the 4537 recipe table is
           the single source for class -> function, so this cannot drift from the grid); anything
           else with a definition in the workspace gets a jump to that definition, which is the one
           place a fix could go. */
        Move "" to sCauseFn
        If (iCauseKind = eMacroCauseClass and hoCause <> 0) ;
            Get RecipeFunctionForClass of hoCause sCauseName to sCauseFn
        If (sCauseFn <> "") ;
            Move (sRow + (ChipHtml("fact", "fact off", "runfnscope", (sCauseFn), ("Convert them" + CS_Ellipsis), ('Runs ' + sCauseFn + ' over the files the compiler reported, converting objects of this class.'), True)) + CS_DivEnd) to sRow
        Else If (sCauseDef <> "") ;
            Move (sRow + (ChipHtml("fact alt", "fact alt off", "opensrc", (sCauseDef), "Open the definition", "Opens the definition - the only place this can be changed.", True)) + CS_DivEnd) to sRow
        Else ;
            Move (sRow + (ChipHtml("fact", "fact off", "", "", "Nothing to change here", "", False)) + CS_DivEnd) to sRow
        // A clickable sample use, so "where does this even appear?" has an answer.
        Move (sRow + (ClickableHtml("div", "fnd sub", "opensrc", (sCauseFile + '|' + String(iCauseLine)), (((SpanOpen("fdot w inv")) + CS_SpanEnd) + (FindingBadge("example")) + (SpanOpen("ffile")) + (HtmlEscaped(Self, sCauseFile)) + ' (' + String(iCauseLine) + (')' + CS_SpanEnd + ((HintOpen(Self, ("One of the " + String(iCauseCount) + " reported uses - opens the editor there."))) + 'One of the ')) + String(iCauseCount) + (' reported uses - opens the editor there.' + CS_SpanEnd)), ""))) to sRow
        Function_Return sRow
    End_Function

    /* The lump row for the "reported away from the construct" findings whose cause could not be
       named - prepended to the hand-review band (sHand) and counted in iHand, both ByRef. Does
       nothing when every one of the iMacro findings was attributed to a named cause. Split out of
       _CauseGroupRowsHtml 2026-09-02, verbatim. */
    Procedure _CauseLumpRowHtml Integer iMacro Integer iCauseNamed Integer iCauseCapped ;
                                String ByRef sHand Integer ByRef iHand
        String sRow sMacroHint

        // Whatever could not be named keeps a lump row - counted, never silently dropped.
        If (iMacro > iCauseNamed) Begin
            Move ((FindingRepOpen("w")) + String(iMacro - iCauseNamed) + CS_Times + CS_SpanEnd) to sRow
            Move (sRow + (FindingMsg("Reported away from the construct"))) to sRow
            /* TWO DIFFERENT FACTS, AND THEY MUST NOT SHARE ONE SENTENCE. "The cause could not be
               read" is a claim about the source; "we stopped looking" is a claim about us. Saying
               the first when the second is true is what put 333 rows under a wrong explanation. */
            If (iCauseCapped > 0) ;
                Move ("The compiler reports these where a macro or class is USED, and the construct itself is not on those lines. " + String(iCauseCapped) + " of them were not examined - the board stops opening files after " + String(CI_ModCauseReadCap) + " to keep Check responsive - so nothing is claimed about their cause. The Analyzer grid holds every one.") to sMacroHint
            Else ;
                Move "The compiler reports these where a macro or class is USED, and the construct itself is not on those lines. The cause could not be read off the line, so nothing is claimed about it - open a row in the Analyzer grid to see the source." to sMacroHint
            Move (sRow + (SpanOpenTip("fhint", sMacroHint)) + sMacroHint + (CS_SpanEnd + CS_DivEnd)) to sRow
            Move (sRow + sHand) to sHand
            Increment iHand
        End
    End_Procedure

    /* The "reported away from the construct" cause groups, and the header chip that qualifies them.

       Lifted out of FindingsListHtml 2026-08-21 (Nils: "way too complicated and should be broken
       up"). Verbatim - the parameters keep the caller's names so nothing inside was rewritten.

       NINETEEN locals came along as locals rather than parameters. Each was checked dead after the
       block in the caller first, so no value this leaves behind can be read downstream. Only three
       things actually cross the boundary: the hand-review band it appends to (sHand), that band's
       count (iHand), and the chip it returns. (2026-09-02: the per-cause locals now live in
       _CauseIsSilent / _CauseRowHtml; the boundary is unchanged.) */
    Function _CauseGroupRowsHtml String[] asCauseName String[] asCauseFile ;
                                 Integer[] aiCauseKind Integer[] aiCauseLine Integer[] aiCauseCount ;
                                 Integer iCauseCapped Integer iMacro ;
                                 String ByRef sHand Integer ByRef iHand Returns String
        String[]  asCauseScope asIdxKey asIdxParent asIdxSite asDefLines
        String    sCauseName sCauseDef sRow
        String    sSilentChip
        Integer   i iCauseLast iCauseNamed iCauseSilent iDefLn
        Boolean   bCauseSilent
        Handle    hoCause

        Move (SizeOfArray(asCauseName) - 1) to iCauseLast
        /* ITS OWN ANALYZER OBJECT. hoCall - the one the row loop creates - is DESTROYED a few lines
           above, right after that loop, so reaching for it here sent to a dead handle and raised
           err 98 "Invalid message" on GET_RECIPEFUNCTIONFORCLASS the moment a workspace opened
           (Nils 2026-08-19). Created only when there is a group to render, and destroyed below. */
        Move 0 to hoCause
        If (iCauseLast >= 0) Begin
            Get CompiledScopeFiles to asCauseScope
            // One pass for every name below, cached against the compile - see the property block.
            Send EnsureDefinitionIndex (&asCauseScope)
            Get pasIdxKey    to asIdxKey
            Get pasIdxParent to asIdxParent
            Get pasIdxSite   to asIdxSite
            Get Create (RefClass(cModAnalyzer)) to hoCause
        End
        Move 0 to iCauseNamed
        For i from 0 to iCauseLast
            Move (iCauseNamed + aiCauseCount[i]) to iCauseNamed
            // Silent (DataFlex's own) or listed? And where is it defined? See _CauseIsSilent.
            Send _CauseIsSilent asCauseName[i] aiCauseKind[i] (&asCauseScope) (&asIdxKey) (&asIdxParent) (&asIdxSite) (&bCauseSilent) (&sCauseDef)
            If (bCauseSilent = True) Begin
                Move (iCauseSilent + aiCauseCount[i]) to iCauseSilent
            End
            Else Begin
            Get _CauseRowHtml asCauseName[i] asCauseFile[i] aiCauseKind[i] aiCauseLine[i] aiCauseCount[i] sCauseDef hoCause to sRow
            Move (sRow + sHand) to sHand
            Increment iHand
            End       // (not silent)
        Loop
        If (hoCause <> 0) ;
            Send Destroy of hoCause
        /* SAID ONCE - AND IT MOVED OUT OF THE BAND, 2026-08-19. It used to be appended to sHand, so
           it rendered UNDER the band. That worked only while the band had rows of its own: the note
           never increments iHand, and BandHtml returns "" on a zero count. The moment the cap fix
           let all 533 of Nils's findings be recognised as DataFlex's own, the band emptied - and the
           only statement that 533 compiler findings had been set aside emptied with it. Correct that
           the band goes (none of them are hand-migration work); wrong that the board then said
           nothing at all, while the Analyzer grid still held every one.

           The header chip is the right home: it is where the board already declares set-aside work
           (hidden findings, dead-dependency skips), it sits beside the total it qualifies, and it
           does not depend on any band surviving. Built here, where iCauseSilent is known; rendered
           into the Findings header far below. */
        Move "" to sSilentChip
        If (iCauseSilent > 0) ;
            Move ((SpanOpenTipHtml("fign", CS_DashSystemClassTip)) + String(iCauseSilent) ;
                + ' inside DataFlex&rsquo;s own classes' + CS_SpanEnd) to sSilentChip
        // Whatever could not be named keeps a lump row - see _CauseLumpRowHtml.
        Send _CauseLumpRowHtml iMacro iCauseNamed iCauseCapped (&sHand) (&iHand)

        Function_Return sSilentChip
    End_Function

    /* The four chips that qualify the Findings header - hidden, plan, system, dead-dependency.

       Lifted out of FindingsListHtml 2026-08-21 (Nils: "way too complicated and should be broken
       up"). Verbatim; the parameters keep the caller's names.

       A Procedure with six ByRef rather than a Function, because these are four separate strings
       that land at four different places in the header - concatenating them here would only force
       the caller to pull them apart again. iIgnored and bHavePlan come back too: both are read
       further down. The five genuinely local ones - hoIgn, aIgnoredNow, asSkipped, iSkipped,
       iSysRows - were each checked dead in the caller before being moved in here. */

    Procedure _HeaderChipsHtml String ByRef sIgnChip String ByRef sPlanChip ;
                               String ByRef sSysChip String ByRef sSkipChip ;
                               Integer ByRef iIgnored Boolean ByRef bHavePlan ;
                               Integer iListedElsewhere
        tModIgnore[] aIgnoredNow
        String[]     asSkipped
        Handle       hoIgn
        Integer      iSkipped iSysRows

        Move "" to sIgnChip
        Get Create (RefClass(cModAnalyzer)) to hoIgn
        Get ReadIgnored of hoIgn to aIgnoredNow
        Send Destroy of hoIgn
        Move 0 to iIgnored
        If (ghoModAnalyzerDock <> 0) ;
            Get piSumIgnored of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iIgnored
        Set piChkHidden to iIgnored
        If (iIgnored > 0) ;
            Move ((SpanOpen("fign")) + String(iIgnored) + ' hidden ' + (ChipHtml("fact", "fact off", "clearignored", "", "Show them again", "", True)) + CS_SpanEnd) to sIgnChip
        Else If (SizeOfArray(aIgnoredNow) > 0) ;
            Move ((SpanOpenTip("fign", CS_DashDismissedTip)) + (ChipHtml("fact", "fact off", "clearignored", "", "Show hidden findings again", "", True)) + CS_SpanEnd) to sIgnChip
        /* THE WAY BACK IN AFTER A RESTART. Offered only when a saved plan EXISTS and no Check has run
           this session - a dead link on a fresh workspace helps nobody, and once a real Check has run
           its result is the truth. Once loaded, the header says plainly that this is the previous
           Check and when it ran; it must never be mistakable for fresh. */
        Move "" to sPlanChip
        If (Trim(psLastPlanStamp(Self)) <> "") ;
            Move (((SpanOpen("fign")) + 'Last Check ') + CS_EmDash + ' ' + psLastPlanStamp(Self) + ' ' + CS_MidDot + ((' run ' + (BoldText("Check")) + ' to refresh') + CS_SpanEnd)) to sPlanChip
        Else Begin
            Get SavedPlanFileExists of ghoApplication to bHavePlan
            If (bHavePlan = True and piChkTickAnalyze(ghoApplication) = 0) ;
                Move ((SpanOpen("fign")) + (ChipHtml("fact", "fact off", "showlastplan", "", "Show last Check", "", True)) + CS_SpanEnd) to sPlanChip
        End
        /* WHAT THE SCAN DID NOT LOOK AT, next to what it found (Nils 2026-08-09).

           A dead dependency - Crystal Reports, WinQL32 - is skipped at collection, because every
           finding inside a package that is going to be DELETED is work thrown away. Measured over
           the DF18/DF19 trees those two families hold 26% of the whole legacy-Type surface, so the
           skip is worth a quarter of that report. A number that large cannot be silent: it changes
           what "Findings 47" means.

           HERE rather than on the scope band, which is where coverage facts otherwise live. That
           band repaints on every tile refresh and deliberately does no disk work; this count only
           exists after a collection pass, so there it would read empty before the first Check and
           stale after. The Check IS the pass that filled it, so the honest place is beside the
           number that pass produced.

           Sibling to the hidden-findings chip in every respect, including the way out: that one
           offers "Show them again", this one names the files. A count the reader cannot expand
           invites the question it refuses to answer. */
        /* THE THIRD SET-ASIDE: findings in files DFRefactor will not write (Nils 2026-08-19, "add the
           third chip"). Its absence was found by ARITHMETIC, not by eye - his Check held 662 rows and
           the header accounted for 653 of them (533 DataFlex-owned + 120 hidden). The missing 9 were
           W 4536 rows in the DataFlex install itself, dropped by the scope gate and named only in the
           Analyzer grid. A board that shows a total must let its own states add up to it.

           Read from piSumFiltered, which BOTH load paths now publish - the live one always did, and
           the restore path was returning a flat 0 until it was taught to recount (ModAnalyzerFT). A
           chip fed by the live path alone would have been right after a Check and wrong after a
           restart, which is the same defect this session already fixed twice. */
        Move "" to sSysChip
        If (ghoModAnalyzerDock <> 0) Begin
            /* OFF THE GRID, NOT THE DOCK. psErrorFile / psPlanSourcePrn live on oAnalyzerArea (the
               dock) but every piSum* counter is declared INSIDE oModAnalyzer_grd, so the dock does not
               understand this message and answering it raised err 98 "Invalid message" on
               GET_PISUMFILTERED the moment a workspace loaded (Nils 2026-08-19). Same reach the row
               build a few hundred lines above already uses for BuildSavedPlanRowsVisible - two
               properties named in the same file are not necessarily on the same object. */
            Get piSumFiltered of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iSysRows
            /* MINUS what the board now LISTS (2026-08-29): the pool-package rows aggregated into
               the read-only packages band and the install 4536s re-pointed at their Use lines are
               no longer set aside, so counting them here again would double-report them. What
               remains under this chip is the genuinely unlisted rest - DataFlex's own install
               files with nothing for the user to act on. */
            Move (iSysRows - iListedElsewhere) to iSysRows
            If (iSysRows > 0) ;
                Move ((SpanOpenTip("fign", CS_DashUnwritableTip)) + String(iSysRows) + (' in read-only system files' + CS_SpanEnd)) to sSysChip
        End
        Move "" to sSkipChip
        Get pasDeadDepSkipped of ghoApplication to asSkipped
        Move (SizeOfArray(asSkipped)) to iSkipped
        If (iSkipped > 0) ;
            Move ((SpanOpen("fign")) + String(iSkipped) + ' in scope skipped ' + CS_EmDash + ' dead dependency ' + (ChipHtml("fact", "fact off", "showskipped", "", "Which ones?", "", True)) + CS_SpanEnd) to sSkipChip
        /* THE LIBRARY SKIP, on its own chip (2026-09-16). It gets a sentence of its own rather
           than being folded into the count above, because the two mean opposite things to the
           reader: a dead dependency is work not worth doing, a library is work to do SOMEWHERE
           ELSE. Counts drop the first time this runs on a workspace with recognised libraries -
           which is exactly why it must be visible. An unrecognised library is NOT here: it stayed
           in scope, because it is presumed yours. */
        Get pasLibrarySkipped of ghoApplication to asSkipped
        Move (SizeOfArray(asSkipped)) to iSkipped
        If (iSkipped > 0) ;
            Move (sSkipChip + (SpanOpen("fign")) + String(iSkipped) + ' in third-party libraries ' + CS_EmDash + ' refactor those upstream' + CS_SpanEnd) to sSkipChip
    End_Procedure

    /* The tally loop of _OtherProjectsHealthHtml (see the design record above that function):
       walks every workspace project other than sMain (the main program's name, lowercased and
       without its extension) and hands back, all ByRef: sParts - the "; "-joined named ERRORS
       entries, capped at CI_OtherProjHealthNameCap; iClean / iNever / iErrs - the per-state
       counts; iNamed - how many of iErrs are in sParts; iOthers - the projects examined;
       iExeOnly / dtOldestExe - the projects whose only artifact is an exe (no .err, no .prn)
       and the oldest of those exes; and bOthersBad, set True (never reset here) when any other
       project has errors recorded on its last build. asProjects arrives ByRef only so it is not
       copied. Split out 2026-09-02, verbatim; exe-only added 2026-09-03. */
    Procedure _TallyOtherProjects String[] ByRef asProjects String sMain ;
                                  String ByRef sParts Integer ByRef iClean Integer ByRef iNever ;
                                  Integer ByRef iOthers Integer ByRef iErrs Integer ByRef iNamed ;
                                  Boolean ByRef bOthersBad Integer ByRef iExeOnly DateTime ByRef dtOldestExe
        tProjectBuildHealth Health
        tSwsFile WS
        String sName
        Integer i iMax iDot

        Get pCurrentSws of ghoApplication to WS
        Move "" to sParts
        Move 0 to iClean
        Move 0 to iNever
        Move 0 to iOthers
        Move 0 to iErrs
        Move 0 to iNamed
        Move 0 to iExeOnly
        Move (SizeOfArray(asProjects) - 1) to iMax
        For i from 0 to iMax
            Move (Lowercase(Trim(asProjects[i]))) to sName
            Move (Pos(".", sName)) to iDot
            If (iDot > 1) ;
                Move (Left(sName, (iDot - 1))) to sName
            If (sName <> sMain and sName <> "") Begin
                Increment iOthers
                Get ProjectBuildHealth of ghoApplication asProjects[i] WS to Health
                If (Health.eState = CI_BuildHealthErrors) Begin
                    Move True to bOthersBad
                    Increment iErrs
                    If (iNamed < CI_OtherProjHealthNameCap) Begin
                        Increment iNamed
                        If (sParts <> "") ;
                            Move (sParts + "; ") to sParts
                        Move (sParts + (BoldHtml(HtmlEscaped(Self, asProjects[i]))) + ' ' + CS_EmDash + ' ' + String(Health.iErrors) + ' error(s) on its last build (' + Health.sWhen + ')') to sParts
                    End
                End
                Else If (Health.eState = CI_BuildHealthNeverBuilt) ;
                    Increment iNever
                Else If (Health.eState = CI_BuildHealthExeOnly) Begin
                    // An exe with no listing beside it is not a build record - counted with the
                    // unexamined, and the OLDEST exe dates the disclaimer (Nils 2026-09-03).
                    Increment iExeOnly
                    If (iExeOnly = 1 or Health.dtWhen < dtOldestExe) ;
                        Move Health.dtWhen to dtOldestExe
                End
                Else ;
                    Increment iClean
            End
        Loop
    End_Procedure

    /* The sentence _OtherProjectsHealthHtml returns, assembled from the tally: the scope
       disclaimer tail for never-built projects, then either the all-clean wording (bOthersBad
       False) or the named-errors wording with its "and N more" / "N built clean" counts. Returns
       the String the caller returns. Split out 2026-09-02, verbatim. */
    Function _OtherProjectsSentence Boolean bOthersBad String sParts Integer iClean ;
                                    Integer iNever Integer iErrs Integer iNamed ;
                                    Integer iExeOnly String sOldestExe Returns String
        String sHtml sTail

        // The scope disclaimer, built once - it is the tail of every wording below that has
        // something unexamined to disclose. EXE-ONLY FIRST (Nils 2026-09-03): a program whose
        // only artifact is an exe read as "built clean on its last build" - 20 WinServ programs,
        // every one a 32-bit exe from 2021, in a DF26 migration that had never compiled one of
        // them. An exe says nothing about when or where it was built, so it is disclosed with
        // its age, never folded into the good news.
        Move "" to sTail
        If (iExeOnly = 1) ;
            Move (" One other program has an exe from " + sOldestExe + " but no build record here, so this Check says nothing about it.") to sTail
        If (iExeOnly > 1) ;
            Move (" " + String(iExeOnly) + " other programs have an exe but no build record here (the oldest from " + sOldestExe + "), so this Check says nothing about them.") to sTail
        If (iNever = 1) ;
            Move (sTail + " One other program has never been built here, so this Check says nothing about it.") to sTail
        If (iNever > 1) ;
            Move (sTail + " " + String(iNever) + " other programs have never been built here, so this Check says nothing about them.") to sTail

        If (bOthersBad = False) Begin
            If (iClean = 0) ;
                Function_Return (Trim(sTail))
            If (iClean = 1) ;
                Function_Return ("The workspace's other built program also built clean on its last build." + sTail)
            Function_Return ("The workspace's " + String(iClean) + " other built programs all built clean on their last builds." + sTail)
        End

        Move ("This Check compiled one program. Of the workspace's other program(s): " + sParts) to sHtml
        If (iErrs > iNamed) ;
            Move (sHtml + "; and " + String(iErrs - iNamed) + " more with errors on their last build") to sHtml
        If (iClean > 0) ;
            Move (sHtml + "; " + String(iClean) + " built clean") to sHtml
        Move (sHtml + ". Switch the main program and run Check again to cover them." + sTail) to sHtml
        Function_Return sHtml
    End_Function

    /* THE OTHER PROJECTS' LAST-BUILD TRUTH (Nils 2026-08-29). A Check
       compiles ONE program, and this board's verdict was worded as if it covered the workspace -
       "the compiler is clean" over two E 4539 in a program the Check had never compiled. This is
       the missing evidence, from each other project's own compile artifacts (ProjectBuildHealth,
       cCompileMixin).

       WHAT GETS NAMED IS WHAT IS WRONG (Nils 2026-08-30: "the grid is full ... and a very, very
       long list of *.src files"). The first cut named the never-built projects too, and on a
       134-project workspace that put 133 file names in one sentence. Two states, two treatments:

         - ERRORS on its last build - real, actionable, and the reason this function exists. NAMED,
           up to CI_OtherProjHealthNameCap of them, and the remainder is COUNTED with its own
           wording so the cap never reads as "that was all of them".
         - NEVER BUILT HERE - not a defect. A .sws project list accumulates every program the
           workspace has ever held, and on a large legacy one the normal state of nearly all of
           them is that this user has never compiled them on this machine. COUNTED, never named,
           and it no longer sets bOthersBad: telling somebody to "switch the main program and run
           Check again" 133 times is not advice. It stays in the sentence as a scope disclaimer,
           because unexamined still is not clean.

         - EXE ONLY (Nils 2026-09-03) - an exe with no .err and no .prn beside it. Not a build
           record: the exe may be years old and from another DataFlex (WinServ: 20 of them, all
           32-bit, all from 2021, and the sentence said "all built clean on their last builds").
           COUNTED with the oldest exe's month, never named, and it does not set bOthersBad
           either - it is unexamined, exactly like never-built.

       Demoting never-built does not weaken the incident that motivated this: that program had a
       .err with two errors on disk, so it is the ERRORS branch that catches it, not this one.

       ONE CALLER NOW - the Check verdict dialog (Nils 2026-08-30: "APAdjustLog.src is the selected
       program. This text should not clutter up the grid when another program is being
       compiled/analyzed"). The findings board stated it too, and there it was both redundant with
       its own header - which already scopes the list to the compiled program - and about a program
       the user is not working on. The dialog is where the question "is this workspace clean?" gets
       asked, so that is where the answer belongs, once.

       Returns "" when the workspace has no other projects; bOthersBad is True only when another
       project has ERRORS recorded on its last build. */
    // "November 2021" for a DateTime - the age of an exe, at the resolution a reader needs.
    Function _MonthYearText DateTime dt Returns String
        String[] asMonths
        Integer iMonth

        Move (StrSplitToArray("January,February,March,April,May,June,July,August,September,October,November,December", ",")) to asMonths
        Move (DateGetMonth(dt)) to iMonth
        If (iMonth < 1 or iMonth > 12) ;
            Function_Return (String(dt))
        Function_Return (asMonths[iMonth - 1] + " " + String(DateGetYear(dt)))
    End_Function

    Function _OtherProjectsHealthHtml Boolean ByRef bOthersBad Returns String
        String[] asProjects
        String sSWS sMain sParts sHtml sOldestExe
        Integer iDot iClean iNever iOthers iErrs iNamed iExeOnly
        DateTime dtOldestExe

        Move False to bOthersBad
        Get psSWSFile of ghoApplication to sSWS
        If (sSWS = "") ;
            Function_Return ""
        // On disk only (2026-09-23): a listed program whose file is gone is not "never built".
        Get WorkspaceProgramsOnDisk of ghoApplication sSWS to asProjects
        Get MainProgram of ghoApplication to sMain
        Move (Lowercase(Trim(sMain))) to sMain
        Move (Pos(".", sMain)) to iDot
        If (iDot > 1) ;
            Move (Left(sMain, (iDot - 1))) to sMain
        // Count the other projects by last-build state; name the ones with errors (capped).
        Send _TallyOtherProjects (&asProjects) sMain (&sParts) (&iClean) (&iNever) (&iOthers) (&iErrs) (&iNamed) (&bOthersBad) (&iExeOnly) (&dtOldestExe)
        If (iOthers = 0) ;
            Function_Return ""

        Move "" to sOldestExe
        If (iExeOnly > 0) ;
            Get _MonthYearText dtOldestExe to sOldestExe
        Get _OtherProjectsSentence bOthersBad sParts iClean iNever iErrs iNamed iExeOnly sOldestExe to sHtml
        Function_Return sHtml
    End_Function

    // Rebuilds the overriding-copies memo for the compiled scope sStamp (the memo miss of
    // _SysOverrideWarningHtml): stamps the memo, asks cShadowedPackageFiles for every copy this
    // workspace carries in front of a DataFlex system package, classified, and stores the rows
    // and the retired count in paSysOverride / piSysOverrideGone.
    // SYSTEM PACKAGES ONLY since 2026-10-05 (Nils, on the Rename dialog: "It is actually perfectly OK
    // with duplicate filenames, as long as they are not a DataFlex system package. Thus all other
    // 'duplicates' should be removed from the dialog"). cShadowedPackageFiles answers nothing else
    // any more, and the line, [Which files?] and the dialog are all rendered from this memo.
    Procedure _BuildSysOverrideMemo String sStamp
        Handle ho
        tShadowCopy[] aRows
        tWorkspacePaths TargetWS
        String sRetired sLanguage sInstallLanguage
        Integer iCount iGone

        Set psSysOverrideStamp to sStamp
        Set pbSysOverrideBuilt to True
        Move (ResizeArray(aRows, 0)) to aRows
        Move 0 to iGone
        Move "" to sRetired
        Move "" to sLanguage
        Move "" to sInstallLanguage
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho <> 0) Begin
            Get ShadowCopiesNow of ho (&aRows) (&iGone) to iCount
            // Its sentence is about what the build compiles now, so no listing, no line - like the rows.
            If (sStamp <> "") Begin
                Get pTargetWS of ghoApplication to TargetWS
                Get RetiredLanguageSettingNow of ho TargetWS.sOpenPath (&sLanguage) (&sInstallLanguage) to sRetired
            End
            Send Destroy of ho
        End
        Set paSysOverride     to aRows
        Set piSysOverrideGone to iGone
        Set psRetiredLanguageFile to sRetired
        Set psRetiredLanguage     to sLanguage
        Set psInstallLanguage     to sInstallLanguage
    End_Procedure

    /* The overriding-copies memo, current for the compiled scope: rebuilt only when the stamp moved.
       The line above the bands reads it, and since 2026-11-12 so do the rows of the "In packages"
       band (_FailingPackageCopyNote), which are built before that line is. */
    Procedure _EnsureSysOverrideMemo
        String sStamp

        Get CompiledScopeStamp to sStamp
        If (sStamp <> psSysOverrideStamp(Self) or pbSysOverrideBuilt(Self) = False) ;
            Send _BuildSysOverrideMemo sStamp
    End_Procedure

    /* THE "IN PACKAGES" ROW OF A PACKAGE THE WORKSPACE MAY BE BREAKING (2026-11-12). When this build
       compiled a workspace copy in place of one of sPackage's files (a row of kind
       eShadowFailingPackage, not kept), the row's advice - fix it where the package is maintained - is
       wrong until the copy is looked at, so the words returned here lead its hint. "" otherwise.
       sPackage is the band's display name, and the rows carry the same one (PoolPackageDisplayNameOf).
       Plain text: the hint goes through a tooltip builder that escapes. */
    Function _FailingPackageCopyNote String sPackage Returns String
        tShadowCopy[] aRows
        String sLeaves
        Integer i iLast iCount

        If (Trim(sPackage) = "") ;
            Function_Return ""
        Send _EnsureSysOverrideMemo
        Get paSysOverride to aRows
        Move 0 to iCount
        Move "" to sLeaves
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (aRows[i].eKind = eShadowFailingPackage and aRows[i].bKept = False) Begin
                If (Lowercase(Trim(aRows[i].sSource)) = Lowercase(Trim(sPackage))) Begin
                    Increment iCount
                    If (sLeaves <> "") ;
                        Move (sLeaves + ", ") to sLeaves
                    Move (sLeaves + aRows[i].sLeaf) to sLeaves
                End
            End
        Loop
        If (iCount = 0) ;
            Function_Return ""
        If (iCount = 1) ;
            Function_Return ("This build compiled the workspace's own " + sLeaves + " in place of this package's, and that may be what breaks it: rename the copy (Rename them... above) and compile again. ")
        Function_Return ("This build compiled the workspace's own " + sLeaves + " in place of this package's files, and that may be what breaks it: rename the copies (Rename them... above) and compile again. ")
    End_Function

    /* "…and this file exists N times under the workspace" - the sentence that turns a row about a
       warning into a row about the RIGHT COPY of the file, or "" when the file is unique.

       THE HONEST TRIGGER IS THE INTERSECTION. Shadowing on its own is a big, dull list - 36 files
       on the workspace this came from - and a board carrying all of it would be noise. What
       matters is a file the board is ALREADY telling you to look at which also has other copies:
       there, the shadow changes what the advice means, because the copy you edit may not be the
       copy that compiles. On that workspace the intersection was exactly ONE file - vWin32fh.pkg,
       7 messages, 8 copies - which is the whole point: one sentence, on the one row that needed it.

       The full picture stays in ShadowedPackageFilesReport for whoever wants the sweep. */
    /* THE WORKSPACE IS OVERRIDING DATAFLEX SYSTEM FILES - the loudest thing this board can say,
       and the one finding here that is never about the users own code.

       Nils, 2026-08-30, after a workspace lost a day to it: "such duplicates of DataFlex system
       files are very serious." They are, and the reason is where the damage SHOWS. A 1992
       errornum.inc in the applications own Pkg folder won over the installed one, took the include
       guard with it, and produced 573 errors - every single one reported against a DataFlex install
       file. Nothing pointed at the workspace. The last error in that build was an End_Object without
       Object, which read like a broken view in the application and was not.

       NOT FOLDED INTO A BAND, deliberately. Every band on this board groups findings by what you can
       DO about them; this one is a precondition - while it stands, the messages in those bands may
       be describing a DataFlex the compiler never actually read. So it sits above all of them, in
       the error colour, and it does not collapse.

       THE TRIGGER IS NARROW ON PURPOSE, and it was measured before it was written. Every workspace
       shares names with the install - 10 on one, 28 on another - so the test is not "same name". It
       is: the compiler ACTUALLY included your copy (read from the listing, not simulated), and that
       copy is in the workspaces own source rather than a package pool. On the workspace that has the
       bug that yields 10; on a healthy one whose libraries legitimately carry install names, 0. */
    Function _SysOverrideCopiesHtml Returns String
        tShadowCopy[] aRows
        String  sOut sNoun sLead sKeptChip sHead sFail sFailLeaf sPkgs
        Integer iLast iGone i iLive iDormant iInstall iKept iFail iFailErr

        // THE STAMP ONLY - the array this used to fetch was discarded a line later, and it is 2365
        // paths. See CompiledScopeStamp; in _ShadowNoteForFile, which runs per finding row, that
        // waste was the whole of a 131 s render.
        Send _EnsureSysOverrideMemo
        Get paSysOverride     to aRows
        Get piSysOverrideGone to iGone
        Move (SizeOfArray(aRows) - 1) to iLast
        /* NOTHING LIVE LEFT - BUT SAY WHY THE BOARD IS STALE (Nils 2026-08-31: "After pressing the
           button it renamed the file. But coming back to the dashboard, the line is still there in
           the grid. It should have been removed. If a new Check is needed, that should clearly have
           been said.") Both halves of that are answered here: the red line and its [Rename them] are
           gone the moment there is nothing left to rename, and what replaces it names the ONE action
           that makes the rest of the board true again. Deliberately NOT silence: this listing was
           produced by a compile that read the retired copies, so every finding under it may be
           describing a DataFlex the compiler never actually read - which is the whole reason this
           line sits above the bands. */
        If (iLast < 0) Begin
            If (iGone <= 0) ;
                Function_Return ""
            Move ("The " + String(iGone) + " overriding copies this build compiled are") to sNoun
            If (iGone = 1) ;
                Move "The overriding copy this build compiled is" to sNoun
            Function_Return ((DivOpen("fsysover")) ;
                + (BoldHtml(sNoun + " no longer in the workspace.")) ;
                + " These findings still come from that build - run " + (BoldHtml("Check")) ;
                + " to compile against the shipped files and rebuild the list." + CS_DivEnd)
        End
        /* ONE LINE AND A BUTTON (Nils 2026-08-30: "I see no point in cluttering the bigger part of
           the dashboard with warnings and file listings. Better would be a concise line explaining
           it and a button with a [Fix it] type of thing, that renames those offending local
           copies"). The four-sentence block and the file list moved out; what is left says the one
           thing the reader must know - the compiler read YOUR copy - and offers the fix.

           ONE KIND (2026-10-05): the copies of DataFlex system packages - the kind that breaks the
           build in files the reader does not own. From 2026-09-15 a second sentence counted the
           copies of files the workspace's LIBRARIES ship; they left the line with the memo (see
           _BuildSysOverrideMemo). The sentence keeps apart the copies this build compiled from the
           ones it did not read (Nils 2026-09-13), or the reader either panics over a dormant file or
           shrugs at a live override. The counts are what has to be legible every time the board
           renders; the names stay behind [Which files?]. */
        Move 0 to iLive
        Move 0 to iDormant
        Move 0 to iKept
        Move 0 to iFail
        Move 0 to iFailErr
        Move "" to sFailLeaf
        Move "" to sPkgs
        For i from 0 to iLast
            /* A COPY THE USER DECIDED TO KEEP (2026-09-15) is out of the sentence and the dialog -
               it still shadows, and the report still names it, but the user has judged it, and
               a line that keeps counting it is the "button that sticks" Nils reported. It is
               counted into a chip of its own instead, which is also the way back. */
            If (aRows[i].bKept = True) Begin
                Increment iKept
            End
            Else If (aRows[i].eKind = eShadowInstall) Begin
                If (aRows[i].iClass = 0) ;
                    Increment iLive
                Else ;
                    Increment iDormant
            End
            // a copy compiled in place of the file of a package that fails in this build (2026-11-12)
            Else If (aRows[i].eKind = eShadowFailingPackage) Begin
                Increment iFail
                Move aRows[i].sLeaf to sFailLeaf
                Move aRows[i].iPackageErrors to iFailErr
                If (not((", " + sPkgs + ",") contains (", " + aRows[i].sSource + ","))) Begin
                    If (sPkgs <> "") ;
                        Move (sPkgs + ", ") to sPkgs
                    Move (sPkgs + aRows[i].sSource) to sPkgs
                End
            End
        Loop
        Move (iLive + iDormant) to iInstall
        Move "" to sKeptChip
        If (iKept > 0) ;
            Move (" " + (ChipHtml("fact alt", "fact alt off", "unkeepshadow", "", ;
                (String(iKept) + " kept"), ;
                "Copies you decided to keep as forks. They still shadow the shipped file, and the report still names them. Offer them again.", ;
                True))) to sKeptChip
        // EVERYTHING KEPT: no red sentence, no Rename - just the record and its way back. The line
        // stays visible at all because the copies still shadow; silence would read as "fixed".
        If (iInstall + iFail = 0) ;
            Function_Return ((DivOpen("fsysover")) ;
                + "The " + String(iKept) + " overriding cop" + (If(iKept = 1, "y", "ies")) ;
                + " this workspace carries " + (If(iKept = 1, "is", "are")) + " kept by your decision." ;
                + sKeptChip + CS_DivEnd)
        Move "" to sLead
        /* "The workspace contains copies of 14 DataFlex system packages:", never "Your own copies of
           ..." (Nils 2026-10-05). The person at the screen is often a consultant on somebody else's
           codebase, or the copies went in twenty years ago - and "packages" is his word for them. */
        If (iInstall > 0) Begin
            // "1 file(s)" reads like a placeholder once the count is actually 1 - and it is 1 as
            // soon as the user retires the rest, which is exactly when they read it most carefully.
            Move ("The workspace contains copies of " + String(iInstall) + " DataFlex system packages") to sHead
            If (iInstall = 1) ;
                Move "The workspace contains a copy of 1 DataFlex system package" to sHead
            If (iDormant = 0) ;
                Move ((BoldHtml(sHead + " ")) ;
                    + "that this build compiled in place of the installed " + (If(iInstall = 1, "one.", "ones."))) to sLead
            Else If (iLive = 0) ;
                Move ((BoldHtml(sHead + " ")) ;
                    + "that this build did not read - " + (If(iInstall = 1, "it", "each")) + " compiles nothing today and wins the day the compiler reaches it.") to sLead
            Else ;
                Move ((BoldHtml(sHead + ": ")) ;
                    + String(iLive) + " compiled by this build in place of the installed ones, " ;
                    + String(iDormant) + " more it did not read.") to sLead
        End
        /* THE SECOND KIND, ITS OWN SENTENCE (2026-11-12): a copy compiled in place of the file of a
           package that has errors in this build. It is no DataFlex system package, and what earns it the
           line is the package's errors, which the "In packages" band lists and could not explain. "May":
           the package can fail for reasons of its own (cShadowedPackageFiles.FailingPackageCopies). */
        If (iFail > 0) Begin
            If (iFail = 1) ;
                Move ((BoldHtml("This build compiled the workspace's own " + (HtmlEscaped(Self, sFailLeaf)) + " in place of " + (HtmlEscaped(Self, sPkgs)) + "'s,")) ;
                    + " and " + (HtmlEscaped(Self, sPkgs)) + " has " + String(iFailErr) + (If(iFailErr = 1, " error", " errors")) ;
                    + " in this build " + CS_EmDash + " the copy may be what breaks it.") to sFail
            Else ;
                Move ((BoldHtml("This build compiled " + String(iFail) + " of the workspace's own files in place of package files of the same names")) ;
                    + " (" + (HtmlEscaped(Self, sPkgs)) + "), and those packages have errors in this build " + CS_EmDash + " the copies may be what breaks them.") to sFail
            If (sLead <> "") ;
                Move (sLead + " " + sFail) to sLead
            Else ;
                Move sFail to sLead
        End
        /* "WHICH FILES?" IS A CHIP, NOT A TOOLTIP (Nils 2026-08-30: "the 'Which files?' looks like it
           needs a linkage to a e.g. a dialog that lists the files?"). It opens the list, with the
           full path of each copy and the file it stands in front of. "Rename them..." opens the
           per-file dialog - the ellipsis says a choice follows, not an action. */
        Move ((DivOpen("fsysover")) ;
            + sLead + " " ;
            + (ChipHtml("fact alt", "fact alt off", "showshadow", "", "Which files?", ;
                     "List the copies: the file each one stands in front of, whether this build read it, and whether the two are identical.", True)) ;
            + " " + (ChipHtml("fact", "fact off", "fixshadow", "", "Rename them...", ;
                     "Choose which of these copies to rename to <name>.shadowed so the shipped " ;
                     + "version is used instead - identical copies come ticked, and so do copies that differ but add nothing the workspace uses; the rest do not. " ;
                     + "Reversible - Revert, or rename back. The build must be run again afterwards for it to take effect.", True)) ;
            + sKeptChip + CS_DivEnd) to sOut
        Function_Return sOut
    End_Function

    /* A LANGUAGE SETTING THE RENAME TOOK AWAY, offered back (Nils 2026-11-05). Its own line, because
       it is not an overriding copy: nothing stands in front of anything, the build is clean, and the
       only sign is that DataFlex's own texts changed language. When it shows is decided in
       cShadowedPackageFiles.RetiredLanguageSettingIn. Two answers, so the line never sticks: only
       the first moves a file, and the second is recorded like any other Keep. */
    Function _RetiredLanguageHtml Returns String
        String sRetired sLanguage sInstall

        Get psRetiredLanguageFile to sRetired
        If (sRetired = "") ;
            Function_Return ""
        Get psRetiredLanguage to sLanguage
        Get psInstallLanguage to sInstall
        Function_Return ((DivOpen("fsysover")) ;
            + (BoldHtml("A language setting was renamed away. ")) ;
            + (HtmlEscaped(Self, ExtractFileName(sRetired))) + " picks " + (HtmlEscaped(Self, sLanguage)) ;
            + ", so DataFlex's own texts now compile in " + (HtmlEscaped(Self, sInstall)) + ". " ;
            + (ChipHtml("fact", "fact off", "restorelang", "", "Rename it back...", ;
                ("Rename it back to " + CS_LanguageSettingFile + ", so the next build compiles those texts in " + sLanguage + " again."), True)) ;
            + " " + (ChipHtml("fact alt", "fact alt off", "keeplang", "", ("Stay in " + sInstall), ;
                ("Keep " + sInstall + " and stop showing this line. The file stays where it is."), True)) ;
            + CS_DivEnd)
    End_Function

    // What stands above the bands: the overriding copies, then a retired language setting. The first
    // builds the memo the second reads, hence two Gets in this order.
    Function _SysOverrideWarningHtml Returns String
        String sCopies sLanguage

        Get _SysOverrideCopiesHtml to sCopies
        Get _RetiredLanguageHtml to sLanguage
        Function_Return (sCopies + sLanguage)
    End_Function


    /* The index behind _ShadowNoteForFile: every file name the current listing compiled, and the
       path(s) compiled under each (CompiledLeafIndex), rebuilt when the compile stamp moves. It is
       built from CompiledScopeFiles - the list the analyzer's scoped actions already read and cache -
       so it costs one pass over that per listing and no folder walk at all; the count it replaces
       walked every source file under the home to tally names. Keyed on the listing stamp AND the
       workspace home - see the property block. No listing: EMPTY, and no row gets a note without a
       build behind it. */
    Procedure _EnsureShadowMemo
        String[] asCompiled asLeaf asBuilt
        String sStamp sKey sHome sProgram

        // THE STAMP FIRST - CompiledScopeFiles is asked only when it has moved. Fetching arrays per
        // row was the whole of a 131 s render once; see CompiledScopeStamp.
        Get CompiledScopeStamp to sStamp
        Get psHomeTarget of ghoApplication to sHome
        Move (Trim(sHome)) to sHome
        Move (sStamp + "|" + Lowercase(sHome)) to sKey
        If (sKey = psShadowMemoStamp(Self)) ;
            Procedure_Return
        Set psShadowMemoStamp to sKey
        Move "" to sProgram
        If (sStamp <> "") Begin
            Get CompiledScopeFiles to asCompiled
            Move (CompiledLeafIndex(asCompiled, &asBuilt)) to asLeaf
            // The stamp's first field is the listing itself: "<path>.prn|size|date".
            Move (ProgramOfListing(Left(sStamp, (Pos("|", sStamp) - 1)))) to sProgram
        End
        Set pasShadowLeaf   to asLeaf
        Set pasShadowBuilt  to asBuilt
        Set psShadowProgram to sProgram
    End_Procedure

    /* THE NOTE ON A FINDING ROW WHOSE FILE THE BUILD DID NOT COMPILE (Nils 2026-09-11).

       It used to print "N copies of this file exist here; the build uses THIS one" on every row whose
       FILE NAME occurred more than once under the home. Nils: "It is the '2 copies of this file
       exist here...' that is very confusing". On the row he read, the other copy sat in a
       language-variant folder no build searches, nothing said where it was, and "THIS one" was never
       checked - a row about that other copy would have printed the same sentence, falsely. This
       comment carried that as a KNOWN GAP for Deep Scan rows.

       Now it is decided from the listing, per row: the copy the build compiled gets NO note - the row
       already sends the reader to the right file; a DIFFERENT file of a name the build compiled gets
       "Main.src compiles AppSrc\Helpers.pkg, not this copy." - the one case where the reader is about
       to edit something the compiler never reads; anything else, nothing. A Deep Scan row is judged
       by the same listing as a compiler row, which closes the gap.

       SHORT, PLAIN TEXT, AND IT LEADS THE HINT. The hint cell ellipsizes, and if you are about to
       edit the wrong copy of a file, that outranks anything else the row says. No CS_EmDash here -
       this goes through a tooltip builder that escapes its input.

       THE DISK IS NOW. The listing is history: a compiled copy that has since left the disk - renamed
       by a retire, say - is not named. */
    Procedure _ShadowNoteForFile String sFile tFindingsCtx ByRef Ctx String ByRef sNote
        String sBuilt sHome
        Integer iAt

        Move "" to sNote
        Move (Trim(sFile)) to sFile
        If (sFile = "") ;
            Procedure_Return
        // ONCE PER RENDER - the stamp check and one copy of the index into Ctx. This runs per
        // finding row, and a property Get copies the whole array every time it is asked.
        If (Ctx.bShadowLoaded = False) Begin
            Send _EnsureShadowMemo
            Get pasShadowLeaf   to Ctx.asShadowLeaf
            Get pasShadowBuilt  to Ctx.asShadowBuilt
            Get psShadowProgram to Ctx.sShadowProgram
            Move True to Ctx.bShadowLoaded
        End
        Move (BinarySearchArray(FileLeafLower(sFile), Ctx.asShadowLeaf)) to iAt
        If (iAt = -1) ;
            Procedure_Return
        Move (CompiledCopyFor(sFile, Ctx.asShadowBuilt[iAt])) to sBuilt
        If (sBuilt = "") ;
            Procedure_Return
        If (vFilePathExists(sBuilt) = 0) ;
            Procedure_Return
        Get psHomeTarget of ghoApplication to sHome
        Move (CompiledElsewhereNote(Ctx.sShadowProgram, sBuilt, sHome)) to sNote
    End_Procedure

    /* Where the workspace's own code pulls in an install package a 4536 flagged as obsolete -
       "file|line" of the first 'Use <package>' in the compiled scope's workspace files, "" when
       none is found. Only files under the workspace home are read (24 KB heads, the
       cause-attribution budget), never the DataFlex install or the DfPkg pool - the Use we can
       point the user at has to be one they can edit.

       ONE PASS FOR EVERY PACKAGE (2026-09-02). Until today this was a sweep PER PACKAGE: for each
       4536 leaf, head-read the workspace files in compiled order until one Used it - and a package
       no workspace file Uses (8 of WinServ's 19) read all 1976 heads for nothing, every line paying
       UseLineForPackage's per-character word walk. The 08-31 regression (b5bd01d) had silenced the
       sweep by emptying its file list; fixing that brought the cost back: "Check: building the
       findings list" took 124 s (Nils 2026-09-02). Now the heads are read ONCE, every Use line in
       them goes into the index (UseLinesInHead spares the word walk for any line that cannot be a
       Use), and each 4536 row is a lookup. First file in compiled order wins, and within a file the
       first Use line - exactly the answer the sweep gave. Stamped in _UseSiteForPackage, which is
       the only caller; the property block at the top holds the arrays. */
    Procedure _BuildUseSiteIndex Handle hoAn
        String[]  asFiles asLines asKeys asVals asLeafs
        Integer[] aiLines
        String    sHome
        Integer   i iMax j jMax

        Get psHomeTarget of ghoApplication to sHome
        Move (Lowercase(vFolderFormat(sHome))) to sHome
        If (sHome <> "") ;
            Get CompiledScopeFiles to asFiles
        Move (SizeOfArray(asFiles) - 1) to iMax
        For i from 0 to iMax
            If (Left(Lowercase(asFiles[i]), Length(sHome)) = sHome and (not(Lowercase(asFiles[i]) contains "\dfpkg\"))) Begin
                Move (rfReadEncodedFileHead(asFiles[i], 24576)) to asLines
                Send UseLinesInHead of hoAn (&asLines) (&asLeafs) (&aiLines)
                Move (SizeOfArray(asLeafs) - 1) to jMax
                For j from 0 to jMax
                    If (SearchArray(asLeafs[j], asKeys) = -1) Begin
                        Move asLeafs[j] to asKeys[-1]
                        Move (asFiles[i] + "|" + String(aiLines[j])) to asVals[-1]
                    End
                Loop
            End
        Loop
        Set pasUseSiteMemoKey to asKeys
        Set pasUseSiteMemoVal to asVals
    End_Procedure

    Procedure _UseSiteForPackage String sPkgFile tFindingsCtx ByRef Ctx String ByRef sSite
        String sKey sStamp
        Integer iAt

        Move "" to sSite
        If (Ctx.hoCall = 0) ;
            Procedure_Return
        Get UsePackageBase of Ctx.hoCall (ExtractFileName(sPkgFile)) to sKey
        If (sKey = "") ;
            Procedure_Return
        /* ONCE PER RENDER: the stamp check, the build if the compile changed, and ONE copy of the
           two arrays into Ctx. A property Get copies the whole array, and the index is one entry
           per distinct Use target in the workspace (~1000 on WinServ) - per row, that copy would
           be the 131 s render's shape in miniature. */
        If (Ctx.bUseLoaded = False) Begin
            Get CompiledScopeStamp to sStamp           // the stamp only - see CompiledScopeStamp
            If (sStamp <> psUseSiteMemoStamp(Self)) Begin
                Set psUseSiteMemoStamp to sStamp
                Send _BuildUseSiteIndex Ctx.hoCall
            End
            Get pasUseSiteMemoKey to Ctx.asUseKey
            Get pasUseSiteMemoVal to Ctx.asUseVal
            Move True to Ctx.bUseLoaded
        End
        Move (SearchArray(sKey, Ctx.asUseKey)) to iAt
        If (iAt <> -1) ;
            Move Ctx.asUseVal[iAt] to sSite
    End_Procedure

    // Finds the outside-band group of the write-protected row aRows[i] (sLeaf is its file's
    // leaf name) - keyed "pkg|<name>" on the pool package's display name when Ctx.hoCall knows
    // one, else on the lowercased file path - and creates the slot in the Ctx.*Out* arrays when
    // the group is new. Hands the group index back in iAt.
    Procedure _OutsideGroupSlot tSavedPlanRow[] ByRef aRows Integer i String sLeaf tFindingsCtx ByRef Ctx Integer ByRef iAt
        String sName sKey

        Get PoolPackageDisplayName of Ctx.hoCall aRows[i].sFile to sName
        If (sName <> "") ;
            Move ("pkg|" + Lowercase(sName)) to sKey
        Else Begin
            Move sLeaf to sName
            Move (Lowercase(aRows[i].sFile)) to sKey
        End
        Move (SearchArray(sKey, Ctx.asOutKey)) to iAt
        If (iAt = -1) Begin
            Move (SizeOfArray(Ctx.asOutKey)) to iAt
            Move sKey            to Ctx.asOutKey[iAt]
            Move sName           to Ctx.asOutName[iAt]
            Move aRows[i].sFile  to Ctx.asOutFile[iAt]
            Move aRows[i].iLine  to Ctx.aiOutLine[iAt]
            Move 0               to Ctx.aiOutErr[iAt]
            Move 0               to Ctx.aiOutWarn[iAt]
            Move 0               to Ctx.aiOutScan[iAt]
            Move sLeaf           to Ctx.asOutLeaf[iAt]
            Move ""              to Ctx.asOutSeen[iAt]
            Move 0               to Ctx.aiOutFiles[iAt]
            Move (sLeaf + ' (' + aRows[i].sLineDisplay + ') ' + aRows[i].sMsg) to Ctx.asOutSample[iAt]
        End
    End_Procedure

    // The write-protected branch of _CollectOutsideRow: aggregates the pool-package row
    // aRows[i] (sLeaf is its file's leaf name) into its outside-band group in Ctx - one count
    // per distinct finding, the scan lane apart from the warnings, an error taking over as the
    // group's face. Every path counts the row in Ctx.iSysListed.
    Procedure _CollectPoolPackageRow tSavedPlanRow[] ByRef aRows Integer i String sLeaf tFindingsCtx ByRef Ctx
        String sRowKey
        Integer iAt iOcc
        Boolean bErr bFirstErr

        Send _OutsideGroupSlot (&aRows) i sLeaf (&Ctx) (&iAt)
        /* ONE FINDING, however many converters might fix it. A message matching several
           function-bearing recipes produces one row per candidate, each carrying the SAME
           occurrence count - and a System row has its function stripped, so the duplicates are
           not even distinguishable on screen. Counted before the tallies below, and counted
           once. */
        Move (Lowercase(Trim(aRows[i].sFile)) + '|' + Trim(aRows[i].sMsg) + '|' + Trim(aRows[i].sLineDisplay)) to sRowKey
        If (SearchArray(sRowKey, Ctx.asOutRowKey) <> -1) Begin
            Increment Ctx.iSysListed
            Procedure_Return
        End
        Move sRowKey to Ctx.asOutRowKey[-1]
        // Distinct FILES in this package, so the row can name the one file when there is one.
        If (not(Ctx.asOutSeen[iAt] contains ('|' + Lowercase(sLeaf) + '|'))) Begin
            Move (Ctx.asOutSeen[iAt] + '|' + Lowercase(sLeaf) + '|') to Ctx.asOutSeen[iAt]
            Increment Ctx.aiOutFiles[iAt]
        End
        // COUNT MESSAGES, NOT ROWS. A folded row carries "(xN)" in its line cell and speaks for
        // N findings; counting rows reported 2 where the package held 7.
        Get OccurrencesFromLineCell of Ctx.hoCall aRows[i].sLineDisplay to iOcc
        /* THE SCAN LANE IS COUNTED APART, never folded into the warnings. Both lanes see the
           same construct: the compiler's W 4534 and DS 9207 fire on every ToANSI call alike,
           so summing them reported 14 over a file holding 7 lines. */
        If (aRows[i].sMsg contains "DS ") Begin
            Move (Ctx.aiOutScan[iAt] + iOcc) to Ctx.aiOutScan[iAt]
            Increment Ctx.iSysListed
            Procedure_Return
        End
        Move (aRows[i].sMsg contains "E ") to bErr
        If (bErr = True) Begin
            // Tested BEFORE the add: the tally now grows by the row's occurrence count, so
            // "is this the first error" can no longer be read off the total being 1.
            Move (Ctx.aiOutErr[iAt] = 0) to bFirstErr
            Move (Ctx.aiOutErr[iAt] + iOcc) to Ctx.aiOutErr[iAt]
            Move (Ctx.iOutsideErr + iOcc) to Ctx.iOutsideErr
            // An ERROR outranks a warning as the group's face: jump target, sample and the
            // named file all follow it.
            If (bFirstErr = True) Begin
                Move aRows[i].sFile to Ctx.asOutFile[iAt]
                Move aRows[i].iLine to Ctx.aiOutLine[iAt]
                Move sLeaf          to Ctx.asOutLeaf[iAt]
                Move (sLeaf + ' (' + aRows[i].sLineDisplay + ') ' + aRows[i].sMsg) to Ctx.asOutSample[iAt]
            End
        End
        Else ;
            Move (Ctx.aiOutWarn[iAt] + iOcc) to Ctx.aiOutWarn[iAt]
        Increment Ctx.iSysListed
    End_Procedure

    /* ONE System (read-only) row, routed instead of skipped (Nils 2026-08-29, the
       "Yikes": pool-package ERRORS, pool warnings and an install 4536 were all invisible here -
       counted in a header chip nobody reads while the verdict said clean).

         - A file under the workspace roots that is write-protected (a DfPkg checkout, the df-cli
           package cache, a VCS read-only copy) is AGGREGATED per package into the outside band's
           arrays - rendered by _OutsideRowsHtml after the loop.
         - An install 4536 (the package deprecating ITSELF, reported at its own line 1) is
           re-pointed at the workspace's own Use line and listed as a Review row - the one place
           the user can act. Unmapped (no Use found in the workspace's own files - it is pulled in
           indirectly), it stays a chip-only set-aside, as does every other install-file row
           (Nils 2026-07-28: no point listing DataFlex's own packages). */
    Procedure _CollectOutsideRow tSavedPlanRow[] ByRef aRows Integer i String sCompBadge tFindingsCtx ByRef Ctx
        String sLeaf sSite sUseFile sRow sClass sSuper sHint
        Integer iPos iUseLine iGrp iClassLine
        Boolean bSub bOnBoard

        Move (ExtractFileName(aRows[i].sFile)) to sLeaf
        If (Ctx.hoCall = 0) ;
            Get Create (RefClass(cModAnalyzer)) to Ctx.hoCall
        If (aRows[i].sHint contains "Write-protected") Begin
            Send _CollectPoolPackageRow (&aRows) i sLeaf (&Ctx)
            Procedure_Return
        End
        // Outside the workspace roots: DataFlex's own install (or an external include).
        If (aRows[i].sMsg contains "4536") Begin
            Send _UseSiteForPackage sLeaf (&Ctx) (&sSite)
            If (sSite <> "") Begin
                Move (Pos("|", sSite)) to iPos
                Move (Left(sSite, (iPos - 1)))               to sUseFile
                Move (Mid(sSite, (Length(sSite)), (iPos + 1))) to iUseLine
                /* ...UNLESS THE USE IS THERE FOR A SUBCLASS (Nils 2026-10-04: "Its kind of pointless to
                   list this line: Use Dftable.pkg from the MyDbGrid.pkg, which is a sub-class of
                   DbGrid."). There is nothing to check then: the file's own class is built on a class
                   the package declares, and the Use goes only when that class is ported - hand work,
                   in the hand band, with the way on in its hint. Every other obsolete package stays
                   the Review row below. */
                Get PackageKeptBySubclass of Ctx.hoCall aRows[i].sFile sUseFile (&sClass) (&sSuper) (&iClassLine) to bSub
                If (bSub = True) Begin
                    /* ...and when the subclass HAS a row of its own - the Deep Scan's subclass row on its class
                       line (DS 9198 dbGrid subclass, DS 9200 dbList subclass) - the package row is not listed at
                       all: that row already sends the user to the port, and the port takes the Use with it (Nils,
                       the Check after: "the MyDbGrid.pkg and MyDbList.pkg are still listed two times"). Counted as
                       listed, like a row folded into another. A subclass with no row of its own - MyPrintDialog,
                       AmcMapiHandler: no scan rule knows their classes - keeps the hand row below. */
                    Get SavedPlanHasRowAt of Ctx.hoCall (&aRows) sUseFile iClassLine to bOnBoard
                    If (bOnBoard = True) Begin
                        Increment Ctx.iSysListed
                        Procedure_Return
                    End
                    Get SubclassKeptPackageHint of Ctx.hoCall sLeaf (ExtractFileName(sUseFile)) sClass sSuper to sHint
                    Move ((ClickableHtml("div", "fnd", "opensrc", (sUseFile + '|' + String(iUseLine)), ;
                        (((SpanOpen("fdot w")) + CS_SpanEnd) + sCompBadge + (FindingMsg("W 4536")) ;
                        + (SpanOpen("ffile")) + (HtmlEscaped(Self, sLeaf)) + CS_SpanEnd ;
                        + (HintCell(Self, HtmlEscaped(Self, sHint)))), ;
                        (HtmlEscaped(Self, sUseFile))))) to sRow
                    Send _RouteHandPkgRow sLeaf sHint sRow (&Ctx)
                    Increment Ctx.iSysListed
                    Procedure_Return
                End
                /* OBSOLETE DOES NOT MEAN UNUSED (Nils 2026-08-30, correcting the premise this
                   row was built on): an install package DataFlex marks obsolete can still be
                   the only declarer of fully-supported functions - MapiDllCalls.pkg carries
                   External_Function ShellExecute, still very much allowed and widely used. So
                   the hint points at the Use line and asks for a CHECK, never for a removal -
                   what the file consumes from the package decides (the 543-error rule: never
                   remove what the file calls). */
                Move ((ClickableHtml("div", "fnd", "opensrc", (sUseFile + '|' + String(iUseLine)), ;
                    (((SpanOpen("fdot w")) + CS_SpanEnd) + sCompBadge + (FindingMsg("W 4536")) ;
                    + (SpanOpen("ffile")) + (HtmlEscaped(Self, sLeaf)) + CS_SpanEnd ;
                    + (HintCell(Self, 'Obsolete does not always mean unused: the package may still be the only declarer of supported functions (MapiDllCalls.pkg still carries ShellExecute). Opens the Use line at ' + (ExtractFileName(sUseFile)) + ' (' + String(iUseLine) + ') ' + CS_EmDash + ' check what the file actually uses from the package before changing anything.'))), ;
                    (HtmlEscaped(Self, sUseFile))))) to sRow
                /* DISMISSABLE, because nothing else will ever clear it. This row asks for a
                   judgement - check what your file uses from the package - and a judgement leaves
                   no trace in the source, so the next Check raises it again, and the next
                   (Nils 2026-08-30: "there is no offer to ignore it, so the line just keeps
                   appearing"). It has no converter to be dismissed BY, which is why the
                   function-keyed tally skipped it; the PACKAGE is the thing the user recognises
                   and decides about, so the package name is the group. */
                Get TallyDismissable (&Ctx.asRevPkgKey) (&Ctx.aiRevPkgCount) (&Ctx.asRevPkgHint) sLeaf ;
                    'Obsolete package in the DataFlex install. Dismiss it once you have checked what this workspace actually uses from it - the warning cannot clear itself.' to iGrp
                // Create the slot before reading it: a brand-new group's element does not exist yet.
                If (iGrp >= 0 and iGrp >= SizeOfArray(Ctx.asRevPkgRows)) ;
                    Move "" to Ctx.asRevPkgRows[iGrp]
                If (iGrp >= 0) ;
                    Move (Ctx.asRevPkgRows[iGrp] + sRow) to Ctx.asRevPkgRows[iGrp]
                Else ;
                    Move (Ctx.sReview + sRow) to Ctx.sReview
                Increment Ctx.iReview
                Increment Ctx.iReviewPkg
                Increment Ctx.iSysListed
                If (Ctx.sPeekReview = "") ;
                    Move ('W 4536 ' + (HtmlEscaped(Self, sLeaf))) to Ctx.sPeekReview
            End
        End
    End_Procedure

    // ONE row of the outside band, for the group iGrp that _CollectOutsideRow aggregated
    // (bErrRow: the group carries errors): each lane's count, the package - or its one file -
    // as the label, the hint led by the shadow note; appended to Ctx.sOutside and counted in
    // Ctx.iOutside, and the first row seeds Ctx.sPeekOutside.
    Procedure _OutsideGroupRowHtml tFindingsCtx ByRef Ctx Integer iGrp Boolean bErrRow
        String sCounts sHint sRow sWhere sShadow sCopyNote

        // EACH LANE STATED, no total: a compiler warning and a scan finding on the
        // same line are one problem, and adding them claims two.
        Move "" to sCounts
        If (Ctx.aiOutErr[iGrp] > 0) ;
            Move (String(Ctx.aiOutErr[iGrp]) + ' error(s)') to sCounts
        If (Ctx.aiOutWarn[iGrp] > 0) Begin
            If (sCounts <> "") ;
                Move (sCounts + ', ') to sCounts
            Move (sCounts + String(Ctx.aiOutWarn[iGrp]) + ' warning(s)') to sCounts
        End
        If (Ctx.aiOutScan[iGrp] > 0) Begin
            If (sCounts <> "") ;
                Move (sCounts + ', ') to sCounts
            Move (sCounts + String(Ctx.aiOutScan[iGrp]) + ' scan finding(s)') to sCounts
        End
        /* NAME THE FILE, not just the package. The package is the unit of ACTION - it
           is what gets updated or vendored - but it is not what the reader is looking
           at, and when a package has exactly one offending file, printing only the
           package hides the very answer (Nils 2026-08-30: "the file is inside the
           VDFQuery20 package and the name is vWin32fh.pkg"). One file gets named;
           several get counted, because a list of eight leaves is not a row. */
        /* ESCAPED IN PIECES, because CS_EmDash IS MARKUP. It is the "&mdash;" entity,
           so running the finished label through HtmlEscaped turned its "&" into
           "&amp;" and the row printed the entity as text (Nils 2026-08-30). The names
           are data and must be escaped; the separator is markup and must not be. Same
           rule the row's other cells already follow - the escaping decision belongs
           where the value comes from. */
        If (Ctx.aiOutFiles[iGrp] > 1) ;
            Move ((HtmlEscaped(Self, Ctx.asOutName[iGrp])) + ' ' + CS_EmDash + ' ' + String(Ctx.aiOutFiles[iGrp]) + ' files') to sWhere
        Else If (Trim(Ctx.asOutLeaf[iGrp]) <> "" and Lowercase(Trim(Ctx.asOutLeaf[iGrp])) <> Lowercase(Trim(Ctx.asOutName[iGrp]))) ;
            Move ((HtmlEscaped(Self, Ctx.asOutName[iGrp])) + ' ' + CS_EmDash + ' ' + (HtmlEscaped(Self, Ctx.asOutLeaf[iGrp]))) to sWhere
        Else ;
            Move (HtmlEscaped(Self, Ctx.asOutName[iGrp])) to sWhere
        /* SHORT ENOUGH TO READ IN THE CELL. The old wording said "Read-only package
           FILES" of a row about one named file, then repeated that file, its line and
           its message as "Opens vwin32fh.pkg (256  (x7)) W 4534" - nested parentheses
           and a third repeat of what the row already shows in its own cells. It read
           as unclear and it pushed everything after it off the edge (Nils 2026-08-30).
           The row names the file and the counts; the hint says what to DO. */
        /* "UPSTREAM" AND "VENDOR" ARE NOT INSTRUCTIONS (Nils 2026-08-30: "can we change
           the text 'fix it upstream' - what does it mean?"). They are borrowed
           packaging jargon, and this row is read by someone who wants to know what to
           DO about a file they cannot edit. Say the two facts instead: an edit here
           does not survive, and the place it does survive is wherever the package is
           maintained.

           Deliberately NOT suggesting "copy it into your own AppSrc" any more. It is a
           real option, but it is also exactly how a workspace acquires the duplicate
           copies the first half of this very hint is warning about - so it belongs in
           the Shadowed package files report, which lists all three routes with their
           consequences, not in one line of advice. */
        If (bErrRow = True) ;
            Move ('Breaks the build from inside a read-only package. Fix it where the package is maintained, then update to a newer version.') to sHint
        Else ;
            Move ('Not fixable here - an edit is undone by the next package update. Fix it where the package is maintained, then update to a newer version.') to sHint
        // "Fix it upstream" is only right while this IS the copy in play. Where the
        // same file sits elsewhere too, that advice can send someone to edit a
        // package that never compiles - so the row says so FIRST.
        Send _ShadowNoteForFile Ctx.asOutFile[iGrp] (&Ctx) (&sShadow)
        If (sShadow <> "") ;
            Move (sShadow + sHint) to sHint
        // A workspace copy of one of this package's files compiled in its place leads the hint
        // (2026-11-12): while it stands, the package may be failing because of it.
        Get _FailingPackageCopyNote Ctx.asOutName[iGrp] to sCopyNote
        If (sCopyNote <> "") ;
            Move (sCopyNote + sHint) to sHint
        /* The hint below carries its OWN tooltip (TagTipText, not FindingHint). The
           row's title is the file PATH, so hovering a clipped hint showed the path and
           never the words that were clipped - "the tooltip only shows the full path to
           the file". An inner title wins over the row's for the element under the
           pointer, and the ordinary finding rows have always done it this way. */
        Move ((ClickableHtml("div", "fnd", "opensrc", (Ctx.asOutFile[iGrp] + '|' + String(Ctx.aiOutLine[iGrp])), ;
            (((SpanOpen("fdot " + (If(bErrRow, "e", "w")))) + CS_SpanEnd) ;
            + (FindingBadge("package")) ;
            + (SpanOpen("ffile")) + sWhere + CS_SpanEnd ;
            + (FindingMsg(sCounts)) ;
            + (TagTipText("span", "fhint", sHint, sHint))), ;
            (HtmlEscaped(Self, Ctx.asOutFile[iGrp]))))) to sRow
        Move (Ctx.sOutside + sRow) to Ctx.sOutside
        Increment Ctx.iOutside
        If (Ctx.sPeekOutside = "") ;
            Move ((HtmlEscaped(Self, Ctx.asOutName[iGrp])) + ' ' + CS_EmDash + ' ' + sCounts) to Ctx.sPeekOutside
    End_Procedure

    // The outside band's rows, from the groups _CollectOutsideRow aggregated: error-carrying
    // packages first (they BREAK the build the board just analyzed), warning-only after. Each row
    // opens the group's first flagged line - read-only in fact, but seeing the line is how the
    // upstream fix starts.
    Procedure _OutsideRowsHtml tFindingsCtx ByRef Ctx
        Integer iPass iGrp iMax
        Boolean bErrRow

        Move (SizeOfArray(Ctx.asOutKey) - 1) to iMax
        For iPass from 0 to 1
            For iGrp from 0 to iMax
                Move (Ctx.aiOutErr[iGrp] > 0) to bErrRow
                If ((iPass = 0 and bErrRow = True) or (iPass = 1 and bErrRow = False)) Begin
                    Send _OutsideGroupRowHtml (&Ctx) iGrp bErrRow
                End
            Loop
        Loop
    End_Procedure

    /* ---- ONE FINDING ROW (2026-09-02: the 266-line _BuildFindingRow of 2026-08-21, now in pieces) ----
       The row build touches 31 of the render's variables; what is carried BETWEEN rows travels in
       tFindingsCtx (Ctx, always ByRef), what is per-row scratch is a local of the piece that needs
       it. The pieces, in the order a row goes through them:
         _BuildRowCells        the lane badge + dot, the file cell, message, class chip and hint -> Ctx.sRow
         _BuildRenameCallsRow  the E 4546 finding: the "Rename the calls" chip + its old -> new sub-row
         _BuildObjCallRow      the E 4379 finding: the "Rewrite as Get" chip (Self receiver) or the
                               diagnosis (handle receiver), each with its editor-jump sub-row
         _RouteReviewRow       a Review row into the band, or into its dismissal group
         _RouteHandRow         a hand-migration row into its dismissal group
       Ctx.asCallLines / Ctx.sCallFile are ONE slot shared with the cause attribution, keyed by the
       file AND by what kind of read it holds - see _EnsureCallLinesWhole. */

    /* The call-line slot, holding the WHOLE file (or the cached whole file) - never a head left by
       the cause attribution (Ctx.iCallKind: 0 nothing, 1 the 24 KB head, 2 the whole file). Keying
       the slot on the FILENAME alone was not enough: once cause attribution had put the head of a
       big view file in there, a later 4546 row in that same file matched on the name, skipped its
       own read and searched a truncated array - NearMissDeclaredIn then failed to find a
       declaration that really was there, and the row offered "<name>X" in its place (2026-08-21).
       The analyzer helper and the built-ins catalogue come with it, once - through the memoised
       RunNativeGlobalFuncNames, never InstallGlobalFuncNames (the 2791 ms lesson of 2026-08-20). */
    Procedure _EnsureCallLinesWhole String sFile tFindingsCtx ByRef Ctx
        If (Ctx.hoCall = 0) ;
            Get Create (RefClass(cModAnalyzer)) to Ctx.hoCall
        If (SizeOfArray(Ctx.asBuiltins) = 0) ;
            Get RunNativeGlobalFuncNames of ghoFuncLib to Ctx.asBuiltins
        If (Lowercase(sFile) <> Ctx.sCallFile or Ctx.iCallKind < 2) Begin
            Move (rfReadEncodedFileAsStringArray(sFile)) to Ctx.asCallLines
            Move (Lowercase(sFile)) to Ctx.sCallFile
            Move 2 to Ctx.iCallKind
        End
    End_Procedure

    /* CLASS chip: the Begin_Row enrichment writes "... lives in 'Object <name> is a <Class>'" into
       the hint (VerifyBeginRow) - but the hint cell truncates right around the class name, so a
       SUBCLASSED grid/list (the case needing the class-names parameter, possibly a second plan run)
       was only visible in the tooltip (Nils 2026-07-25: "when classes have been subclassed... not
       clear in the (WIP) list?"). Lift the class out of our own hint grammar and show it as its own
       chip so subclassing reads at a glance. "" when the hint carries no class. */
    Function _ClassChipFromHint String sHint Returns String
        String sTail
        Integer iPos iP2

        Move (Pos("lives in 'Object ", sHint)) to iPos
        If (iPos = 0) ;
            Function_Return ""
        Move (Mid(sHint, (Length(sHint)), (iPos + 17))) to sTail
        Move (Pos(" is a ", sTail)) to iP2
        If (iP2 = 0) ;
            Function_Return ""
        Move (Mid(sTail, (Length(sTail)), (iP2 + 6))) to sTail
        Move (Pos("'", sTail)) to iP2
        If (iP2 <= 1) ;
            Function_Return ""
        Function_Return ((SpanOpen("fcls")) + Left(sTail, (iP2 - 1)) + CS_SpanEnd)
    End_Function

    /* A FILE THAT HALTS THE RUN is noted for the banner as well as shown as its row - once per
       file, with the line that uses FlexCOM.pkg. _FlexComHaltHtml turns the list into buttons. */
    Procedure _NoteFlexComHaltFile String sFile Integer iLine tFindingsCtx ByRef Ctx
        Integer i iLast

        Move True to Ctx.bFlexComHalt
        Move (SizeOfArray(Ctx.asHaltFile) - 1) to iLast
        For i from 0 to iLast
            If (Lowercase(Ctx.asHaltFile[i]) = Lowercase(sFile)) ;
                Procedure_Return
        Loop
        Move sFile to Ctx.asHaltFile[-1]
        Move iLine to Ctx.aiHaltLine[-1]
    End_Procedure

    /* ONE ROW'S CELLS into Ctx.sRow - with Ctx.sDot / Ctx.sBadge kept for the sub-rows that reuse
       them, and sBase handed back as the "name.pkg (872)" file text those sub-rows print again.

       THE BADGE SAYS WHICH LANE; THE TOOLTIP SAYS WHAT THAT COSTS YOU (Nils 2026-07-30). He ran a
       full clean cycle on one main program, switched to another, pressed Check, and new grid
       findings appeared: "didn't the Deep scan check all the ticked folders? ... That is hard to
       explain to a user, right?" It had. The new rows were COMPILER rows, and the compiler only
       reaches what the SELECTED PROGRAM includes - so changing the program legitimately changes
       half the board. The scan half had been complete all along and did not move. The two lanes
       had different reach, the badges named them, and nothing anywhere said what the names
       implied, so the only available reading was "the scan missed something". (In his case the
       lanes were complementary rather than overlapping: the views instantiate a workspace
       SUBCLASS, which the scan's boundary-aware base-class rules correctly do not match - it
       flagged the subclass declaration instead - while the compiler saw straight through the
       subclass to the obsolete base.)

       JUMP-TO-SOURCE on every row that names a real file+line (Nils 2026-07-23: "a static list
       that doesn't offer much help") - the WHOLE ROW is the click target (a lone file cell was not
       obviously clickable) and opens the editor at the row's first-occurrence line, the same
       sequence the Manual Changes and Analyzer grids use. Rows without a file (or line 0) stay
       plain. Report rows keep their own buttons and no row click. */
    Procedure _BuildRowCells String sFile Integer iLine String sLineDisplay String sMsg String sHint ;
                             String sScanBadge String sCompBadge tFindingsCtx ByRef Ctx String ByRef sBase
        String  sLine sFileCell sClassChip sOut
        String[] asBuiltBy
        Integer iPos
        Boolean bScan bErr

        Move (Pos("DS ", sMsg) > 0) to bScan
        Move (Pos("E ",  sMsg) > 0) to bErr
        /* The FlexCOM blocker (DS 9220): the engine refuses every write-run while it stands, so
           the render must lead with the halt rather than offer the plan. NARROWED with the engine
           (Nils 2026-09-03, LegacyApp): only a proxy some program compiles halts, so the banner
           agrees with the gate - a proxy no program builds is dead code; its row stays, its hint
           says so, and the plan is offered. */
        If (bScan = True and Pos("DS 9220", sMsg) > 0) Begin
            Get ProgramsCompilingFile of ghoApplication sFile to asBuiltBy
            If (SizeOfArray(asBuiltBy) > 0) ;
                Send _NoteFlexComHaltFile sFile iLine (&Ctx)
            Else ;
                Move (sHint + " NOT HALTING: no program in this workspace compiles this file - it is in no compile listing - so it is dead code. Retire it rather than re-generate it.") to sHint
        End
        // file basename (+ line as shown)
        Move sFile to sOut
        Move (RightPos("\", sOut)) to iPos
        If (iPos > 0) ;
            Move (Right(sOut, (Length(sOut) - iPos))) to sOut
        Move sLineDisplay to sLine
        If (sLine <> "") Begin
            // "name.pkg (872)", not "name.pkg:872" - the parenthesised form the rest of the
            // product uses (Nils 2026-07-23). A multi-occurrence "872 (x4)" folds to
            // "(872, x4)" so the parentheses never nest.
            Move (Replaces(" (x", sLine, ", x")) to sLine
            Move (Replaces(")", sLine, ""))     to sLine
            Move (sOut + " (" + sLine + ")") to sOut
        End
        Move sOut to sBase
        // source badge + severity dot
        If (bScan = True) Begin
            Move sScanBadge to Ctx.sBadge
            Move ((SpanOpen("fdot s")) + CS_SpanEnd) to Ctx.sDot
        End
        Else Begin
            Move sCompBadge to Ctx.sBadge
            If (bErr = True) ;
                Move ((SpanOpen("fdot e")) + CS_SpanEnd) to Ctx.sDot
            Else ;
                Move ((SpanOpen("fdot w")) + CS_SpanEnd) to Ctx.sDot
        End
        If (sFile <> "" and iLine > 0) ;
            Move (DivOpenClick("fnd", "opensrc", (sFile + '|' + String(iLine)), "")) to sFileCell
        Else ;
            Move (DivOpen("fnd")) to sFileCell
        Get _ClassChipFromHint sHint to sClassChip
        // The hint cell is ellipsized at 46% width, so the FULL text rides in the title tooltip
        // (Nils 2026-07-23: "the line is chopped off... needs a tooltip with the full text").
        Move (sFileCell + Ctx.sDot + Ctx.sBadge + (SpanOpen("fmsg")) + sMsg + (CS_SpanEnd + (SpanOpen("ffile"))) + sOut + CS_SpanEnd + sClassChip + (TagTipText("span", "fhint", sHint, sHint)) + CS_DivEnd) to Ctx.sRow
    End_Procedure

    /* THE 4546 CALL-SITE RENAME (Nils 2026-08-16: "Why is the legacy definition not listed with a
       button that suggests to rename it, and then offer an auto-rename? We have that in other
       cases"). E 4546 is what the calls say once their wrapper was renamed by hand (SQLExecute ->
       SQLExecuteX at the declaration; the calls still read SQLExecute and now bind to sql.pkg's
       PROCEDURE). The compiler does not name the offender, so the line is read: the name called
       function-style (CallNameCandidates - literals masked, built-ins and reserved words out) and
       the near-miss wrapper declared in the same file (NearMissDeclaredIn), if any. The chip -
       "Rename the calls..." -> RenameCollidingGlobalFunction "old|new" over the selected scope,
       which renames every of-less call and skips the already-renamed declaration - sits on the
       FINDING line (2026-08-19); the old -> new pair keeps its own sub-row because the finding line
       has no room for it, and that sub-row carries the editor jump. Reads are capped: past 25 such
       rows the row stays as it is (sCallSub comes back "").

       THE BUTTON ON THE FINDING LINE means this row must stop being a click target: a chip inside
       a clickable row fires BOTH handlers and both hand the relay a click, so the second
       silently overwrites the first. The row is rebuilt here without opensrc; the sub-row takes
       over the editor jump, so nothing is lost. */
    Procedure _BuildRenameCallsRow String sFile Integer iLine String sMsg String sBase String sHint ;
                                   tFindingsCtx ByRef Ctx String ByRef sCallSub
        String[] asCallNames
        String   sCallOld sCallNew sSub

        Move "" to sCallSub
        If (sFile = "" or iLine <= 0 or Ctx.iCallReads >= 25) ;
            Procedure_Return
        Increment Ctx.iCallReads
        Send _EnsureCallLinesWhole sFile (&Ctx)
        If (iLine > SizeOfArray(Ctx.asCallLines)) ;
            Procedure_Return
        Get CallNameCandidates of Ctx.hoCall Ctx.asCallLines[iLine - 1] Ctx.asBuiltins to asCallNames
        If (SizeOfArray(asCallNames) = 0) ;
            Procedure_Return
        Move asCallNames[0] to sCallOld
        Get NearMissDeclaredIn of Ctx.hoCall (&Ctx.asCallLines) sCallOld to sCallNew
        If (sCallNew = "") ;
            Move (sCallOld + "X") to sCallNew
        // One chip per old -> new PAIR - the run covers every site of it.
        If (SearchArray(Lowercase(sCallOld + "|" + sCallNew), Ctx.asCallPairs) <> -1) ;
            Procedure_Return
        Move (Lowercase(sCallOld + "|" + sCallNew)) to Ctx.asCallPairs[-1]
        Move (_CompilerRowHtml(Self, sMsg)) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpen("ffile")) + sBase + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (TagTipText("span", "fhint", sHint, sHint))) to Ctx.sRow
        Move (Ctx.sRow + (ChipHtml("fact", "fact off", "renamecalls", (sCallOld + '|' + sCallNew), ("Rename the calls" + CS_Ellipsis), ('Renames every of-less call of ' + sCallOld + ' in the selected scope - you confirm the new name next. Get/Send ... of <object> forms are never touched.'), True)) + CS_DivEnd) to Ctx.sRow
        Move ((DivOpenClick("fnd sub", "opensrc", (sFile + '|' + String(iLine)), (HtmlEscaped(Self, sFile)))) ;
            + (SpanOpen("fdot e inv")) + CS_SpanEnd + (FindingBadge("rename")) + (SpanOpen("ffile")) + sCallOld + ' ' + CS_RArrow + ' ' + sCallNew + CS_SpanEnd) to sSub
        // Nils's wording, 2026-08-19. The old sentence said the calls "now bind to a
        // DataFlex procedure", which is more mechanism than the row can carry.
        Move (sSub + (HintCell(Self, "The calls still use the old name and it is now used differently in DataFlex. Opens the editor here.")) + CS_DivEnd) to sCallSub
    End_Procedure

    // The compiler's own text for the message at sFile/iLine, from the analyze's scoped message set
    // ("" when the grid is not there or the set does not hold it - a board restored from a saved plan).
    // Called only for the rare 4345 rows, behind the same read cap as the other line-reading rows.
    Function _CompilerTextAt String sFile Integer iLine Returns String
        tCompileError[] aMsgs
        Integer i iLast

        If (ghoModAnalyzerDock = 0) ;
            Function_Return ""
        Get paScopedMessages of (oModAnalyzer_grd(ghoModAnalyzerDock)) to aMsgs
        Move (SizeOfArray(aMsgs) - 1) to iLast
        For i from 0 to iLast
            If (aMsgs[i].iLine = iLine and Lowercase(aMsgs[i].sFileName) = Lowercase(sFile)) ;
                Function_Return aMsgs[i].sText
        Loop
        Function_Return ""
    End_Function

    /* THE 4345 DUPLICATE-NAME ERROR ON A CLASS LINE (Nils 2026-09-03: "it is vital that a class name
       clash gets a recipe and one with high priority too. It normally generates lots of compile
       errors"). The compiler prints only the existing symbol's internal token (|CI134), so the row
       used to be a dead end under Information only. The reported LINE names the class - "Class
       cRegEx is a cObject" - and the owner is either a package of the target install (the class
       catalogue names it) or DataFlex's runtime (cRegEx: in no Pkg file; the compiler is the only
       oracle). Either way the fix is the same: rename the workspace's class everywhere, which
       RenameCollidingClass does. One chip per class; the declaration site is the sub-row. Only the
       should-not-be-defined variant qualifies - a 4345 on a Class line can also be the retired-base
       kind (U_DBLIST), told apart by the message text the scoped message set still carries; a board
       restored from a saved plan has no text and keeps the plain row. */
    Procedure _BuildClassClashRow String sFile Integer iLine String sMsg String sBase ;
                                  tFindingsCtx ByRef Ctx String ByRef sCallSub
        String sClass sText sOwner sPkg sSub sVer sWhy

        Move "" to sCallSub
        If (sFile = "" or iLine <= 0 or Ctx.iCallReads >= 25) ;
            Procedure_Return
        Increment Ctx.iCallReads
        Get _CompilerTextAt sFile iLine to sText
        If (Pos("should not be defined", Lowercase(sText)) = 0) ;
            Procedure_Return
        Send _EnsureCallLinesWhole sFile (&Ctx)
        If (iLine > SizeOfArray(Ctx.asCallLines)) ;
            Procedure_Return
        Get ClassDeclaredOnLine of Ctx.hoCall Ctx.asCallLines[iLine - 1] to sClass
        If (sClass = "") ;
            Procedure_Return
        // One chip per class - the run covers every reference of it.
        If (SearchArray(Lowercase("class|" + sClass), Ctx.asCallPairs) <> -1) ;
            Procedure_Return
        Move (Lowercase("class|" + sClass)) to Ctx.asCallPairs[-1]
        Get psTargetDfVersion of ghoApplication to sVer
        If (Trim(sVer) = "") ;
            Move "The target DataFlex" to sVer
        Else ;
            Move ("DataFlex " + sVer) to sVer
        Get InstallClassPkgFor of ghoFuncLib sClass to sPkg
        If (sPkg <> "") ;
            Move (sVer + " declares a class of this name itself, in " + sPkg + ".") to sOwner
        Else ;
            Move (sVer + " already has a class of this name - in its runtime, no package source declares it - or another file in this workspace declares it too.") to sOwner
        Move (sOwner + " Every use of the workspace's class fails with it - rename that class across the scope.") to sWhy
        Move (_CompilerRowHtml(Self, sMsg)) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpen("ffile")) + sClass + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (TagTipText("span", "fhint", sWhy, sWhy))) to Ctx.sRow
        Move (Ctx.sRow + (ChipHtml("fact", "fact off", "renameclass", sClass, ("Rename the class" + CS_Ellipsis), ("Renames " + sClass + " at its Class line and at every 'is a', RefClass() and 'for' reference in the compiled scope - you enter the new name next. Nothing else that spells the word is touched."), True)) + CS_DivEnd) to Ctx.sRow
        Move ((DivOpenClick("fnd sub", "opensrc", (sFile + '|' + String(iLine)), (HtmlEscaped(Self, sFile)))) ;
            + (SpanOpen("fdot e inv")) + CS_SpanEnd + (FindingBadge("declared")) + (SpanOpen("ffile")) + sBase + ' (' + String(iLine) + (')' + CS_SpanEnd)) to sSub
        Move (sSub + (HintCell(Self, "The clashing Class line. Opens the editor here.")) + CS_DivEnd) to sCallSub
    End_Procedure

    /* WHAT THE PLAN ALREADY KNOWS ABOUT LEGACY GRIDS, gathered once per render for _LegacyGridNote:
       which files carry a RefactorDbGridTocDbCJGrid row (so "the Auto-fix band already converts it" is
       READ off the plan, never assumed), and which class names the scan's 'Class X is a dbGrid' rule
       fired on - the workspace's own subclasses, read off the flagged line itself (word 2 of "Class
       MyDbGrid is a dbGrid"). The rule is found by KIND and TOKEN in the seed, not by its DS number
       as a literal: the number is stable by contract, but a literal here would be one more place to
       forget if that contract were ever renegotiated. Subclass files are read whole (a handful per
       workspace), capped so a pathological plan cannot turn this into a disk walk. */
    Procedure _CollectLegacyGridFacts tSavedPlanRow[] ByRef aRows tFindingsCtx ByRef Ctx
        tDeepScanRule[] aRules
        String[] asLines
        String sTok sKey sClass
        Integer i iLast iDS iReads
        Handle hoDS

        Get Create (RefClass(cDeepScanner)) to hoDS
        If (hoDS = 0) ;
            Procedure_Return
        Get BuildDefaultDeepScanRules of hoDS to aRules
        Send Destroy of hoDS
        Move 0 to iDS
        Move (SizeOfArray(aRules) - 1) to iLast
        For i from 0 to iLast
            If (aRules[i].eDSKind = eDSClassSubclass and aRules[i].sToken = "dbgrid") ;
                Move aRules[i].iDSNumber to iDS
        Loop
        Move ("DS " + String(iDS)) to sTok
        Move 0 to iReads
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (Lowercase(aRows[i].sFn) contains "refactordbgridtocdbcjgrid") Begin
                Move (Lowercase(Trim(aRows[i].sFile))) to sKey
                If (sKey <> "" and SearchArray(sKey, Ctx.asGridConvFiles) = -1) ;
                    Move sKey to Ctx.asGridConvFiles[-1]
            End
            If (iDS > 0 and iReads < 8 and aRows[i].iLine > 0 and Pos(sTok, aRows[i].sMsg) > 0) Begin
                Increment iReads
                Move (rfReadEncodedFileAsStringArray(aRows[i].sFile)) to asLines
                If (aRows[i].iLine <= SizeOfArray(asLines)) Begin
                    Get _NthWord of ghoFuncLib (Lowercase(asLines[aRows[i].iLine - 1])) 2 to sClass
                    If (sClass <> "" and SearchArray(sClass, Ctx.asLegacyGridClasses) = -1) ;
                        Move sClass to Ctx.asLegacyGridClasses[-1]
                End
            End
        Loop
    End_Procedure

    /* THE OBJECT THE LINE LIVES IN, when that object is a legacy grid (Nils 2026-09-04, LegacyApp
       PlanView.VW: "the big problem is that this is inside a DbGrid that should be suggested to
       convert to a CodeJock grid"). The suggestion existed - a W 4533 Begin_Row row in the Review
       band names the very object and offers RefactorDbGridTocDbCJGrid - but the E 4379 row in
       Breaks-the-build said nothing about the object it sat in, and the two facts were two bands
       apart. The compiler is no help: 4537 fires ONCE per class per program (LegacyApp: one warning
       for 1,490 MyDbGrid objects in 748 files), never per object.

       MEASURED, not assumed: EnclosingObjectClass reads the declaration above the line; the class
       is legacy when it ends in "dbgrid" (dbGrid itself, MyDbGrid, My_dbGrid - the converter's
       own auto-detect pattern and VerifyBeginRow's test) or is one of the workspace's "Class X is a
       dbGrid" subclasses the scan found (Ctx.asLegacyGridClasses). Whether the plan really converts
       THIS file is read off the plan rows (Ctx.asGridConvFiles), so the sentence never promises a row
       that is not there. Since 2026-10-03 that conversion is Auto-fix, and for the PLAIN dbGrid only:
       an EMPTY run leaves an object of the workspace's own subclass as it is, so for one of those the
       note names ConvertGridSubclassToCodeJock, which ports the class in place and its objects with it
       (2026-10-04).

       THE ORDER MATTERS, which is why the arity row says "fix the count first": the conversion
       turns "Entry_Item (f(Self, a, b))" into "Get f a b to sValue" inside the column object
       (cDbGridTocDbCJGrid's DF26 calculated-value route), and a Get compiles at any argument
       count - so converting first makes the E 4379 vanish with the count never looked at. The
       converter now leaves a TODO there too, but a TODO after the fact is the weaker warning.
       iKind: 0 = collision row (Self receiver, count fits or unknown), 1 = arity row, 2 = handle
       receiver. Fills sNote (visible), sTip (tooltip) and appends a "grid" jump to sSub - all three
       left as they were when the line is not inside a legacy grid. */
    Procedure _LegacyGridNote String sFile String sBase Integer iLine Integer iKind tFindingsCtx ByRef Ctx ;
                              String ByRef sNote String ByRef sTip String ByRef sSub
        String sClass sObjName sClassLc sWhat sOffer
        Integer iObjLine
        Boolean bLegacy bOffered bAuto

        Move "" to sNote
        Move "" to sTip
        If (Ctx.hoCall = 0 or iLine < 1) ;
            Procedure_Return
        Get EnclosingObjectClass of Ctx.hoCall (&Ctx.asCallLines) iLine (&sObjName) (&iObjLine) to sClass
        If (sClass = "") ;
            Procedure_Return
        Move (Lowercase(sClass)) to sClassLc
        Move (Right(sClassLc, 6) = "dbgrid") to bAuto
        Move (bAuto = True or SearchArray(sClassLc, Ctx.asLegacyGridClasses) <> -1) to bLegacy
        If (bLegacy = False) ;
            Procedure_Return
        Move (SearchArray(Lowercase(sFile), Ctx.asGridConvFiles) <> -1) to bOffered
        If (sClassLc = "dbgrid") Begin
            Move "the legacy dbGrid" to sWhat
            If (bOffered = True) ;
                Move " that the Auto-fix band already converts with RefactorDbGridTocDbCJGrid" to sOffer
            Else ;
                Move " - RefactorDbGridTocDbCJGrid converts it" to sOffer
        End
        // The workspace's own subclass: the converter's EMPTY run leaves its objects as they are, so the
        // note never promises that conversion - it says what has to come first.
        Else Begin
            Move "a workspace subclass of dbGrid" to sWhat
            Move (". RefactorDbGridTocDbCJGrid leaves its objects as they are: ConvertGridSubclassToCodeJock with the parameter " + (HtmlEscaped(Self, ("'" + sClass + "'"))) + " ports " + sClass + " to cDbCJGrid in place and converts its objects with it") to sOffer
        End
        Move (' It sits in ' + (BoldText("Object " + sObjName + " is a " + sClass)) + ' (line ' + String(iObjLine) + '), ' + sWhat + sOffer ;
            + (If((iKind = 1), ' - fix the count first.', '.'))) to sNote
        If (iKind = 1) Begin
            Move " Converting the grid rewrites this line as a Get inside the column object, and a Get compiles at any argument count - so the E 4379 would vanish with the count never settled and the surplus dropped in silence. Count first, grid second." to sTip
        End
        Else If (iKind = 2) Begin
            Move " Converting the grid keeps a call on another object as it is inside the column object, so the count still has to be settled either way." to sTip
        End
        Else Begin
            Move " Converting the grid rewrites this line as a Get inside the column object; a Get is a message send and binds to the workspace's method, so the collision goes with it." to sTip
        End
        Move (sSub + (ClickableHtml("div", "fnd sub", "opensrc", (sFile + '|' + String(iObjLine)), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("grid")) + (SpanOpen("ffile")) + sBase + ' (' + String(iObjLine) + (')' + CS_SpanEnd) + (HintCell(Self, "Opens the editor at the object declaration - the grid this line belongs to."))), ((HtmlEscaped(Self, sFile)))))) to sSub
    End_Procedure

    /* THE 4379 OBJECT-EXPRESSION CALL (Nils 2026-08-19: "I believe we already have a way to refactor
       local function calls used with global function call source lines constructs"). We do -
       ChangeObjectFunctionCallToGet - but it only knew methods declared in the SAME file, and his
       nine "Move (Split(Self, ...)) to sa" lines call a method declared once in wslibrary.pkg, so it
       could touch none of them. The name is read off the line (the 4379 message names no symbol)
       and passed to the converter as its parameter, which is now accepted as authorization. One
       chip per NAME - the run covers every site of it. Two receivers, two rows: Self gets the Get
       rewrite, a handle receiver gets a diagnosis and no automatic offer. Reads are capped at 25. */
    Procedure _BuildObjCallRow String sFile Integer iLine String sMsg String sBase ;
                               tFindingsCtx ByRef Ctx String ByRef sCallSub
        String sObjName sObjRecv sSub

        Move "" to sCallSub
        If (sFile = "" or iLine <= 0 or Ctx.iCallReads >= 25) ;
            Procedure_Return
        Increment Ctx.iCallReads
        Send _EnsureCallLinesWhole sFile (&Ctx)
        If (iLine > SizeOfArray(Ctx.asCallLines)) ;
            Procedure_Return
        Get ObjExprCallNameInLine of Ctx.hoCall Ctx.asCallLines[iLine - 1] to sObjName
        If (sObjName <> "") Begin
            If (SearchArray(Lowercase(sObjName), Ctx.asObjNames) = -1) ;
                Send _BuildObjCallSelfRow sFile iLine sMsg sBase sObjName (&Ctx) (&sSub)
            Move sSub to sCallSub
            Procedure_Return
        End
        Get ObjExprHandleCallInLine of Ctx.hoCall Ctx.asCallLines[iLine - 1] (&sObjRecv) to sObjName
        If (sObjName <> "" and SearchArray(Lowercase(sObjName), Ctx.asObjNames) = -1) ;
            Send _BuildObjCallHandleRow sFile iLine sMsg sBase sObjName sObjRecv (&Ctx) (&sSub)
        Move sSub to sCallSub
    End_Procedure

    /* WHAT THIS FILE KNOWS ABOUT <sName>'s OWN DECLARATION - one sentence for the collision row,
       and the one that must not overclaim, because it states a COUNT. Three cases, and the middle
       one is why this is a function rather than a nested If inside the row expression: iCallArgs
       comes back -1 when the call cannot be read off the line (unbalanced, or not the call the
       name suggests), and the first draft printed that -1 at the user as a parameter count.
       iDeclParams is -1 when this file declares no such object method. Both are ordinary states,
       not errors. PURE. */
    Function _ObjCallCountNote String sName Integer iDeclParams Integer iCallArgs Returns String
        String sPlural

        If (iDeclParams < 0) ;
            Function_Return (" This file does not declare " + sName + ", so the count cannot be" ;
                + " checked here - read the declaration where it lives before rewriting, because" ;
                + " a Get with the wrong count compiles and drops the surplus in silence.")
        Move (If((iDeclParams = 1), " parameter", " parameters")) to sPlural
        If (iCallArgs < 0) ;
            Function_Return (" This file declares " + sName + " with " + String(iDeclParams) ;
                + sPlural + ", but the arguments on this line could not be read - compare them by" ;
                + " eye before rewriting.")
        Function_Return (" This file declares " + sName + " with the " + String(iDeclParams) ;
            + sPlural + " this call passes, so the count is not the fault, and a name the newer" ;
            + " DataFlex owns is what is left.")
    End_Function

    /* THE BUTTON GOES ON THE FINDING LINE (Nils 2026-08-19: "Any action button normally sits on the
       first line, not on the sub-line"). Which means the row must stop being a click target of its
       own: a chip inside a clickable row fires BOTH handlers, and both hand the relay a click, so
       the second silently overwrites the first. That is why the 4390 name rows carry their
       chips on a row with no click and put the jump on sub-rows - the same shape is used here: the
       row is rebuilt without opensrc, and the sub-row below becomes the "open the line" jump, so
       nothing is lost.

       THE WORDING, corrected the same day. Nils read the first version as a claim about the CALL
       SYNTAX and objected that the syntax is the whole problem. Probe-compiled against DF26 to
       settle it: an own method called Name(Self, a, b) compiles perfectly (a name DataFlex does not
       own), a bare Split("T", "a T b") compiles with NOTHING declaring it, and Split with three
       arguments is the 4379. So the syntax is fine and the NAME is taken: DF26's runtime owns
       Split - it is in no .pkg and not in Lib\GlobalFunctions.lst, and StringSplit does not exist
       (E 4367). The hint says exactly that. */
    Procedure _BuildObjCallSelfRow String sFile Integer iLine String sMsg String sBase String sObjName ;
                                   tFindingsCtx ByRef Ctx String ByRef sCallSub
        String  sJoined sGridNote sGridTip sGridSub
        Integer iDeclLine iDeclParams iCallArgs

        Move (Lowercase(sObjName)) to Ctx.asObjNames[-1]
        /* WHICH 4379 IS THIS? (Nils 2026-09-04, LegacyApp PlanView.VW.) The collision story below was
           told to every Self-receiver 4379, and for his line every clause of it was false: his own
           fHeadValue is declared in the same object above the call, DataFlex owns no such name,
           and the fault was arithmetic - one declared parameter against two passed arguments, the
           shape 19.1 waved through. The Get rewrite would not have fixed that; probe-compiled under
           DF26, "Get f 1 2 to n" against a one-parameter f compiles CLEAN, so the offer would have
           silenced the error and dropped the surplus argument. When this file's own declaration is
           in reach and the counts disagree, that is a FACT and the row states it instead. */
        Move 0 to iDeclLine
        Get JoinContinuedFrom of Ctx.hoCall (&Ctx.asCallLines) (iLine - 1) to sJoined
        Get ObjExprCallArgCount of Ctx.hoCall sJoined sObjName to iCallArgs
        Get DeclaredParamCountIn of Ctx.hoCall (&Ctx.asCallLines) sObjName (&iDeclLine) to iDeclParams
        If (iDeclParams >= 0 and iCallArgs >= 0 and iDeclParams <> iCallArgs) Begin
            Send _BuildObjCallArityRow sFile iLine sMsg sBase sObjName iDeclLine iDeclParams iCallArgs (&Ctx) (&sCallSub)
            Procedure_Return
        End
        Move "" to sGridSub
        Send _LegacyGridNote sFile sBase iLine 0 (&Ctx) (&sGridNote) (&sGridTip) (&sGridSub)
        Move (_CompilerRowHtml(Self, sMsg)) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpen("ffile")) + sBase + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpenTip("fhint", ("The object-expression form itself is legal and" ;
            + " stays legal. What E 4379 reports is that the argument count does not fit the" ;
            + " function the call RESOLVED to - and when a newer DataFlex owns the same name," ;
            + " that is its function, not the workspace's: the runtime declares it in no package, so a" ;
            + " source search for the thing the name collided with finds nothing. A Get statement is" ;
            + " a message send, so it binds back to the workspace's OWN method." ;
            + (_ObjCallCountNote(Self, sObjName, iDeclParams, iCallArgs)) + sGridTip))) ;
            + 'The argument count does not fit the function this call resolved to' ;
            + ' - and where a newer DataFlex owns ' + (BoldText(sObjName)) + ', that is its' ;
            + " function rather than the workspace's. A Get statement binds to the workspace's." + sGridNote + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (ChipHtml("fact", "fact off", "objcalltoget", (sObjName), ("Rewrite as Get" + CS_Ellipsis), ('Rewrites Move (' + sObjName + '(Self, args)) to dest into Get ' + sObjName + ' args to dest, across the files the compiler reported. Declarations are not touched.'), True)) + CS_DivEnd) to Ctx.sRow
        // The jump, now that the row itself no longer carries one.
        Move ((ClickableHtml("div", "fnd sub", "opensrc", (sFile + '|' + String(iLine)), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("line")) + (SpanOpen("ffile")) + sBase + ' (' + String(iLine) + (')' + CS_SpanEnd) + (HintCell(Self, "Opens the editor here."))), ((HtmlEscaped(Self, sFile)))))) to sCallSub
        Move (sCallSub + sGridSub) to sCallSub
    End_Procedure

    /* THE COUNT DOES NOT FIT YOUR OWN METHOD (Nils 2026-09-04, LegacyApp PlanView.VW). fHeadValue
       declares one parameter and line 318 passes two; its three siblings in the same object declare
       two each, are called the same way, and none of them errors - so the call was written to the
       sibling pattern and DataFlex 19.1 accepted the extra argument unchecked.

       NO GET REWRITE IS OFFERED, and that is the point. The Get rewrite this row used to carry does
       not fix a count: probe-compiled under DF26, "Get f 1 2 to n" against a one-parameter f
       compiles clean, because a message send does not count arguments. Pressing it would have
       retired the error and thrown the second argument away without a word. The fix is a decision
       at the declaration or at the call, so the row states both numbers and jumps to both lines.

       THE ONE OFFER THAT IS HONEST HERE (Nils 2026-09-04, "please do 1, 2, 3" - this is 3): drop
       the surplus. 19.1 passed the extra argument and the method never read it, so removing it
       changes nothing at run time; the only thing that changes is that DF26 stops counting it.
       Offered only when the helper the run would use says it WOULD change this very line
       (iDropped > 0): the call is whole on the line, the receiver is Self, the surplus carries no
       nested call. The other honest fix - the declaration was meant to grow - stays a hand
       decision, and the dialog says so. Too FEW arguments is never offered: there the old runtime
       handed the method blanks it may have relied on.

       And the OBJECT the line sits in (this is 1): when it is a legacy grid, the row says so and
       jumps to it - see _LegacyGridNote for why the count must come before the conversion. */
    Procedure _BuildObjCallArityRow String sFile Integer iLine String sMsg String sBase String sObjName ;
                                    Integer iDeclLine Integer iDeclParams Integer iCallArgs ;
                                    tFindingsCtx ByRef Ctx String ByRef sCallSub
        String sNear sGridNote sGridTip sGridSub sPreview
        Integer iDropped

        Get NearMissDeclaredIn of Ctx.hoCall (&Ctx.asCallLines) sObjName to sNear
        Move "" to sGridSub
        Send _LegacyGridNote sFile sBase iLine 1 (&Ctx) (&sGridNote) (&sGridTip) (&sGridSub)
        Move 0 to iDropped
        If (iCallArgs > iDeclParams and iLine <= SizeOfArray(Ctx.asCallLines)) ;
            Get _DropSurplusArgsInLine of ghoFuncLib Ctx.asCallLines[iLine - 1] sObjName iDeclParams (&iDropped) to sPreview
        Move (_CompilerRowHtml(Self, sMsg)) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpen("ffile")) + sBase + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpenTip("fhint", ("This file declares " + sObjName + " itself, so the" ;
            + " two numbers can be held against each other right here - and they do not match." ;
            + " DataFlex 19.1 and earlier accepted extra arguments on the expression form" ;
            + " unchecked, so a call that was quietly wrong for years first errors on a newer" ;
            + " compiler. No Get rewrite is offered because none would be honest: a Get statement" ;
            + " does not count arguments either, so it would compile and drop the surplus in" ;
            + " silence. Decide at the declaration or at the call which one is right." + sGridTip))) ;
            + "The workspace's " + (BoldText(sObjName)) + ' declares ' + String(iDeclParams) ;
            + ' parameter' + (If((iDeclParams = 1), '', 's')) + ' and this call passes ' ;
            + String(iCallArgs) + ' - check the count before anything else.' ;
            + (If((sNear <> ""), (' A sibling ' + (BoldText(sNear)) + ' is declared in this file' ;
            + ' - check whether the arguments were meant for it.'), '')) ;
            + sGridNote + CS_SpanEnd) to Ctx.sRow
        If (iDropped > 0) ;
            Move (Ctx.sRow + (ChipHtml("fact", "fact off", "dropsurplus", (sObjName + "|" + String(iDeclParams) + "|" + String(iLine) + "|" + sFile), ("Drop the surplus argument" + (If((iDropped = 1), "", "s")) + CS_Ellipsis), ("Removes the trailing " + String(iDropped) + " argument" + (If((iDropped = 1), "", "s")) + " from the " + sObjName + "(Self, ...) calls in this file that pass more than the " + String(iDeclParams) + " declared. The old runtime never delivered them, so nothing changes at run time. The declaration is not touched - if it was meant to grow instead, do that by hand and leave this."), True))) to Ctx.sRow
        Move (Ctx.sRow + CS_DivEnd) to Ctx.sRow
        Move ((ClickableHtml("div", "fnd sub", "opensrc", (sFile + '|' + String(iLine)), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("call")) + (SpanOpen("ffile")) + sBase + ' (' + String(iLine) + (')' + CS_SpanEnd) + (HintCell(Self, "Opens the editor at the call."))), ((HtmlEscaped(Self, sFile)))))) to sCallSub
        If (iDeclLine > 0) ;
            Move (sCallSub + (ClickableHtml("div", "fnd sub", "opensrc", (sFile + '|' + String(iDeclLine)), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("declared")) + (SpanOpen("ffile")) + sBase + ' (' + String(iDeclLine) + (')' + CS_SpanEnd) + (HintCell(Self, "Opens the editor at the declaration - the parameter list to hold the call against."))), ((HtmlEscaped(Self, sFile)))))) to sCallSub
        Move (sCallSub + sGridSub) to sCallSub
    End_Procedure

    /* THE HANDLE-RECEIVER VARIANT (Nils 2026-08-29): Name(ghoDialog, args) - the same legal call
       form aimed at another object. NOTHING AUTOMATIC IS OFFERED here, and that is a decision, not
       a gap: on the row that taught us this (SelectFolder(ghoDFSFolderSelectorDialog, 4 args)
       against a 2-parameter SelectFolder, waved through by 19.1's unchecked expression arguments),
       a blind Get rewrite keeps the wrong count and produces a differently broken line - the
       arguments fit the near-miss sibling SelectFolder2, which is what the call was meant for. So
       the row DIAGNOSES: the name, the receiver, the argument count read off the
       (continuation-joined) line, and a same-file near-miss when one is declared. The fix stays a
       decision the user makes at the declaration. */
    Procedure _BuildObjCallHandleRow String sFile Integer iLine String sMsg String sBase String sObjName String sObjRecv ;
                                     tFindingsCtx ByRef Ctx String ByRef sCallSub
        String  sObjJoined sObjNear sGridNote sGridTip sGridSub
        Integer iObjArgs

        Move (Lowercase(sObjName)) to Ctx.asObjNames[-1]
        Get JoinContinuedFrom of Ctx.hoCall (&Ctx.asCallLines) (iLine - 1) to sObjJoined
        Get ObjExprCallArgCount of Ctx.hoCall sObjJoined sObjName to iObjArgs
        Get NearMissDeclaredIn of Ctx.hoCall (&Ctx.asCallLines) sObjName to sObjNear
        Move "" to sGridSub
        Send _LegacyGridNote sFile sBase iLine 2 (&Ctx) (&sGridNote) (&sGridTip) (&sGridSub)
        Move (_CompilerRowHtml(Self, sMsg)) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpen("ffile")) + sBase + CS_SpanEnd) to Ctx.sRow
        Move (Ctx.sRow + (SpanOpenTip("fhint", ("The object-expression form itself is legal;" ;
            + " DataFlex 19.1 and earlier accepted extra arguments on it unchecked, so a call" ;
            + " that was quietly wrong for years first errors on a newer compiler. Compare the" ;
            + " count against the declared parameter list before changing the call - and check" ;
            + " near-miss siblings, whose parameter list often matches exactly what is passed." + sGridTip))) ;
            + "The workspace's " + (BoldText(sObjName)) + ' is called on ' + (BoldText(sObjRecv)) ;
            + (If((iObjArgs >= 0), (' with ' + String(iObjArgs) + ' argument' + (If((iObjArgs = 1), '', 's'))), '')) ;
            + ' - hold that against the parameters ' + (BoldText(sObjName)) + ' declares.' ;
            + (If((sObjNear <> ""), (' A sibling ' + (BoldText(sObjNear)) + ' is declared in this file' ;
            + ' - check whether the arguments were meant for it.'), '') ) ;
            + sGridNote + CS_SpanEnd + CS_DivEnd) to Ctx.sRow
        Move ((ClickableHtml("div", "fnd sub", "opensrc", (sFile + '|' + String(iLine)), (((SpanOpen("fdot e inv")) + CS_SpanEnd) + (FindingBadge("line")) + (SpanOpen("ffile")) + sBase + ' (' + String(iLine) + (')' + CS_SpanEnd) + (HintCell(Self, "Opens the editor here."))), ((HtmlEscaped(Self, sFile)))))) to sCallSub
        Move (sCallSub + sGridSub) to sCallSub
    End_Procedure

    /* A Review row: into the band when a plan run would act on it, else into its dismissal group.
       A REPORT IS STILL WORK THE TOOL CAN DO (Nils 2026-08-31). Counted apart from iReviewRun,
       which must keep meaning "rows a plan run would CHANGE" - that is what keeps the Run-the-plan
       chip honest (the DS 9221 rule: never offer a Run that cannot change anything). But the
       campaign EXIT was gating on that same number, so it announced "the tool has run everything
       it can" with four runnable reports sitting on the board - and then told the user, one
       sentence later, to go and run one. Two different questions; they now have two counters. */
    Procedure _RouteReviewRow String sFile String sFn String sMsg String sHint Handle hoFnDD tFindingsCtx ByRef Ctx
        String  sFileKey sLeaf sTip sRowX
        Integer iGrp
        Boolean bRunnable

        If (Ctx.iReview = 0) ;
            Move (HtmlEscaped(Self, sHint)) to Ctx.sPeekReview
        Increment Ctx.iReview
        // Count SEPARATELY the rows a plan run would actually act on: the band's action is
        // only honest while at least one of them exists.
        Get RowHasRunnableFunction hoFnDD sFn to bRunnable
        If (bRunnable = True) Begin
            Increment Ctx.iReviewRun
            /* ITS OWN IGNORE, IN A SIBLING CELL (Nils 2026-09-05). A converter-backed row has no
               dismissal group - the band's one Run-the-plan chip is its action - so a file that is to
               stay as it is (LegacyApp: two Grid dialogs among the DS 9191 rows) could only be set aside
               on the analyzer grid. The chip sits BESIDE the row, never inside it: a chip inside a
               clickable row fires both handlers (the 4546 rename row's lesson), and this row keeps
               its editor jump. Same subdued look as the header's Show-hidden chip (.fign). */
            Move (ExtractFileName(sFile)) to sLeaf
            Move ('Hides this ' + Trim(sMsg) + ' finding for ' + sLeaf + ' and leaves it out of the plan. Show hidden findings again, in the band header, brings it back.') to sTip
            Move ((DivOpen("fndx")) + Ctx.sRow + (SpanOpen("fign")) + (ChipHtml("fact", "fact off", "ignorerow", (sFile + '|' + sMsg), "Ignore", sTip, True)) + CS_SpanEnd + CS_DivEnd) to sRowX
            Move (Ctx.sReview + sRowX) to Ctx.sReview
            Move (Lowercase(Trim(sFile))) to sFileKey
            If (sFileKey <> "" and SearchArray(sFileKey, Ctx.asReviewFiles) = -1) ;
                Move sFileKey to Ctx.asReviewFiles[-1]
            Procedure_Return
        End
        If (Trim(sFn) <> "") ;
            Increment Ctx.iReviewReport
        Get TallyDismissable (&Ctx.asRevFn) (&Ctx.aiRevCount) (&Ctx.asRevHint) sFn sHint to iGrp
        // Create the slot before reading it: a brand-new group's element does not exist
        // yet, and appending reads it first. See feedback on jagged/array element init.
        If (iGrp >= 0 and iGrp >= SizeOfArray(Ctx.asRevRows)) ;
            Move "" to Ctx.asRevRows[iGrp]
        If (iGrp >= 0) ;
            Move (Ctx.asRevRows[iGrp] + Ctx.sRow) to Ctx.asRevRows[iGrp]
        Else ;
            Move (Ctx.sReview + Ctx.sRow) to Ctx.sReview
    End_Procedure

    /* A hand-migration row into its dismissal group - BY MESSAGE, not function: Explain/Unknown
       rows have no converter by definition, so sFn is empty for every one of them (1,446 of 1,462
       on WinServ) and a function tally produced no groups at all. The message is what they DO
       carry, it is what the user recognises, and it is the ignore list's own key. */
    Procedure _RouteHandRow String sMsg String sHint tFindingsCtx ByRef Ctx
        Integer iGrp

        If (Ctx.iHand = 0) ;
            Move (HtmlEscaped(Self, (sMsg * sHint))) to Ctx.sPeekHand
        Increment Ctx.iHand
        Get TallyDismissable (&Ctx.asHandFn) (&Ctx.aiHandCount) (&Ctx.asHandHint) sMsg sHint to iGrp
        If (iGrp >= 0 and iGrp >= SizeOfArray(Ctx.asHandRows)) ;
            Move "" to Ctx.asHandRows[iGrp]
        If (iGrp >= 0) ;
            Move (Ctx.asHandRows[iGrp] + Ctx.sRow) to Ctx.asHandRows[iGrp]
        Else ;
            Move (Ctx.sHand + Ctx.sRow) to Ctx.sHand
    End_Procedure

    /* A hand-migration row keyed by PACKAGE (2026-10-04): an obsolete install package whose Use is
       there for the workspace's own subclass (_CollectOutsideRow). Grouped and dismissed per package
       file, like the Review band's package rows - see tFindingsCtx.asHandPkgKey for why not by
       message. sRow is the finished row, sHint its hint. */
    Procedure _RouteHandPkgRow String sLeaf String sHint String sRow tFindingsCtx ByRef Ctx
        Integer iGrp

        If (Ctx.iHand = 0) ;
            Move (HtmlEscaped(Self, ("W 4536" * sHint))) to Ctx.sPeekHand
        Increment Ctx.iHand
        Get TallyDismissable (&Ctx.asHandPkgKey) (&Ctx.aiHandPkgCount) (&Ctx.asHandPkgHint) sLeaf sHint to iGrp
        If (iGrp >= 0 and iGrp >= SizeOfArray(Ctx.asHandPkgRows)) ;
            Move "" to Ctx.asHandPkgRows[iGrp]
        If (iGrp >= 0) ;
            Move (Ctx.asHandPkgRows[iGrp] + sRow) to Ctx.asHandPkgRows[iGrp]
        Else ;
            Move (Ctx.sHand + sRow) to Ctx.sHand
    End_Procedure

    /* WHICH AUTO-FIXABLE ROWS LEAD THEIR BAND (Nils 2026-10-05, on a workspace whose band held 787
       "COMPILER W 4533" lines above the seven rows that explain them: "one has to scroll all the way
       to the bottom of the list until the subclass lines appear ... It would be better/clearer if the
       subclass items were placed at the top of the list"). The scan's rows for a grid subclass of the
       workspace's own - the class itself, and the summary of its objects - say WHAT
       ConvertGridSubclassToCodeJock converts; the compiler's rows are the Begin_Row lines inside
       those objects, one per grid. The analyzer lists compiler findings first and scan findings
       after, which put the explanation under everything it explains.

       A row leads when the scan alone reported it (no compiler message is merged into it) and its
       function is the subclass converter. Among the leading rows the analyzer's order stands, and
       that is catalogue order: the classes (DS 9198-9200) before their objects (DS 9234-9236).
       _BuildFindingRow collects them in Ctx.sAutoLead; _AddPlanLeadRows puts them above the band's
       other rows, under the plan line. */
    Function LeadsAutoBand String sMsg String sFn Returns Boolean
        If (Lowercase(Trim(sFn)) <> "convertgridsubclasstocodejock") ;
            Function_Return False
        Function_Return (Left(Trim(sMsg), 3) = "DS " and Pos("W ", sMsg) = 0 and Pos("E ", sMsg) = 0)
    End_Function

    /* ONE FINDING ROW: decide which band it lands in, build what it says, offer its actions.
       aRows is ByRef only to avoid copying 1,462 rows per call; it is not written. */
    Procedure _BuildFindingRow tSavedPlanRow[] ByRef aRows Integer i Handle hoFnDD ;
                               String sScanBadge String sCompBadge tFindingsCtx ByRef Ctx
        String  sHint sMsg sBase sShadowNote sCallSub sFileKey
        Integer iCat
        Boolean bErr bColl

        Move aRows[i].sMsg      to sMsg
        Move aRows[i].eCategory to iCat
        Move aRows[i].sHint     to sHint
        // A row sends the reader to a FILE. When the last build compiled a DIFFERENT file of
        // that name, the one they are about to edit is not the one that compiles - so the row
        // says so first. Empty for the copy the build compiled, which is nearly every row.
        Send _ShadowNoteForFile aRows[i].sFile (&Ctx) (&sShadowNote)
        If (sShadowNote <> "") ;
            Move (sShadowNote + sHint) to sHint
        Send _BuildRowCells aRows[i].sFile aRows[i].iLine aRows[i].sLineDisplay sMsg sHint sScanBadge sCompBadge (&Ctx) (&sBase)
        Move (Pos("E ",  sMsg) > 0) to bErr
        Move (Pos("4544", sMsg) > 0 or Pos("4390", sMsg) > 0) to bColl
        // assign to exactly ONE band (priority: auto-fixable, then blocking errors, then review, then manual)
        // Name collisions are deliberately represented ONCE - by the actionable name rows that lead
        // Breaks-the-build (_AddCollisionRows) - not as a wall of individually useless rows: they all
        // trace back to a few conflicting declarations, none is separately fixable, and on a flooded
        // workspace they bury every other finding. This also absorbs the flood SUMMARY row emitted
        // by the analyzer (its sMsg is "E 4544").
        If (bColl = True) Begin
            // deliberately nothing - counted by the grid, rendered as the name rows
        End
        /* THE USER'S "NEVER PICK" LIST (Nils 2026-09-23): a converter the user has set aside is
           still a finding, but not an automatic one. Its row goes to Review, where the plan lists
           the function unticked and the user's own tick runs it. Select Functions holds the list
           (cRefactorApplication.NeverPickFunctions has the story). */
        Else If (iCat = eModAutoFix and IsNeverPickFunction(ghoApplication, Trim(aRows[i].sFn)) = True) ;
            Send _RouteReviewRow aRows[i].sFile aRows[i].sFn sMsg ("On your never-pick list: " + Trim(aRows[i].sFn) + " does not run (Select Functions), so the plan lists it unticked. " + sHint) hoFnDD (&Ctx)
        Else If (iCat = eModAutoFix) Begin
            // A row that leads the band is collected apart (LeadsAutoBand has the story). The peek in
            // the folded band's header is the hint of the row the band opens with: the first leading
            // row when there is one, otherwise the first row of all.
            If (LeadsAutoBand(Self, sMsg, aRows[i].sFn) = True) Begin
                If (Ctx.sAutoLead = "") ;
                    Move (HtmlEscaped(Self, sHint)) to Ctx.sPeekAuto
                Move (Ctx.sAutoLead + Ctx.sRow) to Ctx.sAutoLead
            End
            Else Begin
                Move (Ctx.sAuto + Ctx.sRow) to Ctx.sAuto
                If (Ctx.iAuto = 0) ;
                    Move (HtmlEscaped(Self, sHint)) to Ctx.sPeekAuto
            End
            Increment Ctx.iAuto
            Move (Lowercase(Trim(aRows[i].sFile))) to sFileKey
            If (sFileKey <> "" and SearchArray(sFileKey, Ctx.asAutoFiles) = -1) ;
                Move sFileKey to Ctx.asAutoFiles[-1]
        End
        Else If (bErr = True) Begin
            /* THE ROW GOES TO ITS BAND AT THE END, not here - because whether it carries a
               code-changing chip is only known once the 4546 / 4379 reads have run, and that
               decides WHICH half of the band it belongs to (Nils 2026-08-19: "there is one
               'Rename the calls..' button and it is not at the top of the list. I thought we
               agreed on having buttons that can change the code ... at the top?"). */
            Move "" to sCallSub
            If (Pos("4546", sMsg) > 0 and Trim(aRows[i].sFn) = "") ;
                Send _BuildRenameCallsRow aRows[i].sFile aRows[i].iLine sMsg sBase sHint (&Ctx) (&sCallSub)
            If (sCallSub = "" and Pos("4379", sMsg) > 0) ;
                Send _BuildObjCallRow aRows[i].sFile aRows[i].iLine sMsg sBase (&Ctx) (&sCallSub)
            If (sCallSub = "" and Pos("4345", sMsg) > 0) ;
                Send _BuildClassClashRow aRows[i].sFile aRows[i].iLine sMsg sBase (&Ctx) (&sCallSub)
            /* A ROW THAT CAN CHANGE CODE LEADS THE BAND. sBreakAct collects the finding row TOGETHER
               with its action sub-row - they are one unit and must never be separated - and is
               prepended by _AddCollisionRows, above the rows that only describe. The rest keep
               their order. */
            If (sCallSub <> "") ;
                Move (Ctx.sBreakAct + Ctx.sRow + sCallSub) to Ctx.sBreakAct
            Else ;
                Move (Ctx.sBreak + Ctx.sRow) to Ctx.sBreak
            /* ESCAPED, like every other place a hint reaches the markup. The peek is the first
               row's hint pasted into the band's <summary>, and on a DataFlex 3.1 workspace the
               first error was E 4313, whose hint spells out "<TABLE>.<column>" - a raw <table>
               tag inside the header, which the parser obeys: the title vanished and the rows
               fell out of the band, indented under nothing (Nils 2026-09-19). The row cell was
               safe all along (TagTipText escapes); only the four band peeks pasted raw. */
            If (Ctx.iBreak = 0) ;
                Move (HtmlEscaped(Self, (sMsg * sHint))) to Ctx.sPeekBreak
            Increment Ctx.iBreak
        End
        Else If (iCat = eModSuggest) ;
            Send _RouteReviewRow aRows[i].sFile aRows[i].sFn sMsg sHint hoFnDD (&Ctx)
        Else ;
            Send _RouteHandRow sMsg sHint (&Ctx)
    End_Procedure

    /* ---- THE FINDINGS RENDER (2026-09-02: FindingsListHtml, 577 lines on 2026-08-21, now in pieces) ----
       Everything carried across the row loop travels in tFindingsCtx (Ctx, ByRef); every piece that
       needs it is a PROCEDURE, because a struct handed to a same-object Get arrives empty (the
       2026-08-12 lesson), and the pieces hand strings back through ByRef locals. In render order:
         _FindingsBadges          the scan / compiler badges, built once
         _AttributeMacroCause     per "reported away from the construct" row: WHICH class or macro
         _BuildFindingRow         every other row (its own family, above)
         _OutsideRowsHtml         the read-only packages band, from what _CollectOutsideRow aggregated
         _AddCollisionRows        the 4544 / 4390 name rows that lead Breaks-the-build
         _AddPlanLeadRows         the halt banner and the plan / review lead rows
         _AddReviewDismissals     "Ignore all N" groups for the Review band
         _CauseGroupRowsHtml      the cause groups into the hand band (+ the system-class chip)
         _AddHandDismissals       "Ignore all N" groups for the hand band
         _PublishRenderVerdict    piChkActionable / piChkListed / piChkOutsideErr for the steps tile
         _AppendFindingsHeader    the count, its chips, the lanes note, Clear board
         _EmptyBoardHtml          the four honest empty states, each ending in NextStepHtml
         _AppendBands             the bands in argued order, ending in NextStepHtml */

    /* Both row badges, built ONCE per render - the compiler one names the program whose include
       chain defines its reach, which is the fact the whole scan-vs-compiler confusion turned on. */
    Procedure _FindingsBadges String ByRef sScanBadge String ByRef sCompBadge String ByRef sMainProg String ByRef sMainEsc
        String sProg sEsc

        Get MainProgram of ghoApplication to sProg
        Move (Trim(sProg)) to sProg
        If (sProg = "") ;
            Move "the selected program" to sProg
        Get HtmlEscaped sProg to sEsc
        Move sProg to sMainProg
        Move sEsc  to sMainEsc
        Move ((SpanOpenTipHtml("bdg bdg-ds", CS_DashScanBadgeTip)) + 'scan' + CS_SpanEnd) to sScanBadge
        Move ((SpanOpenTipHtml("bdg bdg-c", ("Found by compiling " + sEsc + " " + CS_EmDash ;
            + " covers only the files that program includes."))) ;
            + 'compiler' + CS_SpanEnd) to sCompBadge
    End_Procedure

    /* LEGACY CODE INSIDE A MACRO IS STATED ONCE, NOT LISTED (Nils 2026-07-28). The compiler reports
       these at every USE of the macro - 579 rows across 542 files on WinServ - while the fix, if
       anyone should attempt it at all, lives in ONE definition. Nils's call: "it is fine with legacy
       code there ... If somebody really wants to fix code in a macro command, they need to be super
       knowledgable about macro code, something most developers are not." Same treatment the
       name-collision flood already gets: counted, collapsed, never listed individually. The
       analyzer grid still holds every one of them.

       GROUP THESE BY THEIR REAL CAUSE, don't lump them (Nils 2026-08-19: "'Inside macro
       expansions'? What is?" - and there was no link to anything). The analyzer only knows the
       construct is NOT on the reported line; the LINE says whether that is because it declares an
       object of a class, or because it invokes a macro. Sampled on his WinServ: the largest family
       (W 4538) sits on "Object X is a cTrDbView", i.e. not a macro at all. One group per named
       cause, each keeping its first site so the row can link somewhere.

       THE CAP WAS THE BUG, NOT A CATEGORY (Nils 2026-08-19: "333x Reported away from the construct
       ... it is a reference to a DataFlex system package code and is a false positive"). It read
       the cause for the first 200 findings only - his WinServ raises 533 of these, 533 - 200 = 333
       - and the rest fell into a lump row that said their cause "could not be read off the line",
       when nothing had tried. A silent cap that mislabels what it skipped is worse than no cap. A
       bound REMAINS, purely as a runaway guard (CI_ModCauseReadCap), and it is now honest: what it
       skips is counted in iCauseCapped and SAID, never relabelled as a cause that could not be read.

       READ THE HEAD, NOT THE FILE (2026-08-20). Only ONE line of each file is wanted - the one the
       compiler pointed at - and on WinServ those sit at median line 13, p90 26, max 271. 24 KB
       covers ~400 lines of DataFlex source; when a line does land beyond it the array is simply
       short, and the fallback re-reads that one file in full. NO BUILT-INS FETCH HERE: this branch
       never reads asBuiltins, and sharing the 4379 branches' fetch made it pay 2791 ms of a 2793 ms
       row loop. */
    /* COUNTED IN WARNINGS, NOT IN ROWS (2026-09-09). The analyzer grid folds a macro-expansion
       family per (file, macro), so ONE row here can stand for every call site in that file - 310
       of them behind a single row on the workspace that prompted the fold. Tallying 1 per row
       would shrink this family by exactly the fold factor and quietly contradict the compiler.
       The row's Line cell already carries the merged count as '(xN)', which is what
       OccurrencesFromLineCell reads; it returns 1 for an unfolded row, so nothing else changes.
       iMacro, iCauseCapped and aiCauseCount all move to the same unit together - _CauseLumpRowHtml
       shows 'iMacro - iCauseNamed' as the unattributed remainder, so they must never diverge. */
    Procedure _AttributeMacroCause String sFile Integer iLine String sLineDisplay tFindingsCtx ByRef Ctx
        String  sCauseName
        Integer iCauseKind iCauseIdx iOcc

        // Created before the early returns below: the occurrence count is read off the row for
        // EVERY row of the family, including the ones that never reach the source read.
        If (Ctx.hoCall = 0) ;
            Get Create (RefClass(cModAnalyzer)) to Ctx.hoCall
        Get OccurrencesFromLineCell of Ctx.hoCall sLineDisplay to iOcc
        Move (Ctx.iMacro + iOcc) to Ctx.iMacro
        If (sFile = "" or iLine <= 0) ;
            Procedure_Return
        If (Ctx.iCauseReads >= CI_ModCauseReadCap) Begin
            Move (Ctx.iCauseCapped + iOcc) to Ctx.iCauseCapped
            Procedure_Return
        End
        Increment Ctx.iCauseReads
        If (Lowercase(sFile) <> Ctx.sCallFile) Begin
            Move (rfReadEncodedFileHead(sFile, 24576)) to Ctx.asCallLines
            Move (Lowercase(sFile)) to Ctx.sCallFile
            Move 1 to Ctx.iCallKind
        End
        // Beyond the head - pay for the whole file, for this one file only. Not when the slot is
        // ALREADY the whole file: then a short array means the file is short, and re-reading it
        // would say the same thing at full price.
        If (iLine > SizeOfArray(Ctx.asCallLines) and Ctx.iCallKind < 2) Begin
            Move (rfReadEncodedFileAsStringArray(sFile)) to Ctx.asCallLines
            Move 2 to Ctx.iCallKind
        End
        If (iLine > SizeOfArray(Ctx.asCallLines)) ;
            Procedure_Return
        Get MacroExpansionCause of Ctx.hoCall Ctx.asCallLines[iLine - 1] (&sCauseName) to iCauseKind
        If (sCauseName = "") ;
            Procedure_Return
        Move (SearchArray(Lowercase(sCauseName), Ctx.asCauseKey)) to iCauseIdx
        If (iCauseIdx = -1) Begin
            Move (SizeOfArray(Ctx.asCauseKey)) to iCauseIdx
            Move (Lowercase(sCauseName)) to Ctx.asCauseKey[iCauseIdx]
            Move sCauseName              to Ctx.asCauseName[iCauseIdx]
            Move iCauseKind              to Ctx.aiCauseKind[iCauseIdx]
            Move sFile                   to Ctx.asCauseFile[iCauseIdx]
            Move iLine                   to Ctx.aiCauseLine[iCauseIdx]
            Move 0                       to Ctx.aiCauseCount[iCauseIdx]
        End
        Move (Ctx.aiCauseCount[iCauseIdx] + iOcc) to Ctx.aiCauseCount[iCauseIdx]
    End_Procedure

    // One group heading inside the Breaks-the-build band: the label, then what a row in it offers.
    Function _BreakGroupHeadHtml String sTitle String sSub Returns String
        Function_Return ((DivOpen("fgrp")) + sTitle + (SpanOpen("fgrp-s")) + ' ' + CS_EmDash + ' ' + sSub + CS_SpanEnd + CS_DivEnd)
    End_Function

    /* THREE GROUPS, NAMED (Nils 2026-09-03: the band, opening on a stack of "Rename the calls...",
       "Rewrite as Get...", Check declarations x5, "Guard them", "Rename it..." and "Show
       declarations", was "hard to read"). Same rows, same order - now under a heading each that
       says what a row in it offers: FIX FROM HERE (the filled chip on the row writes source or
       offers the change after a scan - the write-source finding rows, the 4544 names, then the
       4390 names) and INFORMATION ONLY (the compiler's other errors, fixed by hand). A LOOK FIRST
       group held the 4544 family for a few hours on 2026-09-03, until Nils: "it doesn't seem
       helpful to check something instead of doing something about the problem" - the names now
       carry their fix. A heading is emitted only when the band holds MORE than one group - a
       single group under a label is noise. Assembles Ctx.sBreak from the parts; the descriptive
       rows already sit in it when this runs. */
    Procedure _GroupBreakBand tFindingsCtx ByRef Ctx String sAmbRows String sRepRow
        String sFix sOut
        Integer iGroups

        // Write-source rows, then the 4544 names (each with its Fix it...), then the 4390 names.
        Move (Ctx.sBreakAct + sAmbRows + sRepRow) to sFix
        Move 0 to iGroups
        If (sFix <> "") ;
            Increment iGroups
        If (Ctx.sBreak <> "") ;
            Increment iGroups
        Move "" to sOut
        If (sFix <> "") Begin
            If (iGroups > 1) ;
                Move (sOut + (_BreakGroupHeadHtml(Self, "Fix from here", "the button on the row changes the source, or offers the change after a scan"))) to sOut
            Move (sOut + sFix) to sOut
        End
        If (Ctx.sBreak <> "") Begin
            If (iGroups > 1) ;
                Move (sOut + (_BreakGroupHeadHtml(Self, "Information only", "the compiler's other errors, fixed by hand at the line"))) to sOut
            Move (sOut + Ctx.sBreak) to sOut
        End
        Move sOut to Ctx.sBreak
    End_Procedure

    /* The name-collision signal, split by MESSAGE - the two halves END DIFFERENTLY, so each gets its
       own actionable rows leading Breaks-the-build: 4544 (ambiguous return type) opens a REPORT,
       because renaming or type-aligning declarations is human judgement; 4390 (already defined)
       offers the guard / rename, because version-guarding a home-brewed global is mechanical. A row
       per NAME is the whole point: the cause is a handful of declarations, and a lump sum of 220
       hides that completely.

       CHECK DECLARATIONS FIRST (Nils 2026-08-17: "both Check declarations - that actually do
       something - buttons are in the list together with Show declarations - which doesn't change
       anything. How about always showing the Check declarations buttons at the top, just like we do
       for Auto fixing?"). The 4544 name rows lead the band; the 4390 rows follow.

       THE BAND'S ORDER, TOP DOWN (Nils 2026-08-19): rows whose button WRITES SOURCE (Ctx.sBreakAct,
       collected by the row build - a "Rename the calls..." pair used to sit wherever its finding
       happened to fall in analyzer order, under a dozen rows offering nothing), then these report
       rows that name the declarations behind a flood, then the rows that only describe. Since
       2026-09-03 the three parts carry a heading each (_GroupBreakBand); the 4390 names join the
       write-source group, every one of them now carrying a filled chip. */
    Procedure _AddCollisionRows Handle hoGrid tFindingsCtx ByRef Ctx
        String[]  asAmbNames asBackNames asAmbForeign asAmbFirst
        Integer[] aiAmbCounts aiBackCounts aiAmbOwn aiAmbFirst
        Boolean[] abGuardable abExternal
        String[][]  asSiteFiles
        Integer[][] aiSiteLines
        String  sRepRow sAmbRows
        Integer iRetType iBackport

        Get piSumReturnTypeErr of hoGrid to iRetType
        Get piSumBackportErr   of hoGrid to iBackport
        Get pasAmbiguousFnNames of hoGrid to asAmbNames
        Get paiAmbiguousCounts  of hoGrid to aiAmbCounts
        Get paiAmbiguousOwnSites of hoGrid to aiAmbOwn
        Get pasAmbiguousForeignFile of hoGrid to asAmbForeign
        Get pasAmbiguousFirstFile of hoGrid to asAmbFirst
        Get paiAmbiguousFirstLine of hoGrid to aiAmbFirst
        Get pasBackportNames    of hoGrid to asBackNames
        Get paiBackportCounts   of hoGrid to aiBackCounts
        Get pabBackportGuardable of hoGrid to abGuardable
        Get pabBackportExternal  of hoGrid to abExternal
        Get pasBackportSiteFiles of hoGrid to asSiteFiles
        Get paiBackportSiteLines of hoGrid to aiSiteLines
        Get _BackportNameRowsHtml asBackNames aiBackCounts abGuardable abExternal ;
                                  asSiteFiles aiSiteLines asAmbNames ;
                                  (&Ctx.sPeekBreak) (&Ctx.iBreak) to sRepRow
        // (The 4544 lump row for a message shape that yields no name lives in the helper now.)
        Get _AmbiguousNameRowsHtml asAmbNames aiAmbCounts aiAmbOwn asAmbForeign asAmbFirst aiAmbFirst iRetType (&Ctx.sPeekBreak) (&Ctx.iBreak) to sAmbRows
        // Fallback: 4390s exist but the compiler text did not yield a name (an unexpected message
        // shape). Better a lump row than silently dropping them from the list.
        If (SizeOfArray(asBackNames) = 0 and iBackport > 0) Begin
            Move (sRepRow + (FindingRepOpen("e")) + ('compiler' + CS_SpanEnd) + (FindingMsg("E 4390"))) to sRepRow
            Move (sRepRow + ((SpanOpen("ffile")) + 'Names DataFlex already uses (') + String(iBackport) + (')' + CS_SpanEnd)) to sRepRow
            Move (sRepRow + (HintCell(Self, "A declaration here uses a name DataFlex already provides."))) to sRepRow
            Move (sRepRow + (ChipHtml("fact", "fact off", "guardglobals", "", "Guard them", "", True)) + CS_DivEnd) to sRepRow
            Increment Ctx.iBreak
        End
        // Fix from here (write-source rows, then the 4390 names), Look first (4544), Information only (the rest).
        Send _GroupBreakBand (&Ctx) sAmbRows sRepRow
    End_Procedure

    /* THE HALT BANNER NAMES ITS FILES (Nils 2026-10-12, on a workspace whose board held thousands
       of rows; the banner ended "See the FlexCOM row below": "As the grid holds thousands of items
       it is near impossible to find the FlexCOM row"). A pointer into a list that long is no
       pointer. The banner now carries what the row was wanted for: one button per halting file,
       which opens the editor at the line that uses FlexCOM.pkg - the jump the row itself makes.
       The row stays where it was, counted and dismissable as before.

       The buttons stand on a line of their own under the sentence (tiles.css: .fhalt .fact);
       written inline after it, a second row of them ran into the text above.

       A CAP THAT SAYS WHAT IT LEFT OUT: beyond CI_FlexComHaltChips files the banner counts the
       rest and says where every one of them is listed - as DS 9220 under Needs hand migration,
       which is where _BuildFindingRow sends an Explain row that has no function. */
    Function _FlexComHaltHtml String[] asFile Integer[] aiLine Returns String
        String  sOut sLeaf sTip
        Integer i iCount iShown iPos

        Move (SizeOfArray(asFile)) to iCount
        If (iCount <= 1) ;
            Move " - a FlexCOM-era COM proxy blocks every run. Re-generate it (Studio: Import COM Object Library), then press Check again." to sOut
        Else ;
            Move (" - " + String(iCount) + " FlexCOM-era COM proxies block every run. Re-generate them (Studio: Import COM Object Library), then press Check again.") to sOut
        Move ((DivOpen("fsysover fhalt")) + (BoldHtml("Refactoring is HALTED")) + sOut) to sOut
        If (iCount = 0) ;
            Function_Return (sOut + CS_DivEnd)
        Move (sOut + CS_Br + (If(iCount = 1, "The file:", "The files:"))) to sOut
        Move iCount to iShown
        If (iShown > CI_FlexComHaltChips) ;
            Move CI_FlexComHaltChips to iShown
        For i from 0 to (iShown - 1)
            Move asFile[i] to sLeaf
            Move (RightPos("\", sLeaf)) to iPos
            If (iPos > 0) ;
                Move (Right(sLeaf, (Length(sLeaf) - iPos))) to sLeaf
            // A file with no line (never seen, but the row itself would not be a link either) is named, not linked.
            If (aiLine[i] > 0) Begin
                Move ("Opens the editor at line " + String(aiLine[i]) + " of " + asFile[i] + ", where the file uses FlexCOM.pkg. The file is also listed as DS 9220 under Needs hand migration.") to sTip
                Move (sOut + " " + (ChipHtml("fact alt", "fact alt off", "opensrc", (asFile[i] + '|' + String(aiLine[i])), (HtmlEscaped(Self, (sLeaf + " (" + String(aiLine[i]) + ")"))), (HtmlEscaped(Self, sTip)), True))) to sOut
            End
            Else ;
                Move (sOut + " " + (SpanOpen("fsysfiles")) + (HtmlEscaped(Self, sLeaf)) + CS_SpanEnd) to sOut
        Loop
        If (iCount > iShown) ;
            Move (sOut + " and " + String(iCount - iShown) + " more. All of them are listed as DS 9220 under Needs hand migration.") to sOut
        Function_Return (sOut + CS_DivEnd)
    End_Function

    /* THE EXECUTE PATH (Nils 2026-07-23: rows navigate fine, but "it is unclear how to execute
       them"): the plan-capable bands lead with ONE action row that opens the Refactoring Plan
       dialog - the same StartAutoSelect the dock's Refactor Plan action calls, built from these very
       grid rows (plan-from-rows), so what the dialog lists is exactly what is on screen here. The
       dialog is the confirm surface: review, deselect, then run - nothing is touched by this click
       itself. Shown at the top of Auto-fixable, and at the top of Review whenever Review has
       runnable rows (Review rows ride in the same plan, unticked while Auto rows exist).

       BOTH UNITS, NAMED (Nils 2026-08-17: "1929" here against "1451 Files" in the run's start
       question - "one of those numbers must be wrong"). Neither was: this line counts FINDINGS (one
       per file x message), the run counts FILES it opens - and the run's set is larger than the
       files behind these rows, because a ticked function runs over every row that names it (Review
       rows too) plus a collapsed scan rule's whole file list. So the line says findings AND the
       files those findings sit in, and the hint says where the run's own file list is.

       THE HALT OUTRANKS THE PLAN (Nils 2026-08-27: after the FlexCOM halt landed, the board still
       opened with "Run the refactoring plan" - inviting a run the engine now refuses with a message
       box. Offering work that cannot start is worse than offering nothing). While DS 9220 stands,
       the plan rows are withheld and the banner says why and names the files (_FlexComHaltHtml);
       the Explain row carries the full guidance. The banner is NOT a band member (Nils 2026-08-30:
       "it looks weird that it is part of the 'Auto-fixable' section, as it clearly is not") - it
       is emitted ABOVE every band, beside the system-override warning, because a band groups
       findings by what you can DO about them, and a halt is a precondition, not a category of
       finding.

       THE PLAN GOES ABOVE THE ERRORS WHEN ONLY REVIEW CARRIES IT (Nils 2026-11-05: "Breaks the build" stands at
       the top of the board and takes over the impression of what to do next, with the plan in a closed band
       further down). With nothing in Auto-fixable and a band of errors above Review, the Review lead leaves its
       band and goes above every band, in a box of its own. Breaks the build itself never carries a plan row: a
       fixable error is routed to Auto-fixable or Review. With Auto rows the plan already stands first, and with
       no errors Review is the first band to open, so its lead stays where it is. Every band starts closed under
       the lifted row (_AppendBands), or the open errors would take over again.

       NOT plan-runnable: every Review row names only report functions (or no function at all), and
       reports are excluded from plan runs. Offering the plan anyway sent the user round a loop with
       no exit - the plan came back empty, its dialog blamed a stale list and said "run Check
       again", and Check produced the very same screen (Nils 2026-07-26). Never offer a plan that is
       already known to be empty; state what these rows actually need instead. */
    Procedure _AddPlanLeadRows tFindingsCtx ByRef Ctx String ByRef sTopRow String ByRef sReviewLead
        String sTop sLead sMore sHint

        Move "" to sTop
        Move "" to sLead
        // The rows that lead the Auto-fixable band (LeadsAutoBand) go above its other rows here,
        // before the plan line goes above them all.
        If (Ctx.sAutoLead <> "") Begin
            Move (Ctx.sAutoLead + Ctx.sAuto) to Ctx.sAuto
            Move "" to Ctx.sAutoLead
        End
        If (Ctx.bFlexComHalt = True) ;
            Get _FlexComHaltHtml Ctx.asHaltFile Ctx.aiHaltLine to sTop
        If (Ctx.bFlexComHalt = False and Ctx.iAuto > 0) Begin
            /* BOTH COUNTS ON THE ONE LINE (Nils 2026-09-03): the Review band's runnable rows ride in
               this same plan, listed unticked, and a lead that named only the Auto count sent him
               through a run, a Check and a fold before the two WinServ rows' fix turned up. */
            Move "" to sMore
            Move "The plan shows exactly what runs before anything is changed, and lists every file it will open - a ticked function runs over each file that names it." to sHint
            If (Ctx.iReviewRun > 0) Begin
                Move (' ' + CS_EmDash + ' ' + String(Ctx.iReviewRun) + ' more wait in Review') to sMore
                Move (sHint + " The Review band's " + String(Ctx.iReviewRun) + " runnable finding(s) are in the same plan, unticked: look at them first, then tick their functions - here or from Review.") to sHint
            End
            Move ((FindingRepOpen("w")) + ('plan' + CS_SpanEnd + (SpanOpen("fmsg"))) + String(Ctx.iAuto) + ' finding(s) in ' + String(SizeOfArray(Ctx.asAutoFiles)) + ' file(s) convert automatically' + sMore + CS_SpanEnd + (HintCell(Self, sHint)) + (ChipHtml("fact", "fact off", "runplan", "", "Run the refactoring plan", "", True)) + CS_DivEnd) to Ctx.sRow
            Move (Ctx.sRow + Ctx.sAuto) to Ctx.sAuto
        End
        /* REVIEW KEEPS ITS OWN LEAD whenever it has runnable rows - no longer only when Auto-fixable
           is empty (until 2026-09-03 the Review plan was invisible behind a non-empty Auto band).
           Same chip, same dialog: with Auto rows on the board these are listed there unticked. */
        If (Ctx.bFlexComHalt = False and Ctx.iReviewRun > 0) Begin
            Move "The plan shows exactly what runs before anything is changed, and lists every file it will open - a ticked function runs over each file that names it." to sHint
            If (Ctx.iAuto > 0) ;
                Move (sHint + " With auto-fixable rows on the board these are listed UNTICKED: look at the row, then tick its function.") to sHint
            Move (Ctx.iAuto = 0 and (Ctx.iBreak > 0 or Ctx.iOutsideErr > 0)) to Ctx.bPlanOnTop
            If (Ctx.bPlanOnTop = True) ;
                Move (sHint + " These findings are listed under Review. Running the plan first can also clear rows under Breaks the build.") to sHint
            Move ((FindingRepOpen("w")) + ('plan' + CS_SpanEnd + (SpanOpen("fmsg"))) + String(Ctx.iReviewRun) + ' finding(s) in ' + String(SizeOfArray(Ctx.asReviewFiles)) + (' file(s) to review' + CS_SpanEnd) + (HintCell(Self, sHint)) + (ChipHtml("fact", "fact off", "runplan", "", "Run the refactoring plan", "", True)) + CS_DivEnd) to Ctx.sRow
            If (Ctx.bPlanOnTop = True) ;
                Move ((DivOpen("fplantop")) + Ctx.sRow + CS_DivEnd) to sTop
            Else ;
                Move Ctx.sRow to sLead
        End
        Else If (Ctx.iReview > 0) Begin
            Move ((FindingRepOpen("w")) + ('review' + CS_SpanEnd + (SpanOpen("fmsg"))) + String(Ctx.iReview) + (' row(s) to review' + CS_SpanEnd)) to Ctx.sRow
            Move (Ctx.sRow + (HintCell(Self, (('Nothing here converts automatically ' + CS_EmDash) + ' these need a person, not a converter: open a row to look at the source, and dismiss it once judged.'))) + CS_DivEnd) to Ctx.sRow
            Move Ctx.sRow to sLead
        End
        Move sTop to sTopRow
        Move sLead to sReviewLead
    End_Procedure

    /* BULK DISMISSAL ROWS, one per function, at the head of EACH band that has non-runnable rows -
       and rendered into the band the rows actually live in. The first cut tallied both bands
       together and emitted the whole set into ONE, so a function whose findings sat in
       Needs-hand-migration got its button rendered under Review; clicking it emptied Review and
       left 1,446 hand rows untouched, which is exactly what a dismissal control must never do: act
       somewhere other than where it appears (Nils 2026-07-28). Emitted as SIBLINGS of the finding
       rows, never nested inside one: a cWebHtmlBox click fires EVERY ancestor's ServerOnClick.

       Review contributes only when a plan run would NOT act on the rows - a family the plan can
       still convert is never dismissable from here; that work belongs to the plan. The PACKAGE
       groups are NOT behind that gate: an obsolete install package the workspace legitimately still
       uses has no fix at all, so waiting for the plan to empty would withhold it for ever.

       A SUMMARY MUST TOUCH THE ROWS IT SUMMARISES. The band holds two populations: the rows a plan
       run would act on, announced by the lead row and actioned by its button - and the rows it
       would not, collected into the dismissal groups. So the order is lead, its own rows, then the
       groups. Corrected twice in one day, each time on a real reading of the board (Nils: "the
       order should first be the Run plan button and only then the Ignore all", then "this is what
       fouled me" when the groups sat BETWEEN the plan line and the findings it counts). */
    Procedure _AddReviewDismissals tFindingsCtx ByRef Ctx String sReviewLead
        String sDisRows sPkgRows

        Move "" to sDisRows
        If (Ctx.iReviewRun = 0) ;
            Get DismissRowsHtml (&Ctx.asRevFn) (&Ctx.aiRevCount) (&Ctx.asRevHint) (&Ctx.asRevRows) "F" to sDisRows
        Get DismissRowsHtml (&Ctx.asRevPkgKey) (&Ctx.aiRevPkgCount) (&Ctx.asRevPkgHint) (&Ctx.asRevPkgRows) "U" to sPkgRows
        Move (sDisRows + sPkgRows) to sDisRows
        If (sDisRows <> "") ;
            Move ((DismissNoteHtml(Self)) + sDisRows) to sDisRows
        Move (sReviewLead + Ctx.sReview + sDisRows) to Ctx.sReview
    End_Procedure

    // The hand-migration band keeps its groups at the HEAD, and rightly: there the groups ARE the
    // content, and no summary row is waiting to be read with them.
    Procedure _AddHandDismissals tFindingsCtx ByRef Ctx
        String sDisRows sPkgRows

        Get DismissRowsHtml (&Ctx.asHandFn) (&Ctx.aiHandCount) (&Ctx.asHandHint) (&Ctx.asHandRows) "M" to sDisRows
        // The package groups (_RouteHandPkgRow) lead: each names its way on, a converter for the grid
        // families. Dismissed per package file (U), like the Review band's.
        Get DismissRowsHtml (&Ctx.asHandPkgKey) (&Ctx.aiHandPkgCount) (&Ctx.asHandPkgHint) (&Ctx.asHandPkgRows) "U" to sPkgRows
        Move (sPkgRows + sDisRows) to sDisRows
        If (sDisRows <> "") ;
            Move ((DismissNoteHtml(Self)) + sDisRows + Ctx.sHand) to Ctx.sHand
    End_Procedure

    /* Record this render's verdict for the steps tile (see the property block). ACTIONABLE is what
       the tool can still do - Review rows count only when a plan run would execute them or a report
       would list them, so a board of reports-only reads as "nothing left for the tool", which is
       the truth.

       AN EMPTY GRID IS ONLY A VERDICT IF SOMETHING FILLED IT (Nils 2026-07-29: restarted, picked
       the workspace, and got a board saying all 106 findings were hidden with "Open Tidy Up" lit -
       without having restored anything). The rows come from the analyzer grid, and on a fresh start
       that grid is EMPTY: no Check has run and no saved plan has been loaded. Writing actionable =
       0 there told every consumer "the tool has nothing left to do" - so Tidy Up lit up and the
       board declared a result it had never computed. -1 is the "not looked yet" value the property
       was born with; the fix is simply to stop overwriting it with a number derived from nothing.
       Both surfaces gate on it: the stepper needs = 0 for stage 2, NextStepHtml needs = 0 to light
       Tidy Up. bLooked comes back for the empty-board wording, which draws the same line. */
    Procedure _PublishRenderVerdict Integer iTotal Integer iRows tFindingsCtx ByRef Ctx Boolean ByRef bLooked
        Boolean bSeen

        Move (piChkTickAnalyze(ghoApplication) <> 0 or Trim(psLastPlanStamp(Self)) <> "") to bSeen
        // piChkListed EXCLUDES the packages band: the verdict dialog's "N need a person ... a report
        // can list every place" sentence describes Review/hand rows, and a read-only package row is
        // neither - the dialog names those separately from piChkOutsideErr.
        Set piChkListed to (iTotal - Ctx.iOutside)
        Set piChkOutsideErr to Ctx.iOutsideErr
        Set piChkReviewRows   to Ctx.iReview
        Set piChkReviewPkg    to Ctx.iReviewPkg
        Set piChkHandRows     to Ctx.iHand
        Set piChkHiddenReport to Ctx.iHiddenReport
        Set piChkHiddenFn     to Ctx.iHiddenFn
        If (bSeen = False and iRows = 0) ;
            Set piChkActionable to -1
        Else ;
            /* A REVIEW ROW IS NOT DONE (Nils 2026-09-04: "There should be NO dialog until the Review
               section is empty! Why should there be?"). Until now only the RUNNABLE review rows and
               the report rows counted, so ten obsolete-package rows waiting for a judgement left
               the trail saying stage 2 was finished, Tidy Up lit, and the done dialog speaking over a
               Review band with rows in it. Every row the Review band lists now holds the stage open;
               it closes when the user has converted, run or dismissed them.

               AND NEITHER IS A BY-HAND ROW (Nils 2026-09-13). Until today the by-hand band did not
               hold the stage - "that list is outside the tool's reach by definition" - so a Check
               that left 68 by-hand rows announced "0 of 68 can be fixed automatically ... Tidy Up is
               the next stage" over a band of work still to do, and the stepper called stage 2
               finished. The tool cannot do those changes, but the PERSON has not done them either,
               and the stage is the person's as much as the tool's. So every visible row on the
               board now holds it: the stage closes when the user has converted, run, changed by hand
               or dismissed them. Hidden rows never counted, and still do not - dismissing is a
               deliberate "this is fine", and it is named on the Ready line instead. */
            Set piChkActionable to (Ctx.iBreak + Ctx.iAuto + Ctx.iReview + Ctx.iHand)
        Move bSeen to bLooked
    End_Procedure

    /* THE FINDINGS HEADER: the count, the chips that qualify it, the lanes note, the
       program-changed note and the Clear board row - appended to sHtml.

       THE WAY BACK. A dismissal that cannot be undone is a trap, and these rows are deferred WORK,
       not noise - so the count of what is hidden, and the button that restores it, live in the
       header where they are visible without hunting. COUNT FINDINGS, NOT IGNORE-LIST ENTRIES (Nils
       2026-08-10: "Ignore all 22" left the header reading "9 hidden"): the ignore list is keyed by
       (file, message) and DEDUPED, so 22 findings that share files and message numbers collapse to
       9 entries - a true number, of the wrong thing. piSumIgnored on the analyzer grid is the
       dismissed-ROW count. The list size still decides whether to OFFER the way back, because it
       outlives the rows - see _HeaderChipsHtml.

       THE TWO LANES HAVE DIFFERENT REACH, AND THE BOARD HAS TO SAY SO. Rows have always been badged
       scan / compiler, but nothing stated what that means for coverage - so a user who switched
       main program saw half the board change and could only read it as the scan having missed
       something (Nils 2026-07-30). Said once, under the header; and when this board is for a
       DIFFERENT program than the last one, say so outright instead of making them infer it from a
       changed row count. (The other programs' health is NOT restated here any more - it lives in
       the Check verdict dialog, Nils 2026-08-30.)

       THE WAY OUT, AT THE TOP (Nils 2026-08-27, twice: first "there should be a way to clear the
       dashboard grid", then "the chip should be placed at the top of the grid" - at the tail it was
       below a fold of rows, invisible on exactly the boards that need it most). Only when there are
       rows; an empty board has nothing to clear. */
    Procedure _AppendFindingsHeader tFindingsCtx ByRef Ctx Integer iTotal String sSilentChip ;
                                    String sMainProg String sMainEsc ;
                                    String ByRef sHtml Integer ByRef iIgnored Boolean ByRef bHavePlan
        String  sOut sIgnChip sPlanChip sSysChip sSkipChip
        Integer iIgn
        Boolean bPlan

        Send _HeaderChipsHtml (&sIgnChip) (&sPlanChip) (&sSysChip) (&sSkipChip) (&iIgn) (&bPlan) Ctx.iSysListed
        Move iIgn  to iIgnored
        Move bPlan to bHavePlan
        Move (TileCss(Self) + (((DivOpen("fwrap")) + (DivOpen("fhead")) + 'Findings ') + (SpanOpen("n"))) + String(iTotal) + CS_SpanEnd + sIgnChip + sSkipChip + sSilentChip + sSysChip + sPlanChip + (CheckPhaseHtml(Self)) + CS_DivEnd) to sOut
        If (iTotal > 0) Begin
            Move (sOut + (DivOpen("flanes")) + (BoldText("compiler")) ;
                + ' findings come from building ' + (BoldHtml(sMainEsc)) ;
                + ' and cover only the files it includes; ' + (BoldText("scan")) ;
                + ' findings cover every selected folder, whatever the program.') to sOut
            If (Trim(psLastFindingsProgram(Self)) <> "" and Trim(psLastFindingsProgram(Self)) <> sMainProg) ;
                Move (sOut + (CS_Br + (SpanOpen("flanenew")) + 'Program changed from ') ;
                    + (BoldHtml(HtmlEscaped(Self, psLastFindingsProgram(Self)))) + ' ' + CS_EmDash + (' the compiler half of this list is for a different set of files than last time.' + CS_SpanEnd)) to sOut
            Move (sOut + CS_DivEnd) to sOut
        End
        If (iTotal > 0) ;
            Move (sOut + ((FindingRepOpen("w")) + ('clear' + CS_SpanEnd + (SpanOpen("fmsg"))) ;
                + ('Done with this list, or starting over?' + CS_SpanEnd) ;
                + (ChipHtml("fact alt", "fact alt off", "clearboard", "", "Clear board", "", True)) + CS_DivEnd)) to sOut
        Move sOut to sHtml
    End_Procedure

    /* THE EMPTY BOARD - four honest states, each ending in the next step (the Tidy Up button used
       to vanish with the last finding; NextStepHtml is emitted on every path out - Nils 2026-07-29:
       "there is no button to 'Tidy up' again?"). Returns everything after the header, including
       the close of .fwrap.

       HONEST empty state: "No findings - Nice" is only true when the analyzer really has nothing;
       if its grid is holding rows that did not classify into any band, saying "Nice" hides a
       disagreement between the two surfaces instead of reporting it (Nils 2026-07-26). piSumVisible
       is what the grid itself shows, so the two counts are directly comparable.

       AN EMPTY BOARD BEFORE ANYTHING RAN SAYS SO, and says it BEFORE the hidden-count branch - which
       reads the ignore list off DISK and would otherwise announce "all 106 are hidden" over a board
       that was never filled. AN EMPTY BOARD YOU EMPTIED IS NOT A CLEAN ONE (Nils 2026-07-29: hid
       the last two hand-migration groups, restarted, restored the Check, and got "No findings ...
       Nice." - "a tad confusing, to be honest"): say what is true, with the way back in the same
       sentence.

       THE WARNING OUTRANKS THE CONGRATULATION. A board can be clean BECAUSE the compiler read the
       wrong DataFlex - the override is still there, and "Nice" over the top of it is the worst
       thing this screen could say. It goes first, so the good news arrives underneath it qualified
       rather than instead of it. The congratulation is for the program the Check compiled ("in this
       scope"); the other projects' health is stated once, in the Check verdict dialog. */
    Function _EmptyBoardHtml Handle hoGrid Boolean bLooked Boolean bHavePlan Integer iIgnored String sTopRow Returns String
        String sOut
        Integer iVisible

        Get piSumVisible of hoGrid to iVisible
        If (iVisible > 0) Begin
            Move (((DivOpen("fclean")) + 'The analyzer grid is holding ') + String(iVisible) + ' row(s) that did not classify into any band here ' + CS_EmDash + ((' the two views disagree, so this list is not trustworthy. Run ' + (BoldText("Check")) + ' to rebuild both from one pass.') + CS_DivEnd)) to sOut
            Function_Return (sOut + (NextStepHtml(Self)) + CS_DivEnd)
        End
        If (bLooked = False) Begin
            Move ((DivOpen("fclean fmuted")) ;
                + 'Nothing examined yet in this session.' + CS_Br ;
                + (SpanOpen("fsub")) ;
                + 'This board is empty because no Check has run, not because the workspace is clean.' ;
                + CS_SpanEnd) to sOut
            If (bHavePlan = True) ;
                Move (sOut + CS_Br + (ChipHtml("fact spaced", "fact spaced off", "showlastplan", "", "Show last Check", "", True))) to sOut
            Move (sOut + CS_DivEnd) to sOut
            Function_Return (sOut + (NextStepHtml(Self)) + CS_DivEnd)
        End
        If (iIgnored > 0) Begin
            Move ((DivOpen("fclean fmuted")) ;
                + 'Nothing left to show ' + CS_EmDash + ' but nothing was found clean either.' + CS_Br ;
                + (SpanOpen("fsub")) ;
                + 'All ' + String(iIgnored) + ' finding(s) in this scope are hidden. The work is still outstanding.' ;
                + CS_SpanEnd + CS_Br ;
                + (ChipHtml("fact spaced", "fact spaced off", "clearignored", "", "Show them again", "", True)) ;
                + CS_DivEnd) to sOut
            Function_Return (sOut + (NextStepHtml(Self)) + CS_DivEnd)
        End
        Move ((_SysOverrideWarningHtml(Self)) + sTopRow) to sOut
        Move (sOut + ((DivOpen("fclean")) + CS_Check + CS_Nbsp + ' No findings ' + CS_EmDash + (' nothing flagged in this scope. Nice.' + CS_DivEnd))) to sOut
        Function_Return (sOut + (NextStepHtml(Self)) + CS_DivEnd)
    End_Function

    /* THE BANDS, in the order the board argues them, appended to sHtml with the board's ending.

       AUTO-FIXABLE FIRST (Nils 2026-08-16: "It is daunting to see a long list that breaks the
       build, and those tend to catch the focus of the user, that might never even see the
       Auto-Fixable that removes most, if not all of them"). The board's question is "what do I do
       next", and the next action is the plan - so the band that carries "Run the refactoring plan"
       leads and opens by default. Breaks-the-build only ever holds errors WITHOUT an auto-fix (a
       fixable error is routed to Auto-fixable), and after a plan run + recompile a good share of
       those cascades are gone anyway; it comes second, still red, still counted. First non-empty
       band in THIS order opens; the rest stay collapsed with a peek.

       THE PACKAGES BAND RANKS BY WHAT IT HOLDS (Nils 2026-08-30: "it would make more sense to have
       the In packages (read-only) below the Review ... because there is nothing that can be done
       about those lines anyway"). True of WARNINGS, and they are the usual content: the rows belong
       to a package this workspace only consumes, so no run and no person here can clear them - that
       ranks them below EVERY band the user can act on, Needs-hand-migration included. NOT true of
       ERRORS: an error inside a pool package stops this build exactly as hard as one in own code,
       so the band keeps its place behind Breaks-the-build whenever it carries one, and sinks to the
       bottom only when it is warnings-only. The auto-open reads the same signal (iOutsideErr) -
       and NOTHING OPENS WHEN ONLY THE READ-ONLY BAND HAS CONTENT (Nils 2026-08-30: after the cycle
       was exhausted and Tidy Up had run, the board "ended by expanding the In packages (read-only)
       again ... hardly necessary"): unfolding rows nobody here can act on, at the moment the user
       finishes, reads as more work when there is none.

       NOTHING OPENS UNDER A PLAN ROW THAT STANDS ABOVE THE BANDS (Nils 2026-11-05): the next action is that
       row, and an open band of errors or a long Review list would take over from it. Each band keeps its
       count and its peek.

       THE BOARD NEEDS AN ENDING (Nils 2026-07-29: "I would first like to see the continuation after
       'Needs hand migration' and a 'Tidy up' button at the very end"). The trail's stepper promises
       four stages and the list stopped dead at the third; NextStepHtml is that answer. */
    Procedure _AppendBands tFindingsCtx ByRef Ctx String sTopRow String ByRef sHtml
        String sOut sOutBand sOpenBreak sOpenAuto sOpenReview sOpenHand sOpenOutside

        Move sHtml to sOut
        If (Ctx.bPlanOnTop = False) Begin
            If (Ctx.iAuto > 0) ;
                Move " open" to sOpenAuto
            Else If (Ctx.iBreak > 0) ;
                Move " open" to sOpenBreak
            Else If (Ctx.iOutsideErr > 0) ;
                Move " open" to sOpenOutside
            Else If (Ctx.iReview > 0) ;
                Move " open" to sOpenReview
            Else If (Ctx.iHand > 0) ;
                Move " open" to sOpenHand
        End
        // ABOVE EVERY BAND. Not a finding but a precondition on all of them - see
        // _SysOverrideWarningHtml for why it does not fold into one.
        Move (sOut + (_SysOverrideWarningHtml(Self))) to sOut
        Move (sOut + sTopRow) to sOut
        Move (BandHtml(Self, "b-out", "In packages (read-only)", Ctx.iOutside, Ctx.sPeekOutside, sOpenOutside, Ctx.sOutside)) to sOutBand
        Move (sOut + (BandHtml(Self, "b-auto",   "Auto-fixable",         Ctx.iAuto,   Ctx.sPeekAuto,   sOpenAuto,   Ctx.sAuto)))   to sOut
        Move (sOut + (BandHtml(Self, "b-break",  "Breaks the build",     Ctx.iBreak,  Ctx.sPeekBreak,  sOpenBreak,  Ctx.sBreak)))  to sOut
        If (Ctx.iOutsideErr > 0) ;
            Move (sOut + sOutBand) to sOut
        Move (sOut + (BandHtml(Self, "b-review", "Review",               Ctx.iReview, Ctx.sPeekReview, sOpenReview, Ctx.sReview))) to sOut
        Move (sOut + (BandHtml(Self, "b-hand",   "Needs hand migration", Ctx.iHand,   Ctx.sPeekHand,   sOpenHand,   Ctx.sHand)))   to sOut
        If (Ctx.iOutsideErr = 0) ;
            Move (sOut + sOutBand) to sOut
        Move (sOut + (NextStepHtml(Self)) + CS_DivEnd) to sOut
        Move sOut to sHtml
    End_Procedure

    /* The guided Check result: ONE severity-ranked findings list built from the analyzer grid's
       classified rows (BuildSavedPlanRowsVisible - ALL categories, compiler + Deep Scan combined),
       in foldable bands, first non-empty open. The pieces are listed at the head of this family. */
    Function FindingsListHtml Returns String
        tFindingsCtx Ctx
        tSavedPlanRow[] aRows aAllRows
        Boolean[] abIgn
        String  sHtml sTopRow sReviewLead sSilentChip sScanBadge sCompBadge sMainProg sMainEsc sTail sHidFn sNotice
        Integer i iLast iTotal iIgnored iH iHLast
        Handle  hoFnDD hoGrid
        Boolean bLooked bHavePlan bRep

        If (ghoModAnalyzerDock = 0) ;
            Function_Return (TileCss(Self) + ((DivOpen("fwrap")) + (DivOpen("ph")) + ('Run a ' + (BoldText("Check")) + ' to see findings ')) + CS_EmDash + (' one list, what to do next first.' + CS_DivEnd) + CS_DivEnd)
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        // VISIBLE rows only: the full builder keeps DISMISSED (Ignore) rows for the saved-plan JSON,
        // but showing them here resurrects rows the grid hides - and offers a plan that will be empty
        // (the 95 dismissed W 4533 rows shown as Auto-fixable, Nils 2026-07-25).
        Get BuildSavedPlanRowsVisible of hoGrid to aRows
        Send _FindingsBadges (&sScanBadge) (&sCompBadge) (&sMainProg) (&sMainEsc)
        // Report-only functions are filtered out of a plan run, so a Review row that names ONLY
        // reports is not plan-runnable - see RowHasRunnableFunction for why offering the plan
        // anyway dead-ends the user. One DD instance for the whole list (a Find per row is cheap).
        Get Create (RefClass(cFunctionsDataDictionary)) to hoFnDD
        // What the plan already knows about legacy grids, once, for the E 4379 rows' object note.
        Send _CollectLegacyGridFacts (&aRows) (&Ctx)
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            /* PROGRESS, because this loop is the slow half of the board (Nils 2026-08-31). Cause
               attribution READS SOURCE FILES per row (capped, memoed - see Ctx.asCallLines), so a
               few thousand findings is tens of seconds of disk work with nothing on screen. Inert
               outside a Check-driven render - see BoardRenderBeat. */
            If (Mod(i, 50) = 0) ;
                Send BoardRenderBeat ("Check: building the findings list - finding " + String(i + 1) + " of " + String(iLast + 1) + "...")
            /* System (read-only) rows are ROUTED, no longer skipped wholesale (Nils 2026-08-29, the
               "Yikes" - a pool package's E 4539s broke the build while this board said clean).
               _CollectOutsideRow sends a write-protected POOL file's findings to the read-only
               packages band (aggregated per package) and re-points an install 4536 self-deprecation
               at the workspace's own Use line; only DataFlex-install rows with nothing for the user
               to act on stay chip-only, which is what the 2026-07-28 skip ("no point at all to list
               system/native DataFlex packages") was actually about. */
            If (Trim(aRows[i].sCategory) = "System (read-only)") ;
                Send _CollectOutsideRow (&aRows) i sCompBadge (&Ctx)
            // CONTAINS, not equals: a FOLDED macro row leads its hint with the command's own name
            // and carries the shared constant at the end (MacroOriginHint), so an exact match would
            // send exactly the folded rows down the ordinary finding path - the many-call-sites rows
            // this family exists to set aside. An unfolded row still holds the constant alone.
            Else If (Trim(aRows[i].sHint) contains CS_ModMacroExpansionHint) ;
                Send _AttributeMacroCause aRows[i].sFile aRows[i].iLine aRows[i].sLineDisplay (&Ctx)
            Else ;
                Send _BuildFindingRow (&aRows) i hoFnDD sScanBadge sCompBadge (&Ctx)
        Loop
        /* WHAT THE IGNORE CHOICES HID, by what the tool could still do with it (Nils 2026-09-04): the
           dialog behind this render said "for some, a report can list every place first" when every
           report row was hidden - 69 of them, dismissed with Ignore all twelve minutes earlier - and
           the ten rows it could see were obsolete packages. The full row set against the grid's own
           ignore flags (the index-aligned pair BuildSavedPlanRowsVisible filters by), while the
           Functions DD that tells a report from a converter is still here. */
        Get BuildSavedPlanRows of hoGrid to aAllRows
        Get pabIgnoredFull    of hoGrid to abIgn
        Move (SizeOfArray(aAllRows) - 1) to iHLast
        For iH from 0 to iHLast
            If (iH < SizeOfArray(abIgn)) Begin
                If (abIgn[iH] = True) Begin
                    Move (Trim(aAllRows[iH].sFn)) to sHidFn
                    If (sHidFn <> "") Begin
                        Increment Ctx.iHiddenFn
                        Get RowHasRunnableFunction hoFnDD sHidFn to bRep
                        If (bRep = False) ;
                            Increment Ctx.iHiddenReport
                    End
                End
            End
        Loop
        Send Destroy of hoFnDD
        Send _OutsideRowsHtml (&Ctx)
        Send _AddCollisionRows hoGrid (&Ctx)
        If (Ctx.hoCall <> 0) ;
            Send Destroy of Ctx.hoCall
        Send _AddPlanLeadRows (&Ctx) (&sTopRow) (&sReviewLead)
        Send _AddReviewDismissals (&Ctx) sReviewLead
        /* ONE ROW PER NAMED CAUSE, each one linked (Nils 2026-08-19). The old single row said
           "533x Inside macro expansions" with no name and nothing to click - and the label was wrong
           for most of them. Now: the class or macro is NAMED, the count is per cause, and the row
           carries an action - its converter where DFRefactor has one for that class, otherwise the
           definition site. A definition only in the DataFlex install is not the user's to change and
           the row says so instead of linking it. Groups the analyzer could not name keep the honest
           lump row at the end. The system-class chip it returns rides the header. */
        Get _CauseGroupRowsHtml Ctx.asCauseName Ctx.asCauseFile Ctx.aiCauseKind Ctx.aiCauseLine Ctx.aiCauseCount ;
                                Ctx.iCauseCapped Ctx.iMacro (&Ctx.sHand) (&Ctx.iHand) to sSilentChip
        Send _AddHandDismissals (&Ctx)
        // Header count = what is actually LISTED (the collisions collapsed into their name rows;
        // the packages band counts its aggregated rows the same way).
        Move (Ctx.iBreak + Ctx.iAuto + Ctx.iReview + Ctx.iHand + Ctx.iOutside) to iTotal
        Send _PublishRenderVerdict iTotal (SizeOfArray(aRows)) (&Ctx) (&bLooked)
        Send _AppendFindingsHeader (&Ctx) iTotal sSilentChip sMainProg sMainEsc (&sHtml) (&iIgnored) (&bHavePlan)
        // The character-mode notice sits under the header, on the empty board as well as the full one.
        Get _CharModeNoticeHtml to sNotice
        Move (sHtml + sNotice) to sHtml
        Set psLastFindingsProgram to sMainProg
        If (iTotal = 0) Begin
            Get _EmptyBoardHtml hoGrid bLooked bHavePlan iIgnored sTopRow to sTail
            Function_Return (sHtml + sTail)
        End
        Send _AppendBands (&Ctx) sTopRow (&sHtml)
        Function_Return sHtml
    End_Function

    Object oWebHost is a cFTDbLocalWebControlHost
        Set Size to 438 596
        Set Location to 0 2
        Set piColumnCount to 12
        Set peAnchors to anAll
        Set Main_DD to oSysFile_DD
        Set Server  to oSysFile_DD

        /* THE WORKSPACE CRUMB, where the workspace TILE used to be (Nils 2026-08-06).

           Selecting a workspace is the Start Center's job now (StartCenterFT.vw), so this board no
           longer carries the banner, the recent chips or the .sws Open dialog. What it must still
           carry is the answer to "which workspace am I in, and how do I leave" - that is the crumb,
           shared markup so both boards say it identically (ghoTileMarkup).

           Rendered at construct rather than seeded with a placeholder: WorkspaceCrumbHtml reads
           psSWSFile and returns, with no dashboard object and no panel to be ready first - which is
           what forced the old tile's "Loading workspace..." seed. */
        Object oTile_Crumb is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <link rel="stylesheet" href="RDCFlexTron/palette.css">
            <link rel="stylesheet" href="CssStyle/tilemarkup.css">
            <div class="dash-crumb"><span class="dash-crumb-back">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 6l6 6l-6 6"/></svg>Start Center</span><span class="dash-crumb-sep">|</span><span class="dash-crumb-lbl">Current Workspace:</span><span class="dash-crumb-name">Workspace name</span></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (WorkspaceCrumbHtml(ghoTileMarkup))
            End_Procedure
            Procedure OnHtmlClick String sId String sParam
                If (sId = "startcenter") ;
                    Send RunClickAction of (oDashboard_vw(Self)) CI_ChkStartCenter
            End_Procedure
        End_Object

        // Second row, just as on the dashboard: the EXACT "Target DataFlex version" tile (compiler + target
        // version, or a warning skin when none is set) and the Libraries tile beside it. Reuses the
        // dashboard's SetupLibsRowHtml (rendered on Activate); clicking Target (data-ServerOnClick="setup")
        // pops the modal Compiler Settings picker - the ONLY place a compiler is chosen (matching the
        // app's "compiler = its own dialog" convention). Both tiles land in THIS host, which is why the
        // one OnClick below still catches both ids after the 2026-09-10 split.
        Object oTile_Setup is a cFTWebHtmlBox
            Set piColumnSpan to 12     // full row (the Program combo is its own row below - see the note there)
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <div class="dash-cols">
                <div class="dash-tile-off">
                    <div class="dash-ico"></div>
                    <div class="dash-txt">
                        <div class="dash-h">Target DataFlex version</div>
                        <div class="dash-p">Load a workspace to see the target</div></div></div>
                <div class="dash-tile-off">
                    <div class="dash-ico">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 4l-8 4l8 4l8 -4l-8 -4 M4 12l8 4l8 -4 M4 16l8 4l8 -4"/></svg></div>
                    <div class="dash-txt">
                        <div class="dash-h">Libraries</div>
                        <div class="dash-p">Load a workspace to see them</div></div></div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (CS_PaletteCssLink + CS_TilesCssLink + (DivOpen("tload")) + 'Loading target' + CS_Ellipsis + CS_DivEnd)
            End_Procedure
            Procedure OnHtmlClick String sId String sParam
                If (sId = CS_IdSetup) ;
                    Send RunClickAction of (oDashboard_vw(Self)) CI_ChkCompilerSetup
                Else If (sId = "libraries") ;
                    Send RunClickAction of (oDashboard_vw(Self)) CI_ChkLibraries
            End_Procedure
        End_Object

        Object oTile_Steps is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <link rel="stylesheet" href="RDCFlexTron/palette.css">
            <link rel="stylesheet" href="RDCFlexTron/buttons.css">
            <link rel="stylesheet" href="RDCFlexTron/bars.css">
            <link rel="stylesheet" href="CssStyle/tiles.css">
            <div class="wrap">
                <div class="step">
                    <div class="st done"><span class="d">&#10003;</span>Select&nbsp;Program</div><span class="bar"></span>
                    <div class="st now"><span class="d">2</span>Check &amp; fix</div><span class="bar"></span>
                    <div class="st"><span class="d">3</span>Tidy&nbsp;Up</div><span class="bar"></span></div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (StepsTileHtml(Self))
            End_Procedure
        End_Object


        // The program picker (native combo), BELOW the stepper - the input for step 1 "Program". Narrow
        // (span 5, left), NOT full width. A native combo dropdown just works (no scroll/stacking/click
        // issues a hand-rolled HTML dropdown hit). Do NOT give it a psCSSClass that sets display/height -
        // that disrupts the grid flow. OnChange writes CS_LastCompileKeyPrefix (SetMainProgram). Always
        // enabled: with no workspace it is simply empty (OnFill returns nothing).
        Object oProgram_cmb is a cFTWebCombo
            Set piColumnSpan to 3
            Set piColumnIndex to 0
            // No visible label (the stepper above already says "Program"), but pbShowLabel True reserves a
            // 20px "label" column so the INPUT starts ~20px in - lining it up with the tiles' text instead of
            // sitting flush at the grid's left edge. (piColumnIndex moves in whole ~36px columns = too coarse;
            // a CSS margin is ignored because the framework positions controls with absolute left/width.
            // piLabelOffset is the framework's own lever and reliably shifts the input.)
            Set pbShowLabel to True
            Set psLabel to ""
            Set piLabelOffset to 20
            Set peSortItems to csUnsorted

            Procedure OnFill
                String sSWS sProg
                String[] asProjects
                Integer i iLast
                Get psSWSFile of ghoApplication to sSWS
                If (sSWS = "") ;
                    Procedure_Return
                // Only the programs whose .src is on disk (Nils 2026-09-23: a workspace file that
                // listed six programs, one of them present, put all six in this combo). The ones
                // left out are named under the Check button - see _BodyMissingProgramsHtml.
                Get WorkspaceProgramsOnDisk of ghoApplication sSWS to asProjects
                Move (SizeOfArray(asProjects) - 1) to iLast
                For i from 0 to iLast
                    Move asProjects[i] to sProg
                    Send AddComboItem sProg sProg
                Loop
            End_Procedure

            Procedure OnChange String sNewValue String sOldValue
                If (sNewValue <> "") Begin
                    Send SetMainProgram of ghoApplication sNewValue
                    Send ArmAction of (oChkDeferTimer(Self)) CI_ChkRefresh
                End
            End_Procedure
        End_Object

        /* MODERNIZATION PROGRESS used to be a tile of its own here, directly under the stepper
           (Nils 2026-07-30). It moved into the check row inside oTile_Body on 2026-08-09 - see the
           comment at that row in BodyTileHtml for why, and oTile_Body's OnClick for the "history"
           route that came with it. It is still ABOVE the findings list, which was the original
           reason for placing it high: a list that can run to hundreds of rows would hide it.

           Deliberately not a span-6 tile beside a span-6 check tile. The host does NOT stretch two
           separate tiles to a common row height (the same finding that produced the dashboard's
           oTile_Columns), so a two-tile row would have left the shorter of the pair floating against
           a taller neighbour. One host, two flex children, one OnClick. */

        Object oTile_Body is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <link rel="stylesheet" href="RDCFlexTron/palette.css">
            <link rel="stylesheet" href="RDCFlexTron/buttons.css">
            <link rel="stylesheet" href="RDCFlexTron/bars.css">
            <link rel="stylesheet" href="CssStyle/tiles.css">
            <div class="wrap wrap-pt">
                <div class="k">Scope <span class="sub">&mdash; what the scan &amp; manual passes cover</span></div>
                <div class="scope"><span class="v">Whole workspace</span><span class="cav"><b>194 of 205</b><span class="cl">analyze rules</span></span><span class="acts"><span class="sbtn">Select
                    Folders</span><span class="sbtn">Analyze rules</span></span></div>
                <div class="checkrow"><span class="cbtn"><span>&#9654;&nbsp; Check</span><span class="sm">compile + analyze</span></span><span class="prog">
                    <div class="dash-readout dash-readout-m">
                        <div class="dash-ico"></div>
                        <div class="dash-rtxt">
                            <div class="dash-h">Modernization progress</div>
                            <div class="dash-p">Load a workspace to track its burn-down</div></div></div></span></div></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (BodyTileHtml(Self))
            End_Procedure
            /* Each arm chooses an action; it runs once at the foot, after the web click has returned.

               Was two standalone Ifs followed by a two-arm Else chain - "adjust" on its own, then
               "dsrules" with "check" hanging off it. Harmless, because the ids are mutually
               exclusive, but it was not written that way on purpose: the chain broke when the
               "reset" branch between them was removed. A Case cannot express the difference, which
               is the point of using one here. */
            Procedure OnHtmlClick String sId String sParam
                Integer iAction

                Move 0 to iAction
                Case Begin
                    Case (sId = "adjust")
                        Move CI_ChkAdjustScope to iAction
                        Case Break
                    Case (sId = "dsrules")
                        Move CI_ChkDeepScanRules to iAction
                        Case Break
                    /* No "reset" arm any more - the chip no longer carries a ServerOnClick, so
                       nothing can reach it. Kept as a note rather than deleted silently: the id,
                       the CI_ChkResetScope code and its no-op handler all still exist, so building
                       the feature is re-attaching one attribute and filling in the handler, not
                       reconstructing the wiring. */
                    Case (sId = "check")
                        Move CI_ChkRunCheck to iAction
                        Case Break
                    /* The progress readout now rides the check row (see BodyTileHtml), so its
                       "history" id arrives HERE rather than at a tile of its own. The action stays
                       ours rather than borrowed from the dashboard for the reason it always was:
                       the modal can RESET the history from inside, Popup blocks, and whichever
                       surface opened it has to repaint itself afterwards. */
                    Case (sId = CS_IdHistory)
                        Move CI_ChkViewProgress to iAction
                        Case Break
                Case End

                If (iAction <> 0) ;
                    Send RunClickAction of (oDashboard_vw(Self)) iAction
            End_Procedure
        End_Object

        // The guided Check result: ONE severity-ranked findings list (compiler + scan) in foldable bands.
        // Placeholder until a Check runs; RefreshFindings / RenderGuidedFindings push the real list.
        Object oTile_Findings is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <link rel="stylesheet" href="RDCFlexTron/palette.css">
            <link rel="stylesheet" href="RDCFlexTron/buttons.css">
            <link rel="stylesheet" href="RDCFlexTron/bars.css">
            <link rel="stylesheet" href="CssStyle/tiles.css">
            <div class="fwrap">
                <div class="fhead">Findings <span class="n">3</span></div>
                <details class="band b-auto" open>
                    <summary><span class="tw">&#9654;</span>Auto-fixable<span class="bpeek">obsolete calls</span><span class="bcount">2</span></summary>
                    <div class="brows">
                        <div class="fnd rep"><span class="fdot e"></span><span class="bdg bdg-c">compiler</span><span class="fmsg">E 4544</span><span class="fhint">Two declarations of one name disagree on the return type.</span></div>
                        <div class="fnd sub"><span class="fdot e inv"></span><span class="bdg bdg-c">declared</span><span class="ffile">SomeFile.pkg (120)</span><span class="fhint">Opens the editor at
                            this declaration.</span></div></div></details>
                <details class="band b-hand">
                    <summary><span class="tw">&#9654;</span>Needs hand migration<span class="bpeek"></span><span class="bcount">1</span></summary>
                    <div class="brows">
                        <div class="fnd rep"><span class="fdot w"></span><span class="bdg bdg-c">compiler</span><span class="fmsg">W 4536</span><span class="fhint">An obsolete package is still in use.</span></div></div></details></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (CS_PaletteCssLink + CS_TilesCssLink + (((DivOpen("tnote")) + 'Run a Check to see findings.') + CS_DivEnd))
            End_Procedure
            /* The row ids that CARRY A PARAMETER: each arm parks sParam where its action reads it
               from and names the action in iAction. Leaves iAction untouched for any other id. */
            Procedure _ParkFindingsParam String sId String sParam Integer ByRef iAction
                Case Begin
                    Case (sId = "collreport")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkViewCollisions to iAction
                        Case Break
                    Case (sId = "renamename")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkRenameGlobal to iAction
                        Case Break
                    Case (sId = "renamecalls")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkRenameCalls to iAction
                        Case Break
                    Case (sId = "runfnscope")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkRunFnScope to iAction
                        Case Break
                    Case (sId = "objcalltoget")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkObjCallToGet to iAction
                        Case Break
                    Case (sId = "dropsurplus")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkDropSurplus to iAction
                        Case Break
                    Case (sId = "fixdecl")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkFixDecl to iAction
                        Case Break
                    Case (sId = "renameclass")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkRenameClass to iAction
                        Case Break
                    Case (sId = "guardext")
                        Set psPendingDeclName of (oDashboard_vw(Self)) to sParam
                        Move CI_ChkGuardExternal to iAction
                        Case Break
                    Case (sId = "ignorerow")
                        Set psPendingIgnoreRow of (oChkDeferTimer(Self)) to sParam
                        Move CI_ChkIgnoreRow to iAction
                        Case Break
                    Case (sId = "ignorefn")
                        Set psPendingIgnoreFn of (oChkDeferTimer(Self)) to sParam
                        Move CI_ChkIgnoreFn to iAction
                        Case Break
                    Case (sId = "opensrc")
                        Set psPendingOpenSrc of (oChkDeferTimer(Self)) to sParam
                        Move CI_ChkOpenSource to iAction
                        Case Break
                Case End
            End_Procedure

            // Returns the action code for a parameterless row id; 0 when sId is not one of ours.
            Function _FindingsActionForId String sId Returns Integer
                Integer iAction

                Move 0 to iAction
                Case Begin
                    Case (sId = "tidyup")
                        Move CI_ChkTidyUp to iAction
                        Case Break
                    /* Its OWN id, not the Check band's "check". A click reaches sibling boxes'
                       handlers too, so reusing that id here would leave two handlers claiming one
                       click - the ancestor-fires-everything trap the dismissal rows were shaped
                       around. Same action, unambiguous owner. */
                    Case (sId = "verifycheck")
                        Move CI_ChkRunCheck to iAction
                        Case Break
                    Case (sId = "showlastplan")
                        Move CI_ChkShowLastPlan to iAction
                        Case Break
                    Case (sId = "clearignored")
                        Move CI_ChkClearIgnored to iAction
                        Case Break
                    Case (sId = "showskipped")
                        Move CI_ChkShowSkipped to iAction
                        Case Break
                    Case (sId = "fixshadow")
                        Move CI_ChkFixShadow to iAction
                        Case Break
                    Case (sId = "showshadow")
                        Move CI_ChkShowShadowFiles to iAction
                        Case Break
                    Case (sId = "unkeepshadow")
                        Move CI_ChkUnkeepShadows to iAction
                        Case Break
                    Case (sId = "restorelang")
                        Move CI_ChkRestoreLanguage to iAction
                        Case Break
                    Case (sId = "keeplang")
                        Move CI_ChkKeepInstallLanguage to iAction
                        Case Break
                    Case (sId = "runplan")
                        Move CI_ChkRunPlan to iAction
                        Case Break
                    Case (sId = "clearboard")
                        Move CI_ChkClearBoard to iAction
                        Case Break
                    Case (sId = "guardglobals")
                        Move CI_ChkGuardGlobals to iAction
                        Case Break
                    Case (sId = "charinv")
                        Move CI_ChkCharModeInventory to iAction
                        Case Break
                Case End
                Function_Return iAction
            End_Function

            // Row actions, after the web click has returned (the library's click relay): the click arrives ON
            // the WebView2 pump, and running the engine (which pops a status panel + summary) from that stack
            // is the err-4410 path. Only OUR ids act - a cWebHtmlBox click also reaches sibling boxes'
            // handlers, so each handler must stay strictly id-scoped.
            /* Every arm chooses an action and, where it needs one, parks a parameter; the action runs
               once at the foot. Was fifteen Else If arms each repeating the same two Sets (Nils
               2026-08-25). */
            Procedure OnHtmlClick String sId String sParam
                Integer iAction

                Move 0 to iAction
                Send _ParkFindingsParam sId sParam (&iAction)
                If (iAction = 0) ;
                    Get _FindingsActionForId sId to iAction

                If (iAction <> 0) ;
                    Send RunClickAction of (oDashboard_vw(Self)) iAction
            End_Procedure
        End_Object

        /* THE AFTER-A-RUN UTILITIES: Read log / Read other logs / Compare Source / Revert (Nils
           2026-07-30 - "the last tile on the dashboard ... could you add that please?").

           BORROWED, NOT COPIED, in both directions. The HTML comes from the shared
           ActionRowHtml, exactly as this view already borrows WorkspaceCrumbHtml and SetupTileHtml -
           so the four enable/disable gates and their per-state tooltips have ONE implementation. The
           clicks then arm the DASHBOARD's deferred timer rather than ours, so the actions themselves
           also have one implementation: Revert pops the backup dialog and Compare shells the external
           diff tool, neither of which should exist twice.

           The .dash-* classes need no CSS here - they live in AppHtml/CssStyle/application.css, which
           the framework auto-loads into every web host, which is why the two borrowed tiles above
           already render correctly.

           Guarded on a loaded workspace like the dashboard's own handler: every one of these acts on
           the workspace's backup folder. */
        Object oTile_Actions is a cFTWebHtmlBox
            Set piColumnSpan to 12
            // DESIGN-TIME PLACEHOLDER for the Studio's Windows Designer, which models the LAST literal
            // psHtml it can parse. The runtime content is set in End_Construct_Object below, which the
            // Designer never reads, so the placeholder is never seen at runtime.
            Set psHtml to """
            <div class="dash-action-row"><span class="dash-action-off">Read log</span><span class="dash-action-off">Read other logs (0)</span><span class="dash-action-off">Compare Source</span><span
                class="dash-action-off">Revert (0)</span></div>
            """

            // RUNTIME content - here rather than in the object body, so the Designer keeps the literal above.
            Procedure End_Construct_Object
                Forward Send End_Construct_Object
                Set psHtml to (ActionRowHtml(ghoTileMarkup))
            End_Procedure

            Procedure OnHtmlClick String sId String sParam
                String sWS
                Integer iAction

                Get psSWSFile of ghoApplication to sWS
                If (sWS = "") ;
                    Procedure_Return
                Move 0 to iAction
                Case Begin
                    Case (sId = CS_IdReadLog)
                        Move CI_ChkReadLog to iAction
                        Case Break
                    Case (sId = CS_IdReadOtherLogs)
                        Move CI_ChkReadOtherLogs to iAction
                        Case Break
                    Case (sId = CS_IdCompare)
                        Move CI_ChkCompare to iAction
                        Case Break
                    Case (sId = CS_IdUndo)
                        Move CI_ChkUndo to iAction
                        Case Break
                Case End
                If (iAction <> 0) ;
                    Send RunClickAction of (oDashboard_vw(Self)) iAction
            End_Procedure
        End_Object
    End_Object

    // The workspace the combo was last primed for. PrimeCombo re-Refills ONLY when this changes - re-
    // Refilling on every RefreshTiles (the one the user's own pick triggers via OnChange -> CI_ChkRefresh
    // included) re-runs OnFill and re-sets psValue, which can re-fire OnChange / reset the selection and
    // clobber the program the user just picked. NOTE: this guard is worth keeping, but it was NOT the cause
    // of the "combo doesn't save" report - that was PrimeCombo pushing the restored value with a plain Set
    // after the page had mounted (see the pbInitWebApp gate below). Nils 2026-07-20.
    Property String psLastPrimedWS ""


    /* Seed the program combo: fill its items from the workspace + select the persisted main program.

       The ITEM list only changes with the workspace, so the folder-scanning Refill stays guarded by
       psLastPrimedWS. The VALUE is re-read on every refresh, though: since 2026-08-01 the Dashboard has
       its own picker over the SAME setting, so this combo can be out of date without this workspace
       having changed at all. Two controls, one source of truth - each re-reads it on entry. */
    Procedure PrimeCombo
        String sMain sSWS sLast sShown
        Boolean bListed bPageUp
        String[] asProjects
        Integer i iMax
        Handle hoHost

        Get psSWSFile of ghoApplication to sSWS
        Get psLastPrimedWS to sLast
        /* THE ITEMS GO TO A PAGE THAT IS UP, NEVER TO ONE THAT IS NOT (Nils 2026-10-12: a workspace opened in
           the Start Center, then the Guided pane clicked - "Could not find object 'oProgram_cmb'", error 999).
           The framework's Refill asks nothing: it fills the list and queues a "fill" for the client, every
           time. Sent while this view's page was not there - the workspace broadcast reaches every view - that
           message waited on the host and went out with the next page, before the page had built the combo.
           A page that is not up needs no Refill at all: every page that loads fills its combos itself
           (cWebCombo.PreSerializeObject), with the workspace of that moment. */
        Move (oWebHost(Self)) to hoHost
        Move (FTHostPageIsUp(hoHost)) to bPageUp
        If (sSWS <> sLast and bPageUp = True) ;
            Send Refill of (oProgram_cmb(hoHost))
        /* NOTHING PICKED YET? PICK ONE (Nils 2026-08-09: opening a workspace in the Start Center
           and clicking through to the guided board left Check dead - "pick a program first").

           MainProgram is "" for any workspace that has never been compiled here, which is every
           workspace on first arrival. So the trail's primary button was inert on the one screen
           whose whole job is to say what to press, and the fix for it - the combo three lines
           below - is easy to miss precisely because the button beside it looks broken rather than
           waiting.

           So take the FIRST project - the only entry when a workspace declares one, and a
           defensible guess when it declares several. It is written through SetMainProgram rather
           than merely displayed, so the Dashboard's own picker over the same setting agrees with
           it and a later Check compiles what the combo says.

           It cannot overwrite a choice: this runs only when nothing is stored. And it lands before
           any tile is painted - PrimeCombo is the first thing RefreshTilesKeepFindings does - so
           Check lights on the same pass rather than needing a second refresh. */
        Get MainProgram of ghoApplication to sMain
        /* A STORED PICK WHOSE FILE IS GONE IS NO PICK (2026-09-23). The combo lists only the
           programs on disk now, so a remembered name that is not among them would leave the combo
           blank and send Check after a file that is not there. When nothing on disk is listed at
           all, the stored name is kept - there is nothing better to offer. */
        Get WorkspaceProgramsOnDisk of ghoApplication sSWS to asProjects
        Move (SizeOfArray(asProjects) - 1) to iMax
        If (sMain <> "" and iMax >= 0) Begin
            Move False to bListed
            For i from 0 to iMax
                If (Lowercase(Trim(asProjects[i])) = Lowercase(Trim(sMain))) ;
                    Move True to bListed
            Loop
            If (bListed = False) ;
                Move "" to sMain
        End
        If (sMain = "") Begin
            If (iMax >= 0) Begin
                Move asProjects[0] to sMain
                Send SetMainProgram of ghoApplication sMain
            End
        End
        If (sMain = "") ;
            Procedure_Return
        // Already showing it (the common same-workspace refresh) - nothing to push.
        Get psValue of (oProgram_cmb(oWebHost(Self))) to sShown
        If (sMain = sShown and sSWS = sLast) ;
            Procedure_Return
        // Push the persisted pick the SAME way cFTWebHtmlBox.UpdateHtml pushes HTML - RDCFlexTron's
        // FTHostPageIsUp is the readiness truth. While the page is NOT UP, Set the stored property
        // (the page's mount sync serves it). Once the page is ALIVE, only WebSet reaches the client: a plain
        // Set updates the SERVER copy while the combo on screen stays blank - which reads as "the program
        // combo doesn't save" even though the registry holds the program. The symptom is the RESTORE, not
        // the write (OnChange -> SetMainProgram persists correctly; verified in the registry under
        // ...\DFRefactorFT\Settings). This path only runs on a workspace CHANGE - i.e. long after mount -
        // so it was always taking the blank branch. WebSet pre-realization faults 4402, hence the gate
        // rather than simply switching to WebSet. Nils 2026-07-20.
        /* IS THE PAGE UP? (2026-10-11) The question here was the framework's pbInitWebApp alone, and that
           flag keeps saying "ready" for a view that is closed or being shown again: the WebSet then went to a
           page that was gone, and nothing was stored for the one that comes back. FTHostPageIsUp (RDCFlexTron's
           FTPageIsUp.pkg) asks both halves - the host is active, and its page has called home. */
        If (bPageUp = True) ;
            WebSet psValue of (oProgram_cmb(hoHost)) to sMain
        Else ;
            Set psValue of (oProgram_cmb(hoHost)) to sMain
        /* STAMPED LAST, ON PURPOSE. The stamp is what makes this a one-per-workspace job, so writing it
           up front made any failed attempt PERMANENT: a Refill that lands while the page is between
           activation and realization reaches no client, the combo on screen stays empty, and every
           later refresh then early-returns on the stamp - an empty, unselectable Program combo for the
           rest of the session. Stamping only after the push means a bad moment costs one retry instead
           of the workspace. (Nils 2026-07-31: "the Program combo can then not be selected as it is
           empty".) The sMain="" return above deliberately leaves it unstamped too - no program is
           picked yet, so there is nothing to remember. */
        /* ...AND NOT WHILE A PAGE IS STILL LOADING (2026-10-12). A host that is active but whose page has not
           called home yet may have been built with the workspace before this one, and it got no Refill
           above: it stays unstamped, so the next refresh - with the page up - fills it. A host that is not
           active is stamped: the page it builds when it is shown fills itself. */
        If (bPageUp = True or Active_State(hoHost) = False) ;
            Set psLastPrimedWS to sSWS
    End_Procedure

    // Re-render every tile from live state + re-prime the combo. The workspace + target tiles reuse the
    // dashboard's builders (exact look). Runtime push via UpdateHtml + CheckUpdateWebUI.
    /* A workspace change repaints this view's tiles.

       UpdateWorkspaceSelectorDisplay broadcasts OnWorkspaceLoaded to every MDI view; DashboardFT
       has handled it since the split, this view never did - so after a load its Workspace tile went
       on showing the PREVIOUS .sws while psSWSFile and everything reading it had already moved on.
       Visible after the migration copy step loads the copy: the plan behind Alt+P showed the new
       workspace's folders while the tile above it still named the old one (Nils 2026-08-06). */
    /* SINCE THE START CENTER OWNS WORKSPACE SELECTION, THIS IS THE ONLY PATH IN (Nils 2026-08-06).

       This board used to change the workspace itself, and its own handler called WorkspaceChanged
       straight afterwards - which is what cleared the findings, the plan stamp and the tick
       stamps so one workspace's verdict could not describe another's. With selection moved to the
       Start Center, that handler is gone and the broadcast is all that arrives; leaving this as a
       bare RefreshTiles would have repainted the tiles around a findings list still holding the
       PREVIOUS workspace's rows. The exact defect WorkspaceChanged was written to prevent.

       Guarded on a real CHANGE rather than run unconditionally: the broadcast also fires when the
       same .sws is re-loaded, and throwing away a Check the user just ran - to re-derive the same
       verdict - is a worse answer than repainting. Tracked here rather than read back from
       ghoApplication because by the time this fires psSWSFile is already the NEW value. */
    Procedure OnWorkspaceLoaded
        String sWS sPrev
        Get psSWSFile of ghoApplication to sWS
        Get psBoardWS to sPrev
        Set psBoardWS to sWS
        If (sWS <> sPrev) ;
            Send WorkspaceChanged
        Else ;
            Send RefreshTiles
        /* DEFERRED, NOT INLINE, and the deferral is load-bearing. The folder discovery this reads
           runs in SelectFoldersViewFT's own OnWorkspaceLoaded - a sibling handler of the same
           broadcast, with no ordering guarantee between them - so asking inline could see the
           selection before it exists. The timer fires after the whole broadcast has settled. It
           also keeps the dialog out of the pump the tiles are painting on. */
        Send Arm of (oScopeOfferTimer(Self))
    End_Procedure

    /* ---- Moved here from the retired split board, 2026-08-10 ----
       RunDeepScan / RunDeepScanVerify: the STANDALONE source analyze, broadcast by TestCompileFT
       (its analyze chip, and the "nothing left for the compiler - analyze the source now?" prompt).
       This board's OWN Check runs the scan half quietly and parks it on the analyzer, so it never
       needed a standalone door; the manual board still offers one. Broadcast reaches every MDI
       view, so answering here serves whichever board the user is standing on.

       Moved VERBATIM rather than reimplemented: the campaign bookkeeping (pass numbers, the
       shrink line, the exhaustion verdict and the Tidy Up offer) is the part a thin re-write
       would quietly have dropped. Split into named helpers 2026-09-02 - scope confirm, pass
       bookkeeping, caption, result line, bar verdict - with that bookkeeping intact. */
    Procedure RunDeepScan
        Handle hoStatusBar hoTC
        String[] asFolders
        String sText sPanelCaption sScopeText
        tCompileError[] aMessages
        Integer iStartTick iCacheHits iFilesTotal iPass iScanSecs iGridLeft iPos
        Boolean bBusy bCancelled bVerify bOk bFileScope

        // ALPHA GATE belt: the chip is hidden while CB_DeepScanEnabled is False, but a stale
        // rendered card could still route a click here - refuse quietly.
        If (CB_DeepScanEnabled = False) ;
            Procedure_Return
        Get pbDeepScanning of ghoDeepScanDriver to bBusy
        If (bBusy = True) ;
            Procedure_Return
        // VERIFY RE-SCAN (Nils 2026-07-16): a fix plan just APPLIED inside the scan loop, so
        // TestCompileFT.StartAutoSelect requested an automatic re-scan - the cache makes it cheap
        // (only the files the run wrote get re-read) and the grid then shows POST-run truth instead
        // of the stale pre-run rows ("why did my rows survive?"). One-shot; consumed here.
        Get pbVerifyRescanOnce to bVerify
        Set pbVerifyRescanOnce to False
        Get _DeepScanScope bVerify (&asFolders) (&bFileScope) to bOk
        If (bOk = False) ;
            Procedure_Return
        Get _DeepScanPassForScope asFolders bFileScope to iPass
        Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
        Move (GetTickCount()) to iStartTick
        // Bring the working surface up BEFORE the scan: editor view + the Test Compile dock (its
        // bar carries Run Fix Plan + the marquee). Showing the dock now lets its WebView2 controls
        // REALIZE during the scan's per-file pumps - shown only at the end, the bar wasn't realized
        // yet and SetBusyMarquee's render no-op'd (the realization guard), so the marquee never
        // appeared during the grid fill (Nils 2026-07-10).
        Send Activate_oEditorView_vw of (Client_Id(phoMainPanel(ghoApplication)))
        Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        Get _DeepScanCaption bVerify iPass to sPanelCaption
        // The scan CORE (extracted 2026-07-25 so the guided Check shares it): file collection,
        // status panel + cancel, the incremental cache, hits -> analyzer currency.
        // SINGLE-FILE scope: asFolders holds the one file's path - the driver's file door scans
        // exactly that (see _DeepScanScope); everything after the scan is the same lap.
        If (bFileScope = True) ;
            Get ScanFilesToMessages of ghoDeepScanDriver asFolders sPanelCaption (&bCancelled) (&iFilesTotal) (&iCacheHits) to aMessages
        Else ;
            Get ScanFoldersToMessages of ghoDeepScanDriver asFolders sPanelCaption (&bCancelled) (&iFilesTotal) (&iCacheHits) to aMessages
        If (iFilesTotal = 0) Begin
            Send FTInfoBox "No source files found to scan in the selected folders."
            Procedure_Return
        End
        If (bCancelled = True) Begin
            Set StatusText of hoStatusBar to "Analyze Source cancelled - no results loaded."
            Procedure_Return
        End
        // The scan's own elapsed seconds, captured BEFORE the grid load below so the result
        // line keeps measuring the scan (the load's classify/source-guard time is its own cost).
        Move ((GetTickCount() - iStartTick) / 1000) to iScanSecs
        // Load the Analyzer in Deep-Scan mode - this ONE path handles BOTH outcomes, so no Info_Box:
        // with findings the grid fills and Run Fix Plan lights up; with NONE the grid clears to its
        // "exhausted" empty-state message (EmptyGridReason, pbDeepScanView branch) and its own
        // SyncWebButtonStates gates Run Fix Plan off by the 0 row count - so the previous scan's rows
        // + plan button can no longer linger and a stale re-run is impossible (Nils 2026-07-14).
        // Marquee ON while the grid fills (classify + per-finding source-guards take a moment on a
        // big scan) - the same bracket StartAnalyze puts around its own load. Loaded BEFORE the
        // result-line verdict since 2026-07-19: the verdict reads the grid's POST-DEMOTE sums.
        Get phoTestCompileFT of ghoApplication to hoTC
        If (hoTC <> 0) Begin
            Send SetBusyMarquee of hoTC True
            Send PumpMsgQueue of Desktop
        End
        Send ActivateModAnalyzerDeepScan of (Client_Id(ghoCommandBars)) aMessages
        Get _DeepScanActionableLeft (SizeOfArray(aMessages)) to iGridLeft
        // Name the scope the way it was chosen: N folders, or the one file by its base name.
        If (bFileScope = True) Begin
            Move (RightPos("\", asFolders[0])) to iPos
            Move (" - single file " + Right(asFolders[0], (Length(asFolders[0]) - iPos))) to sScopeText
        End
        Else ;
            Move (" from " + String(SizeOfArray(asFolders)) + " folder(s)") to sScopeText
        Get _DeepScanResultLine iPass (SizeOfArray(aMessages)) iFilesTotal iCacheHits sScopeText bFileScope iScanSecs iGridLeft to sText
        Set StatusText of hoStatusBar to sText
        Send _NoteScanLaneVerdict hoTC (SizeOfArray(aMessages) > 0) (iGridLeft = 0) bFileScope
    End_Procedure

    /* The folders a scan will run over, confirmed. SCOPE IS THE USER'S DECISION (Nils 2026-07-11 -
       no silently inherited folder scope; the plan run's folder-ticking is gone too): an existing
       selection is shown back (first folders + a count) and confirmed; no selection offers the
       AppSrc fallback EXPLICITLY. Cancelling either confirm just ABORTS and stays on the board
       (Nils 2026-07-12: a No used to jump to the Select Folders view, which was unexpected). A
       VERIFY re-scan replays the scope the user confirmed when the lap started
       (pasLastScanFolders) with no re-confirm: same lap, not a new scan. Returns False when there
       is nothing to scan or the user said no.

       THE SINGLE-FILE SCOPE (Nils 2026-09-17). Single-file mode means the user picked ONE file (the
       Manual board's Single file tile -> SelectSourceFile) and every manual action since has been
       about that file - so the scan is about it too: asFolders comes back holding that file's path
       and bFileScope True, and there is nothing to confirm, because the pill that starts this names
       the file. Never inferred from what the editor shows: the mode flag is set only by that pick
       and cleared by a workspace load or the workspace-mode setup views (OpenManualSetup). */
    Function _DeepScanScope Boolean bVerify String[] ByRef asFolders Boolean ByRef bFileScope Returns Boolean
        tWorkspacePaths TargetWS
        String sText sFile
        Integer i iFolders iRetval
        Boolean bWsMode bExists

        Move False to bFileScope
        If (bVerify = True) Begin
            Get pasLastScanFolders to asFolders
            Get pbLastScanWasFile to bFileScope
            Function_Return (SizeOfArray(asFolders) > 0)
        End
        Get pbWorkspaceMode of ghoApplication to bWsMode
        If (bWsMode = False) Begin
            Get psCurrentSourceFileName of ghoApplication to sFile
            Move False to bExists
            If (sFile <> "") ;
                Get vFilePathExists sFile to bExists
            If (bExists = True) Begin
                Move (ResizeArray(asFolders, 0)) to asFolders
                Move sFile to asFolders[0]
                Move True to bFileScope
                Function_Return True
            End
        End
        Get pasSelectedFolders of ghoApplication to asFolders
        Move (SizeOfArray(asFolders)) to iFolders
        If (iFolders = 0) Begin
            Get pTargetWS of ghoApplication to TargetWS
            If (TargetWS.sAppSrc = "") Begin
                Send FTInfoBox "No source folders to scan - load a workspace first."
                Function_Return False
            End
            // Plain Yes/No - the Rules dialog has its OWN doors (the gear next to the Deep Scan
            // chip + the Tools toolbar button); hijacking Cancel for it read as a mystery
            // (Nils 2026-07-11).
            Move ("No source folders are selected.\n\nScan the workspace's AppSrc folder?\n\n" + TargetWS.sAppSrc) to sText
            Get FTYesNoBox sText to iRetval
            If (iRetval <> MBR_Yes) ;
                Function_Return False
            Move TargetWS.sAppSrc to asFolders[0]
            Function_Return True
        End
        Move "" to sText
        For i from 0 to (iFolders - 1)
            If (i < 6) ;
                Move (sText + asFolders[i] + "\n") to sText
        Loop
        If (iFolders > 6) ;
            Move (sText + "... and " + String(iFolders - 6) + " more\n") to sText
        Move ("Analyze Source will analyze the " + String(iFolders) + " selected source folder(s):\n\n" + sText + "\nContinue?") to sText
        Get FTYesNoBox sText to iRetval
        Function_Return (iRetval = MBR_Yes)
    End_Function

    /* CAMPAIGN bookkeeping (Nils 2026-07-17: users must learn that ONE scan+plan cycle is rarely
       enough - staged conversions unlock in order, so the loop narrates itself). The same folder
       set as the previous scan = the NEXT pass of the same campaign; a changed scope = a fresh
       campaign at pass 1 (a delta across different scopes misleads - the 2026-07-11 AppSrcNils
       "keeps finding new rows" lesson). Compared against the OLD pasLastScanFolders, and then THIS
       resolved scope is remembered - after the confirms, so a cancelled confirm never becomes a
       verify scope; the post-plan verify re-scan replays exactly this. Returns the number of the
       pass about to run; a cancelled scan never advances the stored counter, so a retry stays the
       same pass. */
    Function _DeepScanPassForScope String[] asFolders Boolean bFileScope Returns Integer
        String[] asPrevFolders
        Integer i iN iPass
        Boolean bSameScope bPrevFile

        Get pasLastScanFolders to asPrevFolders
        Get pbLastScanWasFile to bPrevFile
        Get piDeepScanPassNo to iPass
        Move (SizeOfArray(asFolders)) to iN
        Move (SizeOfArray(asPrevFolders) = iN) to bSameScope
        If (bSameScope = True) Begin
            For i from 0 to (iN - 1)
                If (SearchArray(asFolders[i], asPrevFolders, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move False to bSameScope
            Loop
        End
        // A file and a folder are never the same scope, whatever the strings say.
        If (bSameScope = False or bPrevFile <> bFileScope) ;
            Move 0 to iPass
        Set pasLastScanFolders to asFolders
        Set pbLastScanWasFile  to bFileScope
        Function_Return (iPass + 1)
    End_Function

    // The status-panel caption. The pass number in it is deliberate teaching: a user watching
    // "pass 2" run unprompted learns the loop is MEANT to go around more than once.
    Function _DeepScanCaption Boolean bVerify Integer iPass Returns String
        If (bVerify = True) ;
            Function_Return ("Analyze Source pass " + String(iPass) + " - verifying the applied fix plan (re-analyzing)...")
        If (iPass > 1) ;
            Function_Return ("Analyze Source pass " + String(iPass) + " - analyzing source for obsolete symbols...")
        Function_Return "Analyze Source - analyzing source for obsolete symbols..."
    End_Function

    /* THE EXHAUSTED VERDICT READS THE GRID, NOT THE RAW HITS (live-test catch, Nils 2026-07-19,
       LegacyApp2): the raw pre-classified tally OVER-counts by design - the grid's recipe/dry-run
       honesty demotes and the ignore list only ever REMOVE actionable rows - so the final pass can
       hold raw Auto/Suggest hits while the grid shows nothing actionable. The BAR (which reads the
       grid sums) then said "scan exhausted", the status line kept coaching "run the fix plan", and
       the scan-lane latch never set, so the Tidy Up campaign-exit offer never fired. ONE source of
       truth now: the same piSumAuto+piSumSuggest the bar reads, fresh from the load - and
       exhaustion is still never claimed EARLY, because demotion only shrinks the count. With no
       grid to consult the raw count stands: never claim exhausted blind. */
    Function _DeepScanActionableLeft Integer iRawFindings Returns Integer
        Integer iGridAuto iGridSug

        If (ghoModAnalyzerDock = 0) ;
            Function_Return iRawFindings
        Get piSumAuto    of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iGridAuto
        Get piSumSuggest of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iGridSug
        Function_Return (iGridAuto + iGridSug)
    End_Function

    /* AND NAME THE FOLDERS THAT GAVE NOTHING (Nils 2026-08-31). A selected folder holding 152
       packages contributed zero files to a WinServ scan, and the result line still read as a
       clean sweep - the gap was only findable by diffing the scan cache against the compile
       scope by hand. A folder that yields no source file is either not the one the user thinks
       they ticked or is being filtered out, and both are worth one line on screen. Capped at
       three names: this is a pointer, not the report. "" when every folder yielded something. */
    Function _EmptyFoldersNote Returns String
        String[] asEmpty
        String sText
        Integer i iEmpty iShow

        Get pasEmptyFolders of ghoApplication to asEmpty
        Move (SizeOfArray(asEmpty)) to iEmpty
        If (iEmpty = 0) ;
            Function_Return ""
        Move (" " + String(iEmpty) + " selected folder(s) held no source file:") to sText
        Move (iEmpty - 1) to iShow
        If (iShow > 2) ;
            Move 2 to iShow
        For i from 0 to iShow
            Move (sText + " " + asEmpty[i]) to sText
        Loop
        If (iEmpty > 3) ;
            Move (sText + " ...") to sText
        Function_Return sText
    End_Function

    /* The result line, and the campaign counters it reads and writes.
       Name the SCOPE: repeated scans that "keep finding new rows" are almost always a scope change
       - the first scan's fallback is AppSrc alone, while a fix-plan run TICKS its folders into the
       selection, widening the next scan (Nils 2026-07-11, the AppSrcNils surprise). The
       re-scanned/unchanged split does the same job for SPEED: it makes an incremental re-scan's
       sudden quickness legible (a 3s second pass reads as "1686 unchanged", not as a scan that
       skipped work).
       PASS NARRATIVE (Nils 2026-07-17): the pass number + the shrinking count ARE the explanation
       that one cycle is rarely enough - each pass converts what is convertible NOW; the re-scan
       finds what that just unlocked (operators first, then the If Not on the same line, etc.). The
       delta always compares like with like (a scope change reset the campaign). Nothing actionable
       left = the campaign is over: say so with the arc, and reset the counters. */
    Function _DeepScanResultLine Integer iPass Integer iFindings Integer iFilesTotal Integer iCacheHits ;
                                 String sScopeText Boolean bFileScope Integer iScanSecs Integer iGridLeft Returns String
        String sText sEmptyNote
        Integer iPrevFindings

        Get piDeepScanLastFindings to iPrevFindings
        Move "Ready. Analyze Source" to sText
        If (iPass > 1) ;
            Move (sText + " pass " + String(iPass)) to sText
        // sScopeText is the caller's " from N folder(s)" or " - single file <name>".
        If (bFileScope = True) ;
            Move (sText + ": " + String(iFindings) + " finding(s)" + sScopeText + " (" + String(iScanSecs) + "s).") to sText
        Else Begin
            Move (sText + ": " + String(iFindings) + " finding(s) in " + String(iFilesTotal) + " files (" + String(iFilesTotal - iCacheHits) + " re-scanned, " + String(iCacheHits) + " unchanged)" + sScopeText + " (" + String(iScanSecs) + "s).") to sText
            // The empty-folder note belongs to a COLLECTION; a file scope collected nothing.
            Get _EmptyFoldersNote to sEmptyNote
            Move (sText + sEmptyNote) to sText
        End
        If (iGridLeft = 0) Begin
            If (bFileScope = True) ;
                Move (sText + " Nothing auto-fixable or reviewable remains in this file after " + String(iPass) + " pass(es).") to sText
            Else ;
                Move (sText + " Nothing auto-fixable or reviewable remains - scan lane exhausted after " + String(iPass) + " pass(es). Compile to verify.") to sText
            Set piDeepScanPassNo to 0
            Set piDeepScanLastFindings to 0
        End
        Else Begin
            If (iPass > 1) Begin
                If (iFindings < iPrevFindings) ;
                    Move (sText + " Down from " + String(iPrevFindings) + " - the loop is converging.") to sText
                Else ;
                    Move (sText + " Previous pass: " + String(iPrevFindings) + " finding(s).") to sText
                Move (sText + " Some fixes unlock others - run the fix plan and re-scan; repeat until the scan is exhausted.") to sText
            End
            Set piDeepScanPassNo to iPass
            Set piDeepScanLastFindings to iFindings
        End
        Function_Return sText
    End_Function

    /* The bar's post-scan state + the campaign-exit latch (Nils 2026-07-15 / 2026-07-19).
       A fresh scan means no plan has applied against THESE results yet, so any prior "scan plan
       applied -> recompile to verify" state drops (covers the re-scan too). Then THIS scan's
       verdict goes into the session-scoped scan-lane latch - a scan WITH actionable findings
       un-latches a stale exhausted, the honesty mirror of NoteCompileLaneVerdict on the compile
       lane. Keys off the same GRID sums as the result line (post-demote - the bar, the status line
       and this latch must agree). On exhausted, MaybeSuggestTidyUp pops its one-shot when the
       compile lane is also clean; the grid is already loaded, so the exhausted empty-state view
       sits behind the offer. */
    Procedure _NoteScanLaneVerdict Handle hoTC Boolean bAnyRows Boolean bExhausted Boolean bFileScope
        String sScanWS sPrevDoneWS

        If (hoTC = 0) ;
            Procedure_Return
        // pbAnalyzed points the bar's you-are-here ladder at step 3 (Run Fix Plan) - set only
        // when there ARE rows to run; an exhausted scan leaves it off.
        Set pbAnalyzed of hoTC to bAnyRows
        Set pbScanPlanRan of hoTC to False
        Send SetBusyMarquee of hoTC False
        Send SyncWebButtonStates of hoTC
        // ONE FILE'S verdict is not the workspace's scan lane: it must neither latch the campaign
        // exit (and pop the Tidy Up offer) nor un-latch a verdict a real workspace scan earned.
        If (bFileScope = True) ;
            Procedure_Return
        Get psSWSFile of ghoApplication to sScanWS
        If (sScanWS = "") ;
            Procedure_Return
        If (bExhausted = True) Begin
            Set psScanLaneDoneWS of hoTC to sScanWS
            Send MaybeSuggestTidyUp of hoTC
        End
        Else Begin
            Get psScanLaneDoneWS of hoTC to sPrevDoneWS
            If (sPrevDoneWS = sScanWS) ;
                Set psScanLaneDoneWS of hoTC to ""
        End
    End_Procedure

    // The post-plan AUTO verify re-scan door (Nils 2026-07-16). Broadcast from
    // TestCompileFT.StartAutoSelect (via its defer timer) after a LIVE scan-loop plan run applied:
    // re-scan the SAME scope the plan's scan used, no scope confirm. Guards mirror RunDeepScan's
    // own; a missing prior scope (e.g. the loop's scan ran in an earlier session) just leaves the
    // manual "recompile to verify" nudge in place - nothing is lost. If the user CANCELS the verify
    // scan mid-way, pbScanPlanRan stays set on the bar for the same reason.
    Procedure RunDeepScanVerify
        Boolean bBusy
        String[] asLast
        If (CB_DeepScanEnabled = False) ;
            Procedure_Return
        Get pbDeepScanning of ghoDeepScanDriver to bBusy
        If (bBusy = True) ;
            Procedure_Return
        Get pasLastScanFolders to asLast
        If (SizeOfArray(asLast) = 0) ;
            Procedure_Return
        Set pbVerifyRescanOnce to True
        Send RunDeepScan
    End_Procedure

    Procedure RefreshTiles
        Send RefreshTilesKeepFindings True
    End_Procedure

    /* ---- The three refresh Broadcasts, answered here since 2026-08-10 ----
       All three used to be answered by the split cockpit board. When it left the build they kept
       being broadcast and stopped being heard, and a Broadcast no-ops on a view that does not
       handle it - so nothing failed, the tiles just quietly went stale. This board is the
       dashboard now, so it answers them.

       Each is a REQUEST to repaint, not a repaint: they all arm the board's own 1 ms coalescing
       oChkDeferTimer rather than painting inline. That matters most for RequestTileRefresh, which
       arrives on EVERY selection tick - a 65-row Select All would otherwise be 65 full repaints -
       and it is also what keeps the paint off the caller's stack, where a WebView2 push during a
       grid click or an analyze tail has bitten this codebase before. */

    // Broadcast by ModAnalyzerFT (analyze finished) and BackupFilesFT (a restore changed the tree).
    // The findings list is rebuilt from the analyzer, so this is the FULL refresh.
    Procedure RefreshAnalyze
        Send ArmAction of oChkDeferTimer CI_ChkRefresh
    End_Procedure

    // Broadcast by the engine when a run finishes. Also the full refresh - a run changes counts,
    // the progress tile and what the plan has left to do.
    Procedure RefreshAfterRun
        /* THE LIST GOES BEFORE THE SUMMARY DIALOG, NOT AFTER IT (Nils 2026-09-23). The engine
           broadcasts this before it shows the run summary, but the deferred refresh could only
           fire once that modal had closed - and then it re-rendered every row from the grid
           before RunGuidedPlan's tail replaced them with the note. On a long list that was
           seconds in which the old findings, "Run the refactoring plan" included, sat on
           screen clickable. So for a guided plan run the note is pushed NOW, inline, while the
           summary is still to come; and the refresh that follows is the LIGHT one, which
           restates the tiles and never touches the findings tile. Every other run keeps the
           full refresh. */
        If (pbPlanRunInFlight(Self) = True) Begin
            Send PushHtml of (oTile_Findings(oWebHost(Self))) (PlanRanFindingsNote(Self))
            Send PumpMsgQueue of Desktop
            Send ArmAction of oChkDeferTimer CI_ChkRefreshLight
            Procedure_Return
        End
        Send ArmAction of oChkDeferTimer CI_ChkRefresh
    End_Procedure

    // Broadcast by Select Folders / Select Functions on every selection change. LIGHT refresh: the
    // tiles restate the scope, but the findings list and its folds are the user's place in the work
    // and must survive a tick. Arriving in bursts is the normal case, hence the coalescing timer.
    Procedure RequestTileRefresh
        Send ArmAction of oChkDeferTimer CI_ChkRefreshLight
    End_Procedure

    /* A DIFFERENT WORKSPACE IS A DIFFERENT BOARD. The loaded plan's stamp, the last render's verdict
       and the one-shot restore all belong to the .sws we just left; carrying them over would let one
       workspace's result describe another's. Cleared back to "not looked yet" (-1), which re-arms the
       automatic restore so the NEW workspace's own saved Check can load. */
    /* THE BOARD RESET, shared by the two events that orphan its rows: switching workspace, and a
       REVERT of this workspace's files (Nils 2026-08-27: "when reverting, the dashboard grid
       should be wiped, but it was not"). A revert restores pre-run source, so every row - and the
       tick stamps certifying them - describes files that no longer exist on disk. Same wipe as a
       workspace change; what differs is only what happens AFTER (see each caller). */
    Procedure ResetBoardForChangedSource
        Set psLastPlanStamp   to ""
        Set psAutoPlanTriedWS to ""
        Set piChkActionable   to -1
        Set piChkListed       to -1
        Set piChkOutsideErr   to 0
        Set piChkHidden       to 0
        Set pbCharModeCheck   to False
        /* The Findings Themselves, which clearing the view's own counters did NOT touch (Nils
           2026-07-29: "after a workspace change the FINDINGS section needs to be reset"). The board
           renders from the analyzer grid, and the grid was still holding the PREVIOUS workspace's
           rows - so they redrew under the new workspace's name, beside the new workspace's hidden
           count, because the ignore list is per-workspace and the rows were not. Two halves of one
           board describing two different projects.
           The tick stamps go with them: piChkTickAnalyze is what tells the render "a Check has been
           looked at this session", and left standing it certified the stale rows as this
           workspace's verdict. A Check ran, but not for THIS .sws - which makes it no Check at all. */
        Set piChkTickStart   of ghoApplication to 0
        Set piChkTickScan    of ghoApplication to 0
        Set piChkTickCompile of ghoApplication to 0
        Set piChkTickAnalyze of ghoApplication to 0
        // Both verdicts are about a run on the workspace we just left.
        Set pbGuardFoundNothing   to False
        Set pbConvertFoundNothing to False
        Set pbChkDoneAnnounced    to False
        If (ghoModAnalyzerDock <> 0) ;
            Send ResetAnalyzerData of (oModAnalyzer_grd(ghoModAnalyzerDock))
        Send RefreshTiles
    End_Procedure

    Procedure WorkspaceChanged
        Boolean bRestoring

        Send ResetBoardForChangedSource
        // A DIFFERENT workspace may have its own saved Check - restore it (one shot per .sws).
        Get MaybeRestoreLastCheck to bRestoring
    End_Procedure

    /* Broadcast by the Revert dialog after it restored files. The board wipe without the restore:
       the revert has already cleared this workspace's analyze snapshot, so there is nothing valid
       to bring back - the truthful board is an empty one saying "not analyzed", and the next
       Check rebuilds it from the reverted source. */
    Procedure SourceReverted
        /* A revert puts back what [Rename them] retired, so the two memos that count those
           copies are stale - and neither key moves on a revert, the listing stamp and the home
           being what they were. Cleared outright, as [Rename them] clears them (2026-09-02). */
        Set pbSysOverrideBuilt to False
        Set psSysOverrideStamp to ""
        Set psShadowMemoStamp  to ""
        Send ResetBoardForChangedSource
        Send RefreshFindings
    End_Procedure

    /* Broadcast by the Test Compile bar's Clear, which empties the analyzer grid this board renders its
       findings from (Nils 2026-09-30). The board's own counters and tick stamps go with the rows - the same
       wipe as a workspace change - so it says "not analyzed" rather than presenting the emptied grid as a
       Check that found nothing. The saved Check stays: the source has not changed, so it is still true. */
    Procedure AnalysisCleared
        Send ResetBoardForChangedSource
        Send RefreshFindings
    End_Procedure

    /* THE LIST BEHIND "Which files?" - what the tooltip used to hint at and could not deliver.

       BOTH SIDES OF EACH PAIR, because the leaf name alone is what made this hard to act on: the
       user needs to know WHICH copy of a common name is winning (the workspace can hold several)
       and WHAT it is standing in front of. Full paths, one pair per file, plus the two facts the
       Rename dialog decides on - did this build read it, and is it identical.

       Rendered from the memo the line already built, so the dialog and the sentence above it can
       never disagree about the count - and no second scan runs to open a list. */
    Procedure DoShowShadowedFiles
        tShadowCopy[] aRows
        String sMsg sTitle
        Integer i iLast

        Get paSysOverride to aRows
        Move "Copies of DataFlex system packages" to sTitle
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (aRows[i].eKind = eShadowFailingPackage) ;
                Move "Overriding copies" to sTitle
        Loop
        If (iLast < 0) Begin
            Send FTInfoBox "No copies of DataFlex system packages were found in this workspace's own source." ;
                "Copies of DataFlex system packages"
            Procedure_Return
        End
        Move "" to sMsg
        For i from 0 to iLast
            If (i > 0) ;
                Move (sMsg + "\n") to sMsg
            Move (sMsg + aRows[i].sLeaf + "\n") to sMsg
            Move (sMsg + "    workspace copy : " + aRows[i].sPath + "\n") to sMsg
            If (aRows[i].eKind = eShadowFailingPackage) Begin
                Move (sMsg + "    package file   : " + aRows[i].sShipped + "\n") to sMsg
                Move (sMsg + "    package        : " + aRows[i].sSource + ", " + String(aRows[i].iPackageErrors) ;
                    + " error(s) in this build - the copy may be what breaks it" + "\n") to sMsg
            End
            Else ;
                Move (sMsg + "    shipped file   : " + aRows[i].sShipped + "\n") to sMsg
            // which of the two this build read - the fact that decides what the rename changes
            If (aRows[i].iClass <> 0) ;
                Move (sMsg + "    this build     : did not read the workspace copy - it compiles nothing today" + "\n") to sMsg
            Else ;
                Move (sMsg + "    this build     : COMPILED THE WORKSPACE COPY in place of the shipped file" + "\n") to sMsg
            If (aRows[i].bSame = True) ;
                Move (sMsg + "    content        : identical to the shipped file" + "\n") to sMsg
            Else ;
                Move (sMsg + "    content        : DIFFERENT from the shipped file - compare the two before renaming" + "\n") to sMsg
            If (aRows[i].bKept = True) ;
                Move (sMsg + "    decision       : KEPT by you - off the line and out of the dialog until the kept chip offers it again" + "\n") to sMsg
        Loop
        Move (sMsg + "\nRename them... opens this list with a tick per file - identical copies ticked, " ;
            + "different ones not - and renames the ticked ones to <name>.shadowed. For a copy this " ;
            + "build compiled that changes the next build; for one it did not read it changes nothing " ;
            + "until the day the compiler would have reached it.") to sMsg
        Send FTInfoBox sMsg sTitle
    End_Procedure



    /* Hands back through sMsg the result message of a retire: the renamed count, the files left
       unticked (iLeft), the files that could not be renamed (asFailed), the ones that took a
       numbered name (asTwins) and - when anything was renamed - the Run-Check-again note. */
    Procedure _ShadowRetireResultMsg Integer iDone Integer iLiveDone Integer iLeft Integer iKept String[] ByRef asFailed String[] ByRef asTwins String ByRef sMsg
        Integer iFail iTwins i iLast

        // PLAIN TEXT, not markup: FTInfoBox is the message-box wrapper, and every other caller
        // passes text with a literal \n. HelpParagraph here would print its own tags.
        Move (SizeOfArray(asFailed)) to iFail
        Move (String(iDone) + " file(s) renamed to <name>.shadowed.") to sMsg
        // The unticked rows went one of two ways, and the closer the user pressed says which:
        // left for later (still on the line, offered again) or KEPT (recorded, off the line).
        If (iLeft > 0) ;
            Move (sMsg + "\n\n" + String(iLeft) + " left as they are - not ticked. They stay on the board's " ;
                + "line and are offered again the next time.") to sMsg
        If (iKept > 0) ;
            Move (sMsg + "\n\n" + String(iKept) + " kept by your decision - off the board's line and out of " ;
                + "the dialog. The line's '" + String(iKept) + " kept' chip lists them and can offer them again.") to sMsg
        If (iFail > 0) Begin
            Move (sMsg + "\n\n" + String(iFail) + " could not be renamed:") to sMsg
            Move (iFail - 1) to iLast
            For i from 0 to iLast
                Move (sMsg + "\n" + asFailed[i]) to sMsg
            Loop
        End
        /* A NUMBERED TWIN (2026-09-14): an earlier retire's <name>.shadowed was still there - a
           Revert had put the live copy back - so this copy took the next free number instead of
           failing on it. Each line says whether the older twin is identical. */
        Move (SizeOfArray(asTwins)) to iTwins
        If (iTwins > 0) Begin
            Move (sMsg + "\n\n" + String(iTwins) + " took a numbered name, because an earlier retire's " ;
                + "<name>.shadowed was still there. Nothing is deleted:") to sMsg
            Move (iTwins - 1) to iLast
            For i from 0 to iLast
                Move (sMsg + "\n" + asTwins[i]) to sMsg
            Loop
        End
        /* NAME THE CONTROL THE READER HAS. "Build the program again" was the right idea under the
           wrong verb: on this board nothing is called Build - Check is what compiles and rebuilds
           the findings, and it is the only control here that does. Nils 2026-08-31, after a retire
           left the line standing: "If a new Check is needed, that should clearly have been said."
           It also names the risk the confirm raised, at the moment it can actually bite: a copy
           that was a deliberate fork fails on that next compile, not on the rename. */
        If (iLiveDone > 0) ;
            Move (sMsg + "\n\nRun Check again now - it compiles against the installed files and " ;
                + "rebuilds this board. Until you do, every finding on it still comes from the " ;
                + "compile that read the old copies, and a copy that was a deliberate fork will " ;
                + "only fail on that next compile.") to sMsg
        // Only copies this build never read: the board describes a compile that did not involve
        // them, so it is not stale, and there is nothing a Check would show differently.
        Else If (iDone > 0) ;
            Move (sMsg + "\n\nNone of these was read by this build, so nothing on the board changes - " ;
                + "they are simply out of the compiler's way for good.") to sMsg
    End_Procedure

    /* RENAME the workspace copies the user ticks - the overriding-copies line's "Rename them...".

       THE DIALOG CARRIES THE DECISION, row by row (Nils 2026-09-15, after the library-file copies
       joined the line: "we probably need to suggest this on a file-by-file basis", and for the
       install copies too: "Yes, move the install line to the same per-file dialog"). It replaced a
       confirm that named the risk and then renamed every copy - right for decades-old copies of
       system files, wrong for the copies of library files, every one of which differed from the
       library's on the five workspaces measured. The dialog ticks an identical copy, leaves a
       DIFFERENT one unticked, and shows both facts per row; RetireShadowCopies then touches only
       what is ticked. No exception list in either direction: an unticked copy is offered again.

       AND IT SAYS REBUILD. A retire changes nothing the running board can see: the findings on
       screen were produced by a compile that read the OLD copies, so the board is stale the moment
       this succeeds. The result dialog says so; the cache stamp is cleared so the line recomputes. */
    Procedure DoFixShadowedFiles
        Handle ho
        tShadowCopy[] aRows aDue
        String[] asFailed asTwins asAll
        String sMsg sHome sInstall
        Boolean bOk bKeepRest
        Integer iDone iLiveDone iLeft iKept i iLast iSafe

        // The rows are read off the memo the line was built from, so the dialog can never list a
        // copy the sentence above it did not count - and a copy the user already decided to keep
        // is not offered: that is what the decision means, and the kept chip is its way back.
        Get paSysOverride to aRows
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (aRows[i].bKept = False) ;
                Move aRows[i] to aDue[-1]
        Loop
        If (SizeOfArray(aDue) = 0) Begin
            Send FTInfoBox ("Nothing to rename - this board is not listing an overriding copy " ;
                + "for this workspace that you have not decided to keep. Run Check to compile and " ;
                + "rebuild the list, or use the kept chip to offer a kept copy again.") "Nothing to rename"
            Procedure_Return
        End
        /* A DIFFERENT copy that adds nothing the workspace uses comes ticked (Nils 2026-11-12). That is the one
           answer here that needs the workspace's source, so it is asked as the dialog opens, not while the
           board draws (cShadowedPackageFiles.MarkCopiesThatAddNothingUsed). */
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho <> 0) Begin
            Send Cursor_Wait of Cursor_Control
            Get psHomeTarget of ghoApplication to sHome
            Get WorkspaceSourceFiles of ho sHome to asAll
            Get psTargetPkgFolder of ghoApplication to sInstall
            Get MarkCopiesThatAddNothingUsed of ho (&aDue) (&asAll) sInstall to iSafe
            Send Cursor_Ready of Cursor_Control
            Send Destroy of ho
        End
        Get ChooseShadowCopiesToRetire (&aDue) (&bKeepRest) to bOk
        If (bOk = False) ;
            Procedure_Return
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho = 0) ;
            Procedure_Return
        Get RetireShadowCopies of ho (&aDue) (&asFailed) (&asTwins) (&iLiveDone) to iDone
        /* THE UNTICKED, by the closer pressed: left for later, or recorded as KEPT - the one
           deliberate act that writes the record (Nils 2026-09-15, choosing "Explicit Keep": "an
           unticked-to-look-at-later row" must never leave the line by omission). */
        Move 0 to iLeft
        Move 0 to iKept
        Move (SizeOfArray(aDue) - 1) to iLast
        For i from 0 to iLast
            If (aDue[i].bTicked = False) Begin
                If (bKeepRest = True) Begin
                    Send RememberKept of ho aDue[i].sPath aDue[i].sLeaf
                    Increment iKept
                End
                Else ;
                    Increment iLeft
            End
        Loop
        Send Destroy of ho

        // The line is memoised against the compiled-scope stamp, which a rename does not change.
        Set pbSysOverrideBuilt to False
        Set psSysOverrideStamp to ""
        Set psShadowMemoStamp  to ""         // the copy tally moves with the same rename

        Send _ShadowRetireResultMsg iDone iLiveDone iLeft iKept (&asFailed) (&asTwins) (&sMsg)
        Send FTInfoBox sMsg "Overriding copies renamed"
        Send RefreshFindings
    End_Procedure

    /* OFFER THE KEPT COPIES AGAIN - the reverse of the decision, so a verdict the board makes
       permanent is not one the user has to edit a JSON file to undo.

       It forgets the RECORD, not the file: nothing on disk moves, the copies stay exactly where the
       user put them, and the only change is that the line counts them and Rename them... lists them
       next time. That is why the confirm can be brief - there is nothing here to lose. */
    Procedure DoUnkeepShadowedFiles
        Handle ho
        tShadowCopy[] aRows
        String sList
        Boolean bOk
        Integer i iLast iKept

        Get paSysOverride to aRows
        Move "" to sList
        Move 0 to iKept
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (aRows[i].bKept = True) Begin
                Increment iKept
                Move (sList + (BoldHtml(HtmlEscaped(Self, aRows[i].sLeaf))) + " " + CS_EmDash + " " ;
                    + (HtmlEscaped(Self, aRows[i].sPath)) + CS_Br) to sList
            End
        Loop
        If (iKept = 0) Begin
            Send FTInfoBox "No copy is being kept here." "Offer them again"
            Procedure_Return
        End
        Get FTHtmlMessage "Offer these again" ;
            (HelpParagraph("You decided to keep these copies, so the line and " + (BoldText("Rename them...")) ;
                + " have been leaving them out:") ;
             + HelpParagraph(sList) ;
             + HelpParagraph("Offer them again? Nothing on disk changes - the files stay exactly where " ;
                + "they are; the next Rename them... simply lists them once more.")) ;
            "Offer them again" "Not now" to bOk
        If (bOk = False) ;
            Procedure_Return
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho = 0) ;
            Procedure_Return
        For i from 0 to iLast
            If (aRows[i].bKept = True) ;
                Send ForgetKept of ho aRows[i].sPath
        Loop
        Send Destroy of ho
        Set pbSysOverrideBuilt to False
        Set psSysOverrideStamp to ""
        Send FTInfoBox (String(iKept) + " cop" + (If(iKept = 1, "y", "ies")) + " will be offered again by Rename them...") ;
            "Offer them again"
        Send RefreshFindings
    End_Procedure

    /* RENAME THE LANGUAGE SETTING BACK - the "Rename it back..." on the line. No backup, unlike
       [Rename them]: the file keeps its bytes and the rename overwrites nothing, so all that changes
       is the name, and the next build's language with it. */
    Procedure DoRestoreLanguageSetting
        Handle ho
        String sRetired sLanguage sInstall sWhy
        Boolean bOk

        Get psRetiredLanguageFile to sRetired
        Get psRetiredLanguage     to sLanguage
        Get psInstallLanguage     to sInstall
        If (sRetired = "") Begin
            Send FTInfoBox "No language setting is waiting to be renamed back." "Rename it back"
            Procedure_Return
        End
        Get FTHtmlMessage "Rename the language setting back" ;
            (HelpParagraph((HtmlEscaped(Self, sRetired)) + " picks " + (BoldText(HtmlEscaped(Self, sLanguage))) ;
                + ". It was renamed away, so DataFlex's own texts in this workspace's programs now compile in " ;
                + (HtmlEscaped(Self, sInstall)) + ".") ;
             + HelpParagraph("Rename it back to " + (BoldText(CS_LanguageSettingFile)) + "? The next build then compiles " ;
                + "those texts in " + (HtmlEscaped(Self, sLanguage)) + " again.")) ;
            "Rename it back" "Not now" to bOk
        If (bOk = False) ;
            Procedure_Return
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho = 0) ;
            Procedure_Return
        Get RestoreLanguageSetting of ho sRetired to sWhy
        Send Destroy of ho
        Set pbSysOverrideBuilt to False
        Set psSysOverrideStamp to ""
        Set psShadowMemoStamp  to ""         // the copy tally moves with the same rename
        If (sWhy <> "") ;
            Send FTInfoBox ("Could not rename it back: " + sWhy) "Rename it back"
        Else ;
            Send FTInfoBox (CS_LanguageSettingFile + " is back. Run Check now, so the next build compiles " ;
                + "DataFlex's own texts in " + sLanguage + ".") "Rename it back"
        Send RefreshFindings
    End_Procedure

    /* STAY WITH THE INSTALL'S LANGUAGE - the line's other answer. Nothing on disk moves: the decision
       is recorded, the line goes, and renaming the file back by hand is the way back. A live
       Language_Current.inc is never offered, so that needs no second record. */
    Procedure DoKeepInstallLanguage
        Handle ho
        String sRetired sLanguage sInstall

        Get psRetiredLanguageFile to sRetired
        Get psRetiredLanguage     to sLanguage
        Get psInstallLanguage     to sInstall
        If (sRetired = "") ;
            Procedure_Return
        Get Create (RefClass(cShadowedPackageFiles)) to ho
        If (ho = 0) ;
            Procedure_Return
        Send RememberKept of ho sRetired (ExtractFileName(sRetired))
        Send Destroy of ho
        Set pbSysOverrideBuilt to False
        Set psSysOverrideStamp to ""
        Send FTInfoBox ("This workspace stays in " + sInstall + ", and this line will not come back. " ;
            + sRetired + " stays where it is: to use " + sLanguage + " again, rename it to " ;
            + CS_LanguageSettingFile + " by hand.") ("Stay in " + sInstall)
        Send RefreshFindings
    End_Procedure


    /* The user's own Clear, from the board's tail chip. TWO questions, one dialog each (the
       Studio-conventions rule): first the wipe itself, then - only if a saved Check exists on
       disk - whether it goes too. They are different decisions: the board is this session's
       view, the JSON is what MaybeRestoreLastCheck would quietly bring back next time, and
       clearing one while keeping the other is a legitimate choice. The snapshot registry
       follows the FILE, not the wipe - counts describing a Check that can still be restored
       are not stale, counts describing a deleted one are. */
    Procedure DoClearBoard
        String sPlanFile
        Boolean bOk bExists

        Get FTHtmlMessage "Clear the findings board" ;
            (HelpParagraph("Clear every row from the findings board? Nothing in the source changes - the next " ;
                + (BoldText("Check")) + " rebuilds the list from the code as it stands.")) ;
            "Clear" "Not now" to bOk
        If (bOk = False) ;
            Procedure_Return
        Send ResetBoardForChangedSource
        Send RefreshFindings

        /* THE SECOND QUESTION WAITS FOR ITS OWN TICK. ShowConfirm routes an input-less confirm to
           the message box, and that box cannot nest with itself (the 2026-08-15 split's own rule):
           popping it again in the same breath - while its web objects are mid-teardown and the
           board re-render is in flight - raised err 99 on oMbBody_hb at the client, and the
           unhandled error took the queued board update down with it, so the wipe LOOKED like it
           had not happened (Nils, 2026-08-27). Same cure as every board action: a fresh timer
           tick, off the WebView2 pump. */
        Get SavedPlanJsonPath of ghoApplication to sPlanFile
        Get vFilePathExists sPlanFile to bExists
        If (bExists = True) ;
            Send ArmAction of (oChkDeferTimer(Self)) CI_ChkAskDeleteSavedCheck
    End_Procedure

    /* Tick two of Clear board: the saved-Check question, asked only once the first box has fully
       closed and the emptied board has rendered. A different decision from the wipe - the JSON is
       what MaybeRestoreLastCheck would quietly bring back next time - and the registry snapshot
       follows the FILE: counts describing a Check that can still be restored are not stale,
       counts describing a deleted one are. */
    Procedure DoAskDeleteSavedCheck
        String sPlanFile sName
        Boolean bOk bExists
        Integer iVoid

        Get SavedPlanJsonPath of ghoApplication to sPlanFile
        Get vFilePathExists sPlanFile to bExists
        If (bExists = False) ;
            Procedure_Return
        Get ParseFileName of ghoApplication sPlanFile to sName
        Get FTHtmlMessage "Delete the saved Check as well?" ;
            (HelpParagraph("The saved Check for this workspace (" + sName + ") still holds these findings, and " ;
                + "would restore them the next time this workspace is opened. Delete it as well?")) ;
            "Delete it" "Keep it" to bOk
        If (bOk = False) ;
            Procedure_Return
        Get vDeleteFile sPlanFile to iVoid
        Send ClearAnalyzeSnapshot of ghoApplication (psSWSFile(ghoApplication))
        Move 0 to ghiLastAnalyzeDone
        Send RefreshTiles
    End_Procedure

    /* Re-render the tiles. bWithFindings False leaves the findings list EXACTLY as it is.

       Coming back from the editor re-activates this view, and a full refresh rebuilt the findings
       HTML - which recomputes every band's <details open> from scratch, so the band the user had
       open collapsed and had to be re-opened on every single jump-to-source (Nils 2026-07-28).
       The findings cannot have changed by merely returning to the view: they change when a Check
       runs or when the ignore list moves, and both of those paths call RefreshFindings themselves. */
    /* ARM THE AUTOMATIC UPDATE CHECK - once per workspace, and only when an answer is possible.

       Three refusals, each for its own reason:
         no workspace   - nothing to scan.
         switched off   - the preference; default on, see PackageUpdateCheckEnabled.
         already done   - UpdateScanDone is keyed on the workspace, so re-entering this board (which
                          happens on every tab switch) costs nothing, while LOADING a different
                          workspace does arm a fresh scan.

       Arming only queues it. The scan itself waits for the timer, so the board paints first. */
    Procedure ArmPackageUpdateScan
        String sWS

        Get psSWSFile of ghoApplication to sWS
        If (sWS = "") ;
            Procedure_Return
        If ((PackageUpdateCheckEnabled()) = False) ;
            Procedure_Return
        If ((UpdateScanDone(ghoLibraryReport, sWS)) = True) ;
            Procedure_Return
        Send ArmAction of oChkDeferTimer CI_ChkUpdateScan
    End_Procedure

    Procedure RefreshTilesKeepFindings Boolean bWithFindings
        Send PrimeCombo
        Send UpdateHtml of (oTile_Crumb(oWebHost(Self)))     (WorkspaceCrumbHtml(ghoTileMarkup))
        Send UpdateHtml of (oTile_Setup(oWebHost(Self)))     (SetupLibsRowHtml(ghoTileMarkup))
        Send ArmPackageUpdateScan
        // FINDINGS BEFORE STEPS: the findings render is what computes piChkActionable, and the steps
        // tile reads it to decide whether stage 2 is finished. Rendered the other way round the trail
        // was always one refresh behind the list it describes.
        If (bWithFindings = True) ;
            Send UpdateHtml of (oTile_Findings(oWebHost(Self))) (FindingsListHtml(oWebHost(Self)))
        Send UpdateHtml of (oTile_Steps(oWebHost(Self))) (StepsTileHtml(oWebHost(Self)))
        // Migration progress rides the body tile's check row now, so BodyTileHtml carries it - one
        // UpdateHtml instead of two. Still the shared builder, so the gates and the muted/inert
        // empty state stay single-sourced; it reads the per-workspace history JSON, so this refresh
        // costs a file read.
        Send UpdateHtml of (oTile_Body(oWebHost(Self)))  (BodyTileHtml(oWebHost(Self)))
        // The after-a-run utilities, from the shared tile markup so the gates stay single-sourced.
        // Its heaviest gate is a recursive backup-folder walk, which is why it rides the tile
        // refresh rather than being recomputed per click.
        Send PushHtml of (oTile_Actions(oWebHost(Self))) (ActionRowHtml(ghoTileMarkup))
    End_Procedure

    // Build the "Ignore all N" rows for ONE band's function tally. Shared so both bands emit an
    // identical control and neither can drift from the other.
    /* One FOLDABLE section per group: the header names it, and its own findings live INSIDE it.

       The first cut stacked every group header at the top of the band and then listed all 1,446
       rows flat underneath, so a "47x W 4534" line sat nowhere near the 47 rows it described
       (Nils 2026-07-28: "if those items at least would be a part of a foldable first line ... it
       would had made some sort of sense"). Now the band holds ~8 collapsed lines, and opening one
       shows exactly the findings that line is about.

       Nested <details> inside the band's own <details> - native, no script, same as the bands.
       Every group starts CLOSED: the point is a short board, and one that opened 425 rows would
       be the flat list again. The Ignore action rides in the summary; clicking it also toggles the
       fold, which does not matter because a successful ignore re-renders the group away entirely. */
    Function DismissRowsHtml String[] ByRef asFn Integer[] ByRef aiCount String[] ByRef asHint String[] ByRef asRows String sKind Returns String
        Integer i iLast
        String sOut sRow

        Move "" to sOut
        Move (SizeOfArray(asFn) - 1) to iLast
        For i from 0 to iLast
            Move ((('<details class="grp"><summary>' + (SpanOpen("tw")) + CS_PlayTriangle) + CS_SpanEnd)) to sRow
            Move (sRow + (SpanOpen("bdg bdg-c")) + String(aiCount[i]) + CS_Times + CS_SpanEnd) to sRow
            Move (sRow + (SpanOpen("fmsg")) + asFn[i] + CS_SpanEnd) to sRow
            /* title= as well, for the same reason the ordinary rows carry one: this cell
               ellipsizes and the tail is where the instruction lives. Nils 2026-07-29: "the rest is
               chopped off, and no tooltip to show the full text." */
            Move (sRow + (TagTipText("span", "fhint", asHint[i], asHint[i]))) to sRow
            Move (sRow + (ChipHtml("fact", "fact off", "ignorefn", (sKind + '|' + asFn[i]), ('Ignore all ' + String(aiCount[i])), "", True)) + '</summary>') to sRow
            Move (sRow + (DivOpen("grows")) + asRows[i] + (CS_DivEnd + '</details>')) to sRow
            Move (sOut + sRow) to sOut
        Loop
        Function_Return sOut
    End_Function

    /* Count rows per refactoring function, for the bulk-dismissal rows. Parallel arrays rather than a
       struct: the caller only ever needs "name -> count" and a stable emit order, and a plain
       SearchArray over a String[] is the cheap lookup (same reasoning as the scan cache's asPathsLow).
       A row with no function name is skipped - there is nothing to dismiss it BY. */
    Function TallyDismissable String[] ByRef asFn Integer[] ByRef aiCount String[] ByRef asHint String sFn String sHint Returns Integer
        Integer iIdx

        Move (Trim(sFn)) to sFn
        If (sFn = "") ;
            Function_Return -1
        Move (SearchArray(sFn, asFn)) to iIdx
        If (iIdx >= 0) Begin
            Move (aiCount[iIdx] + 1) to aiCount[iIdx]
            Function_Return iIdx
        End
        Move sFn to asFn[-1]
        Move 1   to aiCount[-1]
        // The FIRST row's hint stands for the group. Checked against the real saved plan: these
        // groups are overwhelmingly uniform - 531/531, 425/425, 342/342 share a single hint - so the
        // first is a faithful label, and it is the only thing that answers "ignore WHAT?" on the row.
        Move (Trim(sHint)) to asHint[-1]
        Function_Return (SizeOfArray(asFn) - 1)
    End_Function

    /* Returns the key one saved-plan row is matched on for an ignore group of kind sKind: the
       refactoring function for F, the lower-cased file leaf for U, the WHOLE Msg cell otherwise. */
    Function _IgnoreGroupRowKey String sKind String sFn String sFile String sMsg Returns String
        String sRowKey

        If (sKind = "F") ;
            Move (Trim(sFn)) to sRowKey
        Else If (sKind = "U") ;
            Move (Lowercase(ExtractFileName(sFile))) to sRowKey
        Else ;
            Move (Trim(sMsg)) to sRowKey
        Function_Return sRowKey
    End_Function

    /* Adds each SINGLE message token of one row's Msg cell (sMsg, possibly a ", "-joined list) for
       sFile to aIgnored, skipping the ones already there, and counts every addition in iAdded. */
    Procedure _IgnoreRowMsgTokens Handle ho String sFile String sMsg tModIgnore[] ByRef aIgnored Integer ByRef iAdded
        String[] asMsgTok
        String sTok
        Integer j iTok iN
        Boolean bExists

        Get SplitMsgList of ho sMsg to asMsgTok
        Move (SizeOfArray(asMsgTok) - 1) to iTok
        For j from 0 to iTok
            Move asMsgTok[j] to sTok
            Get IsIgnored of ho sFile sTok (&aIgnored) to bExists
            If (bExists = False) Begin
                Move (SizeOfArray(aIgnored)) to iN
                Move sFile to aIgnored[iN].sFile
                Move sTok           to aIgnored[iN].sMsg
                Increment iAdded
            End
        Loop
    End_Procedure

    /* Ignore every listed row in one group, by writing the SAME per-workspace ignore list the
       analyzer grid writes (cModAnalyzer). Two surfaces, one list - dismissing here hides the rows
       there too, which is the point: a second opinion about what is hidden is worse than no feature.

       sParam is "<kind>|<key>". Kind F matches the refactoring FUNCTION (the Review band, whose rows
       are converter-backed); kind M matches the MESSAGE (the hand-migration band, whose rows have no
       function at all - Explain and Unknown are by definition what no converter handles, so grouping
       them by function produced nothing to click).

       The Msg cell of a MERGED row can be a ", "-joined LIST ("W 4533, W 4538"), and
       DropIgnoredMessages keys per SINGLE message - so each token is ignored separately. Storing the
       joined string never round-trips and the row silently comes back, which is the defect the grid's
       own ignore path had to fix. Matching for kind M compares the WHOLE cell, because that is what
       the group row displayed and therefore what the user chose. */
    Procedure IgnoreFindingsForGroup String sParam
        Handle ho
        Integer i iLast iAdded iPos
        String sKind sKey sRowKey
        tSavedPlanRow[] aRows
        tModIgnore[] aIgnored
        Boolean bMatch

        Move (Pos("|", sParam)) to iPos
        If (iPos < 2) ;
            Procedure_Return
        Move (Left(sParam, (iPos - 1))) to sKind
        Move (Trim(Right(sParam, (Length(sParam) - iPos)))) to sKey
        If (sKey = "") ;
            Procedure_Return
        /* "U" groups are keyed by the FILE the messages sit on, named by its leaf - the obsolete
           install package. Case-folded because the key travelled through the markup as the package
           wrote its own name, while the compiler reports the path however the include resolved it. */
        If (sKind = "U") ;
            Move (Lowercase(sKey)) to sKey
        /* THE WHOLE STRETCH IS BUSY (Nils 2026-10-04: "When a 'Ignore all xx' button is clicked it can take
           a while until the work is done"). The wait cursor used to come on after the rows were read and go
           off BEFORE the re-render - the grid's re-filter and the whole board, the slow part - so the click
           looked like nothing. BoardBusyOn / BoardBusyOff now hold it, with the marquee and a status note,
           from the first read to the last repaint. */
        Send BoardBusyOn "Hiding the findings you ignored..."
        Get BuildSavedPlanRows of (oModAnalyzer_grd(ghoModAnalyzerDock)) to aRows
        Move (SizeOfArray(aRows) - 1) to iLast
        Move 0 to iAdded
        If (iLast >= 0) Begin
            Get Create (RefClass(cModAnalyzer)) to ho
            Get ReadIgnored of ho to aIgnored
            For i from 0 to iLast
                Get _IgnoreGroupRowKey sKind aRows[i].sFn aRows[i].sFile aRows[i].sMsg to sRowKey
                Move (sRowKey = sKey) to bMatch
                If (bMatch = True and Trim(aRows[i].sFile) <> "" and Trim(aRows[i].sMsg) <> "") Begin
                    Send _IgnoreRowMsgTokens ho aRows[i].sFile aRows[i].sMsg (&aIgnored) (&iAdded)
                End
            Loop
            If (iAdded > 0) ;
                Send WriteIgnored of ho aIgnored
            Send Destroy of ho
        End
        If (iAdded > 0) ;
            Send RefreshIgnoredAndRender
        Send BoardBusyOff
    End_Procedure

    /* Ignore ONE row: that file's finding, written to the same per-file, per-message-token list the
       group action and the analyzer grid write (Nils 2026-09-05, LegacyApp: two Grid dialogs, ReadMsg.dg
       and SENDMSG.DG, that are to stay as they are while the other DS 9191 rows run the plan). The
       group action is for floods; this is for the exception inside a group the user otherwise wants
       to run. Until now the only way out was the analyzer grid's Ignore Row(s): a Review row that
       carries a converter has no dismissal group, only the band's one Run-the-plan chip.

       sParam is "<file>|<msg>", the row's own cell values. A path never contains "|", so the first
       one is the boundary. Every token of a merged Msg cell is written separately, exactly as the
       group action does - IsRowIgnored hides a row only when ALL its tokens are listed. The plan
       reads the ignore-filtered set, so the row leaves the plan together with the board. */
    Procedure IgnoreFindingRow String sParam
        Handle ho
        Integer iPos iAdded
        String sFile sMsg
        tModIgnore[] aIgnored

        Move (Pos("|", sParam)) to iPos
        If (iPos < 2) ;
            Procedure_Return
        Move (Trim(Left(sParam, (iPos - 1)))) to sFile
        Move (Trim(Right(sParam, (Length(sParam) - iPos)))) to sMsg
        If (sFile = "" or sMsg = "") ;
            Procedure_Return
        // Busy from the write to the last repaint, as the group action is (see IgnoreFindingsForGroup).
        Send BoardBusyOn "Hiding the finding you ignored..."
        Get Create (RefClass(cModAnalyzer)) to ho
        Get ReadIgnored of ho to aIgnored
        Move 0 to iAdded
        Send _IgnoreRowMsgTokens ho sFile sMsg (&aIgnored) (&iAdded)
        If (iAdded > 0) ;
            Send WriteIgnored of ho aIgnored
        Send Destroy of ho
        If (iAdded > 0) ;
            Send RefreshIgnoredAndRender
        Send BoardBusyOff
    End_Procedure

    /* Fill the board from the SAVED plan - the previous Check's frozen result - without re-running
       compile + analyze.

       WHY v1 DID NOTHING (Nils, 2026-07-28: "Did not work"). It set pbSavedView and called
       LoadSavedPlan on the grid directly. But LoadSavedPlan opens with

           If (not(IsComObjectCreated(Self))) ;
               Procedure_Return

       and on a fresh start the analyzer dock has never been realized, so that guard fired and the
       whole call was a SILENT no-op. The stamp still got set - my code carried on - which is exactly
       what Nils saw: the header changed, the board stayed empty, and he was back to running Check.
       Nothing "started a re-analyze"; the feature simply did not happen.

       WHY THE DOCK'S OWN ENTRY IS RIGHT. I avoided ShowSavedPlan because it ends with ShowTab, which
       I assumed switched views. It does not: ShowTab makes the DOCK panel visible and active
       (pbVisible + Activate on the dock) and never touches the TabWorkspace, so the trail stays on
       screen. And that realization is precisely what LoadSavedPlan needs - the dock's Activate then
       runs the guarded Initialize, which sees pbSavedView and loads the frozen plan. The thing I was
       routing around was the thing that makes it work.

       THE COLD-SHOW TICK is not optional, and it is the dashboard's hard-won lesson (View last plan,
       2026-07-01): on the FIRST realization the dock's WebView2 strips can finish on their
       design-time defaults, losing the runtime pushes ShowTab fired before they existed.
       ReassertAnalyzerView re-asserts once warm. Our findings render rides the same tick for a
       plainer reason - the grid must be LOADED before the board is built from it. */
    Procedure ShowLastCheckOnBoard
        Boolean bOK
        Get RestoreLastCheck True to bOK
    End_Procedure

    // bLoud False = the automatic path: it may find nothing and must then simply not happen, so the
    // "no saved Check yet" dialog is for the button press only.
    Function RestoreLastCheck Boolean bLoud Returns Boolean
        Handle ho hoGrid
        Boolean bOK
        String sStaleWhy
        tSavedPlan ThePlan

        If (ghoModAnalyzerDock = 0) ;
            Function_Return False
        Get Create (RefClass(cModAnalyzer)) to ho
        Get ReadSavedPlan of ho (&ThePlan) to bOK
        Get psSavedPlanStaleWhy of ho to sStaleWhy
        Send Destroy of ho
        If (bOK = False) Begin
            /* TWO KINDS OF NO (2026-08-17): never checked, or checked but the plan's compile output no
               longer matches this workspace (a recreated copy at the same path, a cleaned or rewritten
               .prn). The silent path stays silent either way; the button says which. */
            If (bLoud = True) Begin
                If (sStaleWhy <> "") ;
                    Send FTInfoBox sStaleWhy "Last Check is out of date"
                Else ;
                    Send FTStopBox "No saved Check for this workspace yet - run Check once and it will be here next time."
            End
            Function_Return False
        End
        Send Cursor_Wait of Cursor_Control
        Set psLastPlanStamp to (Trim(ThePlan.sDate))
        /* THE LOUD PATH opens the dock, and should: pressing "Show last Check" is a request to LOOK
           at the thing, and the dock is where rows can be double-clicked through to source. Same
           proven sequence as the dashboard's "View last plan" - ShowSavedPlan (whose ShowTab is what
           realizes the grid) plus the 150ms cold-show tick. */
        If (bLoud = True) Begin
            Send ShowSavedPlan of ghoModAnalyzerDock
            Set piTimeout of oChkDeferTimer to 150
            Send ArmAction of oChkDeferTimer CI_ChkFinishLastPlan
            Function_Return True
        End
        /* THE SILENT PATH MUST NOT TOUCH THE FURNITURE (Nils 2026-07-29: "the tab-pages are shown
           above the TestCompile dialog ... it is just wrong").

           Routing this through ShowSavedPlan was wrong twice over. It made three tab-pages appear
           because someone picked a workspace - and worse, it DOCKED the output panel before the Test
           Compile bar had ever been shown. Both sit at xtpBarBottom, and CodeJock stacks bottom bars
           in the order they first dock, so the whole session then ran with the tabs wedged above the
           bar. Hiding the dock again afterwards (my previous attempt) could never have fixed that:
           the damage is done at DOCK time, not at show time, and hiding leaves the slot claimed.

           LoadSavedPlan reads a JSON and fills the grid's DATA properties; only its final repaint
           needs COM. Its old top-of-procedure IsComObjectCreated guard is what forced the detour -
           see the note there. So the board now gets its rows the honest way: no dock, no tab, no
           timer, nothing on screen moves. The dock still paints correctly whenever it is opened
           later, because pbAnalyzeDataReady stays False until a real DisplayFiltered runs, and
           ReassertAnalyzerView re-initializes on that. */
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Set pbSavedView    of hoGrid to True
        Set pbDeepScanView of hoGrid to False
        /* AND IT SAYS WHAT IT IS DOING (Nils 2026-08-31: opening WinServ took "almost exactly 2
           minutes"). This runs on EVERY workspace load with a saved Check, and it is the same
           board render the guided Check pays for - a saved plan of 1993 rows here. It had a wait
           cursor and nothing else, so a slow open looked like a hung program with no clue as to
           which part was slow. Same three signals as every other long render.
           SILENT PATH ONLY. The loud path above hands off to oChkDeferTimer, and BoardBusyOn's
           latch makes that timer defer - it would wait for a BoardBusyOff that only the timer
           itself could reach. */
        Send BoardBusyOn "Restoring the last Check for this workspace..."
        Send LoadSavedPlan of hoGrid
        Send RefreshTiles
        Send BoardBusyOff
        Function_Return True
    End_Function

    /* THE RESTORE THE USER SHOULD NOT HAVE TO ASK FOR (Nils 2026-07-29: "I did not press the 'Show
       last check' button, because it is not needed to view the last check").

       He was right about what he wanted and wrong about what he was looking at: nothing had been
       restored, the board was simply empty, and the persisted ignore count made it read like a
       restored one. Rather than teach the screen to explain that distinction better, remove it -
       arriving at the trail with a saved Check on disk and no Check run this session now loads it.

       ONE SHOT PER WORKSPACE. Re-entering the view must not resurrect a board the user has since
       emptied, and the restore itself re-renders - which re-enters here - so the workspace is
       stamped BEFORE the call, not after. Switching workspace re-arms it; a real Check makes it
       moot (piChkTickAnalyze), which is the honest order: this session's evidence always wins. */
    Function MaybeRestoreLastCheck Returns Boolean
        String sWS sPlanRun
        Boolean bHavePlan bOK
        tAnalyzeSnapshot Snap

        Get psSWSFile of ghoApplication to sWS
        Move (Trim(sWS)) to sWS
        If (sWS = "" or sWS = psAutoPlanTriedWS(Self)) ;
            Function_Return False
        // A Check this session, or a plan already on the board: nothing to restore over.
        If (piChkTickAnalyze(ghoApplication) <> 0 or Trim(psLastPlanStamp(Self)) <> "") ;
            Function_Return False
        Get SavedPlanFileExists of ghoApplication to bHavePlan
        If (bHavePlan = False) ;
            Function_Return False
        /* NOT IF A PLAN RAN AFTER THE ANALYZE (Nils 2026-08-09: after a compile+analyze+run cycle,
           closing and reopening showed "the list with all auto-fix's that was run through before
           restarting").

           The saved plan is a snapshot of the last ANALYZE. A plan run then rewrites the source it
           describes, so those rows name work that is already done - and restoring them silently
           presents finished work as outstanding, which is worse than an empty board because it
           looks authoritative.

           The comparison is the one the guided cycle strip already makes: WritePlanRunStamp against
           the snapshot's own .Date, both ISO date+time, so a plain string compare orders them. It
           is self-healing for free - the next analyze writes a newer .Date and supersedes the
           stamp, exactly as the strip relies on.

           The plan FILE is untouched. "Show last Check" still loads it deliberately, where the
           header says whose Check it is and when it ran; what is withdrawn is the automatic restore
           that cannot caption itself. Deleting it would also break the rule that this app does not
           destroy a user's files on its own. */
        Get ReadPlanRunStamp of ghoApplication to sPlanRun
        If (Trim(sPlanRun) <> "") Begin
            Get ReadAnalyzeSnapshot of ghoApplication to Snap
            If (Snap.bFound = True and sPlanRun > Snap.sDate) Begin
                Set psAutoPlanTriedWS to sWS
                Function_Return False
            End
        End
        Set psAutoPlanTriedWS to sWS
        Get RestoreLastCheck False to bOK
        Function_Return bOK
    End_Function

    // The cold-show follow-up: re-assert the analyzer tab now the dock is warm, then build the board
    // from the grid the previous tick loaded.
    Procedure FinishShowLastCheck
        Send ReassertAnalyzerView of ghoOutputDock
        // The WHOLE board, not just the findings: on the automatic path this tick replaces the light
        // refresh that Activate would otherwise have run, so the other tiles need their turn too.
        Send RefreshTiles
        Send Cursor_Ready of Cursor_Control
    End_Procedure

    // Bring everything back: empty the list and re-render. The one-way-door guard on the whole
    // feature, and the reason the dismissal rows can say "hiding them leaves the work outstanding".
    Procedure ClearIgnoredFindings
        Handle ho
        tModIgnore[] aNone
        Get Create (RefClass(cModAnalyzer)) to ho
        Send WriteIgnored of ho aNone
        Send Destroy of ho
        Send RefreshIgnoredAndRender
    End_Procedure

    /* OFFER THE SCOPE ONCE, WHEN THERE IS NONE (Nils 2026-08-31).

       THE WARNING THIS REPLACES WAS WRONG, and worth recording so it is not rebuilt. It compared
       the folders the workspace declares against the folders the user had selected, and treated
       the difference as a defect. But a folder can be missing from the selection because the user
       REMOVED it - the grid has a right-click Delete - so the signal was indistinguishable from
       ordinary curation. It measured intent, and no amount of suppression could fix that; a
       fingerprint and a session latch were both added trying.

       This asks a question with no intent in it. A workspace opened for the first time - a copy,
       most often - has its folders discovered by SaveNewHeaderAndChildRecords and every one of
       them saved UNSELECTED. Nothing is in scope, so nothing can be scanned, and no Check run
       against it can mean anything. That is a fact about the workspace, not a guess about the
       user, and it clears itself the moment they tick a folder - which is why this needs no
       "seen it" state of any kind. */
    Procedure OfferInitialScope
        String[] asSelected
        String sWS

        Get psSWSFile of ghoApplication to sWS
        If (Trim(sWS) = "") ;
            Procedure_Return
        Get pasSelectedFolders of ghoApplication to asSelected
        // Anything selected at all means the user has been here and decided. Silent.
        If (SizeOfArray(asSelected) > 0) ;
            Procedure_Return
        Send Activate_oSelectFoldersView of (Client_Id(phoMainPanel(ghoApplication)))
        Send FTInfoBox "No source folders are selected for this workspace yet, so there is nothing for a Check to scan.\n\nThe folders below were found in the workspace and its libraries. Tick the ones that belong in scope - and press Re-scan if you have since added a library or a source folder.\n\nThis is asked once: it will not come back after you have made a selection." "Choose what to scan"
    End_Procedure

    /* Returns the paths the last Check actually skipped as one "[path][path]..." key string,
       lower-cased, built from the "<path>|<reason>" entries of asSkipped - so each row of the
       listing can say whether it was skipped or simply never scanned. */
    Function _DeadDepScopeKeys String[] ByRef asSkipped Returns String
        String sScopeLow sRow
        Integer i iBar

        // A path list of what the Check actually skipped, so each row of the listing (_DeadDepFileListing) can say which it was.
        Move "" to sScopeLow
        For i from 0 to (SizeOfArray(asSkipped) - 1)
            Move asSkipped[i] to sRow
            Move (Pos("|", sRow)) to iBar
            If (iBar > 1) ;
                Move (sScopeLow + "[" + Lowercase(Left(sRow, (iBar - 1))) + "]") to sScopeLow
        Loop
        Function_Return sScopeLow
    End_Function

    /* Appends to sMsg one line per file of asAll[0..iLast] ("<path>|<reason>" entries): each family's
       reason once, ahead of the files it covers, then every path tagged [skipped] when it is in the
       sScopeLow key string and [not in scope] otherwise. */
    Procedure _DeadDepFileListing String[] ByRef asAll Integer iLast String sScopeLow String ByRef sMsg
        String sRow sWhy sSeen sPath
        Integer i iBar
        Boolean bInScope

        Move "" to sSeen
        For i from 0 to iLast
            Move asAll[i] to sRow
            Move (Pos("|", sRow)) to iBar
            If (iBar > 1) Begin
                Move (Left(sRow, (iBar - 1))) to sPath
                Move (Right(sRow, (Length(sRow) - iBar))) to sWhy
                // The reason once per family, ahead of the files it covers - it is the same sentence
                // for every file of that family, and repeating it buries the filenames.
                If (sSeen contains sWhy) Begin
                End
                Else Begin
                    Move (sSeen + sWhy) to sSeen
                    Move (sMsg + (Character(10)) + sWhy + (Character(10))) to sMsg
                End
                Move (sScopeLow contains ("[" + Lowercase(sPath) + "]")) to bInScope
                If (bInScope = True) ;
                    Move (sMsg + "    [skipped]     " + sPath + (Character(10))) to sMsg
                Else ;
                    Move (sMsg + "    [not in scope] " + sPath + (Character(10))) to sMsg
            End
        Loop
    End_Procedure

    /* NAME THE FILES THE SCAN LEFT OUT (the findings header's "Which ones?").

       The chip states a count; this answers the question a count provokes. Reporting a skip without
       being able to see it is only marginally better than not reporting it - the reader still
       cannot judge whether the exclusion was right, which is the entire reason it is surfaced.

       The REASON is shown once per family rather than per file. It is the same sentence for every
       Crystal file in the list, and repeating it thirty times would bury the filenames that are
       the actual answer. Filenames only - no paths trimmed away, because which COPY of
       crystalreport.pkg was skipped is part of the answer in these workspaces. */
    Procedure ShowSkippedDeadDependencies
        String[] asSkipped asAll
        String sMsg sRow sScopeLow
        Integer i iLast iBar iInScope iOutside

        Get pasDeadDepSkipped of ghoApplication to asSkipped
        // The whole workspace, not just what the Check collected. Collection is non-recursive, so a
        // dead file one folder down is never skipped and would otherwise never be mentioned - which
        // made the old wording read as an inventory when it was a report about one pass.
        Get WorkspaceDeadDependencyFiles of ghoApplication to asAll
        Move (SizeOfArray(asAll)) to iLast
        If (iLast = 0) Begin
            Send FTInfoBox "No dead-dependency files were found in this workspace."
            Procedure_Return
        End
        Get _DeadDepScopeKeys (&asSkipped) to sScopeLow
        /* THE HEADER'S NUMBERS ARE COUNTED FROM THE LIST, not taken from the skipped array.
           Reading them from two different sets is what let the first version claim "0 outside"
           while marking a row [not in scope] - a readout contradicting its own body. Count what
           will actually be printed, then print it. */
        Move 0 to iInScope
        For i from 0 to (iLast - 1)
            Move asAll[i] to sRow
            Move (Pos("|", sRow)) to iBar
            If (iBar > 1) Begin
                If (sScopeLow contains ("[" + Lowercase(Left(sRow, (iBar - 1))) + "]")) ;
                    Increment iInScope
            End
        Loop
        Move (iLast - iInScope) to iOutside
        Move ("This workspace contains " + String(iLast) + " file(s) belonging to a dependency with no successor - refactoring them is work on code that is going to be deleted, not modernized." + (Character(10))) to sMsg
        Move (sMsg + String(iInScope) + " were in the last Check's scope and were skipped; " + String(iOutside) + " sit outside the selected folders and were never scanned." + (Character(10))) to sMsg
        Move (sMsg + "(Folder selection does not include sub-folders, which is why a file one level down can be present but unscanned.)" + (Character(10)) + (Character(10))) to sMsg
        Decrement iLast
        Send _DeadDepFileListing (&asAll) iLast sScopeLow (&sMsg)
        Send FTInfoBox sMsg
    End_Procedure

    /* Re-derive the board after the ignore list changed. The analyzer grid owns the filtering, so it
       re-filters in place (RefilterIgnored - no .prn re-parse) and this view then rebuilds from the
       grid's rows, exactly as it does after a Check. Both surfaces move together.

       SAVED-PLAN MODE NEEDS A RELOAD, NOT A RE-FILTER (Nils 2026-07-29: after a restart, "Show
       last Check", then "Show them again", the board came back EMPTY). RefilterIgnored re-filters
       the cached LIVE build - and in saved view there is no live build, so it filtered nothing into
       nothing. The grid's own ClearIgnored has always branched on pbSavedView for exactly this
       reason; this reached past that and called the live half directly. LoadSavedPlan re-reads the
       frozen plan and applies the (now empty) ignore list per row, which is what brings the hidden
       rows back. */
    Procedure RefreshIgnoredAndRender
        Handle hoGrid
        Boolean bSaved
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pbSavedView of hoGrid to bSaved
        If (bSaved = True) ;
            Send LoadSavedPlan of hoGrid
        Else ;
            Send RefilterIgnored of hoGrid
        Send RefreshFindings
    End_Procedure

    /* The clean / not-clean sentence of the Check-done dialog for the compiled program sMainEsc
       (already HTML-escaped), from the compiler's RAW error tally and its two off-board shares:
       errors in read-only packages (iOutErr) and errors hidden or set aside (iHiddenErr).
       Returns the sentence as HTML, without a closing stop - the body adds its own. */
    Function _CheckCleanSentence String sMainEsc Integer iRawErr Integer iOutErr Integer iHiddenErr Returns String
        String sClean

        // A character-mode program was not compiled (see _RunCharacterModeCheck), so neither "compiles
        // clean" nor "does NOT compile clean" is true of it; say what is (Nils 2026-09-20).
        If (pbCharModeCheck(Self) = True) ;
            Function_Return ((BoldHtml(sMainEsc)) + " was not compiled: it is a character-mode program, and DataFlex 26 cannot build it until its screen handling has been rewritten by hand (the inventory on the findings board counts that work)")
        If (iRawErr = 0) ;
            Move ((BoldHtml(sMainEsc)) + " compiles clean") to sClean
        Else Begin
            Move ((BoldHtml(sMainEsc)) + (BoldText(" does NOT compile clean:"))) to sClean
            If (iOutErr > 0) ;
                Move (sClean + " " + String(iOutErr) + " error(s) sit in read-only package files (the In packages band names them; they are fixed where the package is maintained, not in this workspace)") to sClean
            If (iHiddenErr > 0) Begin
                If (iOutErr > 0) ;
                    Move (sClean + ", and") to sClean
                Move (sClean + " " + String(iHiddenErr) + " error(s) are not on the board " + CS_EmDash + " hidden rows or set-aside files; the compiler output has the full list") to sClean
            End
        End
        Function_Return sClean
    End_Function

    /* Returns the Check-done dialog's body as HTML: the counts line, the clean sentence (sClean),
       the other projects' health line (sOthers, when any) and the next-stage line. */
    Function _CheckDoneBodyHtml Integer iListed Integer iRawErr String sClean String sOthers ;
                                Integer iReviewPkg Integer iReviewOther Integer iHand ;
                                Integer iHidden Integer iHiddenReport Integer iHiddenFn Returns String
        String sBody sSplit sHid
        Boolean bReady

        /* LEAD WITH THE SPLIT, not with "done" (Nils 2026-07-28). The old text opened "Check & fix
           is done." and qualified it afterwards - so on a board headed FINDINGS 1462 the first
           sentence read as a flat contradiction of the screen behind it, and the number that
           reconciles the two was buried in a subordinate clause. Both statements were true and
           they still fought each other; the tell was Nils not being sure afterwards what the
           dialog had actually said. State both counts in the first line instead: nothing is
           claimed to be finished except the part that is. */
        If (iListed > 0) Begin
            Move ((HelpParagraph((BoldHtml("0 of " + String(iListed) + " findings can be fixed automatically."))))) to sBody
            /* "WORKSHEET" WAS OUR WORD, NOT THE USER'S (Nils 2026-07-29: "the confusing bit is the
               talk about worksheet, can another more understandable word be used?"). It meant "the
               file a report function writes", which is a second name for something the UI already
               calls a REPORT - so the sentence introduced a noun the user had met nowhere else and
               then used it twice. Say what the thing DOES instead: a report lists the places. */
            /* THE SPLIT THE BANDS SHOW, in the dialog's words (Nils 2026-09-04, LegacyApp: "either the
               review section with 10 items is wrong, or the dialog!"). Neither was - the dialog
               said "for some, a report can list every place first" over a board whose ten Review
               rows were obsolete packages to judge, and it sent the user to the function list for
               a report that was not on the board at all: the 69 report rows were hidden by Ignore.
               So the sentence names each kind by its count, and only the kinds that are there;
               and the hidden rows get a sentence of their own, with what the tool could still do
               for them. This dialog only ever fires with the Review AND the by-hand bands EMPTY
               (piChkActionable = 0 counts every row of both since 2026-09-04 / 2026-09-13), so the
               split sentences below are for the record: a board with 68 by-hand rows no longer gets
               a dialog saying "Tidy Up is the next stage" - the band is the next stage. */
            Move "" to sSplit
            If (iReviewPkg > 0) ;
                Move (sSplit + " " + String(iReviewPkg) + (If((iReviewPkg = 1), " is an obsolete DataFlex package", " are obsolete DataFlex packages")) + " that files in the workspace still Use " + CS_EmDash + " check what each file takes from the package, then dismiss the row (the Review band).") to sSplit
            If (iReviewOther > 0) ;
                Move (sSplit + " " + String(iReviewOther) + (If((iReviewOther = 1), " is a review row", " are review rows")) + " with no converter behind " + (If((iReviewOther = 1), "it", "them")) + ".") to sSplit
            If (iHand > 0) ;
                Move (sSplit + " " + String(iHand) + (If((iHand = 1), " is a change", " are changes")) + " to make by hand " + CS_EmDash + " open a row to look at the source.") to sSplit
            Move (sBody + (HelpParagraph(sClean + ", and nothing listed converts automatically. The " + String(iListed) + " listed need a person:" + sSplit))) to sBody
            If (iHidden > 0) Begin
                Move ((BoldHtml(String(iHidden) + " finding" + (If((iHidden = 1), " is", "s are")) + " hidden by your Ignore choices"))) to sHid
                If (iHiddenReport > 0) ;
                    Move (sHid + " " + CS_EmDash + " " + (If((iHiddenReport = iHidden), "all of them", (String(iHiddenReport) + " of them"))) + " belong to " + (If((iHiddenReport = 1), "a report", "reports")) + " the tool can still run for you") to sHid
                Else If (iHiddenFn > 0) ;
                    Move (sHid + " " + CS_EmDash + " " + String(iHiddenFn) + " of them carry a converter or a report") to sHid
                Move (sBody + (HelpParagraph(sHid + ". " + (BoldText("Show them again")) + " in the findings header brings them back."))) to sBody
            End
        End
        Else Begin
            If (iRawErr = 0) ;
                Move ((HelpParagraph((BoldText("Nothing left to fix."))))) to sBody
            Else ;
                Move ((HelpParagraph((BoldText("Nothing left for the tool to fix here."))))) to sBody
            Move (sBody + (HelpParagraph(sClean + (If((iRawErr = 0), " and the board is empty.", "."))))) to sBody
        End
        If (sOthers <> "") ;
            Move (sBody + (HelpParagraph(sOthers))) to sBody
        /* ...unless the trail is FINISHED, in which case pointing at Tidy Up as "the next stage"
           contradicts the Ready the board behind this dialog is showing. Two surfaces describing one
           state have to agree, so this reads the same GuidedStageReady the stepper and the footer do
           rather than assuming the stage after a clean Check is always Tidy Up. */
        Get GuidedStageReady to bReady
        If (bReady = True) ;
            Move (sBody + (HelpParagraph((BoldText("That completes the trail for this program.")) ;
            + " Tidy Up can be run again whenever you want " + CS_EmDash ;
            + " it only acts on what it still finds."))) to sBody
        Else ;
            Move (sBody + (HelpParagraph((BoldText("Tidy Up")) + " is the next stage " + CS_EmDash + " the tidy-and-remove passes that follow modernization."))) to sBody
        Function_Return sBody
    End_Function

    /* Say ONCE, when a Check settles with nothing visible left on the board - for the tool or for a
       person - that stage 2 is finished and what the next stage is. Without it the run simply
       stopped: the board went quiet, the trail
       stayed on "2 Check & fix", and the user was left guessing whether it had finished or failed
       (Nils 2026-07-26: "if there is no more to do, the (WIP) view should have been activated, and
       possibly also some sort of message ... And then onwards to 3 Clean").

       Only after a Check has actually completed (piChkTickAnalyze) and the findings render has
       produced a verdict (piChkActionable >= 0). Reports listed but not runnable are NOT work: they
       are worksheets, so the message names them rather than pretending the board is empty. */
    Procedure AnnounceCheckStageDone
        Boolean bDummy bOthersBad
        Integer iListed iRawErr iOutErr iHiddenErr iReviewRows iReviewPkg iHand iHidden iHiddenReport iHiddenFn
        String  sBody sMainEsc sClean sOthers sBail sCrash

        If (pbChkDoneAnnounced(Self) = True) ;
            Procedure_Return
        If (piChkTickAnalyze(ghoApplication) = 0) ;
            Procedure_Return
        /* NOT COMPILED IS NOT CLEAN (Nils 2026-09-23). A compile that never ran - df-cli could not
           load a workspace file whose name carried åäö - leaves no listing, and this dialog then
           judged whatever the grid still held: "compiles clean and the board is empty, Tidy Up is
           next" over a compiler pane reading "Failed: compiler exited with code 1". The
           compiler's own words come first, whatever the board shows, and nothing else is claimed. */
        Get psChkCompileBail of ghoApplication to sBail
        If (sBail <> "") Begin
            Set pbChkDoneAnnounced to True
            Get HtmlEscaped (Trim(MainProgram(ghoApplication))) to sMainEsc
            If (sMainEsc = "") ;
                Move "The selected program" to sMainEsc
            Move (HelpParagraph((BoldText("The program was not compiled.")))) to sBody
            Move (sBody + (HelpParagraph((BoldHtml(sMainEsc)) + " was not compiled: the compiler stopped before it compiled anything. It said:"))) to sBody
            Move (sBody + (HelpParagraph(Replaces(Character(10), (HtmlEscaped(Self, sBail)), "<br>")))) to sBody
            Move (sBody + (HelpParagraph("Any findings on the board are from before this Check. Fix what the compiler names and press Check again; its full output is in the Compiler Output pane."))) to sBody
            Get FTHtmlMessage "Check workspace" sBody "OK" "" to bDummy
            Procedure_Return
        End
        /* THE COMPILER CRASHED - SAY SO (Nils 2026-10-05, testing a workspace on which the DataFlex 26
           compiler died three Checks in a row: stack overflow twice, heap corruption once). Each time
           the listing stopped in the middle of a line and the Check read it as a finished compile: the
           board showed 29 errors and nothing said that the compile had stopped there. The findings are
           real, but they are not all of them, and no verdict is given over half a compile. */
        Get psChkCompileCrash of ghoApplication to sCrash
        If (sCrash <> "") Begin
            Set pbChkDoneAnnounced to True
            Get HtmlEscaped (Trim(MainProgram(ghoApplication))) to sMainEsc
            If (sMainEsc = "") ;
                Move "The selected program" to sMainEsc
            Move (HelpParagraph((BoldText("The compiler crashed.")))) to sBody
            Move (sBody + (HelpParagraph((BoldHtml(sMainEsc)) + " was compiled only in part: the DataFlex compiler crashed (" + (HtmlEscaped(Self, sCrash)) + ") before it reached the end of the program."))) to sBody
            Move (sBody + (HelpParagraph("The findings on the board are from the part it had compiled, so there may be more. The crash is a fault in the compiler, not in a refactoring."))) to sBody
            Move (sBody + (HelpParagraph("The last lines of the Compiler Output pane show the file it was working on. Fix the errors listed for that file and press Check again; the compile may then get past it."))) to sBody
            Get FTHtmlMessage "Check workspace" sBody "OK" "" to bDummy
            Procedure_Return
        End
        If (piChkActionable(Self) <> 0) ;
            Procedure_Return
        Set pbChkDoneAnnounced to True
        Get piChkListed to iListed
        /* THE VERDICT CITES ITS EVIDENCE, ALL OF IT (Nils 2026-08-29, the "Yikes"): "the
           compiler is clean" used to be derived from the FILTERED board - so errors sitting in
           read-only pool packages, errors the user had hidden, and every project the Check never
           compiled were all silently folded into the good news. Three sources now speak:
             - the grid's RAW error tally (piSumErr - every error the compile reported, badged,
               hidden or not), split against the packages band's share (piChkOutsideErr);
             - the CLEAN claim, scoped to the one program that was actually compiled;
             - the OTHER projects' last-build health (_OtherProjectsHealthHtml), same words as the
               board's own coverage line. */
        Move 0 to iRawErr
        If (ghoModAnalyzerDock <> 0) ;
            Get piSumErr of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iRawErr
        Get piChkOutsideErr to iOutErr
        Move (iRawErr - iOutErr) to iHiddenErr
        Get HtmlEscaped (Trim(MainProgram(ghoApplication))) to sMainEsc
        If (sMainEsc = "") ;
            Move "The selected program" to sMainEsc
        Get _OtherProjectsHealthHtml (&bOthersBad) to sOthers
        Get _CheckCleanSentence sMainEsc iRawErr iOutErr iHiddenErr to sClean
        // The listed count's split and the hidden rows, from the render that just published the verdict.
        Get piChkReviewRows   to iReviewRows
        Get piChkReviewPkg    to iReviewPkg
        Get piChkHandRows     to iHand
        Get piChkHidden       to iHidden
        Get piChkHiddenReport to iHiddenReport
        Get piChkHiddenFn     to iHiddenFn
        Get _CheckDoneBodyHtml iListed iRawErr sClean sOthers iReviewPkg (iReviewRows - iReviewPkg) iHand iHidden iHiddenReport iHiddenFn to sBody
        Get FTHtmlMessage "Check workspace" sBody "OK" "" to bDummy
    End_Procedure

    /* ---- Busy feedback for a board render (see pbBoardRendering) ----
       ON: arm the latch, take the wait cursor, name the work in the status bar, and pump ONCE so
       both actually paint before the render blocks the message loop. OFF: hand the cursor back and
       say the board is current. BEAT: one progress line from inside the render's own loop.
       The status bar is the right surface here rather than a dialog: the render is not cancellable
       and the user is watching the board it is about to fill. */
    /* THE MARQUEE BELONGS TO THIS PHASE TOO (Nils 2026-08-31: "while the status_bar shows Check:
       building the findings list... the html progress bar is not shown, and it should").
       StartAnalyze turns it on for the analyze and off again BEFORE broadcasting
       RenderGuidedFindings, so the board render - the last and often longest stretch of a Check -
       ran with the bar blank. It is the same busy state as far as the user is concerned, so it
       gets the same three signals: cursor, status line, marquee.
       Reached through the app-held dock handle (the board cannot see panel-local methods), and
       SetBusyMarquee keeps the state for an un-shown dock, so this is safe from every refresh path. */
    Procedure SetBoardMarquee Boolean bOn
        Handle hoTC
        Get phoTestCompileFT of ghoApplication to hoTC
        If (hoTC <> 0) ;
            Send SetBusyMarquee of hoTC bOn
    End_Procedure

    Procedure BoardBusyOn String sWhat
        Handle hoStatusBar
        Set pbBoardRendering to True     // armed BEFORE the pump below - that is what it guards
        Set piBoardBusyTick  to (GetTickCount())
        Send Cursor_Wait of Cursor_Control
        Send SetBoardMarquee True
        Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
        If (hoStatusBar <> 0) ;
            Set StatusText of hoStatusBar to sWhat
        // ONE pump for all three - cursor, marquee push and status text land together, before
        // the render blocks the message loop.
        Send PumpMsgQueue of Desktop
    End_Procedure

    Procedure BoardBusyOff
        Handle hoStatusBar
        Send Cursor_Ready of Cursor_Control
        Send SetBoardMarquee False
        Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
        If (hoStatusBar <> 0) ;
            Set StatusText of hoStatusBar to ("Ready. Findings list built in " + String((GetTickCount() - piBoardBusyTick(Self)) / 1000) + "s.")
        Set pbBoardRendering to False
    End_Procedure

    // One progress line from inside a render. Inert unless BoardBusyOn armed the latch, so the
    // many other callers of FindingsListHtml (a plain view re-entry, a light tile refresh) neither
    // write to the status bar nor pump.
    Procedure BoardRenderBeat String sWhat
        Handle hoStatusBar
        If (pbBoardRendering(Self) = False) ;
            Procedure_Return
        Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
        If (hoStatusBar = 0) ;
            Procedure_Return
        Set StatusText of hoStatusBar to sWhat
        Send PumpMsgQueue of Desktop
    End_Procedure

    // Push the findings tile from the current analyzer grid (after a guided Check) - and the STEPS
    // tile with it, because the same render decides whether the trail may advance to "3 Tidy Up".
    // Updating findings alone left the stepper stuck on "2 Check & fix" after a clean Check.
    Procedure RefreshFindings
        Send UpdateHtml of (oTile_Findings(oWebHost(Self))) (FindingsListHtml(oWebHost(Self)))
        Send PushHtml of (oTile_Steps(oWebHost(Self)))    (StepsTileHtml(oWebHost(Self)))
    End_Procedure

    /* THE CLOSE OF EVERY WRITE-RUN: repaint the tiles, then replace the findings list with the
       stale note - a run that rewrote source has invalidated the verdict on screen, and the note
       says so instead of leaving numbers sitting there looking current. Seven remedies ended with
       these same three lines; they end here now, so the close cannot drift between them. */
    Procedure ShowStaleFindingsNote
        Send RefreshTiles
        Send PushHtml of (oTile_Findings(oWebHost(Self))) (StaleFindingsNote(Self))
    End_Procedure

    /* THE CLEAR AT THE HEAD OF A CHECK - see CheckRunningNote for why.

       The findings tile ONLY, deliberately: this is not ResetBoardForChangedSource, which is the
       wipe for a workspace change or a Revert. That one also clears psAutoPlanTriedWS, which
       re-arms the one-shot saved-Check restore - a saved Check loading itself onto the board in
       the middle of a running one is exactly what must not happen here. The tiles need no wipe
       either: RunGuidedCheck zeroes piChkTickAnalyze, which is what the stepper reads to decide
       whether stage 2 is done.

       PUMPED, because the scan half blocks the message loop a line or two later. Without it the
       clear would not paint until the scan's own first pump, which on a large workspace is long
       enough for the user to have clicked a row that is still on screen. */
    Procedure ShowCheckRunningNote
        Send PushHtml of (oTile_Findings(oWebHost(Self))) (CheckRunningNote(Self))
        Send PumpMsgQueue of Desktop
    End_Procedure

    // Run ONE named refactoring function over the CURRENT scope, directly - the shared worker behind the
    // findings list's row actions. This REPLACES the dashboard-era routing (pbWorkspaceMode -> Activate
    // Folders -> Activate Functions -> SelectSingleFunction -> Switch_Next_View), which re-seeded the folder
    // grid (wiping a curated scope) and then left the user to spot one pre-ticked function among ~95 - the
    // exact anti-pattern this redesign exists to kill. No view switch.
    //
    // SCOPE IS THE USER'S DECISION (the standing rule - a run must never silently widen it): use the
    // persisted folder selection, and only fall back to the whole workspace when nothing is selected,
    // which is what this view's Scope line claims. The folder grid is NOT touched either way.
    //
    // The engine takes its FUNCTION set from the persistent Functions.Selected flags, so this snapshots the
    // user's standing selection, ticks only sFnName, and RESTORES it afterwards (the LegacyApp2 incident,
    // 2026-07-16: transient ticks that linger silently join the next manual run). eRunManual, not eRunPlan -
    // eRunPlan would stamp a plan run the user never made.
    //
    // bSilent suppresses the engine's start question AND its summary dialog. That is right for a REPORT (it
    // changes nothing, and the caller opens the real output itself) and WRONG for anything that WRITES
    // source: there the start warning is the "you should have version control and a backup" safety net, and
    // the summary is the record of what changed. Returns False when nothing was started.
    Function RunScopedFunction String sFnName Boolean bSilent String sConfirmText String sFnParameter String[] asAffectedFiles Returns Boolean
        String[] asAff asPrevSelFns asWsFolders
        String sPrevParam
        tRefactorFiles RefactorFiles
        Handle hoEditor
        Integer iAffected iRunSeqBefore
        Boolean bOk bRan

        Move (SizeOfArray(asAffectedFiles)) to iAffected
        If (iAffected > 0) Begin
            // FILE-PRECISE run. The compiler already named every file that needs changing, so run over
            // EXACTLY those: no folder selection to get right, nothing touched that does not need it, and
            // nothing missed for sitting outside the chosen folders. (The Run Fix Plan path builds its
            // tRefactorFiles the same way.) Scope stays what this view says it is - "what the scan and
            // manual passes cover" - and does not gate a fix the compiler itself pinpointed.
            // GUARDED to the workspace's own source tree, so an install / system file named in a
            // diagnostic can never be rewritten.
            Move asAffectedFiles to asAff
            Send _ScopedFilesFromCompiler (&asAff) (&RefactorFiles) (&bOk)
        End
        Else Begin
            // Whole-scope run (the report actions): the folders the user chose, else the whole workspace.
            Send _ScopedFilesFromSelection (&RefactorFiles) (&bOk)
        End
        If (bOk = False) ;
            Function_Return False
        // A TARGETED confirmation when the caller supplied one - it names what will happen, to what, and for
        // which DataFlex version, instead of the engine's generic "1 refactoring functions / 2054 Files in
        // 12 selected Folders", which says nothing about WHICH function or WHICH folders. The backup warning
        // is kept: this is still the last stop before source is rewritten. pbStartQuestionAsked then
        // suppresses the generic question WITHOUT suppressing the summary (unlike pbSilentRun).
        Send _ConfirmScopedRun sConfirmText sFnName iAffected (&RefactorFiles) (&bOk)
        If (bOk = False) ;
            Function_Return False
        Send _SelectOnlyFunction sFnName sFnParameter (&asPrevSelFns) (&sPrevParam)
        Get phoEditor of ghoApplication to hoEditor
        Set peRunOrigin of ghoEngine to eRunManual
        Set pbSilentRun of ghoEngine to bSilent
        /* A RUN THAT DID NOT HAPPEN MUST NOT REPORT AS ONE (2026-09-03). StartEngine returns
           without running when the engine is busy or fails to initialise, and this returned True
           regardless - so every remedy then read the funclib counters the LAST run had left and
           showed them as this run's outcome ("Version-guarded 2" for a run that never started,
           WinServ 13:21-13:26). piEngineRunSeq advances only inside RunRefactoringEngine, the same
           test RunGuidedPlan already makes; a cancelled start warning leaves it unmoved too. The
           selection restore below still runs either way - it was already changed. */
        Get piEngineRunSeq of ghoEngine to iRunSeqBefore
        Send StartEngine of ghoEngine RefactorFiles hoEditor
        Move (piEngineRunSeq(ghoEngine) <> iRunSeqBefore) to bRan
        /* A ROW ACTION THAT REWROTE SOURCE INVALIDATES THE BOARD, exactly as a Tidy Up does (Nils
           2026-07-29, on the post-conversion dialog: "I think that a Check is first needed?").
           Only the Tidy Up path said so, yet every one of these actions runs the same engine over
           the same files - so a conversion could rewrite source while the findings list went on
           showing the previous Check's verdict and the trail went on showing Ready. Read BEFORE the
           DD restore below, whose ResetSysFile recomputes the SysFile counters. */
        If (SysFile.iCountNumberOfChangedFiles > 0 and SysFile.bReadOnly = False) ;
            Send MarkSourceUnverified of ghoApplication
        // Belt: the engine consumes the one-shot at the end of a RUN, but StartEngine can return earlier
        // (failed init). Clearing here guarantees it never leaks into the next interactive run.
        Set pbSilentRun of ghoEngine to False
        // Restore the standing selection (see above). ResetSysFile recounts the selection totals the
        // dashboard's "Functions selected" pill reads.
        Send _RestoreFunctionSelection sFnName sFnParameter (&asPrevSelFns) sPrevParam
        Function_Return bRan
    End_Function

    /* THE ONLY PLACE OFF LIMITS IS THE DATAFLEX INSTALL (Nils 2026-08-14).

       "All folders that are selected should be able to be changed - that is the rule,
       together with the file filter. It doesn't matter if the files are part of a library or
       not - it never has. I honestly don't know where this guard came from."

       It came from here, and it was invented rather than inherited. This branch used to keep
       a compiler-named file only if its folder appeared in WholeWorkspaceSourceFolders -
       a rule that exists nowhere else in the engine. On his WinServ it refused
       E:\WebAppSrc\wslibrary.pkg, a file the workspace compiles and that BREAKS THE BUILD,
       and reported it as "most likely an install or system file". Two sessions went into
       chasing why the folder was missing from a list it never needed to be in.

       What the engine actually protects against is the DataFlex INSTALL tree, and it does it
       in AllSourceFiles (cRefactorApplication) with a prefix test on psTargetPkgFolder,
       described there as a hard guard "however the folder was selected". That is the real
       rule and it is the one applied here now: the compiler named these files because it
       compiled them, so the only ones to drop are those that are gone from disk or that live
       inside the read-only install.

       Library membership is not consulted, because it never was anywhere else. */
    // RunScopedFunction's file-precise scope: fills RefactorFiles with the files the compiler named,
    // dropping only those gone from disk or write-protected. bOk comes back False (after saying why)
    // when none of them can be written.
    Procedure _ScopedFilesFromCompiler String[] ByRef asAffectedFiles tRefactorFiles ByRef RefactorFiles Boolean ByRef bOk
        String sFolder
        Boolean bWritable
        Integer i iAffected

        Move (SizeOfArray(asAffectedFiles)) to iAffected
        For i from 0 to (iAffected - 1)
            // On disk, outside the install's Pkg tree, not WRITE-PROTECTED (Nils 2026-08-18: a DfPkg
            // checkout, the package cache, a VCS-locked copy are system files too) - the ONE rule,
            // IsCompilerNamedFileWritable, shared since 2026-09-20 with the grid's per-name site
            // counts and the rewrite offers, so the three cannot disagree about whose a file is.
            Get IsCompilerNamedFileWritable of ghoApplication asAffectedFiles[i] to bWritable
            If (bWritable = True) Begin
                Get ParseFolderName asAffectedFiles[i] to sFolder
                Move (vFolderFormat(sFolder)) to sFolder
                Move asAffectedFiles[i] to RefactorFiles.asFullFileNames[-1]
                If (SearchArray(sFolder, RefactorFiles.asFolders, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move sFolder to RefactorFiles.asFolders[-1]
            End
        Loop
        If (SizeOfArray(RefactorFiles.asFullFileNames) = 0) Begin
            // Only two ways to get here now, and the text names both rather than guessing.
            Send FTInfoBox ("Nothing to change: none of the " + String(iAffected) + " file(s) the compiler named can be written." ;
                + Character(10) + Character(10) + "The first was:" + Character(10) + "   " + asAffectedFiles[0] ;
                + Character(10) + Character(10) + "A file is skipped only when it is no longer on disk, or when it is write-protected (the READ-ONLY attribute: the DataFlex installation, a DfPkg package checkout, a locked VCS copy) - a system file, not refactored here." ;
                + (If(rfPackageManagedPathNote(asAffectedFiles[0]) <> "", Character(10) + Character(10) + rfPackageManagedPathNote(asAffectedFiles[0]), "")))
            Move False to bOk
            Procedure_Return
        End
        Move True to bOk
    End_Procedure

    // RunScopedFunction's whole-scope fallback: fills RefactorFiles from the folders the user chose,
    // else the whole workspace. bOk comes back False (after saying so) when no folders or no source
    // files are in scope.
    Procedure _ScopedFilesFromSelection tRefactorFiles ByRef RefactorFiles Boolean ByRef bOk
        String[] asFolders

        Get pasSelectedFolders of ghoApplication to asFolders
        If (SizeOfArray(asFolders) = 0) ;
            Get WholeWorkspaceSourceFolders of ghoApplication to asFolders
        If (SizeOfArray(asFolders) = 0) Begin
            Send FTInfoBox "No source folders are in scope - load a workspace first."
            Move False to bOk
            Procedure_Return
        End
        Get AllSourceFiles of ghoApplication asFolders SysFile.FileExtensionFilter to RefactorFiles
        If (SizeOfArray(RefactorFiles.asFullFileNames) = 0) Begin
            Send FTInfoBox "No source files were found in the current scope."
            Move False to bOk
            Procedure_Return
        End
        Move True to bOk
    End_Procedure

    // RunScopedFunction's targeted confirm. Asks nothing when sConfirmText is blank (bGo stays True);
    // otherwise bGo comes back False when the user declined, and the engine's generic start question
    // is suppressed when they accepted.
    Procedure _ConfirmScopedRun String sConfirmText String sFnName Integer iAffected tRefactorFiles ByRef RefactorFiles Boolean ByRef bGo
        String sMsg
        Integer i iFolders iRetval

        Move True to bGo
        If (sConfirmText <> "") Begin
            // Name the FUNCTION and list the ACTUAL folders: the engine's generic warning said "1
            // refactoring functions ... 2054 Files in 12 selected Folders", which answers neither "which
            // function?" nor "which folders?" (Nils 2026-07-21). Long lists are capped, like the Deep Scan
            // confirm, so the box stays readable.
            Move (sConfirmText + "\n\nRefactoring function:  " + sFnName) to sMsg
            Move (SizeOfArray(RefactorFiles.asFolders)) to iFolders
            // A file-precise run says so explicitly, so it is obvious that ONLY the files the compiler
            // named will be opened - not everything under the folders listed below.
            If (iAffected > 0) ;
                Move (sMsg + "\n\nFiles:  " + String(SizeOfArray(RefactorFiles.asFullFileNames)) + " (exactly the file(s) the compiler reported this in), in " + String(iFolders) + " folder(s):") to sMsg
            Else ;
                Move (sMsg + "\n\nScope:  " + String(SizeOfArray(RefactorFiles.asFullFileNames)) + " source files in " + String(iFolders) + " folder(s):") to sMsg
            For i from 0 to (iFolders - 1)
                If (i < 8) ;
                    Move (sMsg + "\n    " + RefactorFiles.asFolders[i]) to sMsg
            Loop
            If (iFolders > 8) ;
                Move (sMsg + "\n    ... and " + String(iFolders - 8) + " more") to sMsg
            Move (sMsg + "\n\nYou should ALWAYS have the source under version control and/or backed up before you continue!\n\nContinue?") to sMsg
            Get FTYesNoBox sMsg "DFRefactor" MB_DEFBUTTON2 to iRetval
            If (iRetval <> MBR_Yes) Begin
                Move False to bGo
                Procedure_Return
            End
            Set pbStartQuestionAsked of ghoEngine to True
        End
    End_Procedure

    // Ticks ONLY sFnName in the Functions table for a RunScopedFunction run (and writes its parameter),
    // handing back the user's standing selection and previous parameter for the restore afterwards.
    Procedure _SelectOnlyFunction String sFnName String sFnParameter String[] ByRef asPrevSelFns String ByRef sPrevParam
        String[] asOne
        Handle hoDD

        Move sFnName to asOne[0]
        Move "" to sPrevParam
        Get Create (RefClass(cFunctionsDataDictionary)) to hoDD
        Get SelectedPublishedFunctionNames of hoDD to asPrevSelFns
        Send UnSelectAllRecords of hoDD
        Send SelectRecordsFromStringArray of hoDD asOne
        // A parameterised refactor takes its parameter from the TABLE, so write it for this run and put the
        // user's own value back below - the same rule as the Selected flags.
        If (sFnParameter <> "") ;
            Get SetFunctionParameter of hoDD sFnName sFnParameter to sPrevParam
        Send Destroy of hoDD
    End_Procedure

    // Puts the standing function selection (and the previous parameter) back after a RunScopedFunction
    // run, then recounts the selection totals through ResetSysFile.
    Procedure _RestoreFunctionSelection String sFnName String sFnParameter String[] ByRef asPrevSelFns String sPrevParam
        String sMsg
        Handle hoDD

        Get Create (RefClass(cFunctionsDataDictionary)) to hoDD
        Send UnSelectAllRecords of hoDD
        Send SelectRecordsFromStringArray of hoDD asPrevSelFns
        If (sFnParameter <> "") ;
            Get SetFunctionParameter of hoDD sFnName sPrevParam to sMsg
        Send ResetSysFile of hoDD
        Send Destroy of hoDD
    End_Procedure

    /* ---- Shared by the remedies below (2026-09-02) ---- */

    /* The files the COMPILER named in its messages of one number - the file-precise scope for a
       call-site remedy (Nils 2026-08-16: the calls sat in a library the compiler builds but the
       folder ticks did not include, so a whole-scope run never opened the file). Empty when no
       analyzer dock exists; the callers then fall back to the scope run. */
    Function FilesCarryingMessage String sMsgNo Returns String[]
        String[] asFiles
        tSavedPlanRow[] aRows
        Integer i iLast

        If (ghoModAnalyzerDock = 0) ;
            Function_Return asFiles
        Get BuildSavedPlanRowsVisible of (oModAnalyzer_grd(ghoModAnalyzerDock)) to aRows
        Move (SizeOfArray(aRows) - 1) to iLast
        For i from 0 to iLast
            If (Pos(sMsgNo, aRows[i].sMsg) > 0 and Trim(aRows[i].sFile) <> "") Begin
                If (SearchArray(aRows[i].sFile, asFiles, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move aRows[i].sFile to asFiles[-1]
            End
        Loop
        Function_Return asFiles
    End_Function

    // How many 4544 errors the compiler reported for ONE name, summed over the grid's per-name
    // tally. "" sums every name. 0 with no analyzer dock.
    Function AmbiguousCallCountForName String sName Returns Integer
        String[]  asNames
        Integer[] aiCounts
        Integer i iLast iCalls
        Handle hoGrid

        If (ghoModAnalyzerDock = 0) ;
            Function_Return 0
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasAmbiguousFnNames of hoGrid to asNames
        Get paiAmbiguousCounts  of hoGrid to aiCounts
        Move 0 to iCalls
        Move (SizeOfArray(asNames) - 1) to iLast
        For i from 0 to iLast
            If (sName = "" or Lowercase(Trim(asNames[i])) = Lowercase(Trim(sName))) ;
                Move (iCalls + aiCounts[i]) to iCalls
        Loop
        Function_Return iCalls
    End_Function

    /* The version a guard is written against - read from the .sws EXACTLY as the converter reads
       it, so the confirm can name it. 0 when it cannot be read, after saying so: both guard offers
       refuse up front rather than let the converter silently no-op. */
    Function GuardVersionMacro String ByRef sVer Returns Integer
        tWorkspacePaths WS
        Integer iVer
        Boolean bDummy

        Get pTargetWS of ghoApplication to WS
        Move WS.sDfVersion to sVer
        Get DfVersionToMacroNumber of ghoFuncLib sVer to iVer
        If (iVer = 0) ;
            Get FTHtmlMessage "Version guard" (HelpParagraph("This workspace's DataFlex version could not be read from its .sws, so the version guard cannot be written.")) "OK" "" to bDummy
        Function_Return iVer
    End_Function

    // The confirm body for RunGuardGlobals: the guard directive as a code block, with the 4390 count
    // when the analyzer has one. Returns the HTML.
    /* THE DIALOG DESCRIBES THE GUARD THE CONVERTER WRITES (Nils 2026-09-03, reading it on WinServ:
       "#IF (!@ <= 260) ... so the workspace's own version still compiles on DataFlex 26 and older"
       - which, on the DataFlex 26 build that reported the errors, would leave every duplicate in
       place). That was the rule until 2026-08-16; the converter has used the PER-FUNCTION boundary
       since - the release DataFlex first shipped the name in (FirstNativeVersionFor) - and only a
       name no catalogue lists falls back to the workspace's own version. The text now says so. */
    Function _GuardGlobalsConfirmBody String sVer Integer iVer Integer iCount Returns String
        String sGuard sGuardEsc sFall sFallEsc sExample sExampleEsc sBody

        // Character()-built for the SAME reason the converter builds it that way: a literal "#IF (!@" in
        // this file would be consumed by FMAC during DFRefactor's own compile.
        Move (Character(35) + "IF (" + Character(33) + "@ < <release DataFlex first shipped it in>)") to sGuard
        Move (Character(35) + "IF (" + Character(33) + "@ < 201)") to sExample
        Move (Character(35) + "IF (" + Character(33) + "@ <= " + String(iVer) + ")") to sFall
        Get HtmlEscaped sGuard   to sGuardEsc
        Get HtmlEscaped sExample to sExampleEsc
        Get HtmlEscaped sFall    to sFallEsc
        Move ((HelpParagraph("Version-guard the global functions in this workspace that DataFlex " + sVer + " already provides natively."))) to sBody
        If (iCount > 0) ;
            Move (sBody + (HelpParagraph((BoldHtml(String(iCount))) + " duplicate-global error(s) 4390 were reported."))) to sBody
        Move (sBody + ((HelpParagraph("Each declaration is wrapped in:")) + "<pre>") + sGuardEsc + Character(10) + "    ..." + Character(10) + Character(35) + "ENDIF</pre>") to sBody
        Move (sBody + (HelpParagraph("The boundary is per function - the release DataFlex first provided that name in, read from the per-version catalogues. OemToUtf8 first appears in 20.1, so its guard reads " + (BoldHtml(sExampleEsc)) + ". The workspace's copy then compiles only on releases that have no native one; DataFlex " + sVer + " uses the built-in. No call sites are changed."))) to sBody
        Move (sBody + (HelpParagraph("A name no catalogue lists falls back to " + (BoldHtml(sFallEsc)) + ", the workspace's own version. A guard DFRefactor wrote earlier with the old boundary is repaired in place."))) to sBody
        Function_Return sBody
    End_Function

    // The outcome body for RunGuardGlobals: what was guarded, or WHICH kind of nothing it was
    // (already guarded / the converter stopped before scanning / no native match). Returns the HTML.
    Function _GuardGlobalsOutcomeBody String sVer Integer iDone Integer iAlready String sSkipWhy Returns String
        String sBody

        If (iDone > 0) Begin
            Move ((HelpParagraph((BoldHtml("Version-guarded " + String(iDone) + " global function declaration(s)."))))) to sBody
            Move (sBody + (HelpParagraph("Each is kept only for the releases before DataFlex first provided that name; " + sVer ;
            + " and every release with the native one use the built-in. " + (BoldText("VERIFY")) ;
            + " the built-in behaves the same before relying on it - the note above each guard says which release the boundary is."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it - the guarded errors should be gone from the list.")))) to sBody
        End
        Else Begin
            /* ALREADY GUARDED IS NOT "NOT FOUND" (Nils 2026-08-15: "I do not understand why this
               message exists ... this whole logic have worked just fine for a long time").

               It had. The previous run guarded OEMToUTF8 in wslibrary.pkg and the #IF is sitting in
               his source. THIS run correctly found nothing new to do - and then explained that by
               saying the name is not in the DataFlex Pkg folder, which is false (OemToUtf8 is in the
               catalogue) and which sends the user off to RENAME a function that is already guarded.

               The row still offers the action because the .prn it was read from was produced BEFORE
               the guard was written: the 4390 is real in that listing and gone from the source. So
               name the state and point at the recompile. */
            If (iAlready > 0) Begin
                Move ((HelpParagraph((BoldHtml("Nothing to do " + CS_EmDash + " " + String(iAlready) + " declaration(s) are already version-guarded."))))) to sBody
                Move (sBody + (HelpParagraph("DFRefactor wrapped them on an earlier run, so this one left them alone. The source is already in the state this action was going to put it in."))) to sBody
                Move (sBody + (HelpParagraph("They are still listed because the compiler output these findings came from was produced " + (BoldText("before")) + " the guard was written. Run " + (BoldText("Check")) + " to recompile " + CS_EmDash + " they should drop off the list."))) to sBody
            End
            Else If (Trim(sSkipWhy) <> "") Begin
                /* THE CONVERTER KNOWS WHY IT STOPPED - ask it before guessing (2026-08-15).

                   It has three exits that return "guarded 0" without looking at a single
                   declaration: no target version, an unparsable one, and an empty native catalogue.
                   All three used to arrive here indistinguishable from "scanned everything, matched
                   nothing", and got reported as the latter - which is how Nils was twice told a name
                   is absent from the Pkg folder while OemToUtf8 sits in the catalogue and the #IF
                   sits in his source. psGuardSkipReason is blank when the run really did scan. */
                Move ((HelpParagraph((BoldText("Nothing was changed."))))) to sBody
                Move (sBody + (HelpParagraph("The guard run stopped before it examined any declaration, because " + sSkipWhy))) to sBody
                Move (sBody + (HelpParagraph("This is NOT a statement about the workspace's functions - they were never reached, and nothing in the source was touched."))) to sBody
            End
            Else Begin
                Move ((HelpParagraph((BoldText("Nothing was changed."))))) to sBody
                Move (sBody + (HelpParagraph("To guard one of the workspace's functions, DFRefactor first has to find the DataFlex function it clashes with. It looks for global functions in the DataFlex Pkg folder, and none of these names are declared there."))) to sBody
                Move (sBody + (HelpParagraph("They do still clash. A name can also be taken by:"))) to sBody
                Move (sBody + (HelpParagraph(CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + ("the DataFlex runtime, which has no source file to find it in" + CS_Br) + CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + ("a method on a DataFlex class" + CS_Br) + CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + "an External_Function declaration"))) to sBody
                Move (sBody + (HelpParagraph("Any of those is enough to make the workspace's declaration illegal - but a version guard is the wrong fix for them."))) to sBody
                Move (sBody + (HelpParagraph("Rename the workspace's function instead. Guarding is only right when DataFlex provides the SAME thing under that name. Where it simply uses the name for something else, guarding would compile cleanly and quietly change what the code does."))) to sBody
                Move (sBody + ((HelpParagraph("Use " + (BoldText("Show declarations")) + " to see the clashing names.")))) to sBody
            End
        End
        Function_Return sBody
    End_Function

    // Findings row "Guard them" (E 4390): wrap this workspace's own globals that DataFlex now ships
    // natively in an #IF (!@ <= <workspace version>) guard. NOT silent - it WRITES source, so the engine's
    // start warning and summary both belong here (see RunScopedFunction).
    Procedure RunGuardGlobals
        String sVer sBody sSkipWhy
        String[] asFiles
        Integer iVer iCount iDone iAlready
        Boolean bRan bDummy

        Get GuardVersionMacro (&sVer) to iVer      // the version named, or 0 after saying it could not be read
        If (iVer = 0) ;
            Procedure_Return
        Move 0 to iCount
        If (ghoModAnalyzerDock <> 0) Begin
            Get piSumBackportErr of (oModAnalyzer_grd(ghoModAnalyzerDock)) to iCount
            // FILE-PRECISE, like the 4544 action: a 4390 is reported AT the offending declaration, so
            // the files carrying those errors ARE the files to change. Without this the run walked the
            // whole scope - ~2000 files to edit two - which read as the run hanging (Nils 2026-07-21).
            Get pasBackportFiles of (oModAnalyzer_grd(ghoModAnalyzerDock)) to asFiles
        End
        // GENERAL CONFIRM DIALOG pilot (Nils 2026-07-24): the confirm + outcome go through
        // ghoConfirmDialog - formatted body, the directive as a real code block, caller-verb
        // buttons. The engine then runs SILENT: the question was already asked here, so the guided
        // flow owns the whole conversation (no doubled engine YesNo).
        Get _GuardGlobalsConfirmBody sVer iVer iCount to sBody
        Get FTHtmlMessage "Guard duplicate globals" sBody "Guard them" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Get RunScopedFunction "GuardRedundantGlobalFunctions" True "" "" asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        // Say what happened - and when nothing was guarded, say WHY. The catalogue this matches against is
        // built by scanning the install's package SOURCE for "Function <name> Global", so it structurally
        // cannot see a name provided by the RUNTIME (Split), by a DataFlex CLASS METHOD (SqlExecute), or by
        // an External_Function. All three still collide, because message names are workspace-global. A bare
        // "0 lines" left the user to guess whether that was correct (Nils 2026-07-21).
        Get piGuardedCount of ghoFuncLib to iDone
        Get piAlreadyGuardedCount of ghoFuncLib to iAlready
        Get psGuardSkipReason of ghoFuncLib to sSkipWhy
        Set pbGuardFoundNothing to (iDone = 0)
        Get _GuardGlobalsOutcomeBody sVer iDone iAlready sSkipWhy to sBody
        Get FTHtmlMessage "Guard duplicate globals" sBody "OK" "" to bDummy
        // NOTHING CHANGED -> leave the screen exactly as it was. Refreshing here re-rendered the findings
        // tile from the analyzer grid, which a refactor run has left stale, so the list fell back to its
        // "Run a Check to see findings" placeholder and the whole view looked freshly opened - after a run
        // that had done nothing at all (Nils 2026-07-21: "the (WIP) screen goes back to how it looks after
        // a new workspace has been opened. What?").
        If (iDone = 0) Begin
            // Nothing changed, so the analysis is still valid: re-render just the LIST - not the whole
            // tile set, and without the source-changed notice - so the spent action repaints as inert.
            Send RefreshFindings
            Procedure_Return
        End
        // Send, NOT Delegate: the close lives on THIS object, and Delegate starts looking at the PARENT -
        // from a view-level procedure it walks straight past the view and faults err 98 "Invalid message"
        // (Nils 2026-07-21). Delegate is right in oChkDeferTimer's OnTimer, a child reaching up to the view.
        Send ShowStaleFindingsNote
    End_Procedure

    // Findings "Run the refactoring plan": hand the analyzed rows to the SAME Refactoring Plan
    // dialog the dock's Refactor Plan action opens - the plan IS the confirm surface (review,
    // deselect, then run). Mirrors CI_ChkRunCheck's dispatch: show the panel, then send to the
    // handle it publishes. The action row only renders when plan-capable rows exist, which implies
    // an analyze has populated the grid - StartAutoSelect's own guards cover the rest.
    Procedure RunGuidedPlan
        Handle hoPanel
        Integer iRunSeqBefore
        Boolean bPlanEmpty bDummy
        String sBody

        // DOCK ONLY - see the note on the Check action below: the trail never sends the user to the
        // editor to do its own work. The plan dialog is modal and opens on top from wherever we are.
        Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        Get phoTestCompileFT of ghoApplication to hoPanel
        If (hoPanel = 0) ;
            Procedure_Return
        // The plan dialog (and the run + summary it may launch) is MODAL, so control returns here
        // when everything has closed. The engine's run counter tells whether a run actually
        // happened: on cancel, nothing changed and the findings stay valid as-is.
        Get piEngineRunSeq of ghoEngine to iRunSeqBefore
        Set pbGuidedPlanRun of hoPanel to True
        Set pbPlanRunInFlight to True
        Send StartAutoSelect of hoPanel
        Set pbPlanRunInFlight to False
        If (piEngineRunSeq(ghoEngine) = iRunSeqBefore) Begin
            // No run happened. CANCEL leaves the findings valid - keep the screen as-is. But an
            // EMPTY plan means every auto-fixable row was consumed by an earlier run and this list
            // describes source that no longer exists: say so, point at the next step, and retire
            // the spent action instead of letting the click dead-end again (Nils 2026-07-25).
            Get pbAutoSelectPlanEmpty of hoPanel to bPlanEmpty
            If (bPlanEmpty = False) ;
                Procedure_Return
            Send Activate_oDashboard_vw of (Client_Id(ghoCommandBars))
            Move ((HelpParagraph((BoldText("Nothing left to auto-fix."))))) to sBody
            Move (sBody + (HelpParagraph("None of the listed rows translate into a runnable auto-fix any more - typically because an earlier plan run already refactored them, so the list describes source that has since changed."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it. Anything that remains belongs to the Review or hand-migration bands - and once those are clear too, Tidy Up is the next stage.")))) to sBody
            Get FTHtmlMessage "Run the refactoring plan" sBody "OK" "" to bDummy
            Send PushHtml of (oTile_Findings(oWebHost(Self))) (TileCss(Self) + ((DivOpen("tnote")) + 'Nothing left to auto-fix in the last analysis ') + CS_EmDash + ((' run ' + (BoldText("Check")) + ' again to see current findings.') + CS_DivEnd))
            Procedure_Return
        End
        // A run rewrote source: come back to the guided surface (the user launched from here, but
        // the modal chain leaves focus with the editor/panel - Nils 2026-07-23) and say the findings
        // no longer describe the code, exactly like the guard/hoist write-runs do.
        Send Activate_oDashboard_vw of (Client_Id(ghoCommandBars))
        // The LIGHT refresh: the findings tile already carries the note (RefreshAfterRun pushed it
        // before the summary), and a full RefreshTiles would render every old row just to be
        // replaced again - the lag Nils saw after closing the summary (2026-09-23).
        Send RefreshTilesKeepFindings False
        Send PushHtml of (oTile_Findings(oWebHost(Self))) (PlanRanFindingsNote(Self))
    End_Procedure

    // A findings row's file cell opens the source in the editor at the row's first-occurrence line -
    // the same phoEditor / LoadFile / JumpToSourceLine sequence the Manual Changes and Analyzer grids
    // use. Every row can honestly offer this even when no converter applies (Nils 2026-07-23: "a
    // static list that doesn't offer much help").
    Procedure OpenFindingSource
        String sParam sFile sLineTxt
        Integer iPos iLine
        Handle hoEditor

        Get psPendingOpenSrc of oChkDeferTimer to sParam
        Move (Pos("|", sParam)) to iPos
        If (iPos < 2) ;
            Procedure_Return
        Move (Left(sParam, (iPos - 1))) to sFile
        Move (Right(sParam, (Length(sParam) - iPos))) to sLineTxt
        Move sLineTxt to iLine
        Get phoEditor of ghoApplication to hoEditor
        If (hoEditor <> 0 and sFile <> "" and iLine > 0) Begin
            // Activate the VIEW through its registered activation message, not the editor object:
            // the views live inside CodeJock's TabWorkspace, and a bare object Activate moves the
            // DataFlex focus tree WITHOUT switching CodeJock's active tab-page - the editor showed
            // the right line while the WIP tab stayed current (Nils 2026-07-23).
            Send Activate_oEditorView_vw of (Client_Id(ghoCommandBars))
            Send LoadFile of hoEditor sFile
            Send JumpToSourceLine of hoEditor (iLine - 1)
        End
    End_Procedure

    // The confirm body for OfferExternalGuard: the guard directive as a code block and what it means
    // for older / newer releases. Returns the HTML.
    Function _ExternalGuardConfirmBody String sVer Integer iVer Returns String
        String sGuard sGuardEsc sBody

        // Character()-built for the SAME reason the converter builds it that way: a literal "#IF (!@" in
        // this file would be consumed by FMAC during DFRefactor's own compile.
        Move (Character(35) + "IF (" + Character(33) + "@ < " + String(iVer) + ")") to sGuard
        Get HtmlEscaped sGuard to sGuardEsc
        Move (HelpParagraph("Version-guard this workspace's External_Function declarations that newer DataFlex releases now declare themselves.")) to sBody
        Move (sBody + ((HelpParagraph("Each declaration is wrapped in:")) + "<pre>") + sGuardEsc + Character(10) + "    ..." + Character(10) + Character(35) + "ENDIF</pre>") to sBody
        Move (sBody + (HelpParagraph("so releases OLDER than DataFlex " + sVer + " keep compiling the workspace's declaration, while " + sVer + " and newer use DataFlex's own. No call sites are changed."))) to sBody
        Function_Return sBody
    End_Function

    // The outcome body for OfferExternalGuard: what was guarded, or WHICH zero it was. bSkippedCalled
    // comes back True when the converter refused because THIS file calls the declaration(s); the
    // caller then shows the body, re-renders the list and returns, exactly as before.
    Procedure _ExternalGuardOutcomeBody String sVer Integer iDone String ByRef sBody Boolean ByRef bSkippedCalled
        String[] asSkipped
        Integer iAlready iSkipped iI

        Move False to bSkippedCalled
        If (iDone > 0) Begin
            Move ((HelpParagraph((BoldHtml("Version-guarded " + String(iDone) + " External_Function declaration(s)."))))) to sBody
            Move (sBody + (HelpParagraph("Each is kept for DataFlex " + sVer + " and older; newer builds use DataFlex's own declaration. " + (BoldText("VERIFY")) + " the entry points match - an ANSI (...A) binding vs DataFlex's wide (...W) one differs only where text buffers cross."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it - the guarded errors should be gone from the list.")))) to sBody
        End
        Else Begin
            /* SAY WHICH ZERO IT WAS. This used to blame the install lookup for every zero-change
               run - "none of these names are declared there" - including the common case where the
               names ARE declared there and every one was already guarded. Nils read that on
               LegacyApp4 while looking at PageSetupDlg, which DataFlex declares in its own
               Prnt_dlg.pkg (2026-08-26): the dialog named a cause that was not the cause. */
            /* THE REFUSAL FIRST, because it is the most specific reason and the one a reader can
               act on: the declaration is a real duplicate, but this file CALLS it, so guarding it
               out would leave the call with nothing to bind to. Prnt_dlg.pkg declares PageSetupDlg
               and calls it a few hundred lines down - 543 errors when that was not checked
               (LegacyApp4, 2026-08-26). */
            Get pasGuardSkippedCalled of ghoFuncLib to asSkipped
            Move (SizeOfArray(asSkipped)) to iSkipped
            If (iSkipped > 0) Begin
                Move ((HelpParagraph((BoldText("Nothing was changed - and it should not be.")) + " " ;
                    + String(iSkipped) + " declaration(s) here are used by THIS file, so removing them " ;
                    + "on newer builds would leave those calls with nothing to bind to."))) to sBody
                For iI from 0 to (iSkipped - 1)
                    Move (sBody + (HelpParagraph(CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + asSkipped[iI]))) to sBody
                Loop
                Move (sBody + ((HelpParagraph("A guard suits a declaration you no longer use. Where the file " ;
                    + "still calls it, the question is whether the file belongs in the workspace at all - a " ;
                    + "legacy copy of a DataFlex package is a migration decision, not a refactor.")))) to sBody
                Move True to bSkippedCalled
                Procedure_Return
            End
            Get piAlreadyGuardedExternalCount of ghoFuncLib to iAlready
            If (iAlready > 0) Begin
                Move ((HelpParagraph((BoldText("Nothing to change.")) + " " + String(iAlready) ;
                    + " declaration(s) already carry a version guard."))) to sBody
                Move (sBody + (HelpParagraph("If the error is still reported, the guard is not excluding this build - " ;
                    + "check the #IF line above the declaration. A guard written for an older release of this tool " ;
                    + "can say <= the workspace's version, which is true on it."))) to sBody
                Move (sBody + ((HelpParagraph("Where the declaration is DataFlex's OWN file copied into the workspace, " ;
                    + "a guard only defers the clash - the file itself is the duplicate.")))) to sBody
            End
            Else Begin
            Move ((HelpParagraph((BoldText("Nothing was changed."))))) to sBody
            Move (sBody + (HelpParagraph("To guard a declaration, DFRefactor first has to find the matching External_Function in the target DataFlex's Pkg folder - and none of these names are declared there. The clash then comes from somewhere a guard cannot help (the runtime, or a source outside the scanned packages)."))) to sBody
            Move (sBody + ((HelpParagraph("Use " + (BoldText("Show declarations")) + " to see the sites.")))) to sBody
            End
        End
    End_Procedure

    // The files declaring ONE 4390 name (pasBackportSiteFiles by name index, de-duplicated) - the
    // file-precise scope of the row's "Guard it". Empty when the grid has no site list for it.
    Function _BackportSiteFilesForName String sName Returns String[]
        String[]   asNames asFiles
        String[][] asSites
        Integer i iLast iSite iSiteLast
        Handle hoGrid

        If (ghoModAnalyzerDock = 0) ;
            Function_Return asFiles
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasBackportNames     of hoGrid to asNames
        Get pasBackportSiteFiles of hoGrid to asSites
        Move (SizeOfArray(asNames) - 1) to iLast
        For i from 0 to iLast
            If (Lowercase(Trim(asNames[i])) = Lowercase(Trim(sName)) and i < SizeOfArray(asSites)) Begin
                Move (SizeOfArray(asSites[i]) - 1) to iSiteLast
                For iSite from 0 to iSiteLast
                    If (SearchArray(asSites[i][iSite], asFiles, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                        Move asSites[i][iSite] to asFiles[-1]
                Loop
            End
        Loop
        Function_Return asFiles
    End_Function

    /* The same-width guard run and its outcome, shared by the post-report offer and the row's
       "Guard it" fall-through (2026-09-03). The confirm is the caller's - the engine runs SILENT
       here. Says what happened, and when nothing was guarded, WHICH zero it was: the guard only
       applies where the target install's own Pkg source declares the SAME External_Function name. */
    Procedure _RunExternalGuardOut String sVer String[] asFiles
        String sBody
        Integer iDone
        Boolean bRan bDummy bSkippedCalled

        Get RunScopedFunction "GuardDuplicateExternalFunctions" True "" "" asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piGuardedExternalCount of ghoFuncLib to iDone
        Send _ExternalGuardOutcomeBody sVer iDone (&sBody) (&bSkippedCalled)
        Get FTHtmlMessage "Guard duplicate External_Functions" sBody "OK" "" to bDummy
        If (bSkippedCalled = True or iDone = 0) Begin
            // Nothing changed, so the analysis is still valid: re-render just the LIST.
            Send RefreshFindings
            Procedure_Return
        End
        Send ShowStaleFindingsNote
    End_Procedure

    // The confirm body for RunGuardExternalForName: the Use-arm shape, what each release then
    // compiles, and the same-width fall-through. Returns the HTML.
    Function _ExternalGuardForNameConfirmBody String sName Integer iSites String sTarget Integer iGate Returns String
        String sGuard sGuardEsc sBody

        // Character()-built: a literal "#IF (!@" here would be consumed by FMAC during DFRefactor's own compile.
        Move (Character(35) + "IF (" + Character(33) + "@ < " + String(iGate) + ")") to sGuard
        Get HtmlEscaped sGuard to sGuardEsc
        Move (HelpParagraph("Version-guard " + (BoldHtml(sName)) + " in " + String(iSites) + " file(s). DataFlex " + sTarget + " declares this Windows API itself, and a second External_Function of a name is error 4390.")) to sBody
        Move (sBody + ((HelpParagraph("The workspace's declaration is kept for releases older than DataFlex " + sTarget + ":")) + "<pre>") + sGuardEsc + Character(10) + "    ..." + Character(10) + Character(35) + "ELSE" + Character(10) + "    Use &lt;DataFlex's own package&gt;" + Character(10) + Character(35) + "ENDIF</pre>") to sBody
        Move (sBody + (HelpParagraph("From " + sTarget + " on the file reads DataFlex's own declaration. No call site changes; nothing is deleted."))) to sBody
        Move (sBody + (HelpParagraph("A declaration that is not an ANSI (...A) binding is guarded out on newer releases instead - and left alone, with the reason, where this file still calls it."))) to sBody
        Function_Return sBody
    End_Function

    // Post-report offer for the duplicate-External_Function flavor of E 4390 ("already defined as an
    // external_function"): the same version guard the globals converter writes, applied by
    // GuardDuplicateExternalFunctions over the files the compiler pointed at. Mirrors RunGuardGlobals -
    // NOT silent (it writes source), file-precise scope, outcome stated with its reason.
    Procedure OfferExternalGuard
        String sVer sBody
        String[] asFiles
        Integer iVer
        Boolean bRan

        Get GuardVersionMacro (&sVer) to iVer      // the version named, or 0 after saying it could not be read
        If (iVer = 0) ;
            Procedure_Return
        // FILE-PRECISE, like the globals guard: a 4390 is reported AT the offending declaration, so
        // the files carrying those errors ARE the files to change.
        If (ghoModAnalyzerDock <> 0) ;
            Get pasBackportFiles of (oModAnalyzer_grd(ghoModAnalyzerDock)) to asFiles
        // GENERAL CONFIRM DIALOG pilot (Nils 2026-07-24): confirm + outcome via ghoConfirmDialog;
        // the engine runs SILENT since the question was already asked here.
        Get _ExternalGuardConfirmBody sVer iVer to sBody
        Get FTHtmlMessage "Guard duplicate External_Functions" sBody "Guard them" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Send _RunExternalGuardOut sVer asFiles
    End_Procedure

    /* The E 4390 External_Function row's "Guard it" (Nils 2026-09-03: the two WinServ rows offered
       only text and "Show declarations", while their fix - the Use-arm the wide guard writes - sat
       as a Review row behind a non-empty Auto-fixable band, found by accident). File-precise: the
       files declaring THIS name. The wide guard first - an ANSI (...A) declaration the target
       install declares itself gets its Use-arm (the file keeps calling the name; DataFlex's own
       package binds it from the target version on) - then, when it wrote nothing, the same-width
       guard with its own outcome, refusals included. One confirm covers both; both runs are silent. */
    Procedure RunGuardExternalForName
        String sName sVer sTarget sBody
        String[] asFiles
        Integer iVer iGate iDone
        Boolean bRan bDummy

        Get psPendingDeclName to sName
        Move (Trim(sName)) to sName
        If (sName = "") ;
            Procedure_Return
        Get GuardVersionMacro (&sVer) to iVer      // the version named, or 0 after saying it could not be read
        If (iVer = 0) ;
            Procedure_Return
        // The Use-arm's gate is the TARGET's version (it pairs with the Pkg folder the catalogue walks -
        // see GuardAnsiExternalFunctionWithWide); the workspace's own when that cannot be read.
        Get psTargetDfVersion of ghoApplication to sTarget
        Get DfVersionToMacroNumber of ghoFuncLib sTarget to iGate
        If (iGate = 0) Begin
            Move sVer to sTarget
            Move iVer to iGate
        End
        Get _BackportSiteFilesForName sName to asFiles
        If (SizeOfArray(asFiles) = 0 and ghoModAnalyzerDock <> 0) ;
            Get pasBackportFiles of (oModAnalyzer_grd(ghoModAnalyzerDock)) to asFiles
        Get _ExternalGuardForNameConfirmBody sName (SizeOfArray(asFiles)) sTarget iGate to sBody
        Get FTHtmlMessage "Guard duplicate External_Function" sBody "Guard it" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Get RunScopedFunction "GuardAnsiExternalFunctionWithWide" True "" "" asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piGuardedAnsiWideCount of ghoFuncLib to iDone
        If (iDone > 0) Begin
            Move ((HelpParagraph((BoldHtml("Version-guarded " + String(iDone) + " External_Function declaration(s)."))))) to sBody
            Move (sBody + (HelpParagraph("Each stays for releases older than DataFlex " + sTarget + "; from there on the file reads DataFlex's own declaration through a Use line. The run log names each declaration and the package it now comes from - " + (BoldText("VERIFY")) + " the call sites that pass text buffers."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it - the guarded errors should be gone from the list.")))) to sBody
            Get FTHtmlMessage "Guard duplicate External_Function" sBody "OK" "" to bDummy
            Send ShowStaleFindingsNote
            Procedure_Return
        End
        // Not an ANSI binding the wide guard could route (or already done): the same-width guard,
        // which says which zero it was when it too changes nothing.
        Send _RunExternalGuardOut sVer asFiles
    End_Procedure

    // The fixed header of the declined-calls report: what the file is, the reasons a call is declined,
    // and how to read each entry. Writes to the open channel iCh.
    Procedure _WriteDeclinedReportHeader Integer iCh
        Writeln channel iCh "Ambiguous calls still needing a hand change (error 4544)."
        Writeln channel iCh ""
        Writeln channel iCh "Convert to Get rewrites an expression-style call into a Get statement. It declined the"
        Writeln channel iCh "calls below, with the reason against each. Nothing here has been changed."
        Writeln channel iCh ""
        Writeln channel iCh "  old comparison words          - the line still uses Eq/Ne/Ge/Le/Gt/Lt, which cannot take the"
        Writeln channel iCh "                                  temporary variable the conversion introduces. Run Change legacy"
        Writeln channel iCh "                                  operators over the file, then convert again."
        Writeln channel iCh "  argument of a Find / Constrain - the eq/ge word there is the command's own mode, not a comparison,"
        Writeln channel iCh "                                  and a temporary cannot go in its place. Get the value into a typed"
        Writeln channel iCh "                                  variable on the line above, then use that variable in the command."
        Writeln channel iCh "  split over two lines          - a continuation line whose statement start could not be found."
        Writeln channel iCh ""
        Writeln channel iCh "Each entry: the line number, the reason, and the line as it stands - so this reads without the file open."
        Writeln channel iCh ""
    End_Procedure

    // Splits one "<file>|<line>|<why>|<text>" row of pasDeclinedCalls into its fields. Returns False
    // (and assigns nothing) when the row has no '|' at all; sWhy and sText come back "" when absent.
    Function _ParseDeclinedRow String sRow String ByRef sFile String ByRef sLine String ByRef sWhy String ByRef sText Returns Boolean
        Integer iPos

        Move (Pos("|", sRow)) to iPos
        If (iPos > 0) Begin
            Move (Left(sRow, (iPos - 1)))               to sFile
            Move (Right(sRow, (Length(sRow) - iPos)))   to sLine
            Move (Pos("|", sLine)) to iPos
            Move "" to sWhy
            Move "" to sText
            If (iPos > 0) Begin
                Move (Right(sLine, (Length(sLine) - iPos))) to sWhy
                Move (Left(sLine, (iPos - 1)))              to sLine
                // The 4th field (2026-08-17): the line's own text. Split on the FIRST '|' after the
                // reason - the text itself may contain '|'.
                Move (Pos("|", sWhy)) to iPos
                If (iPos > 0) Begin
                    Move (Right(sWhy, (Length(sWhy) - iPos))) to sText
                    Move (Left(sWhy, (iPos - 1)))              to sWhy
                End
            End
            Function_Return True
        End
        Function_Return False
    End_Function

    // Write the declined calls to a report in the workspace's backup folder, beside the other reports.
    // The clickable rows only live as long as this session's analysis, so anyone who wants to plan the
    // work, hand it to someone else, or come back to it tomorrow needs a file. Returns its path ("" if
    // it could not be written). Registered in pasOtherLogFiles so it shows up under Other log files.
    Function WriteDeclinedReport Returns String
        String[] asDeclined asOther
        String sHome sPath sRow sFile sLine sWhy sPrevFile sText
        Integer iCh i iLast
        Boolean bParsed

        Get pasDeclinedCalls to asDeclined
        Move (SizeOfArray(asDeclined) - 1) to iLast
        If (iLast < 0) ;
            Function_Return ""
        Get psHomeTarget of ghoApplication to sHome
        Move (vFolderFormat(sHome) + CS_BackupFolder + CS_DirSeparator + CS_AmbiguousCallsToFixLogFile) to sPath
        Get rfOpenOutput sPath to iCh
        If (iCh < 0) ;
            Function_Return ""
        Send _WriteDeclinedReportHeader iCh
        Move "" to sPrevFile
        For i from 0 to iLast
            Move asDeclined[i] to sRow
            Get _ParseDeclinedRow sRow (&sFile) (&sLine) (&sWhy) (&sText) to bParsed
            If (bParsed = True) Begin
                If (sFile <> sPrevFile) Begin
                    Writeln channel iCh ""
                    Writeln channel iCh sFile
                    Move sFile to sPrevFile
                End
                Writeln channel iCh ("    line " + sLine + "   " + sWhy)
                If (sText <> "") ;
                    Writeln channel iCh ("        " + sText)
            End
        Loop
        Writeln channel iCh ""
        Writeln channel iCh ("Total: " + String(iLast + 1) + " call(s) to change by hand.")
        Send rfCloseOutput iCh
        Get pasOtherLogFiles of ghoFuncLib to asOther
        If (SearchArray(sPath, asOther, Desktop, RefFunc(DFSTRICMP)) = -1) Begin
            Move sPath to asOther[-1]
            Set pasOtherLogFiles of ghoFuncLib to asOther
        End
        Function_Return sPath
    End_Function

    // Hand the declined calls to the Manual Changes tab. That grid - not a dialog and not a band in this
    // list - is where "what is left for me to do" belongs: it sorts, it holds hundreds of rows, and a
    // double-click opens the source. Rows are tagged with the contributing function, so re-running
    // replaces only this converter's findings and never discards another's.
    Procedure PushDeclinedToManualGrid String[] asDeclined
        String sRow sFile sLine sWhy
        Integer i iLast iPos iLine

        If (ghoManualChangesDock = 0) ;
            Procedure_Return
        Send ClearManualChanges of ghoManualChangesDock "ChangeAmbiguousCallToGet"
        Move (SizeOfArray(asDeclined) - 1) to iLast
        For i from 0 to iLast
            Move asDeclined[i] to sRow
            Move (Pos("|", sRow)) to iPos
            If (iPos > 0) Begin
                Move (Left(sRow, (iPos - 1)))             to sFile
                Move (Right(sRow, (Length(sRow) - iPos))) to sLine
                Move (Pos("|", sLine)) to iPos
                Move "" to sWhy
                If (iPos > 0) Begin
                    Move (Right(sLine, (Length(sLine) - iPos))) to sWhy
                    Move (Left(sLine, (iPos - 1)))              to sLine
                End
                // The reason is its own field; the line's text (a 4th field since 2026-08-17) belongs to
                // the report, not to the grid's reason column.
                Move (Pos("|", sWhy)) to iPos
                If (iPos > 0) ;
                    Move (Left(sWhy, (iPos - 1))) to sWhy
                Move sLine to iLine
                Send AddManualChange of ghoManualChangesDock "ChangeAmbiguousCallToGet" sFile iLine "Rewrite this call as a Get statement by hand" sWhy
            End
        Loop
        Send RefreshManualGrid of ghoManualChangesDock
        // Bring the tab forward when there IS something on it. Leaving the Analyzer selected meant the
        // work was filed somewhere the user had to know to go and look (Nils 2026-07-22).
        If (SizeOfArray(asDeclined) > 0 and ghoOutputDock <> 0) ;
            Send ShowTab of ghoOutputDock eTabManual
    End_Procedure

    /* THE VERDICT IS OUT OF DATE - the close for any run that has just rewritten source.

       A run cannot clear the findings board, and must not: those rows describe the code as the
       LAST COMPILE saw it, and blanking them would publish a clean result the tool has no evidence
       for. So every remedy ends by saying the board is stale and pointing at the Check that settles
       it (Nils 2026-07-29: "This text after a conversion doesn't seem right. I think that a Check
       is first needed?").

       Here rather than inline because RunHoistAmbiguous has TWO summary exits and only one of them
       said it. The other - the legacy-operator path, which is the one a workspace full of gt/le
       takes - converted, showed its total and stopped, so on WinServ the ComItem rewrite finished
       with no word about re-checking while the alignment path next to it said it properly (Nils
       2026-08-26). Two wordings of one sentence is how that happens; there is now one. */
    Function BoardIsStaleHtml Returns String
        String sBody

        Move ((HelpParagraph("The source has changed, so the error list on the board is from " + (BoldText("before")) + " this run. Run " + (BoldText("Check")) + " to see what is actually left."))) to sBody
        Move (sBody + (HelpParagraph("If errors do survive that, they are not calls this can reach. Two common reasons:"))) to sBody
        Move (sBody + (HelpParagraph(CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + ("the error is reported wherever a macro is USED, but the call itself sits once inside the macro, so one line causes many errors" + CS_Br) + CS_Nbsp + CS_Nbsp + CS_Bullet + CS_Nbsp + "the error is inside DataFlex's own packages, which are never changed"))) to sBody
        Move (sBody + ((HelpParagraph("Both are fixed at the declaration. Use " + (BoldText("Fix it...")) + " on the name, or " + (BoldText("Show the report")) + ", to see which ones disagree.")))) to sBody

        Function_Return sBody
    End_Function

    // Returns the ambiguous function names joined with ";" - the parameter ChangeAmbiguousCallToGet takes.
    Function _HoistParamList String[] ByRef asNames Returns String
        String sParam
        Integer i iLast

        Move (SizeOfArray(asNames) - 1) to iLast
        Move "" to sParam
        For i from 0 to iLast
            If (sParam <> "") ;
                Move (sParam + ";") to sParam
            Move (sParam + asNames[i]) to sParam
        Loop
        Function_Return sParam
    End_Function

    // Returns the one-dialog confirm body for the ambiguous-call rewrite: the report path's context
    // intro (sIntro), the how-it-works explanation with the Was/Now example, and the file count.
    Function _HoistConfirmBodyHtml String sIntro String sParam Integer iFileCount Integer iForeign Returns String
        String sBody

        Move sIntro to sBody
        Move (sBody + ((HelpParagraph("These functions are declared with different return types, so DataFlex cannot compile a call to them written " + (BoldText("inside an expression")) + ":")) + "<pre>") + (Replaces(";", sParam, ", ")) + "</pre>") to sBody
        Move (sBody + (HelpParagraph("Each such call is rewritten as a Get statement on the line above, and the expression then uses the result:"))) to sBody
        Move (sBody + "<pre>Was:   If (Value(oForm) = sWanted) Begin" + Character(10) + Character(10) + "Now:   Variant vDfrGet1" + Character(10) + "       Get Value of (oForm) to vDfrGet1" + Character(10) + "       If (vDfrGet1 = sWanted) Begin</pre>") to sBody
        Move (sBody + (HelpParagraph("No declaration is changed and no return type is altered. The Get form compiles because the destination variable says what the type is. Calls spread over TWO lines are deliberately left alone, so expect some to remain for hand work."))) to sBody
        // No back-up nag here (Nils 2026-08-16): RunScopedFunction shows the engine's own start
        // warning for anything that writes source, so this dialog was saying it twice.
        // ... minus the ones that are not this workspace's to write, named as such (2026-09-20).
        If (iForeign > 0) Begin
            Move (sBody + (HelpParagraph((BoldHtml('Files: ' + String(iFileCount))) + ' (the file(s) the compiler reported this in; ' + String(iForeign) + ' more are DataFlex' + "'" + 's own or write-protected and are left alone).'))) to sBody
        End
        Else Begin
            Move (sBody + (HelpParagraph((BoldHtml('Files: ' + String(iFileCount))) + ' (exactly the file(s) the compiler reported this in).'))) to sBody
        End
        Function_Return sBody
    End_Function

    // The compiler-named files this workspace can write (IsCompilerNamedFileWritable), how many were
    // dropped and the leaf of the first dropped - so an offer counts what it will actually touch.
    Function _WritableCompilerFiles String[] asFiles Integer ByRef iDropped String ByRef sFirstDropped Returns String[]
        String[] asKeep
        Integer i iLast
        Boolean bOk

        Move 0  to iDropped
        Move "" to sFirstDropped
        Move (SizeOfArray(asFiles) - 1) to iLast
        For i from 0 to iLast
            Get IsCompilerNamedFileWritable of ghoApplication asFiles[i] to bOk
            If (bOk = True) Begin
                Move asFiles[i] to asKeep[-1]
            End
            Else Begin
                Increment iDropped
                If (sFirstDropped = "") ;
                    Move (ExtractFileName(asFiles[i])) to sFirstDropped
            End
        Loop
        Function_Return asKeep
    End_Function

    /* THE REMAINING WORK IS STATED IN THE SUMMARY, NOT ASKED ABOUT AFTERWARDS (Nils 2026-08-17:
       after the run's own box came "Save the remaining work? - Write the report / Not now", then
       the report opened in a window - "this is very confusing!"). The report is DFRefactor's own
       file in the workspace's DFRefactor_Backup folder, regenerated from this run's list, so there
       is nothing to ask: write it, and say where it is in the same box that says what was left.
       One question per dialog - and this was not even a question. */
    // Returns the "call(s) that need a hand change" paragraph for the declined calls (empty when there
    // are none), writing the declined report on the way and naming where it went.
    Function _HoistRemainHtml String[] ByRef asDeclinedNow Returns String
        String sRemain sReportPath

        Move "" to sRemain
        If (SizeOfArray(asDeclinedNow) > 0) Begin
            Get WriteDeclinedReport to sReportPath
            Move ((CS_ParaOpen + "The ") + (BoldHtml(String(SizeOfArray(asDeclinedNow)) + " call(s)")) + " that need a hand change are listed on the " + (BoldText("Manual Changes")) + " tab - double-click a row to open the editor there") to sRemain
            If (sReportPath <> "") ;
                Move (sRemain + " - and written to <code>" + (Replaces("&", sReportPath, "&amp;")) + "</code> to pick up later") to sRemain
            Move (sRemain + ("." + CS_ParaEnd)) to sRemain
        End
        Function_Return sRemain
    End_Function

    // Returns the outcome's opening paragraphs: the converted count, then the two-line and the
    // Find / Constrain leftovers when they apply - each names its own next action.
    Function _HoistOutcomeBodyHtml Integer iDone Integer iTwoLine Integer iDbMode Returns String
        String sBody

        Move ((HelpParagraph((BoldHtml("Converted " + String(iDone) + " call(s) to Get statements."))))) to sBody
        If (iTwoLine > 0) ;
            Move (sBody + (HelpParagraph(String(iTwoLine) + " call(s) were left alone because the call is split over two lines. Nothing can be inserted between a line and its continuation, so those need doing by hand."))) to sBody
        /* A FIND / CONSTRAIN ARGUMENT IS HAND WORK, NOT AN OFFER (Nils 2026-08-17: 'Constrain
           WEB_FORM.NR eq (Value(oX))' was counted as "old comparison words", the operators run was
           offered, converted 0 of 170, the re-convert 0 more - and the closing box still said 4
           "still use old comparison words": "So why the question?"). The hoist now counts those
           under their own reason; they get their own sentence and never trigger the offer below. */
        If (iDbMode > 0) ;
            Move (sBody + (HelpParagraph(String(iDbMode) + " call(s) sit inside a Find / Constrain argument, where the eq/ge word is the command's own mode and the temporary variable cannot go. Hand work: Get the value into a typed variable on the line above, then use that variable in the Find / Constrain."))) to sBody
        Function_Return sBody
    End_Function

    // OFFER the prerequisite rather than naming it. Telling the user to go and run another function
    // means finding it in the ~95-function picker - the detour this redesign exists to remove (Nils
    // 2026-07-22: "Wouldn't it be better if the change legacy operators would be offered to the user
    // to be run automatically?"). Same files, then convert again, in one answer.
    // Asks the "Modernise the operators first?" question on top of sBody; on Yes runs Change legacy
    // operators and then the rewrite again over the same files, shows the second pass's outcome and
    // adds its converted count to iDone (handed back ByRef).
    Procedure _HoistModerniseThenConvert String[] ByRef asFiles String sParam String sBody String sRemain Integer iLegacy Integer ByRef iDone
        Integer iDone2 iTwoLine iDbMode
        Boolean bRan bDummy

        Move (sBody + (HelpParagraph(String(iLegacy) + " call(s) were left alone because their line still uses the old comparison words (Eq, Ne, Ge, Le, Gt, Lt) or Indicate. Those cannot use the temporary variable this conversion needs."))) to sBody
        Move (sBody + ((HelpParagraph("Run " + (BoldText("Change legacy operators")) + " over the same files now, and then convert again?")))) to sBody
        Move (sBody + sRemain) to sBody
        Get FTHtmlMessage "Modernise the operators first?" sBody "Modernise + convert" "Not now" to bRan
        If (bRan = True) Begin
            // The user has just answered for BOTH runs, so neither asks the engine's generic question.
            // The flag is one-shot (consumed at the end of a run), hence set once per run.
            Set pbStartQuestionAsked of ghoEngine to True
            Get RunScopedFunction "ChangeLegacyOperators" False "" "" asFiles to bRan
            If (bRan = True) Begin
                Set pbStartQuestionAsked of ghoEngine to True
                Get RunScopedFunction "ChangeAmbiguousCallToGet" False "" sParam asFiles to bRan
                Get piHoistConverted   of ghoFuncLib to iDone2
                Get piHoistSkipTwoLine of ghoFuncLib to iTwoLine
                Get piHoistSkipLegacy  of ghoFuncLib to iLegacy
                Get piHoistSkipDbMode  of ghoFuncLib to iDbMode
                Move ((HelpParagraph((BoldHtml("Converted " + String(iDone2) + " more call(s)")) + " after modernising the operators."))) to sBody
                // If the SAME lines are still being declined for legacy operators, the operators run
                // could not reach them - say so instead of implying progress and offering it again.
                If (iLegacy > 0) ;
                    Move (sBody + (HelpParagraph(String(iLegacy) + " call(s) still use old comparison words that Change legacy operators did not convert. Those need looking at by hand - running it again will not help."))) to sBody
                If (iTwoLine > 0) ;
                    Move (sBody + (HelpParagraph(String(iTwoLine) + " call(s) are still split over two lines and need doing by hand."))) to sBody
                If (iDbMode > 0) ;
                    Move (sBody + (HelpParagraph(String(iDbMode) + " call(s) sit inside a Find / Constrain argument - hand work, as above."))) to sBody
                Move (iDone + iDone2) to iDone
                Move (sBody + sRemain) to sBody
                // Same close as the other exit: source was rewritten, so the board is now stale.
                If (iDone > 0) ;
                    Move (sBody + (BoardIsStaleHtml(Self))) to sBody
                Get FTHtmlMessage "Modernise the operators first?" sBody "OK" "" to bDummy
                Set pbConvertFoundNothing to (iDone = 0)
            End
        End
    End_Procedure

    // A 0-CONVERTED RUN IS NOT A FAILURE and must not read like one. It means every call this can
    // reach was already done, and what is left needs a person - but the message led with
    // "Converted 0 call(s)" and then a paragraph about macros and DataFlex packages that is about
    // REMAINING ERRORS, not about this run, so the actual outcome was buried (Nils 2026-07-22:
    // "I don't think anything changed so far?" - he was right, and the dialog never said so).
    // State the outcome first, and only explain the leftovers that actually apply.
    // Shows the rewrite's ordinary close (no legacy-operator leftovers): the outcome, the leftovers
    // that apply, the remaining-work paragraph - in one OK box.
    Procedure _HoistShowOrdinaryClose String sBody String sRemain Integer iDone Integer iTwoLine
        Boolean bDummy

        If (iDone = 0) Begin
            Move ((HelpParagraph((BoldText("Nothing left for this to convert")) + " - every call it can reach has already been done."))) to sBody
            If (iTwoLine > 0) ;
                Move (sBody + (HelpParagraph("The " + String(iTwoLine) + " call(s) that remain are split over two lines, and a statement cannot be inserted between a line and its continuation. Those need doing by hand - they are listed on the " + (BoldText("Manual Changes")) + " tab."))) to sBody
            Move (sBody + ((HelpParagraph("Renaming the declarations clears all of them at once instead, including the ones no converter can reach. " + (BoldText("Check declarations")) + " lists the few lines involved.")))) to sBody
        End
        /* SAY WHAT IS KNOWN, AND NOTHING PAST IT (Nils 2026-07-29: "This text after a conversion
           doesn't seem right. I think that a Check is first needed?").

           He is right. The run has just rewritten source, so the board's error list describes the
           code as it was BEFORE it - and this paragraph opened by discussing whether "errors
           remain", a question nothing on screen can answer yet. It read as a verdict on the
           current state and was really a guess about it, which is the same fault as a stale
           board publishing a clean result: a claim outrunning its evidence.

           So: state the outcome, say plainly that the verdict is now out of date, offer the
           Check that settles it - and keep the macro / system-package explanation, but framed
           as what to expect IF errors survive that Check rather than as news about now. */
        Else Begin
            Move (sBody + (BoardIsStaleHtml(Self))) to sBody
        End
        Move (sBody + sRemain) to sBody
        Get FTHtmlMessage "Rewrite ambiguous calls" sBody "OK" "" to bDummy
    End_Procedure

    // Findings row "Hoist calls" (E 4544): rewrite the expression-style calls of the ambiguous methods into
    // hoisted Get statements, clearing the errors WITHOUT touching a declaration. The function names come
    // from the COMPILER (pasAmbiguousFnNames, lifted out of the 4544 texts), so nothing has to be typed by
    // the user or harvested from the workspace. NOT silent - it writes source, so the engine's start
    // warning and summary both belong here.
    Procedure RunHoistAmbiguous
        String[] asNames asFiles asDeclinedNow
        String sParam sConfirm sBody sRemain sOnly sLeaf
        Integer iLast iDone iLegacy iTwoLine iDbMode iForeign
        Boolean bRan bDummy
        Handle hoGrid

        If (ghoModAnalyzerDock = 0) ;
            Procedure_Return
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasAmbiguousFnNames of hoGrid to asNames
        Get pasAmbiguousFiles   of hoGrid to asFiles
        // A per-name "Fix it..." rewrites THAT name only (psHoistOnlyName, set around the offer chain);
        // the report path keeps the whole set - one problem, one rewrite. The file set stays the
        // compiler's: a name's sites are not listed per name, and the converter skips what it does not match.
        Get psHoistOnlyName to sOnly
        If (Trim(sOnly) <> "") Begin
            Move (ResizeArray(asNames, 0)) to asNames
            Move (Trim(sOnly)) to asNames[0]
        End
        Move (SizeOfArray(asNames) - 1) to iLast
        If (iLast < 0) Begin
            Get FTHtmlMessage "Rewrite ambiguous calls" (HelpParagraph("The compiler output named no ambiguous functions, so there is nothing to convert.")) "OK" "" to bDummy
            Procedure_Return
        End
        Get _HoistParamList (&asNames) to sParam
        /* ONLY THE FILES THIS WORKSPACE CAN WRITE (2026-09-20). The compiler's set can hold DataFlex's
           own packages - a 4544 reported INSIDE Winkern.pkg when that package fails to compile in a
           character-mode program - and the engine dropped those at its gate, AFTER the confirm: the
           dialog counted "Files: 3", the button ran, and a box said none could be written. Filtered
           here, so the confirm counts what will be touched and an all-foreign set never shows a
           Rewrite button at all. */
        Get _WritableCompilerFiles asFiles (&iForeign) (&sLeaf) to asFiles
        If (SizeOfArray(asFiles) = 0) Begin
            Set psHoistIntroHtml to ""
            Get _ForeignSitesOnlyHtml (If((Trim(sOnly) = ""), "these names", Trim(sOnly))) (AmbiguousCallCountForName(Self, sOnly)) sLeaf -1 to sBody
            Get FTHtmlMessage "Rewrite ambiguous calls" sBody "OK" "" to bDummy
            Procedure_Return
        End
        // ONE dialog for the whole question (Nils 2026-07-24: the rewrite asked twice in a row):
        // the report path's context intro (psHoistIntroHtml, one-shot from OfferCallRewrite) + the
        // how-it-works body + the file count + the backup warning - then the engine runs with the
        // question PRE-ANSWERED (pbStartQuestionAsked, the same flag the chained branch uses).
        Get psHoistIntroHtml to sBody
        Set psHoistIntroHtml to ""
        Get _HoistConfirmBodyHtml sBody sParam (SizeOfArray(asFiles)) iForeign to sBody
        Get FTHtmlMessage "Rewrite ambiguous calls" sBody "Rewrite the calls" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Set pbStartQuestionAsked of ghoEngine to True
        Get RunScopedFunction "ChangeAmbiguousCallToGet" False "" sParam asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        // SAY WHAT WAS LEFT ALONE, AND WHY. The engine's summary reports only "N lines changed", so a run
        // that converts 1 and declines 220 reads exactly like a broken one (Nils 2026-07-21: "feels like
        // we're going round in circles"). Each category below names its own next action, so the remaining
        // work is visible instead of having to be inferred from a disappointing error count.
        Get piHoistConverted   of ghoFuncLib to iDone
        Get pasHoistDeclined   of ghoFuncLib to asDeclinedNow
        Set pasDeclinedCalls to asDeclinedNow
        Send PushDeclinedToManualGrid asDeclinedNow
        // The remaining work is stated in the summary, not asked about afterwards - see _HoistRemainHtml.
        Get _HoistRemainHtml (&asDeclinedNow) to sRemain
        Get piHoistSkipLegacy  of ghoFuncLib to iLegacy
        Get piHoistSkipTwoLine of ghoFuncLib to iTwoLine
        Get piHoistSkipDbMode  of ghoFuncLib to iDbMode
        // Set here for the ordinary path; the chained branch (_HoistModerniseThenConvert) re-sets it after its second pass.
        Set pbConvertFoundNothing to (iDone = 0)
        Get _HoistOutcomeBodyHtml iDone iTwoLine iDbMode to sBody
        // Legacy-operator leftovers -> OFFER the prerequisite (see _HoistModerniseThenConvert); otherwise
        // the ordinary close (see _HoistShowOrdinaryClose).
        If (iLegacy > 0) Begin
            Send _HoistModerniseThenConvert (&asFiles) sParam sBody sRemain iLegacy (&iDone)
        End
        Else Begin
            Send _HoistShowOrdinaryClose sBody sRemain iDone iTwoLine
        End
        // (The "Save the remaining work?" question that used to follow here is gone - the report is
        // written unasked and named in the summary above; see the note above _HoistRemainHtml.)
        // Nothing converted -> leave the screen alone (see the note in RunGuardGlobals: refreshing would
        // blank the findings list and make a no-op run look like a freshly opened workspace).
        If (iDone = 0) Begin
            Send RefreshFindings
            Procedure_Return
        End
        Send ShowStaleFindingsNote
    End_Procedure

    // Findings row "Check declarations" (E 4544): the DECLARATION route, and now the PRIMARY action on the
    // row. The report names every declaration of the contested name - the workspace's AND the ones the
    // target DataFlex ships - which is what decides whether the fix is a rename or a type-alignment.
    // Silent: it changes nothing.
    // Fill the Manual Changes tab with the DECLARATION sites the report just named. Tagged with this
    // report as the contributor, so a re-run replaces its own rows and never discards the converter's.
    // ONE parser for the "<file>|<line>|<what>|<why>" rows every contributor produces - the report's
    // declaration sites and the rename converter's unprovable call sites use the same shape, and a
    // second copy of this parse would be a second place for the field order to drift.
    Procedure PushRowsToManualGrid String[] asDecls String sContributor
        String sRow sFile sRest sLine sWhat sWhy
        Integer i iLast iPos iLine

        If (ghoManualChangesDock = 0) ;
            Procedure_Return
        Send ClearManualChanges of ghoManualChangesDock sContributor
        Move (SizeOfArray(asDecls) - 1) to iLast
        For i from 0 to iLast
            Move asDecls[i] to sRow
            // "<file>|<line>|<what>|<why>" - a DataFlex path or identifier cannot contain "|".
            Move (Pos("|", sRow)) to iPos
            If (iPos > 0) Begin
                Move (Left(sRow, (iPos - 1)))             to sFile
                Move (Right(sRow, (Length(sRow) - iPos))) to sRest
                Move (Pos("|", sRest)) to iPos
                Move "" to sWhat
                Move "" to sWhy
                If (iPos > 0) Begin
                    Move (Left(sRest, (iPos - 1)))              to sLine
                    Move (Right(sRest, (Length(sRest) - iPos))) to sRest
                    Move (Pos("|", sRest)) to iPos
                    If (iPos > 0) Begin
                        Move (Left(sRest, (iPos - 1)))              to sWhat
                        Move (Right(sRest, (Length(sRest) - iPos))) to sWhy
                    End
                    Else ;
                        Move sRest to sWhat
                End
                Else ;
                    Move sRest to sLine
                Move sLine to iLine
                Send AddManualChange of ghoManualChangesDock sContributor sFile iLine sWhat sWhy
            End
        Loop
        Send RefreshManualGrid of ghoManualChangesDock
    End_Procedure

    // The declaration sites the report just named.
    Procedure PushMismatchDeclsToManualGrid
        String[] asDecls

        Get pasReturnMismatchDecls of ghoFuncLib to asDecls
        Send PushRowsToManualGrid asDecls "FunctionReturnMismatchReport"
        // BRING THE TAB FORWARD when this report actually filed something - the same reveal the other
        // two contributors already do (Nils 2026-07-22: work filed somewhere the user has to know to go
        // and look is work they never find). This path was the one that pushed in silence: it opens the
        // report in the log viewer and goes straight into the rename / align / rewrite offer, so the
        // NAVIGABLE copy - the one that double-clicks to the declaration - was never surfaced at all.
        // Guarded on THIS report's own rows, not ManualChangeCount: that counts every contributor, so a
        // rename's leftovers would yank the dock to a tab this run added nothing to. And zero is a real
        // answer here ("Total: 0 contested name(s)"), never a worklist to be shown an empty grid for.
        If (SizeOfArray(asDecls) > 0 and ghoOutputDock <> 0) ;
            Send ShowTab of ghoOutputDock eTabManual
    End_Procedure

    // The call sites the rename could not prove a receiver for. Its own contributor tag, so re-running
    // the rename replaces only these and leaves the report's declaration rows alone.
    Procedure PushRenameUnprovenToManualGrid
        String[] asRows
        Get pasRenameUnproven of ghoFuncLib to asRows
        Send PushRowsToManualGrid asRows "ChangeCollidingMethodName"
    End_Procedure

    // Returns the rung-1 question's body: sName has to be renamed, how its declarations break down
    // (described, not labelled), and why a non-class name renames mechanically.
    Function _HandRenameConfirmHtml String sName Returns String
        String[] asDecls
        String sBody sBreak
        Integer iDecls iGlobals iOther

        // DESCRIBE THE DECLARATIONS, do not label them (Split: a Global in one library, a plain
        // file-scope Function in another - Nils 2026-07-22).
        Get pasReturnMismatchDecls of ghoFuncLib to asDecls
        Get piMismatchGlobalDecls  of ghoFuncLib to iGlobals
        Move (SizeOfArray(asDecls)) to iDecls
        Move (iDecls - iGlobals) to iOther
        Move "" to sBreak
        If (iGlobals > 0) ;
            Move (String(iGlobals) + " declared Global") to sBreak
        If (iOther > 0 and sBreak <> "") ;
            Move (sBreak + ", " + String(iOther) + " at file scope without it") to sBreak
        If (iOther > 0 and sBreak = "") ;
            Move (String(iOther) + " at file scope, none declared Global") to sBreak
        Move ((HelpParagraph((BoldHtml(sName + " has to be renamed")) + " - the name belongs to DataFlex."))) to sBody
        // Reached from the row's own "Rename it..." there is no declaration harvest yet (iDecls = 0):
        // word it from the compiler's count instead of claiming "none of its 0 declarations".
        If (iDecls > 0) Begin
            Move (sBody + (CS_ParaOpen + "None of its ") + String(iDecls) + " declaration(s) is a class method") to sBody
            If (sBreak <> "") ;
                Move (sBody + " (" + sBreak + ")") to sBody
        End
        Else Begin
            Get NameBackportCount sName to iDecls
            If (iDecls > 0) ;
                Move (sBody + (CS_ParaOpen + "The compiler flags it at ") + String(iDecls) + " declaration(s) in the selected scope") to sBody
            Else ;
                Move (sBody + (CS_ParaOpen + "It is a plain global, not a class method")) to sBody
        End
        Move (sBody + (" - and a non-class name renames mechanically: the declaration, expression calls and of-less Get statements take the new name, while Get/Send ... " + (BoldText("of")) + (" &lt;object&gt; forms are never touched (those belong to the class method the name clashes with)." + CS_ParaEnd))) to sBody
        Move (sBody + (HelpParagraph("The rename runs over the whole scope, so every call site unifies in one pass."))) to sBody
        Function_Return sBody
    End_Function

    // Rung 1, answered Yes: sNew is the new name typed in the input box (default <name>X); runs
    // RenameCollidingGlobalFunction over the compiled scope and reports the count. Returns True only
    // when something was actually renamed.
    Function _HandRenameNow String sName String sNew Returns Boolean
        String[] asNoFiles
        String sBody
        Integer iRenamed
        Boolean bRan bDummy

        Move (Trim(sNew)) to sNew
        If (sNew = "" or Lowercase(sNew) = Lowercase(sName)) ;
            Move (sName + "X") to sNew
        Get CompiledScopeFiles to asNoFiles      // the compiled files, else the folder scope
        Get RunScopedFunction "RenameCollidingGlobalFunction" True "" (sName + "|" + sNew) asNoFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Get piRenamedGlobalCount of ghoFuncLib to iRenamed
        If (iRenamed > 0) Begin
            Move ((HelpParagraph((BoldHtml("Renamed " + String(iRenamed) + " line(s)")) + " - " + sName + " is now " + sNew + " at its declaration and every of-less call site in the scope."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it; any site the rename could not prove stays on the old name and will still be flagged.")))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was renamed")) + " - no declaration or of-less call of " + sName + " was found in the scope."))) to sBody
            Move (sBody + ((HelpParagraph("Widen the scope, or use " + (BoldText("Check declarations")) + " to see where the compiler saw it.")))) to sBody
        End
        Get FTHtmlMessage ("Rename " + sName) sBody "OK" "" to bDummy
        If (iRenamed = 0) ;
            Function_Return False
        // Source changed: same stale-notice contract as the other write-runs.
        Send ShowStaleFindingsNote
        Function_Return True
    End_Function

    // Rung 2 (rename declined): offers to list every declaration and use of sName on the Manual
    // Changes tab (ChangeCollidingMethodName's no-seeds path, which rewrites nothing). Returns True
    // when the list was built.
    Function _HandRenameWorklist String sName Returns Boolean
        String[] asNoFiles asUnproven
        String sBody
        Boolean bRan bDummy

        Move ((HelpParagraph("List every place " + sName + " is declared and used on the " + (BoldText("Manual Changes")) + " tab, so it can be worked through by hand?"))) to sBody
        Get FTHtmlMessage ("Rename " + sName + " by hand?") sBody "List them" "Not now" to bRan
        If (bRan = False) ;
            Function_Return False
        Get CompiledScopeFiles to asNoFiles
        Get RunScopedFunction "ChangeCollidingMethodName" True "" (sName + "=" + sName + "Renamed") asNoFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Send PushRenameUnprovenToManualGrid
        Get pasRenameUnproven of ghoFuncLib to asUnproven
        Move ((HelpParagraph("Every place " + sName ;
                    + " is declared or used is now on the " + (BoldText("Manual Changes")) + " tab - " ;
                    + (BoldHtml(String(SizeOfArray(asUnproven)) + " row(s)")) ;
                    + ". Double-click a row to open the editor there."))) to sBody
        Move (sBody + (HelpParagraph("Nothing was changed. Which declaration a given call means cannot be told from the source, so none of it was guessed at."))) to sBody
        Get FTHtmlMessage ("Rename " + sName + " by hand") sBody "OK" "" to bDummy
        If (SizeOfArray(asUnproven) > 0 and ghoOutputDock <> 0) ;
            Send ShowTab of ghoOutputDock eTabManual
        Function_Return True
    End_Function

    /* For a name that MUST be renamed and is not a class method. Since RenameCollidingGlobalFunction
       (2026-07-24) that is no longer a dead end: the declaration, expression calls and of-less Get
       statements rename mechanically; Get/Send ... OF <object> forms are never touched (those are
       the class method the name clashes with). So the offer is a two-rung ladder, each question in
       its own dialog (the one-question rail):
         1) Rename NOW over the whole scope - the confirm dialog's INPUT slot's first live customer:
            the new name is entered right in the dialog, default <name>X (the workspace's own
            SQLExecuteX convention).
         2) Declined -> the previous behavior: list every declaration + use on the Manual Changes
            tab (built by ChangeCollidingMethodName's no-seeds path, which rewrites nothing). */
    Function OfferHandRenameWorklist String sName Returns Boolean
        String sBody sNew
        Boolean bRan

        // ---- Rung 1: rename NOW ----
        Get _HandRenameConfirmHtml sName to sBody
        Move (sName + "X") to sNew
        Get FTInputBox ("Rename " + sName) sBody "Rename to:" (&sNew) "Rename now" "Not now" to bRan
        If (bRan = True) Begin
            Get _HandRenameNow sName sNew to bRan
            Function_Return bRan
        End
        // ---- Rung 2 (rename declined): the worklist offer, exactly as before ----
        Get _HandRenameWorklist sName to bRan
        Function_Return bRan
    End_Function

    /* Did the COMPILER say this name is already defined (error 4390)? That is the one oracle that sees
       the runtime, and it settles the rename-vs-align question that a source scan cannot.

       The scan can only read the target install's Pkg SOURCE, so a name the runtime owns reads back as
       "DataFlex does not use this name" - the exact opposite of the truth. Nils, 2026-07-22: Split belongs
       to DataFlex's cRegEx and the DF 26 release candidate MOVED IT INTO THE RUNTIME, so it appears in no
       Pkg file in either version. A hand-kept list of runtime names would have to be re-curated every
       release; this derivation cannot go stale, because the compiler is re-run every time.

       Checked against all three live cases: Split (4390, Pkg 0) -> rename; Value (4544, Pkg 7) -> rename;
       pbSilent (4544, Pkg 0) -> align, which is what actually cleared its 151 errors. */
    Function NameHasBackportError String sName Returns Boolean
        String[] asBack
        Integer i iLast
        Handle hoGrid
        If (ghoModAnalyzerDock = 0) ;
            Function_Return False
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasBackportNames of hoGrid to asBack
        Move (SizeOfArray(asBack) - 1) to iLast
        For i from 0 to iLast
            If (Lowercase(Trim(asBack[i])) = Lowercase(Trim(sName))) ;
                Function_Return True
        Loop
        Function_Return False
    End_Function

    // One pasReturnMismatchOwnTypes row, "<file>|<line>|<type>", into its parts (the type trimmed); False
    // for a row with no file.
    Function _SplitOwnTypeRow String sRow String ByRef sFile String ByRef sLine String ByRef sType Returns Boolean
        Integer iPos iP2

        Move (Pos("|", sRow)) to iPos
        If (iPos <= 1) ;
            Function_Return False
        Move (Left(sRow, (iPos - 1)))             to sFile
        Move (Right(sRow, (Length(sRow) - iPos))) to sRow
        Move (Pos("|", sRow)) to iP2
        Move "" to sLine
        Move sRow to sType
        If (iP2 > 0) Begin
            Move (Left(sRow, (iP2 - 1)))             to sLine
            Move (Right(sRow, (Length(sRow) - iP2))) to sType
        End
        Move (Trim(sType)) to sType
        Function_Return True
    End_Function

    /* THE EVEN-SPLIT ALIGN (2026-09-03). The workspace's own declarations of sPlain disagree with no
       majority to follow - COMREPLACE: two declarations, two types. OfferDeclarationAlign used to
       return in silence here ("a decision, not a fix") and the chain fell through to the call
       rewrite, whose text called a rename "the smaller change" - which sent Nils into a 937-call
       rewrite of every name for a 2-error one. The decision IS the user's, so it is asked: every
       declaration with its type, the type to use in the input slot (the first as default), then
       the same converter the majority path runs, changing each declaration that differs. A type
       that none of them declares is refused - the choice is between what exists. Returns True
       when the run changed something. */
    Function _OfferAlignTie String sPlain Returns Boolean
        String[] asTypes asNoFiles asSeen
        String sBody sFile sLine sType sDefault sChosen sParam
        Integer i iLast iCalls iAligned
        Boolean bRan bDummy bRow

        Get pasReturnMismatchOwnTypes of ghoFuncLib to asTypes
        Move (SizeOfArray(asTypes) - 1) to iLast
        If (iLast < 1) ;
            Function_Return False
        Get AmbiguousCallCountForName sPlain to iCalls
        Move ((HelpParagraph("Nothing outside this workspace uses the name " + (BoldHtml(sPlain)) + ", but the workspace's declarations disagree on its return type - with no majority to follow, so the tool cannot pick one for you:"))) to sBody
        Move (sBody + "<pre>") to sBody
        Move "" to sDefault
        For i from 0 to iLast
            Get _SplitOwnTypeRow asTypes[i] (&sFile) (&sLine) (&sType) to bRow
            If (bRow = True) Begin
                If (sType <> "" and SearchArray(sType, asSeen, Desktop, RefFunc(DFSTRICMP)) = -1) ;
                    Move sType to asSeen[-1]
                If (sDefault = "") ;
                    Move sType to sDefault
                Get HtmlEscaped sFile to sFile
                If (i > 0) ;
                    Move (sBody + Character(10)) to sBody
                Move (sBody + sFile + "  line " + sLine + "  returns " + sType) to sBody
            End
        Loop
        Move (sBody + "</pre>") to sBody
        Move (sBody + (HelpParagraph("Enter the type ALL of them should return. Every declaration that differs is changed to it; nothing else moves."))) to sBody
        If (iCalls > 0) ;
            Move (sBody + (HelpParagraph("That clears all " + (BoldHtml(String(iCalls))) + " of these errors and touches no call site."))) to sBody
        Move (sBody + (HelpParagraph("This changes a declared " + (BoldText("TYPE")) + ", so check that nothing assigns a value to it that the chosen type cannot hold."))) to sBody
        Move sDefault to sChosen
        Get FTInputBox ("Align " + sPlain) sBody "Return type for all:" (&sChosen) "Change them" "Not now" to bRan
        If (bRan = False) ;
            Function_Return False
        Move (Trim(sChosen)) to sChosen
        If (sChosen = "") ;
            Move sDefault to sChosen
        If (SearchArray(sChosen, asSeen, Desktop, RefFunc(DFSTRICMP)) = -1) Begin
            Get FTHtmlMessage ("Align " + sPlain) (HelpParagraph((BoldText("Nothing was changed.")) + " " + sChosen + " is not one of the types these declarations return - the choice is between the types listed.")) "OK" "" to bDummy
            Function_Return False
        End
        Move (sPlain + "=" + sChosen) to sParam
        Get CompiledScopeFiles to asNoFiles      // the compiled files, else the folder scope
        Get RunScopedFunction "AlignCollidingDeclarationType" True "" sParam asNoFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Get piAlignedDecls of ghoFuncLib to iAligned
        Move ((HelpParagraph((BoldHtml("Changed " + String(iAligned) + " declaration(s) of " + sPlain + " to " + sChosen + "."))))) to sBody
        Move (sBody + ((HelpParagraph("Only the declaration line" + (If((iAligned = 1), "", "s")) + " changed - every call of " + sPlain + " is exactly as it was. Run " + (BoldText("Check")) + " again to see what the compiler makes of it.")))) to sBody
        Get FTHtmlMessage ("Align " + sPlain) sBody "OK" "" to bDummy
        If (iAligned = 0) ;
            Function_Return False
        Send ShowStaleFindingsNote
        Function_Return True
    End_Function

    /* The odd declarations of sPlain whose BODY returns text, when the majority type cannot hold
       text - the fact that turns an align into a rename (see OfferDeclarationAlign). Reads each odd
       site's file once and asks FunctionReturnsTextIn (cModAnalyzer, either-ender aware). Fills
       asText with "<file>|<line>|<type>|<evidence>|<mixed>" rows - mixed = 1 when the SAME file
       also declares the name with the majority type, where a file-scoped rename would catch both
       and the fix has to be by hand. Returns the row count. A majority of String or Variant holds
       anything, so nothing is read and 0 comes back. Reads capped at 12 files. */
    Function _OddDeclsReturningText String sPlain String sMajor String[] ByRef asText Returns Integer
        String[] asTypes asLines
        String sFile sLine sType sEv sLastFile sMajLc sFileLc sRow2 sFile2 sType2
        Integer i j iLast iPos iP2 iLine iReads
        Handle hoAn
        Boolean bMixed bRow

        Move (Lowercase(Trim(sMajor))) to sMajLc
        If (sMajLc = "" or sMajLc = "string" or sMajLc = "variant") ;
            Function_Return 0
        Get pasReturnMismatchOwnTypes of ghoFuncLib to asTypes
        Move (SizeOfArray(asTypes) - 1) to iLast
        If (iLast < 1) ;
            Function_Return 0
        Get Create (RefClass(cModAnalyzer)) to hoAn
        If (hoAn = 0) ;
            Function_Return 0
        Move "" to sLastFile
        Move 0 to iReads
        For i from 0 to iLast
            Get _SplitOwnTypeRow asTypes[i] (&sFile) (&sLine) (&sType) to bRow
            If (bRow = True) Begin
                Move sLine to iLine
                Move (Lowercase(Trim(sFile))) to sFileLc
                If (Lowercase(sType) <> sMajLc and iLine > 0 and sFileLc <> "") Begin
                    If (sFileLc <> sLastFile and iReads < 12) Begin
                        Move (rfReadEncodedFileAsStringArray(sFile)) to asLines
                        Move sFileLc to sLastFile
                        Increment iReads
                    End
                    Move "" to sEv
                    If (sFileLc = sLastFile) ;
                        Get FunctionReturnsTextIn of hoAn (&asLines) iLine to sEv
                    If (sEv <> "") Begin
                        // Does this same file also carry a majority-typed declaration?
                        Move False to bMixed
                        For j from 0 to iLast
                            Move asTypes[j] to sRow2
                            Move (Pos("|", sRow2)) to iPos
                            If (iPos > 1) Begin
                                Move (Lowercase(Trim(Left(sRow2, (iPos - 1))))) to sFile2
                                Move (Right(sRow2, (Length(sRow2) - iPos))) to sRow2
                                Move (Pos("|", sRow2)) to iP2
                                Move sRow2 to sType2
                                If (iP2 > 0) ;
                                    Move (Right(sRow2, (Length(sRow2) - iP2))) to sType2
                                If (sFile2 = sFileLc and Lowercase(Trim(sType2)) = sMajLc) ;
                                    Move True to bMixed
                            End
                        Loop
                        Move (sFile + "|" + sLine + "|" + sType + "|" + sEv + "|" + (If(bMixed, "1", "0"))) to asText[-1]
                    End
                End
            End
        Loop
        Send Destroy of hoAn
        Function_Return (SizeOfArray(asText))
    End_Function

    /* THE RENAME OF THE ODD ONE OUT (Nils 2026-09-04, "go ahead and make those changes"). Shown in
       place of the align when _OddDeclsReturningText found text coming back from a declaration the
       majority type could not hold: the evidence line by line, then the input slot with
       <name>Text, then RenameSameNamedMethod over the odd files ONLY - its declaration, expression
       calls and of-less Gets rename there; the majority declarations never see the run. A call from
       another file through "of <object>" is out of reach by design and is said so. A mixed file
       (the odd one beside a majority-typed one) is refused: a file-wide rename would catch both.
       Returns True when something was renamed. */
    Function _OfferOddRename String sPlain String sMajor String[] ByRef asText Returns Boolean
        String[] asFiles
        String sBody sRow sFile sRest sLine sType sEv sMixed sNew sPlural
        Integer i iLast iPos iRenamed iMixed
        Boolean bRan bDummy

        Move (SizeOfArray(asText) - 1) to iLast
        If (iLast < 0) ;
            Function_Return False
        Move (If((iLast = 0), "", "s")) to sPlural
        Move ((HelpParagraph("Nothing outside this workspace uses the name " + (BoldHtml(sPlain)) + ", and most of its declarations say " + (BoldHtml(sMajor)) + " - but " + (If((iLast = 0), "this one returns", "these return")) + " text, which " + sMajor + " cannot hold:"))) to sBody
        Move (sBody + "<pre>") to sBody
        Move 0 to iMixed
        For i from 0 to iLast
            Move asText[i] to sRow
            Move (Pos("|", sRow)) to iPos
            Move (Left(sRow, (iPos - 1)))             to sFile
            Move (Right(sRow, (Length(sRow) - iPos))) to sRest
            Move (Pos("|", sRest)) to iPos
            Move (Left(sRest, (iPos - 1)))              to sLine
            Move (Right(sRest, (Length(sRest) - iPos))) to sRest
            Move (Pos("|", sRest)) to iPos
            Move (Left(sRest, (iPos - 1)))              to sType
            Move (Right(sRest, (Length(sRest) - iPos))) to sRest
            Move (Pos("|", sRest)) to iPos
            Move (Left(sRest, (iPos - 1)))              to sEv
            Move (Right(sRest, (Length(sRest) - iPos))) to sMixed
            If (sMixed = "1") ;
                Increment iMixed
            If (SearchArray(Lowercase(sFile), asFiles) = -1 and sMixed <> "1") ;
                Move (Lowercase(sFile)) to asFiles[-1]
            If (i > 0) ;
                Move (sBody + Character(10)) to sBody
            Move (sBody + (HtmlEscaped(Self, sFile)) + "  line " + sLine + "  returns " + sType + "  -  " + (HtmlEscaped(Self, sEv))) to sBody
        Loop
        Move (sBody + "</pre>") to sBody
        Move (sBody + (HelpParagraph((BoldHtml("This is a different function that happens to share the name.")) + " Retyping it to " + sMajor + " would compile - and make it return 0 where the text was. The fix is a name of its own."))) to sBody
        If (iMixed > 0) Begin
            Move (sBody + (HelpParagraph("Its file also declares " + sPlain + " as " + sMajor + ", so a file-wide rename would catch both - rename this one by hand: the declaration line and the calls that mean it."))) to sBody
            Get FTHtmlMessage ("Rename " + sPlain) sBody "OK" "" to bDummy
            Function_Return False
        End
        Move (sBody + (HelpParagraph("The declaration and every call of it in its own file" + sPlural + " - expression calls and of-less Get statements - are renamed; the " + sMajor + " declarations and their calls are not touched. A call from another file through " + (BoldHtml("of &lt;object&gt;")) + " is not renamed and the next Check will flag it."))) to sBody
        Move (sPlain + "Text") to sNew
        Get FTInputBox ("Rename " + sPlain) sBody "Rename to:" (&sNew) "Rename it" "Not now" to bRan
        If (bRan = False) ;
            Function_Return False
        Move (Trim(sNew)) to sNew
        If (sNew = "" or Lowercase(sNew) = Lowercase(sPlain)) ;
            Move (sPlain + "Text") to sNew
        Set pbStartQuestionAsked of ghoEngine to True
        Get RunScopedFunction "RenameSameNamedMethod" True "" (sPlain + "|" + sNew) asFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Get piRenamedMethodCount of ghoFuncLib to iRenamed
        If (iRenamed > 0) Begin
            Move ((HelpParagraph((BoldHtml("Renamed " + String(iRenamed) + " line(s)")) + " - " + sPlain + " is now " + sNew + " at its declaration and its calls in " + String(SizeOfArray(asFiles)) + " file(s). The " + sMajor + " declarations keep the name."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it.")))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was renamed")) + " - no declaration or of-less call of " + sPlain + " was found in the file(s) listed."))) to sBody
        End
        Get FTHtmlMessage ("Rename " + sPlain) sBody "OK" "" to bDummy
        If (iRenamed > 0) ;
            Send ShowStaleFindingsNote
        Else ;
            Send RefreshFindings
        Function_Return (iRenamed > 0)
    End_Function

    // Returns the align question's body: why renaming would not help, the majority type, the odd
    // declarations as a code block, what changing them clears, and the declared-TYPE caveat.
    Function _AlignConfirmHtml String sPlain String sMajor String[] ByRef asOdd Integer iOdd Integer iCalls Returns String
        String sBody sRow sRest sFile sLine
        Integer i iLast iPos

        // Confirm via the general dialog (Nils 2026-07-24): the odd declarations as a code block.
        Move ((HelpParagraph("Nothing outside this workspace uses the name " + (BoldHtml(sPlain)) + ", so renaming it would change nothing - the declarations would simply disagree under the new name."))) to sBody
        Move (sBody + (HelpParagraph("Most of them say " + (BoldHtml(sMajor)) + ". These do not:")) + "<pre>") to sBody
        Move (iOdd - 1) to iLast
        For i from 0 to iLast
            Move asOdd[i] to sRow
            Move (Pos("|", sRow)) to iPos
            If (iPos > 1) Begin
                Move (Left(sRow, (iPos - 1)))             to sFile
                Move (Right(sRow, (Length(sRow) - iPos))) to sRest
                Move (Pos("|", sRest)) to iPos
                Move "" to sLine
                If (iPos > 1) ;
                    Move (Left(sRest, (iPos - 1))) to sLine
                Get HtmlEscaped sFile to sFile
                If (i > 0) ;
                    Move (sBody + Character(10)) to sBody
                Move (sBody + sFile + "  line " + sLine) to sBody
            End
        Loop
        Move (sBody + "</pre>") to sBody
        If (iCalls > 0) ;
            Move (sBody + (HelpParagraph("Changing them to " + sMajor + " clears all " + (BoldHtml(String(iCalls))) + " of these errors, and touches no call site at all."))) to sBody
        If (iCalls = 0) ;
            Move (sBody + (HelpParagraph("Changing them to " + sMajor + " clears the ambiguity, and touches no call site at all."))) to sBody
        Move (sBody + (HelpParagraph("This changes a declared " + (BoldText("TYPE")) + ", so check that nothing assigns a value to it that " + sMajor + " cannot hold."))) to sBody
        Function_Return sBody
    End_Function

    /* THE OTHER FIX - and for a name nothing outside the workspace owns, the ONLY one that works.

       Two packages declare pbSilent Boolean, a third declares it String, 151 errors follow, and one word
       separates them from a clean build. Renaming all three would have carried the same disagreement to
       the new name; the report knows that, because it knows DataFlex declares the name nowhere.

       Changing a declared TYPE is a semantic change, so the question names the file, the line and both
       types, and says plainly what could go wrong. Nothing is inferred that the user cannot check in one
       glance. Returns True when the align actually ran. */
    Function OfferDeclarationAlign String sName Returns Boolean
        String[] asOdd asNoFiles asText
        String sBody sMajor sParam sPlain sPath
        Integer iOdd iCalls iAligned iText
        Boolean bRan bScanFailed bBackport bDummy bTie

        Move (Trim(sName)) to sPlain
        If (sPlain = "") ;
            Function_Return False
        Get psMismatchMajorityType of ghoFuncLib to sMajor
        Get pasReturnMismatchOdd   of ghoFuncLib to asOdd
        Move (SizeOfArray(asOdd)) to iOdd
        // No majority (an even split) means there IS no odd one out - that is a decision, not a fix,
        // and since 2026-09-03 it is ASKED (_OfferAlignTie) once the two guards below have had their say.
        Move (sMajor = "" or iOdd = 0) to bTie
        // THE COMPILER OVERRULES THE SCAN. If it reported "already defined" for this name, something
        // outside our source owns it, whatever the Pkg folder did or did not contain - and aligning our
        // own declarations to each other cannot clear that. Without this the runtime-owned names read as
        // unowned and land here, where the fix would edit declared types on a false premise.
        Get NameHasBackportError sPlain to bBackport
        If (bBackport = True) Begin
            Move ((HelpParagraph("The compiler reports that " + (BoldHtml(sPlain + " is already defined")) + " (error 4390), so something outside this workspace owns the name. DataFlex's packages do not declare it, which leaves the runtime, an External_Function, or a class method that has moved into the runtime - DataFlex 26 did exactly that with Split."))) to sBody
            Move (sBody + ((HelpParagraph("Aligning the workspace's declarations to each other cannot clear that. They have to stop using the name - rename them. The declarations are listed on the " + (BoldText("Manual Changes")) + " tab.")))) to sBody
            Get FTHtmlMessage ("Align " + sPlain) sBody "OK" "" to bDummy
            Function_Return False
        End
        // ALIGNING IS ONLY SAFE ONCE WE KNOW DATAFLEX DOES NOT HOLD THE NAME, and an unread Pkg folder
        // means we do not. Aligning our declarations to each other while the runtime holds the name with
        // a different type would change nothing and read as a failed fix; worse, it edits declared types
        // on no evidence at all. Say what is wrong instead of guessing (Nils 2026-07-22).
        Get pbInstallScanFailed of ghoFuncLib to bScanFailed
        If (bScanFailed = True) Begin
            Get psInstallScanPath of ghoFuncLib to sPath
            Get HtmlEscaped sPath to sPath
            Move ((HelpParagraph("The target DataFlex's packages could not be read, so there is no way to tell whether DataFlex itself declares " + (BoldHtml(sPlain)) + " - and that is what decides whether to rename the workspace's declarations or align them."))) to sBody
            Move (sBody + ((HelpParagraph("Looked in:")) + "<pre>") + sPath + "</pre>") to sBody
            Move (sBody + ((HelpParagraph("Point the workspace at an installed DataFlex version, then run " + (BoldText("Check")) + " again.")))) to sBody
            Get FTHtmlMessage ("Align " + sPlain) sBody "OK" "" to bDummy
            Function_Return False
        End
        If (bTie = True) Begin
            Get _OfferAlignTie sPlain to bRan
            Function_Return bRan
        End
        /* WHAT DOES THE ODD ONE RETURN? (Nils 2026-09-04, LegacyApp FCOUNT.) Two Integer fCounts return
           a count; Unit.sl's returns "Fixed amount". This offer compared the declared types and
           retyped the text one to Integer - it compiled, and the selection list shows 0 where the
           description was. Its only guard was the closing sentence asking the user to check what
           the tool could have read itself. Now it reads the body: a Function whose body returns
           text, against a majority type that cannot hold text, is a DIFFERENT function sharing the
           name - a rename, never an align. Properties have no body and keep this path (pbSilent). */
        Get _OddDeclsReturningText sPlain sMajor (&asText) to iText
        If (iText > 0) Begin
            Get _OfferOddRename sPlain sMajor (&asText) to bRan
            Function_Return bRan
        End
        Get AmbiguousCallCountForName sPlain to iCalls
        Move (sPlain + "=" + sMajor) to sParam
        Get _AlignConfirmHtml sPlain sMajor (&asOdd) iOdd iCalls to sBody
        Get FTHtmlMessage ("Align " + sPlain + " to " + sMajor) sBody "Change them" "Not now" to bRan
        If (bRan = False) ;
            Function_Return False
        Get CompiledScopeFiles to asNoFiles      // the compiled files, else the folder scope
        Get RunScopedFunction "AlignCollidingDeclarationType" True "" sParam asNoFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Get piAlignedDecls of ghoFuncLib to iAligned
        Move ((HelpParagraph((BoldHtml("Changed " + String(iAligned) + " declaration(s) of " + sPlain + " to " + sMajor + "."))))) to sBody
        // "No call site was touched" read as a puzzle (Nils 2026-09-04) - say what it meant.
        Move (sBody + ((HelpParagraph("Only the declaration line" + (If((iAligned = 1), "", "s")) + " changed - every call of " + sPlain + " is exactly as it was. Run " + (BoldText("Check")) + " again to see what the compiler makes of it.")))) to sBody
        Get FTHtmlMessage ("Align " + sPlain + " to " + sMajor) sBody "OK" "" to bDummy
        // Same close as the rename: changed source -> the stale note, not a re-render of the old rows.
        If (iAligned > 0) ;
            Send ShowStaleFindingsNote
        Else ;
            Send RefreshFindings
        Function_Return True
    End_Function

    // A declaration outside the workspace home sits in a library this workspace SHARES. It gets
    // renamed - the user asked for it - but the other applications compiling against that library
    // still expect the old name, and that has to be said before the write, not discovered after.
    // Returns how many of the iDecls "<file>|<line>|..." rows in asDecls lie outside the workspace home.
    Function _SharedDeclCount String[] ByRef asDecls Integer iDecls Returns Integer
        String sHome sRow sLc
        Integer i iLast iPos iShared

        Get psHomeTarget of ghoApplication to sHome
        Move (Lowercase(vFolderFormat(sHome))) to sHome
        Move 0 to iShared
        Move (iDecls - 1) to iLast
        For i from 0 to iLast
            Move asDecls[i] to sRow
            Move (Pos("|", sRow)) to iPos
            If (iPos > 1) Begin
                Move (Lowercase(Left(sRow, (iPos - 1)))) to sLc
                If (sHome <> "" and Pos(sHome, sLc) <> 1) ;
                    Increment iShared
            End
        Loop
        Function_Return iShared
    End_Function

    // The suggested name is DERIVED, not invented: the declaring class without its leading "c".
    // "ByKey" was apt for a keyed accessor like Value and absurd for anything else.
    // Returns the name to pre-fill in the rename question for sPlain, declared in class sDeclClass.
    Function _SuggestedRenameFor String sPlain String sDeclClass Returns String
        String sRoot sNew

        Move sDeclClass to sRoot
        If (Lowercase(Left(sRoot, 1)) = "c") ;
            Move (Right(sRoot, (Length(sRoot) - 1))) to sRoot
        Move (sRoot + sPlain) to sNew
        /* ...UNLESS THE ROOT ALREADY SAYS THE NAME, in which case gluing them together produces a
           word nobody would type. Class PageSetupDialog declaring PageSetupDlg suggested
           "PageSetupDialogPAGESETUPDLG" - the class root, plus the name in the COMPILER's shouting
           case - and it was pre-filled in an editable box, which is exactly enough plausibility to
           be accepted (Nils, 2026-08-26). Fall back to the same "<name>Renamed" default the picker
           already uses, which reads as the placeholder it is. */
        If (Lowercase(sRoot) contains Lowercase(sPlain) or Lowercase(sPlain) contains Lowercase(sRoot)) ;
            Move (sPlain + "Renamed") to sNew
        Function_Return sNew
    End_Function

    // The body for the CONFIRM DIALOG with the INPUT slot; the rationale (Nils 2026-07-24) sits at the
    // ShowConfirm in OfferDeclarationRename that shows it.
    // Returns the rename question's body: the declaration count, what renaming clears, the
    // shared-library note when it applies, and the two closing paragraphs.
    Function _RenameConfirmHtml String sPlain Integer iDecls Integer iCalls Integer iShared Returns String
        String sBody

        Move (CS_ParaOpen + (BoldHtml(sPlain + " is declared in " + String(iDecls) + " place(s)")) + " in this workspace.") to sBody
        If (iCalls > 0) ;
            Move (sBody + " Renaming it clears all " + (BoldHtml(String(iCalls))) + (" of these errors at once - including the ones no call-site converter can reach: calls split over two lines, calls inside a macro, and calls in DataFlex's own packages." + CS_ParaEnd)) to sBody
        If (iCalls = 0) ;
            Move (sBody + (" Renaming it clears the ambiguity at once." + CS_ParaEnd)) to sBody
        If (iShared > 0) ;
            Move (sBody + (HelpParagraph((BoldText("Note:")) + " " + String(iShared) + " of those declaration(s) live outside this workspace's own folder, in a library shared with other applications. They will be renamed here, and those applications will need the same change."))) to sBody
        Move (sBody + (HelpParagraph("The suggested name is taken from the declaring class - edit it below if another fits better."))) to sBody
        Move (sBody + ((HelpParagraph("Only calls whose receiver can be proved from the source are renamed. Anything else is listed on the " + (BoldText("Manual Changes")) + " tab rather than guessed at.")))) to sBody
        Function_Return sBody
    End_Function

    // "Renamed on 0 line(s)" after the user said Yes is the silent no-op wearing a number. Say what
    // stopped it: this renames CLASS methods, and a global function has no class to walk.
    // Shows the rename's outcome box once ChangeCollidingMethodName has run: the no-class-seeds
    // hand-over (the whole job to the Manual Changes tab, tab brought forward), or the renamed count
    // with the unprovable call sites followed by the findings refresh.
    Procedure _RenameShowOutcome String sPlain String sNew Integer iRenamed Boolean bNoSeeds
        String[] asUnproven
        String sBody
        Boolean bDummy

        If (bNoSeeds = True) Begin
            // Hand over the WHOLE job, and bring the tab forward. Handing back only the two declarations
            // was no help at all (Nils 2026-07-22) - the call sites are the part that cannot be found by eye.
            Send PushRenameUnprovenToManualGrid
            Get pasRenameUnproven of ghoFuncLib to asUnproven
            Move ((HelpParagraph((BoldText("Nothing was renamed automatically.")) + " " + sPlain + " is not declared inside a class, and this converter renames class methods - it walks the class family and works out which objects a call targets. A global function has neither."))) to sBody
            Move (sBody + (HelpParagraph("Every place it is declared or used is now on the " + (BoldText("Manual Changes")) + " tab - " + String(SizeOfArray(asUnproven)) + " row(s) - so the rename can be worked through by hand. Double-click a row to open the editor there."))) to sBody
            Get FTHtmlMessage ("Rename " + sPlain) sBody "OK" "" to bDummy
            If (SizeOfArray(asUnproven) > 0 and ghoOutputDock <> 0) ;
                Send ShowTab of ghoOutputDock eTabManual
            Procedure_Return
        End
        Send PushRenameUnprovenToManualGrid
        Get pasRenameUnproven of ghoFuncLib to asUnproven
        Move ((HelpParagraph((BoldHtml("Renamed " + sPlain + " to " + sNew + " on " + String(iRenamed) + " line(s)."))))) to sBody
        If (SizeOfArray(asUnproven) > 0) ;
            Move (sBody + (HelpParagraph(String(SizeOfArray(asUnproven)) + " call site(s) were left alone because their receiver could not be typed from the source. They are on the " + (BoldText("Manual Changes")) + " tab - check each and rename it by hand if it targets one of the renamed classes."))) to sBody
        Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it.")))) to sBody
        Get FTHtmlMessage ("Rename " + sPlain) sBody "OK" "" to bDummy
        /* A RENAME THAT WROTE SOURCE INVALIDATES THE BOARD - the same close every other write-run has
           (Nils 2026-09-03, after VALUE: "The dashboard grid did not empty after the dialog was
           closed"). RefreshFindings re-rendered the previous Check's rows over source that no longer
           matched them; only a run that changed nothing may leave the list standing. */
        If (iRenamed > 0) ;
            Send ShowStaleFindingsNote
        Else ;
            Send RefreshFindings
    End_Procedure

    /* THE FIX, offered before the workaround. Asked only after the report has been read, so every number
       in the question is real: how many declarations cause it, how many errors they cause, and whether
       any of them live in a library this workspace shares with others.

       The proposed name is spelled out in the question rather than invented silently - "<name>ByKey" is
       a suggestion for the accessor shape these collisions take, not a rule. Declining leaves the
       call-rewrite offer to follow, and anyone who wants a different name can run
       ChangeCollidingMethodName from the picker with its own Old=New parameter.

       Returns True when the rename actually ran, so the caller does not then also offer the workaround
       for something that is already fixed. */
    Function OfferDeclarationRename String sName Returns Boolean
        String[] asDecls asNoFiles
        String sBody sRow sNew sParam sPlain sDeclClass
        Integer iDecls iCalls iShared iRenamed iDfDecls
        Boolean bRan bScanFailed bBackport bNoSeeds

        Move (Trim(sName)) to sPlain
        If (sPlain = "") ;
            Function_Return False
        Get pasReturnMismatchDecls of ghoFuncLib to asDecls
        Move (SizeOfArray(asDecls)) to iDecls
        // Nothing of ours declares it -> nothing to rename; the workaround is the only route left.
        If (iDecls = 0) ;
            Function_Return False
        // A RENAME ONLY HELPS WHEN SOMETHING OUTSIDE THE WORKSPACE HOLDS THE NAME. If the disagreement is
        // purely among our own declarations, renaming all of them carries that same disagreement to the
        // new name and clears nothing - it would have proposed pbSilent -> pbSilentByKey across three
        // packages that would then still have disagreed, Boolean/String/Boolean (Nils 2026-07-22).
        // That case belongs to OfferDeclarationAlign, which the caller tries next.
        // Either DataFlex's packages declare it, OR the compiler says the name is already taken and the
        // packages cannot show by whom - which means the runtime. Both are rename cases; only a purely
        // internal disagreement is an align case.
        Get piMismatchDfDecls of ghoFuncLib to iDfDecls
        Get NameHasBackportError sPlain to bBackport
        If (iDfDecls = 0 and bBackport = False) ;
            Function_Return False
        // An unread catalogue cannot support either offer - see OfferDeclarationAlign for the reasoning.
        Get pbInstallScanFailed of ghoFuncLib to bScanFailed
        If (bScanFailed = True) ;
            Function_Return False
        // How many errors those declarations cause - the other half of the trade.
        Get AmbiguousCallCountForName sPlain to iCalls
        Get _SharedDeclCount (&asDecls) iDecls to iShared
        // NO ONE-CLICK RENAME FOR A GLOBAL. This converter walks class families; a name declared outside
        // any class is out of its reach, and offering it anyway produced "Rename SPLIT to SPLITByKey?"
        // followed by "Nothing was renamed" (Nils 2026-07-22). Offer the hand worklist instead.
        Get psMismatchDeclClass of ghoFuncLib to sDeclClass
        If (sDeclClass = "") Begin
            Get OfferHandRenameWorklist sPlain to bRan
            Function_Return bRan
        End
        Get _SuggestedRenameFor sPlain sDeclClass to sNew
        // CONFIRM DIALOG with the INPUT slot (Nils 2026-07-24): the suggested name is pre-filled
        // and editable right here, which retires the old "for a different name, run Change
        // colliding method name with the parameter X=YourName" workaround paragraph entirely.
        Get _RenameConfirmHtml sPlain iDecls iCalls iShared to sBody
        Move sNew to sRow
        Get FTInputBox ("Rename " + sPlain) sBody "Rename to:" (&sRow) "Rename now" "Not now" to bRan
        If (bRan = False) ;
            Function_Return False
        Move (Trim(sRow)) to sRow
        If (sRow <> "" and Lowercase(sRow) <> Lowercase(sPlain)) ;
            Move sRow to sNew
        Move (sPlain + "=" + sNew) to sParam
        // Whole-workspace scope: the class family and the objects it is called on are spread across
        // files, so an empty file list (folder scope) is the CORRECT scope here, not a shortcut.
        Get CompiledScopeFiles to asNoFiles      // the compiled files, else the folder scope
        Get RunScopedFunction "ChangeCollidingMethodName" True "" sParam asNoFiles to bRan
        If (bRan = False) ;
            Function_Return False
        Get piRenamedCalls of ghoFuncLib to iRenamed
        Get pbRenameNoClassSeeds of ghoFuncLib to bNoSeeds
        Send _RenameShowOutcome sPlain sNew iRenamed bNoSeeds
        Function_Return True
    End_Function

    // The choice the row deliberately does NOT make. Both routes really do fix a 4544: rename the few
    // declarations, or rewrite every call site into a Get statement whose destination supplies the type.
    // Which is right depends on two numbers - how many declarations, how many calls - and on whether the
    // declarations are yours to touch at all. None of that is known until the report has run, which is why
    // this is asked here, once, with both counts in the question, instead of as a second button on the row.
    /* DO THE COMPILER'S 4544 LINES FOR THIS NAME CARRY THE NAME AT ALL? (2026-08-16.) On WinServ
       every one of pbSilent's 151 sites is "SaveRecordIfValid RV" - a MACRO invocation; the
       ambiguous call "(pbSilent(ghoKeyFieldValidation))" sits in the macro's body
       (KeyFieldValidation.pkg). A call rewrite on the invocation lines cannot reach it - it ran
       and changed 0 lines, and the row was still there after the next Check ("that makes no
       sense", and it did not). Sample up to 25 of the compiler's lines for the name (the grid's
       scoped messages, files read once each, code-only text, whole-word): returns how many carry
       it, and hands back the first line seen (with its file) so the offer can NAME the macro. */
    Function _AmbiguousSitesCarryingName String sName String ByRef sExample Returns Integer
        tCompileError[] aMsgs
        String[] asLines
        String sFile sLastFile sCode sSeen
        Integer i iMax iSampled iOn iLine
        Handle hoGrid hoAn

        Move "" to sExample
        If (ghoModAnalyzerDock = 0) ;
            Function_Return 0
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get paScopedMessages of hoGrid to aMsgs
        Get Create (RefClass(cModAnalyzer)) to hoAn
        Move (SizeOfArray(aMsgs) - 1) to iMax
        Move 0 to iSampled
        Move 0 to iOn
        For i from 0 to iMax
            If (iSampled < 25 and aMsgs[i].iErrorNo = 4544) Begin
                Get AmbiguousFnNameFromText of hoAn aMsgs[i].sText to sSeen
                If (Lowercase(Trim(sSeen)) = Lowercase(Trim(sName)) and aMsgs[i].sFileName <> "" and aMsgs[i].iLine > 0) Begin
                    Move aMsgs[i].sFileName to sFile
                    If (Lowercase(sFile) <> sLastFile) Begin
                        Move (rfReadEncodedFileAsStringArray(sFile)) to asLines
                        Move (Lowercase(sFile)) to sLastFile
                    End
                    Move aMsgs[i].iLine to iLine
                    If (iLine >= 1 and iLine <= SizeOfArray(asLines)) Begin
                        Increment iSampled
                        Get _CodeOnlyLine of ghoFuncLib asLines[iLine - 1] to sCode
                        If (_FindKeywordPos(ghoFuncLib, sCode, sName, True, 1) > 0) ;
                            Increment iOn
                        If (sExample = "") ;
                            Move (Trim(asLines[iLine - 1]) + "  (" + sFile + " line " + String(iLine) + ")") to sExample
                    End
                End
            End
        Loop
        Send Destroy of hoAn
        If (iSampled = 0) ;
            Function_Return -1        // nothing to sample - do not conclude
        Function_Return iOn
    End_Function

    /* THE NAME'S SITES, BY OWNER (2026-09-20): True when the compiler reported this name only in
       files this workspace cannot write - DataFlex's own packages, a package checkout - and hands
       back the leaf of the first such file. "" = every name. False with no analyzer dock, and False
       for a name with no reported site at all: no evidence is no verdict. */
    Function AmbiguousSitesAllForeign String sName String ByRef sLeaf Returns Boolean
        String[]  asNames asForeign
        Integer[] aiOwn aiCounts
        Integer i iLast iSites iOwn
        Handle hoGrid

        Move "" to sLeaf
        If (ghoModAnalyzerDock = 0) ;
            Function_Return False
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasAmbiguousFnNames     of hoGrid to asNames
        Get paiAmbiguousCounts      of hoGrid to aiCounts
        Get paiAmbiguousOwnSites    of hoGrid to aiOwn
        Get pasAmbiguousForeignFile of hoGrid to asForeign
        Move 0 to iSites
        Move 0 to iOwn
        Move (SizeOfArray(asNames) - 1) to iLast
        For i from 0 to iLast
            If (sName = "" or Lowercase(Trim(asNames[i])) = Lowercase(Trim(sName))) Begin
                Move (iSites + aiCounts[i]) to iSites
                If (i < SizeOfArray(aiOwn)) ;
                    Move (iOwn + aiOwn[i]) to iOwn
                If (sLeaf = "" and i < SizeOfArray(asForeign)) ;
                    Move asForeign[i] to sLeaf
            End
        Loop
        Function_Return (iSites > 0 and iOwn = 0 and sLeaf <> "")
    End_Function

    // The build's FIRST compiler error as one paragraph, or "" - the lead when a DataFlex package is
    // the one erroring: its cause is upstream of it in the listing, and this is the listing's top.
    Function _BuildFirstErrorHtml Returns String
        tCompileError[] aMsgs
        Integer i iMax
        Handle hoGrid
        String sLeaf

        If (ghoModAnalyzerDock = 0) ;
            Function_Return ""
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get paScopedMessages of hoGrid to aMsgs
        Move (SizeOfArray(aMsgs) - 1) to iMax
        For i from 0 to iMax
            If (aMsgs[i].bError = True and aMsgs[i].bDeepScan = False) Begin
                Move (ExtractFileName(aMsgs[i].sFileName)) to sLeaf
                Function_Return (HelpParagraph((BoldText("The build's first error:")) + " E " + String(aMsgs[i].iErrorNo) + " " + (HtmlEscaped(Self, Trim(aMsgs[i].sErrorTxt))) + (If((sLeaf <> ""), (" - " + sLeaf + " line " + String(aMsgs[i].iLine)), "")) + "."))
            End
        Loop
        Function_Return ""
    End_Function

    /* THE OFFER THAT IS NOT MADE (2026-09-20). Every call the compiler reports for this name sits
       in a file this tool never writes - DataFlex's own packages, or a write-protected checkout -
       so the call rewrite has nowhere to go; offering it ended at "Nothing to change: none of the
       3 file(s) the compiler named can be written" behind a live Rewrite button. Said up front,
       with the one fact that matters: a DataFlex package that no longer compiles against its own
       declarations is failing because of something EARLIER in this build (in the case seen, the
       program's first error was a package DataFlex 26 does not ship), so the lead is the build's
       first error, not this name. iDecls > 0: the harvest found declarations of the name here,
       which the rename / align offers already handled; 0: nothing here declares it; below 0: no
       harvest has run, so nothing is claimed about declarations. */
    Function _ForeignSitesOnlyHtml String sName Integer iCalls String sLeaf Integer iDecls Returns String
        String sBody sFirst

        Move ((HelpParagraph((BoldHtml("Nothing to rewrite for " + sName + ".")) + " Every one of the " + String(iCalls) + " reported call(s) is inside DataFlex's own packages - the first in " + (BoldHtml(sLeaf)) + " - and those files are never edited here."))) to sBody
        If (iDecls > 0) Begin
            Move (sBody + (HelpParagraph("The " + String(iDecls) + " declaration(s) of the name in this workspace are what disagrees with DataFlex's; they are listed on the " + (BoldText("Manual Changes")) + " tab, and renaming them is the fix."))) to sBody
        End
        Else If (iDecls = 0) Begin
            Move (sBody + (HelpParagraph("Nothing in the compiled scope declares the name either. A DataFlex package that no longer compiles against its own declarations is failing because of something " + (BoldText("earlier")) + " in this build - a package or type it expects that never loaded - and this error goes away with that cause, not with this name."))) to sBody
        End
        Else Begin
            Move (sBody + (HelpParagraph("Whether this workspace declares the name is what the name row's " + (BoldText("Fix it" + CS_Ellipsis)) + " finds out; when nothing here does, the error is a symptom of something " + (BoldText("earlier")) + " in this build."))) to sBody
        End
        Get _BuildFirstErrorHtml to sFirst
        Move (sBody + sFirst) to sBody
        Function_Return sBody
    End_Function

    Procedure OfferCallRewrite String sName
        String[] asDecls asNames
        String sBody sExample sMacro sOnly sLeaf
        Integer iCalls iAllCalls iNames iDecls iOnLine
        Boolean bNothing bRan bDummy bForeign

        Get pbConvertFoundNothing to bNothing
        If (bNothing = True) ;
            Procedure_Return
        If (ghoModAnalyzerDock = 0) ;
            Procedure_Return
        Get pasReturnMismatchDecls of ghoFuncLib to asDecls
        Move (SizeOfArray(asDecls)) to iDecls
        // How many errors the compiler reported for THIS name - the size of the other side of the trade.
        // AND for every ambiguous name, because that is what the button below actually runs: RunHoistAmbiguous
        // passes the WHOLE pasAmbiguousFnNames / pasAmbiguousFiles set to the converter, never one row's name.
        // Saying "Rewriting the 1 call(s)" and then converting 13 across 4 names is the dialog under-stating
        // its own button by an order of magnitude (Nils 2026-08-19).
        Get pasAmbiguousFnNames of (oModAnalyzer_grd(ghoModAnalyzerDock)) to asNames
        Move (SizeOfArray(asNames)) to iNames
        Get AmbiguousCallCountForName sName to iCalls
        Get AmbiguousCallCountForName ""    to iAllCalls
        If (iCalls = 0) ;
            Procedure_Return
        // NOT OFFERED when no reported site is this workspace's to write - see _ForeignSitesOnlyHtml.
        Get AmbiguousSitesAllForeign sName (&sLeaf) to bForeign
        If (bForeign = True) Begin
            Get _ForeignSitesOnlyHtml sName iCalls sLeaf iDecls to sBody
            Get FTHtmlMessage ("Rewrite ambiguous calls - " + sName) sBody "OK" "" to bDummy
            Procedure_Return
        End
        // NOT OFFERED when the sites do not carry the name - see _AmbiguousSitesCarryingName. Say what
        // they are instead, and where the fix is: the declarations (align / rename), which the report's
        // own offers before this one already handle when the compiled set shows them all.
        Get _AmbiguousSitesCarryingName sName (&sExample) to iOnLine
        If (iOnLine = 0) Begin
            Move sExample to sMacro
            If (Pos(" ", sMacro) > 0) ;
                Move (Left(sMacro, (Pos(" ", sMacro) - 1))) to sMacro
            Move ((HelpParagraph((BoldHtml("The " + String(iCalls) + " call(s) of " + sName + " cannot be rewritten from where the compiler reports them."))))) to sBody
            Move (sBody + (HelpParagraph("Every reported line is an invocation of a macro command - the first is <pre>" + sExample + "</pre> - and the ambiguous call itself sits inside that macro's body (" + (BoldHtml(sMacro)) + "). Rewriting the invocation lines changes nothing, so it is not offered."))) to sBody
            Move (sBody + (HelpParagraph("The fix is at the " + (BoldText("declarations")) + " of " + sName + ": make them agree on one return type (the align offer) or rename the name - either clears all " + String(iCalls) + " at once. Or edit the macro body by hand."))) to sBody
            Get FTHtmlMessage ("Rewrite ambiguous calls - " + sName) sBody "OK" "" to bDummy
            Procedure_Return
        End
        // ONE question, not two (Nils 2026-07-24: answering "Rewrite the call sites?" popped the
        // engine's own confirm right after). The context paragraphs ride into RunHoistAmbiguous's
        // single merged dialog via the one-shot intro property; the question is asked THERE, once.
        If (iDecls > 0) Begin
            Move (CS_ParaOpen + (BoldHtml(String(iDecls) + " declaration(s)")) + " in this workspace cause all " + (BoldHtml(String(iCalls))) + " of these errors. They are now listed on the " + (BoldText("Manual Changes")) + (" tab." + CS_ParaEnd)) to sBody
            Move (sBody + (HelpParagraph("Making those " + String(iDecls) + " agree on one return type - or renaming them, where DataFlex owns the name - fixes every call at once and is much the smaller change; that offer came first and is one Fix it... away again. The alternative is to leave them alone and rewrite the call(s) into Get statements - many more edits, but it touches no library code."))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing here can be renamed:")) + " DataFlex owns this name - from the runtime, a class method, or an External_Function - and its type cannot change."))) to sBody
            Move (sBody + (HelpParagraph("Rewriting the call(s) into Get statements is the only fix that can work."))) to sBody
        End
        // WHAT THE BUTTON ACTUALLY COVERS. One row opened this, but the run takes every ambiguous name the
        // compiler reported - they are one problem with one rewrite. Said here rather than left for the user
        // to discover in the summary. The count is the COMPILER's; what was really converted is reported
        // afterwards (two-line calls and Find/Constrain arguments are declined).
        // A per-name Fix it... narrows the run to its name (psHoistOnlyName); the report path keeps the set.
        Get psHoistOnlyName to sOnly
        If (iNames > 1 and Trim(sOnly) = "") Begin
            Move (sBody + ((CS_ParaOpen + "This covers ") + (BoldText("every")) + " ambiguous name the compiler reported, not just ") + sName ;
                        + " - " + (BoldHtml(String(iNames))) + " names, " + (BoldHtml(String(iAllCalls))) + (" reported call site(s) between them." + CS_ParaEnd)) to sBody
        End
        Else If (iNames > 1) Begin
            Move (sBody + (HelpParagraph("This covers " + (BoldText(sName)) + " only - " + (BoldHtml(String(iCalls))) + " reported call site(s). The other " + String(iNames - 1) + " name(s) have their own Fix it..."))) to sBody
        End
        Else ;
            Move (sBody + (HelpParagraph("The compiler reported " + (BoldHtml(String(iCalls))) + " call site(s)."))) to sBody
        Set psHoistIntroHtml to sBody
        Send RunHoistAmbiguous
    End_Procedure

    /* THE FILES THE COMPILER READ - the scope for every compiler-message action (2026-08-16).
       Nils pressed "Check declarations" on PBSILENT (151): the report ran over his SELECTED folders -
       E:\WebAppSrc root, not its AppSrc - saw one of the name's three declarations, called it "rename
       yours" when it is the align case (Boolean / String / Boolean across three of his own packages),
       and its 151 errors stayed. The compiler had read all three; the listing says so on every
       "Including file:" line. Every action a compiler message starts - the report, the rename and
       align offers - now runs over THAT set through RunScopedFunction's file-precise branch (which
       drops the DataFlex install and anything gone from disk). Empty when no listing is at hand -
       the callers then fall back to the folder scope, as before. */
    /* THE STAMP ALONE - which is all a memo's FRESHNESS CHECK ever wants (the three memo-checkers
       in this file; _BuildUseSiteIndex fetches the array once, for its single pass), and asking
       CompiledScopeFiles for it cost 131 SECONDS on WinServ (Nils 2026-08-31: "in all it took
       131s to build the list").

       _ShadowNoteForFile runs ONCE PER FINDING ROW and opened with
       "Get CompiledScopeFiles to asAll // refreshes psScopeStamp" - then immediately overwrote
       asAll with WorkspaceSourceFiles. The array was pure waste, and it is 2365 paths on
       WinServ: a property Get plus the return plus the assignment is several full copies of it,
       per row, 1993 times. DataFlex copies arrays element by element (the same cost that capped
       the .prn pipeline at ~10 MB/s), so the render spent its time copying a list it threw away.
       The memo below it was correct and never got the chance to help - the waste was in the
       line that CHECKED whether the memo was current.

       Same resolution chain and same stamp as CompiledScopeFiles, which now calls this, so the
       two cannot disagree about which listing is current. Cost is three file-system calls. */
    Function CompiledScopeStamp Returns String
        String sPrn sErr sStamp
        Handle hoPanel
        Boolean bExists

        /* The listing the ANALYZER parsed comes first: ghoModAnalyzerDock.psErrorFile is set by
           ActivateModAnalyzer on every path, including the guided Check that runs the Test Compile
           panel HIDDEN - where phoTestCompileFT (published only when the dock is shown) is 0. That
           0 is why the first cut still ran the pbSilent report over the folder scope (Nils, 21:38).
           The panel's own paths are the fallback for a dock-driven session. */
        Move "" to sPrn
        If (ghoModAnalyzerDock <> 0) Begin
            Get psErrorFile of ghoModAnalyzerDock to sErr
            If (sErr <> "") ;
                Move (Left(sErr, (Length(sErr) - 4)) + ".prn") to sPrn
        End
        If (sPrn = "") Begin
            Get phoTestCompileFT of ghoApplication to hoPanel
            If (hoPanel <> 0) Begin
                Get psPrnFilePath of hoPanel to sPrn
                If (sPrn = "") Begin
                    Get psErrFilePath of hoPanel to sPrn
                    If (sPrn <> "") ;
                        Move (Left(sPrn, (Length(sPrn) - 4)) + ".prn") to sPrn
                End
            End
        End
        /* THE RESTORED PLAN'S OWN .prn - the only source in a session where no Check has run
           (2026-08-19). Both routes above are set by a Check: psErrorFile by ActivateModAnalyzer, the
           panel paths by a dock-driven compile. Reopen a workspace on a saved plan and neither
           exists, so this returned "" - and callers that ask the compiled source for EVIDENCE got an
           empty list and quietly reached the opposite conclusion. It put 495 of Nils's 533
           DataFlex-owned findings back into Needs hand migration, because the classes that are
           silenced by a PARENT lookup lost the source to look the parent up in, while the 38 matched
           by name alone stayed silent. Last in the chain: a live Check still wins, and this only
           speaks when nothing else can. */
        If (sPrn = "" and ghoModAnalyzerDock <> 0) ;
            Get psPlanSourcePrn of ghoModAnalyzerDock to sPrn
        If (sPrn = "") ;
            Function_Return ""
        Get vFilePathExists sPrn to bExists
        If (bExists = False) ;
            Function_Return ""
        /* CACHED ON THE .prn'S IDENTITY. Eight callers reach this, and it was re-parsing a 53.6 MB
           listing for each of them. Size + write time means a recompile rebuilds it and nothing else
           does. */
        Move (sPrn + "|" + String(rfFileSizeLive(sPrn)) + "|" + String(rfFileDate(sPrn))) to sStamp
        Function_Return sStamp
    End_Function

    Function CompiledScopeFiles Returns String[]
        String[] asNone asFiles
        String sPrn sStamp
        tScopeIndexFile Cached

        // Resolution chain + stamp: CompiledScopeStamp above (one source, so a caller that only
        // needs the stamp never pays for the array).
        Get CompiledScopeStamp to sStamp
        If (sStamp = "") ;
            Function_Return asNone
        Move (Left(sStamp, (Pos("|", sStamp) - 1))) to sPrn
        If (sStamp = (psScopeStamp(Self))) ;
            Function_Return (pasScopeFiles(Self))
        /* COLD PROCESS: try the DISK cache before re-deriving anything. The properties above
           die with the process, which is why every session paid 11.2s to rebuild two things
           that only change when the program is recompiled. A stamp match here restores BOTH
           the scope list and the definition index, so EnsureDefinitionIndex below finds its
           work already done. */
        Get ReadScopeIndex of ghoApplication to Cached
        If (Trim(Cached.sStamp) = sStamp) Begin
            Set pasScopeFiles to Cached.asScopeFiles
            Set pasIdxKey     to Cached.asIdxKey
            Set pasIdxParent  to Cached.asIdxParent
            Set pasIdxSite    to Cached.asIdxSite
            Set psScopeStamp  to sStamp
            Set psIdxStamp    to sStamp
            Function_Return (Cached.asScopeFiles)
        End
        Get rfPrnIncludedFiles sPrn to asFiles
        Set pasScopeFiles to asFiles
        Set psScopeStamp  to sStamp
        // The definition index is built from this same set, so it is invalidated with it.
        Set psIdxStamp to ""
        Function_Return asFiles
    End_Function

    /* ONE PASS over the compiled scope, collecting every class and macro definition it holds. Built
       on demand and cached against the scope stamp, so a findings render pays for it once per
       compile rather than once per cause.

       The inner test is a cheap Left() before any word splitting: this walks roughly 1.5 million
       lines on Nils's workspace, and _NthWord on every one of them was most of the cost. Only lines
       that actually open "class " or "#command " get split. */
    Procedure EnsureDefinitionIndex String[] ByRef asScope
        String[] asKey asParent asSite asLines
        String sStamp sLow sW2 sW5 sCmd
        tScopeIndexFile ToSave
        Integer i iMax j jMax iN

        Get psScopeStamp to sStamp
        If (sStamp = "" or sStamp = (psIdxStamp(Self))) ;
            Procedure_Return
        Move (Character(35) + "command ") to sCmd
        Move (SizeOfArray(asScope) - 1) to iMax
        For i from 0 to iMax
            Move (rfReadEncodedFileAsStringArray(asScope[i])) to asLines
            Move (SizeOfArray(asLines) - 1) to jMax
            For j from 0 to jMax
                /* MEASURED, AND IT MADE NO DIFFERENCE (2026-08-20). A one-character gate was
                   tried here on the theory that Lowercase(Trim(...)) over 733,386 lines was the
                   7.5s cost. It moved the number by nothing: the time is in READING 1035 files
                   into String[] arrays, not in testing the lines once they are there. The fix
                   is not to test them faster, it is to not rebuild this every session - see the
                   disk cache in the property block. Left plain on purpose. */
                Move (Lowercase(Trim(asLines[j]))) to sLow
                If (Left(sLow, 6) = "class ") Begin
                    Get _NthWord of ghoFuncLib sLow 2 to sW2
                    Get _NthWord of ghoFuncLib sLow 5 to sW5      // "class x is a|an y"
                    If (sW2 <> "" and (SearchArray(("c|" + sW2), asKey)) = -1) Begin
                        Move (SizeOfArray(asKey)) to iN
                        Move ("c|" + sW2)                          to asKey[iN]
                        Move sW5                                   to asParent[iN]
                        Move (asScope[i] + "|" + String(j + 1))    to asSite[iN]
                    End
                End
                Else If (Left(sLow, 9) = sCmd) Begin
                    Get _NthWord of ghoFuncLib sLow 2 to sW2
                    If (sW2 <> "" and (SearchArray(("m|" + sW2), asKey)) = -1) Begin
                        Move (SizeOfArray(asKey)) to iN
                        Move ("m|" + sW2)                          to asKey[iN]
                        Move ""                                    to asParent[iN]
                        Move (asScope[i] + "|" + String(j + 1))    to asSite[iN]
                    End
                End
            Loop
        Loop
        Set pasIdxKey    to asKey
        Set pasIdxParent to asParent
        Set pasIdxSite   to asSite
        Set psIdxStamp   to sStamp
        /* Persist it, so the NEXT session loads in milliseconds instead of rebuilding. Written
           once per compile - the stamp only moves when the .prn does. */
        Move sStamp   to ToSave.sStamp
        Move asScope  to ToSave.asScopeFiles
        Move asKey    to ToSave.asIdxKey
        Move asParent to ToSave.asIdxParent
        Move asSite   to ToSave.asIdxSite
        Send WriteScopeIndex of ghoApplication ToSave
    End_Procedure

    /* The E 4345 class row's "Rename the class..." (2026-09-03) - confirm with the new name in the
       input slot (default <Class>X), RenameCollidingClass over the compiled scope, the count back.
       Mirrors _HandRenameNow for globals; no worklist rung - a class has no of-form ambiguity. */
    Procedure RunRenameClassOffer
        String[] asNoFiles
        String sClass sNew sBody sPkg sOwner
        Integer iRenamed
        Boolean bRan bDummy

        Get psPendingDeclName to sClass
        Move (Trim(sClass)) to sClass
        If (sClass = "") ;
            Procedure_Return
        Get InstallClassPkgFor of ghoFuncLib sClass to sPkg
        If (sPkg <> "") ;
            Move (" (" + sPkg + ")") to sOwner
        Else ;
            Move " in its runtime" to sOwner
        Move ((HelpParagraph((BoldHtml(sClass + " has to be renamed")) + " - the newer DataFlex defines a class of that name" + sOwner + ", and a second definition is error 4345."))) to sBody
        Move (sBody + (HelpParagraph("The rename is mechanical: the Class line, every " + (BoldText("is a " + sClass)) + " (objects and subclasses), every " + (BoldText("RefClass(" + sClass + ")")) + " and every " + (BoldText("for " + sClass)) + " augmentation take the new name. Nothing else that spells the word is touched - a variable or a file name of the same spelling stays."))) to sBody
        Move (sBody + (HelpParagraph("It runs over the whole compiled scope, so every reference unifies in one pass. If you would rather drop the workspace's class and use DataFlex's own, do that by hand instead."))) to sBody
        Move (sClass + "X") to sNew
        Get FTInputBox ("Rename " + sClass) sBody "Rename to:" (&sNew) "Rename now" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Move (Trim(sNew)) to sNew
        If (sNew = "" or Lowercase(sNew) = Lowercase(sClass)) ;
            Move (sClass + "X") to sNew
        Get CompiledScopeFiles to asNoFiles      // the compiled files, else the folder scope
        Get RunScopedFunction "RenameCollidingClass" True "" (sClass + "|" + sNew) asNoFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piRenamedClassCount of ghoFuncLib to iRenamed
        If (iRenamed > 0) Begin
            Move ((HelpParagraph((BoldHtml("Renamed " + String(iRenamed) + " reference(s)")) + " - " + sClass + " is now " + sNew + " at its Class line and at every is-a, RefClass and for-reference in the scope."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it.")))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was renamed")) + " - no Class line or reference of " + sClass + " was found in the scope."))) to sBody
            Move (sBody + ((HelpParagraph("Widen the scope, or open the declaration from its row and rename by hand.")))) to sBody
        End
        Get FTHtmlMessage ("Rename " + sClass) sBody "OK" "" to bDummy
        If (iRenamed = 0) ;
            Procedure_Return
        Send ShowStaleFindingsNote
    End_Procedure

    // The E 4390 row's "Rename it..." - straight to the whole-scope rename offer, no report first.
    Procedure RunRenameGlobalOffer
        String sName
        Boolean bRan
        Get psPendingDeclName to sName
        Move (Trim(sName)) to sName
        If (sName = "") ;
            Procedure_Return
        Get OfferHandRenameWorklist sName to bRan
    End_Procedure

    /* The E 4546 sub-row's "Rename the calls..." - psPendingDeclName carries "old|new". The same
       converter as the 4390 rename (RenameCollidingGlobalFunction), same confirm-with-input, same
       summary; here the declaration is usually already on the new name and simply does not match,
       so what moves is the calls. */
    Procedure RunRenameCallsOffer
        String sPair sOld sNew sBody sTyped
        String[] asFiles
        Integer iPos iRenamed
        Boolean bRan bDummy

        Get psPendingDeclName to sPair
        Move (Pos("|", sPair)) to iPos
        If (iPos < 2) ;
            Procedure_Return
        Move (Trim(Left(sPair, (iPos - 1)))) to sOld
        Move (Trim(Mid(sPair, (Length(sPair)), (iPos + 1)))) to sNew
        If (sNew = "") ;
            Move (sOld + "X") to sNew
        Move ((HelpParagraph((BoldHtml("Calls of " + sOld + " still use the old name")) + " - and that name now binds to a DataFlex procedure, which is what E 4546 says."))) to sBody
        Move (sBody + (HelpParagraph("Every of-less call of " + sOld + " in the selected scope is renamed to the name below (its declaration, already renamed, is left as it is); Get/Send ... " + (BoldText("of")) + " &lt;object&gt; forms are never touched."))) to sBody
        Move sNew to sTyped
        Get FTInputBox ("Rename the calls of " + sOld) sBody "Rename to:" (&sTyped) "Rename now" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Move (Trim(sTyped)) to sTyped
        If (sTyped <> "" and Lowercase(sTyped) <> Lowercase(sOld)) ;
            Move sTyped to sNew
        /* FILE-PRECISE, over the files the compiler named in its 4546s - not the selected-folder
           scope. Nils's first press renamed nothing: the calls sit in E:\WebAppSrc, a library the
           compiler builds but that is not among his selected folders, so the whole-scope run never
           opened the file (2026-08-16). The compiler pinpointed exactly which files bind the old
           name; RunScopedFunction's file-precise branch exists for that (the Guard-them fix, and its
           own note: a fix the compiler pinpointed is not gated by the selection - only the DataFlex
           install is off limits). The converter's own text gate skips a named file that does not
           carry this name. An empty list (no analyzer dock) falls back to the scope run. */
        Get FilesCarryingMessage "4546" to asFiles
        Get RunScopedFunction "RenameCollidingGlobalFunction" True "" (sOld + "|" + sNew) asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piRenamedGlobalCount of ghoFuncLib to iRenamed
        If (iRenamed > 0) Begin
            Move ((HelpParagraph((BoldHtml("Renamed " + String(iRenamed) + " line(s)")) + " - the calls now read " + sNew + "."))) to sBody
            Move (sBody + ((HelpParagraph("Run " + (BoldText("Check")) + " again to see what the compiler makes of it; a call the rename could not prove stays on the old name and will still be flagged.")))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was renamed")) + " - no of-less call of " + sOld + " was found in the file(s) the compiler named."))) to sBody
        End
        Get FTHtmlMessage ("Rename the calls of " + sOld) sBody "OK" "" to bDummy
        If (iRenamed = 0) ;
            Procedure_Return
        Send ShowStaleFindingsNote
    End_Procedure

    /* The E 4379 sub-row's "Rewrite as Get..." - psPendingDeclName carries the method name read off the
       line. Same shape as RunRenameCallsOffer above: file-precise over the files the compiler named in
       ITS 4379s (the calls sit in libraries the compiler builds but the folder ticks may not include),
       the name handed to the converter as its parameter so a method declared in another file is
       authorized, and the summary says what was left for hand work.

       ChangeObjectFunctionCallToGet converts the clean "Move (Name(Self[, simple args])) to dest" shape
       and marks anything else with a //TODO, which is why the closing box names both numbers. */
    Procedure RunObjCallToGetOffer
        String[] asFiles
        String sName sBody
        Integer iConverted
        Boolean bRan bDummy

        Get psPendingDeclName to sName
        Move (Trim(sName)) to sName
        If (sName = "") ;
            Procedure_Return
        /* WORDED FROM WHAT IS KNOWN, not from the case it was written for (Nils 2026-09-04). This
           asserted "DataFlex 26 now owns the name <X>" as fact for every name, with the cRegEx
           parenthetical and the Split example's own sSep / sText / saParts left standing behind a
           substituted name - so on LegacyApp it claimed DataFlex owned fHeadValue, which is his, and
           showed a rewrite of a call that does not exist. The row now keeps this offer away from a
           name this file declares with a different parameter count; what is left is the collision
           case and the one it cannot see, a method declared in ANOTHER file. Hence the warning:
           the count is the thing to check, because a Get does not check it either. */
        Move ((HelpParagraph((BoldHtml(sName + " is called in the object-expression form")) + " - which is legal DataFlex and stays legal. What E 4379 reports is that the argument count does not fit the function this call <i>resolved</i> to. When a newer DataFlex owns the same name, that is its function rather than the workspace's: the runtime declares it in no package, so searching the sources for what the name collided with finds nothing."))) to sBody
        Move (sBody + (HelpParagraph("A Get statement is a message send, so it binds to the workspace's OWN method instead:"))) to sBody
        Move (sBody + "<pre>Was:   Move (" + sName + "(Self, args)) to dest" + Character(10) + Character(10) + "Now:   Get " + sName + " args to dest</pre>") to sBody
        Move (sBody + (HelpParagraph((BoldHtml("Check the declaration first.")) + " A message send does not count arguments: where the call simply passes too many to the workspace's method, this rewrite compiles clean and drops the surplus in silence. The board says so on the row when it can see the declaration - it is in the file being compiled - but a method declared in another file it cannot."))) to sBody
        Move (sBody + (HelpParagraph("No declaration is touched. Only the clean " + (BoldHtml("Move (" + CS_Ellipsis + ") to &lt;dest&gt;")) + " shape is rewritten; a call nested inside a bigger expression gets a //TODO comment for hand work."))) to sBody
        Get FTHtmlMessage ("Rewrite " + sName + " calls as Get") sBody "Rewrite the calls" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Get FilesCarryingMessage "4379" to asFiles
        Set pbStartQuestionAsked of ghoEngine to True
        Get RunScopedFunction "ChangeObjectFunctionCallToGet" True "" sName asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piObjCallsConverted of ghoFuncLib to iConverted
        If (iConverted > 0) Begin
            Move ((HelpParagraph((BoldHtml("Rewrote " + String(iConverted) + " call(s) as Get statements."))))) to sBody
            Move (sBody + ((HelpParagraph("The source has changed, so the error list on the board is from " + (BoldText("before")) + " this run. Run " + (BoldText("Check")) + " to see what is actually left; any call this could not reach carries a //TODO comment on its own line.")))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was rewritten")) + " - no " + (BoldHtml("Move (" + sName + "(Self, " + CS_Ellipsis + ")) to &lt;dest&gt;")) + " line was found in the file(s) the compiler named."))) to sBody
            Move (sBody + (HelpParagraph("The calls are probably nested inside a larger expression, which cannot be hoisted mechanically - open the reported line and rewrite it by hand."))) to sBody
        End
        Get FTHtmlMessage ("Rewrite " + sName + " calls as Get") sBody "OK" "" to bDummy
        If (iConverted = 0) ;
            Procedure_Return
        Send ShowStaleFindingsNote
    End_Procedure

    /* The arity row's "Drop the surplus argument..." (Nils 2026-09-04). psPendingDeclName carries
       "Name|DeclaredCount|Line|File" - everything the row measured - so the dialog shows the REAL
       line and what it becomes, built by the same pure helper the run uses; a templated example is
       a lie with a variable in it. Runs DropSurplusCallArguments over THAT ONE FILE: the count was
       read off this file's own declaration, and a call from another file would carry a handle
       receiver, which is the other row. Same close as the other remedies: the counter, then the
       stale note. */
    Procedure RunDropSurplusOffer
        String[] asFiles asLines asParts
        String sPayload sName sFile sWas sNow sBody sLeaf sPlural
        Integer iKeep iLine iDropped iDone
        Boolean bRan bDummy

        Get psPendingDeclName to sPayload
        // Name|Count|Line|File - the file last, because a path is the one part that could hold anything.
        Move (StrSplitToArray(sPayload, "|")) to asParts
        If (SizeOfArray(asParts) < 4) ;
            Procedure_Return
        Move (Trim(asParts[0])) to sName
        Move asParts[1] to iKeep
        Move asParts[2] to iLine
        Move (Trim(asParts[3])) to sFile
        If (sName = "" or sFile = "" or iLine < 1) ;
            Procedure_Return
        Move (ExtractFileName(sFile)) to sLeaf
        Move (If((iKeep = 1), "", "s")) to sPlural
        Move (rfReadEncodedFileAsStringArray(sFile)) to asLines
        If (iLine > SizeOfArray(asLines)) ;
            Procedure_Return
        Move asLines[iLine - 1] to sWas
        Get _DropSurplusArgsInLine of ghoFuncLib sWas sName iKeep (&iDropped) to sNow
        If (iDropped = 0) Begin
            // The row was built from a line that has since changed - never act on a stale measurement.
            Move ((HelpParagraph((BoldText("Nothing to drop")) + " - line " + String(iLine) + " of " + sLeaf + " no longer passes more than " + String(iKeep) + " argument" + sPlural + " to " + sName + ". The source has changed since this Check; run " + (BoldText("Check")) + " again."))) to sBody
            Get FTHtmlMessage "Drop the surplus argument" sBody "OK" "" to bDummy
            Procedure_Return
        End
        Move ((HelpParagraph((BoldHtml(sName + " declares " + String(iKeep) + " parameter" + sPlural + " and this call passes " + String(iKeep + iDropped) + ".")) + " DataFlex 19.1 and earlier passed the surplus along and the method never read it, so removing it changes nothing at run time - it only stops DataFlex 26 counting it."))) to sBody
        Move (sBody + "<pre>Was:   " + (HtmlEscaped(Self, Trim(sWas))) + Character(10) + Character(10) + "Now:   " + (HtmlEscaped(Self, Trim(sNow))) + "</pre>") to sBody
        Move (sBody + (HelpParagraph("Every " + sName + "(Self, " + CS_Ellipsis + ") call in " + sLeaf + " that passes more than " + String(iKeep) + " on one line is trimmed the same way; the declaration is not touched, and a call whose surplus carries a nested call is left alone."))) to sBody
        Move (sBody + (HelpParagraph((BoldHtml("The other honest fix")) + " is that the declaration was meant to take the extra value. The tool cannot tell which one you meant - if it is that one, choose Not now and add the parameter by hand."))) to sBody
        Get FTHtmlMessage ("Drop the surplus argument" + (If((iDropped = 1), "", "s"))) sBody "Drop it" "Not now" to bRan
        If (bRan = False) ;
            Procedure_Return
        Move sFile to asFiles[0]
        Set pbStartQuestionAsked of ghoEngine to True
        Get RunScopedFunction "DropSurplusCallArguments" True "" (sName + "|" + String(iKeep)) asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get piSurplusArgsDropped of ghoFuncLib to iDone
        If (iDone > 0) Begin
            Move ((HelpParagraph((BoldHtml("Trimmed " + String(iDone) + " call" + (If((iDone = 1), "", "s")) + " of " + sName + " in " + sLeaf + "."))))) to sBody
            Move (sBody + (HelpParagraph("The source has changed, so the error list on the board is from " + (BoldText("before")) + " this run. Run " + (BoldText("Check")) + " to see what is actually left."))) to sBody
        End
        Else Begin
            Move ((HelpParagraph((BoldText("Nothing was changed")) + " - no " + sName + "(Self, " + CS_Ellipsis + ") call in " + sLeaf + " passes more than " + String(iKeep) + " argument" + sPlural + " on a single line."))) to sBody
        End
        Get FTHtmlMessage ("Drop the surplus argument" + (If((iDropped = 1), "", "s"))) sBody "OK" "" to bDummy
        If (iDone = 0) ;
            Procedure_Return
        Send ShowStaleFindingsNote
    End_Procedure

    /* The cause row's "Convert them..." - psPendingDeclName carries the refactor function the 4537
       recipe table named for that class. Runs it over the files the COMPILER read (the same scope every
       other compiler-message action uses), behind RunScopedFunction's own confirm, which names the
       function and lists the folders before anything is written. */
    Procedure RunFnOverCompiledScope
        String[] asFiles
        String sFn sBody
        Boolean bRan

        Get psPendingDeclName to sFn
        Move (Trim(sFn)) to sFn
        If (sFn = "") ;
            Procedure_Return
        Get CompiledScopeFiles to asFiles
        Move ((CS_ParaOpen + "This runs ") + (BoldHtml(sFn)) + (" over the files the compiler read." + CS_ParaEnd) + (HelpParagraph("It converts the objects declared from this class; the class itself is not changed. Anything the converter cannot prove is left alone and reported afterwards."))) to sBody
        Get RunScopedFunction sFn False sBody "" asFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Send ShowStaleFindingsNote
    End_Procedure

    // How many 4390s the compiler raised for this name - the declaration count the board shows.
    Function NameBackportCount String sName Returns Integer
        String[] asBack
        Integer[] aiCounts
        Integer i iLast
        Handle hoGrid

        If (ghoModAnalyzerDock = 0) ;
            Function_Return 0
        Move (oModAnalyzer_grd(ghoModAnalyzerDock)) to hoGrid
        Get pasBackportNames  of hoGrid to asBack
        Get paiBackportCounts of hoGrid to aiCounts
        Move (SizeOfArray(asBack) - 1) to iLast
        For i from 0 to iLast
            If (Lowercase(Trim(asBack[i])) = Lowercase(Trim(sName)) and i < SizeOfArray(aiCounts)) ;
                Function_Return aiCounts[i]
        Loop
        Function_Return 0
    End_Function

    /* The shared core of the two 4544 actions: the harvest run (FunctionReturnMismatchReport, narrowed
       to sOneName when given), the Manual-Changes push, the viewer only when asked for, then the
       offers - the guard for a duplicate External_Function, else rename the declarations, else align
       the odd return type, else rewrite the calls. The offers were always the point; the viewer used
       to stand between the click and them (Nils 2026-09-03). */
    Procedure _RunMismatchAndOffer String sOneName Boolean bShowReport
        String sReport sHome
        String[] asNoFiles
        Boolean bRan bExists bRenamed

        // Over the files the compiler READ, not the folder ticks - see CompiledScopeFiles.
        Get CompiledScopeFiles to asNoFiles
        Get RunScopedFunction "FunctionReturnMismatchReport" True "" sOneName asNoFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        // The report writes into the workspace's backup folder and only appends it to pasOtherLogFiles (and
        // only when it found something), i.e. a list the user would have to know to go hunting in - which is
        // why the report "could be found nowhere" (Nils 2026-07-20). Opened directly in the log viewer when
        // asked for. Shown even when the count is zero: "Total: 0 contested name(s)" is a real, useful answer.
        Send PushMismatchDeclsToManualGrid
        Get psHomeTarget of ghoApplication to sHome
        Move (vFolderFormat(sHome) + CS_BackupFolder + CS_DirSeparator + CS_ReturnMismatchReportLogFile) to sReport
        Get vFilePathExists sReport to bExists
        If (bExists = False) Begin
            Get FTHtmlMessage "Check declarations" (HelpParagraph("The return-type mismatch report could not be created.")) "OK" "" to bRan
            Procedure_Return
        End
        // The log viewer is modal (Send Popup), so we are back here the instant the user closes the report -
        // the first moment they have read what causes this and can actually choose. Ask then, not before.
        If (bShowReport = True) ;
            Send ActivateEngineLogFile of (Client_Id(phoMainPanel(ghoApplication))) sReport
        // THE FIX FIRST: renaming the few declarations clears every call of the name, including the ones
        // no converter can reach. Only if that is declined is the call-site workaround worth offering.
        // A duplicate External_Function (both sides declare the same Windows API) has no rename, align
        // or call-rewrite route - the fix is the version guard, so THAT is what gets offered (Nils
        // 2026-07-23: same directive and same apply-offer as the globals guard).
        If (pbMismatchExternalDup(ghoFuncLib) = True) Begin
            Send OfferExternalGuard
            Procedure_Return
        End
        Get OfferDeclarationRename sOneName to bRenamed
        If (bRenamed = False) Begin
            // Not a rename case -> is it an align case? Only one of the two can apply, and the report has
            // already worked out which by looking at whether DataFlex declares the name at all.
            Get OfferDeclarationAlign sOneName to bRenamed
        End
        If (bRenamed = False) ;
            Send OfferCallRewrite sOneName
    End_Procedure

    // The 4544 lead row's outlined "Show the report" (and the 4390 rows' "Show declarations"): the
    // report in the viewer - narrowed to the row's name when it carries one - then the offers.
    Procedure RunReturnMismatchReport
        String sOneName

        Get psPendingDeclName to sOneName
        Send _RunMismatchAndOffer sOneName True
    End_Procedure

    /* The 4544 name row's filled "Fix it..." (Nils 2026-09-03: "it doesn't seem helpful to check
       something instead of doing something about the problem"). The same harvest the report makes -
       it IS the scan that finds the declarations, a minute or two over the compiled scope - run
       silently and not shown: the offers follow directly. The report stays one click away on the
       lead row. */
    Procedure RunFixDeclarationOffer
        String sOneName

        Get psPendingDeclName to sOneName
        Move (Trim(sOneName)) to sOneName
        If (sOneName = "") ;
            Procedure_Return
        Set psHoistOnlyName to sOneName
        Send _RunMismatchAndOffer sOneName False
        Set psHoistOnlyName to ""
    End_Procedure

    // Broadcast target (Register_Procedure in DFRefactorFT.src): StartAnalyze's tail calls this after a
    // GUIDED compile+analyze. Deferred onto the view's timer - the broadcast arrives on the analyze path, so
    // the web push + view switch run safely on a fresh tick (the err-4410 web-pump lesson).
    /* Come back to the trail and Check, after a run the trail sent the user off to make. Registered
       in DFRefactorFT.src so the manual-run handoff can Send it by handle. Reuses the Check button's
       OWN path (CI_ChkRunCheck) rather than repeating its setup - that block sets four phase stamps
       and two one-shots, and a second copy would drift from it. */
    /* Come back to the trail WITHOUT starting a Check - for a run the trail sent the user on that
       changed nothing, where there is nothing to verify but every reason to return them to the flow
       they were following. Refreshes the tiles so the stepper picks up the Tidy Up latch. */
    Procedure ActivateGuidedTrail
        Send Activate_oDashboard_vw of (Client_Id(ghoCommandBars))
        Send ArmAction of oChkDeferTimer CI_ChkRefresh
    End_Procedure

    Procedure StartGuidedCheckFromRun
        Send Activate_oDashboard_vw of (Client_Id(ghoCommandBars))
        Send ArmAction of oChkDeferTimer CI_ChkRunCheck
    End_Procedure

    Procedure RenderGuidedFindings
        // A real Check supersedes a loaded saved plan: drop the stamp so the header stops saying the
        // board is the previous Check's. (The grid is already back in live mode by this point - the
        // analyze that got us here rebuilt it.)
        Set psLastPlanStamp to ""
        // The verify a changed Tidy Up was owed has now happened - whatever this Check found, it
        // found it in the code as it stands, so the Ready stage may light again on its verdict.
        Send ClearSourceUnverified of ghoApplication
        Send ArmAction of oChkDeferTimer CI_ChkRenderFindings
    End_Procedure

    /* A page click's action, from a box's OnHtmlClick - after the web click has returned, through the library's
       click relay: run now, or queued on oChkDeferTimer while a board render is in flight, which runs it the
       moment the render lets go (its OnTimer's rule). Until 2026-10-07 every click went through the timer's
       one slot, where it could overwrite an action the workspace-load path had just queued. */
    Procedure RunClickAction Integer iAction
        If (pbBoardRendering(Self)) ;
            Send ArmAction of oChkDeferTimer iAction
        Else ;
            Send RunBoardAction iAction
    End_Procedure

    /* ---- The deferred dispatcher (2026-09-02) ----
       oChkDeferTimer.OnTimer used to be one 225-line If-chain with the Check body inlined in the
       middle of it. The chain is a TABLE - one arm per CI_Chk* code - and reads best kept that
       way, so it is split by what the arms DO rather than rewritten: the Check lifecycle, the
       findings-row remedies (which write source or open the report that leads to one), board
       housekeeping, and navigation + the after-run utilities. RunBoardAction tries the families in
       that order and the first that owns the code runs it. All of it executes on the timer's fresh
       tick, off the WebView2 pump - see the DEFERRAL note at the top of this file. */
    Procedure RunBoardAction Integer iAction
        Boolean bDone

        Get _RunCheckAction iAction to bDone
        If (bDone = False) ;
            Get _RunRemedyAction iAction to bDone
        If (bDone = False) ;
            Get _RunHousekeepingAction iAction to bDone
        If (bDone = False) ;
            Send _RunNavigationAction iAction
    End_Procedure

    // The Check lifecycle: the repaints, the Check itself, the render that follows it, the saved-Check restore.
    Function _RunCheckAction Integer iAction Returns Boolean
        Case Begin
            Case (iAction = CI_ChkRefreshLight)
                Send RefreshTilesKeepFindings False
                Case Break
            Case (iAction = CI_ChkRefresh)
                Send BoardBusyOn "Building the findings list..."
                Send RefreshTiles
                Send BoardBusyOff
                Case Break
            Case (iAction = CI_ChkResetScope)
                Send RefreshTiles     // scope set-once/Reset policy lands in the next increment
                Case Break
            Case (iAction = CI_ChkRunCheck)
                Send RunGuidedCheck
                Case Break
            Case (iAction = CI_ChkRenderFindings)
                Send FinishGuidedRender
                Case Break
            Case (iAction = CI_ChkShowLastPlan)
                Send ShowLastCheckOnBoard
                Case Break
            Case (iAction = CI_ChkFinishLastPlan)
                Set piTimeout of oChkDeferTimer to 1            // restore the snappy default
                Send FinishShowLastCheck
                Case Break
            Case Else
                Function_Return False
        Case End
        Function_Return True
    End_Function

    /* "Not now - a Check is in flight", asked once and worded by the caller. Returns True when the
       action must NOT run; the caller returns immediately on True.

       sWouldDo is the caller's own middle paragraph because the reason differs per action and a
       generic one would be useless: a findings row is stale, a Revert rewrites the files being
       compiled. The head and the way out are shared.

       pbGuidedCheckRun is the signal because it already brackets exactly this window, and one flag
       cannot disagree with itself the way two would. Its cancelled-compile clear (see FinishCompile)
       is what keeps a stopped Check from holding actions for ever.

       Read-only actions are deliberately NOT gated: opening the editor at a line, reading a log,
       folding a band. There is no reason to stop someone reading while they wait. */
    Function _HeldByRunningCheck String sWouldDo Returns Boolean
        String sBody
        Boolean bChecking bDummy

        Get pbGuidedCheckRun of ghoApplication to bChecking
        If (bChecking = False) ;
            Function_Return False
        Move (HelpParagraph((BoldText("Check is still running.")))) to sBody
        Move (sBody + (HelpParagraph(sWouldDo))) to sBody
        Move (sBody + (HelpParagraph("Wait for the findings list to appear, then choose again. To stop the Check instead, press " + (BoldText("Stop")) + " in the compile dock and run " + (BoldText("Check")) + " when you are ready."))) to sBody
        Get FTHtmlMessage "Check is running" sBody "OK" "" to bDummy
        Function_Return True
    End_Function

    /* HELD WHILE A CHECK RUNS (Nils 2026-09-16: "while a Check is running, hold the run/remedy
       actions").

       A Check is ~77 s on a large workspace and spans several event-loop turns - the scan half
       pumps the message loop and the compile is asynchronous - while the board still carries the
       PREVIOUS Check's rows. A click landing in that window loaded the saved plan, found its
       provenance broken (this very Check had just rewritten the .prn it was read from) and
       answered "the compile output it was read from has been written since". Accurate, and
       baffling: the user changed nothing, they clicked during a Check, and the message reads like
       the tool losing their plan.

       So the click never reaches the remedy. The findings on screen are already history - the
       board says so in CheckRunningNote - and every action below writes source or opens the report
       that leads to one.

       Read-only actions are deliberately NOT gated: opening the editor at a line, folding a band.
       There is no reason to stop someone reading while they wait.

       pbGuidedCheckRun is the signal because it already brackets exactly this window, and one
       flag cannot disagree with itself the way two would. Its cancelled-compile clear (see
       FinishCompile) is what keeps a stopped Check from holding these for ever. */
    Function _RunRemedyAction Integer iAction Returns Boolean
        Boolean bChecking

        /* A BACKSTOP, not the thing doing the work - and the difference is worth stating so the
           next reader does not credit this line with a protection it is not providing.

           Every code below is emitted by a findings-ROW builder, and those all feed oTile_Findings
           - the tile ShowCheckRunningNote replaces with an inert note BEFORE the Check starts
           anything slow. So the rows are gone for the whole window this tests, and in the earlier
           window where they were still clickable the flag was not yet set. Removing the control
           beats refusing the click, and 1e4f07a4 already does it.

           It stays because it costs one property read and it keeps the invariant true for a row
           that might one day survive the note. The click that actually needed holding was Revert,
           on a tile the note never touches - see the CI_ChkUndo arm. */
        Get _HeldByRunningCheck "The rows on the board came from the previous compile, so acting on them now would work from findings this Check is in the middle of replacing." to bChecking
        If (bChecking = True) ;
            Function_Return True
        Case Begin
            Case (iAction = CI_ChkViewCollisions)
                Send RunReturnMismatchReport
                Case Break
            Case (iAction = CI_ChkCharModeInventory)
                Send RunCharModeInventory
                Case Break
            Case (iAction = CI_ChkRenameGlobal)
                Send RunRenameGlobalOffer
                Case Break
            Case (iAction = CI_ChkRenameCalls)
                Send RunRenameCallsOffer
                Case Break
            Case (iAction = CI_ChkObjCallToGet)
                Send RunObjCallToGetOffer
                Case Break
            Case (iAction = CI_ChkDropSurplus)
                Send RunDropSurplusOffer
                Case Break
            Case (iAction = CI_ChkRunFnScope)
                Send RunFnOverCompiledScope
                Case Break
            Case (iAction = CI_ChkFixDecl)
                Send RunFixDeclarationOffer
                Case Break
            Case (iAction = CI_ChkRenameClass)
                Send RunRenameClassOffer
                Case Break
            Case (iAction = CI_ChkGuardExternal)
                Send RunGuardExternalForName
                Case Break
            Case (iAction = CI_ChkGuardGlobals)
                Send RunGuardGlobals
                Case Break
            Case (iAction = CI_ChkRunPlan)
                Send RunGuidedPlan
                Case Break
            Case (iAction = CI_ChkFixShadow)
                Send DoFixShadowedFiles
                Case Break
            Case Else
                Function_Return False
        Case End
        Function_Return True
    End_Function

    // Board housekeeping: the editor jump, the ignore list, Clear board, the "Which ones?" lists, the shadow copies, Tidy Up.
    Function _RunHousekeepingAction Integer iAction Returns Boolean
        String sGroup

        Case Begin
            Case (iAction = CI_ChkOpenSource)
                Send OpenFindingSource
                Case Break
            Case (iAction = CI_ChkIgnoreFn)
                Get psPendingIgnoreFn of oChkDeferTimer to sGroup
                Send IgnoreFindingsForGroup sGroup
                Case Break
            Case (iAction = CI_ChkIgnoreRow)
                Get psPendingIgnoreRow of oChkDeferTimer to sGroup
                Send IgnoreFindingRow sGroup
                Case Break
            Case (iAction = CI_ChkClearIgnored)
                Send ClearIgnoredFindings
                Case Break
            Case (iAction = CI_ChkShowSkipped)
                Send ShowSkippedDeadDependencies
                Case Break
            Case (iAction = CI_ChkClearBoard)
                Send DoClearBoard
                Case Break
            Case (iAction = CI_ChkAskDeleteSavedCheck)
                Send DoAskDeleteSavedCheck
                Case Break
            Case (iAction = CI_ChkShowShadowFiles)
                Send DoShowShadowedFiles
                Case Break
            Case (iAction = CI_ChkUnkeepShadows)
                Send DoUnkeepShadowedFiles
                Case Break
            Case (iAction = CI_ChkRestoreLanguage)
                Send DoRestoreLanguageSetting
                Case Break
            Case (iAction = CI_ChkKeepInstallLanguage)
                Send DoKeepInstallLanguage
                Case Break
            /* STAGE 4. The existing Tidy Up nudge (TestCompileFT CI_TCDeferTidyUp) sets pbWorkspaceMode
               and activates the FOLDERS view before Functions - and activating Folders REBUILDS the
               folder grid from the workspace, wiping a curated scope. That is the documented defect
               this redesign exists to avoid, so the trail goes straight to Functions and leaves the
               scope exactly as the user left it. */
            Case (iAction = CI_ChkTidyUp)
                // Mark the run as OURS, so the manual-run handoff closes the loop back to this trail
                // ("run Check to verify") instead of the pre-trail "Open Test Compile" dialog.
                Set pbGuidedTidyUpRun of ghoApplication to True
                Send Activate_oSelectFunctionsView of (Client_Id(phoMainPanel(ghoApplication)))
                Send SetFnGroupFilter of (oSelectFunctionsView(Client_Id(phoMainPanel(ghoApplication)))) eFnGroupCleanup
                Case Break
            Case Else
                Function_Return False
        Case End
        Function_Return True
    End_Function

    // Navigation and the utilities: the other views, the modals, the after-run row. Tried last, so an
    // unknown code is simply ignored here.
    Procedure _RunNavigationAction Integer iAction
        Boolean bLibsOk bHeld
        Integer iScanned

        Case Begin
            Case (iAction = CI_ChkAdjustScope)
                Send Activate_oSelectFoldersView of (Client_Id(phoMainPanel(ghoApplication)))
                Case Break
            /* ActivateDeepScanRulesDialog follows the file-scope-procedure convention of
               ShowProgressHistory and FillBackupFilesDialog: it lands on the command-bar client that
               Used the dialog. Modal, so control returns only once it closes - and a toggle in there
               changes the count on this tile AND invalidates the scan cache (the rules version is in
               its fingerprint), so the tile is repainted rather than left showing the old ratio.
               Findings are left alone: they are the PREVIOUS scan's, and a rule change does not
               retroactively alter what it found. */
            Case (iAction = CI_ChkDeepScanRules)
                Send ActivateDeepScanRulesDialog of (Client_Id(ghoCommandBars))
                Send RefreshTilesKeepFindings False
                Case Break
            /* ShowProgressHistory is a file-scope procedure in ModProgressHistoryFT.dg, so it lands
               on the command-bar client that Used it. It Popups the dialog, which renders the history
               fresh on each open, and the Popup BLOCKS until the modal closes, so a Reset performed
               inside it has already happened by the time control returns - which is why the progress
               readout is repainted here. (The Dashboard used to be repainted from here too; it
               repaints itself on entry. Nils 2026-08-02.) */
            Case (iAction = CI_ChkViewProgress)
                Send ShowProgressHistory of (Client_Id(ghoCommandBars))
                Send RefreshTilesKeepFindings False
                Case Break
            Case (iAction = CI_ChkReadLog)
                Send ShowLogFile of ghoApplication
                Case Break
            Case (iAction = CI_ChkReadOtherLogs)
                Send ShowOtherLogFiles of ghoApplication
                Case Break
            Case (iAction = CI_ChkCompare)
                Send CompareSource of ghoBoardActions
                Case Break
            Case (iAction = CI_ChkUndo)
                /* THE ONE THE NOTE DOES NOT COVER. Revert lives on oTile_Actions, which
                   ShowCheckRunningNote never touches, and the board keeps pumping through both
                   halves of a Check - so this chip stays clickable throughout, unlike every
                   findings row. RevertFromBackup restores backup files OVER the source the compile
                   is reading, which would leave the findings describing code that is no longer
                   there. This is the click the Check gate was actually needed for. */
                Get _HeldByRunningCheck "Restoring a backup set now would rewrite the source files this Check is in the middle of compiling, so whatever it reported would describe code that is no longer there." to bHeld
                If (bHeld = False) Begin
                    Send RevertFromBackup of ghoBoardActions
                    // Modal, so it has closed. A restore moves backups out of the folder, so the Revert
                    // count and the Compare gate are stale - repaint this view's OWN action row.
                    Send PushHtml of (oTile_Actions(oWebHost(Self))) (ActionRowHtml(ghoTileMarkup))
                End
                Case Break
            /* ONE dialog, one click. It used to open a read-only report which then offered a
               link to the editor - two surfaces over one subject, reached one after the other
               (Nils 2026-08-11: "a bit awkward"). They are now the same screen.
               "" = the loaded workspace, which MaintainWorkspaceLibraries resolves itself. Modal,
               so it has closed - and the [Libraries] list it may have just rewritten is what the
               tile half above counts. Same repaint the compiler picker does below. */
            /* THE AUTOMATIC UPDATE CHECK, on its own tick so the board is already on screen. It
               spawns a process per git dependency and waits on a network, which is why it may not
               happen on the paint path - and why it is bounded at CI_GitLsRemoteQuickSecs rather
               than the button's twenty seconds. Only the top row repaints: nothing else it could
               have changed, and a full RefreshTiles would re-arm this and loop. */
            Case (iAction = CI_ChkUpdateScan)
                Move (PublishWorkspaceUpdateScan(psSWSFile(ghoApplication))) to iScanned
                Send PushHtml of (oTile_Setup(oWebHost(Self))) (SetupLibsRowHtml(ghoTileMarkup))
                Case Break
            Case (iAction = CI_ChkLibraries)
                Get MaintainWorkspaceLibraries "" to bLibsOk
                Send RefreshTiles
                Case Break
            Case (iAction = CI_ChkCompilerSetup)
                // The modal Compiler Settings picker (same Popup the dashboard uses). Popup is synchronous,
                // so the tiles re-render with the new selection as soon as it closes.
                Send Popup of (oCompilerSetup_dg(Client_Id(ghoCommandBars)))
                Send RefreshTiles
                Case Break
            /* THE CRUMB'S ONE ACTION - back to the Start Center. The three handlers that stood here
               (open the .sws dialog, load a recent by index, remove a recent) went with the workspace
               tile: that whole job is the Start Center's now, and leaving the code behind would have
               left three routes into a workspace change that this board no longer offers a way to
               reach. What used to follow them - WorkspaceChanged - is not lost; it moved to
               OnWorkspaceLoaded, where it now runs for a change made ANYWHERE. */
            Case (iAction = CI_ChkStartCenter)
                Send Activate_oStartCenter_vw of (Client_Id(phoMainPanel(ghoApplication)))
                Case Break
        Case End
    End_Procedure

    /* THE CHECK ITSELF - the button's own caption: scan + compile. Runs on the timer's tick
       (CI_ChkRunCheck), never on the click. pbGuidedCheckRun makes StartAnalyze's tail hand back
       via RenderGuidedFindings instead of the old dashboard nudges; the phase stamps (see
       cRefactorApplication) are set here and by the compile and analyze in turn, so the board can
       report the split when it renders. */
    Procedure RunGuidedCheck
        Handle hoPanel hoStatusBar
        Boolean bCharMode bScanCancelled bWasGuard bWasConvert bWasAnnounced bWasCharMode
        Integer iWasStart iWasScan iWasCompile iWasAnalyze
        String  sWasBail sWasCrash

        // What this Check is about to reset - kept, so a Check cancelled during its scan can put it
        // back (the cancel branch below).
        Get pbGuardFoundNothing   to bWasGuard
        Get pbConvertFoundNothing to bWasConvert
        Get pbChkDoneAnnounced    to bWasAnnounced
        Get pbCharModeCheck       to bWasCharMode
        Get piChkTickStart   of ghoApplication to iWasStart
        Get piChkTickScan    of ghoApplication to iWasScan
        Get piChkTickCompile of ghoApplication to iWasCompile
        Get piChkTickAnalyze of ghoApplication to iWasAnalyze
        Get psChkCompileBail of ghoApplication to sWasBail
        Get psChkCompileCrash of ghoApplication to sWasCrash

        // A new Check produces new information, so both spent actions are worth offering again -
        // and it may reach a different verdict, so the stage-done message may speak once more.
        Set pbGuardFoundNothing   to False
        Set pbConvertFoundNothing to False
        Set pbChkDoneAnnounced    to False
        Set pbGuidedCheckRun of ghoApplication to True
        Set piChkTickStart   of ghoApplication to (GetTickCount())
        Set piChkTickScan    of ghoApplication to 0
        Set piChkTickCompile of ghoApplication to 0
        Set piChkTickAnalyze of ghoApplication to 0
        Set psChkCompileBail of ghoApplication to ""
        Set psChkCompileCrash of ghoApplication to ""
        // THE OLD FINDINGS GO NOW, before anything slow starts - they belong to the compile this
        // Check is replacing, and until this they stayed on screen and clickable throughout it.
        Send ShowCheckRunningNote
        /* A CHARACTER-MODE PROGRAM HAS NO DATAFLEX 26 BUILD (Nils 2026-09-20: a 3.1 workspace's
           Check produced a board of DataFlex's own packages failing against themselves, from
           UI.PKG not found downwards). Its Check is the source scan plus the inventory, and the
           board says why there was no compile - see _RunCharacterModeCheck. */
        Get MainProgramIsCharacterMode of ghoApplication to bCharMode
        Set pbCharModeCheck to bCharMode
        If (bCharMode = True) Begin
            Send _RunCharacterModeCheck
            Procedure_Return
        End
        /* DOCK ONLY, never the editor (Nils 2026-08-01). ShowTestCompilePanel is
           "Activate_oEditorView_vw + show the dock", so Check used to throw the user into the
           editor, compile there, and then drag them back here when the findings rendered - a
           round trip through a view they had not asked for and could not use yet.

           The dock is docked to the FRAME, not to a view, so it shows the live compile output
           just as well from here (the Dashboard's own Deep Scan chip has always shown it this
           way). The editor is opened when it is actually needed: double-clicking a findings
           row, which is the only moment there is a file and a line to look at. */
        Send ShowTestCompileDockOnly of (Client_Id(ghoCommandBars))
        Send _GuidedScanHalf (&bScanCancelled)
        /* CANCEL STOPS THE CHECK (Nils 2026-10-05: "the process continues with a compile/analyze.
           It should stop all together after 'Cancel' of the status_panel is clicked"). The scan
           half's Cancel ended the scan and nothing more: the compile half below started all the
           same, so the one button that says stop bought a full compile and analyze.

           Nothing has changed when the scan is cancelled - no compile ran, and the analyzer grid
           still holds the previous Check's rows - so the board goes back to what it showed: the
           stamps and the spent-action flags this Check reset are put back, the Check-is-running
           note gives way to those findings again, and the status bar says what happened. */
        If (bScanCancelled = True) Begin
            Set pbGuidedCheckRun of ghoApplication to False
            Set pbGuardFoundNothing   to bWasGuard
            Set pbConvertFoundNothing to bWasConvert
            Set pbChkDoneAnnounced    to bWasAnnounced
            Set pbCharModeCheck       to bWasCharMode
            Set piChkTickStart   of ghoApplication to iWasStart
            Set piChkTickScan    of ghoApplication to iWasScan
            Set piChkTickCompile of ghoApplication to iWasCompile
            Set piChkTickAnalyze of ghoApplication to iWasAnalyze
            Set psChkCompileBail of ghoApplication to sWasBail
            Set psChkCompileCrash of ghoApplication to sWasCrash
            Send BoardBusyOn "Check cancelled - putting the previous findings back..."
            Send RefreshTilesKeepFindings True
            Send BoardBusyOff
            Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoStatusBar
            If (hoStatusBar <> 0) ;
                Set StatusText of hoStatusBar to "Check cancelled - nothing was compiled. The board shows the previous Check."
            Procedure_Return
        End
        Set piChkTickScan of ghoApplication to (GetTickCount())
        // THE COMPILE HALF. DoCompileToggle is a method ON the panel, not an app-level entry -
        // send it to the panel handle the panel publishes when shown (the F5 pattern in
        // EditorViewFT.StartCompiler).
        Get phoTestCompileFT of ghoApplication to hoPanel
        If (hoPanel <> 0) ;
            Send DoCompileToggle of hoPanel
    End_Procedure

    /* THE CHARACTER-MODE CHECK (Nils 2026-09-20). No compile - there is nothing to compile with -
       so: the inventory report over the Check's scope, silent (its totals feed the board's notice
       and its log is one chip away), then the same Deep Scan the ordinary Check parks for its
       analyze, fed to the analyzer grid directly through the scan-only door Analyze Source uses.
       The phase stamps are set so the header's split renders (compile at 0 s), and
       pbGuidedCheckRun is cleared - there is no compile to hand back through. */
    Procedure _RunCharacterModeCheck
        String[] asScanFolders asNoFiles
        tCompileError[] aScanMsgs
        Boolean bScanCancelled bRan
        Integer iFilesTotal iCacheHits

        Set pbGuidedCheckRun of ghoApplication to False
        Move False to bScanCancelled
        Send BoardBusyOn "Check: taking the character-mode inventory..."
        Get RunScopedFunction "CharacterModeInventoryReport" True "" "" asNoFiles to bRan
        Send BoardBusyOff
        Get pasSelectedFolders of ghoApplication to asScanFolders
        If (SizeOfArray(asScanFolders) = 0) ;
            Get WholeWorkspaceSourceFolders of ghoApplication to asScanFolders
        If (SizeOfArray(asScanFolders) > 0) ;
            Get ScanFoldersToMessages of ghoDeepScanDriver asScanFolders "Check - scanning source for obsolete symbols..." (&bScanCancelled) (&iFilesTotal) (&iCacheHits) to aScanMsgs
        Set piChkTickScan    of ghoApplication to (GetTickCount())
        Set piChkTickCompile of ghoApplication to (GetTickCount())
        If (bScanCancelled = True) Begin
            Send RefreshFindings
            Procedure_Return
        End
        Send ActivateModAnalyzerDeepScan of (Client_Id(ghoCommandBars)) aScanMsgs
        Set piChkTickAnalyze of ghoApplication to (GetTickCount())
        Send RenderGuidedFindings
    End_Procedure

    // The notice's "Show the inventory": the report over the Check's scope, then its log in the viewer.
    Procedure RunCharModeInventory
        String[] asNoFiles
        String sHome sReport
        Boolean bRan bExists bDummy

        Get RunScopedFunction "CharacterModeInventoryReport" True "" "" asNoFiles to bRan
        If (bRan = False) ;
            Procedure_Return
        Get psHomeTarget of ghoApplication to sHome
        Move (vFolderFormat(sHome) + CS_BackupFolder + CS_DirSeparator + CS_CharModeInventoryLogFile) to sReport
        Get vFilePathExists sReport to bExists
        If (bExists = False) Begin
            Get FTHtmlMessage "Character-mode inventory" (HelpParagraph("The inventory report could not be created.")) "OK" "" to bDummy
            Procedure_Return
        End
        Send ActivateEngineLogFile of (Client_Id(phoMainPanel(ghoApplication))) sReport
        Send RefreshFindings
    End_Procedure

    /* THE NOTICE (Nils 2026-09-20): why this board has no compiler lane. Rendered under the findings
       header whenever the last Check found a character-mode main program; the inventory totals come
       from the report the Check ran (pCharModeInventory), and the chip opens its log. */
    Function _CharModeNoticeHtml Returns String
        tCharModeInventory Inv
        String sHtml sMainEsc

        If (pbCharModeCheck(Self) = False) ;
            Function_Return ""
        Get pCharModeInventory of ghoFuncLib to Inv
        Get HtmlEscaped (Trim(MainProgram(ghoApplication))) to sMainEsc
        Move ((DivOpen("fnote")) + (BoldText("Character-mode program")) + ' ' + CS_EmDash + ' ' + (BoldHtml(sMainEsc)) + ' starts with Use UI, so it was written for DataFlex character mode. DataFlex 26 has no character mode: the program cannot be compiled by DataFlex 26 until it has been rewritten as a Windows program (one that starts with Use DFAllEnt.pkg). This Check therefore ran the source scan only and skipped the compile.') to sHtml
        Move (sHtml + CS_Br + 'To be rewritten by hand: ' + (BoldHtml(String(Inv.iImages))) + ' screen image(s), ' + (BoldHtml(String(Inv.iScreenCmds))) + ' screen and keyboard command(s), ' + (BoldHtml(String(Inv.iUiObjects))) + ' UI object(s) and ' + (BoldHtml(String(Inv.iKeyprocs))) + ' Keyproc handler(s) in ' + String(Inv.iFiles) + ' file(s). The findings below are what this tool can change for you. ') to sHtml
        Move (sHtml + (ChipHtml("fact alt", "fact alt off", "charinv", "", "Show the inventory", "Runs the character-mode inventory over the Check's scope and opens it: every site, per file.", True))) to sHtml
        /* WHICH CONVERTERS THIS PROGRAM CAN TAKE IS THE USER'S CALL (Nils 2026-09-23). Local and
           Chain were hard-gated for a few hours; they are the never-pick list's job now, and the
           board says where that list is instead of deciding for the user. */
        /* The examples are the ones testers have met on 3.x programs - Local (2026-09-23), Chain, and Return to
           Gosub_Return (GitHub, 2026-10-06) - not the whole list: every syntax rewrite writes what the Windows
           program needs, and a 3.x compiler takes none of that. The never-pick list is the user's answer. */
        Move (sHtml + CS_Br + 'A 3.x compiler cannot use some of the conversions ' + CS_EmDash + ' removing the Local keyword, Chain to Runprogram, Return to Gosub_Return, and others like them. To stop DFRefactor from running such a function, open Select Functions, right-click the function and tick ' + (BoldText("Never pick this function for me")) + '. It then does not run, and its findings can be found in the Review band instead.' + CS_DivEnd) to sHtml
        Function_Return sHtml
    End_Function

    /* THE SCAN HALF (phase-2 merge, Nils 2026-07-25): run the Deep Scan core FIRST - it is
       seconds under the incremental cache - over the Check's own scope (the selected folders,
       else the whole workspace; the same resolution every guided row action uses), with NO
       scope confirm: Check's scope is already the user's decision. The results are PARKED on
       the analyzer grid (paPendingScanMessages) and the compile's analyze folds them into the
       ONE board - compiler + scan, classified together, planned together. The trigger:
       'Object oX is a cTrGrid' is invisible to the compiler, so without the scan lane the
       board could never say "this file still has a legacy grid". */
    Procedure _GuidedScanHalf Boolean ByRef bScanCancelled
        String[] asScanFolders asChkEmpty
        tCompileError[] aScanMsgs
        Integer iFilesTotal iCacheHits
        Handle  hoChkSB

        // Handed back to RunGuidedCheck, which stops the whole Check on it (2026-10-05).
        Move False to bScanCancelled
        Get pasSelectedFolders of ghoApplication to asScanFolders
        If (SizeOfArray(asScanFolders) = 0) ;
            Get WholeWorkspaceSourceFolders of ghoApplication to asScanFolders
        If (SizeOfArray(asScanFolders) = 0) ;
            Procedure_Return
        Get ScanFoldersToMessages of ghoDeepScanDriver asScanFolders "Check - scanning source for obsolete symbols..." (&bScanCancelled) (&iFilesTotal) (&iCacheHits) to aScanMsgs
        // A cancelled scan leaves the PREVIOUS scan's parked results as they are (cancel
        // changes nothing); a completed one replaces them - even when empty, which is how
        // scan rows retire once their fixes land.
        If (bScanCancelled = False and ghoModAnalyzerDock <> 0) ;
            Set paPendingScanMessages of (oModAnalyzer_grd(ghoModAnalyzerDock)) to aScanMsgs
        /* A SELECTED FOLDER THAT GAVE NOTHING IS NEWS (Nils 2026-08-31). On WinServ a
           ticked folder holding 152 packages contributed zero files, and nothing on any
           surface said so - every scan-only rule was simply absent for those files and
           the board read as coverage. The Check has no result line of its own, so it
           says it here; Analyze Source appends the same to its own line. */
        Get pasEmptyFolders of ghoApplication to asChkEmpty
        If (SizeOfArray(asChkEmpty) > 0) Begin
            Get Statusbar_Id of (phoMainPanel(ghoApplication)) to hoChkSB
            If (hoChkSB <> 0) ;
                Set StatusText of hoChkSB to ("Check: " + String(SizeOfArray(asChkEmpty)) + " selected folder(s) held no source file - first: " + asChkEmpty[0])
        End
    End_Procedure

    /* After a guided Check's analyze: put the findings on screen, come forward, say the verdict.
       THE SILENT STRETCH Nils reported (2026-08-31): the analyze has already handed the cursor
       back and written "Ready. Analyzed in Ns.", and this render - the one that actually puts the
       findings on screen - used to run with no cursor and no note. */
    Procedure FinishGuidedRender
        Send BoardBusyOn "Check: building the findings list..."
        Send RefreshFindings
        Send BoardBusyOff
        Send Activate_oDashboard_vw of (Client_Id(ghoCommandBars))
        Send AnnounceCheckStageDone
    End_Procedure

    Object oChkDeferTimer is a cFTDeferTimer
        // "<file>|<line>" for CI_ChkOpenSource - the findings row's jump-to-source target.
        Property String  psPendingOpenSrc ""
        Property String  psPendingIgnoreFn ""
        // "<file>|<msg>" for CI_ChkIgnoreRow - the one Review row to hide.
        Property String  psPendingIgnoreRow ""

        /* THE WAY IN for everything that is not a page click: ArmAction (cFTDeferTimer) parks the action
           code and arms the 1 ms one-shot; OnDeferredAction runs it once the caller's stack - a Broadcast,
           an analyze tail, the combo's change - has unwound. A page click runs through the library's click
           relay instead (RunClickAction on the view) and comes here only while a render is in flight. */

        /* A board render PUMPS to keep its wait cursor and progress line alive (see pbBoardRendering).
           Every action is something a queued click could ask for MID-render - a compile, a modal, a
           second render - so none of them may be dispatched on that pump. Held instead: the action runs
           the moment the render lets go. */
        Function DeferHold Returns Boolean
            Boolean bRendering
            Delegate Get pbBoardRendering to bRendering
            Function_Return bRendering
        End_Function

        // The action families live on the view - see RunBoardAction just above this object.
        Procedure OnDeferredAction Integer iAction String sParam
            Delegate Send RunBoardAction iAction
        End_Procedure
    End_Object

    /* THE SCOPE OFFER GETS ITS OWN TIMER, and that is not fussiness (Nils 2026-08-31).

       oChkDeferTimer is a SINGLE-SLOT dispatcher - one piPendingAction - and OnWorkspaceLoaded
       fires for every workspace load. WorkspaceChanged has just armed that slot itself, via
       MaybeRestoreLastCheck -> RestoreLastCheck -> CI_ChkFinishLastPlan: the cold-show follow-up
       that reasserts the analyzer view, refreshes the tiles and drops the wait cursor. Arming the
       shared slot immediately afterwards overwrote it, the follow-up never ran, and the board came
       up COMPLETELY EMPTY after a Check - no findings, not even the Tidy Up button.

       Anything armed from the workspace-load path is competing with a restore that path already
       started. Own timer, own slot, no competition. */
    Object oScopeOfferTimer is a cFTDeferTimer
        // Same rule as oChkDeferTimer: never dispatch a modal onto a render's pump.
        Function DeferHold Returns Boolean
            Boolean bRendering
            Delegate Get pbBoardRendering to bRendering
            Function_Return bRendering
        End_Function

        Procedure OnDeferredAction Integer iAction String sParam
            Boolean bOk
            String sPending sWS
            Delegate Send OfferInitialScope
            /* THE COPY'S LIBRARIES DIALOG FOLLOWS THE QUESTION (2026-09-14): the copy step parks its
               wish on the application, stamped with the copy's .sws - see psLibrariesAfterScopeWS.
               Consumed here whatever happens next; opened only when the loaded workspace is that
               copy. One modal after the other, on one timer, so they can no longer interleave. */
            Get psLibrariesAfterScopeWS of ghoApplication to sPending
            If (sPending <> "") Begin
                Set psLibrariesAfterScopeWS of ghoApplication to ""
                Get psSWSFile of ghoApplication to sWS
                If (Lowercase(Trim(sPending)) = Lowercase(Trim(sWS))) ;
                    Get MaintainWorkspaceLibraries "" to bOk
            End
        End_Procedure
    End_Object

    Procedure Activate Returns Integer
        Integer iRetVal
        Boolean bRestoring

        Forward Get msg_Activate to iRetVal
        If (iRetVal = 0) Begin
            // The user is working on the GUIDED surface: from now on, every analyze in this session
            // hands back here (StartAnalyze's tail), not just ones the view's own Check button drove.
            // Compiling from the dock and being left in the grid+editor read as the flow losing its
            // place (Nils 2026-07-23: "I had to manually activate the (WIP) view again").
            Set pbGuidedSurfaceUsed of ghoApplication to True
            // ...and stamp WHICH board is in use, so the Editor's back crumb returns here.
            Set piLastBoardView of ghoApplication to eBoardGuided
            // Same stamp on the SURFACE property, which the Select Folders / Select Functions crumbs
            // read - they can also be entered from the Start Center, which piLastBoardView cannot say.
            Set piLastSurface   of ghoApplication to eBoardGuided
            // A spent action goes inert so it cannot be pressed again pointlessly - but that verdict is only
            // about the run that just happened. Coming back to the view is a deliberate "try again", and the
            // answer may genuinely have changed since: a rebuilt DFRefactor can convert what the previous
            // build declined (exactly what the Indicate fix did). Clearing here keeps the guard useful
            // without turning it into a dead end that only a full compile+analyze can escape.
            Set pbGuardFoundNothing   to False
            Set pbConvertFoundNothing to False
            /* Arriving with a saved Check on disk and none run this session restores it (see
               MaybeRestoreLastCheck) - and that path drives its own deferred tick, so it must not
               have the light refresh scheduled over the top of it. One timer, one action. */
            Get MaybeRestoreLastCheck to bRestoring
            If (bRestoring = False) Begin
                Send ArmAction of oChkDeferTimer CI_ChkRefreshLight
            End
        End
        Procedure_Return iRetVal
    End_Procedure

End_Object
