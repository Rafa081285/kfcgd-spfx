#Requires -Version 5.0
<#
.SYNOPSIS
  Simple deployment script for kfcgd-spfx to grupokfc tenant - Part 2 (App Installation)
.DESCRIPTION
  After uploading to App Catalog, this installs the app in the target site collection
.EXAMPLE
  .\deploy-grupokfc-v2.ps1
#>

param(
    [string]$ClientId = "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d",
    [string]$Tenant = "grupokfc.onmicrosoft.com",
    [string]$TargetSiteUrl = "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt",
    [string]$SolutionId = "d1e1c7e0-1234-4567-abcd-ef1234567890"
)

Write-Host "======================================" -ForegroundColor Green
Write-Host "KFCGD SPFx - Paso 2: Instalar en Sitio" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Asegurarse que está desconectado
Write-Host "`n[1] Desconectando sesiones previas..." -ForegroundColor Cyan
Disconnect-PnPOnline -WarningAction SilentlyContinue 2>$null | Out-Null

# Conectar al sitio de destino
Write-Host "`n[2] Conectando a sitio de destino: $TargetSiteUrl" -ForegroundColor Cyan
Connect-PnPOnline -Url $TargetSiteUrl -ClientId $ClientId -Tenant $Tenant -Interactive

# Instalar la app
Write-Host "`n[3] Instalando app en el sitio..." -ForegroundColor Cyan
try {
    $app = Get-PnPApp -Identity $SolutionId -ErrorAction SilentlyContinue
    if ($app) {
        Write-Host "  ℹ App encontrada en el catálogo" -ForegroundColor Yellow
        
        # Verificar si ya está instalada
        $installedApp = Get-PnPApp -Scope Site -Identity $SolutionId -ErrorAction SilentlyContinue
        if ($installedApp) {
            Write-Host "  ✓ App ya instalada en este sitio" -ForegroundColor Green
        }
        else {
            Install-PnPApp -Identity $SolutionId -Scope Site
            Write-Host "  ✓ App instalada exitosamente" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  ✗ App no encontrada en el catálogo" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ✗ Error durante instalación: $_" -ForegroundColor Red
}

# Crear página (opcional)
Write-Host "`n[4] Información sobre la página..." -ForegroundColor Cyan
Write-Host "  ℹ Para crear la página 'inicio.aspx', abra SharePoint manualmente:" -ForegroundColor Yellow
Write-Host "  ℹ 1. Vaya a $TargetSiteUrl" -ForegroundColor White
Write-Host "  ℹ 2. Crear nueva página 'inicio'" -ForegroundColor White
Write-Host "  ℹ 3. Agregar webparts 'GdNavigation' y 'GdResults'" -ForegroundColor White
Write-Host "  ℹ 4. Configurar propiedades según DEPLOYMENT-GRUPOKFC.md" -ForegroundColor White

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "✓ INSTALACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "`nURLs importantes:" -ForegroundColor Cyan
Write-Host "- Sitio: $TargetSiteUrl" -ForegroundColor White
Write-Host "- Página (para crear): $TargetSiteUrl/SitePages/inicio.aspx" -ForegroundColor White

Disconnect-PnPOnline
