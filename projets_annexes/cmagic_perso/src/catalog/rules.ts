import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogBinderSourceName,
    catalogIleasticSourceName,
    catalogIwsBinderSourceName,
    catalogIwsBindingDirectorySourceName,
    catalogIwsSourceName,
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
    iwsObjectName?: string;
    rpgReadSource: string;
    ileasticSource: string;
    iwsSource: string;
    iwsBinderSource: string;
    iwsBindingDirectorySource: string;
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
    const iwsObjectName =
        spec.iwsObject === undefined
            ? undefined
            : catalogObjectName(spec.iwsObject);
    if (
        ileasticObjectName !== undefined &&
        iwsObjectName !== undefined
    ) {
        throw new Error(
            `Catalog transport is ambiguous for ${spec.entity}: choose ILEastic or IWS`
        );
    }
    if (
        ileasticObjectName !== undefined &&
        isSameIbmIObjectName(ileasticObjectName, objectName)
    ) {
        throw new Error(
            `IBM i object name collision: ${ileasticObjectName} is used by read and ILEastic modules`
        );
    }
    if (
        iwsObjectName !== undefined &&
        isSameIbmIObjectName(iwsObjectName, objectName)
    ) {
        throw new Error(
            `IBM i object name collision: ${iwsObjectName} is used by read and IWS service programs`
        );
    }

    return {
        entityName: spec.entity,
        objectName,
        ...(ileasticObjectName === undefined ? {} : { ileasticObjectName }),
        ...(iwsObjectName === undefined ? {} : { iwsObjectName }),
        rpgReadSource: catalogRpgReadSourceName(spec.resource),
        ileasticSource: catalogIleasticSourceName(spec.resource),
        iwsSource: catalogIwsSourceName(spec.resource),
        iwsBinderSource: catalogIwsBinderSourceName(spec.resource),
        iwsBindingDirectorySource:
            catalogIwsBindingDirectorySourceName(spec.resource),
        binderSource: catalogBinderSourceName(spec.resource)
    };
};

export const generateCatalogRules = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
