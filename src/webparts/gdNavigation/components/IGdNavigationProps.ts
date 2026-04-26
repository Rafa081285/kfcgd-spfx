import { SPFI } from '@pnp/sp';

export interface IGdNavigationProps {
  sp: SPFI;
  navJsonUrl: string;
  resultsPageUrl: string;
  nodeIdParam: string;
  isDarkTheme: boolean;
  hasTeamsContext: boolean;
}
