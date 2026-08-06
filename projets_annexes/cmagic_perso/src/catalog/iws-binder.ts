import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';
import {
    catalogIwsCreateProcedure,
    catalogIwsGetListProcedure,
    catalogIwsGetOneProcedure
} from './iws.js';

const templateName = 'catalog-iws.bnd.hbs';

type CatalogIwsBinderTemplateModel = {
    signature: string;
    exports: string[];
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogIwsBinderTemplateModel => {
    if (!spec.iwsObject) {
        throw new Error(
            `Catalog IWS binder requires iwsObject: ${spec.entity}`
        );
    }
    if (!spec.capabilities.includes('list')) {
        throw new Error(
            `Catalog IWS binder requires LIST capability: ${spec.entity}`
        );
    }

    return {
        signature: `${catalogObjectName(spec.iwsObject)}.0.0.1`,
        exports: [
            catalogIwsGetListProcedure(spec.entity),
            ...(spec.capabilities.includes('get')
                ? [catalogIwsGetOneProcedure(spec.entity)]
                : []),
            ...(spec.capabilities.includes('create')
                ? [catalogIwsCreateProcedure(spec.entity)]
                : [])
        ]
    };
};

export const generateCatalogIwsBinder = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildTemplateModel(spec),
        templatesDirectory
    );
