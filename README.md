# kfcgd-spfx

SPFx 1.18.2 solution for KFC Gestor Documental on `/sites/KFCGD`.

## Webparts

| Webpart | Description |
|---|---|
| `gdNavigation` | Renders a collapsible nav tree from `nav.json` using Fluent UI `Nav` |
| `gdResults` | Reads `nodeId` from URL, builds CAML query, renders results in `DetailsList` |

## Common Utilities (`src/common/`)

- `INavNode.ts` – TypeScript interfaces for nav config, nodes and filters
- `navConfig.ts` – loads `nav.json` via PnPjs `sp.web.getFileByServerRelativePath`
- `queryString.ts` – parses query-string parameters from `window.location.search`
- `camlBuilder.ts` – builds CAML `<Where>` / `<View>` XML from node filters
- `nodeUtils.ts` – DFS search to find a node by id in the nav tree

## nav.json

Upload `nav.sample.json` to `/sites/KFCGD/SiteAssets/nav.json` and customise the nodes/filters to match your content types and metadata.

## Setup

```bash
npm install
gulp bundle          # development build
gulp bundle --ship   # production build
gulp package-solution --ship
```

## Webpart Properties

### gdNavigation
| Property | Default | Description |
|---|---|---|
| `navJsonUrl` | `/sites/KFCGD/SiteAssets/nav.json` | Server-relative path to nav.json |
| `resultsPageUrl` | `/sites/KFCGD/SitePages/resultados.aspx` | Results page URL |
| `nodeIdParam` | `nodeId` | Query-string parameter name for node id |

### gdResults
| Property | Default | Description |
|---|---|---|
| `navJsonUrl` | `/sites/KFCGD/SiteAssets/nav.json` | Server-relative path to nav.json |
| `nodeIdParam` | `nodeId` | Query-string parameter name for node id |
| `libraryTitle` | `Gestor Documental` | Title of the SharePoint document library |
