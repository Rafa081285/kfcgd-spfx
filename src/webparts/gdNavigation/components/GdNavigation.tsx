import * as React from 'react';
import {
  Nav,
  INavLink,
  INavLinkGroup,
  Spinner,
  SpinnerSize,
  MessageBar,
  MessageBarType,
  DetailsList,
  DetailsListLayoutMode,
  IColumn,
  SelectionMode,
  Panel,
  PanelType,
  IconButton
} from '@fluentui/react';
import { INavConfig, INavNode } from '../../../common/INavNode';
import { loadNavConfig } from '../../../common/navConfig';
import { findNodeById } from '../../../common/nodeUtils';
import { buildViewXml } from '../../../common/camlBuilder';
import { IGdNavigationProps } from './IGdNavigationProps';

export interface IGdNavigationState {
  navConfig: INavConfig | null;
  loading: boolean;
  error: string | null;
  selectedNodeId: string | null;
  selectedNodeLabel: string | null;
  items: object[];
  loadingItems: boolean;
  itemsError: string | null;
  isRelatedPanelOpen: boolean;
  relatedPanelTitle: string;
  relatedItems: object[];
  loadingRelatedItems: boolean;
  relatedItemsError: string | null;
  isDocumentModalOpen: boolean;
  documentModalTitle: string;
  documentModalUrl: string;
  documentModalSource: 'main' | 'related' | null;
  ignoreNextActiveItemChange: boolean;
  isInfoPanelOpen: boolean;
  activeFilter: 'all' | 'expired' | 'dueThisMonth';
  searchTerm: string;
  currentPage: number;
}

interface IListItemRow {
  [key: string]: string;
}

interface ICountByLabel {
  label: string;
  count: number;
}

interface IStatusBuckets {
  expired: object[];
  dueThisMonth: object[];
}

const BRAND = {
  primary: '#c8102e',
  primaryDark: '#9f0d24',
  textPrimary: '#1f2937',
  textMuted: '#6b7280',
  border: '#d1d5db',
  panelBg: '#f3f4f6',
  canvasBg: '#eef1f4'
};

function getDateFromRow(row: IListItemRow): Date | null {
  const raw = row.GD_FechaCaducidad || row.GD_VigenciaHasta;
  if (!raw) {
    return null;
  }

  const parsed = new Date(raw);
  if (isNaN(parsed.getTime())) {
    return null;
  }

  return parsed;
}

function buildStatusBuckets(items: object[]): IStatusBuckets {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();
  const buckets: IStatusBuckets = {
    expired: [],
    dueThisMonth: []
  };

  items.forEach(item => {
    const row = item as IListItemRow;
    const date = getDateFromRow(row);
    if (!date) {
      return;
    }

    const itemDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    if (itemDay < today) {
      buckets.expired.push(item);
      return;
    }

    if (itemDay.getMonth() === currentMonth && itemDay.getFullYear() === currentYear) {
      buckets.dueThisMonth.push(item);
    }
  });

  return buckets;
}

function getEffectivePageSize(pageSizeValue: string): number {
  const parsed = parseInt(pageSizeValue, 10);
  if (isNaN(parsed) || parsed <= 0) {
    return 10;
  }

  return parsed;
}

function buildCountByField(items: object[], fieldName: string): ICountByLabel[] {
  const counts: { [key: string]: number } = {};

  for (const item of items) {
    const row = item as IListItemRow;
    const raw = row[fieldName];
    const label = raw && raw.trim().length > 0 ? raw.trim() : 'Sin dato';
    counts[label] = (counts[label] || 0) + 1;
  }

  return Object.keys(counts)
    .map(label => ({ label, count: counts[label] }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 8);
}

function countUpdatedThisMonth(items: object[]): number {
  const now = new Date();
  const month = now.getMonth();
  const year = now.getFullYear();
  let total = 0;

  for (const item of items) {
    const row = item as IListItemRow;
    const raw = row.GD_FechaActualizacion || row.Modified;
    if (!raw) {
      continue;
    }

    const parsed = new Date(raw);
    if (isNaN(parsed.getTime())) {
      continue;
    }

    if (parsed.getMonth() === month && parsed.getFullYear() === year) {
      total += 1;
    }
  }

  return total;
}

function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .replace(/[áàäâ]/g, 'a')
    .replace(/[éèëê]/g, 'e')
    .replace(/[íìïî]/g, 'i')
    .replace(/[óòöô]/g, 'o')
    .replace(/[úùüû]/g, 'u')
    .replace(/ñ/g, 'n');
}

