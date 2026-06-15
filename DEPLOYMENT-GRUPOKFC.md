# KFCGD SPFx Deployment a grupokfc.sharepoint.com

Esta rama (`kfcdeploy`) contiene todo lo necesario para desplegar la solución kfcgd-spfx en el tenant `grupokfc.sharepoint.com` y crear la página de inicio en el sitio `ecu-devgestioncalidadplt`.

## Requisitos previos

- ✅ PnP.PowerShell instalado: `Install-Module PnP.PowerShell -Scope CurrentUser`
- ✅ Node.js 20.x y npm instalados
- ✅ Acceso al tenant `grupokfc.sharepoint.com` con permisos de SharePoint Admin
- ✅ Cliente registrado en Entra ID:
  - **Client ID**: `4a4d6fb0-7423-40c8-a95c-e46662d3cf3d`
  - **Tenant**: `grupokfc.onmicrosoft.com`
- ✅ App Catalog en: `https://grupokfc.sharepoint.com/sites/aplicaciones`
- ✅ Sitio destino: `https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt`

## Paso 1: Provisioning del sitio (COMPLETADO)

Los scripts de provisioning ya se ejecutaron en el sitio destino:

- ✅ Term Store creado
- ✅ Site Columns agregadas
- ✅ Taxonomy Fields creadas
- ✅ Content Types configurados
- ✅ Bibliotecas creadas

> Ver `provisioning/PROVISIONING-INSTRUCTIONS.md` para detalles

## Paso 2: Build y packaging

```powershell
# En la raíz del proyecto
npm install
npx gulp bundle --ship
npx gulp package-solution --ship
```

Esto genera: `sharepoint/solution/kfcgd-spfx.sppkg`

## Paso 3: Deployment a grupokfc

```powershell
# Desde la carpeta provisioning/
cd provisioning
.\deploy-grupokfc.ps1
```

**El script hará automáticamente:**

1. ✅ Sube el `.sppkg` al App Catalog (`/sites/aplicaciones`)
2. ✅ Instala la app en el sitio `ecu-devgestioncalidadplt`
3. ✅ Crea la página `inicio.aspx` con los webparts configurados

### Parámetros (opcionales)

Si necesitas usar valores diferentes, pasa los parámetros:

```powershell
.\deploy-grupokfc.ps1 -AppCatalogUrl "https://grupokfc.sharepoint.com/sites/aplicaciones" `
                      -TargetSiteUrl "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt" `
                      -PageName "inicio" `
                      -SolutionPackagePath "../../sharepoint/solution/kfcgd-spfx.sppkg"
```

## URLs importantes

| Elemento          | URL                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------ |
| **Tenant**        | https://grupokfc.sharepoint.com                                                      |
| **App Catalog**   | https://grupokfc.sharepoint.com/sites/aplicaciones                                   |
| **Sitio destino** | https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt                       |
| **Página inicio** | https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt/SitePages/inicio.aspx |

## Archivos de asset necesarios

Asegúrate de que existan en el sitio destino:

- `/SiteAssets/nav.json` — Estructura de navegación
- `/SitePages/resultados.aspx` — Página de resultados

## Troubleshooting

### "App already installed"

- Normal, significa que el deployment anterior fue exitoso

### "Cannot connect to tenant"

- Verifica que las credenciales sean válidas y que el Client ID tenga permisos en el tenant

### "Page creation failed"

- Verifica que el sitio destino esté completamente provisionado
- Intenta crear la página manualmente desde SharePoint UI y luego agrega los webparts

## Revertir cambios

Si necesitas revertir:

```powershell
Connect-PnPOnline -Url "https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt" `
                   -ClientId "4a4d6fb0-7423-40c8-a95c-e46662d3cf3d" `
                   -Tenant "grupokfc.onmicrosoft.com" `
                   -Interactive

# Eliminar la página
Remove-PnPClientSidePage -Identity "inicio.aspx" -Force

# Desinstalar la app
Uninstall-PnPApp -Identity "d1e1c7e0-1234-4567-abcd-ef1234567890"
```

## Próximos pasos después del deployment

1. Abre la página: `https://grupokfc.sharepoint.com/sites/ecu-devgestioncalidadplt/SitePages/inicio.aspx`
2. Verifica que los webparts aparezcan correctamente
3. Configura los webparts si es necesario (vía UI)
4. Valida que la navegación y búsqueda funcionen

---

**Rama**: `kfcdeploy`  
**Fecha**: Junio 2026  
**Tenant destino**: `grupokfc.sharepoint.com`
