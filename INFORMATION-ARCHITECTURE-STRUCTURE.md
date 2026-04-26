# KFCGD — Estructura de información (IA) y metadatos — Especificación para revisión/contraste

Este documento describe la **estructura esperada** (Term Store, metadatos, Content Types y biblioteca) del Gestor Documental, para comparar contra lo implementado con scripts u otras herramientas.

---

## 1) Sitio destino

- SharePoint Online Site:
  - Default: `/sites/KFCGD`
- No se usa Content Type Hub (los CTs se crean en el sitio).

---

## 2) Term Store (Taxonomía)

### 2.1 Term Group
- **Nombre**: `GestorDocumentalGD`

### 2.2 Term Sets (todos *Closed*)
> Los nombres deben coincidir exactamente para que los campos MM se enlacen correctamente.

1. `GD - Categoria`
   - Términos semilla:
     - `Transversales Ecuador (Manufactura)`
     - `Transversales Ecuador (Administrativos)`
     - `Regional de Manufactura`
     - `Franquicias`

2. `GD - Alcance`
   - Términos semilla:
     - `Regional`
     - `Nacional`

3. `GD - Confidencialidad`
   - Términos semilla:
     - `Interno`
     - `Confidencial`
     - `Confidencial YUM`

4. `GD - Plantas y Centros`
   - Términos semilla:
     - `Ecuador`

5. `GD - Producto - Familia - SKU`
   - Términos semilla:
     - `Pollos`
     - `Vegetales`
     - `Cárnicos`
     - `Pastelería`
     - `Cocina`
     - `Hamburguesas`

6. `GD - Areas - Departamentos`
   - Términos semilla:
     - `Calidad`
     - `Mantenimiento`
     - `Mantenimiento / Calidad`
     - `Legal`

7. `GD - Cargos - Roles`
   - Términos semilla:
     - `Coordinador de Gestión Documental`
     - `Jefe de Mantenimiento`
     - `Supervisora laboratorio`

8. `GD - Ambito - Programa`
   - Términos semilla:
     - `KFC YUM`
     - `KFC REGIONAL`
     - `KFC AUDITORIAS YUM`
     - `ECUADOR: MARCAS NACIONALES`

---

## 3) Site Columns (campos base)

> Convención: InternalName = nombre técnico con prefijo `GD_`.  
> Grupo sugerido: `GD Columns`.

### 3.1 Text (Texto)
- `GD_Codigo`
- `GD_NombreProcedimiento`
- `GD_ProductoLabels` *(texto auxiliar: etiquetas o búsqueda)*
- `GD_Version`

### 3.2 Choice (Selección)
- `GD_Aplicabilidad`:
  - `General`
  - `Por producto`

- `GD_Estatus`:
  - `Borrador`
  - `En revisión`
  - `Aprobado`
  - `Rechazado`
  - `Obsoleto`

- `GD_TipoProceso`:
  - `Proceso de Manufactura`
  - `Administrativos Transversales de cada Planta`

- `GD_MotivoActualizacion`:
  - `Actualización normativa`
  - `Auditoría interna`
  - `Auditoría externa`
  - `Mejora de proceso`
  - `Cambio operativo`

- `GD_ImpactoContinuidad`:
  - `Alto`
  - `Medio`
  - `Bajo`

### 3.3 Date (solo fecha)
> En SharePoint: Field Type = `DateTime`, con `Format=DateOnly`.

- `GD_FechaDivulgacion`
- `GD_FechaActualizacion`
- `GD_VigenciaHasta`
- `GD_FechaCaducidad`
- `GD_FechaHomologacion`
- `GD_FechaVencimientoYUM`

### 3.4 People (Personas)
- Single:
  - `GD_AprobadoPorYUM`
  - `GD_ResponsablePrincipal`
- Multi:
  - `GD_RespElaboracionActualizacion`
  - `GD_RespRevision`
  - `GD_RespAprobacion`

---

## 4) Taxonomy Site Columns (Managed Metadata)

> Deben crearse y enlazarse a term sets dentro del Term Group `GestorDocumentalGD`.

### 4.1 Single-value (por defecto)
- `GD_Categoria` → TermSet `GD - Categoria`
- `GD_Alcance` → TermSet `GD - Alcance`
- `GD_Confidencialidad` → TermSet `GD - Confidencialidad`
- `GD_DepartamentoResponsable` → TermSet `GD - Areas - Departamentos`
- `GD_CargoLiderPO` → TermSet `GD - Cargos - Roles`
- `GD_AmbitoPrograma` → TermSet `GD - Ambito - Programa`

### 4.2 Multi-value (confirmados)
- `GD_PlantasAplicables` → TermSet `GD - Plantas y Centros` (**Multi**)
- `GD_HomologacionPlanta` → TermSet `GD - Plantas y Centros` (**Multi**)
- `GD_Producto` → TermSet `GD - Producto - Familia - SKU` (**Multi**)

