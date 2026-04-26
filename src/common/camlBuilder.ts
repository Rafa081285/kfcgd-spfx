import { INavFilter, INavNode } from './INavNode';

function escapeXml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

function buildClause(filter: INavFilter): string {
  const { field, op, value } = filter;
  if (op === 'eq') {
    return `<Eq><FieldRef Name="${field}" /><Value Type="Text">${escapeXml(value as string)}</Value></Eq>`;
  } else if (op === 'in') {
    const values = (value as string[])
      .map(v => `<Value Type="Text">${escapeXml(v)}</Value>`)
      .join('');
    return `<In><FieldRef Name="${field}" /><Values>${values}</Values></In>`;
  } else if (op === 'containsTerm') {
    const term = Array.isArray(value) ? value[0] : value;
    return `<Contains><FieldRef Name="${field}" /><Value Type="Text">${escapeXml(term)}</Value></Contains>`;
  }
  return '';
}

function andChain(clauses: string[]): string {
  if (clauses.length === 0) return '';
  if (clauses.length === 1) return clauses[0];
  let result = clauses[clauses.length - 1];
  for (let i = clauses.length - 2; i >= 0; i--) {
    result = `<And>${clauses[i]}${result}</And>`;
  }
  return result;
}

export function buildCamlWhere(node: INavNode): string {
  if (!node.filters || node.filters.length === 0) return '';
  const clauses = node.filters.map(buildClause).filter(c => c !== '');
  if (clauses.length === 0) return '';
  return `<Where>${andChain(clauses)}</Where>`;
}

export function buildViewXml(node: INavNode, rowLimit = 500): string {
  const where = buildCamlWhere(node);
  const viewFields = `<ViewFields>
    <FieldRef Name="GD_Codigo" />
    <FieldRef Name="FileLeafRef" />
    <FieldRef Name="FileRef" />
    <FieldRef Name="ContentType" />
    <FieldRef Name="GD_PlantasAplicables" />
    <FieldRef Name="GD_VigenciaHasta" />
    <FieldRef Name="GD_FechaCaducidad" />
    <FieldRef Name="GD_Estatus" />
    <FieldRef Name="Modified" />
  </ViewFields>`;
  return `<View><Query>${where}</Query>${viewFields}<RowLimit>${rowLimit}</RowLimit></View>`;
}
