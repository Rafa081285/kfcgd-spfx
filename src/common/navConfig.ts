import { SPFI } from '@pnp/sp';
import '@pnp/sp/fields';
import { INavConfig, INavNode } from './INavNode';

interface ITaxonomyHiddenItem {
  Title?: string;
  IdForTerm?: string;
  IdForTermSet?: string;
  Path?: string;
}

interface IFieldInfo {
  SchemaXml?: string;
}

const CATEGORY_TERM_SET_NAME = 'GD - Categoria';
const CATEGORY_TERM_SET_ID_FALLBACK = '6a7c2e6b-ad9f-4016-a819-65eac475cf56';
const ROOT_NODE_ID = 'po';
const ROOT_NODE_LABEL = 'PO Generales';
const PO_CONTENT_TYPE = 'GD – PO';

function normalizePath(pathValue: string | undefined, title: string): string[] {
  const source = pathValue && pathValue.trim().length > 0 ? pathValue : title;
  return source
    .split(';')
    .map(segment => segment.trim())
    .filter(segment => segment.length > 0);
}

function sanitizeNodeId(value: string): string {
  return value
    .toLowerCase()
    .replace(/[áàäâ]/g, 'a')
    .replace(/[éèëê]/g, 'e')
    .replace(/[íìïî]/g, 'i')
    .replace(/[óòöô]/g, 'o')
    .replace(/[úùüû]/g, 'u')
    .replace(/ñ/g, 'n')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function resolveNavConfigPath(navJsonUrl: string, webServerRelativeUrl: string): string {
  if (!navJsonUrl || navJsonUrl.trim().length === 0) {
    return `${webServerRelativeUrl.replace(/\/$/, '')}/SiteAssets/nav.json`;
  }

  const trimmed = navJsonUrl.trim();
  if (/^https?:\/\//i.test(trimmed)) {
    // Absolute URL cannot be used with getFileByServerRelativePath; fallback to default site asset path.
    return `${webServerRelativeUrl.replace(/\/$/, '')}/SiteAssets/nav.json`;
  }

  if (trimmed.indexOf('/') === 0) {
    const webRoot = webServerRelativeUrl.replace(/\/$/, '');
    const webRootWithSlash = `${webRoot.toLowerCase()}/`;
    if (trimmed.toLowerCase().indexOf(webRootWithSlash) === 0) {
      return trimmed;
    }

    return `${webRoot}${trimmed}`;
  }

  return `${webServerRelativeUrl.replace(/\/$/, '')}/${trimmed}`;
}

function extractTermSetIdFromSchemaXml(schemaXml: string | undefined): string | null {
  if (!schemaXml) {
    return null;
  }

  const match = schemaXml.match(/TermSetId="\{?([0-9a-fA-F-]{36})\}?"/i);
  if (!match || !match[1]) {
    return null;
  }

  return match[1].toLowerCase();
}

async function resolveCategoryTermSetId(sp: SPFI): Promise<string> {
  try {
    const field = await sp.web.fields
      .getByInternalNameOrTitle('GD_Categoria')
      .select('SchemaXml')<IFieldInfo>();

    const extracted = extractTermSetIdFromSchemaXml(field.SchemaXml);
    if (extracted) {
      return extracted;
    }
  } catch (fieldError) {
    // fallback below
  }

  return CATEGORY_TERM_SET_ID_FALLBACK;
}

function ensureChildNode(parentNode: INavNode, pathParts: string[], termId: string): void {
  let currentNode = parentNode;

  pathParts.forEach((part, index) => {
    const nodeId = index === pathParts.length - 1
      ? `${ROOT_NODE_ID}-${sanitizeNodeId(part)}-${termId.toLowerCase()}`
      : `${ROOT_NODE_ID}-${sanitizeNodeId(pathParts.slice(0, index + 1).join('-'))}`;

    if (!currentNode.children) {
      currentNode.children = [];
    }

    let nextNode: INavNode | undefined;
    for (let childIndex = 0; childIndex < currentNode.children.length; childIndex++) {
      const child = currentNode.children[childIndex];
      if (child.label === part) {
        nextNode = child;
        break;
      }
    }
    if (!nextNode) {
      nextNode = {
        id: nodeId,
        label: part,
        filters: [
          { field: 'ContentType', op: 'eq', value: PO_CONTENT_TYPE },
          { field: 'GD_Categoria', op: 'containsTerm', value: part }
        ],
        children: []
      };
      currentNode.children.push(nextNode);
    }

    currentNode = nextNode;
  });
}

async function loadTaxonomyNavigation(sp: SPFI): Promise<INavConfig> {
  const webInfo = await sp.web
    .select('ServerRelativeUrl')<{ ServerRelativeUrl?: string }>();

  const categoryTermSetId = await resolveCategoryTermSetId(sp);

  const hiddenItems = await sp.web.lists
    .getByTitle('TaxonomyHiddenList')
    .items
    .select('Title', 'IdForTerm', 'IdForTermSet', 'Path')<ITaxonomyHiddenItem[]>();

  const categoryItems = hiddenItems.filter(item => {
    return !!item.Title && !!item.IdForTermSet && item.IdForTermSet.toLowerCase() === categoryTermSetId;
  });

  const rootNode: INavNode = {
    id: ROOT_NODE_ID,
    label: ROOT_NODE_LABEL,
    filters: [
      { field: 'ContentType', op: 'eq', value: PO_CONTENT_TYPE }
    ],
    children: []
  };

  categoryItems
    .sort((left, right) => (left.Path || left.Title || '').localeCompare(right.Path || right.Title || ''))
    .forEach(item => {
      const title = item.Title || '';
      const termId = item.IdForTerm || sanitizeNodeId(title);
      const pathParts = normalizePath(item.Path, title);
      if (pathParts.length > 0) {
        ensureChildNode(rootNode, pathParts, termId);
      }
    });

  // In some tenants, TaxonomyHiddenList only materializes terms after usage.
  // Force fallback to nav.json when no taxonomy terms are available yet.
  if (!rootNode.children || rootNode.children.length === 0) {
    throw new Error(`No terms found in TaxonomyHiddenList for term set '${CATEGORY_TERM_SET_NAME}'`);
  }

  return {
    schemaVersion: `taxonomy:${CATEGORY_TERM_SET_NAME}`,
    site: { serverRelativeUrl: webInfo.ServerRelativeUrl || '/' },
    results: { page: '/SitePages/resultados.aspx', nodeIdQueryParam: 'nodeId' },
    nodes: [rootNode]
  } as INavConfig;
}

export async function loadNavConfig(sp: SPFI, navJsonUrl: string): Promise<INavConfig> {
  try {
    return await loadTaxonomyNavigation(sp);
  } catch (taxonomyError) {
    const webInfo = await sp.web.select('ServerRelativeUrl')<{ ServerRelativeUrl?: string }>();
    const resolvedNavPath = resolveNavConfigPath(navJsonUrl, webInfo.ServerRelativeUrl || '/');
    const text = await sp.web.getFileByServerRelativePath(resolvedNavPath).getText();
    return JSON.parse(text) as INavConfig;
  }
}
