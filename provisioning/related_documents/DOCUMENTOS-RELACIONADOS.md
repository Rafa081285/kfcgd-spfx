# Documentos Relacionados — Especificación del tipo documental

**Sitio:** `/sites/KFCGD`  
**Content Type:** `GD – Relacionado`  
**Hereda de:** `Document`  
**Biblioteca objetivo (default):** `Documentos Relacionados GD` (parametrizable)

---

## 1. Descripción del tipo documental

Los **Documentos relacionados** son documentos de referencia, homologación o procedimiento que se encuentran **enlazados a un Documento general** (PO o IT) registrado en el Gestor Documental.

Permiten:

- Referenciar versiones homologadas de un procedimiento por producto o planta.
- Identificar documentos específicos de una línea de proceso o centro de producción.
- Relacionar explícitamente un documento a su "Documento general" padre mediante un enlace (hyperlink).

---

## 2. Tabla de columnas / metadatos

### 2.1 Campos del tipo documental

| #   | Columna (visible)                                 | Nombre interno                    | Tipo             | Multi  | Requerido | Observaciones                                                                                                   |
| --- | ------------------------------------------------- | --------------------------------- | ---------------- | ------ | --------- | --------------------------------------------------------------------------------------------------------------- |
| 1   | Código                                            | `GD_Codigo`                       | Texto            | No     | Sí        | Reutilizado. Formato: `DF:GC:GD`, `IT:GC:DFP`, etc.                                                             |
| 2   | Nomenclatura                                      | `GD_Nomenclatura`                 | Texto            | No     | No        | **Nuevo.** Nomenclatura o sigla del documento.                                                                  |
| 3   | Nombre del procedimiento                          | `GD_NombreProcedimiento`          | Texto            | No     | Sí        | Reutilizado. Nombre descriptivo del procedimiento.                                                              |
| 4   | Tipo de documento (Aplica por producto o General) | `GD_Aplicabilidad`                | Choice           | No     | Sí        | Reutilizado. Valores: `General` / `Por producto`.                                                               |
| 5   | Nombre de documento homologado                    | `GD_NombreDocumentoHomologado`    | Texto            | No     | No        | **Nuevo.** Nombre exacto del documento homologado de referencia.                                                |
| 6   | Visualización documento                           | `GD_VisualizacionDocumento`       | URL (Hyperlink)  | No     | No        | **Nuevo.** Enlace directo al archivo para visualización.                                                        |
| 7   | Aplica a qué planta                               | `GD_PlantasAplicables`            | Taxonomía (MM)   | **Sí** | No        | Reutilizado. TermSet: `GD - Plantas y Centros`.                                                                 |
| 8   | Aplica a alguna línea de proceso                  | `GD_LineaProceso`                 | Taxonomía (MM)   | **Sí** | No        | **Nuevo.** TermSet: `GD - Lineas de Proceso`.                                                                   |
| 9   | Versión                                           | `GD_Version`                      | Texto            | No     | Sí        | Reutilizado.                                                                                                    |
| 10  | Vigencia                                          | `GD_VigenciaHasta`                | Fecha (DateOnly) | No     | No        | Reutilizado.                                                                                                    |
| 11  | Fecha de emisión                                  | `GD_FechaEmision`                 | Fecha (DateOnly) | No     | No        | **Nuevo.** Fecha en que se emitió el documento.                                                                 |
| 12  | Fecha de actualización                            | `GD_FechaActualizacion`           | Fecha (DateOnly) | No     | No        | Reutilizado.                                                                                                    |
| 13  | Fecha de caducidad                                | `GD_FechaCaducidad`               | Fecha (DateOnly) | No     | No        | Reutilizado.                                                                                                    |
| 14  | Responsable de actualización                      | `GD_RespElaboracionActualizacion` | Persona          | **Sí** | No        | Reutilizado. Multi-valor.                                                                                       |
| 15  | Estatus                                           | `GD_Estatus`                      | Choice           | No     | Sí        | Reutilizado. Valores: `Borrador` / `En revisión` / `Aprobado` / `Rechazado` / `Obsoleto`.                       |
| 16  | Aprobado por YUM                                  | `GD_AprobadoPorYUM`               | Persona          | No     | No        | Reutilizado.                                                                                                    |
| 17  | Fecha de vencimiento YUM                          | `GD_FechaVencimientoYUM`          | Fecha (DateOnly) | No     | No        | Reutilizado.                                                                                                    |
| 18  | Documento general relacionado                     | `GD_DocumentoGeneral`             | Lookup           | No     | No        | **Nuevo.** Lookup a la biblioteca `Gestor Documental` (`Title`). Referencia al Documento general (PO/IT) padre. |

