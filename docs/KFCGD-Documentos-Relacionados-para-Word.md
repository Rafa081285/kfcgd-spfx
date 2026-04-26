# Tipo Documental: Documentos Relacionados
**Sistema:** Gestor Documental GD  
**Sitio:** `/sites/KFCGD`  
**Biblioteca:** `Gestor Documental` (parametrizable)  
**Versión:** 1.0  
**Fecha:** 2026-04-26  
**Propietario:** PO Gestión Documental  

---

## 1. Objetivo
Definir la estructura del tipo documental **Documentos Relacionados**, incluyendo:
- Propósito y alcance del tipo documental
- Tabla de metadatos (columnas) con nombre funcional, nombre interno, tipo de SharePoint, cardinalidad y reglas
- Regla de relación con el **Documento General**
- Reglas de estatus, vigencia/caducidad y aprobación (incl. YUM si aplica)
- Vistas sugeridas para control y auditoría
- Ejemplos basados en la matriz provista

---

## 2. Definición
Un **Documento Relacionado** es un documento derivado o complementario de un **Documento General**. Incluye, entre otros:
- Diagramas de Flujo asociados a un procedimiento o a un instructivo
- Instructivos
- Matrices (p.ej. lista maestra)
- Documentos internos (p.ej. plantillas, bases de datos)
- Evaluaciones
- Presentaciones y ayudas visuales
- Cualquier documento adicional que deba quedar trazado contra un Documento General

---

## 3. Alcance y uso esperado
Este tipo documental se usa cuando:
- El documento principal (“general”) necesita anexos/soportes formales
- Se requiere localizar rápidamente “todo lo relacionado” a un documento general
- Se requiere filtrar relacionados por planta, línea de proceso, producto, estatus o vigencia

---

## 4. Relación con Documento General

### 4.1 Mecanismo de relación (MVP recomendado)
La relación se captura mediante el campo:
- **Documento general relacionado (URL)** (`GD_DocumentoGeneralUrl`) — tipo **Hipervínculo**

**Regla (MVP):**
- El usuario copia el enlace del documento general y lo pega en este campo al crear/editar el documento relacionado.

**Ventajas:**
- Simple, robusto e independiente del tipo de biblioteca/estructura.
- No depende de IDs internos ni configuraciones complejas.

### 4.2 Alternativas futuras (no MVP)
- Lookup a un registro/ítem del documento general (requiere fuente/clave estable)
- Document ID (guardar ID como texto y resolverlo con automatización)

---

## 5. Metadatos (columnas) — Especificación

### 5.1 Tabla oficial de metadatos
> Columnas: Nombre (negocio) | InternalName sugerido | Tipo SharePoint | Multi | Origen | Comentarios/Reglas

