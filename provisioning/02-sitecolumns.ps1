param(
    [Parameter(Mandatory=$true)]
    [string] $TenantUrl,
    [string] $SiteRelativeUrl = '/sites/KFCGD'
)

$fullUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
Connect-PnPOnline -Url $fullUrl -Interactive

$fields = @(
    @{ Name = 'GD_Codigo'; Type = 'Text' },
    @{ Name = 'GD_NombreProcedimiento'; Type = 'Text' },
    @{ Name = 'GD_ProductoLabels'; Type = 'Text' },
    @{ Name = 'GD_Aplicabilidad'; Type = 'Choice'; Choices = @('General', 'Por producto') },
    @{ Name = 'GD_Estatus'; Type = 'Choice'; Choices = @('Borrador', 'En revisión', 'Aprobado', 'Rechazado', 'Obsoleto') },
    @{ Name = 'GD_TipoProceso'; Type = 'Choice'; Choices = @('Proceso de Manufactura', 'Administrativos Transversales de cada Planta') },
    @{ Name = 'GD_Version'; Type = 'Text' },
    @{ Name = 'GD_FechaDivulgacion'; Type = 'DateOnly' },
    @{ Name = 'GD_FechaActualizacion'; Type = 'DateOnly' },
    @{ Name = 'GD_MotivoActualizacion'; Type = 'Choice'; Choices = @('Actualización normativa', 'Auditoría interna', 'Auditoría externa', 'Mejora de proceso', 'Cambio operativo') },
    @{ Name = 'GD_VigenciaHasta'; Type = 'DateOnly' },
    @{ Name = 'GD_FechaCaducidad'; Type = 'DateOnly' },
    @{ Name = 'GD_FechaHomologacion'; Type = 'DateOnly' },
    @{ Name = 'GD_AprobadoPorYUM'; Type = 'User' },
    @{ Name = 'GD_FechaVencimientoYUM'; Type = 'DateOnly' },
    @{ Name = 'GD_ImpactoContinuidad'; Type = 'Choice'; Choices = @('Alto', 'Medio', 'Bajo') },
    @{ Name = 'GD_ResponsablePrincipal'; Type = 'User' },
    @{ Name = 'GD_RespElaboracionActualizacion'; Type = 'UserMulti' },
    @{ Name = 'GD_RespRevision'; Type = 'UserMulti' },
    @{ Name = 'GD_RespAprobacion'; Type = 'UserMulti' }
)

foreach ($field in $fields) {
    $fieldXml = "<Field Type='" + $field.Type + "' Name='" + $field.Name + "' ID='{GUID}' DisplayName='" + $field.Name + "' Required='FALSE' Group='GD Columns' />"
    try {
        Add-PnPFieldFromXml -FieldXml $fieldXml
    } catch {
        Write-Host "Field '$($field.Name)' already exists. Skipping..."
    }
}