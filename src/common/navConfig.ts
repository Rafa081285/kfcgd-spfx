import { SPFI } from '@pnp/sp';
import { INavConfig, INavNode } from './INavNode';

interface ITaxonomyHiddenItem {
  Title?: string;
  IdForTerm?: string;
  IdForTermSet?: string;
  Path?: string;
}

const CATEGORY_TERM_SET_NAME = 'GD - Categoria';
const CATEGORY_TERM_SET_ID = '6a7c2e6b-ad9f-4016-a819-65eac475cf56';
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

  const hiddenItems = await sp.web.lists
    .getByTitle('TaxonomyHiddenList')
    .items
    .select('Title', 'IdForTerm', 'IdForTermSet', 'Path')<ITaxonomyHiddenItem[]>();

  const categoryItems = hiddenItems.filter(item => {
    return !!item.Title && !!item.IdForTermSet && item.IdForTermSet.toLowerCase() === CATEGORY_TERM_SET_ID;
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
    const text = await sp.web.getFileByServerRelativePath(navJsonUrl).getText();
    return JSON.parse(text) as INavConfig;
  }
}
