<#
.SYNOPSIS
    Builds a DFRefactor pull request and runs the whole unit test suite on it.

.DESCRIPTION
    Until pull requests can be tested on a build server, this is the maintainer's one-command check of
    a contribution:

      1. fetches the pull request into a throw-away git worktree OUTSIDE this checkout (your working
         copy, its Data folder and its Programs folder are never touched);
      2. installs the workspace's library packages there (df-cli config);
      3. builds DUFUpdateProgram.src and UnitTests.src into that folder with df-cli build-file;
      4. runs UnitTests64.exe -c -o results.xml with a time limit (it first runs the DUF updater
         built beside it, because a fresh checkout's database is older than the code);
      5. prints the result - the number of tests, and each failing test by name;
      6. optionally posts that result as a comment on the pull request (-Comment);
      7. removes the worktree again (unless -Keep).

    Building a pull request RUNS ITS CODE on this machine. Read the change first - the script shows
    the files it changes and asks before it builds (skip the question with -Yes).

    Needs: git, the GitHub CLI (gh, signed in) and DataFlex 26 (df-cli).

.PARAMETER Number
    The pull request number.

.PARAMETER Repo
    The GitHub repository. Default: NilsSve/DfRefactor.

.PARAMETER WorkRoot
    Where the throw-away worktree goes. Default: %TEMP%\DfRefactor-PR.

.PARAMETER TimeoutMinutes
    How long the test run may take before it is stopped. Default: 30.

.PARAMETER Comment
    Post the result as a comment on the pull request (asks first unless -Yes).

.PARAMETER Keep
    Keep the worktree afterwards, to look at the build or run the TestBench on it.

.PARAMETER Yes
    Do not ask before building or before posting the comment.

.EXAMPLE
    .\Tools\Test-PullRequest.ps1 86

.EXAMPLE
    .\Tools\Test-PullRequest.ps1 -Number 86 -Comment -Keep

.EXAMPLE
    .\Tools\Test-PullRequest.ps1 -Branch master
    Tests the current master the same way - a baseline to compare a pull request with.

.EXAMPLE
    .\Tools\Test-PullRequest.ps1 -Commit HEAD
    Tests a commit of this checkout - nothing is fetched - from a fresh copy, the way a contributor's
    clone starts.
#>
[CmdletBinding(DefaultParameterSetName = 'PR')]
param(
    [Parameter(ParameterSetName = 'PR', Mandatory = $true, Position = 0)]
    [int]$Number,
    [Parameter(ParameterSetName = 'Branch', Mandatory = $true)]
    [string]$Branch,
    [Parameter(ParameterSetName = 'Commit', Mandatory = $true)]
    [string]$Commit,
    [string]$Repo = 'NilsSve/DfRefactor',
    [string]$WorkRoot = (Join-Path $env:TEMP 'DfRefactor-PR'),
    [int]$TimeoutMinutes = 30,
    [switch]$Comment,
    [switch]$Keep,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$RepoRoot  = Split-Path -Parent $PSScriptRoot          # this checkout - read from, never written to
$Workspace = 'DFRefactorFlexTron.sws'
$Program   = 'UnitTests'
$Updater   = 'DUFUpdateProgram'
$Toolchain = '26.0.0+windows-64'

function Write-Step([string]$Text) { Write-Host "`n== $Text" -ForegroundColor Cyan }

function Confirm-Step([string]$Question) {
    if ($Yes) { return $true }
    $a = Read-Host "$Question [y/N]"
    return ($a -match '^(y|yes)$')
}

function Find-DfCli {
    $cmd = Get-Command df-cli -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $p = 'C:\Program Files\DataFlex 26.0\Bin64\df-cli.exe'
    if (Test-Path $p) { return $p }
    throw 'df-cli was not found. Install DataFlex 26, or put df-cli on the PATH.'
}

# ---- 0. Tools --------------------------------------------------------------------------------------
foreach ($t in 'git', 'gh') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "$t was not found on the PATH." }
}
$DfCli = Find-DfCli
if ($Comment -and $PSCmdlet.ParameterSetName -ne 'PR') { throw '-Comment needs a pull request -Number.' }

