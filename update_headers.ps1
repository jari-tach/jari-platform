$files = @(
    'docs/01_BUSINESS_VISION.md', 'docs/02_SYSTEM_ARCHITECTURE.md', 'docs/03_ENTERPRISE_ARCHITECTURE.md',
    'docs/04_CLEAN_ARCHITECTURE.md', 'docs/05_FOLDER_STRUCTURE.md', 'docs/06_CODING_STANDARDS.md',
    'docs/07_NAMING_CONVENTION.md', 'docs/08_UI_DESIGN_SYSTEM.md', 'docs/09_DATABASE_ARCHITECTURE.md',
    'docs/10_PRODUCT_CATALOG_ARCHITECTURE.md', 'docs/11_WHOLESALE_MARKET_ARCHITECTURE.md',
    'docs/12_DELIVERY_ENGINE.md', 'docs/13_API_ARCHITECTURE.md', 'docs/14_SECURITY_GUIDE.md',
    'docs/15_OFFLINE_GUIDE.md', 'docs/16_LOGGING_GUIDE.md', 'docs/17_ERROR_HANDLING.md',
    'docs/18_TESTING_GUIDE.md', 'docs/19_DEPLOYMENT_GUIDE.md', 'docs/20_DEVELOPMENT_ROADMAP.md',
    'docs/21_AI_ROADMAP.md', 'docs/22_SAUDI_COMPLIANCE.md', 'docs/23_CHANGELOG.md', 'docs/24_INDEX.md'
)

$old = "> **Author:** Senior Flutter Software Engineer  `n> **Related:"
$new = "> **Author:** Senior Flutter Software Engineer  `n> **Review Date:** 2026-07-23  `n> **Next Review:** 2027-01-23  `n> **Related:"

foreach ($f in $files) {
    if (Test-Path $f) {
        $content = Get-Content $f -Raw -Encoding utf8
        if ($content -match "Review Date") {
            Write-Host "SKIP (already has Review Date): $f"
        } elseif ($content.IndexOf($old) -ge 0) {
            $content = $content.Replace($old, $new)
            Set-Content $f $content -Encoding utf8
            Write-Host "UPDATED: $f"
        } else {
            Write-Host "PATTERN NOT FOUND: $f"
        }
    } else {
        Write-Host "SKIP (not found): $f"
    }
}
Write-Host "Done!"
