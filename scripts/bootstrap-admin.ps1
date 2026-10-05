[CmdletBinding()]
param(
    [string] $Username = 'admin'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($env:SPRING_DATASOURCE_URL)) {
    throw 'Thiếu SPRING_DATASOURCE_URL. Cấu hình SQL Server trước khi tạo admin.'
}
if ([string]::IsNullOrWhiteSpace($Username) -or $Username.Length -gt 100) {
    throw 'Tên tài khoản phải có từ 1 đến 100 ký tự.'
}

$securePassword = Read-Host 'Mật khẩu admin mới (ít nhất 12 ký tự)' -AsSecureString
$plainPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
if ($plainPassword.Length -lt 12) {
    throw 'Mật khẩu admin phải có ít nhất 12 ký tự.'
}

try {
    $env:APP_BOOTSTRAP_ADMIN_ENABLED = 'true'
    $env:APP_BOOTSTRAP_ADMIN_USERNAME = $Username
    $env:APP_BOOTSTRAP_ADMIN_PASSWORD = $plainPassword
    pwsh -File (Join-Path $PSScriptRoot 'dev.ps1') -Target api
    exit $LASTEXITCODE
}
finally {
    Remove-Item Env:APP_BOOTSTRAP_ADMIN_ENABLED -ErrorAction SilentlyContinue
    Remove-Item Env:APP_BOOTSTRAP_ADMIN_USERNAME -ErrorAction SilentlyContinue
    Remove-Item Env:APP_BOOTSTRAP_ADMIN_PASSWORD -ErrorAction SilentlyContinue
    $plainPassword = $null
}