# ---- 1. What is being tested -------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'PR') {
    Write-Step "Pull request #$Number in $Repo"
    $info = gh pr view $Number -R $Repo --json title,author,headRefName,headRefOid,files,state,isCrossRepository | ConvertFrom-Json
    if (-not $info) { throw "Pull request #$Number was not found in $Repo." }
    Write-Host ("{0}  (by {1}, {2}, {3})" -f $info.title, $info.author.login, $info.state, $info.headRefOid.Substring(0, 8))
    Write-Host ("{0} file(s) changed:" -f $info.files.Count)
    foreach ($f in $info.files) { Write-Host ("   +{0,-5} -{1,-5} {2}" -f $f.additions, $f.deletions, $f.path) }
    $Label   = "pr-$Number"
    $FetchRef = "pull/$Number/head"
    Write-Host "`nBuilding it runs the pull request's code on this machine. Read the change first:"
    Write-Host "   gh pr diff $Number -R $Repo"
    if (-not (Confirm-Step 'Build and test it now?')) { Write-Host 'Stopped - nothing was done.'; exit 2 }
} elseif ($PSCmdlet.ParameterSetName -eq 'Branch') {
    Write-Step "Branch $Branch of $Repo"
    $Label    = "branch-" + ($Branch -replace '[^\w.-]', '_')
    $FetchRef = $Branch
} else {
    $Commit = (git -C $RepoRoot rev-parse --verify "$Commit^{commit}").Trim()
    if ($LASTEXITCODE -ne 0) { throw "$Commit is not a commit in this checkout." }
    Write-Step "Commit $Commit of this checkout"
    $Label    = "commit-" + $Commit.Substring(0, 8)
    $FetchRef = $null
}

$Url  = "https://github.com/$Repo.git"
$Tree = Join-Path $WorkRoot $Label
$Out  = Join-Path $Tree '_build'

# ---- 2. A throw-away worktree -----------------------------------------------------------------------
Write-Step "Fetching into $Tree"
if (Test-Path $Tree) {
    git -C $RepoRoot worktree remove --force $Tree 2>$null
    if (Test-Path $Tree) { Remove-Item -Recurse -Force $Tree }
}
git -C $RepoRoot worktree prune
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
if ($FetchRef) {
    # Fetched by URL into FETCH_HEAD only: no remote, branch or tag is added to this checkout.
    git -C $RepoRoot fetch --quiet --no-tags $Url $FetchRef
    if ($LASTEXITCODE -ne 0) { throw "git fetch of $FetchRef failed." }
    $Commit = (git -C $RepoRoot rev-parse FETCH_HEAD).Trim()
}
git -C $RepoRoot worktree add --detach --quiet $Tree $Commit
if ($LASTEXITCODE -ne 0) { throw 'git worktree add failed.' }
Write-Host "Commit $Commit"

$Started = Get-Date
$Result  = $null
$cacheDir    = 'C:\ProgramData\DataFlex\Packages\Cache'
$cacheBefore = @(if (Test-Path $cacheDir) { Get-ChildItem $cacheDir -Directory | ForEach-Object Name })

