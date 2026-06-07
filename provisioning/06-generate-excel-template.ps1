<#
.SYNOPSIS
  Genera la plantilla Excel para carga masiva de metadatos del Gestor Documental.
.DESCRIPTION
  Crea un fichero .xlsx con:
    - Hoja "Plantilla"   → columnas de metadatos + validaciones de lista (dropdowns) para campos Choice.
    - Hoja "Instrucciones" → guía de uso para el usuario funcional.
  Requiere el módulo ImportExcel (Install-Module ImportExcel -Scope CurrentUser).
.PARAMETER OutputPath
  Ruta completa del fichero Excel a generar.
  Por defecto: .\plantilla-carga-masiva.xlsx
.EXAMPLE
  .\06-generate-excel-template.ps1 -OutputPath "C:\Temp\plantilla.xlsx"
#>

param(
  [string]$OutputPath = (Join-Path $PSScriptRoot 'plantilla-carga-masiva.xlsx')
)

# ---------------------------------------------------------------------------
# Dependencias
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
  Write-Host "El módulo ImportExcel no está instalado. Instalando..." -ForegroundColor Yellow
  Install-Module -Name ImportExcel -Scope CurrentUser -Force
}
Import-Module ImportExcel -Force

# ---------------------------------------------------------------------------
# Definición de columnas
# Formato: [ordered]@{ Header; InternalName; Type; Choices; Notes }
# ---------------------------------------------------------------------------
$columns = [ordered]@{}

# ---- Columna de control ----
$columns['TipoContenido']               = @{ Header='Tipo de contenido *'; Type='choice'; Choices=@('GD – PO','GD – IT'); Notes='Obligatorio. Selecciona el tipo de contenido.' }
$columns['RutaArchivoLocal']            = @{ Header='Ruta archivo local'; Type='text'; Notes='Ruta completa al fichero a subir (ej: C:\Docs\manual.pdf). Dejar vacío si el documento ya existe en SharePoint.' }
$columns['TituloDocumento']             = @{ Header='Título documento'; Type='text'; Notes='Nombre del documento en SharePoint. Si se sube archivo, se usará como nombre. Si ya existe, se busca por este título.' }

# ---- Identificación ----
$columns['GD_Codigo']                   = @{ Header='Código'; Type='text'; Notes='Código identificador del documento.' }
$columns['GD_NombreProcedimiento']      = @{ Header='Nombre del procedimiento'; Type='text'; Notes='Nombre descriptivo del procedimiento.' }

# ---- Clasificación ----
$columns['GD_Aplicabilidad']            = @{ Header='Aplicabilidad'; Type='choice'; Choices=@('General','Por producto'); Notes='Selecciona si aplica de forma general o por producto.' }
$columns['GD_TipoProceso']              = @{ Header='Tipo de proceso'; Type='choice'; Choices=@('Proceso de Manufactura','Administrativos Transversales de cada Planta'); Notes='Tipo de proceso asociado al documento.' }
$columns['GD_Estatus']                  = @{ Header='Estatus'; Type='choice'; Choices=@('Borrador','En revisión','Aprobado','Rechazado','Obsoleto'); Notes='Estado actual del documento.' }

# ---- Ciclo de vida ----
$columns['GD_Version']                  = @{ Header='Versión'; Type='text'; Notes='Número de versión (ej: 1.0, 2.3).' }
$columns['GD_FechaDivulgacion']         = @{ Header='Fecha divulgación'; Type='date'; Notes='Formato DD/MM/AAAA.' }
$columns['GD_FechaActualizacion']       = @{ Header='Fecha actualización'; Type='date'; Notes='Formato DD/MM/AAAA.' }
$columns['GD_MotivoActualizacion']      = @{ Header='Motivo actualización'; Type='choice'; Choices=@('Actualización normativa','Auditoría interna','Auditoría externa','Mejora de proceso','Cambio operativo'); Notes='Razón por la que se actualiza el documento.' }
$columns['GD_VigenciaHasta']            = @{ Header='Vigencia hasta'; Type='date'; Notes='Formato DD/MM/AAAA.' }
$columns['GD_FechaCaducidad']           = @{ Header='Fecha de caducidad'; Type='date'; Notes='Formato DD/MM/AAAA.' }

# ---- Homologación ----
$columns['GD_FechaHomologacion']        = @{ Header='Fecha de homologación'; Type='date'; Notes='Formato DD/MM/AAAA.' }

# ---- YUM ----
$columns['GD_AprobadoPorYUM']          = @{ Header='Aprobado por YUM (UPN)'; Type='text'; Notes='Email/UPN del usuario que aprueba en YUM (ej: usuario@empresa.com).' }
$columns['GD_FechaVencimientoYUM']     = @{ Header='Fecha vencimiento YUM'; Type='date'; Notes='Formato DD/MM/AAAA.' }

