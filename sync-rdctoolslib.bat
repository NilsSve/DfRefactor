@echo off
setlocal enableextensions enabledelayedexpansion

REM ===========================================================================
REM  sync-rdctoolslib.bat - propagate an RDCToolsLib change up the nested
REM  submodule chain so the DFRefactor workspace ends up in sync.
REM
REM  Chain:  DfRefactor --pins--> DUF --pins--> RDCToolsLib
REM
REM  CONTRACT (do this FIRST, by hand, in the ONE canonical place):
REM     1. Edit in   C:\Projects\DF20\Libraries\RDCToolsLib   (it is on 'main')
REM     2. git add / commit  there
REM     3. git push origin main   there       <-- use git CLI, NOT GitHub
REM                                               Desktop (it skips submodule
REM                                               pushes and you desync again)
REM
REM  THEN run this script. It:
REM     - refuses to run unless the standalone clone is clean AND pushed
REM     - fast-forwards DUF's nested RDCToolsLib to that published commit,
REM       commits the gitlink, pushes DUF  (NilsSve/DbUpdateFramework.git)
REM     - bumps DfRefactor's DUF pin, commits, pushes DfRefactor
REM
REM  Safety: stages ONLY the submodule gitlink at each level (never -A, so
REM  in-progress AppSrc work is never swept in); only auto-pushes a level if
REM  that level had NO other unpushed commits; aborts on any surprise and
REM  is idempotent (re-running when already in sync does nothing).
REM ===========================================================================

set "DR=%~dp0"
if "%DR:~-1%"=="\" set "DR=%DR:~0,-1%"
set "DUF=%DR%\Libraries\DUF"
set "NESTED=%DUF%\Libraries\RDCToolsLib"
for %%I in ("%DR%\..\Libraries\RDCToolsLib") do set "STANDALONE=%%~fI"

echo === sync-rdctoolslib ===
echo   DfRefactor : %DR%
echo   DUF        : %DUF%
echo   nested     : %NESTED%
echo   standalone : %STANDALONE%
echo.

where git >nul 2>nul || (echo [ERROR] git is not on PATH. & goto :fail)

for %%P in ("%DR%" "%DUF%" "%NESTED%" "%STANDALONE%") do (
    git -C "%%~P" rev-parse --is-inside-work-tree >nul 2>nul || (echo [ERROR] not a git repo: %%~P & goto :fail)
)

REM -------- [1/3] standalone clone must be clean AND fully pushed ----------
echo [1/3] Verifying standalone RDCToolsLib is committed ^& pushed...
git -C "%STANDALONE%" fetch origin --quiet || (echo [ERROR] fetch failed ^(network?^). & goto :fail)

for /f %%S in ('git -C "%STANDALONE%" status --porcelain ^| find /c /v ""') do set "DIRTY=%%S"
if not "!DIRTY!"=="0" (
    echo [STOP] %STANDALONE%
    echo        has uncommitted changes. Commit ^& push your RDCToolsLib edits
    echo        there first, then re-run this script.
    goto :fail
)

for /f "delims=" %%B in ('git -C "%STANDALONE%" rev-parse --abbrev-ref HEAD') do set "SBR=%%B"
if /i not "!SBR!"=="main" (echo [STOP] standalone is on "!SBR!", expected "main". & goto :fail)

for /f %%A in ('git -C "%STANDALONE%" rev-list --count origin/main..HEAD') do set "AHEAD=%%A"
for /f %%B in ('git -C "%STANDALONE%" rev-list --count HEAD..origin/main') do set "BEHIND=%%B"
if not "!AHEAD!"=="0" (
    echo [STOP] standalone has !AHEAD! unpushed commit^(s^). Push first:
    echo        git -C "%STANDALONE%" push origin main
    goto :fail
)
if not "!BEHIND!"=="0" (
    echo [STOP] standalone is !BEHIND! behind origin/main. Update first:
    echo        git -C "%STANDALONE%" pull --ff-only
    goto :fail
)
for /f "delims=" %%H in ('git -C "%STANDALONE%" rev-parse HEAD') do set "TARGET=%%H"
echo        OK - target RDCToolsLib commit = !TARGET!
echo.

REM -------- [2/3] DUF adopts TARGET, commit + (guarded) push --------------
echo [2/3] Updating DUF's nested RDCToolsLib...
for /f %%S in ('git -C "%NESTED%" status --porcelain ^| find /c /v ""') do set "NDIRTY=%%S"
if not "!NDIRTY!"=="0" (
    echo [STOP] nested copy has local changes:
    echo        %NESTED%
    echo        Resolve/stash/commit them there first, then re-run.
    goto :fail
)
git -C "%NESTED%" fetch origin --quiet || (echo [ERROR] nested fetch failed. & goto :fail)
git -C "%NESTED%" checkout --quiet !TARGET! || (echo [ERROR] cannot checkout !TARGET! in nested copy. & goto :fail)
for /f "delims=" %%H in ('git -C "%NESTED%" rev-parse HEAD') do set "NHEAD=%%H"
if /i not "!NHEAD!"=="!TARGET!" (echo [ERROR] nested HEAD != target after checkout. & goto :fail)

