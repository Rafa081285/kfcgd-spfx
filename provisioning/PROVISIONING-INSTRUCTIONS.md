# KFCGD Provisioning (PnP.PowerShell) — Instrucciones funcionales

Este documento describe **qué hace** el provisioning y **cómo debe ejecutarse** (funcionalmente), para contrastarlo con lo implementado en los scripts PnP.PowerShell del repositorio.

> Alcance: aprovisionamiento directo en un sitio SharePoint Online (por defecto: `/sites/KFCGD`), **sin Content Type Hub**, usando PnP.PowerShell.

---

## 1) Objetivo del provisioning

Aprovisionar, de forma repetible e idempotente, los elementos necesarios para un Gestor Documental:

1. **Term Store**
   - Grupo de términos: `GestorDocumentalGD`
   - Term sets requeridos (cerrados / *Closed*) con términos semilla
2. **Site Columns base**
   - Campos tipo Texto, Choice, Fecha (solo fecha), Personas (single/multi)
3. **Taxonomy Site Columns**
   - Columnas Managed Metadata enlazadas a term sets del Term Store
4. **Content Types**
   - Content Types a nivel de sitio:
     - `GD – PO`
     - `GD – IT`
   - Heredan de `Document`
   - Incluyen field links a: site columns base + taxonomy columns
5. **Biblioteca**
   - Biblioteca de documentos (parametrizable):
     - Título por defecto: `Gestor Documental`
     - Puede cambiarse a `Documentos GD Generales` u otro nombre
   - Content Types habilitados
   - Content Types `GD – PO` y `GD – IT` añadidos a la biblioteca
   - Recomendación: **NO eliminar** el CT “Document” por defecto

---

## 2) Prerrequisitos

### 2.1 Módulo PnP.PowerShell
Instalar PnP.PowerShell:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

### 2.2 Permisos
Debes tener permisos para:
- Administrar el sitio `/sites/KFCGD`
- Administrar el Term Store (o al menos crear: grupo / term sets / términos)

---

## 3) Parámetros y convenciones

### 3.1 Parámetros comunes (todos los scripts)
- `-TenantUrl` (**obligatorio**)
  - Ej: `https://contoso.sharepoint.com`
- `-SiteRelativeUrl` (opcional)
  - Default: `/sites/KFCGD`

### 3.2 Parámetros específicos
- Term Store / taxonomía:
  - `-TermGroupName` (opcional), default: `GestorDocumentalGD`
- Biblioteca:
  - `-LibraryTitle` (opcional), default: `Gestor Documental`

### 3.3 Autenticación / Conexión
Todos los scripts deben conectarse con autenticación interactiva y con URL completo:

```powershell
$siteUrl = $TenantUrl.TrimEnd('/') + $SiteRelativeUrl
Connect-PnPOnline -Url $siteUrl -Interactive
```

> Evitar `-UseWebLogin` (obsoleto/no recomendado).

---

## 4) Orden de ejecución (recomendado)

> Ejecuta en este orden para respetar dependencias.

1. `01-termstore.ps1`  
   Crea grupo/term sets/términos (Term Store).
2. `02-sitecolumns.ps1`  
   Crea columnas base (Text/Choice/DateOnly/People).
3. `05-taxonomyfields.ps1`  
   Crea columnas Managed Metadata (MM) enlazadas al Term Store.
4. `03-contenttypes.ps1`  
   Crea content types `GD – PO` y `GD – IT` y enlaza todas las columnas (base + MM).
5. `04-library.ps1`  
   Crea biblioteca, habilita content types y añade `GD – PO` / `GD – IT`.

Ejemplo:

```powershell
.\01-termstore.ps1 -TenantUrl "https://contoso.sharepoint.com"
.\02-sitecolumns.ps1 -TenantUrl "https://contoso.sharepoint.com"
.\05-taxonomyfields.ps1 -TenantUrl "https://contoso.sharepoint.com"
.\03-contenttypes.ps1 -TenantUrl "https://contoso.sharepoint.com"
.\04-library.ps1 -TenantUrl "https://contoso.sharepoint.com" -LibraryTitle "Documentos GD Generales"
```

---

## 5) Reglas funcionales (idempotencia y consistencia)

### 5.1 Idempotencia
Cada script debe poder ejecutarse N veces sin romper:
- Si el recurso existe (grupo/term set/field/CT/biblioteca), debe “asegurarse” o saltarse.
- No debe crear duplicados.
- Debe registrar mensajes claros:
  - `created` / `exists` / `skipped` / `warning`

### 5.2 Tipos de campo base
- **Fechas**: se crean como `DateTime`, con `Format=DateOnly`.
- **Choice**: debe incluir lista de opciones exactas.
- **People**:
  - Single: campo `User` (PeopleOnly)
  - Multi: campo `User` con `Mult="TRUE"` (PeopleOnly)

