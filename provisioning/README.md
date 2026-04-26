# KFCGD Provisioning (PnP PowerShell)

This folder contains PnP.PowerShell scripts to provision SharePoint Online resources directly in **/sites/KFCGD** (no Content Type Hub), using a tenant URL parameter.

## Prerequisites

- Install PnP.PowerShell:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

- You must have permission to:
  - Manage the site `/sites/KFCGD`
  - Manage Term Store (or at least create groups/term sets/terms)

## Parameters (all scripts)

- `-TenantUrl` (**required**) e.g. `https://contoso.sharepoint.com`
- `-SiteRelativeUrl` (optional) default: `/sites/KFCGD`
- `-TermGroupName` (optional) default: `GestorDocumentalGD` (no spaces)

## Execution order (recommended)

> Run in this exact order to satisfy dependencies.

```powershell
# 1) Term Store group + term sets (Closed) + terms
.
\01-termstore.ps1 -TenantUrl "https://contoso.sharepoint.com"

# 2) Base site columns (Text/Choice/Date/People)
.
\02-sitecolumns.ps1 -TenantUrl "https://contoso.sharepoint.com"

# 3) Site content types: GD – PO, GD – IT (attach base fields)
.
\03-contenttypes.ps1 -TenantUrl "https://contoso.sharepoint.com"

# 4) Managed Metadata site columns bound to Term Sets + attach to CTs
.
\05-taxonomyfields.ps1 -TenantUrl "https://contoso.sharepoint.com"

# 5) Create library "Gestor Documental" + enable CTs + add CTs
.
\04-library.ps1 -TenantUrl "https://contoso.sharepoint.com"
```

## Scripts

- `01-termstore.ps1`
  - Creates/ensures Term Group `GestorDocumentalGD`
  - Creates/ensures Term Sets **Closed** and the initial terms (MVP)

- `02-sitecolumns.ps1`
  - Creates base Site Columns (internal names agreed in the design document)

- `03-contenttypes.ps1`
  - Creates site content types inheriting from `Document`:
    - `GD – PO`
    - `GD – IT`
  - Attaches base fields

- `05-taxonomyfields.ps1`
  - Creates Managed Metadata fields bound to the Term Sets in `GestorDocumentalGD`
  - Important multi-value fields (confirmed):
    - `GD_Producto` (multi)
    - `GD_PlantasAplicables` (multi)
  - Attaches taxonomy fields to `GD – PO` and `GD – IT`

- `04-library.ps1`
  - Creates the library `Gestor Documental`
  - Enables content types
  - Adds `GD – PO` and `GD – IT`

## Related documents provisioning

An additional provisioning module for the **"Documentos relacionados"** content type is available in:

```
provisioning/related_documents/
```

It must be run **after** the base provisioning above. See [`related_documents/README.md`](./related_documents/README.md) for details.

Quick execution order (after base provisioning):

```powershell
cd related_documents
.\01-rd-sitecolumns.ps1  -TenantUrl "https://contoso.sharepoint.com"
.\02-rd-taxonomyfield.ps1 -TenantUrl "https://contoso.sharepoint.com"
.\03-rd-contenttype.ps1  -TenantUrl "https://contoso.sharepoint.com"
.\04-rd-library.ps1      -TenantUrl "https://contoso.sharepoint.com"   # optional
```

---

## Notes

- Scripts are intended to be idempotent (re-running should skip already existing resources).
- If `Add-PnPTaxonomyField` parameter names differ in your PnP.PowerShell version, update the script accordingly.
