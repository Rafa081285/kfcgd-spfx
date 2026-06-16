import * as React from 'react';
import {
  DetailsList,
  DetailsListLayoutMode,
  IColumn,
  SelectionMode,
  Link,
  Spinner,
  SpinnerSize,
  MessageBar,
  MessageBarType
} from '@fluentui/react';
import { INavConfig, INavNode } from '../../../common/INavNode';
import { loadNavConfig } from '../../../common/navConfig';
import { getQueryParam } from '../../../common/queryString';
import { findNodeById } from '../../../common/nodeUtils';
import { buildViewXml } from '../../../common/camlBuilder';
import { IGdResultsProps } from './IGdResultsProps';

export interface IGdResultsState {
  navConfig: INavConfig | null;
  items: object[];
  loading: boolean;
  error: string | null;
}

export default class GdResults extends React.Component<IGdResultsProps, IGdResultsState> {
  private readonly _officeExtensions: string[] = ['doc', 'docx', 'ppt', 'pptx', 'pps', 'ppsx', 'xls', 'xlsx', 'xlsm', 'docm', 'pptm'];

  constructor(props: IGdResultsProps) {
    super(props);
    this.state = {
      navConfig: null,
      items: [],
      loading: true,
      error: null
    };
  }

  public componentDidMount(): void {
    this._loadData().catch(err => {
      this.setState({ loading: false, error: err.message || 'Error loading results' });
    });
  }

  public componentDidUpdate(prevProps: IGdResultsProps): void {
    const changed =
      prevProps.navJsonUrl !== this.props.navJsonUrl ||
      prevProps.nodeIdParam !== this.props.nodeIdParam ||
      prevProps.libraryTitle !== this.props.libraryTitle;
    if (changed) {
      this.setState({ loading: true, error: null, items: [] });
      this._loadData().catch(err => {
        this.setState({ loading: false, error: err.message || 'Error loading results' });
      });
    }
  }

  private async _loadData(): Promise<void> {
    const { sp, navJsonUrl, nodeIdParam, libraryTitle } = this.props;

    if (!navJsonUrl) {
      this.setState({ loading: false, error: 'No nav JSON URL configured.' });
      return;
    }

    const nodeId = getQueryParam(nodeIdParam);
    if (!nodeId) {
      this.setState({ loading: false, error: `Missing query parameter: ${nodeIdParam}` });
      return;
    }

    const config = await loadNavConfig(sp, navJsonUrl);
    const node: INavNode | undefined = findNodeById(config.nodes, nodeId);

    if (!node) {
      this.setState({ loading: false, error: `Node not found: ${nodeId}` });
      return;
    }

    const viewXml = buildViewXml(node);
    const result = await sp.web.lists
      .getByTitle(libraryTitle)
      .renderListDataAsStream({ ViewXml: viewXml });

    const rows: object[] = (result && result.Row) ? result.Row : [];
    this.setState({ navConfig: config, items: rows, loading: false, error: null });
  }

  private _resolveDocumentUrl(fileRef: string): string {
    if (!fileRef) {
      return '';
    }

    const absoluteUrl = (fileRef.indexOf('http://') === 0 || fileRef.indexOf('https://') === 0)
      ? fileRef
      : `${window.location.origin}${fileRef}`;

    return this._toWebViewerUrlIfOffice(absoluteUrl);
  }

  private _toWebViewerUrlIfOffice(url: string): string {
    const pathWithoutQuery = url.split('?')[0];
    const extension = (pathWithoutQuery.split('.').pop() || '').toLowerCase();

    if (this._officeExtensions.indexOf(extension) === -1) {
      return url;
    }

    if (/[?&]web=1(?:&|$)/i.test(url)) {
      return url;
    }

    return `${url}${url.indexOf('?') >= 0 ? '&' : '?'}web=1`;
  }

  private _getColumns(): IColumn[] {
    return [
      {
        key: 'GD_Codigo',
        name: 'Código',
        fieldName: 'GD_Codigo',
        minWidth: 80,
        maxWidth: 120,
        isResizable: true
      },
      {
        key: 'FileLeafRef',
        name: 'Nombre',
        fieldName: 'FileLeafRef',
        minWidth: 200,
        maxWidth: 400,
        isResizable: true,
        onRender: (item: { FileLeafRef: string; FileRef: string }) => (
          <Link href={this._resolveDocumentUrl(item.FileRef)} target="_blank">
            {item.FileLeafRef}
          </Link>
        )
      },
      {
        key: 'ContentType',
        name: 'Tipo documento',
        fieldName: 'ContentType',
        minWidth: 120,
        maxWidth: 180,
        isResizable: true
      },
      {
        key: 'GD_PlantasAplicables',
        name: 'Planta(s) aplicables',
        fieldName: 'GD_PlantasAplicables',
        minWidth: 120,
        maxWidth: 200,
        isResizable: true
      },
      {
        key: 'GD_VigenciaHasta',
        name: 'Vigencia',
        fieldName: 'GD_VigenciaHasta',
        minWidth: 90,
        maxWidth: 120,
        isResizable: true
      },
      {
        key: 'GD_FechaCaducidad',
        name: 'Caducidad',
        fieldName: 'GD_FechaCaducidad',
        minWidth: 90,
        maxWidth: 120,
        isResizable: true
      },
      {
        key: 'GD_Estatus',
        name: 'Estatus',
        fieldName: 'GD_Estatus',
        minWidth: 80,
        maxWidth: 120,
        isResizable: true
      },
      {
        key: 'Modified',
        name: 'Modificado',
        fieldName: 'Modified',
        minWidth: 100,
        maxWidth: 150,
        isResizable: true
      }
    ];
  }

  public render(): React.ReactElement<IGdResultsProps> {
    const { loading, error, items } = this.state;

    if (loading) {
      return <Spinner size={SpinnerSize.medium} label="Loading documents..." />;
    }

    if (error) {
      return (
        <MessageBar messageBarType={MessageBarType.error}>
          {error}
        </MessageBar>
      );
    }

    if (items.length === 0) {
      return <MessageBar>No documents found.</MessageBar>;
    }

    return (
      <DetailsList
        items={items}
        columns={this._getColumns()}
        layoutMode={DetailsListLayoutMode.fixedColumns}
        selectionMode={SelectionMode.none}
        isHeaderVisible={true}
      />
    );
  }
}