git -C "%DUF%" diff --quiet -- Libraries/RDCToolsLib
if errorlevel 1 (set "DUFCHANGED=1") else (set "DUFCHANGED=0")
if "!DUFCHANGED!"=="0" (
    echo        DUF already pins this commit - nothing to commit at DUF level.
    set "DUFRESULT=already in sync"
) else (
    set "DUFAHEAD=1"
    for /f %%A in ('git -C "%DUF%" rev-list --count @{u}..HEAD 2^>nul') do set "DUFAHEAD=%%A"
    git -C "%DUF%" add Libraries/RDCToolsLib || (echo [ERROR] git add failed in DUF. & goto :fail)
    git -C "%DUF%" commit -m "Bump RDCToolsLib submodule to !TARGET:~0,7!" >nul || (echo [ERROR] commit failed in DUF. & goto :fail)
    if "!DUFAHEAD!"=="0" (
        git -C "%DUF%" push origin HEAD || (echo [ERROR] DUF push failed ^(non-fast-forward? pull --ff-only then re-run^). & goto :fail)
        echo        DUF committed ^& pushed.
        set "DUFRESULT=committed + pushed"
    ) else (
        echo [WARN] DUF had !DUFAHEAD! pre-existing unpushed commit^(s^);
        echo        committed the bump locally but did NOT push DUF.
        echo        Review, then:  git -C "%DUF%" push origin HEAD
        set "DUFRESULT=committed locally, push held"
    )
)
echo.

REM -------- [3/3] DfRefactor adopts new DUF (stage ONLY Libraries/DUF) ----
echo [3/3] Updating DfRefactor's DUF pin...
git -C "%DR%" diff --quiet -- Libraries/DUF
if errorlevel 1 (set "DRCHANGED=1") else (set "DRCHANGED=0")
if "!DRCHANGED!"=="0" (
    echo        DfRefactor already pins the current DUF - nothing to do.
    set "DRRESULT=already in sync"
    goto :summary
)
set "DRAHEAD=1"
for /f %%A in ('git -C "%DR%" rev-list --count @{u}..HEAD 2^>nul') do set "DRAHEAD=%%A"
git -C "%DR%" add Libraries/DUF || (echo [ERROR] git add failed in DfRefactor. & goto :fail)
for /f "delims=" %%F in ('git -C "%DR%" diff --cached --name-only') do (
    if /i not "%%F"=="Libraries/DUF" (
        echo [ERROR] unexpected staged path "%%F" - unstaging and aborting.
        git -C "%DR%" reset --quiet HEAD -- Libraries/DUF
        goto :fail
    )
)
git -C "%DR%" commit -m "Bump DUF submodule (propagates RDCToolsLib !TARGET:~0,7!)" >nul || (echo [ERROR] commit failed in DfRefactor. & goto :fail)
if "!DRAHEAD!"=="0" (
    git -C "%DR%" push origin HEAD || (echo [ERROR] DfRefactor push failed. & goto :fail)
    echo        DfRefactor committed ^& pushed.
    set "DRRESULT=committed + pushed"
) else (
    echo [WARN] DfRefactor had !DRAHEAD! pre-existing unpushed commit^(s^) ^(your WIP^);
    echo        committed the DUF bump locally but did NOT push DfRefactor
    echo        so your other commits are not pushed unintentionally.
    echo        Review, then:  git -C "%DR%" push origin HEAD
    set "DRRESULT=committed locally, push held"
)

:summary
echo.
echo === verify ===
for /f "delims=" %%H in ('git -C "%NESTED%" rev-parse HEAD') do set "FINAL=%%H"
echo   nested RDCToolsLib = !FINAL!
if /i "!FINAL!"=="!TARGET!" (echo   MATCHES target - propagated OK.) else (echo   [WARN] does NOT match target !TARGET!)
echo.
echo === summary ===
echo   RDCToolsLib target : !TARGET!
echo   DUF                : !DUFRESULT!
echo   DfRefactor         : !DRRESULT!
echo === done ===
endlocal
exit /b 0

:fail
echo.
echo *** sync-rdctoolslib ABORTED - no changes beyond any explicitly noted above. ***
endlocal
exit /b 1
