import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-iws.bnddir.hbs';

type CatalogIwsBindingDirectoryTemplateModel = {
    objectNames: string[];
};

const requireIwsObjectName = (spec: CatalogSpec): string => {
    if (!spec.iwsObject) {
        throw new Error(
            `Catalog IWS binding directory requires iwsObject: ${spec.entity}`
        );
    }
    return catalogObjectName(spec.iwsObject);
};

const buildReadTemplateModel = (
    spec: CatalogSpec
): CatalogIwsBindingDirectoryTemplateModel => ({
    objectNames: [catalogObjectName(spec.entity)]
});

const buildIwsTemplateModel = (
    spec: CatalogSpec
): CatalogIwsBindingDirectoryTemplateModel => ({
    objectNames: [
        catalogObjectName(spec.entity),
        requireIwsObjectName(spec)
    ]
});

export const generateCatalogIwsReadBindingDirectory = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildReadTemplateModel(spec),
        templatesDirectory
    );

export const generateCatalogIwsBindingDirectory = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildIwsTemplateModel(spec),
        templatesDirectory
    );
