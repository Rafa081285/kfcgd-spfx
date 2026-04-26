<#
.SYNOPSIS
  Agrega el Content Type "GD – Relacionado" a la biblioteca de documentos.
.DESCRIPTION
  - Conecta con -Interactive
  - Verifica que la biblioteca exista (debe haber sido creada por ../04-library.ps1)
  - Habilita Content Types en la biblioteca (idempotente)
  - Agrega el CT "GD – Relacionado" a la biblioteca si no está ya presente
  - NO elimina CTs existentes (Document, GD – PO, GD – IT)
.PARAMETER LibraryTitle
  Título de la biblioteca donde se agrega el CT.
  Por defecto: 'Gestor Documental'
  Alternativo: 'Documentos GD Generales' u otro nombre parametrizable.
.NOTES
  Ejecutar DESPUÉS de:
    ../04-library.ps1
    03-rd-contenttype.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/KFCGD',

  [string]$LibraryTitle = 'Gestor Documental'
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
Connect-PnPOnline -Url $siteUrl -Interactive

$ctName = 'GD – Relacionado'

# ─────────────────────────────────────────────────────────────────────────────
# 1) Verificar que la biblioteca existe
# ─────────────────────────────────────────────────────────────────────────────

$list = Get-PnPList -Identity $LibraryTitle -ErrorAction SilentlyContinue
if (-not $list) {
  throw "Biblioteca '$LibraryTitle' no encontrada. Ejecuta ../04-library.ps1 primero."
}
Write-Host "Library found: $LibraryTitle"

# ─────────────────────────────────────────────────────────────────────────────
# 2) Habilitar Content Types (idempotente)
# ─────────────────────────────────────────────────────────────────────────────

Set-PnPList -Identity $LibraryTitle -ContentTypesEnabled:$true | Out-Null
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
