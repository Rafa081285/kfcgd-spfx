<#
.SYNOPSIS
  Crea/asegura las columnas de sitio nuevas para el tipo documental "Documentos relacionados".
.DESCRIPTION
  - Conecta con -Interactive
  - Crea únicamente los campos que NO existen ya en el sitio (idempotente)
  - Nuevos campos específicos de "Documentos relacionados":
      GD_Nomenclatura, GD_NombreDocumentoHomologado, GD_VisualizacionDocumento,
      GD_DocumentoGeneral, GD_FechaEmision
  - Los campos reutilizados de "Documentos generales" (GD_Codigo, GD_Estatus, etc.)
    ya deben existir (creados por ../02-sitecolumns.ps1).
.NOTES
  Ejecutar DESPUÉS de ../04-library.ps1 (necesario para el campo Lookup GD_DocumentoGeneral)
  Ejecutar DESPUÉS de ../02-sitecolumns.ps1
  Ejecutar ANTES  de 03-rd-contenttype.ps1
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$TenantUrl,

  [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',

  [string]$LibraryTitle = 'Gestor Documental',

  [string]$ClientId,
  [string]$Tenant
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

$group = 'GD Columns'

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

function Ensure-FieldText {
  param(
    [Parameter(Mandatory=$true)][string]$InternalName,
    [Parameter(Mandatory=$true)][string]$DisplayName
  )
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) {
    Write-Host "Field exists (skip): $InternalName"
    return
  }
  Add-PnPField -DisplayName $DisplayName -InternalName $InternalName -Type Text `
    -Group $group -AddToDefaultView:$false | Out-Null
  Write-Host "Created text field:   $InternalName"
}

function Ensure-FieldDate {
  param(
    [Parameter(Mandatory=$true)][string]$InternalName,
    [Parameter(Mandatory=$true)][string]$DisplayName
  )
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) {
    Write-Host "Field exists (skip): $InternalName"
    return
  }
  $ctx = Get-PnPContext
  $xml = "<Field Type='DateTime' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Group='$group' Required='FALSE' Format='DateOnly' />"
  $ctx.Web.Fields.AddFieldAsXml($xml, $false, [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue) | Out-Null
  $ctx.ExecuteQuery()
  Write-Host "Created date field:   $InternalName"
}

function Ensure-FieldUrl {
  param(
    [Parameter(Mandatory=$true)][string]$InternalName,
    [Parameter(Mandatory=$true)][string]$DisplayName
  )
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) {
    Write-Host "Field exists (skip): $InternalName"
    return
  }
  $ctx = Get-PnPContext
  $xml = "<Field Type='URL' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Group='$group' Required='FALSE' Format='Hyperlink' />"
  $ctx.Web.Fields.AddFieldAsXml($xml, $false, [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue) | Out-Null
  $ctx.ExecuteQuery()
  Write-Host "Created URL field:    $InternalName"
}

function Ensure-FieldLookup {
  param(
    [Parameter(Mandatory=$true)][string]$InternalName,
    [Parameter(Mandatory=$true)][string]$DisplayName,
    [Parameter(Mandatory=$true)][string]$LookupListTitle,
    [string]$LookupField = 'Title'
  )
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) {
    Write-Host "Field exists (skip): $InternalName"
    return
  }
  $lookupList = Get-PnPList -Identity $LookupListTitle -ErrorAction SilentlyContinue
  if (-not $lookupList) {
    Write-Warning "List '$LookupListTitle' not found. Cannot create Lookup field '$InternalName'. Run ../04-library.ps1 first."
    return
  }
  $ctx = Get-PnPContext
  $xml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Group='$group' Required='FALSE' List='{$($lookupList.Id)}' ShowField='$LookupField' />"
  $ctx.Web.Fields.AddFieldAsXml($xml, $false, [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue) | Out-Null
  $ctx.ExecuteQuery()
  Write-Host "Created Lookup field: $InternalName (-> $LookupListTitle.$LookupField)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Nuevas columnas exclusivas de "Documentos relacionados"
# ─────────────────────────────────────────────────────────────────────────────

# Identificación extendida
Ensure-FieldText -InternalName 'GD_Nomenclatura'               -DisplayName 'Nomenclatura'
Ensure-FieldText -InternalName 'GD_NombreDocumentoHomologado'  -DisplayName 'Nombre de documento homologado'

# Visualización / acceso al documento
Ensure-FieldUrl  -InternalName 'GD_VisualizacionDocumento'     -DisplayName 'Visualización documento'

# Enlace al documento general relacionado (Lookup a la biblioteca principal)
Ensure-FieldLookup -InternalName 'GD_DocumentoGeneral' -DisplayName 'Documento general relacionado' `
                   -LookupListTitle $LibraryTitle -LookupField 'Title'

# Ciclo de vida — nueva fecha de emisión (no existe en columns base)
Ensure-FieldDate -InternalName 'GD_FechaEmision'               -DisplayName 'Fecha de emisión'

# ─────────────────────────────────────────────────────────────────────────────
# Verificación de campos reutilizados (solo aviso, no se crean aquí)
# ─────────────────────────────────────────────────────────────────────────────
$reused = @(
  'GD_Codigo', 'GD_NombreProcedimiento', 'GD_Aplicabilidad',
  'GD_Version', 'GD_VigenciaHasta', 'GD_FechaActualizacion',
  'GD_FechaCaducidad', 'GD_RespElaboracionActualizacion',
  'GD_Estatus', 'GD_AprobadoPorYUM', 'GD_FechaVencimientoYUM',
  'GD_PlantasAplicables'
)

Write-Host ""
Write-Host "── Verificando campos reutilizados de Documentos generales ──"
foreach ($fn in $reused) {
  if (Get-PnPField -Identity $fn -ErrorAction SilentlyContinue) {
    Write-Host "  OK: $fn"
  } else {
    Write-Warning "  MISSING: $fn — ejecuta ../02-sitecolumns.ps1 (y ../05-taxonomyfields.ps1) antes."
  }
}

Write-Host ""
Write-Host "OK. Site columns for 'Documentos relacionados' provisioned."
