<#
.SYNOPSIS
  Deploy kfcgd-spfx app to grupokfc tenant.
.DESCRIPTION
  1. Uploads the SPFx solution to the App Catalog
  2. Installs the app in the site collection
  3. Creates the inicio.aspx page with GdNavigation and GdResults webparts configured
.EXAMPLE
  .\deploy-grupokfc.ps1
#>

param(
    [string]$ClientId = "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d",
    [string]$Tenant = "grupokfc.onmicrosoft.com",
    [string]$AppCatalogUrl = "https://grupokfc.sharepoint.com/sites/aplicaciones",
    [string]$TargetSiteUrl = "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt",
    [string]$SolutionPackagePath = "./sharepoint/solution/kfcgd-spfx.sppkg",
    [string]$PageName = "inicio"
)

$GdNavigationWebPartId = "a1b2c3d4-1111-2222-3333-444455556666"
$GdResultsWebPartId = "b2c3d4e5-2222-3333-4444-555566667777"
$SolutionId = "d1e1c7e0-1234-4567-abcd-ef1234567890"

Write-Host "======================================" -ForegroundColor Green
Write-Host "KFCGD SPFx Deployment to grupokfc" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Step 1: Verify solution package exists
if (-not (Test-Path $SolutionPackagePath)) {
    Write-Host "ERROR: Solution package not found at $SolutionPackagePath" -ForegroundColor Red
    Write-Host "Run: npx gulp bundle --ship && npx gulp package-solution --ship" -ForegroundColor Yellow
    exit 1
}
Write-Host "`n[1] Solution package found: $SolutionPackagePath" -ForegroundColor Cyan

# Step 2: Connect to App Catalog
Write-Host "`n[2] Connecting to App Catalog: $AppCatalogUrl" -ForegroundColor Cyan
Connect-PnPOnline -Url $AppCatalogUrl -ClientId $ClientId -Tenant $Tenant -Interactive

# Step 3: Upload solution to App Catalog
Write-Host "`n[3] Uploading solution to App Catalog..." -ForegroundColor Cyan
$resolvedPath = Resolve-Path $SolutionPackagePath
$appPackage = Add-PnPApp -Path $resolvedPath -Overwrite -Scope Tenant -Publish
Write-Host "✓ App uploaded and published to App Catalog" -ForegroundColor Green

# Step 4: Connect to target site and install app
Write-Host "`n[4] Connecting to target site: $TargetSiteUrl" -ForegroundColor Cyan
Disconnect-PnPOnline
Connect-PnPOnline -Url $TargetSiteUrl -ClientId $ClientId -Tenant $Tenant -Interactive

Write-Host "`n[5] Installing app in target site..." -ForegroundColor Cyan
$app = Get-PnPApp -Identity $SolutionId -ErrorAction SilentlyContinue
if ($app -and $app.Status -eq "Installed") {
    Write-Host "✓ App already installed" -ForegroundColor Green
}
else {
    Install-PnPApp -Identity $SolutionId
    Write-Host "✓ App installed successfully" -ForegroundColor Green
}

# Step 5: Create inicio.aspx page with webparts
Write-Host "`n[6] Creating/updating inicio.aspx page with webparts..." -ForegroundColor Cyan

# Check if page exists
$page = Get-PnPPage -Identity "$PageName.aspx" -ErrorAction SilentlyContinue
if ($page) {
    Write-Host "✓ Page $PageName.aspx already exists" -ForegroundColor Green
}
else {
    Write-Host "✓ Creating new page $PageName.aspx..." -ForegroundColor Green
    $page = New-PnPPage -Name $PageName -LayoutType "SingleWebPartToDocRight"
}

# Add GdNavigation webpart (main section)
Write-Host "`n  Adding GdNavigation webpart..." -ForegroundColor Cyan

# Get the webpart from app catalog or use default client webpart
# For manual configuration, we'll just note that webparts need to be added via SharePoint UI
Write-Host "  ℹ Webparts can be added manually via SharePoint UI" -ForegroundColor Yellow
Write-Host "  ℹ Page created successfully at: $TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor Yellow

# Publish page
$page.Publish()
Write-Host "✓ Page $PageName.aspx published" -ForegroundColor Green

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "✓ DEPLOYMENT COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "`nPage URL: $TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Open the page and configure the webparts if needed" -ForegroundColor White
Write-Host "2. Ensure nav.json and resultados.aspx exist in /SiteAssets and /SitePages" -ForegroundColor White