---

## 5) Content Types (a nivel de sitio)

### 5.1 Content Types requeridos
- `GD – PO`
- `GD – IT`

### 5.2 Herencia
- Ambos heredan de: **Document**

### 5.3 Field Links
Deben incluir:
- Todos los campos base (Sección 3)
- Todos los campos de taxonomía (Sección 4)

> Regla: por defecto, no requeridos.

---

## 6) Biblioteca de documentos

### 6.1 Biblioteca objetivo
- Default: `Gestor Documental`
- Alternativo: `Documentos GD Generales`
- Debe ser parametrizable (`-LibraryTitle`)

### 6.2 Configuración esperada
- Content types habilitados
- Content types agregados a la biblioteca:
  - `GD – PO`
  - `GD – IT`
- Recomendación: mantener `Document` (default)

---

## 8) Tipo documental: Documentos relacionados

> Content Type: `GD – Relacionado` (hereda de `Document`).  
> Scripts de provisioning: [`provisioning/related_documents/`](provisioning/related_documents/README.md).

### 8.1 Columnas nuevas (específicas de este tipo documental)

> Creadas por `provisioning/related_documents/01-rd-sitecolumns.ps1` y `02-rd-taxonomyfield.ps1`.

| Columna (visible) | InternalName | Tipo | Multi | Observaciones |
|---|---|---|---|---|
| Nomenclatura | `GD_Nomenclatura` | Texto | No | Sigla/nomenclatura del documento |
| Nombre de documento homologado | `GD_NombreDocumentoHomologado` | Texto | No | Nombre del doc. homologado de referencia |
| Visualización documento | `GD_VisualizacionDocumento` | URL (Hyperlink) | No | Enlace directo al archivo |
| Documento general relacionado | `GD_DocumentoGeneral` | URL (Hyperlink) | No | Enlace al PO/IT padre |
| Fecha de emisión | `GD_FechaEmision` | Fecha (DateOnly) | No | Fecha de emisión del documento |
| Línea de proceso | `GD_LineaProceso` | Taxonomía (MM) | **Sí** | TermSet: `GD - Lineas de Proceso` |

### 8.2 Columnas reutilizadas de Documentos generales

Los siguientes campos ya existen (secciones 3 y 4) y se enlazan al CT `GD – Relacionado`:

`GD_Codigo`, `GD_NombreProcedimiento`, `GD_Aplicabilidad`, `GD_Version`,
`GD_VigenciaHasta`, `GD_FechaActualizacion`, `GD_FechaCaducidad`,
`GD_RespElaboracionActualizacion`, `GD_Estatus`, `GD_AprobadoPorYUM`,
`GD_FechaVencimientoYUM`, `GD_PlantasAplicables`

### 8.3 Term Set nuevo: GD - Lineas de Proceso

**Term Group:** `GestorDocumentalGD`  
**Term Set:** `GD - Lineas de Proceso` (Closed)

Términos semilla: Fileteado, Corte, Cocción, Marinado, Empaque, Congelación, Distribución, Control de Calidad, Limpieza y Desinfección, Mantenimiento.

### 8.4 Content Type

| Propiedad | Valor |
|---|---|
| Nombre | `GD – Relacionado` |
| Grupo | `GD Content Types` |
| Hereda de | `Document` |
| Biblioteca | `Gestor Documental` (default, parametrizable) |

---

## 9) Criterios de contraste (para otras herramientas)

Al comparar contra otras herramientas, agregar a la validación de la sección 7:

6. Tipo documental `GD – Relacionado`:
   - Campos nuevos: `GD_Nomenclatura`, `GD_NombreDocumentoHomologado`, `GD_VisualizacionDocumento`, `GD_DocumentoGeneral`, `GD_FechaEmision`, `GD_LineaProceso`
   - Term Set `GD - Lineas de Proceso` (Closed, multi)
   - CT `GD – Relacionado` hereda de `Document` y enlaza los 18 campos definidos

Al comparar contra otras herramientas (p. ej. plantillas provisioning, IaC o scripts alternos), validar:

1. Nombres exactos:
   - Term Group, Term Sets, InternalName de fields, nombres de CTs
2. Cardinalidad:
   - Multi en `GD_Producto`, `GD_PlantasAplicables`, `GD_HomologacionPlanta`
3. Tipos y formatos:
   - Fechas como DateOnly (DateTime+Format)
   - People multi vs single
4. Enlaces:
   - Taxonomy fields enlazados al Term Set correcto
   - CTs enlazando todos los fields
   - Biblioteca con CTs habilitados y CTs agregados
5. Idempotencia:
   - Re-ejecución sin duplicados ni fallos
