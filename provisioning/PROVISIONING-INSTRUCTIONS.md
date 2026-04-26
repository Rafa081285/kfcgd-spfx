# KFCGD Provisioning (PnP.PowerShell)  

## Instrucciones funcionales  

### Requisitos previos  
1. Tener instalado PnP.PowerShell en su entorno.  
2. Confirmar que tiene permisos de administrador en el sitio SharePoint.

### Pasos de provisión  
1. Conéctese al sitio de SharePoint utilizando:
   ```powershell
   Connect-PnPOnline -Url https://su-sitio.sharepoint.com -UseWebLogin
   ```
2. Ejecute los siguientes comandos para crear las listas requeridas:
   ```powershell
   # Crear listas
   New-PnPList -Title "Nombre de la Lista" -Template GenericList
   ```
3. Asegúrese de verificar la configuración de las listas una vez creadas.  

### Consideraciones finales  
Es recomendable ejecutar estos pasos en un entorno de prueba antes de aplicarlos en producción.