> **Leyenda:**
>
> - _Reutilizado_: campo ya existente, creado por `provisioning/02-sitecolumns.ps1` o `provisioning/05-taxonomyfields.ps1`.
> - **Nuevo**: campo específico de "Documentos relacionados", creado por los scripts de esta carpeta.

---

## 3. Term Set nuevo: GD - Lineas de Proceso

**Term Group:** `GestorDocumentalGD`  
**Term Set:** `GD - Lineas de Proceso` (Closed)

### Términos semilla

| Término                 |
| ----------------------- |
| Fileteado               |
| Corte                   |
| Cocción                 |
| Marinado                |
| Empaque                 |
| Congelación             |
| Distribución            |
| Control de Calidad      |
| Limpieza y Desinfección |
| Mantenimiento           |

> El Term Set se crea como **Closed** para controlar el vocabulario; los términos deben ser aprobados por el equipo de Gestión Documental.

---

## 4. Content Type: GD – Relacionado

### 4.1 Definición

| Propiedad   | Valor                                         |
| ----------- | --------------------------------------------- |
| Nombre      | `GD – Relacionado`                            |
| Grupo       | `GD Content Types`                            |
| Hereda de   | `Document`                                    |
| Descripción | `Gestor Documental – Documentos relacionados` |

### 4.2 Field Links (campos enlazados)

El CT incluye enlaces a todos los campos de la tabla de la sección 2.1, en el orden:

1. Identificación: `GD_Codigo`, `GD_Nomenclatura`, `GD_NombreProcedimiento`
2. Tipo/aplicabilidad: `GD_Aplicabilidad`, `GD_NombreDocumentoHomologado`
3. Visualización: `GD_VisualizacionDocumento`
4. Alcance: `GD_PlantasAplicables`, `GD_LineaProceso`
5. Ciclo de vida: `GD_Version`, `GD_VigenciaHasta`, `GD_FechaEmision`, `GD_FechaActualizacion`, `GD_FechaCaducidad`
6. Responsables: `GD_RespElaboracionActualizacion`
7. Estatus: `GD_Estatus`
8. YUM: `GD_AprobadoPorYUM`, `GD_FechaVencimientoYUM`
9. Enlace GD: `GD_DocumentoGeneral`

---

## 5. Ejemplos de registros (a partir de la matriz)

| Código      | Nomenclatura | Nombre del procedimiento            | Tipo         | Planta     | Línea de proceso | Versión | Estatus     |
| ----------- | ------------ | ----------------------------------- | ------------ | ---------- | ---------------- | ------- | ----------- |
| `DF:GC:GD`  | DF-GC-001    | Procedimiento de gestión documental | General      | Ecuador    | —                | 1.0     | Aprobado    |
| `IT:GC:DFP` | IT-DFP-002   | Instructivo de fileteado de pollos  | Por producto | Planta UIO | Fileteado, Corte | 2.1     | Aprobado    |
| `IT:GC:MRN` | IT-MRN-005   | Instructivo de marinado de cárnicos | Por producto | Guayaquil  | Marinado         | 1.3     | En revisión |

---

## 6. Relación con Documentos generales

El campo `GD_DocumentoGeneral` permite **enlazar explícitamente** un Documento relacionado a su Documento general (PO/IT) padre:

- **Tipo:** Lookup — referencia directa a un ítem de la biblioteca `Gestor Documental` (campo mostrado: `Title`).
- **Creación:** el script `01-rd-sitecolumns.ps1` resuelve dinámicamente el ID de la biblioteca y crea el campo via XML. **Requiere que la biblioteca ya exista** (ejecutar `../04-library.ps1` antes).
- **Uso:** al crear un Documento relacionado, seleccionar el Documento general padre en el campo desplegable.

---

## 7. Checklist de validación post-provisioning

### Term Store

- [ ] Existe Term Set `GD - Lineas de Proceso` en grupo `GestorDocumentalGD`
- [ ] Term Set está marcado como _Closed_
- [ ] Existen los términos semilla

### Site Columns

- [ ] `GD_Nomenclatura` — Texto
- [ ] `GD_NombreDocumentoHomologado` — Texto
- [ ] `GD_VisualizacionDocumento` — URL (Hyperlink)
- [ ] `GD_DocumentoGeneral` — URL (Hyperlink)
- [ ] `GD_FechaEmision` — DateTime (DateOnly)
- [ ] `GD_LineaProceso` — Taxonomía, multi-valor

### Content Type

- [ ] Existe `GD – Relacionado` en el sitio
- [ ] Hereda de `Document`
- [ ] Grupo: `GD Content Types`
- [ ] Están enlazados todos los campos de la sección 2.1

### Biblioteca

- [ ] CT `GD – Relacionado` visible en la biblioteca destino
- [ ] Content Types habilitados en la biblioteca
