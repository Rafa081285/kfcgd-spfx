# Diseño Funcional y Técnico — Gestor Documental KFC (SharePoint Online + SPFx)

**Fecha:** 2026-04-26  
**Sitio:** `/sites/KFCGD`  
**Idioma:** ES  
**Modelo inicial:** Modelo A (una sola biblioteca: **Gestor Documental**)  

---

## 1. Objetivo

Este documento consolida el diseño acordado para:

1) Tipos documentales y Tipos de contenido (Content Types)  
2) Columnas de sitio (Site Columns) y reglas de metadatos  
3) Taxonomía (Term Store) para metadatos administrados  
4) Navegación por árbol (SPFx) + listado filtrado por `nodeId` usando `nav.json`  
5) Páginas y comportamiento de la solución SPFx

---

## 2. Tipos documentales y Tipos de Contenido (Content Types)

### 2.1 Principio de modelado
- El **tipo documental** se controla mediante **Content Types** (PO, IT, etc.).
- La **clasificación** y navegación se gestiona mediante **metadatos** (Categoría, Ámbito, Producto/Familia, Plantas, Confidencialidad, etc.).
- La **Aplicabilidad** (General / Por producto) se maneja como **Choice** por simplicidad y robustez.
- Se mantiene `Vigencia` y `Fecha de caducidad` como **dos campos distintos** por el momento (pendiente de refinación futura).

### 2.2 Tipos de contenido propuestos (MVP)
1) **GD – PO (Procedimiento Operativo)** *(hereda de Document)*  
2) **GD – IT (Instructivo)** *(hereda de Document)*  

> Extensible (cuando se requiera): GD – Política, GD – Manual, GD – Registro/Formulario, etc.

### 2.3 Biblioteca de documentos (Modelo A)
- **Biblioteca única:** `Gestor Documental`
- Contiene todos los documentos de todos los Content Types.
- Se recomienda habilitar:
  - Versioning
  - (Opcional) Content Approval / flujo de aprobación
  - Content Types habilitados en la biblioteca

---

## 3. Columnas de sitio (Site Columns) — Diccionario de Datos

> Nota: se definen **nombres internos estables** (sin espacios/acentos) para evitar fricción técnica.

### 3.1 Identificación
| Columna (visible) | Nombre interno | Tipo | Requerido | Multi | Detalle |
|---|---|---|---|---|---|
| Código | `GD_Codigo` | Texto (1 línea) | Sí | No | Estandarizar formato (ej. `PO:GC:GD`). |
| Nombre del procedimiento | `GD_NombreProcedimiento` | Texto (1 línea) | Sí | No | Útil aunque exista nombre de archivo. |

### 3.2 Clasificación (core)
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Categoría | `GD_Categoria` | Taxonomía (MM) | Sí | No | Term set: **GD - Categoría**. |
| Alcance | `GD_Alcance` | Taxonomía (MM) | Sí | No | Term set: **GD - Alcance**. |
| Confidencialidad | `GD_Confidencialidad` | Taxonomía (MM) | Sí | No | Term set: **GD - Confidencialidad** (incluye Confidencial YUM). |
| Aplicabilidad | `GD_Aplicabilidad` | Choice | Sí | No | `General` / `Por producto`. |
| Producto / Familia / SKU | `GD_Producto` | Taxonomía (MM) | Cond. | Sí | **Requerido si** Aplicabilidad=Por producto. Term set Closed. |
| Producto (texto auxiliar) | `GD_ProductoLabels` | Texto (1 línea) | No | No | Auxiliar para filtros robustos (valores separados por `;`). |

**Regla funcional (acordada):**  
- Si `GD_Aplicabilidad = Por producto` ⇒ `GD_Producto` requerido y `GD_ProductoLabels` se llena automáticamente (Power Automate).

### 3.3 Organización / Responsables
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Departamento responsable | `GD_DepartamentoResponsable` | Taxonomía (MM) | Sí | No | Term set: GD - Áreas/Departamentos. |
| Cargo del líder del PO | `GD_CargoLiderPO` | Taxonomía (MM) | No | No | Term set: GD - Cargos/Roles. |
| Responsable principal | `GD_ResponsablePrincipal` | Persona | No | No | |
| Responsable elaboración/actualización | `GD_RespElaboracionActualizacion` | Persona | No | Sí | |
| Responsable revisión | `GD_RespRevision` | Persona | No | Sí | |
| Responsable aprobación | `GD_RespAprobacion` | Persona | No | Sí | |

### 3.4 Plantas / Aplicabilidad / Homologación
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Plantas aplicables | `GD_PlantasAplicables` | Taxonomía (MM) | Sí | Sí | Term set: GD - Plantas y Centros. |
| HomologaciónPlanta (referencia) | `GD_HomologacionPlanta` | Taxonomía (MM) | No | Sí | Confirmado: **multi-valor** y distinto de plantas aplicables. |
| Fecha de homologación | `GD_FechaHomologacion` | Fecha | No | No | |

