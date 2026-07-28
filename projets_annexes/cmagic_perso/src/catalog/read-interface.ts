import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { buildCatalogReadTemplateModel } from './rpg-read.js';

const templateName = 'catalog-read.rpgleinc.hbs';

export const generateCatalogReadInterface = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogReadTemplateModel(spec),
        templatesDirectory
    );
