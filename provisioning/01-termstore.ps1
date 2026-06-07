param(
    [string]$TenantUrl,
    [string]$SiteRelativeUrl = '/sites/ecu-devgestioncalidadplt',
    [string]$TermGroupName = 'GestorDocumentalGD',
    [string]$ClientId,
    [string]$Tenant
)

function Ensure-TermSet {
    param( 
        [string]$GroupName, 
        [string]$TermSetName, 
        [bool]$IsOpen,
        [string[]]$Terms
    )
    Write-Host "Ensuring TermSet: $TermSetName"
    $termSet = Get-PnPTermSet -Identity $TermSetName -TermGroup $GroupName -ErrorAction SilentlyContinue
    if (-not $termSet) {
        if ($IsOpen) {
            $termSet = New-PnPTermSet -Name $TermSetName -TermGroup $GroupName -IsOpen
        } else {
            $termSet = New-PnPTermSet -Name $TermSetName -TermGroup $GroupName
        }
        foreach ($term in $Terms) {
            Ensure-Term $termSet $GroupName $term
        }
    } else {
        Write-Host "TermSet $TermSetName already exists."
    }
}

function Ensure-Term {
    param( 
        [object]$TermSet,
        [string]$GroupName,
        [string]$Term
    )
    Write-Host "Ensuring Term: $Term"
    $existingTerm = Get-PnPTerm -Identity $Term -TermSet $TermSet -TermGroup $GroupName -ErrorAction SilentlyContinue
    if (-not $existingTerm) {
        New-PnPTerm -Name $Term -TermSet $TermSet -TermGroup $GroupName
    } else {
        Write-Host "Term $Term already exists."
    }
}

# Connect to PnP Online
$connectParams = @{
    Url         = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
    Interactive = $true
}
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
#Connect-PnPOnline @connectParams

# Ensure Term Store Group
$termGroup = Get-PnPTermGroup -Identity $TermGroupName -ErrorAction SilentlyContinue
if (-not $termGroup) {
    $termGroup = New-PnPTermGroup -Name $TermGroupName
}

# Ensure Term Sets and Seed Terms
Ensure-TermSet 'GestorDocumentalGD' 'GD - Categoria' $false @('Transversales Ecuador (Manufactura)', 'Transversales Ecuador (Administrativos)', 'Regional de Manufactura', 'Franquicias')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Alcance' $false @('Regional', 'Nacional')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Confidencialidad' $false @('Interno', 'Confidencial', 'Confidencial YUM')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Plantas y Centros' $false @('Ecuador')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Producto - Familia - SKU' $false @('Pollos', 'Vegetales', 'Cárnicos', 'Pastelería', 'Cocina', 'Hamburguesas')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Areas - Departamentos' $false @('Calidad', 'Mantenimiento', 'Mantenimiento / Calidad', 'Legal')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Cargos - Roles' $false @('Coordinador de Gestión Documental', 'Jefe de Mantenimiento', 'Supervisora laboratorio')
Ensure-TermSet 'GestorDocumentalGD' 'GD - Ambito - Programa' $false @('KFC YUM', 'KFC REGIONAL', 'KFC AUDITORIAS YUM', 'ECUADOR: MARCAS NACIONALES')