### 3.5 Ciclo de vida (fechas / versión)
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Versión | `GD_Version` | Texto (1 línea) | Sí | No | |
| Fecha divulgación | `GD_FechaDivulgacion` | Fecha | No | No | |
| Fecha actualización | `GD_FechaActualizacion` | Fecha | No | No | |
| Motivo actualización | `GD_MotivoActualizacion` | Choice (o MM futuro) | No | No | |
| Vigencia | `GD_VigenciaHasta` | Fecha | No | No | Mantener por ahora. |
| Fecha de caducidad | `GD_FechaCaducidad` | Fecha | No | No | Mantener por ahora. |

### 3.6 Estado / Flujo
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Estatus | `GD_Estatus` | Choice | Sí | No | `Borrador` / `En revisión` / `Aprobado` / `Rechazado` / `Obsoleto`. |

### 3.7 YUM (condicional)
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Aprobado por YUM | `GD_AprobadoPorYUM` | Persona (o texto) | No | No | |
| Fecha vencimiento YUM | `GD_FechaVencimientoYUM` | Fecha | No | No | |

### 3.8 Continuidad
| Columna | Interno | Tipo | Req. | Multi | Detalle |
|---|---|---|---|---|---|
| Impacto continuidad | `GD_ImpactoContinuidad` | Choice | No | No | Alto/Medio/Bajo. |

### 3.9 Columnas habilitadoras de navegación (acordadas)
| Columna | Interno | Tipo | Req. | Multi | Valores / Term set |
|---|---|---|---|---|---|
| Tipo de proceso | `GD_TipoProceso` | Choice | Sí (recomendado) | No | `Proceso de Manufactura` / `Administrativos Transversales de cada Planta` |
| Ámbito/Programa | `GD_AmbitoPrograma` | Taxonomía (MM) | No | No | Term set: GD - Ámbito/Programa |

---

## 4. Taxonomía (Term Store)

### 4.1 Gobernanza acordada
- Term sets sensibles (Producto, Plantas, Categoría, Confidencialidad, etc.) en estado: **Closed**.
- Se asigna **Term Set Owner** (p. ej. Gestión Documental/Calidad).
- Proceso recomendado: solicitud de alta de término (Teams/Form/Power Automate).

### 4.2 Estructura (en Markdown)
```markdown
Term Group: Gestor Documental (GD)

- Term Set: GD - Categoría  (Closed)
  - Transversales Ecuador (Manufactura)
  - Transversales Ecuador (Administrativos)
  - Regional de Manufactura
  - Franquicias
    - YUM
    - Juan Valdez
    - Baskin Robbins
    - Otras

- Term Set: GD - Alcance  (Closed)
  - Regional
  - Nacional

- Term Set: GD - Confidencialidad  (Closed)
  - Interno
  - Confidencial
  - Confidencial YUM

- Term Set: GD - Plantas y Centros  (Closed)
  - Ecuador
    - Planta UIO
    - Guayaquil
    - CD Mancha

- Term Set: GD - Producto / Familia / SKU  (Closed)
  - Pollos
  - Vegetales
  - Cárnicos
  - Pastelería
  - Cocina
  - Hamburguesas
    - (opcional: productos específicos)

- Term Set: GD - Áreas / Departamentos  (Closed)
  - Calidad
  - Mantenimiento
  - Mantenimiento / Calidad
  - Legal

- Term Set: GD - Cargos / Roles  (Closed)
  - Coordinador de Gestión Documental
  - Jefe de Mantenimiento
  - Supervisora laboratorio

- Term Set: GD - Ámbito/Programa  (Closed)
  - KFC YUM
  - KFC REGIONAL
  - KFC AUDITORIAS YUM
  - ECUADOR: MARCAS NACIONALES

- Term Set: GD - Motivo de Actualización (Opcional)
  - Actualización normativa
  - Auditoría interna
  - Auditoría externa
  - Mejora de proceso
  - Cambio operativo
```

---

## 5. Navegación (SPFx) + JSON + páginas

### 5.1 Principio de navegación
- Se representa toda la estructura con un **árbol SPFx**.
- Cada clic navega a una **página única de resultados** pasando `nodeId` por querystring:
  - `/sites/KFCGD/SitePages/gd-listado.aspx?nodeId=<id>`

### 5.2 Justificación
- Los filtros quedan centralizados en `nav.json`.
- Evita crear/mantener muchas páginas con filtros manuales.
- Permite cambiar navegación sin redeploy (solo actualizando `nav.json`).

