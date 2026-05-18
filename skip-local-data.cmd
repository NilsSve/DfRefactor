@echo off
REM ---------------------------------------------------------------------------
REM Run this ONCE after cloning this repository.
REM
REM The repo ships an empty baseline database as real files under Data\ so the
REM workspace runs out of the box. Once committed, git tracks those files, so
REM any local changes you make to the database would normally show up in
REM git status and could be pushed.
REM
REM This script runs "git update-index --skip-worktree" on every committed
REM file under Data\, telling git to ignore your local edits to them. Your
REM private/working database then stays on your machine and is never tracked
REM or pushed to GitHub.
REM
REM To undo (make git see Data\ changes again), run:
REM   for /f "delims=" %%f in ('git ls-files Data') do git update-index --no-skip-worktree "%%f"
REM ---------------------------------------------------------------------------

setlocal
cd /d "%~dp0"

for /f "delims=" %%f in ('git ls-files Data') do (
  git update-index --skip-worktree "%%f"
  echo skip-worktree set: %%f
)

echo.
echo Done. Git will now ignore local edits to the files listed above.
echo Your private Data\ database stays local and will not be committed.
endlocal
