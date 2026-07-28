import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogBinderSourceName,
    catalogIleasticSourceName,
    catalogRpgReadSourceName
} from './artifact-names.js';
import type { CatalogSpec } from './catalog-spec.js';
import {
    catalogObjectName,
    isSameIbmIObjectName
} from './ibmi-object-name.js';

const templateName = 'catalog.Rules.mk.hbs';

type CatalogRulesTemplateModel = {
    entityName: string;
    objectName: string;
    ileasticObjectName?: string;
    rpgReadSource: string;
    ileasticSource: string;
    binderSource: string;
};

const buildTemplateModel = (
    spec: CatalogSpec
): CatalogRulesTemplateModel => {
    const objectName = catalogObjectName(spec.entity);
    const ileasticObjectName =
        spec.ileasticObject === undefined
            ? undefined
            : catalogObjectName(spec.ileasticObject);
    if (
        ileasticObjectName !== undefined &&
        isSameIbmIObjectName(ileasticObjectName, objectName)
    ) {
        throw new Error(
            `IBM i object name collision: ${ileasticObjectName} is used by read and ILEastic modules`
        );
    }

    return {
        entityName: spec.entity,
        objectName,
        ...(ileasticObjectName === undefined ? {} : { ileasticObjectName }),
        rpgReadSource: catalogRpgReadSourceName(spec.resource),
        ileasticSource: catalogIleasticSourceName(spec.resource),
        binderSource: catalogBinderSourceName(spec.resource)
    };
};

export const generateCatalogRules = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
