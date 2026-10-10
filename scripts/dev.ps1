[CmdletBinding()]
param(
    [ValidateSet('web', 'api')]
    [string] $Target = 'web',
    [int] $Port = 5174
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ($Target -eq 'web') {
    $node = (Get-Command node -ErrorAction Stop).Source
    & $node (Join-Path $PSScriptRoot 'serve-web.mjs') --root (Join-Path $root 'apps\web') --port $Port
    exit $LASTEXITCODE
}

$apiRoot = Join-Path $root 'services\api'
$wrapper = Join-Path $apiRoot 'mvnw.cmd'
if (-not (Test-Path -LiteralPath $wrapper)) {
    throw 'Backend chưa được khởi tạo. Hoàn thành backlog BE-01 và thêm Maven Wrapper trước.'
}
if ([string]::IsNullOrWhiteSpace($env:SPRING_DATASOURCE_URL)) {
    throw 'Thiếu SPRING_DATASOURCE_URL. Xem services/api/README.md để cấu hình SQL Server.'
}

Push-Location $apiRoot
try {
    & $wrapper spring-boot:run
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
