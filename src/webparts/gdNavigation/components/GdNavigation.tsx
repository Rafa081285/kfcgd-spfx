import * as React from 'react';
import { Nav, INavLink, INavLinkGroup, Spinner, SpinnerSize, MessageBar, MessageBarType } from '@fluentui/react';
import { INavConfig, INavNode } from '../../../common/INavNode';
import { loadNavConfig } from '../../../common/navConfig';
import { IGdNavigationProps } from './IGdNavigationProps';

export interface IGdNavigationState {
  navConfig: INavConfig | null;
  loading: boolean;
  error: string | null;
  expandedKeys: { [key: string]: boolean };
}

function buildNavLinks(nodes: INavNode[], resultsPageUrl: string, nodeIdParam: string): INavLink[] {
  return nodes.map(node => {
    const link: INavLink = {
      key: node.id,
      name: node.label,
      url: `${resultsPageUrl}?${nodeIdParam}=${node.id}`,
      isExpanded: false,
      links: node.children ? buildNavLinks(node.children, resultsPageUrl, nodeIdParam) : []
    };
    return link;
  });
}

export default class GdNavigation extends React.Component<IGdNavigationProps, IGdNavigationState> {
  constructor(props: IGdNavigationProps) {
    super(props);
    this.state = {
      navConfig: null,
      loading: true,
      error: null,
      expandedKeys: {}
    };
  }

  public componentDidMount(): void {
    this._loadNav().catch(err => {
      this.setState({ loading: false, error: err.message || 'Error loading navigation' });
    });
  }

  public componentDidUpdate(prevProps: IGdNavigationProps): void {
    if (prevProps.navJsonUrl !== this.props.navJsonUrl) {
      this.setState({ loading: true, error: null });
      this._loadNav().catch(err => {
        this.setState({ loading: false, error: err.message || 'Error loading navigation' });
      });
    }
  }

  private async _loadNav(): Promise<void> {
    const { sp, navJsonUrl } = this.props;
    if (!navJsonUrl) {
      this.setState({ loading: false, error: 'No nav JSON URL configured.' });
      return;
    }
    const config = await loadNavConfig(sp, navJsonUrl);
    this.setState({ navConfig: config, loading: false, error: null });
  }

  public render(): React.ReactElement<IGdNavigationProps> {
    const { loading, error, navConfig } = this.state;
    const { resultsPageUrl, nodeIdParam } = this.props;

    if (loading) {
      return <Spinner size={SpinnerSize.medium} label="Loading navigation..." />;
    }

    if (error) {
      return (
        <MessageBar messageBarType={MessageBarType.error}>
          {error}
        </MessageBar>
      );
    }

    if (!navConfig || !navConfig.nodes || navConfig.nodes.length === 0) {
      return <MessageBar>No navigation nodes found.</MessageBar>;
    }

    const links = buildNavLinks(navConfig.nodes, resultsPageUrl, nodeIdParam);
    const groups: INavLinkGroup[] = [{ links }];

    return (
      <Nav
        groups={groups}
        onLinkClick={(ev?: React.MouseEvent<HTMLElement>, item?: INavLink) => {
          if (item && item.url) {
            ev && ev.preventDefault();
            window.location.href = item.url;
          }
        }}
        styles={{ root: { width: '100%' } }}
      />
    );
  }
}