# ---- Continuidad ----
$columns['GD_ImpactoContinuidad']      = @{ Header='Impacto continuidad'; Type='choice'; Choices=@('Alto','Medio','Bajo'); Notes='Nivel de impacto en la continuidad del negocio.' }

# ---- Responsables (UPN; separados por punto y coma) ----
$columns['GD_ResponsablePrincipal']    = @{ Header='Responsable principal (UPN)'; Type='text'; Notes='Email/UPN del responsable principal.' }
$columns['GD_RespElaboracionActualizacion'] = @{ Header='Responsable elaboración/actualización (UPN;UPN)'; Type='text'; Notes='Emails/UPN separados por punto y coma (;) para múltiples usuarios.' }
$columns['GD_RespRevision']            = @{ Header='Responsable revisión (UPN;UPN)'; Type='text'; Notes='Emails/UPN separados por punto y coma (;) para múltiples usuarios.' }
$columns['GD_RespAprobacion']          = @{ Header='Responsable aprobación (UPN;UPN)'; Type='text'; Notes='Emails/UPN separados por punto y coma (;) para múltiples usuarios.' }

# ---- Campos de Taxonomía (Managed Metadata) ----
# Indicar el LABEL exacto del término tal como está en el Term Store.
# Para campos multi-valor, separar etiquetas con punto y coma (;).
$columns['GD_Categoria']              = @{ Header='Categoría (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Categoria".' }
$columns['GD_Alcance']                = @{ Header='Alcance (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Alcance".' }
$columns['GD_Confidencialidad']       = @{ Header='Confidencialidad (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Confidencialidad".' }
$columns['GD_PlantasAplicables']      = @{ Header='Plantas aplicables (término;término)'; Type='taxonomy-multi'; Notes='Etiquetas de término del Term Set "GD - Plantas y Centros". Separar varios con punto y coma (;).' }
$columns['GD_HomologacionPlanta']     = @{ Header='Homologación planta (término;término)'; Type='taxonomy-multi'; Notes='Etiquetas de término del Term Set "GD - Plantas y Centros". Separar varios con punto y coma (;).' }
$columns['GD_Producto']               = @{ Header='Producto (término;término)'; Type='taxonomy-multi'; Notes='Etiquetas de término del Term Set "GD - Producto - Familia - SKU". Separar varios con punto y coma (;).' }
$columns['GD_DepartamentoResponsable']= @{ Header='Departamento responsable (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Areas - Departamentos".' }
$columns['GD_CargoLiderPO']           = @{ Header='Cargo líder PO (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Cargos - Roles".' }
$columns['GD_AmbitoPrograma']         = @{ Header='Ámbito/Programa (término)'; Type='taxonomy'; Notes='Etiqueta exacta del término del Term Set "GD - Ambito - Programa".' }

# ---------------------------------------------------------------------------
# Construir la hoja Instrucciones
# ---------------------------------------------------------------------------
$instrucciones = @(
  [PSCustomObject]@{ Instrucciones='=== INSTRUCCIONES DE USO ===' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='1. CÓMO RELLENAR ESTA PLANTILLA' }
  [PSCustomObject]@{ Instrucciones='   - Rellena una fila por documento en la hoja "Plantilla".' }
  [PSCustomObject]@{ Instrucciones='   - Los campos con (*) son obligatorios.' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de tipo fecha, usa el formato DD/MM/AAAA.' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de usuarios, introduce el email/UPN del usuario (ej: juan.garcia@empresa.com).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos multi-usuario, separa los UPN con punto y coma (;).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de taxonomía, escribe el label EXACTO del término (respeta mayúsculas/minúsculas).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de taxonomía multi-valor, separa los términos con punto y coma (;).' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='2. COLUMNA "Ruta archivo local"' }
  [PSCustomObject]@{ Instrucciones='   - Si el documento AÚN NO está en SharePoint, indica la ruta completa al fichero local.' }
  [PSCustomObject]@{ Instrucciones='     Ejemplo: C:\Documentos\procedimiento-v1.pdf' }
  [PSCustomObject]@{ Instrucciones='   - Si el documento YA EXISTE en SharePoint, deja esta columna en blanco' }
  [PSCustomObject]@{ Instrucciones='     y rellena "Título documento" con el nombre exacto del documento.' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='3. COLUMNA "Tipo de contenido"' }
  [PSCustomObject]@{ Instrucciones='   - GD – PO : Procedimiento Operativo' }
  [PSCustomObject]@{ Instrucciones='   - GD – IT : Instrucción de Trabajo' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='4. CAMPOS DE TAXONOMÍA — Term Sets disponibles' }
  [PSCustomObject]@{ Instrucciones='   Categoría            → Term Set: GD - Categoria' }
  [PSCustomObject]@{ Instrucciones='   Alcance              → Term Set: GD - Alcance' }
  [PSCustomObject]@{ Instrucciones='   Confidencialidad     → Term Set: GD - Confidencialidad' }
  [PSCustomObject]@{ Instrucciones='   Plantas aplicables   → Term Set: GD - Plantas y Centros (multi)' }
  [PSCustomObject]@{ Instrucciones='   Homologación planta  → Term Set: GD - Plantas y Centros (multi)' }
  [PSCustomObject]@{ Instrucciones='   Producto             → Term Set: GD - Producto - Familia - SKU (multi)' }
  [PSCustomObject]@{ Instrucciones='   Departamento resp.   → Term Set: GD - Areas - Departamentos' }
  [PSCustomObject]@{ Instrucciones='   Cargo líder PO       → Term Set: GD - Cargos - Roles' }
  [PSCustomObject]@{ Instrucciones='   Ámbito/Programa      → Term Set: GD - Ambito - Programa' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='5. NO modificar los nombres de las cabeceras de la hoja "Plantilla".' }
  [PSCustomObject]@{ Instrucciones='6. No dejes filas completamente en blanco entre registros.' }
)

