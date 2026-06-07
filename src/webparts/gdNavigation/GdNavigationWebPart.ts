import * as React from 'react';
import * as ReactDom from 'react-dom';
import { Version } from '@microsoft/sp-core-library';
import {
  IPropertyPaneConfiguration,
  PropertyPaneTextField
} from '@microsoft/sp-property-pane';
import { BaseClientSideWebPart } from '@microsoft/sp-webpart-base';
import { spfi, SPFx } from '@pnp/sp';
import '@pnp/sp/webs';
import '@pnp/sp/files';
import '@pnp/sp/lists';

import * as strings from 'GdNavigationWebPartStrings';
import GdNavigation from './components/GdNavigation';
import { IGdNavigationProps } from './components/IGdNavigationProps';

export interface IGdNavigationWebPartProps {
  navJsonUrl: string;
  resultsPageUrl: string;
  nodeIdParam: string;
  libraryTitle: string;
  relatedLibraryTitle: string;
  pageSize: string;
}

export default class GdNavigationWebPart extends BaseClientSideWebPart<IGdNavigationWebPartProps> {
  public render(): void {
    const sp = spfi().using(SPFx(this.context));

    const element: React.ReactElement<IGdNavigationProps> = React.createElement(GdNavigation, {
      sp,
      navJsonUrl: this.properties.navJsonUrl || '/SiteAssets/nav.json',
      resultsPageUrl: this.properties.resultsPageUrl || '/SitePages/resultados.aspx',
      nodeIdParam: this.properties.nodeIdParam || 'nodeId',
      libraryTitle: this.properties.libraryTitle || 'Gestor Documental',
      relatedLibraryTitle: this.properties.relatedLibraryTitle || 'Documentos Relacionados GD',
      pageSize: this.properties.pageSize || '10',
      isDarkTheme: false,
      hasTeamsContext: !!this.context.sdks.microsoftTeams
    });

    ReactDom.render(element, this.domElement);
  }

  protected onDispose(): void {
    ReactDom.unmountComponentAtNode(this.domElement);
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: { description: strings.PropertyPaneDescription },
          groups: [
            {
              groupName: strings.BasicGroupName,
              groupFields: [
                PropertyPaneTextField('navJsonUrl', {
                  label: strings.NavJsonUrlFieldLabel
                }),
                PropertyPaneTextField('resultsPageUrl', {
                  label: strings.ResultsPageUrlFieldLabel
                }),
                PropertyPaneTextField('nodeIdParam', {
                  label: strings.NodeIdParamFieldLabel
                }),
                PropertyPaneTextField('libraryTitle', {
                  label: strings.LibraryTitleFieldLabel
                }),
                PropertyPaneTextField('relatedLibraryTitle', {
                  label: strings.RelatedLibraryTitleFieldLabel
                }),
                PropertyPaneTextField('pageSize', {
                  label: strings.PageSizeFieldLabel
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