### 5.3 Term sets Closed
- Los term sets deben ser “Closed” (no abiertos), para controlar el vocabulario.

### 5.4 Content Types
- Deben heredar de `Document`
- Deben incluir field links a:
  - campos base (02)
  - campos MM (05)

### 5.5 Biblioteca
- Content types habilitados
- `GD – PO` y `GD – IT` añadidos
- Recomendación: **no eliminar** el CT “Document” por defecto

---

## 6) Validación post-provisioning (checklist)

### 6.1 Term Store
- Existe el grupo `GestorDocumentalGD`
- Existen term sets esperados y están *Closed*
- Existen términos semilla

### 6.2 Site Columns
- Existen todos los campos base por InternalName (prefijo `GD_`)
- Fechas están en “solo fecha”
- People multi y single están correctos

### 6.3 Taxonomy Fields
- Existen los campos MM
- Cada campo está enlazado al term set correcto
- Multi-value en:
  - `GD_Producto`
  - `GD_PlantasAplicables`
  - `GD_HomologacionPlanta`

### 6.4 Content Types
- Existen `GD – PO` y `GD – IT`
- Heredan de `Document`
- Tienen enlazados los fields base + MM

### 6.5 Biblioteca
- Existe la biblioteca (título coincide con `-LibraryTitle`)
- Content Types habilitados
- CTs `GD – PO` y `GD – IT` están presentes

---

## 7) Módulo adicional: Documentos relacionados (`related_documents/`)

Este módulo aprovisiona el tipo documental **"Documentos relacionados"** (`GD – Relacionado`).  
Debe ejecutarse **después** del provisioning base (secciones 1–5 anteriores).

> Documentación completa: [`related_documents/README.md`](./related_documents/README.md)  
> Especificación del tipo documental: [`related_documents/DOCUMENTOS-RELACIONADOS.md`](./related_documents/DOCUMENTOS-RELACIONADOS.md)

### 7.1 Objetivo

Aprovisionar:
1. Nuevas **site columns** exclusivas: `GD_Nomenclatura`, `GD_NombreDocumentoHomologado`, `GD_VisualizacionDocumento`, `GD_DocumentoGeneral`, `GD_FechaEmision`.
2. Nuevo **Term Set** `GD - Lineas de Proceso` (Closed) + campo de taxonomía `GD_LineaProceso` (multi-valor).
3. **Content Type** `GD – Relacionado` heredando de `Document`, con los 18 campos requeridos (nuevos + reutilizados).
4. (Opcional) Agregar CT a la biblioteca.

### 7.2 Orden de ejecución completo (base + relacionados)

```powershell
$tenant = "https://contoso.sharepoint.com"

# ── Provisioning base ────────────────────────────────────────────────────────
.\01-termstore.ps1      -TenantUrl $tenant
.\02-sitecolumns.ps1    -TenantUrl $tenant
.\05-taxonomyfields.ps1 -TenantUrl $tenant
.\03-contenttypes.ps1   -TenantUrl $tenant
.\04-library.ps1        -TenantUrl $tenant -LibraryTitle "Gestor Documental"

# ── Provisioning Documentos relacionados ─────────────────────────────────────
cd related_documents
.\01-rd-sitecolumns.ps1  -TenantUrl $tenant
.\02-rd-taxonomyfield.ps1 -TenantUrl $tenant
.\03-rd-contenttype.ps1  -TenantUrl $tenant
.\04-rd-library.ps1      -TenantUrl $tenant -LibraryTitle "Gestor Documental"  # opcional
```

### 7.3 Nuevas reglas funcionales (Documentos relacionados)

- El campo `GD_DocumentoGeneral` (URL/Hyperlink) permite enlazar el documento a su Documento general (PO/IT) padre.
- El campo `GD_LineaProceso` es **multi-valor** y usa el Term Set `GD - Lineas de Proceso`.
- El Term Set `GD - Lineas de Proceso` debe crearse como **Closed**.
- Los campos reutilizados **no se recrean**; el script `01-rd-sitecolumns.ps1` solo los verifica.

### 7.4 Validación post-provisioning (Documentos relacionados)

#### Term Store
- Existe Term Set `GD - Lineas de Proceso` en `GestorDocumentalGD` (Closed)
- Existen los términos semilla (Fileteado, Corte, Cocción, etc.)

#### Site Columns nuevas
- `GD_Nomenclatura` — Texto
- `GD_NombreDocumentoHomologado` — Texto
- `GD_VisualizacionDocumento` — URL
- `GD_DocumentoGeneral` — URL
- `GD_FechaEmision` — DateTime (DateOnly)
- `GD_LineaProceso` — Taxonomía, multi-valor

#### Content Type
- Existe `GD – Relacionado` en el sitio
- Hereda de `Document`
- Están enlazados los 18 campos definidos

#### Biblioteca (si se ejecutó paso opcional)
- CT `GD – Relacionado` visible en la biblioteca destino
