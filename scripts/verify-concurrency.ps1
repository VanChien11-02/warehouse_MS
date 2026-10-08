[CmdletBinding()]
param(
    [string] $SqlServer = 'localhost',
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,127}$')]
    [string] $SqlUser = '',
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,127}$')]
    [string] $DatabaseName = 'BlueStock'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
if ($SqlUser -and [string]::IsNullOrWhiteSpace($env:SQLCMDPASSWORD)) {
    throw 'Đặt SQLCMDPASSWORD trong terminal khi dùng -SqlUser.'
}
$sqlAuth = if ($SqlUser) { @('-U', $SqlUser) } else { @('-E') }
$processAuth = if ($SqlUser) { '-U "{0}"' -f $SqlUser } else { '-E' }
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

& $sqlcmd -S $SqlServer @sqlAuth -C -b -f i:65001 -d $DatabaseName -i $setup
if ($LASTEXITCODE -ne 0) { throw 'Không tạo được fixture concurrency.' }

$first = $null
$second = $null
$runError = $null
try {
    $startAt = (& $sqlcmd -S $SqlServer @sqlAuth -C -b -h -1 -W -d $DatabaseName `
        -Q "SET NOCOUNT ON; SELECT CONVERT(VARCHAR(8), DATEADD(SECOND, 3, SYSDATETIME()), 108);").Trim()
    if ($LASTEXITCODE -ne 0 -or $startAt -notmatch '^\d{2}:\d{2}:\d{2}$') {
        throw 'Không lấy được giờ hẹn từ SQL Server.'
    }
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($firstRun,
        (Get-Content -LiteralPath $firstFile -Raw -Encoding UTF8).Replace('$(StartAt)', $startAt),
        $encoding)
    [System.IO.File]::WriteAllText($secondRun,
        (Get-Content -LiteralPath $secondFile -Raw -Encoding UTF8).Replace('$(StartAt)', $startAt),
        $encoding)
    $firstArgs = '-S "{0}" {1} -C -b -f i:65001 -d "{2}" -i "{3}"' -f $SqlServer, $processAuth, $DatabaseName, $firstRun
    $secondArgs = '-S "{0}" {1} -C -b -f i:65001 -d "{2}" -i "{3}"' -f $SqlServer, $processAuth, $DatabaseName, $secondRun
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
    & $sqlcmd -S $SqlServer @sqlAuth -C -b -f i:65001 -d $DatabaseName -i $assert
    if ($LASTEXITCODE -ne 0) {
        if ($null -eq $runError) {
            $runError = [System.InvalidOperationException]::new(
                'Đối chiếu hoặc dọn fixture concurrency thất bại.')
        }
        else {
            Write-Warning 'Đối chiếu hoặc dọn fixture concurrency cũng thất bại.'
        }
    }
}

if ($null -ne $runError) { throw $runError }
