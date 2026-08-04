import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { buildCatalogIwsTemplateModel } from './iws.js';

const templateName = 'catalog-iws.rpgleinc.hbs';

export const generateCatalogIwsInterface = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogIwsTemplateModel(spec),
        templatesDirectory
    );

export const generateCatalogTestIwsInterface = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        {
            ...buildCatalogIwsTemplateModel(spec),
            runtimeIncludes: {
                cmagic: 'includes/cmagic.rpgleinc',
                global: 'includes/global.rpgleinc',
                httpRest: 'includes/httpRest.rpgleinc'
            }
        },
        templatesDirectory
    );
