param(
    [string]$TenantUrl,
    [string]$SiteRelativeUrl = '/sites/KFCGD',
    [string]$TermGroupName = 'GestorDocumentalGD'
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
        $termSet = New-PnPTermSet -Name $TermSetName -Group $GroupName -IsOpen $IsOpen
        foreach ($term in $Terms) {
            Ensure-Term $termSet $term
        }
    } else {
        Write-Host "TermSet $TermSetName already exists."
    }
}

function Ensure-Term {
    param( 
        [Microsoft.SharePoint.Client.TermStore.TermSet]$TermSet,
        [string]$Term
    )
    Write-Host "Ensuring Term: $Term"
    $existingTerm = Get-PnPTerm -Identity $Term -TermSet $TermSet -ErrorAction SilentlyContinue
    if (-not $existingTerm) {
        New-PnPTerm -Name $Term -TermSet $TermSet
    } else {
        Write-Host "Term $Term already exists."
    }
}

# Connect to PnP Online
Connect-PnPOnline -Url ($TenantUrl.TrimEnd('/') + $SiteRelativeUrl) -Interactive

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
