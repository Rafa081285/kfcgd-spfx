<#
.SYNOPSIS
  Carga masiva de metadatos del Gestor Documental a SharePoint desde un fichero Excel.
.DESCRIPTION
  Lee la hoja "Plantilla" del Excel generado por 06-generate-excel-template.ps1 y, por cada fila:
    1. Si "Ruta archivo local" tiene valor → sube el fichero a la biblioteca.
    2. Si no → busca el documento existente por "Título documento".
    3. Establece todos los metadatos (campos Text, Choice, Date, User y Taxonomy).
  Genera un CSV de log en la misma carpeta del Excel.
.PARAMETER TenantUrl
  URL del tenant, ej: https://miempresa.sharepoint.com
.PARAMETER SiteRelativeUrl
  Ruta relativa del sitio. Por defecto: /sites/ecu-devgestioncalidadplt
.PARAMETER LibraryTitle
  Nombre de la biblioteca. Por defecto: Gestor Documental
.PARAMETER ExcelPath
  Ruta al fichero Excel relleno por el usuario funcional.
.PARAMETER TermGroupName
  Nombre del Term Group. Por defecto: GestorDocumentalGD
.PARAMETER ClientId
  (Opcional) App Registration Client ID para autenticación no interactiva.
.PARAMETER Tenant
  (Opcional) Nombre del tenant (ej: miempresa.onmicrosoft.com).