### 5.3 `nav.json` — esquema (resumen)
- `schemaVersion`
- `site.serverRelativeUrl`
- `results.page`
- `results.nodeIdQueryParam`
- `nodes[]` (id/label/filters/children)
- `filters[]` con `op`: `eq`, `in`, `containsTerm`

**Nota importante (acordada):**  
- Para producto (taxonomía multi) se filtra con `containsTerm` sobre la columna auxiliar **`GD_ProductoLabels`**.

### 5.4 Páginas en SharePoint (mínimas)
1) `gd-inicio.aspx`  
   - Webpart: **GD-Navegación**
2) `gd-listado.aspx`  
   - Webpart: **GD-Listado**

### 5.5 Funcionalidad SPFx (resumen)
**GD-Navegación**
- Lee `nav.json` desde una URL configurable (ej. biblioteca “Configuración”).
- Renderiza árbol (Fluent UI Nav/Tree).
- Navega a results page con `nodeId`.

**GD-Listado**
- Lee `nav.json`.
- Obtiene `nodeId` de la URL.
- Busca el nodo por DFS.
- Construye CAML `<Where>` con AND de filtros.
- Consulta biblioteca “Gestor Documental” con `renderListDataAsStream`.
- Renderiza tabla `DetailsList` con columnas:
  - Código (`GD_Codigo`)
  - Nombre (link) (`FileLeafRef` + `FileRef`)
  - Tipo documento (`ContentType`)
  - Planta(s) aplicables (`GD_PlantasAplicables`)
  - Vigencia (`GD_VigenciaHasta`)
  - Caducidad (`GD_FechaCaducidad`)
  - Estatus (`GD_Estatus`)
  - Modificado (`Modified`)

---

## 6. Prototipo visual (mockup) — Página de inicio (gd-inicio.aspx)

