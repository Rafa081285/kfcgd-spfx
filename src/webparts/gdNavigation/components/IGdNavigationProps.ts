import { SPFI } from '@pnp/sp';

export interface IGdNavigationProps {
  sp: SPFI;
  navJsonUrl: string;
  resultsPageUrl: string;
  nodeIdParam: string;
  libraryTitle: string;
  relatedLibraryTitle: string;
  pageSize: string;
  isDarkTheme: boolean;
  hasTeamsContext: boolean;
}
