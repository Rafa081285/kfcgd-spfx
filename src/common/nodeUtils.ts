import { INavNode } from './INavNode';

export function findNodeById(nodes: INavNode[], id: string): INavNode | undefined {
  for (const node of nodes) {
    if (node.id === id) return node;
    if (node.children) {
      const found = findNodeById(node.children, id);
      if (found) return found;
    }
  }
  return undefined;
}
