import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogBinderSourceName,
    catalogRpgReadSourceName
} from './artifact-names.js';
import type { CatalogSpec } from './catalog-spec.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog.Rules.mk.hbs';

type CatalogRulesTemplateModel = {
    entityName: string;
    objectName: string;
    rpgReadSource: string;
    binderSource: string;
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogRulesTemplateModel => {
    return {
        entityName: spec.entity,
        objectName: catalogObjectName(spec.entity),
        rpgReadSource: catalogRpgReadSourceName(spec.resource),
        binderSource: catalogBinderSourceName(spec.resource)
    };
};

export const generateCatalogRules = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