| Nombre (negocio) | InternalName sugerido | Tipo SharePoint | Multi | Origen | Comentarios / Reglas |
|---|---|---|:---:|---|---|
| CÓDIGO | `GD_Codigo` | Text | No | Reusar (base) | Ej: `DF:GC:GD`, `IT:GC:DFP`. Validación opcional por patrón. |
| NOMENCLATURA | `GD_Nomenclatura` | Text (o Choice) | No | Nuevo | Ej: `DF`, `IT`, `DI`, `MA`, `EV`, `PO`. Si catálogo cerrado: Choice. |
| NOMBRE DEL PROCEDIMIENTO | `GD_NombreProcedimiento` | Text | No | Reusar (base) | Ej: “PO Gestión Documental”. |
| TIPO (APLICA POR PRODUCTO O GENERAL) | `GD_Aplicabilidad` | Choice | No | Reusar (base) | `General` / `Por producto`. |
| NOMBRE DE DOCUMENTO HOMOLOGADO | `GD_NombreDocumentoHomologado` | Text | No | Nuevo | Nombre estandarizado del documento relacionado. |
| VISUALIZACIÓN DOCUMENTO | `GD_VisualizacionDocumento` | Text (o Choice) | No | Nuevo | Ej: “Cargar documento.” / “Solo lectura” / “Adjunto”. |
| APLICA A QUÉ PLANTA | `GD_PlantasAplicables` | Managed Metadata | Sí | Reusar (taxonomía base) | TermSet: `GD - Plantas y Centros` (multi). |
| APLICA A ALGUNA LÍNEA DE PROCESO | `GD_LineaProceso` | Managed Metadata (ideal) | Sí | Nuevo | Requiere TermSet (p.ej. `GD - Líneas de Proceso`). Alternativa MVP: Text. |
| VERSIÓN | `GD_Version` | Text | No | Reusar (base) | Ej: 1.0 / 2.0. |
| VIGENCIA | `GD_VigenciaHasta` | Date (DateOnly) | No | Reusar (base) | Vigencia “hasta”. |
| FECHA DE EMISIÓN | `GD_FechaDivulgacion` | Date (DateOnly) | No | Reusar (base) | Si “Emisión” ≠ “Divulgación”: crear `GD_FechaEmision`. |
| FECHA DE ACTUALIZACIÓN | `GD_FechaActualizacion` | Date (DateOnly) | No | Reusar (base) | — |
| FECHA DE CADUCIDAD | `GD_FechaCaducidad` | Date (DateOnly) | No | Reusar (base) | — |
| RESPONSABLE DE ACTUALIZACIÓN | `GD_RespElaboracionActualizacion` | Person/Group | Sí | Reusar (base) | Multi-person recomendado. |
| ESTATUS | `GD_Estatus` | Choice | No | Reusar (base) | `Borrador` / `En revisión` / `Aprobado` / `Rechazado` / `Obsoleto`. |
| APROBADO POR YUM | `GD_AprobadoPorYUM` | Person/Group | No | Reusar (base) | Alterno: Sí/No + aprobador separado. |
| FECHA DE VENCIMIENTO YUM | `GD_FechaVencimientoYUM` | Date (DateOnly) | No | Reusar (base) | — |
| DOCUMENTO GENERAL RELACIONADO (URL) | `GD_DocumentoGeneralUrl` | Hyperlink | No | Nuevo | Enlace al documento general. |
| PRODUCTO (si aplica) | `GD_Producto` | Managed Metadata | Sí | Reusar (taxonomía base) | TermSet: `GD - Producto - Familia - SKU` (multi). |

---

## 6. Reglas de negocio

### 6.1 Estatus
- Borrador: en construcción
- En revisión: pendiente de validación
- Aprobado: vigente y usable
- Rechazado: no aprobado
- Obsoleto: no vigente (histórico)

### 6.2 Vigencia y caducidad
- Vigencia define validez del documento.
- Caducidad para alertas/control.
- Vista recomendada: “Vencen en 60 días”.

### 6.3 Aprobación YUM (si aplica)
- Aprobado por YUM identifica aprobador.
- Fecha vencimiento YUM controla vigencia.

### 6.4 Aplicabilidad por producto
Si `GD_Aplicabilidad = Por producto`, se recomienda que `GD_Producto` sea obligatorio (regla/automatización).

---

## 7. Ejemplos (basados en la matriz)
- DF:GC:GD — Diagrama de Flujo asociado al Procedimiento de Gestión Documental — Estatus: APROBADO — Vencimiento YUM: 2026-03-31 — Producto: Vegetales — Línea: Fileteado.
- IT:GC:DFP — Instructivo para elaborar Diagramas de Flujo de Procedimientos — Producto: Pollos — Línea: Corte.
- DF:GC:DFP — Diagrama de Flujo asociado al instructivo DFP — Producto: Cárnicos — Línea: Inyección.

---

## 8. Vistas sugeridas (SharePoint)
- Aprobados
- Por producto
- Por planta
- Por línea de proceso
- Vencen en 60 días
- Relacionados a Documento General (por URL)

---

## 9. Content Type sugerido
- Nombre: `GD – Relacionado`
- Hereda de: `Document`
- Fields: sección 5.1

---

## 10. Control de cambios
| Versión | Fecha | Autor | Cambios |
|---|---:|---|---|
| 1.0 | 2026-04-26 | — | Definición inicial del tipo documental “Documentos Relacionados”. |
