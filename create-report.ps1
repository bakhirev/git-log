param(
    [Parameter(Position = 0)]
    [string] $TargetDir,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

function Show-Message {
    param(
        [string] $Text,
        [System.Windows.Forms.MessageBoxIcon] $Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($Quiet) {
        Write-Host $Text
        return
    }
    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        'Create Assayo report',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

function Find-Git {
    $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe'),
        (Join-Path $env:LocalAppData 'Programs\Git\cmd\git.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    return $null
}

function Convert-AssayoLog {
    param([string] $Raw)

    if ([string]::IsNullOrEmpty($Raw)) {
        return ''
    }

    $text = $Raw.Replace("`r`n", "`n").Replace("`r", "`n")
    $hadTrailingNewline = $text.EndsWith("`n")
    if ($hadTrailingNewline) {
        $text = $text.Substring(0, $text.Length - 1)
    }

    $text = $text.Replace('\', '\\').Replace('`', '"').Replace('$', 'S')
    $wrapped = 'R(f`' + $text + '`);'
    if ($hadTrailingNewline) {
        $wrapped += "`n"
    }
    return $wrapped
}

try {
    if ([string]::IsNullOrWhiteSpace($TargetDir)) {
        Show-Message 'Folder path was not provided.' ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    $TargetDir = $TargetDir.Trim().Trim('"')
    if ($TargetDir.Length -gt 3) {
        $TargetDir = $TargetDir.TrimEnd('\')
    }

    if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
        Show-Message "Folder does not exist:`n$TargetDir" ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    $gitMeta = Join-Path $TargetDir '.git'
    if (-not (Test-Path -LiteralPath $gitMeta)) {
        Show-Message "This folder is not a git repository (.git was not found):`n$TargetDir" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        exit 1
    }

    $source = Join-Path $PSScriptRoot 'build'
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        Show-Message "Report template was not found:`n$source" ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    $git = Find-Git
    if (-not $git) {
        Show-Message 'git.exe was not found. Install Git for Windows and try again.' ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    $dest = Join-Path $TargetDir 'assayo'
    Write-Host "Copying report files to $dest"
    & robocopy.exe $source $dest /E /R:1 /W:1 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    if ($LASTEXITCODE -ge 8) {
        Show-Message "Could not copy the report folder (robocopy exit $LASTEXITCODE)." ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    Write-Host 'Reading git history...'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $git
    $psi.Arguments = '--no-pager log --raw --numstat --oneline --all --reverse --date=iso-strict --pretty=format:%ad>%aN>%aE>%s'
    $psi.WorkingDirectory = $TargetDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.StandardErrorEncoding = New-Object System.Text.UTF8Encoding $false
    $psi.EnvironmentVariables['GIT_PAGER'] = ''

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void] $process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $raw = $stdoutTask.Result
    $stderr = $stderrTask.Result

    if ($process.ExitCode -ne 0) {
        $details = $stderr.Trim()
        if ([string]::IsNullOrWhiteSpace($details)) {
            $details = "git exited with code $($process.ExitCode)."
        }
        Show-Message $details ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    $logPath = Join-Path $dest 'log.txt'
    $wrapped = Convert-AssayoLog $raw
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($logPath, $wrapped, $utf8)

    $htmlPath = Join-Path $dest 'index.html'
    if (-not (Test-Path -LiteralPath $htmlPath)) {
        Show-Message "Report was written, but index.html was not found:`n$htmlPath" ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    Write-Host "Wrote $logPath"
    Start-Process -FilePath $htmlPath
    exit 0
}
catch {
    Show-Message $_.Exception.Message ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
