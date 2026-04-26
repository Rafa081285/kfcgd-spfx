<#
.SYNOPSIS
  Crea/asegura el Content Type "GD – Relacionado" a nivel de sitio.
.DESCRIPTION
  - Conecta con -Interactive
  - Crea CT "GD – Relacionado" heredando de Document si no existe
  - Enlaza todos los campos requeridos:
      · Campos reutilizados de Documentos generales (02-sitecolumns + 05-taxonomyfields)
      · Campos nuevos de Documentos relacionados (01-rd-sitecolumns + 02-rd-taxonomyfield)
.NOTES
  Ejecutar DESPUÉS de:
    ../02-sitecolumns.ps1
    ../05-taxonomyfields.ps1
    01-rd-sitecolumns.ps1
    02-rd-taxonomyfield.ps1
  Ejecutar ANTES de: 04-rd-library.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/KFCGD'
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
Connect-PnPOnline -Url $siteUrl -Interactive

$ctGroup  = 'GD Content Types'
$ctName   = 'GD – Relacionado'

# ─────────────────────────────────────────────────────────────────────────────
# 1) Crear / obtener Content Type
# ─────────────────────────────────────────────────────────────────────────────

$existing = Get-PnPContentType -Identity $ctName -ErrorAction SilentlyContinue
if ($existing) {
  Write-Host "Content Type exists (skip create): $ctName"
  $ct = $existing
} else {
  $parent = Get-PnPContentType -Identity 'Document' -ErrorAction SilentlyContinue
  if (-not $parent) {
    throw "Parent Content Type 'Document' not found. Verify site."
  }
  $ct = New-PnPContentType `
    -Name            $ctName `
    -ParentContentType $parent `
    -Group           $ctGroup `
    -Description     'Gestor Documental – Documentos relacionados'
  Write-Host "Created Content Type: $ctName"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2) Campos a enlazar al CT
#    Orden: identificación → tipo/aplicabilidad → plantas/líneas →
#           ciclo de vida → responsables → estatus → YUM → enlace GD
# ─────────────────────────────────────────────────────────────────────────────

$fieldInternalNames = @(
  # ── Identificación ──────────────────────────────────────────────────────
  'GD_Codigo',                        # reutilizado (02-sitecolumns)
  'GD_Nomenclatura',                  # nuevo       (01-rd-sitecolumns)
  'GD_NombreProcedimiento',           # reutilizado (02-sitecolumns)

  # ── Tipo documental / aplicabilidad ─────────────────────────────────────
  'GD_Aplicabilidad',                 # reutilizado — Choice: General / Por producto
  'GD_NombreDocumentoHomologado',     # nuevo       (01-rd-sitecolumns)

  # ── Visualización del documento ──────────────────────────────────────────
  'GD_VisualizacionDocumento',        # nuevo       (01-rd-sitecolumns) — URL

  # ── Alcance geográfico y de proceso ─────────────────────────────────────
  'GD_PlantasAplicables',             # reutilizado (05-taxonomyfields) — MM multi
  'GD_LineaProceso',                  # nuevo       (02-rd-taxonomyfield) — MM multi

  # ── Ciclo de vida ────────────────────────────────────────────────────────
  'GD_Version',                       # reutilizado (02-sitecolumns)
  'GD_VigenciaHasta',                 # reutilizado (02-sitecolumns) — Vigencia
  'GD_FechaEmision',                  # nuevo       (01-rd-sitecolumns)
  'GD_FechaActualizacion',            # reutilizado (02-sitecolumns)
  'GD_FechaCaducidad',                # reutilizado (02-sitecolumns)

  # ── Responsables ─────────────────────────────────────────────────────────
  'GD_RespElaboracionActualizacion',  # reutilizado (02-sitecolumns) — People multi

  # ── Estatus ──────────────────────────────────────────────────────────────
  'GD_Estatus',                       # reutilizado (02-sitecolumns) — Choice

  # ── YUM ──────────────────────────────────────────────────────────────────
  'GD_AprobadoPorYUM',                # reutilizado (02-sitecolumns)
  'GD_FechaVencimientoYUM',           # reutilizado (02-sitecolumns)

  # ── Enlace al Documento General relacionado ──────────────────────────────
  'GD_DocumentoGeneral'               # nuevo       (01-rd-sitecolumns) — URL
)

# ─────────────────────────────────────────────────────────────────────────────
# 3) Enlazar campos al CT
# ─────────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── Enlazando campos al Content Type '$ctName' ──"
foreach ($fname in $fieldInternalNames) {
  $f = Get-PnPField -Identity $fname -ErrorAction SilentlyContinue
  if (-not $f) {
    Write-Warning "  Field '$fname' no encontrado — se omite. Verifica que los scripts previos se ejecutaron."
    continue
  }
  Add-PnPFieldToContentType -Field $f -ContentType $ct -ErrorAction SilentlyContinue | Out-Null
  Write-Host "  Linked: $fname"
}

Write-Host ""
Write-Host "OK. Content Type '$ctName' ready."
