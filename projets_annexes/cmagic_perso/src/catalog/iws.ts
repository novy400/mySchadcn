import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogIwsInterfaceSourceName,
    catalogRpgReadInterfaceSourceName
} from './artifact-names.js';
import type { CatalogSpec } from './catalog-spec.js';
import {
    buildCatalogReadTemplateModel,
    type CatalogReadTemplateModel
} from './rpg-read.js';
import { catalogObjectName } from './ibmi-object-name.js';

const templateName = 'catalog-iws.sqlrpgle.hbs';

type CatalogIwsFieldModel = {
    name: string;
    rpgType: string;
};

type CatalogIwsInterfacesModel = {
    read: string;
    iws: string;
};

type CatalogIwsProceduresModel =
    CatalogReadTemplateModel['procedures'] & {
        getListIws: string;
        getOneIws: string;
        copyItems: string;
    };

export type CatalogIwsTemplateModel = {
    entityName: string;
    entityDisplayName: string;
    includeGuard: string;
    readObjectName: string;
    runtimeIncludes: {
        cmagic: string;
        global: string;
        httpRest: string;
    };
    hasList: boolean;
    hasGet: boolean;
    interfaces: CatalogIwsInterfacesModel;
    procedures: CatalogIwsProceduresModel;
    itemType: string;
    itemFields: CatalogIwsFieldModel[];
    detailType: string;
    detailFields: CatalogIwsFieldModel[];
    id: CatalogIwsFieldModel;
};

export const catalogIwsGetListProcedure = (entityName: string): string =>
    `${entityName.toLowerCase()}_getlist_iws`;

export const catalogIwsGetOneProcedure = (entityName: string): string =>
    `${entityName.toLowerCase()}_getone_iws`;

export const buildCatalogIwsTemplateModel = (
    spec: CatalogSpec
): CatalogIwsTemplateModel => {
    const readModel = buildCatalogReadTemplateModel(spec);
    const prefix = readModel.entityName;

    return {
        entityName: prefix,
        entityDisplayName: readModel.entityDisplayName,
        includeGuard: `${spec.entity.toUpperCase()}_IWS_H_DEFINED`,
        readObjectName: catalogObjectName(spec.entity),
        runtimeIncludes: {
            cmagic: 'cmagic.rpgleinc',
            global: 'global.rpgleinc',
            httpRest: 'httpRest.rpgleinc'
        },
        hasList: readModel.hasList,
        hasGet: readModel.hasGet,
        interfaces: {
            read: catalogRpgReadInterfaceSourceName(spec.resource),
            iws: catalogIwsInterfaceSourceName(spec.resource)
        },
        procedures: {
            ...readModel.procedures,
            getListIws: catalogIwsGetListProcedure(spec.entity),
            getOneIws: catalogIwsGetOneProcedure(spec.entity),
            copyItems: `${prefix}_copyIwsItems`
        },
        itemType: `${prefix}_item_iws_t`,
        itemFields: readModel.itemFields.map(field => ({
            name: field.rpgName,
            rpgType: field.rpgType
        })),
        detailType: `${prefix}_detail_iws_t`,
        detailFields: readModel.detailFields.map(field => ({
            name: field.rpgName,
            rpgType: field.rpgType
        })),
        id: {
            name: readModel.id.rpgName,
            rpgType: readModel.id.rpgType
        }
    };
};

export const generateCatalogIwsWrapper = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogIwsTemplateModel(spec),
        templatesDirectory
    );
