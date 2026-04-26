import { SPFI } from '@pnp/sp';
import { INavConfig } from './INavNode';

export async function loadNavConfig(sp: SPFI, navJsonUrl: string): Promise<INavConfig> {
  const text = await sp.web.getFileByServerRelativePath(navJsonUrl).getText();
  return JSON.parse(text) as INavConfig;
}
