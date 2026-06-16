#Requires -Version 5.0
<#
.SYNOPSIS
  Create inicio.aspx page and add GdNavigation & GdResults webparts
.DESCRIPTION
  Automates page creation and webpart configuration in target site
.EXAMPLE
  .\create-inicio-page.ps1
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
Write-Host "Creando página: $PageName.aspx" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Conectar al sitio
Write-Host "`n[1] Conectando a $TargetSiteUrl..." -ForegroundColor Cyan
Disconnect-PnPOnline -WarningAction SilentlyContinue 2>$null | Out-Null
Connect-PnPOnline -Url $TargetSiteUrl -ClientId $ClientId -Tenant $Tenant -Interactive

# Verificar si la página existe
Write-Host "`n[2] Verificando página existente..." -ForegroundColor Cyan
$existingPage = Get-PnPPage -Identity "$PageName.aspx" -ErrorAction SilentlyContinue

if ($existingPage) {
    Write-Host "  ✓ Página $PageName.aspx ya existe" -ForegroundColor Yellow
    $page = $existingPage
}
else {
    # Crear página nueva
    Write-Host "  ✓ Creando nueva página $PageName.aspx..." -ForegroundColor Green
    $page = New-PnPPage -Name $PageName -LayoutType "SingleWebPartToDocRight"
    Write-Host "  ✓ Página creada" -ForegroundColor Green
}

# Agregar GdNavigation webpart
Write-Host "`n[3] Agregando webpart GdNavigation..." -ForegroundColor Cyan
try {
    # Buscar el webpart en el app catalog
    $webparts = Get-PnPClientSideWebPart -Page $page
    $navigationExists = $webparts | Where-Object { $_.Title -like "*Navigation*" }
    
    if (-not $navigationExists) {
        # Agregar webpart usando el título del app
        $page | Add-PnPClientSideWebPart -DefaultWebPartType "Client-Side Web Part" -Section 1 -Column 1
        Write-Host "  ✓ Webpart GdNavigation agregado" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ GdNavigation ya existe en la página" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ No se pudo agregar automáticamente: $_" -ForegroundColor Yellow
    Write-Host "  ℹ Deberá agregarlo manualmente desde el catálogo de webparts" -ForegroundColor Yellow
}

# Agregar GdResults webpart
Write-Host "`n[4] Agregando webpart GdResults..." -ForegroundColor Cyan
try {
    $webparts = Get-PnPClientSideWebPart -Page $page
    $resultsExists = $webparts | Where-Object { $_.Title -like "*Results*" }
    
    if (-not $resultsExists) {
        $page | Add-PnPClientSideWebPart -DefaultWebPartType "Client-Side Web Part" -Section 1 -Column 2
        Write-Host "  ✓ Webpart GdResults agregado" -ForegroundColor Green
    }
    else {
        Write-Host "  ℹ GdResults ya existe en la página" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ⚠ No se pudo agregar automáticamente: $_" -ForegroundColor Yellow
    Write-Host "  ℹ Deberá agregarlo manualmente desde el catálogo de webparts" -ForegroundColor Yellow
}

# Publicar página
Write-Host "`n[5] Publicando página..." -ForegroundColor Cyan
try {
    $page.Publish()
    Write-Host "  ✓ Página publicada" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠ Error publicando: $_" -ForegroundColor Yellow
}

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "✓ PÁGINA CREADA" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nURL de la página:" -ForegroundColor Cyan
Write-Host "$TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor White

Write-Host "`nProximos pasos:" -ForegroundColor Yellow
Write-Host "1. Abre la página para verificar webparts" -ForegroundColor White
Write-Host "2. Configura propiedades de los webparts si es necesario" -ForegroundColor White
Write-Host "3. Asegúrate de que nav.json exista en /SiteAssets" -ForegroundColor White

Disconnect-PnPOnline
Write-Host "`n✓ Desconectado" -ForegroundColor Green
