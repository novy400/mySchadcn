import { renderTemplate } from '../generation/template-renderer.js';
import { catalogRpgReadInterfaceSourceName } from './artifact-names.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-read.test.sqlrpgle.hbs';

export type CatalogReadTestTemplateModel = {
    readObjectName: string;
    readInterfaceSource: string;
};

export const buildCatalogReadTestTemplateModel = (
    spec: CatalogSpec
): CatalogReadTestTemplateModel => ({
    readObjectName: catalogObjectName(spec.entity),
    readInterfaceSource: catalogRpgReadInterfaceSourceName(spec.resource)
});

export const generateCatalogReadTest = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogReadTestTemplateModel(spec),
        templatesDirectory
    );
