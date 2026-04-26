<powershell>
param(
  [Parameter(Mandatory=$true)][string]$TenantUrl,
  [string]$SiteRelativeUrl = '/sites/KFCGD'
)

$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
Connect-PnPOnline -Url $siteUrl -Interactive

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

  $multAttr = if ($Multi) { " Mult=\"TRUE\"" } else { "" }
  $xml = "<Field Type=\"User\" Name=\"$InternalName\" DisplayName=\"$DisplayName\" Group=\"$group\" Required=\"FALSE\" UserSelectionMode=\"PeopleOnly\" UserSelectionScope=\"0\"$multAttr />"
  Add-PnPFieldFromXml -FieldXml $xml | Out-Null
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

Write-Host 'Done.'
</powershell>