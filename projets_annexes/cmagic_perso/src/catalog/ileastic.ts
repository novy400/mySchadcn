import { renderTemplate } from '../generation/template-renderer.js';
import {
    catalogIleasticInterfaceSourceName,
    catalogRpgReadInterfaceSourceName
} from './artifact-names.js';
import type { CatalogFieldType, CatalogSpec } from './catalog-spec.js';
import {
    buildCatalogReadTemplateModel,
    type CatalogReadTemplateModel
} from './rpg-read.js';

const templateName = 'catalog-ileastic.sqlrpgle.hbs';

type CatalogIleasticIdentifierModel = {
    rpgType: string;
    isString: boolean;
    isInteger: boolean;
    isDecimal: boolean;
    isDate: boolean;
    isBoolean: boolean;
    isEnum: boolean;
    maxLength?: number;
    precision?: number;
    scale?: number;
    enumValues: string[];
};

type CatalogIleasticInterfacesModel = {
    read: string;
    ileastic: string;
};

type CatalogIleasticProceduresModel =
    CatalogReadTemplateModel['procedures'] & {
        getListRest: string;
        getOneRest: string;
        registerRoutes: string;
        parseId: string;
        writeListResponse: string;
        writeDetailResponse: string;
    };

type CatalogIleasticProcedureParameterModel = {
    name: string;
    type: string;
};

type CatalogIleasticProcedureSignatureModel = {
    name: string;
    parameters: CatalogIleasticProcedureParameterModel[];
};

type CatalogIleasticBooleanFieldModel = {
    name: string;
};

export type CatalogIleasticTemplateModel = {
    entityName: string;
    entityDisplayName: string;
    resource: string;
    includeGuard: string;
    hasList: boolean;
    hasGet: boolean;
    interfaces: CatalogIleasticInterfacesModel;
    procedures: CatalogIleasticProceduresModel;
    procedureSignatures: {
        registerRoutes: CatalogIleasticProcedureSignatureModel;
    };
    booleanFields: {
        list: CatalogIleasticBooleanFieldModel[];
        detail: CatalogIleasticBooleanFieldModel[];
    };
    id: CatalogIleasticIdentifierModel;
};

const identifierModel = (
    type: CatalogFieldType,
    rpgType: string
): CatalogIleasticIdentifierModel => ({
    rpgType,
    isString: type.kind === 'string',
    isInteger: type.kind === 'integer',
    isDecimal: type.kind === 'decimal',
    isDate: type.kind === 'date',
    isBoolean: type.kind === 'boolean',
    isEnum: type.kind === 'enum',
    ...(type.kind === 'string'
        ? { maxLength: type.length ?? 256 }
        : {}),
    ...(type.kind === 'decimal'
        ? { precision: type.precision, scale: type.scale }
        : {}),
    enumValues: type.kind === 'enum' ? type.values : []
});

export const buildCatalogIleasticTemplateModel = (
    spec: CatalogSpec
): CatalogIleasticTemplateModel => {
    const readModel = buildCatalogReadTemplateModel(spec);
    const identifier = spec.fields.find(
        field => field.name === spec.identifier
    );
    if (!identifier) {
        throw new Error(`Catalog identifier field not found: ${spec.identifier}`);
    }

    const prefix = readModel.entityName;
    const registerRoutes = `${prefix}_registerRoutes`;
    const detailBooleanFields = spec.fields
        .filter(field => field.type.kind === 'boolean')
        .map(field => ({ name: field.name }));
    const booleanFieldNames = new Set(
        detailBooleanFields.map(field => field.name)
    );
    return {
        entityName: readModel.entityName,
        entityDisplayName: readModel.entityDisplayName,
        resource: spec.resource,
        includeGuard: `${spec.entity.toUpperCase()}_ILEASTIC_H_DEFINED`,
        hasList: readModel.hasList,
        hasGet: readModel.hasGet,
        interfaces: {
            read: catalogRpgReadInterfaceSourceName(spec.resource),
            ileastic: catalogIleasticInterfaceSourceName(spec.resource)
        },
        procedures: {
            ...readModel.procedures,
            getListRest: `${prefix}_getlist_rest`,
            getOneRest: `${prefix}_getone_rest`,
            registerRoutes,
            parseId: `${prefix}_parseId`,
            writeListResponse: `${prefix}_writeListResponse`,
            writeDetailResponse: `${prefix}_writeDetailResponse`
        },
        procedureSignatures: {
            registerRoutes: {
                name: registerRoutes,
                parameters: [{ name: 'config', type: 'likeDS(IL_config)' }]
            }
        },
        booleanFields: {
            list:
                spec.list?.fields
                    .filter(field => booleanFieldNames.has(field))
                    .map(name => ({ name })) ?? [],
            detail: detailBooleanFields
        },
        id: identifierModel(identifier.type, readModel.id.rpgType)
    };
};

export const generateCatalogIleasticWrapper = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogIleasticTemplateModel(spec),
        templatesDirectory
    );
