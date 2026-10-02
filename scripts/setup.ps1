[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-MajorVersion {
    param(
        [Parameter(Mandatory)] [string] $Command,
        [Parameter(Mandatory)] [string[]] $Arguments,
        [Parameter(Mandatory)] [string] $Pattern
    )

    $output = (& $Command @Arguments 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $output -notmatch $Pattern) {
        throw "Không đọc được phiên bản $Command. Output: $output"
    }

    return [int] $Matches[1]
}

function Require-Command {
    param([Parameter(Mandatory)] [string] $Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Thiếu '$Name'. Hãy cài đặt rồi chạy lại setup."
    }

    return $command.Source
}

$git = Require-Command 'git'
$pwsh = Require-Command 'pwsh'
$node = Require-Command 'node'
$java = Require-Command 'java'

$pwshMajor = Get-MajorVersion -Command $pwsh -Arguments @('--version') -Pattern '(\d+)\.'
$nodeMajor = Get-MajorVersion -Command $node -Arguments @('--version') -Pattern 'v(\d+)\.'
$javaMajor = Get-MajorVersion -Command $java -Arguments @('--version') -Pattern '(\d+)(?:\.|\s)'

if ($pwshMajor -lt 7) { throw "Cần PowerShell 7 trở lên. Phiên bản hiện tại: $pwshMajor." }
if ($nodeMajor -lt 22) { throw "Cần Node.js 22 trở lên. Phiên bản hiện tại: $nodeMajor." }
if ($javaMajor -lt 21) { throw "Cần JDK 21 trở lên. Phiên bản hiện tại: $javaMajor." }

Write-Host "Git: $(& $git --version)"
Write-Host "PowerShell: $(& $pwsh --version)"
Write-Host "Node.js: $(& $node --version)"
Write-Host "Java: $((& $java --version 2>&1 | Select-Object -First 1))"

$webPackage = Join-Path $PSScriptRoot '..\apps\web\package.json'
if (Test-Path -LiteralPath $webPackage) {
    $npm = Require-Command 'npm.cmd'
    $webRoot = Split-Path -Parent $webPackage
    $lockFile = Join-Path $webRoot 'package-lock.json'
    Push-Location $webRoot
    try {
        if (Test-Path -LiteralPath $lockFile) {
            & $npm ci
        }
        else {
            & $npm install
        }
        if ($LASTEXITCODE -ne 0) { throw 'Cài dependency frontend thất bại.' }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host 'Frontend hiện là static baseline; không có dependency npm cần cài.'
}

Write-Host 'Setup hoàn tất. Chạy: pwsh -File scripts/dev.ps1 -Target web'
