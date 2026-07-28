import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { buildCatalogIleasticTemplateModel } from './ileastic.js';

const templateName = 'catalog-ileastic.rpgleinc.hbs';

export const generateCatalogIleasticInterface = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogIleasticTemplateModel(spec),
        templatesDirectory
    );
