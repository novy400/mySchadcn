import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-testing.json.hbs';

type CatalogTestingTemplateModel = {
    codecovModules: string[];
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogTestingTemplateModel => ({
    codecovModules: [
        catalogObjectName(spec.entity),
        ...(spec.iwsObject === undefined
            ? []
            : [catalogObjectName(spec.iwsObject)])
    ]
});

export const generateCatalogTestingConfiguration = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildTemplateModel(spec),
        templatesDirectory
    );
