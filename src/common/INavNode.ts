export interface INavFilter {
  field: string;
  op: 'eq' | 'in' | 'containsTerm';
  value: string | string[];
}

export interface INavNode {
  id: string;
  label: string;
  filters?: INavFilter[];
  children?: INavNode[];
}

export interface INavConfig {
  schemaVersion: string;
  site: { serverRelativeUrl: string };
  results: { page: string; nodeIdQueryParam: string };
  nodes: INavNode[];
}
