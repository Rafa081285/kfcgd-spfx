<#
.SYNOPSIS
  Crea/asegura la biblioteca de Documentos relacionados y agrega el CT "GD – Relacionado".
.DESCRIPTION
  - Conecta con -Interactive
  - Crea la biblioteca si no existe
  - Habilita Content Types en la biblioteca (idempotente)
  - Agrega el CT "GD – Relacionado" a la biblioteca si no está ya presente
.PARAMETER LibraryTitle
  Título de la biblioteca de Documentos relacionados.
  Por defecto: 'Documentos Relacionados GD'
.NOTES
  Ejecutar DESPUÉS de:
    03-rd-contenttype.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',

  [string]$LibraryTitle = 'Documentos Relacionados GD',

  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

$ctName = 'GD – Relacionado'

# ─────────────────────────────────────────────────────────────────────────────
# 1) Crear biblioteca si no existe
# ─────────────────────────────────────────────────────────────────────────────

$list = Get-PnPList -Identity $LibraryTitle -ErrorAction SilentlyContinue
if (-not $list) {
  New-PnPList -Title $LibraryTitle -Template DocumentLibrary | Out-Null
  Write-Host "Library created: $LibraryTitle"
} else {
  Write-Host "Library already exists: $LibraryTitle"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2) Habilitar Content Types (idempotente)
# ─────────────────────────────────────────────────────────────────────────────

Set-PnPList -Identity $LibraryTitle -EnableContentTypes $true | Out-Null
Write-Host "Content Types enabled on library."

# ─────────────────────────────────────────────────────────────────────────────
# 3) Verificar CT a nivel de sitio
# ─────────────────────────────────────────────────────────────────────────────

$ct = Get-PnPContentType -Identity $ctName -ErrorAction SilentlyContinue
if (-not $ct) {
  throw "Content Type '$ctName' no encontrado en el sitio. Ejecuta 03-rd-contenttype.ps1 primero."
}

# ─────────────────────────────────────────────────────────────────────────────
# 4) Agregar CT a la biblioteca (idempotente)
# ─────────────────────────────────────────────────────────────────────────────

Add-PnPContentTypeToList -List $LibraryTitle -ContentType $ctName -ErrorAction SilentlyContinue | Out-Null
Write-Host "Ensured CT in library: $ctName"

Write-Host ""
Write-Host "OK. Library '$LibraryTitle' ready with Content Type '$ctName'."
