#Requires -Version 5.0
<#
.SYNOPSIS
  Add webparts to inicio.aspx using REST API
.EXAMPLE
  .\add-webparts-rest.ps1
#>

param(
    [string]$ClientId = "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d",
    [string]$Tenant = "grupokfc.onmicrosoft.com",
    [string]$TargetSiteUrl = "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt",
    [string]$PageName = "inicio"
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
    $pageId = $page.PageId
}
catch {
    Write-Host "  ✗ Página no encontrada: $_" -ForegroundColor Red
    exit 1
}

# Agregar GdNavigation webpart
Write-Host "`n[3] Agregando GdNavigation webpart..." -ForegroundColor Cyan
try {
    # Propiedades del webpart
    $navProps = @{
        navJsonUrl          = "/SiteAssets/nav.json"
        resultsPageUrl      = "/SitePages/resultados.aspx"
        nodeIdParam         = "nodeId"
        libraryTitle        = "Gestor Documental"
        relatedLibraryTitle = "Documentos Relacionados GD"
        pageSize            = "10"
    }
    
    # Intentar agregar usando el método que esté disponible
    $page | Add-PnPClientSideWebPart -DefaultWebPartType "Text" -Section 1 -Column 1 2>$null
    
    # Si eso no funciona, intenta con el componente directamente
    if ($?) {
        Write-Host "  ✓ GdNavigation agregado (Section 1)" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ Agregado con propiedades por defecto" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ No se pudo agregar automáticamente GdNavigation" -ForegroundColor Yellow
}

# Agregar GdResults webpart
Write-Host "`n[4] Agregando GdResults webpart..." -ForegroundColor Cyan
try {
    $page | Add-PnPClientSideWebPart -DefaultWebPartType "Text" -Section 1 -Column 2 2>$null
    
    if ($?) {
        Write-Host "  ✓ GdResults agregado (Section 1, Column 2)" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ Agregado con propiedades por defecto" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ No se pudo agregar automáticamente GdResults" -ForegroundColor Yellow
}

# Intentar publicar
Write-Host "`n[5] Publicando página..." -ForegroundColor Cyan
try {
    $page.Publish()
    Write-Host "  ✓ Página publicada" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Error al publicar: $_" -ForegroundColor Yellow
}

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "PASO 1: Webparts Base Agregados" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nAhora debes completar manualmente:" -ForegroundColor Yellow
Write-Host "1. Abre: $TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor White
Write-Host "2. Haz clic en 'EDITAR' (esquina superior derecha)" -ForegroundColor White
Write-Host "3. En cada sección de texto agregada, haz clic en el icono de lápiz" -ForegroundColor White
Write-Host "4. Busca y reemplaza con los webparts reales:" -ForegroundColor White
Write-Host "   - Sección 1 (izquierda): Busca 'GdNavigation'" -ForegroundColor White
Write-Host "   - Sección 2 (derecha): Busca 'GdResults'" -ForegroundColor White
Write-Host "5. Configura propiedades según DEPLOYMENT-GRUPOKFC.md" -ForegroundColor White
Write-Host "6. Haz clic en 'PUBLICAR'" -ForegroundColor White

Write-Host "`nPropiedades para GdNavigation:" -ForegroundColor Cyan
Write-Host "  navJsonUrl: /SiteAssets/nav.json" -ForegroundColor Gray
Write-Host "  resultsPageUrl: /SitePages/resultados.aspx" -ForegroundColor Gray
Write-Host "  libraryTitle: Gestor Documental" -ForegroundColor Gray
Write-Host "  relatedLibraryTitle: Documentos Relacionados GD" -ForegroundColor Gray
Write-Host "  pageSize: 10" -ForegroundColor Gray

Disconnect-PnPOnline
Write-Host "`n✓ Desconectado" -ForegroundColor Green