function filterItemsByName(items: object[], searchTerm: string): object[] {
  const normalizedTerm = normalizeText(searchTerm.trim());
  if (!normalizedTerm) {
    return items;
  }

  return items.filter(item => {
    const row = item as IListItemRow;
    const documentName = row.FileLeafRef || '';
    return normalizeText(documentName).indexOf(normalizedTerm) !== -1;
  });
}

function collectNodes(nodes: INavNode[]): INavNode[] {
  const result: INavNode[] = [];

  for (const node of nodes) {
    result.push(node);
    if (node.children && node.children.length > 0) {
      result.push(...collectNodes(node.children));
    }
  }

  return result;
}

function buildNavLinks(nodes: INavNode[]): INavLink[] {
  return nodes.map(node => {
    const link: INavLink = {
      key: node.id,
      name: node.label,
      url: '#',
      isExpanded: true,
      links: node.children ? buildNavLinks(node.children) : []
    };
    return link;
  });
}

export default class GdNavigation extends React.Component<IGdNavigationProps, IGdNavigationState> {
  private _suppressNextActiveItemChange = false;

  constructor(props: IGdNavigationProps) {
    super(props);
    this.state = {
      navConfig: null,
      loading: true,
      error: null,
      selectedNodeId: null,
      selectedNodeLabel: null,
      items: [],
      loadingItems: false,
      itemsError: null,
      isRelatedPanelOpen: false,
      relatedPanelTitle: '',
      relatedItems: [],
      loadingRelatedItems: false,
      relatedItemsError: null,
      isDocumentModalOpen: false,
      documentModalTitle: '',
      documentModalUrl: '',
      documentModalSource: null,
      ignoreNextActiveItemChange: false,
      isInfoPanelOpen: false,
      activeFilter: 'all',
      searchTerm: '',
      currentPage: 1
    };
  }

  public componentDidMount(): void {
    this._loadNav().catch(err => {
      this.setState({ loading: false, error: err.message || 'Error loading navigation' });
    });
  }