# Steps 3-5; returns the result: Ok, Text, Failed.
function Invoke-BuildAndTest {
    # ---- 3. Library packages ----------------------------------------------------------------------
    Write-Step 'Installing the library packages (df-cli config)'
    Push-Location $Tree
    try {
        & $DfCli config $Workspace | Select-Object -Last 3 | ForEach-Object { Write-Host "   $_" }
        if ($LASTEXITCODE -ne 0) { throw "df-cli config failed (exit $LASTEXITCODE)." }

        # ---- 4. Build -----------------------------------------------------------------------------
        New-Item -ItemType Directory -Force $Out | Out-Null
        foreach ($prog in $Updater, $Program) {
            Write-Step "Building $prog.src"
            $cfg = Join-Path $Tree "AppSrc\$prog.cfg"
            $cfgArgs = @(if (Test-Path $cfg) { '--cfg', $cfg })
            $buildLog = & $DfCli build-file "AppSrc\$prog.src" --workspace $Workspace --output-dir $Out `
                            @cfgArgs --toolchain $Toolchain --rebuild 2>&1 | ForEach-Object { "$_" }
            $buildExit = $LASTEXITCODE
            if ($buildExit -ne 0 -or -not (Test-Path (Join-Path $Out "${prog}64.exe"))) { break }
        }
    } finally { Pop-Location }
    $errors = @($buildLog | Where-Object { $_ -match '\bError \d+' })
    $exe = Join-Path $Out "${Program}64.exe"
    if ($buildExit -ne 0 -or $errors.Count -gt 0 -or -not (Test-Path $exe)) {
        $buildLog | Select-Object -Last 25 | ForEach-Object { Write-Host "   $_" }
        return @{ Ok = $false; Text = "The build failed (df-cli exit $buildExit, $($errors.Count) compile error(s))."; Failed = @($errors | Select-Object -First 10) }
    }
    Write-Host "Built $exe"

    # The editor DLLs and COM components the program loads, and a Config.ws pointing at the worktree.
    foreach ($pattern in '*.dll', '*.ocx', '*.avi') {
        Get-ChildItem (Join-Path $Tree 'Programs') -Filter $pattern -File -ErrorAction SilentlyContinue | Copy-Item -Destination $Out -Force
        # Machine files that are not in git (COM components, clips) come from this checkout's Programs.
        Get-ChildItem (Join-Path $RepoRoot 'Programs') -Filter $pattern -File -ErrorAction SilentlyContinue |
            Where-Object { -not (Test-Path (Join-Path $Out $_.Name)) } | Copy-Item -Destination $Out -Force
    }
    $ws = Get-Content (Join-Path $Tree 'Programs\Config.ws') -Raw
    $ws = $ws.Replace('Home=..\', 'Home=' + $Tree.TrimEnd('\') + '\')
    [IO.File]::WriteAllText((Join-Path $Out 'Config.ws'), $ws, (New-Object Text.UTF8Encoding $false))

    # ---- 5. Run the tests ------------------------------------------------------------------------
    # UnitTests brings the database up to date itself first (DUFUpdateProgram64.exe, built beside it).
    Write-Step "Running the unit tests (time limit $TimeoutMinutes min)"
    $xml = Join-Path $Out 'results.xml'
    $p = Start-Process -FilePath $exe -ArgumentList @('-c', '-o', "`"$xml`"") -WorkingDirectory $Out -PassThru
    if (-not $p.WaitForExit($TimeoutMinutes * 60 * 1000)) {
        Stop-Process -Id $p.Id -Force
        return @{ Ok = $false; Text = "The test run did not finish within $TimeoutMinutes minutes and was stopped. (An error box waiting for an answer looks like this.)"; Failed = @() }
    }
    if (-not (Test-Path $xml)) {
        return @{ Ok = $false; Text = "The test program ended (exit $($p.ExitCode)) without writing results.xml."; Failed = @() }
    }
    [xml]$doc = Get-Content $xml -Raw
    $suites = $doc.testsuites
    $failedCases = @($doc.SelectNodes('//testcase[failure or error]') | ForEach-Object {
        $why = if ($_.failure) { $_.failure.message } else { $_.error.message }
        "$($_.classname) / $($_.name)" + $(if ($why) { " - $why" } else { '' })
    })
    $total = [int]$suites.tests; $nFail = [int]$suites.failures + [int]$suites.errors
    return @{
        Ok     = ($nFail -eq 0 -and $total -gt 0)
        Text   = "$total tests, $([int]$suites.failures) failed, $([int]$suites.errors) with errors."
        Failed = $failedCases
    }
}

try {
    $Result = Invoke-BuildAndTest
} finally {
    $minutes = [math]::Round(((Get-Date) - $Started).TotalMinutes, 1)

    # ---- 6. Report ---------------------------------------------------------------------------------
    Write-Step 'Result'
    if ($Result) {
        $colour = if ($Result.Ok) { 'Green' } else { 'Red' }
        Write-Host ("{0}  {1}" -f $(if ($Result.Ok) { 'PASSED' } else { 'FAILED' }), $Result.Text) -ForegroundColor $colour
        foreach ($f in $Result.Failed) { Write-Host "   $f" -ForegroundColor Red }
        Write-Host "Commit $Commit, $minutes min."
    } else {
        Write-Host 'The run stopped before a result - see the error above.' -ForegroundColor Red
    }
    if (Test-Path $cacheDir) {
        $gone = @($cacheBefore | Where-Object { -not (Test-Path (Join-Path $cacheDir $_)) })
        if ($gone.Count -gt 0) {
            Write-Host "Note: df-cli's housekeeping removed $($gone.Count) package cache entr(ies): $($gone -join ', '). df-cli fetches them again when a workspace needs them." -ForegroundColor Yellow
        }
    }

    # ---- 7. Clean up -------------------------------------------------------------------------------
    if ($Keep) {
        Write-Host "Kept: $Tree  (remove it with: git worktree remove --force `"$Tree`")"
    } else {
        Get-Process "${Program}64", "${Updater}64" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Tree*" } | Stop-Process -Force
        git -C $RepoRoot worktree remove --force $Tree 2>$null
        if (Test-Path $Tree) { Remove-Item -Recurse -Force $Tree -ErrorAction SilentlyContinue }
        git -C $RepoRoot worktree prune
    }
}

# ---- 8. Comment on the pull request ------------------------------------------------------------------
if ($Comment -and $Result) {
    $lines = @("**Unit tests on commit ``$($Commit.Substring(0, 8))``: $(if ($Result.Ok) { 'passed' } else { 'FAILED' })**", '', $Result.Text)
    if ($Result.Failed.Count -gt 0) {
        $lines += ''
        $lines += ($Result.Failed | Select-Object -First 30 | ForEach-Object { "- $_" })
    }
    $lines += ''
    $lines += "_DataFlex 26, built and run with Tools/Test-PullRequest.ps1 ($minutes min)._"
    $body = $lines -join "`n"
    Write-Host "`n$body`n"
    if (Confirm-Step "Post this as a comment on pull request #${Number}?") {
        $tmp = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($tmp, $body, (New-Object Text.UTF8Encoding $false))
        gh pr comment $Number -R $Repo --body-file $tmp
        Remove-Item $tmp
    }
}

if ($Result -and $Result.Ok) { exit 0 } else { exit 1 }
