[CmdletBinding()]
param(
    [string] $SqlServer = 'localhost',
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,127}$')]
    [string] $DatabaseName = 'BlueStock'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
$caseRoot = Join-Path $root 'database\tests\concurrency'
$setup = Join-Path $caseRoot 'setup_outbound.sql'
$firstFile = Join-Path $caseRoot 'post_first.sql'
$secondFile = Join-Path $caseRoot 'post_second.sql'
$assert = Join-Path $caseRoot 'assert_cleanup_outbound.sql'
$runId = [guid]::NewGuid().ToString('N')
$firstOutput = Join-Path $env:TEMP "bluestock-concurrency-$runId-first.log"
$secondOutput = Join-Path $env:TEMP "bluestock-concurrency-$runId-second.log"
$firstError = Join-Path $env:TEMP "bluestock-concurrency-$runId-first.err"
$secondError = Join-Path $env:TEMP "bluestock-concurrency-$runId-second.err"
$firstRun = Join-Path $env:TEMP "bluestock-concurrency-$runId-first.sql"
$secondRun = Join-Path $env:TEMP "bluestock-concurrency-$runId-second.sql"

& $sqlcmd -S $SqlServer -E -C -b -d $DatabaseName -i $setup
if ($LASTEXITCODE -ne 0) { throw 'Không tạo được fixture concurrency.' }

$first = $null
$second = $null
$runError = $null
try {
    $startAt = (Get-Date).AddSeconds(3).ToString('HH:mm:ss')
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($firstRun,
        (Get-Content -LiteralPath $firstFile -Raw -Encoding UTF8).Replace('$(StartAt)', $startAt),
        $encoding)
    [System.IO.File]::WriteAllText($secondRun,
        (Get-Content -LiteralPath $secondFile -Raw -Encoding UTF8).Replace('$(StartAt)', $startAt),
        $encoding)
    $firstArgs = '-S "{0}" -E -C -b -d "{1}" -i "{2}"' -f $SqlServer, $DatabaseName, $firstRun
    $secondArgs = '-S "{0}" -E -C -b -d "{1}" -i "{2}"' -f $SqlServer, $DatabaseName, $secondRun
    $first = Start-Process -FilePath $sqlcmd -ArgumentList $firstArgs -WorkingDirectory $root `
        -WindowStyle Hidden -RedirectStandardOutput $firstOutput `
        -RedirectStandardError $firstError -PassThru
    $second = Start-Process -FilePath $sqlcmd -ArgumentList $secondArgs -WorkingDirectory $root `
        -WindowStyle Hidden -RedirectStandardOutput $secondOutput `
        -RedirectStandardError $secondError -PassThru
    if (-not $first.WaitForExit(30000) -or -not $second.WaitForExit(30000)) {
        throw 'Hai phiên SQL vượt thời gian chờ 30 giây.'
    }
    $first.Refresh()
    $second.Refresh()
    Write-Host "Phiên CNC001 exit=$($first.ExitCode):"
    Get-Content -LiteralPath $firstOutput
    Write-Host "Phiên CNC002 exit=$($second.ExitCode):"
    Get-Content -LiteralPath $secondOutput
    if ($first.ExitCode -ne 0 -or $second.ExitCode -ne 0) {
        Get-Content -LiteralPath $firstError, $secondError
        throw 'Một phiên SQL thất bại ngoài lỗi thiếu tồn mong đợi.'
    }
}
catch {
    $runError = $_
}
finally {
    foreach ($process in @($first, $second)) {
        if ($null -ne $process -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
    }
    & $sqlcmd -S $SqlServer -E -C -b -d $DatabaseName -i $assert
    if ($LASTEXITCODE -ne 0) {
        throw 'Đối chiếu hoặc dọn fixture concurrency thất bại.'
    }
}

if ($null -ne $runError) { throw $runError }
