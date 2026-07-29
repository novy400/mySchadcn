import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-iws.bnddir.hbs';
const iwsRuntimeObjectName = 'CIWS';

type CatalogIwsBindingDirectoryTemplateModel = {
    readObjectName: string;
    runtimeObjectName: string;
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogIwsBindingDirectoryTemplateModel => ({
    readObjectName: catalogObjectName(spec.entity),
    runtimeObjectName: iwsRuntimeObjectName
});

export const generateCatalogIwsBindingDirectory = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildTemplateModel(spec),
        templatesDirectory
    );
