[CmdletBinding()]
param(
    [switch] $WithDatabase,
    [string] $SqlServer = 'localhost'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Host '1/4 Kiểm tra file bắt buộc...'
$requiredFiles = @(
    'README.md',
    'AGENTS.md',
    'CONTRIBUTING.md',
    'apps/web/index.html',
    'apps/web/styles.css',
    'apps/web/app.js',
    'docs/README.md',
    'docs/PROJECT_CONTEXT.md',
    'docs/development/BUILD_GUIDE.md',
    'docs/architecture/SYSTEM_ARCHITECTURE.md',
    'docs/architecture/MODULE_CATALOG.md',
    'docs/requirements/BUSINESS_RULES.md',
    'docs/project/governance/BACKLOG.md',
    'docs/project/governance/WORKSTREAMS.md',
    'docs/project/governance/OPEN_DECISIONS.md',
    'contracts/BASELINE.md',
    'contracts/API_CATALOG.md',
    'contracts/session-rbac.md',
    'contracts/san-pham.md',
    'database/SCHEMA_PLAN.md',
    'database/seed/catalog_demo.sql',
    'scripts/bootstrap-admin.ps1',
    'docs/architecture/database/ERD_VA_NGHIEP_VU.md'
)
foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Thiếu file bắt buộc: $relativePath"
    }
}

Write-Host '2/4 Kiểm tra JavaScript frontend...'
$node = (Get-Command node -ErrorAction Stop).Source
& $node --check (Join-Path $root 'apps\web\app.js')
if ($LASTEXITCODE -ne 0) { throw 'JavaScript frontend không hợp lệ.' }
& $node --check (Join-Path $root 'scripts\serve-web.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Static server script không hợp lệ.' }

Write-Host '3/4 Kiểm tra liên kết Markdown nội bộ...'
$markdownRoots = @(
    (Join-Path $root 'README.md'),
    (Join-Path $root 'CONTRIBUTING.md'),
    (Join-Path $root 'AGENTS.md'),
    (Join-Path $root 'apps\web'),
    (Join-Path $root 'services'),
    (Join-Path $root 'database'),
    (Join-Path $root 'contracts'),
    (Join-Path $root 'docs')
)
$markdownFiles = foreach ($item in $markdownRoots) {
    if (Test-Path -LiteralPath $item -PathType Leaf) { Get-Item -LiteralPath $item }
    elseif (Test-Path -LiteralPath $item -PathType Container) { Get-ChildItem -LiteralPath $item -Recurse -Filter '*.md' -File }
}
$missingLinks = [System.Collections.Generic.List[string]]::new()
foreach ($file in $markdownFiles) {
    $content = Get-Content -Raw -LiteralPath $file.FullName
    foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim('<', '>')
        if ($target -match '^(https?://|mailto:|#|codex:)' -or [string]::IsNullOrWhiteSpace($target)) { continue }
        $pathOnly = [Uri]::UnescapeDataString(($target -split '#')[0])
        if ([string]::IsNullOrWhiteSpace($pathOnly)) { continue }
        $resolved = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathOnly))
        if (-not (Test-Path -LiteralPath $resolved)) {
            $missingLinks.Add("$($file.FullName): $target")
        }
    }
}
if ($missingLinks.Count -gt 0) {
    throw "Liên kết Markdown bị thiếu:`n$($missingLinks -join "`n")"
}

Write-Host '4/4 Kiểm tra module tùy chọn...'
$apiWrapper = Join-Path $root 'services\api\mvnw.cmd'
if (Test-Path -LiteralPath $apiWrapper) {
    Push-Location (Split-Path -Parent $apiWrapper)
    try {
        & $apiWrapper test
        if ($LASTEXITCODE -ne 0) { throw 'Backend test thất bại.' }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host 'Backend chưa được khởi tạo; bỏ qua Maven test.'
}

if ($WithDatabase) {
    Write-Host 'Kiểm tra ràng buộc database...'
    $sqlcmd = (Get-Command sqlcmd -ErrorAction Stop).Source
    $databaseTests = @(
        'database\tests\001_catalog_warehouse_constraints.sql',
        'database\tests\002_auth_constraints.sql',
        'database\tests\003_product_crud.sql',
        'database\tests\004_catalog_reference_crud.sql',
        'database\tests\005_warehouse_area_crud.sql',
        'database\tests\006_position_crud.sql',
        'database\tests\007_partner_constraints.sql',
        'database\tests\008_inbound_inventory_constraints.sql',
        'database\tests\009_inbound_completion.sql',
        'database\tests\010_inventory_view.sql',
        'database\tests\011_outbound_constraints.sql',
        'database\tests\012_outbound_completion.sql',
        'database\tests\013_transfer_constraints.sql',
        'database\tests\014_transfer_completion.sql',
        'database\tests\015_inventory_count_constraints.sql',
        'database\tests\016_inventory_count_completion.sql',
        'database\tests\017_return_constraints.sql',
        'database\tests\018_return_completion.sql',
        'database\tests\019_audit_constraints.sql'
    )
    foreach ($testFile in $databaseTests) {
        & $sqlcmd -S $SqlServer -E -C -b -d BlueStock -i (Join-Path $root $testFile)
        if ($LASTEXITCODE -ne 0) { throw "Database test thất bại: $testFile" }
    }
}

Write-Host 'Baseline verification passed.'