### 6.1 Mockup en ASCII (para Word)
> Recomendación: pegarlo con fuente **Consolas** para que se vea alineado.

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│  Sitio: /sites/KFCGD                                                                          │
│  Página: gd-inicio.aspx  —  Gestor Documental (Inicio)                                         │
├───────────────────────────────┬───────────────────────��───────────────────────────────────────┤
│  NAVEGACIÓN (GD-Navegación)   │  PANEL / INSTRUCCIONES (opcional)                              │
│  (árbol completo expandido)   │  - Seleccione un nodo para ver documentos filtrados            │
│                               │  - Los resultados se abren en: gd-listado.aspx?nodeId=...     │
│  ▾ Generales PO               │                                                               │
│    ▾ Proceso de Manufactura   │  Accesos rápidos (opcional):                                   │
│      • KFC YUM                │  [PO Vigentes] [PO Vencidos] [Próximos a vencer]               │
│      • KFC Regional           │                                                               │
│      • KFC Auditorías YUM     │  Estado del sistema (opcional):                                │
│      • Pollos                 │  - Biblioteca: Gestor Documental                               │
│      • Vegetales              │  - Configuración: /Configuración/nav.json                      │
│      • Pastelería             │                                                               │
│      • Cocina                 │                                                               │
│      • IT de elaboración      │                                                               │
│        de hamburguesas        │                                                               │
│                               │                                                               │
│    ▾ Administrativos          │                                                               │
│      transversales de cada    ��                                                               │
│      planta                   │                                                               │
│      ▾ Ecuador: Marcas        │                                                               │
│        Nacionales             │                                                               │
│        • Cárnicos             │                                                               │
│        • Pollos               │                                                               │
│        • Vegetales            │                                                               │
│        • Cocina               │                                                               │
│        • Pastelería           │                                                               │
│                               │                                                               │
├───────────────────────────────┴───────────────────────────────────────────────────────────────┤
│  Footer (opcional): Soporte / Contacto / Versión del nav.json                                  │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Imagen (SVG) para insertar en Word
**Instrucción:** copia el contenido siguiente en un archivo llamado `mockup-gd-inicio.svg` y luego en Word ve a:  
**Insertar → Imágenes → Este dispositivo**.

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="820">
  <style>
    .frame { fill: #ffffff; stroke: #1f2937; stroke-width: 2; }
    .header { fill: #f3f4f6; stroke: #1f2937; stroke-width: 2; }
    .panelTitle { font: 700 18px 'Segoe UI', Arial; fill: #111827; }
    .text { font: 14px 'Segoe UI', Arial; fill: #111827; }
    .muted { font: 14px 'Segoe UI', Arial; fill: #374151; }
    .tree { font: 14px 'Consolas', 'Courier New', monospace; fill: #111827; }
    .divider { stroke: #1f2937; stroke-width: 2; }
    .box { fill: #ffffff; stroke: #9ca3af; stroke-width: 1.5; }
    .pill { fill: #e5e7eb; stroke: #9ca3af; stroke-width: 1; }
    .pillText { font: 13px 'Segoe UI', Arial; fill: #111827; }
  </style>

  <rect x="20" y="20" width="1360" height="780" class="frame"/>
  <rect x="20" y="20" width="1360" height="70" class="header"/>
  <text x="45" y="55" class="panelTitle">Sitio: /sites/KFCGD</text>
  <text x="45" y="78" class="muted">Página: gd-inicio.aspx — Gestor Documental (Inicio)</text>

  <line x1="460" y1="90" x2="460" y2="800" class="divider"/>

  <text x="45" y="125" class="panelTitle">NAVEGACIÓN (GD-Navegación)</text>
  <text x="45" y="148" class="muted">Árbol completo expandido</text>

  <text x="490" y="125" class="panelTitle">PANEL / INSTRUCCIONES (opcional)</text>

  <rect x="490" y="145" width="865" height="240" class="box"/>
  <text x="510" y="175" class="text">• Seleccione un nodo para ver documentos filtrados</text>
  <text x="510" y="200" class="text">• Resultados en: gd-listado.aspx?nodeId=...</text>
  <text x="510" y="235" class="text">Accesos rápidos (opcional):</text>

  <rect x="510" y="250" rx="16" ry="16" width="130" height="32" class="pill"/>
  <text x="525" y="271" class="pillText">PO Vigentes</text>
  <rect x="650" y="250" rx="16" ry="16" width="130" height="32" class="pill"/>
  <text x="665" y="271" class="pillText">PO Vencidos</text>
  <rect x="790" y="250" rx="16" ry="16" width="180" height="32" class="pill"/>
  <text x="805" y="271" class="pillText">Próximos a vencer</text>

  <text x="510" y="320" class="text">Estado del sistema (opcional):</text>
  <text x="510" y="345" class="muted">- Biblioteca: Gestor Documental</text>
  <text x="510" y="368" class="muted">- Configuración: /Configuración/nav.json</text>

  <rect x="45" y="165" width="395" height="610" class="box"/>

  <text x="60" y="195" class="tree">▾ Generales PO</text>
  <text x="80" y="220" class="tree">▾ Proceso de Manufactura</text>
  <text x="100" y="245" class="tree">• KFC YUM</text>
  <text x="100" y="270" class="tree">• KFC Regional</text>
  <text x="100" y="295" class="tree">• KFC Auditorías YUM</text>
  <text x="100" y="320" class="tree">• Pollos</text>
  <text x="100" y="345" class="tree">• Vegetales</text>
  <text x="100" y="370" class="tree">• Pastelería</text>
  <text x="100" y="395" class="tree">• Cocina</text>
  <text x="100" y="420" class="tree">• IT de elaboración de hamburguesas</text>

  <text x="80" y="465" class="tree">▾ Administrativos transversales de cada planta</text>
  <text x="100" y="490" class="tree">▾ Ecuador: Marcas Nacionales</text>
  <text x="120" y="515" class="tree">• Cárnicos</text>
  <text x="120" y="540" class="tree">• Pollos</text>
  <text x="120" y="565" class="tree">• Vegetales</text>
  <text x="120" y="590" class="tree">• Cocina</text>
  <text x="120" y="615" class="tree">• Pastelería</text>

  <rect x="20" y="760" width="1360" height="40" class="header"/>
  <text x="45" y="786" class="muted">Footer (opcional): Soporte / Contacto / Versión del nav.json</text>
</svg>
```

**Pie de figura sugerido (para Word):**  
**Figura X — Prototipo visual de `gd-inicio.aspx`:** Panel izquierdo con árbol completo de navegación (webpart GD-Navegación). Panel derecho opcional con instrucciones y accesos rápidos. Cada nodo redirige a `gd-listado.aspx?nodeId=<id>`, donde el webpart GD-Listado consulta la biblioteca “Gestor Documental” aplicando filtros definidos en `nav.json`.

---

## 7. Anexos

### 7.1 Checklist de implementación (SharePoint)
1) Crear biblioteca: **Gestor Documental**  
2) Crear columnas con los nombres internos definidos en la sección 3  
3) Crear term sets (sección 4)  
4) Crear biblioteca: **Configuración** y subir `nav.json`  
5) Crear páginas:
   - `gd-inicio.aspx` (webpart navegación)
   - `gd-listado.aspx` (webpart listado)
6) (Power Automate) poblar `GD_ProductoLabels` desde `GD_Producto` en create/update  
7) Publicar y validar permisos

### 7.2 Nota técnica — `GD_ProductoLabels`
Se utiliza para filtrar por “Producto/Familia” sin depender de IDs internos de taxonomía, permitiendo consultas CAML con `Contains` de forma consistente.