  public componentDidUpdate(prevProps: IGdNavigationProps): void {
    if (
      prevProps.navJsonUrl !== this.props.navJsonUrl ||
      prevProps.libraryTitle !== this.props.libraryTitle ||
      prevProps.pageSize !== this.props.pageSize
    ) {
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
    const firstNode = collectNodes(config.nodes)[0];

    this.setState({
      navConfig: config,
      loading: false,
      error: null,
      selectedNodeId: firstNode ? firstNode.id : null,
      selectedNodeLabel: firstNode ? firstNode.label : null,
      items: [],
      loadingItems: false,
      itemsError: null,
      isRelatedPanelOpen: false,
      relatedPanelTitle: '',
      relatedItems: [],
      loadingRelatedItems: false,
      relatedItemsError: null,
      isDocumentModalOpen: false,
      documentModalTitle: '',
      documentModalUrl: '',
      documentModalSource: null,
      ignoreNextActiveItemChange: false,
      isInfoPanelOpen: false,
      activeFilter: 'all',
      searchTerm: '',
      currentPage: 1
    });

    if (firstNode) {
      await this._loadNodeItems(firstNode.id, firstNode.label, config);
    }
  }

  private async _loadNodeItems(nodeId: string, nodeLabel: string, config?: INavConfig): Promise<void> {
    const navConfig = config || this.state.navConfig;

    if (!navConfig) {
      this.setState({ items: [], itemsError: 'Navigation configuration is not loaded.' });
      return;
    }

    const node = findNodeById(navConfig.nodes, nodeId);
    if (!node) {
      this.setState({ items: [], loadingItems: false, itemsError: `Node not found: ${nodeId}` });
      return;
    }

    this.setState({
      selectedNodeId: nodeId,
      selectedNodeLabel: nodeLabel,
      loadingItems: true,
      itemsError: null,
      searchTerm: '',
      currentPage: 1
    });

    try {
      const viewXml = buildViewXml(node);
      const result = await this.props.sp.web.lists
        .getByTitle(this.props.libraryTitle)
        .renderListDataAsStream({ ViewXml: viewXml });
      const rows: object[] = (result && result.Row) ? result.Row : [];
      this.setState({ items: rows, loadingItems: false, itemsError: null });
    } catch (e) {
      const message = e && (e as { message?: string }).message
        ? (e as { message: string }).message
        : 'Error loading documents for selected node';
      this.setState({ items: [], loadingItems: false, itemsError: message });
    }
  }

  private _getColumns(): IColumn[] {
    return [
      {
        key: 'GD_Codigo',
        name: 'Codigo',
        fieldName: 'GD_Codigo',
        minWidth: 90,
        maxWidth: 130,
        isResizable: true
      },
      {
        key: 'FileLeafRef',
        name: 'Documento',
        fieldName: 'FileLeafRef',
        minWidth: 220,
        maxWidth: 420,
        isResizable: true,
        onRender: (item: IListItemRow) => {
          const url = this._resolveDocumentUrl(item.FileRef || '');
          return (
            <button
              type="button"
              onMouseDown={() => {
                this._preventNextActiveItemChange();
              }}
              onKeyDown={() => {
                this._preventNextActiveItemChange();
              }}
              onClick={(ev: React.MouseEvent<HTMLButtonElement>) => {
                ev.preventDefault();
                ev.stopPropagation();
                this._openDocumentModal(item.FileLeafRef || 'Documento', url, 'main');
              }}
              style={{
                border: 0,
                background: 'none',
                padding: 0,
                margin: 0,
                color: '#9f0d24',
                fontWeight: 600,
                textDecoration: 'underline',
                cursor: 'pointer',
                font: 'inherit',
                textAlign: 'left'
              }}
            >
              {item.FileLeafRef}
            </button>
          );
        }
      },
      {
        key: 'ContentType',
        name: 'Tipo',
        fieldName: 'ContentType',
        minWidth: 120,
        maxWidth: 180,
        isResizable: true
      },
      {
        key: 'Modified',
        name: 'Modificado',
        fieldName: 'Modified',
        minWidth: 120,
        maxWidth: 180,
        isResizable: true
      }
    ];
  }

  private _getRelatedColumns(): IColumn[] {
    return [
      {
        key: 'GD_Codigo',
        name: 'Codigo',
        fieldName: 'GD_Codigo',
        minWidth: 90,
        maxWidth: 130,
        isResizable: true
      },
      {
        key: 'FileLeafRef',
        name: 'Documento relacionado',
        fieldName: 'FileLeafRef',
        minWidth: 220,
        maxWidth: 420,
        isResizable: true,
        onRender: (item: IListItemRow) => {
          const url = this._resolveDocumentUrl(item.FileRef || '');
          return (
            <button
              type="button"
              onMouseDown={() => {
                this._preventNextActiveItemChange();
              }}
              onKeyDown={() => {
                this._preventNextActiveItemChange();
              }}
              onClick={(ev: React.MouseEvent<HTMLButtonElement>) => {
                ev.preventDefault();
                ev.stopPropagation();
                this._openDocumentModal(item.FileLeafRef || 'Documento relacionado', url, 'related');
              }}
              style={{
                border: 0,
                background: 'none',
                padding: 0,
                margin: 0,
                color: '#9f0d24',
                fontWeight: 600,
                textDecoration: 'underline',
                cursor: 'pointer',
                font: 'inherit',
                textAlign: 'left'
              }}
            >
              {item.FileLeafRef}
            </button>
          );
        }
      },
      {
        key: 'GD_Estatus',
        name: 'Estatus',
        fieldName: 'GD_Estatus',
        minWidth: 100,
        maxWidth: 150,
        isResizable: true
      },
      {
        key: 'Modified',
        name: 'Modificado',
        fieldName: 'Modified',
        minWidth: 120,
        maxWidth: 180,
        isResizable: true
      }
    ];
  }

  private _resolveDocumentUrl(fileRef: string): string {
    if (!fileRef) {
      return '';
    }

    if (fileRef.indexOf('http://') === 0 || fileRef.indexOf('https://') === 0) {
      return fileRef;
    }

    return `${window.location.origin}${fileRef}`;
  }

  private _openDocumentModal(title: string, url: string, source: 'main' | 'related'): void {
    if (!url) {
      return;
    }

    this.setState({
      isDocumentModalOpen: true,
      documentModalTitle: title,
      documentModalUrl: url,
      documentModalSource: source,
      ignoreNextActiveItemChange: true
    });
  }

  private _preventNextActiveItemChange(): void {
    // Synchronous flag to avoid row activation side effects on first click.
    this._suppressNextActiveItemChange = true;
  }

  private async _openRelatedItemsPanel(item: object): Promise<void> {
    const row = item as IListItemRow;
    const idRaw = row.ID;
    const parentId = idRaw ? parseInt(idRaw, 10) : NaN;
    const documentName = row.FileLeafRef || 'Documento';

    this.setState({
      isRelatedPanelOpen: true,
      relatedPanelTitle: `Documentos relacionados - ${documentName}`,
      relatedItems: [],
      loadingRelatedItems: true,
      relatedItemsError: null
    });

    if (!parentId || isNaN(parentId)) {
      this.setState({
        loadingRelatedItems: false,
        relatedItemsError: 'No se pudo identificar el ID del documento seleccionado.'
      });
      return;
    }

    const viewXml = `<View><Query><Where><Eq><FieldRef Name="GD_DocumentoGeneral" LookupId="TRUE" /><Value Type="Lookup">${parentId}</Value></Eq></Where></Query><ViewFields><FieldRef Name="GD_Codigo" /><FieldRef Name="FileLeafRef" /><FieldRef Name="FileRef" /><FieldRef Name="GD_Estatus" /><FieldRef Name="Modified" /></ViewFields><RowLimit>200</RowLimit></View>`;

    try {
      const result = await this.props.sp.web.lists
        .getByTitle(this.props.relatedLibraryTitle)
        .renderListDataAsStream({ ViewXml: viewXml });
      const rows: object[] = result && result.Row ? result.Row : [];
      this.setState({
        relatedItems: rows,
        loadingRelatedItems: false,
        relatedItemsError: null
      });
    } catch (e) {
      const message = e && (e as { message?: string }).message
        ? (e as { message: string }).message
        : 'Error cargando documentos relacionados';
      this.setState({
        relatedItems: [],
        loadingRelatedItems: false,
        relatedItemsError: message
      });
    }
  }

  public render(): React.ReactElement<IGdNavigationProps> {
    const {
      loading,
      error,
      navConfig,
      selectedNodeId,
      selectedNodeLabel,
      items,
      loadingItems,
      itemsError,
      isRelatedPanelOpen,
      relatedPanelTitle,
      relatedItems,
      loadingRelatedItems,
      relatedItemsError,
      isDocumentModalOpen,
      documentModalTitle,
      documentModalUrl,
      documentModalSource,
      ignoreNextActiveItemChange,
      isInfoPanelOpen,
      activeFilter,
      searchTerm,
      currentPage
    } = this.state;
    const statusBuckets = buildStatusBuckets(items);
    const expiredItems = statusBuckets.expired;
    const dueThisMonthItems = statusBuckets.dueThisMonth;
    const filteredItems = activeFilter === 'all'
      ? items
      : activeFilter === 'expired'
        ? expiredItems
        : dueThisMonthItems;
    const searchFilteredItems = filterItemsByName(filteredItems, searchTerm);
    const pageSize = getEffectivePageSize(this.props.pageSize);
    const totalPages = Math.max(1, Math.ceil(searchFilteredItems.length / pageSize));
    const safePage = Math.min(currentPage, totalPages);
    const pageStart = (safePage - 1) * pageSize;
    const pagedItems = searchFilteredItems.slice(pageStart, pageStart + pageSize);
    const docsByType = buildCountByField(items, 'ContentType');
    const reasonsByUpdate = buildCountByField(items, 'GD_MotivoActualizacion');
    const updatedThisMonth = countUpdatedThisMonth(items);

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

    const links = buildNavLinks(navConfig.nodes);
    const groups: INavLinkGroup[] = [{ links }];

    const wrapperStyle: React.CSSProperties = {
      border: `1px solid ${BRAND.border}`,
      borderRadius: 10,
      backgroundColor: '#ffffff',
      boxShadow: '0 10px 28px rgba(15, 23, 42, 0.12)',
      overflow: 'hidden'
    };

    const bodyStyle: React.CSSProperties = {
      display: 'flex',
      flexWrap: 'wrap',
      minHeight: 520,
      backgroundColor: BRAND.canvasBg
    };

    const leftPanelStyle: React.CSSProperties = {
      flex: '0 0 280px',
      minWidth: 260,
      maxWidth: 300,
      borderRight: `1px solid ${BRAND.border}`,
      backgroundColor: BRAND.panelBg
    };

    const rightPanelStyle: React.CSSProperties = {
      flex: '1 1 520px',
      minWidth: 420,
      backgroundColor: '#ffffff'
    };

    const panelHeaderStyle: React.CSSProperties = {
      background: `linear-gradient(90deg, ${BRAND.primaryDark} 0%, ${BRAND.primary} 100%)`,
      color: '#ffffff',
      fontSize: 13,
      fontWeight: 700,
      padding: '0 14px',
      borderBottom: `1px solid ${BRAND.border}`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      height: 46,
      boxSizing: 'border-box'
    };

    const panelBodyStyle: React.CSSProperties = {
      padding: 14
    };

    const cardStyle: React.CSSProperties = {
      backgroundColor: '#ffffff',
      borderRadius: 10,
      border: `1px solid ${BRAND.border}`,
      padding: 16,
      marginBottom: 14
    };

    const footerStyle: React.CSSProperties = {
      borderTop: `1px solid ${BRAND.border}`,
      textAlign: 'center',
      fontSize: 12,
      color: BRAND.textMuted,
      padding: '10px 12px',
      backgroundColor: '#ffffff'
    };

    const filterBarStyle: React.CSSProperties = {
      display: 'flex',
      gap: 8,
      flexWrap: 'wrap',
      marginBottom: 12
    };

    const filterButtonStyle = (value: 'all' | 'expired' | 'dueThisMonth'): React.CSSProperties => ({
      border: activeFilter === value ? `1px solid ${BRAND.primary}` : `1px solid ${BRAND.border}`,
      borderRadius: 16,
      backgroundColor: activeFilter === value ? BRAND.primary : '#ffffff',
      color: activeFilter === value ? '#ffffff' : '#323130',
      fontWeight: 600,
      padding: '6px 12px',
      cursor: 'pointer'
    });

    const pagerContainerStyle: React.CSSProperties = {
      marginTop: 10,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 8,
      flexWrap: 'wrap'
    };

    const pagerButtonStyle: React.CSSProperties = {
      border: `1px solid ${BRAND.border}`,
      borderRadius: 4,
      backgroundColor: '#ffffff',
      padding: '4px 10px',
      cursor: 'pointer',
      color: BRAND.textPrimary,
      fontWeight: 600
    };

    const dashboardGridStyle: React.CSSProperties = {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
      gap: 10,
      marginBottom: 12
    };

    const metricCardStyle: React.CSSProperties = {
      border: `1px solid ${BRAND.border}`,
      borderRadius: 8,
      backgroundColor: '#ffffff',
      padding: 10
    };

    const metricLabelStyle: React.CSSProperties = {
      fontSize: 11,
      fontWeight: 700,
      color: BRAND.textMuted,
      textTransform: 'uppercase',
      letterSpacing: 0.2
    };

    const metricValueStyle: React.CSSProperties = {
      fontSize: 24,
      lineHeight: 1.15,
      fontWeight: 800,
      color: BRAND.textPrimary,
      marginTop: 6
    };

    const chartRowStyle: React.CSSProperties = {
      display: 'grid',
      gridTemplateColumns: 'minmax(120px, 220px) 1fr auto',
      alignItems: 'center',
      gap: 8,
      marginBottom: 6
    };

    const mockupBadgeStyle: React.CSSProperties = {
      display: 'inline-block',
      padding: '2px 8px',
      borderRadius: 999,
      fontSize: 11,
      fontWeight: 700,
      color: '#7f1d1d',
      backgroundColor: '#fee2e2',
      border: '1px solid #fecaca',
      marginLeft: 8
    };

    return (
      <section style={wrapperStyle}>
        <div style={bodyStyle}>
          <div style={leftPanelStyle}>
            <div style={panelHeaderStyle}>
              <span>Navegacion - arbol completo</span>
            </div>
            <div style={panelBodyStyle}>
              <Nav
                groups={groups}
                selectedKey={selectedNodeId || undefined}
                onLinkClick={(ev?: React.MouseEvent<HTMLElement>, item?: INavLink) => {
                  if (item && item.key) {
                    ev && ev.preventDefault();
                    this._loadNodeItems(item.key, item.name).catch(loadError => {
                      this.setState({
                        loadingItems: false,
                        itemsError: loadError.message || 'Error loading node documents'
                      });
                    });
                  }
                }}
                styles={{
                  root: { width: '100%' },
                  compositeLink: { marginBottom: 2, borderRadius: 6 },
                  link: { borderRadius: 6 },
                  linkText: { fontSize: 13, color: BRAND.textPrimary, fontWeight: 600 },
                  chevronButton: { color: BRAND.primary }
                }}
              />
            </div>
          </div>

          <div style={rightPanelStyle}>
            <div style={panelHeaderStyle}>
              <span>Documentos por nodo</span>
              <IconButton
                iconProps={{ iconName: 'Info' }}
                title="Informacion"
                ariaLabel="Informacion"
                styles={{
                  root: {
                    color: '#ffffff',
                    width: 24,
                    height: 24,
                    padding: 0,
                    minWidth: 24
                  },
                  rootHovered: { color: '#ffffff' }
                }}
                onClick={() => {
                  this.setState({ isInfoPanelOpen: true });
                }}
              />
            </div>
            <div style={panelBodyStyle}>
              <div style={cardStyle}>
                <div style={{ fontWeight: 700, marginBottom: 8 }}>
                  Nodo actual: {selectedNodeLabel || 'Sin seleccion'}
                </div>
                <div style={{ color: BRAND.textMuted, fontSize: 12, marginBottom: 12 }}>
                  Biblioteca: {this.props.libraryTitle}
                </div>

                <div style={filterBarStyle}>
                  <button style={filterButtonStyle('all')} onClick={() => { this.setState({ activeFilter: 'all', currentPage: 1 }); }}>
                    Todos los documentos
                  </button>
                  <button style={filterButtonStyle('expired')} onClick={() => { this.setState({ activeFilter: 'expired', currentPage: 1 }); }}>
                    Vencidos
                  </button>
                  <button style={filterButtonStyle('dueThisMonth')} onClick={() => { this.setState({ activeFilter: 'dueThisMonth', currentPage: 1 }); }}>
                    Por vencer este mes
                  </button>
                </div>

                <div style={{ marginBottom: 12 }}>
                  <input
                    type="search"
                    value={searchTerm}
                    onChange={(ev: React.ChangeEvent<HTMLInputElement>) => {
                      this.setState({ searchTerm: ev.target.value, currentPage: 1 });
                    }}
                    placeholder="Buscar por nombre del procedimiento o documento"
                    aria-label="Buscar documentos por nombre"
                    style={{
                      width: '100%',
                      border: `1px solid ${BRAND.border}`,
                      borderRadius: 8,
                      padding: '8px 10px',
                      fontSize: 13,
                      boxSizing: 'border-box'
                    }}
                  />
                </div>

                {loadingItems && <Spinner size={SpinnerSize.medium} label="Loading documents..." />}

                {!loadingItems && itemsError && (
                  <MessageBar messageBarType={MessageBarType.error}>{itemsError}</MessageBar>
                )}

                {!loadingItems && !itemsError && searchFilteredItems.length === 0 && (
                  <MessageBar>
                    {searchTerm.trim().length > 0
                      ? 'No se encontraron documentos que coincidan con la busqueda.'
                      : 'No documents found for this node.'}
                  </MessageBar>
                )}

                {!loadingItems && !itemsError && searchFilteredItems.length > 0 && (
                  <div>
                    <DetailsList
                      items={pagedItems}
                      columns={this._getColumns()}
                      layoutMode={DetailsListLayoutMode.fixedColumns}
                      selectionMode={SelectionMode.single}
                      isHeaderVisible={true}
                      compact={true}
                      styles={{
                        root: {
                          border: `1px solid ${BRAND.border}`,
                          borderRadius: 8
                        },
                        headerWrapper: {
                          backgroundColor: '#f8fafc',
                          borderBottom: `1px solid ${BRAND.border}`
                        }
                      }}
                      onActiveItemChanged={(activeItem?: object) => {
                        if (this._suppressNextActiveItemChange || ignoreNextActiveItemChange) {
                          this._suppressNextActiveItemChange = false;
                          this.setState({ ignoreNextActiveItemChange: false });
                          return;
                        }

                        if (activeItem) {
                          this._openRelatedItemsPanel(activeItem).catch(panelError => {
                            this.setState({
                              loadingRelatedItems: false,
                              relatedItemsError: panelError.message || 'Error cargando relacionados'
                            });
                          });
                        }
                      }}
                    />

                    <div style={pagerContainerStyle}>
                      <div style={{ color: BRAND.textMuted, fontSize: 12 }}>
                        Pagina {safePage} de {totalPages} - {searchFilteredItems.length} documento(s)
                      </div>
                      <div>
                        <button
                          type="button"
                          style={pagerButtonStyle}
                          disabled={safePage <= 1}
                          onClick={() => {
                            this.setState({ currentPage: Math.max(1, safePage - 1) });
                          }}
                        >
                          Anterior
                        </button>
                        <button
                          type="button"
                          style={{ ...pagerButtonStyle, marginLeft: 8 }}
                          disabled={safePage >= totalPages}
                          onClick={() => {
                            this.setState({ currentPage: Math.min(totalPages, safePage + 1) });
                          }}
                        >
                          Siguiente
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div style={cardStyle}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                  <div style={{ fontWeight: 800, color: BRAND.textPrimary }}>Tablero del nodo (datos reales)</div>
                  <div style={{ fontSize: 12, color: BRAND.textMuted }}>Fuente: metadatos de documentos del nodo</div>
                </div>

                <div style={dashboardGridStyle}>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Documentos en nodo</div>
                    <div style={metricValueStyle}>{items.length}</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Vencidos</div>
                    <div style={metricValueStyle}>{expiredItems.length}</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Por vencer este mes</div>
                    <div style={metricValueStyle}>{dueThisMonthItems.length}</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Actualizados este mes</div>
                    <div style={metricValueStyle}>{updatedThisMonth}</div>
                  </div>
                </div>

                <div style={{ marginBottom: 14 }}>
                  <div style={{ fontWeight: 700, color: BRAND.textPrimary, marginBottom: 8 }}>
                    Distribucion por tipo de documento
                  </div>
                  {docsByType.length === 0 && (
                    <div style={{ color: BRAND.textMuted, fontSize: 12 }}>No hay datos para graficar.</div>
                  )}
                  {docsByType.map(type => {
                    const percentage = items.length > 0 ? Math.round((type.count / items.length) * 100) : 0;
                    return (
                      <div key={`type-${type.label}`} style={chartRowStyle}>
                        <div style={{ fontSize: 12, color: BRAND.textPrimary }}>{type.label}</div>
                        <div style={{ height: 10, backgroundColor: '#e5e7eb', borderRadius: 999, overflow: 'hidden' }}>
                          <div style={{ height: '100%', width: `${percentage}%`, backgroundColor: BRAND.primary }} />
                        </div>
                        <div style={{ fontSize: 12, fontWeight: 700, color: BRAND.textPrimary }}>{type.count}</div>
                      </div>
                    );
                  })}
                </div>

                <div>
                  <div style={{ fontWeight: 700, color: BRAND.textPrimary, marginBottom: 8 }}>
                    Cambios por motivo (dato real disponible)
                  </div>
                  {reasonsByUpdate.length === 0 && (
                    <div style={{ color: BRAND.textMuted, fontSize: 12 }}>
                      Aun no hay motivos de actualizacion cargados para este nodo.
                    </div>
                  )}
                  {reasonsByUpdate.map(reason => (
                    <div key={`reason-${reason.label}`} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6, fontSize: 12 }}>
                      <span style={{ color: BRAND.textPrimary }}>{reason.label}</span>
                      <span style={{ fontWeight: 700, color: BRAND.textPrimary }}>{reason.count}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div style={cardStyle}>
                <div style={{ display: 'flex', alignItems: 'center', marginBottom: 10 }}>
                  <div style={{ fontWeight: 800, color: BRAND.textPrimary }}>Tablero ejecutivo (mockup prototipo)</div>
                  <span style={mockupBadgeStyle}>PROTOTIPO</span>
                </div>

                <div style={dashboardGridStyle}>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Personas que accedieron</div>
                    <div style={metricValueStyle}>128</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Impresiones</div>
                    <div style={metricValueStyle}>43</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Lecturas</div>
                    <div style={metricValueStyle}>392</div>
                  </div>
                  <div style={metricCardStyle}>
                    <div style={metricLabelStyle}>Copia controlada</div>
                    <div style={metricValueStyle}>17</div>
                  </div>
                </div>

                <div style={{ marginBottom: 12 }}>
                  <div style={{ fontWeight: 700, color: BRAND.textPrimary, marginBottom: 8 }}>
                    Cambios fuera de planificacion (mockup)
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                    <div style={{ ...metricCardStyle, padding: 8 }}>
                      <div style={{ fontSize: 12, color: BRAND.textMuted }}>Total cambios fuera de plan</div>
                      <div style={{ fontSize: 20, fontWeight: 800, color: BRAND.textPrimary }}>9</div>
                    </div>
                    <div style={{ ...metricCardStyle, padding: 8 }}>
                      <div style={{ fontSize: 12, color: BRAND.textMuted }}>Motivo principal</div>
                      <div style={{ fontSize: 14, fontWeight: 700, color: BRAND.textPrimary }}>Auditoria externa</div>
                    </div>
                  </div>
                </div>

                <div>
                  <div style={{ fontWeight: 700, color: BRAND.textPrimary, marginBottom: 8 }}>
                    Visualizaciones por tipo (mockup)
                  </div>
                  {[
                    { label: 'PO', value: 48 },
                    { label: 'IT', value: 30 },
                    { label: 'Instructivo', value: 22 },
                    { label: 'Politica', value: 14 }
                  ].map(mock => (
                    <div key={`mock-${mock.label}`} style={chartRowStyle}>
                      <div style={{ fontSize: 12, color: BRAND.textPrimary }}>{mock.label}</div>
                      <div style={{ height: 10, backgroundColor: '#e5e7eb', borderRadius: 999, overflow: 'hidden' }}>
                        <div style={{ height: '100%', width: `${mock.value}%`, backgroundColor: '#2563eb' }} />
                      </div>
                      <div style={{ fontSize: 12, fontWeight: 700, color: BRAND.textPrimary }}>{mock.value}%</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div style={footerStyle}>
          Soporte | Contacto | Version nav.json: {navConfig.schemaVersion}
        </div>

        <Panel
          isOpen={isRelatedPanelOpen}
          onDismiss={() => {
            this.setState({
              isRelatedPanelOpen: false,
              ignoreNextActiveItemChange: true
            });
          }}
          closeButtonAriaLabel="Cerrar"
          type={PanelType.large}
          headerText={relatedPanelTitle}
          styles={{
            main: {
              borderLeft: `4px solid ${BRAND.primary}`
            }
          }}
        >
          {loadingRelatedItems && <Spinner size={SpinnerSize.medium} label="Cargando relacionados..." />}

          {!loadingRelatedItems && relatedItemsError && (
            <MessageBar messageBarType={MessageBarType.error}>{relatedItemsError}</MessageBar>
          )}

          {!loadingRelatedItems && !relatedItemsError && relatedItems.length === 0 && (
            <MessageBar>No hay documentos relacionados para este documento.</MessageBar>
          )}

          {!loadingRelatedItems && !relatedItemsError && relatedItems.length > 0 && (
            <DetailsList
              items={relatedItems}
              columns={this._getRelatedColumns()}
              layoutMode={DetailsListLayoutMode.fixedColumns}
              selectionMode={SelectionMode.none}
              isHeaderVisible={true}
              compact={true}
              styles={{
                root: {
                  border: `1px solid ${BRAND.border}`,
                  borderRadius: 8
                },
                headerWrapper: {
                  backgroundColor: '#f8fafc',
                  borderBottom: `1px solid ${BRAND.border}`
                }
              }}
            />
          )}
        </Panel>

        <Panel
          isOpen={isDocumentModalOpen}
          onDismiss={() => {
            const shouldKeepRelatedPanel = documentModalSource === 'related';
            this.setState({
              isDocumentModalOpen: false,
              documentModalTitle: '',
              documentModalUrl: '',
              documentModalSource: null,
              isRelatedPanelOpen: shouldKeepRelatedPanel ? true : isRelatedPanelOpen,
              ignoreNextActiveItemChange: true
            });
          }}
          closeButtonAriaLabel="Cerrar"
          type={PanelType.large}
          headerText={documentModalTitle}
          styles={{
            main: {
              borderLeft: `4px solid ${BRAND.primary}`
            },
            contentInner: {
              padding: 0
            }
          }}
        >
          {documentModalUrl ? (
            <iframe
              src={documentModalUrl}
              title={documentModalTitle}
              style={{ width: '100%', height: '75vh', border: 0 }}
            />
          ) : (
            <MessageBar>No se pudo abrir la vista previa del documento.</MessageBar>
          )}
        </Panel>

        <Panel
          isOpen={isInfoPanelOpen}
          onDismiss={() => {
            this.setState({ isInfoPanelOpen: false });
          }}
          closeButtonAriaLabel="Cerrar"
          type={PanelType.smallFixedFar}
          headerText="Informacion"
          styles={{
            main: {
              borderLeft: `4px solid ${BRAND.primary}`
            }
          }}
        >
          <p style={{ marginTop: 0 }}>
            Esta vista muestra a la izquierda la navegacion jerarquica y a la derecha los documentos del nodo activo.
          </p>
          <ul style={{ margin: 0, paddingLeft: 20, lineHeight: 1.5 }}>
            <li>Selecciona un nodo para refrescar resultados.</li>
            <li>Filtra por estado: todos, vencidos o por vencer este mes.</li>
            <li>Busca por nombre de procedimiento o documento con coincidencia parcial.</li>
            <li>Selecciona una fila para abrir relacionados en ventana flotante.</li>
          </ul>
        </Panel>
      </section>
    );
  }
}
