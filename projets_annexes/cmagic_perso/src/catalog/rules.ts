import { renderTemplate } from '../generation/template-renderer.js';
import type { CatalogSpec } from './catalog-spec.js';

const templateName = 'catalog.Rules.mk.hbs';
const ibmIObjectNamePattern = /^[A-Z$#@][A-Z0-9_$#@]{0,9}$/;

type CatalogRulesTemplateModel = {
    entityName: string;
    objectName: string;
    rpgReadSource: string;
};

export const catalogRpgReadSourceName = (resource: string): string =>
    `${resource}.read.sqlrpgle`;

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogRulesTemplateModel => {
    const objectName = spec.entity.toUpperCase();
    if (!ibmIObjectNamePattern.test(objectName)) {
        throw new Error(
            `Invalid IBM i object name "${objectName}": ` +
                'the entity name must produce a 1-10 character system name'
        );
    }

    return {
        entityName: spec.entity,
        objectName,
        rpgReadSource: catalogRpgReadSourceName(spec.resource)
    };
};

export const generateCatalogRules = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
