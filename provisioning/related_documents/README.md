# Provisioning — Documentos relacionados

Esta carpeta contiene los scripts PnP.PowerShell para aprovisionar el tipo documental **"Documentos relacionados"** (`GD – Relacionado`) en SharePoint Online.

> Para el contexto completo (columnas, term store, content type y biblioteca), consulta [`DOCUMENTOS-RELACIONADOS.md`](./DOCUMENTOS-RELACIONADOS.md).

---

## Prerrequisitos

1. Haber ejecutado previamente los scripts de la carpeta padre (`provisioning/`):
   - `01-termstore.ps1` — Term Group y Term Sets base
   - `02-sitecolumns.ps1` — Site columns base
   - `05-taxonomyfields.ps1` — Campos de taxonomía base
   - `04-library.ps1` — Biblioteca destino
2. Tener instalado PnP.PowerShell:
   ```powershell
   Install-Module PnP.PowerShell -Scope CurrentUser
   ```
3. Permisos de administración sobre el sitio `/sites/KFCGD` y acceso al Term Store.

---

## Orden de ejecución

> Ejecuta en este orden exacto para respetar dependencias.

```powershell
# Parámetros comunes
$tenant = "https://contoso.sharepoint.com"

# 1) Nuevas columnas base de Documentos relacionados
.\01-rd-sitecolumns.ps1 -TenantUrl $tenant

# 2) Term Set "GD - Lineas de Proceso" + campo GD_LineaProceso
.\02-rd-taxonomyfield.ps1 -TenantUrl $tenant

# 3) Content Type "GD – Relacionado" + field links
.\03-rd-contenttype.ps1 -TenantUrl $tenant

# 4) (Opcional) Agregar CT a la biblioteca
.\04-rd-library.ps1 -TenantUrl $tenant -LibraryTitle "Gestor Documental"
```

> El paso 4 es **opcional**: solo necesario si quieres que el CT `GD – Relacionado` esté disponible para crear documentos directamente en la biblioteca. Pasa el nombre de tu biblioteca con `-LibraryTitle`.

---

## Scripts

### `01-rd-sitecolumns.ps1`

Crea las nuevas site columns exclusivas de "Documentos relacionados":

| Campo | Tipo | Descripción |
|---|---|---|
| `GD_Nomenclatura` | Texto | Nomenclatura o sigla del documento |
| `GD_NombreDocumentoHomologado` | Texto | Nombre del documento homologado de referencia |
| `GD_VisualizacionDocumento` | URL (Hyperlink) | Enlace directo al archivo |
| `GD_DocumentoGeneral` | URL (Hyperlink) | Enlace al documento general (PO/IT) relacionado |
| `GD_FechaEmision` | Fecha (DateOnly) | Fecha de emisión del documento |

También verifica (sin crearlos) que los campos reutilizados de Documentos generales ya existan.

**Parámetros:**
- `-TenantUrl` (**obligatorio**)
- `-SiteRelativeUrl` (opcional, default: `/sites/KFCGD`)

---

### `02-rd-taxonomyfield.ps1`

Crea el Term Set `GD - Lineas de Proceso` (Closed) con términos semilla, y el campo de taxonomía `GD_LineaProceso` (multi-valor).

**Términos semilla:** Fileteado, Corte, Cocción, Marinado, Empaque, Congelación, Distribución, Control de Calidad, Limpieza y Desinfección, Mantenimiento.

**Parámetros:**
- `-TenantUrl` (**obligatorio**)
- `-SiteRelativeUrl` (opcional, default: `/sites/KFCGD`)
- `-TermGroupName` (opcional, default: `GestorDocumentalGD`)

---

### `03-rd-contenttype.ps1`

Crea el Content Type `GD – Relacionado` heredando de `Document` y enlaza los 18 campos definidos para este tipo documental.

**Parámetros:**
- `-TenantUrl` (**obligatorio**)
- `-SiteRelativeUrl` (opcional, default: `/sites/KFCGD`)

---

### `04-rd-library.ps1` *(opcional)*

Agrega el Content Type `GD – Relacionado` a la biblioteca especificada.  
La biblioteca debe existir previamente (creada por `../04-library.ps1`).

**Parámetros:**
- `-TenantUrl` (**obligatorio**)
- `-SiteRelativeUrl` (opcional, default: `/sites/KFCGD`)
- `-LibraryTitle` (opcional, default: `Gestor Documental`)

---

## Idempotencia

Todos los scripts son idempotentes: pueden ejecutarse N veces sin crear duplicados.  
Si un recurso ya existe, se registra `"exists (skip)"` y se continúa.

---

## Campos reutilizados de Documentos generales

Los siguientes campos ya existen en el sitio (creados por los scripts base) y son enlazados al CT `GD – Relacionado` sin recrearlos:

`GD_Codigo`, `GD_NombreProcedimiento`, `GD_Aplicabilidad`, `GD_Version`,
`GD_VigenciaHasta`, `GD_FechaActualizacion`, `GD_FechaCaducidad`,
`GD_RespElaboracionActualizacion`, `GD_Estatus`, `GD_AprobadoPorYUM`,
`GD_FechaVencimientoYUM`, `GD_PlantasAplicables`
