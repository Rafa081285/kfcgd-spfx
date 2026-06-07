param(
  [Parameter(Mandatory=$true)][string]$TenantUrl,
  [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',
  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

$ctGroup = 'GD Content Types'

function Ensure-ContentType {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [string]$ParentContentTypeName = 'Document'
  )

  $existing = Get-PnPContentType -Identity $Name -ErrorAction SilentlyContinue
  if ($existing) { return $existing }

  # Buscar primero por nombre; si no aparece, usar el ID estándar de Document (0x0101)
  $parent = Get-PnPContentType -Identity $ParentContentTypeName -ErrorAction SilentlyContinue
  if (-not $parent) { $parent = Get-PnPContentType -Identity '0x0101' -ErrorAction SilentlyContinue }
  if (-not $parent) { throw "Parent content type '$ParentContentTypeName' not found." }

  return Add-PnPContentType -Name $Name -ParentContentType $parent -Group $ctGroup -Description "Gestor Documental - $Name"
}

$ctPO = Ensure-ContentType -Name 'GD – PO'
$ctIT = Ensure-ContentType -Name 'GD – IT'

# Fields to link (base + taxonomy). All Required = No (default).
$fieldInternalNames = @(
  'GD_Codigo',
  'GD_NombreProcedimiento',
  'GD_ProductoLabels',
  'GD_Aplicabilidad',
  'GD_Estatus',
  'GD_TipoProceso',
  'GD_Version',
  'GD_FechaDivulgacion',
  'GD_FechaActualizacion',
  'GD_MotivoActualizacion',
  'GD_VigenciaHasta',
  'GD_FechaCaducidad',
  'GD_FechaHomologacion',
  'GD_AprobadoPorYUM',
  'GD_FechaVencimientoYUM',
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
  'GD_AmbitoPrograma',

  'GD_DocumentosRelacionados'   # referencia inversa a biblioteca Documentos Relacionados GD
)

foreach ($fname in $fieldInternalNames) {
  $f = Get-PnPField -Identity $fname -ErrorAction SilentlyContinue
  if (-not $f) {
    Write-Warning "Field '$fname' not found. Skipping linking to content types. (Run 02 + 05 first)"
    continue
  }

  Add-PnPFieldToContentType -Field $f -ContentType $ctPO -ErrorAction SilentlyContinue | Out-Null
  Add-PnPFieldToContentType -Field $f -ContentType $ctIT -ErrorAction SilentlyContinue | Out-Null
}

Write-Host 'Done.'
