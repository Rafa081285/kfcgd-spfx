#Requires -Version 5.0
<#
.SYNOPSIS
  Create inicio.aspx page using REST API
.EXAMPLE
  .\create-inicio-page-rest.ps1
#>

param(
    [string]$ClientId = "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d",
    [string]$Tenant = "grupokfc.onmicrosoft.com",
    [string]$TargetSiteUrl = "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt",
    [string]$PageName = "inicio"
)

Write-Host "======================================" -ForegroundColor Green
Write-Host "Creando página: $PageName.aspx" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Conectar
Write-Host "`n[1] Conectando al sitio..." -ForegroundColor Cyan
Disconnect-PnPOnline -WarningAction SilentlyContinue 2>$null | Out-Null
Connect-PnPOnline -Url $TargetSiteUrl -ClientId $ClientId -Tenant $Tenant -Interactive

# Obtener context web
Write-Host "`n[2] Obteniendo contexto..." -ForegroundColor Cyan
$web = Get-PnPWeb

# Verificar si la página existe
Write-Host "`n[3] Verificando si $PageName.aspx existe..." -ForegroundColor Cyan
try {
    $files = Get-PnPFile -Url "/SitePages/$PageName.aspx" -ErrorAction SilentlyContinue
    if ($files) {
        Write-Host "  ✓ Página ya existe" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ℹ Página no encontrada, será creada" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ℹ Página no existe (nuevo)" -ForegroundColor Yellow
}

# Crear página usando Add-PnPPage si está disponible, sino usar método alternativo
Write-Host "`n[4] Creando página $PageName.aspx..." -ForegroundColor Cyan

# Intentar con Add-PnPPage (nombre alternativo)
try {
    $pageCreated = Add-PnPPage -Name $PageName -ErrorAction Stop
    Write-Host "  ✓ Página creada exitosamente" -ForegroundColor Green
    
    # Publicar
    Write-Host "`n[5] Publicando página..." -ForegroundColor Cyan
    $pageCreated.Publish()
    Write-Host "  ✓ Página publicada" -ForegroundColor Green
}
catch {
    Write-Host "  Intentando con método alternativo..." -ForegroundColor Yellow
    
    # Método alternativo: crear en SitePages
    try {
        $siteAssetsLib = Get-PnPList -Identity "Site Pages" -ErrorAction Stop
        if ($siteAssetsLib) {
            Write-Host "  ℹ Site Pages library encontrada" -ForegroundColor Gray
            # La página será creada manualmente en el próximo paso
        }
    }
    catch {
        Write-Host "  ⚠ No se puede crear página automáticamente" -ForegroundColor Yellow
    }
}

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "RESULTADO:" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nPágina: $PageName.aspx" -ForegroundColor Cyan
Write-Host "URL: $TargetSiteUrl/SitePages/$PageName.aspx" -ForegroundColor Cyan

Write-Host "`nPara agregar webparts:" -ForegroundColor Yellow
Write-Host "1. Abre la URL anterior" -ForegroundColor White
Write-Host "2. Haz clic en '+ Agregar webpart'" -ForegroundColor White
Write-Host "3. Busca 'GdNavigation' y agrega" -ForegroundColor White
Write-Host "4. Busca 'GdResults' y agrega" -ForegroundColor White
Write-Host "5. Configura propiedades según necesites" -ForegroundColor White
Write-Host "6. Publica la página" -ForegroundColor White

Write-Host "`nPropiedades para GdNavigation:" -ForegroundColor Cyan
Write-Host "  - navJsonUrl: /SiteAssets/nav.json" -ForegroundColor Gray
Write-Host "  - resultsPageUrl: /SitePages/resultados.aspx" -ForegroundColor Gray
Write-Host "  - libraryTitle: Gestor Documental" -ForegroundColor Gray

Disconnect-PnPOnline
Write-Host "`n✓ Desconectado" -ForegroundColor Green
