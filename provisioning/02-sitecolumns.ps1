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

$group = 'GD Columns'

function Ensure-FieldText {
  param([string]$InternalName, [string]$DisplayName = $InternalName)
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) { return }
  Add-PnPField -DisplayName $DisplayName -InternalName $InternalName -Type Text -Group $group -AddToDefaultView:$false | Out-Null
}

function Ensure-FieldChoice {
  param([string]$InternalName, [string]$DisplayName = $InternalName, [string[]]$Choices)
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) { return }
  Add-PnPField -DisplayName $DisplayName -InternalName $InternalName -Type Choice -Group $group -Choices $Choices -AddToDefaultView:$false | Out-Null
}

function Ensure-FieldDate {
  param([string]$InternalName, [string]$DisplayName = $InternalName)
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) { return }
  # Date only
  Add-PnPField -DisplayName $DisplayName -InternalName $InternalName -Type DateTime -Group $group -AddToDefaultView:$false | Out-Null
  # enforce DateOnly format
  Set-PnPField -Identity $InternalName -Values @{'Format'='DateOnly'} | Out-Null
}

function Ensure-FieldUser {
  param([string]$InternalName, [string]$DisplayName = $InternalName, [switch]$Multi)
  if (Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue) { return }

  Add-PnPField -DisplayName $DisplayName -InternalName $InternalName -Type User -Group $group -AddToDefaultView:$false | Out-Null
  if ($Multi) {
    Set-PnPField -Identity $InternalName -Values @{ AllowMultipleValues = $true }
  }
}

function Ensure-FieldLookupMulti {
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
    Write-Warning "List '$LookupListTitle' not found — cannot create Lookup field '$InternalName'. Run 04-library.ps1 + related_documents/04-rd-library.ps1 first."
    return
  }
  $ctx = Get-PnPContext
  # Crear campo Lookup base
  $xml = "<Field Type='Lookup' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Group='$group' Required='FALSE' List='{$($lookupList.Id)}' ShowField='$LookupField' />"
  $ctx.Web.Fields.AddFieldAsXml($xml, $false, [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue) | Out-Null
  $ctx.ExecuteQuery()
  # Activar multi-valor
  $field = Get-PnPField -Identity $InternalName
  $ctx.Load($field)
  $ctx.ExecuteQuery()
  $field.AllowMultipleValues = $true
  $field.Update()
  $ctx.ExecuteQuery()
  Write-Host "Created multi-Lookup field: $InternalName (-> $LookupListTitle.$LookupField, multi)"
}

# 3.1 Identificación
Ensure-FieldText -InternalName 'GD_Codigo' -DisplayName 'Código'
Ensure-FieldText -InternalName 'GD_NombreProcedimiento' -DisplayName 'Nombre del procedimiento'

# Auxiliar para filtros de producto
Ensure-FieldText -InternalName 'GD_ProductoLabels' -DisplayName 'Producto (texto auxiliar)'

# Core choice
Ensure-FieldChoice -InternalName 'GD_Aplicabilidad' -DisplayName 'Aplicabilidad' -Choices @('General','Por producto')
Ensure-FieldChoice -InternalName 'GD_Estatus' -DisplayName 'Estatus' -Choices @('Borrador','En revisión','Aprobado','Rechazado','Obsoleto')

# Navegación habilitadora
Ensure-FieldChoice -InternalName 'GD_TipoProceso' -DisplayName 'Tipo de proceso' -Choices @('Proceso de Manufactura','Administrativos Transversales de cada Planta')

# Ciclo de vida
Ensure-FieldText -InternalName 'GD_Version' -DisplayName 'Versión'
Ensure-FieldDate -InternalName 'GD_FechaDivulgacion' -DisplayName 'Fecha divulgación'
Ensure-FieldDate -InternalName 'GD_FechaActualizacion' -DisplayName 'Fecha actualización'
Ensure-FieldChoice -InternalName 'GD_MotivoActualizacion' -DisplayName 'Motivo actualización' -Choices @('Actualización normativa','Auditoría interna','Auditoría externa','Mejora de proceso','Cambio operativo')
Ensure-FieldDate -InternalName 'GD_VigenciaHasta' -DisplayName 'Vigencia'
Ensure-FieldDate -InternalName 'GD_FechaCaducidad' -DisplayName 'Fecha de caducidad'

# Homologación
Ensure-FieldDate -InternalName 'GD_FechaHomologacion' -DisplayName 'Fecha de homologación'

# YUM (condicional)
Ensure-FieldUser -InternalName 'GD_AprobadoPorYUM' -DisplayName 'Aprobado por YUM'
Ensure-FieldDate -InternalName 'GD_FechaVencimientoYUM' -DisplayName 'Fecha vencimiento YUM'

# Continuidad
Ensure-FieldChoice -InternalName 'GD_ImpactoContinuidad' -DisplayName 'Impacto continuidad' -Choices @('Alto','Medio','Bajo')

# Responsables
Ensure-FieldUser -InternalName 'GD_ResponsablePrincipal' -DisplayName 'Responsable principal'
Ensure-FieldUser -InternalName 'GD_RespElaboracionActualizacion' -DisplayName 'Responsable elaboración/actualización' -Multi
Ensure-FieldUser -InternalName 'GD_RespRevision' -DisplayName 'Responsable revisión' -Multi
Ensure-FieldUser -InternalName 'GD_RespAprobacion' -DisplayName 'Responsable aprobación' -Multi

# Documentos relacionados (referencia inversa, multi-valor)
# ShowField=Title => muestra el nombre del documento; href navega al DispForm del relacionado vía lookupId
Ensure-FieldLookupMulti -InternalName 'GD_DocumentosRelacionados' -DisplayName 'Documentos relacionados' `
                        -LookupListTitle 'Documentos Relacionados GD' -LookupField 'Title'

Write-Host 'Done.'