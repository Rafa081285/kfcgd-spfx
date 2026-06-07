<#
.SYNOPSIS
  Marca como obligatorios los campos de GD – PO y GD – IT en la biblioteca Gestor Documental.
.DESCRIPTION
  Establece Required=$true en el nivel de lista para todos los campos excepto:
    - Campos de fecha (GD_FechaDivulgacion, GD_FechaActualizacion, GD_VigenciaHasta,
      GD_FechaCaducidad, GD_FechaHomologacion, GD_FechaVencimientoYUM)
    - GD_DocumentosRelacionados  (referencia inversa, se rellena a posteriori)
    - GD_VisualizacionDocumento  (auxiliar, puede estar vacía)
    - GD_ProductoLabels          (auxiliar de filtro interno)
.PARAMETER TenantUrl
  URL raíz del tenant (ej: https://tenant.sharepoint.com)
.PARAMETER SiteRelativeUrl
  URL relativa al sitio. Por defecto: /sites/ecu-devgestioncalidadplt
.PARAMETER LibraryTitle
  Nombre de la biblioteca principal. Por defecto: Gestor Documental
#>

param(
  [Parameter(Mandatory=$true)][string]$TenantUrl,
  [string]$SiteRelativeUrl  = '/sites/ecu-devgestioncalidadplt',
  [string]$LibraryTitle     = 'Gestor Documental',
  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

# ---------------------------------------------------------------------------
# Campos que NO se marcan como requeridos
# ---------------------------------------------------------------------------
$skip = @(
  # Fechas
  'GD_FechaDivulgacion',
  'GD_FechaActualizacion',
  'GD_VigenciaHasta',
  'GD_FechaCaducidad',
  'GD_FechaHomologacion',
  'GD_FechaVencimientoYUM',
  # Opcionales / auxiliares
  'GD_DocumentosRelacionados',
  'GD_VisualizacionDocumento',
  'GD_ProductoLabels'
)

# ---------------------------------------------------------------------------
# Campos a marcar como requeridos (todos los del CT excepto los de $skip)
# ---------------------------------------------------------------------------
$required = @(
  'GD_Codigo',
  'GD_NombreProcedimiento',
  'GD_Aplicabilidad',
  'GD_Estatus',
  'GD_TipoProceso',
  'GD_Version',
  'GD_MotivoActualizacion',
  'GD_AprobadoPorYUM',
  'GD_ImpactoContinuidad',
  'GD_ResponsablePrincipal',
  'GD_RespElaboracionActualizacion',
  'GD_RespRevision',
  'GD_RespAprobacion',
  'GD_Categoria',
  'GD_Alcance',
  'GD_Confidencialidad',
  'GD_PlantasAplicables',
  'GD_HomologacionPlanta',
  'GD_Producto',
  'GD_DepartamentoResponsable',
  'GD_CargoLiderPO',
  'GD_AmbitoPrograma'
)

# ---------------------------------------------------------------------------
# Aplicar Required en el nivel de lista
# ---------------------------------------------------------------------------
foreach ($fname in $required) {
  $field = Get-PnPField -List $LibraryTitle -Identity $fname -ErrorAction SilentlyContinue
  if (-not $field) {
    Write-Warning "Campo '$fname' no encontrado en '$LibraryTitle'. Saltando."
    continue
  }
  if ($field.Required) {
    Write-Host "Ya requerido (skip): $fname"
    continue
  }
  Set-PnPField -List $LibraryTitle -Identity $fname -Values @{ Required = $true } | Out-Null
  Write-Host "Required = true : $fname"
}

Write-Host "`nDone." -ForegroundColor Green