.EXAMPLE
  .\07-bulk-load-excel.ps1 -TenantUrl "https://miempresa.sharepoint.com" `
      -ExcelPath "C:\Temp\plantilla-rellena.xlsx"
#>

param(
  [Parameter(Mandatory=$true)][string]$TenantUrl,
  [string]$SiteRelativeUrl   = '/sites/ecu-devgestioncalidadplt',
  [string]$LibraryTitle      = 'Gestor Documental',
  [Parameter(Mandatory=$true)][string]$ExcelPath,
  [string]$TermGroupName     = 'GestorDocumentalGD',
  [string]$ClientId,
  [string]$Tenant
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Dependencias
# ---------------------------------------------------------------------------
foreach ($mod in @('ImportExcel','PnP.PowerShell')) {
  if (-not (Get-Module -ListAvailable -Name $mod)) {
    Write-Host "Instalando módulo $mod..." -ForegroundColor Yellow
    Install-Module $mod -Scope CurrentUser -Force
  }
}
Import-Module ImportExcel -Force
Import-Module PnP.PowerShell -Force

# ---------------------------------------------------------------------------
# Log
# ---------------------------------------------------------------------------
$logPath = Join-Path (Split-Path $ExcelPath) ("bulk-load-log_{0}.csv" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$logRows = [System.Collections.Generic.List[PSObject]]::new()

function Write-Log {
  param([string]$Fila, [string]$Titulo, [string]$Estado, [string]$Detalle = '')
  $row = [PSCustomObject]@{
    Fila    = $Fila
    Titulo  = $Titulo
    Estado  = $Estado
    Detalle = $Detalle
    Hora    = (Get-Date -Format 'HH:mm:ss')
  }
  $logRows.Add($row)
  $color = if ($Estado -eq 'OK') { 'Green' } elseif ($Estado -eq 'AVISO') { 'Yellow' } else { 'Red' }
  Write-Host "[$Estado] Fila $Fila — $Titulo : $Detalle" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Conexión a SharePoint
# ---------------------------------------------------------------------------
$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
$connectParams = @{ Url = $siteUrl; Interactive = $true }
if ($ClientId) { $connectParams['ClientId'] = $ClientId }
if ($Tenant)   { $connectParams['Tenant']   = $Tenant }
Connect-PnPOnline @connectParams
Write-Host "Conectado a: $siteUrl" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Helpers — Campos de usuario
# ---------------------------------------------------------------------------
function Resolve-UserField {
  <#
    Resuelve un UPN o varios UPN (separados por ;) a los IDs de usuario de SharePoint.
    Devuelve un array de FieldUserValue (compatible con Add/Set-PnPListItem).
  #>
  param([string]$Upns)
  if ([string]::IsNullOrWhiteSpace($Upns)) { return $null }
  $result = @()
  foreach ($upn in ($Upns -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    try {
      $user = Get-PnPUser -Identity $upn -ErrorAction Stop
      $result += $user.Id
    } catch {
      Write-Warning "No se pudo resolver el usuario: $upn. Se omite."
    }
  }
  return $result
}

# ---------------------------------------------------------------------------
# Helpers — Campos de taxonomía
# ---------------------------------------------------------------------------

# Caché de términos para evitar llamadas repetidas
$termCache = @{}

function Resolve-TaxonomyTerm {
  <#
    Dado el label de un término y su TermSet, devuelve la cadena "Label|Guid"
    que PnP usa para establecer campos de Managed Metadata.
  #>
  param([string]$TermSetName, [string]$Label)
  if ([string]::IsNullOrWhiteSpace($Label)) { return $null }
  $Label = $Label.Trim()
  $cacheKey = "$TermSetName|$Label"
  if ($termCache.ContainsKey($cacheKey)) { return $termCache[$cacheKey] }

  try {
    $term = Get-PnPTermSet -Identity $TermSetName -TermGroup $TermGroupName -ErrorAction Stop |
            Get-PnPTerm -Identity $Label -ErrorAction Stop
    if (-not $term) { throw "Término no encontrado" }
    $val = "$($term.Name)|$($term.Id.ToString())"
    $termCache[$cacheKey] = $val
    return $val
  } catch {
    Write-Warning "Término '$Label' no encontrado en TermSet '$TermSetName'. Se omite."
    return $null
  }
}

function Resolve-TaxonomyMulti {
  param([string]$TermSetName, [string]$Labels)
  if ([string]::IsNullOrWhiteSpace($Labels)) { return $null }
  $result = @()
  foreach ($lbl in ($Labels -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    $val = Resolve-TaxonomyTerm -TermSetName $TermSetName -Label $lbl
    if ($val) { $result += $val }
  }
  if ($result.Count -gt 0) { return $result } else { return $null }
}

# ---------------------------------------------------------------------------
# Helpers — Fechas
# ---------------------------------------------------------------------------
function Parse-Date {
  param([object]$Value)
  if ($null -eq $Value -or [string]::IsNullOrWhiteSpace("$Value")) { return $null }
  # Si ya es DateTime (ImportExcel puede devolver DateTime directamente)
  if ($Value -is [datetime]) { return $Value }
  $str = "$Value".Trim()
  $formats = @('dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy')
  foreach ($fmt in $formats) {
    $parsed = $null
    if ([datetime]::TryParseExact($str, $fmt, $null, 'None', [ref]$parsed)) { return $parsed }
  }
  # Fallback general
  $parsed = $null
  if ([datetime]::TryParse($str, [ref]$parsed)) { return $parsed }
  Write-Warning "No se pudo parsear la fecha: '$str'"
  return $null
}

# ---------------------------------------------------------------------------
# Mapeo de cabeceras → InternalName + metadatos de campo
# ---------------------------------------------------------------------------
# Estructura: Header del Excel → @{ InternalName; Type; TermSet (opcional) }
$fieldMap = [ordered]@{
  'Tipo de contenido *'                             = @{ InternalName='_ContentType';              Type='contenttype' }
  'Ruta archivo local'                              = @{ InternalName='_FileLocalPath';             Type='control' }
  'Título documento'                                = @{ InternalName='Title';                      Type='text' }
  'Código'                                          = @{ InternalName='GD_Codigo';                  Type='text' }
  'Nombre del procedimiento'                        = @{ InternalName='GD_NombreProcedimiento';     Type='text' }
  'Aplicabilidad'                                   = @{ InternalName='GD_Aplicabilidad';           Type='choice' }
  'Tipo de proceso'                                 = @{ InternalName='GD_TipoProceso';             Type='choice' }
  'Estatus'                                         = @{ InternalName='GD_Estatus';                 Type='choice' }
  'Versión'                                         = @{ InternalName='GD_Version';                 Type='text' }
  'Fecha divulgación'                               = @{ InternalName='GD_FechaDivulgacion';        Type='date' }
  'Fecha actualización'                             = @{ InternalName='GD_FechaActualizacion';      Type='date' }
  'Motivo actualización'                            = @{ InternalName='GD_MotivoActualizacion';     Type='choice' }
  'Vigencia hasta'                                  = @{ InternalName='GD_VigenciaHasta';           Type='date' }
  'Fecha de caducidad'                              = @{ InternalName='GD_FechaCaducidad';          Type='date' }
  'Fecha de homologación'                           = @{ InternalName='GD_FechaHomologacion';       Type='date' }
  'Aprobado por YUM (UPN)'                          = @{ InternalName='GD_AprobadoPorYUM';          Type='user' }
  'Fecha vencimiento YUM'                           = @{ InternalName='GD_FechaVencimientoYUM';     Type='date' }
  'Impacto continuidad'                             = @{ InternalName='GD_ImpactoContinuidad';      Type='choice' }
  'Responsable principal (UPN)'                     = @{ InternalName='GD_ResponsablePrincipal';    Type='user' }
  'Responsable elaboración/actualización (UPN;UPN)' = @{ InternalName='GD_RespElaboracionActualizacion'; Type='user-multi' }
  'Responsable revisión (UPN;UPN)'                  = @{ InternalName='GD_RespRevision';            Type='user-multi' }
  'Responsable aprobación (UPN;UPN)'                = @{ InternalName='GD_RespAprobacion';          Type='user-multi' }
  'Categoría (término)'                             = @{ InternalName='GD_Categoria';               Type='taxonomy';       TermSet='GD - Categoria' }
  'Alcance (término)'                               = @{ InternalName='GD_Alcance';                 Type='taxonomy';       TermSet='GD - Alcance' }
  'Confidencialidad (término)'                      = @{ InternalName='GD_Confidencialidad';        Type='taxonomy';       TermSet='GD - Confidencialidad' }
  'Plantas aplicables (término;término)'            = @{ InternalName='GD_PlantasAplicables';       Type='taxonomy-multi'; TermSet='GD - Plantas y Centros' }
  'Homologación planta (término;término)'           = @{ InternalName='GD_HomologacionPlanta';      Type='taxonomy-multi'; TermSet='GD - Plantas y Centros' }
  'Producto (término;término)'                      = @{ InternalName='GD_Producto';                Type='taxonomy-multi'; TermSet='GD - Producto - Familia - SKU' }
  'Departamento responsable (término)'              = @{ InternalName='GD_DepartamentoResponsable'; Type='taxonomy';       TermSet='GD - Areas - Departamentos' }
  'Cargo líder PO (término)'                        = @{ InternalName='GD_CargoLiderPO';            Type='taxonomy';       TermSet='GD - Cargos - Roles' }
  'Ámbito/Programa (término)'                       = @{ InternalName='GD_AmbitoPrograma';          Type='taxonomy';       TermSet='GD - Ambito - Programa' }
}

# ---------------------------------------------------------------------------
# Leer Excel
# ---------------------------------------------------------------------------
if (-not (Test-Path $ExcelPath)) {
  throw "No se encuentra el fichero Excel: $ExcelPath"
}
Write-Host "Leyendo Excel: $ExcelPath" -ForegroundColor Cyan
$rows = Import-Excel -Path $ExcelPath -WorksheetName 'Plantilla' -StartRow 1

if (-not $rows -or $rows.Count -eq 0) {
  Write-Warning "La hoja 'Plantilla' no tiene filas de datos."
  exit 0
}

Write-Host "$($rows.Count) fila(s) encontrada(s)." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Procesar cada fila
# ---------------------------------------------------------------------------
$rowNum = 1  # Fila 2 del Excel = fila 0 del array, usamos índice + 2
foreach ($row in $rows) {
  $rowNum++
  $titulo  = "$($row.'Título documento')".Trim()
  $ctName  = "$($row.'Tipo de contenido *')".Trim()
  $filePath = "$($row.'Ruta archivo local')".Trim()

  # Saltar filas completamente vacías
  if ([string]::IsNullOrWhiteSpace($titulo) -and [string]::IsNullOrWhiteSpace($filePath)) {
    continue
  }

  try {
    # ------------------------------------------------------------------
    # 1. Obtener o crear el item/documento en SharePoint
    # ------------------------------------------------------------------
    $listItem = $null

    if (-not [string]::IsNullOrWhiteSpace($filePath)) {
      # Subir fichero
      if (-not (Test-Path $filePath)) {
        Write-Log -Fila $rowNum -Titulo $titulo -Estado 'ERROR' -Detalle "Fichero no encontrado: $filePath"
        continue
      }
      $fileName = Split-Path $filePath -Leaf
      if ([string]::IsNullOrWhiteSpace($titulo)) { $titulo = [System.IO.Path]::GetFileNameWithoutExtension($fileName) }

      $uploadedItem = Add-PnPFile -Path $filePath -Folder $LibraryTitle -ErrorAction Stop
      $listItem = Get-PnPListItem -List $LibraryTitle -UniqueId $uploadedItem.UniqueId -ErrorAction Stop
      Write-Log -Fila $rowNum -Titulo $titulo -Estado 'OK' -Detalle "Fichero subido: $fileName"
    } else {
      # Buscar item existente por título
      $listItem = Get-PnPListItem -List $LibraryTitle -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$titulo</Value></Eq></Where></Query></View>" -ErrorAction Stop |
                  Select-Object -First 1
      if (-not $listItem) {
        Write-Log -Fila $rowNum -Titulo $titulo -Estado 'ERROR' -Detalle "Documento no encontrado en la biblioteca con título: '$titulo'"
        continue
      }
    }

    # ------------------------------------------------------------------
    # 2. Cambiar Content Type si se especifica
    # ------------------------------------------------------------------
    if (-not [string]::IsNullOrWhiteSpace($ctName)) {
      $ct = Get-PnPContentType -Identity $ctName -ErrorAction SilentlyContinue
      if ($ct) {
        Set-PnPListItem -List $LibraryTitle -Identity $listItem.Id -ContentType $ctName -ErrorAction SilentlyContinue | Out-Null
      } else {
        Write-Log -Fila $rowNum -Titulo $titulo -Estado 'AVISO' -Detalle "Content Type '$ctName' no encontrado; se omite."
      }
    }

    # ------------------------------------------------------------------
    # 3. Construir hash de valores de metadatos
    # ------------------------------------------------------------------
    $values = @{}
    $warnings = @()

    foreach ($header in $fieldMap.Keys) {
      $meta = $fieldMap[$header]
      # Columnas de control: ya procesadas arriba
      if ($meta.Type -in @('control','contenttype')) { continue }

      $rawValue = $row.PSObject.Properties[$header].Value
      $internalName = $meta.InternalName

      # Saltar si está vacío
      if ($null -eq $rawValue -or [string]::IsNullOrWhiteSpace("$rawValue")) { continue }

      switch ($meta.Type) {
        'text' {
          $values[$internalName] = "$rawValue".Trim()
        }
        'choice' {
          $values[$internalName] = "$rawValue".Trim()
        }
        'date' {
          $d = Parse-Date $rawValue
          if ($d) { $values[$internalName] = $d }
          else    { $warnings += "Fecha no válida en '$header': $rawValue" }
        }
        'user' {
          $resolved = Resolve-UserField -Upns "$rawValue"
          if ($resolved -and $resolved.Count -gt 0) { $values[$internalName] = $resolved[0] }
          else { $warnings += "Usuario no resuelto en '$header': $rawValue" }
        }
        'user-multi' {
          $resolved = Resolve-UserField -Upns "$rawValue"
          if ($resolved -and $resolved.Count -gt 0) { $values[$internalName] = $resolved }
          else { $warnings += "Usuarios no resueltos en '$header': $rawValue" }
        }
        'taxonomy' {
          $val = Resolve-TaxonomyTerm -TermSetName $meta.TermSet -Label "$rawValue"
          if ($val) { $values[$internalName] = $val }
          else      { $warnings += "Término no resuelto en '$header': $rawValue" }
        }
        'taxonomy-multi' {
          $vals = Resolve-TaxonomyMulti -TermSetName $meta.TermSet -Labels "$rawValue"
          if ($vals) { $values[$internalName] = $vals }
          else       { $warnings += "Términos no resueltos en '$header': $rawValue" }
        }
      }
    }

    # ------------------------------------------------------------------
    # 4. Aplicar metadatos
    # ------------------------------------------------------------------
    if ($values.Count -gt 0) {
      Set-PnPListItem -List $LibraryTitle -Identity $listItem.Id -Values $values -ErrorAction Stop | Out-Null
    }

    $detail = "Metadatos establecidos: $($values.Count) campo(s)."
    if ($warnings.Count -gt 0) {
      $detail += " AVISOS: " + ($warnings -join ' | ')
      Write-Log -Fila $rowNum -Titulo $titulo -Estado 'AVISO' -Detalle $detail
    } else {
      Write-Log -Fila $rowNum -Titulo $titulo -Estado 'OK' -Detalle $detail
    }

  } catch {
    Write-Log -Fila $rowNum -Titulo $titulo -Estado 'ERROR' -Detalle $_.Exception.Message
  }
}

# ---------------------------------------------------------------------------
# Guardar log
# ---------------------------------------------------------------------------
$logRows | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Proceso finalizado." -ForegroundColor Green
Write-Host "Log guardado en: $logPath" -ForegroundColor Cyan

$ok    = ($logRows | Where-Object Estado -eq 'OK').Count
$warn  = ($logRows | Where-Object Estado -eq 'AVISO').Count
$error = ($logRows | Where-Object Estado -eq 'ERROR').Count
$summaryColor = if ($error -gt 0) { 'Red' } elseif ($warn -gt 0) { 'Yellow' } else { 'Green' }
Write-Host "Resumen: OK=$ok  AVISOS=$warn  ERRORES=$error" -ForegroundColor $summaryColor
