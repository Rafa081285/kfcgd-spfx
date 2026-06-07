<#
.SYNOPSIS
  Genera la plantilla Excel para carga masiva de metadatos de Documentos Relacionados GD.
.DESCRIPTION
  Crea un fichero .xlsx con:
    - Hoja "Plantilla"      → columnas de metadatos + validaciones de lista (dropdowns) para campos Choice.
    - Hoja "Instrucciones"  → guía de uso para el usuario funcional.
    - Hoja "Leyenda"        → significado de los colores de cabecera.
  Requiere el módulo ImportExcel (Install-Module ImportExcel -Scope CurrentUser).
.PARAMETER OutputPath
  Ruta completa del fichero Excel a generar.
  Por defecto: .\plantilla-carga-masiva-rd.xlsx
.EXAMPLE
  .\06-rd-generate-excel-template.ps1 -OutputPath "C:\Temp\plantilla-rd.xlsx"
#>

param(
  [string]$OutputPath = (Join-Path $PSScriptRoot 'plantilla-carga-masiva-rd.xlsx')
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
# ---------------------------------------------------------------------------
$columns = [ordered]@{}

# ---- Columna de control ----
$columns['RutaArchivoLocal']            = @{ Header='Ruta archivo local'; Type='text'; Notes='Ruta completa al fichero a subir (ej: C:\Docs\doc.pdf). Dejar vacío si el documento ya existe en SharePoint.' }
$columns['TituloDocumento']             = @{ Header='Título documento'; Type='text'; Notes='Nombre del documento en SharePoint. Si se sube archivo se usará como nombre. Si ya existe, se busca por este título.' }

# ---- Identificación ----
$columns['GD_Codigo']                   = @{ Header='Código'; Type='text'; Notes='Código identificador del documento relacionado.' }
$columns['GD_Nomenclatura']             = @{ Header='Nomenclatura'; Type='text'; Notes='Nomenclatura o referencia interna del documento relacionado.' }
$columns['GD_NombreProcedimiento']      = @{ Header='Nombre del procedimiento'; Type='text'; Notes='Nombre descriptivo del procedimiento.' }
$columns['GD_NombreDocumentoHomologado']= @{ Header='Nombre documento homologado'; Type='text'; Notes='Nombre del documento homologado equivalente, si aplica.' }

# ---- Clasificación ----
$columns['GD_Aplicabilidad']            = @{ Header='Aplicabilidad'; Type='choice'; Choices=@('General','Por producto'); Notes='Selecciona si aplica de forma general o por producto.' }
$columns['GD_Estatus']                  = @{ Header='Estatus'; Type='choice'; Choices=@('Borrador','En revisión','Aprobado','Rechazado','Obsoleto'); Notes='Estado actual del documento.' }

# ---- Ciclo de vida ----
$columns['GD_Version']                  = @{ Header='Versión'; Type='text'; Notes='Número de versión (ej: 1.0, 2.3).' }
$columns['GD_FechaEmision']             = @{ Header='Fecha emisión'; Type='date'; Notes='Formato DD/MM/AAAA. Fecha de emisión del documento.' }
$columns['GD_FechaActualizacion']       = @{ Header='Fecha actualización'; Type='date'; Notes='Formato DD/MM/AAAA.' }
$columns['GD_VigenciaHasta']            = @{ Header='Vigencia hasta'; Type='date'; Notes='Formato DD/MM/AAAA.' }
$columns['GD_FechaCaducidad']           = @{ Header='Fecha de caducidad'; Type='date'; Notes='Formato DD/MM/AAAA.' }

# ---- YUM ----
$columns['GD_AprobadoPorYUM']           = @{ Header='Aprobado por YUM (UPN)'; Type='text'; Notes='Email/UPN del usuario que aprueba en YUM (ej: usuario@empresa.com).' }
$columns['GD_FechaVencimientoYUM']      = @{ Header='Fecha vencimiento YUM'; Type='date'; Notes='Formato DD/MM/AAAA.' }

# ---- Responsables ----
$columns['GD_RespElaboracionActualizacion'] = @{ Header='Responsable elaboración/actualización (UPN;UPN)'; Type='text'; Notes='Emails/UPN separados por punto y coma (;) para múltiples usuarios.' }

# ---- Enlace al documento (URL directa) ----
$columns['GD_VisualizacionDocumento']   = @{ Header='URL visualización documento'; Type='text'; Notes='URL directa al documento (opcional). Si se deja vacío, SharePoint usará la URL del propio archivo subido.' }

# ---- Referencia al documento general padre ----
$columns['GD_DocumentoGeneral']         = @{ Header='Documento general (título exacto)'; Type='text'; Notes='Título exacto del documento PO o IT padre en la biblioteca "Gestor Documental". Se usa para crear el Lookup.' }

# ---- Taxonomía ----
$columns['GD_PlantasAplicables']        = @{ Header='Plantas aplicables (término;término)'; Type='taxonomy-multi'; Notes='Etiquetas de término del Term Set "GD - Plantas y Centros". Separar varios con ; (punto y coma).' }
$columns['GD_LineaProceso']             = @{ Header='Línea de proceso (término)'; Type='taxonomy'; Notes='Etiqueta exacta del Term Set "GD - Lineas de Proceso": Todas | Fileteado | Corte | Cocción | Marinado | Empaque | Congelación | Distribución | Control de Calidad | Limpieza y Desinfección | Mantenimiento' }

# ---------------------------------------------------------------------------
# Construir la hoja Instrucciones
# ---------------------------------------------------------------------------
$instrucciones = @(
  [PSCustomObject]@{ Instrucciones='=== INSTRUCCIONES DE USO — DOCUMENTOS RELACIONADOS GD ===' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='1. CÓMO RELLENAR ESTA PLANTILLA' }
  [PSCustomObject]@{ Instrucciones='   - Rellena una fila por documento en la hoja "Plantilla".' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de tipo fecha, usa el formato DD/MM/AAAA.' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de usuarios, introduce el email/UPN del usuario (ej: juan.garcia@empresa.com).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos multi-usuario, separa los UPN con punto y coma (;).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de taxonomía, escribe el label EXACTO del término (respeta mayúsculas/minúsculas).' }
  [PSCustomObject]@{ Instrucciones='   - Para campos de taxonomía multi-valor, separa los términos con punto y coma (;).' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='2. COLUMNA "Ruta archivo local"' }
  [PSCustomObject]@{ Instrucciones='   - Si el documento AÚN NO está en SharePoint, indica la ruta completa al fichero local.' }
  [PSCustomObject]@{ Instrucciones='     Ejemplo: C:\Documentos\relacionado-v1.pdf' }
  [PSCustomObject]@{ Instrucciones='   - Si el documento YA EXISTE en SharePoint, deja esta columna en blanco' }
  [PSCustomObject]@{ Instrucciones='     y rellena "Título documento" con el nombre exacto del documento.' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='3. COLUMNA "Documento general (título exacto)"' }
  [PSCustomObject]@{ Instrucciones='   - Indica el título EXACTO del documento PO o IT en "Gestor Documental" al que pertenece este relacionado.' }
  [PSCustomObject]@{ Instrucciones='   - Este valor se usará para crear el vínculo Lookup automáticamente al cargar.' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='4. COLUMNA "URL visualización documento"' }
  [PSCustomObject]@{ Instrucciones='   - Opcional. Si se rellena, se mostrará como enlace directo al archivo.' }
  [PSCustomObject]@{ Instrucciones='   - Si se deja vacío, el sistema usará la URL del propio archivo en la biblioteca.' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='5. CAMPO Línea de proceso — valores válidos del Term Set "GD - Lineas de Proceso":' }
  [PSCustomObject]@{ Instrucciones='   Todas | Fileteado | Corte | Cocción | Marinado | Empaque | Congelación' }
  [PSCustomObject]@{ Instrucciones='   Distribución | Control de Calidad | Limpieza y Desinfección | Mantenimiento' }
  [PSCustomObject]@{ Instrucciones='' }
  [PSCustomObject]@{ Instrucciones='6. NO modificar los nombres de las cabeceras de la hoja "Plantilla".' }
  [PSCustomObject]@{ Instrucciones='7. No dejes filas completamente en blanco entre registros.' }
)

# ---------------------------------------------------------------------------
# Construir fila vacía con todos los headers
# ---------------------------------------------------------------------------
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
  -AutoSize -FreezeTopRow -BoldTopRow -TableName 'TablaDatosRD' -TableStyle Medium2 -PassThru |
  ForEach-Object {
    $excel = $_
    $ws    = $excel.Workbook.Worksheets['Plantilla']

    $colIdx = 1
    foreach ($key in $columns.Keys) {
      $meta = $columns[$key]
      $cell = $ws.Cells[1, $colIdx]
      $cell.AddComment($meta.Notes, 'GD') | Out-Null

      switch ($meta.Type) {
        'choice'         { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,198,239,206)) }
        'date'           { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,221,235,247)) }
        'taxonomy'       { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,255,242,204)) }
        'taxonomy-multi' { $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                           $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::FromArgb(255,252,228,214)) }
      }

      if ($meta.Type -eq 'choice') {
        $validation = $ws.DataValidations.AddListValidation("$([OfficeOpenXml.ExcelCellAddress]::new(2, $colIdx).Address):$([OfficeOpenXml.ExcelCellAddress]::new(500, $colIdx).Address)")
        $validation.ShowErrorMessage = $true
        $validation.ErrorTitle = 'Valor no válido'
        $validation.Error = 'Usa uno de los valores de la lista desplegable.'
        foreach ($choice in $meta.Choices) {
          $validation.Formula.Values.Add($choice)
        }
      }

      $colIdx++
    }

    Close-ExcelPackage $excel -SaveAs $OutputPath
  }

# Hoja Instrucciones
$instrucciones | Export-Excel -Path $OutputPath -WorksheetName 'Instrucciones' `
  -AutoSize -BoldTopRow -Append

# Hoja Leyenda colores
$leyenda = @(
  [PSCustomObject]@{ Tipo='Texto libre';            Descripción='Sin color especial. Escribe directamente.' }
  [PSCustomObject]@{ Tipo='Choice (lista)';          Descripción='Verde: usa el desplegable o escribe exactamente uno de los valores permitidos.' }
  [PSCustomObject]@{ Tipo='Fecha';                   Descripción='Azul: formato DD/MM/AAAA.' }
  [PSCustomObject]@{ Tipo='Taxonomía (único)';       Descripción='Amarillo: label exacto del término en el Term Store.' }
  [PSCustomObject]@{ Tipo='Taxonomía (múltiple)';    Descripción='Naranja: labels de término separados por ; (punto y coma).' }
)
$leyenda | Export-Excel -Path $OutputPath -WorksheetName 'Leyenda' -AutoSize -BoldTopRow -Append

Write-Host "Plantilla generada: $OutputPath" -ForegroundColor Green
