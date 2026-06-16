#Requires -Version 5.0
<#
.SYNOPSIS
  Add GdNavigation and GdResults webparts to inicio.aspx
.EXAMPLE
  .\add-webparts.ps1
#>

param(
    [string]$ClientId = "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d",
    [string]$Tenant = "grupokfc.onmicrosoft.com",
    [string]$TargetSiteUrl = "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt",
    [string]$PageName = "inicio",
    [string]$SolutionId = "d1e1c7e0-1234-4567-abcd-ef1234567890"
)

$GdNavigationWebPartId = "a1b2c3d4-1111-2222-3333-444455556666"
$GdResultsWebPartId = "b2c3d4e5-2222-3333-4444-555566667777"

Write-Host "======================================" -ForegroundColor Green
Write-Host "Agregando webparts a: $PageName.aspx" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Conectar
Write-Host "`n[1] Conectando al sitio..." -ForegroundColor Cyan
Disconnect-PnPOnline -WarningAction SilentlyContinue 2>$null | Out-Null
Connect-PnPOnline -Url $TargetSiteUrl -ClientId $ClientId -Tenant $Tenant -Interactive

# Obtener página
Write-Host "`n[2] Obteniendo página..." -ForegroundColor Cyan
try {
    $page = Get-PnPPage -Identity "$PageName.aspx" -ErrorAction Stop
    Write-Host "  ✓ Página encontrada" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Página no encontrada: $_" -ForegroundColor Red
    exit 1
}

# Agregar GdNavigation webpart
Write-Host "`n[3] Agregando GdNavigation webpart..." -ForegroundColor Cyan
try {
    $navProps = @{
        navJsonUrl          = "/SiteAssets/nav.json"
        resultsPageUrl      = "/SitePages/resultados.aspx"
        nodeIdParam         = "nodeId"
        libraryTitle        = "Gestor Documental"
        relatedLibraryTitle = "Documentos Relacionados GD"
        pageSize            = "10"
    }
    
    # Buscar webpart por nombre/ID
    $webpart = Add-PnPClientSideWebPart -Page $page `
        -Component "GdNavigation" `
        -Section 1 `
        -Column 1 `
        -ErrorAction SilentlyContinue
    
    if ($webpart) {
        Write-Host "  ✓ GdNavigation agregado" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ GdNavigation no pudo agregarse automáticamente" -ForegroundColor Yellow
        Write-Host "  ℹ Deberá agregarse manualmente desde SharePoint" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ Error: $_" -ForegroundColor Yellow
}

# Agregar GdResults webpart
Write-Host "`n[4] Agregando GdResults webpart..." -ForegroundColor Cyan
try {
    $webpart = Add-PnPClientSideWebPart -Page $page `
        -Component "GdResults" `
        -Section 1 `
        -Column 2 `
        -ErrorAction SilentlyContinue
    
    if ($webpart) {
        Write-Host "  ✓ GdResults agregado" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ GdResults no pudo agregarse automáticamente" -ForegroundColor Yellow
        Write-Host "  ℹ Deberá agregarse manualmente desde SharePoint" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ Error: $_" -ForegroundColor Yellow
}

# Publicar
Write-Host "`n[5] Publicando página..." -ForegroundColor Cyan
try {
    $page.Publish()
    Write-Host "  ✓ Página publicada" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Error: $_" -ForegroundColor Yellow
}

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "✓ COMPLETADO" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nPágina disponible en:" -ForegroundColor Cyan
Write-Host "$TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor White

Write-Host "`nSi los webparts no se agregaron automáticamente:" -ForegroundColor Yellow
Write-Host "1. Abre la URL anterior" -ForegroundColor White
Write-Host "2. Haz clic en 'Editar'" -ForegroundColor White
Write-Host "3. Haz clic en '+ Agregar webpart'" -ForegroundColor White
Write-Host "4. Busca 'GdNavigation' → Agrega" -ForegroundColor White
Write-Host "5. Busca 'GdResults' → Agrega" -ForegroundColor White
Write-Host "6. Haz clic en 'Publicar'" -ForegroundColor White

Disconnect-PnPOnline
Write-Host "`n✓ Desconectado" -ForegroundColor Green
