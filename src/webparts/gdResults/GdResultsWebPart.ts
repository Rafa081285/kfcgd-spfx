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

import * as strings from 'GdResultsWebPartStrings';
import GdResults from './components/GdResults';
import { IGdResultsProps } from './components/IGdResultsProps';

export interface IGdResultsWebPartProps {
  navJsonUrl: string;
  nodeIdParam: string;
  libraryTitle: string;
}

export default class GdResultsWebPart extends BaseClientSideWebPart<IGdResultsWebPartProps> {
  public render(): void {
    const sp = spfi().using(SPFx(this.context));

    const element: React.ReactElement<IGdResultsProps> = React.createElement(GdResults, {
      sp,
      navJsonUrl: this.properties.navJsonUrl || '/SiteAssets/nav.json',
      nodeIdParam: this.properties.nodeIdParam || 'nodeId',
      libraryTitle: this.properties.libraryTitle || 'Gestor Documental',
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
                PropertyPaneTextField('nodeIdParam', {
                  label: strings.NodeIdParamFieldLabel
                }),
                PropertyPaneTextField('libraryTitle', {
                  label: strings.LibraryTitleFieldLabel
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
