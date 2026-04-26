import { SPFI } from '@pnp/sp';

export interface IGdResultsProps {
  sp: SPFI;
  navJsonUrl: string;
  nodeIdParam: string;
  libraryTitle: string;
  isDarkTheme: boolean;
  hasTeamsContext: boolean;
}
