import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';
import { catalogReadProcedures } from './read-procedures.js';

const templateName = 'catalog.bnd.hbs';

type CatalogBinderTemplateModel = {
    signature: string;
    exports: string[];
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogBinderTemplateModel => ({
    signature: `${catalogObjectName(spec.entity)}.0.0.1`,
    exports: catalogReadProcedures(spec).exports
});

export const generateCatalogBinder = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
