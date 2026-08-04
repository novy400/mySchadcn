import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { buildCatalogIwsTemplateModel } from './iws.js';

const templateName = 'catalog-iws.test.sqlrpgle.hbs';

export const generateCatalogIwsTest = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogIwsTemplateModel(spec),
        templatesDirectory
    );