# ---------------------------------------------------------------------------
# Construir filas de datos vacías para la plantilla (0 filas de datos)
# ---------------------------------------------------------------------------
$headers = $columns.Keys

# Construir un único objeto con todas las propiedades para forzar el header
$emptyRow = [ordered]@{}
foreach ($key in $columns.Keys) {
  $emptyRow[$columns[$key].Header] = ''
}

# ---------------------------------------------------------------------------
# Exportar a Excel
# ---------------------------------------------------------------------------
if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

# Hoja Plantilla
$emptyObj = [PSCustomObject]$emptyRow
Export-Excel -Path $OutputPath -WorksheetName 'Plantilla' -InputObject $emptyObj `
  -AutoSize -FreezeTopRow -BoldTopRow -TableName 'TablaDatos' -TableStyle Medium2 -PassThru |
  ForEach-Object {
    $excel = $_
    $ws    = $excel.Workbook.Worksheets['Plantilla']

    # Fila de notas/ayuda (fila 2 ya tiene el objeto vacío; la mantenemos)
    # Añadir fila 3 de ayuda con el "tipo" de cada columna
    $colIdx = 1
    foreach ($key in $columns.Keys) {
      $meta = $columns[$key]
      # Tooltip comentario en celda de cabecera
      $cell = $ws.Cells[1, $colIdx]
      $cell.AddComment($meta.Notes, 'GD') | Out-Null

      # Colorear cabeceras por tipo
      switch ($meta.Type) {
        'choice'         { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,198,239,206)) }  # verde suave
        'date'           { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,221,235,247)) }  # azul suave
        'taxonomy'       { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,255,242,204)) }  # amarillo suave
        'taxonomy-multi' { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,252,228,214)) }  # naranja suave
      }

      # Validación de lista para campos Choice (filas 2..500)
      if ($meta.Type -eq 'choice') {
        $validation = $ws.DataValidations.AddListValidation("$([OfficeOpenXml.ExcelCellAddress]::new(2, $colIdx).Address):$([OfficeOpenXml.ExcelCellAddress]::new(500, $colIdx).Address)")
        $validation.ShowErrorMessage = $true
        $validation.ErrorTitle = 'Valor no válido'
        $validation.Error = "Usa uno de los valores de la lista desplegable."
        foreach ($choice in $meta.Choices) {
          $validation.Formula.Values.Add($choice)
        }
      }

      $colIdx++
    }

    # Eliminar la fila 2 vacía que Export-Excel introduce por el objeto vacío
    # (la dejamos como fila de ejemplo en blanco para el usuario)

    Close-ExcelPackage $excel -SaveAs $OutputPath
  }

# Hoja Instrucciones
$instrucciones | Export-Excel -Path $OutputPath -WorksheetName 'Instrucciones' `
  -AutoSize -BoldTopRow -Append

# Hoja Leyenda colores
$leyenda = @(
  [PSCustomObject]@{ Tipo='Texto libre'; Descripción='Sin color especial. Escribe directamente.' }
  [PSCustomObject]@{ Tipo='Choice (lista)'; Descripción='Verde: usa el desplegable o escribe exactamente uno de los valores permitidos.' }
  [PSCustomObject]@{ Tipo='Fecha'; Descripción='Azul: formato DD/MM/AAAA.' }
  [PSCustomObject]@{ Tipo='Taxonomía (único)'; Descripción='Amarillo: label exacto del término en el Term Store.' }
  [PSCustomObject]@{ Tipo='Taxonomía (múltiple)'; Descripción='Naranja: labels de término separados por ; (punto y coma).' }
)
$leyenda | Export-Excel -Path $OutputPath -WorksheetName 'Leyenda' -AutoSize -BoldTopRow -Append

Write-Host "Plantilla generada: $OutputPath" -ForegroundColor Green
