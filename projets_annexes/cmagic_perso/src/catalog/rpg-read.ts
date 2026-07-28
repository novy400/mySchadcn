import type {
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogListSpec,
    CatalogSpec
} from './catalog-spec.js';
import { renderTemplate } from '../generation/template-renderer.js';
import {
    assertSqlColumnIdentifier,
    assertSqlObjectIdentifier
} from './sql-identifier.js';
import {
    catalogReadProcedures,
    type CatalogReadProcedures
} from './read-procedures.js';
import { catalogRpgReadInterfaceSourceName } from './artifact-names.js';

const templateName = 'catalog-read.sqlrpgle.hbs';

type FieldTypeTemplateModel = {
    rpgType: string;
    sqlDefault: string;
    cmagicDataType: 'C' | 'N' | 'D';
};

type FieldTemplateModel = FieldTypeTemplateModel & {
    name: string;
    rpgName: string;
    column: string;
    required: boolean;
};

type ProcedureParameterTemplateModel = {
    name: string;
    type: string;
    isConst: boolean;
};

type ProcedureSignatureTemplateModel = {
    name: string;
    returnType: 'ind';
    parameters: ProcedureParameterTemplateModel[];
};

type ReadProcedureSignaturesTemplateModel = {
    getSupportedFields: ProcedureSignatureTemplateModel;
    search: ProcedureSignatureTemplateModel;
    get: ProcedureSignatureTemplateModel;
};

export type CatalogReadTemplateModel = {
    entityName: string;
    entityDisplayName: string;
    includeGuard: string;
    readInterfaceSource: string;
    table: string;
    hasList: boolean;
    hasGet: boolean;
    procedures: CatalogReadProcedures;
    procedureSignatures: ReadProcedureSignaturesTemplateModel;
    itemFields: FieldTemplateModel[];
    detailFields: FieldTemplateModel[];
    supportedFields: FieldTemplateModel[];
    defaultSortField: string;
    defaultSortOrder: string;
    id: FieldTemplateModel;
};

const fieldTypeModel = (type: CatalogFieldType): FieldTypeTemplateModel => {
    switch (type.kind) {
        case 'string':
            return {
                rpgType: `varchar(${type.length ?? 256})`,
                sqlDefault: "''",
                cmagicDataType: 'C'
            };
        case 'integer':
            return {
                rpgType: 'int(20)',
                sqlDefault: '0',
                cmagicDataType: 'N'
            };
        case 'decimal':
            return {
                rpgType: `packed(${type.precision}:${type.scale})`,
                sqlDefault: '0',
                cmagicDataType: 'N'
            };
        case 'date':
            return {
                rpgType: 'date',
                sqlDefault: "DATE('0001-01-01')",
                cmagicDataType: 'D'
            };
        case 'boolean':
            return {
                rpgType: 'char(1)',
                sqlDefault: "''",
                cmagicDataType: 'C'
            };
        case 'enum':
            return {
                rpgType: `varchar(${Math.max(
                    1,
                    ...type.values.map(value => value.length)
                )})`,
                sqlDefault: "''",
                cmagicDataType: 'C'
            };
    }
};

const fieldModel = (field: CatalogFieldSpec): FieldTemplateModel => ({
    ...fieldTypeModel(field.type),
    name: field.name,
    rpgName: field.name,
    column: field.column,
    required: field.required
});

const requireField = <Field>(
    fieldsByName: Map<string, Field>,
    fieldName: string,
    role: string
): Field => {
    const field = fieldsByName.get(fieldName);
    if (!field) {
        throw new Error(`Catalog ${role} field not found: ${fieldName}`);
    }
    return field;
};

const requireFields = <Field>(
    fieldsByName: Map<string, Field>,
    fieldNames: string[],
    role: string
): void => {
    for (const fieldName of fieldNames) {
        requireField(fieldsByName, fieldName, role);
    }
};

const requireList = (spec: CatalogSpec): CatalogListSpec => {
    if (!spec.list) {
        throw new Error(`Catalog LIST capability requires a list view: ${spec.entity}`);
    }
    return spec.list;
};

const parameter = (
    name: string,
    type: string,
    isConst = false
): ProcedureParameterTemplateModel => ({
    name,
    type,
    isConst
});

const buildProcedureSignatures = (
    procedures: CatalogReadProcedures,
    id: FieldTemplateModel,
    entityName: string
): ReadProcedureSignaturesTemplateModel => ({
    getSupportedFields: {
        name: procedures.getSupportedFields,
        returnType: 'ind',
        parameters: [
            parameter('pSupportedFields', 'likeDS(CMAGIC_supportedFields)'),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    },
    search: {
        name: procedures.search,
        returnType: 'ind',
        parameters: [
            parameter('pContext', 'likeDS(CMAGIC_context)', true),
            parameter('pTotalCount', 'like(CMAGIC_totalCount)'),
            parameter('pItems', 'pointer'),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    },
    get: {
        name: procedures.get,
        returnType: 'ind',
        parameters: [
            parameter('pId', id.rpgType, true),
            parameter('pDetail', `likeDS(${entityName}_detail_t)`),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    }
});

export const buildCatalogReadTemplateModel = (
    spec: CatalogSpec
): CatalogReadTemplateModel => {
    assertSqlObjectIdentifier(spec.table);
    for (const field of spec.fields) {
        assertSqlColumnIdentifier(field.column);
    }

    const procedures = catalogReadProcedures(spec);
    const fields = spec.fields.map(fieldModel);
    const fieldsByName = new Map(fields.map(field => [field.name, field]));
    const id = requireField(fieldsByName, spec.identifier, 'identifier');
    const list = procedures.hasList ? requireList(spec) : undefined;
    const itemFields =
        list?.fields.map(name => requireField(fieldsByName, name, 'list')) ?? [];
    const entityName = spec.entity.toLowerCase();

    requireFields(fieldsByName, list?.searchFields ?? [], 'search');
    requireFields(fieldsByName, list?.filterFields ?? [], 'filter');
    requireFields(fieldsByName, list?.sortFields ?? [], 'sort');

    return {
        entityName,
        entityDisplayName: spec.entity,
        includeGuard: `${spec.entity.toUpperCase()}_READ_H_DEFINED`,
        readInterfaceSource: catalogRpgReadInterfaceSourceName(spec.resource),
        table: spec.table,
        hasList: procedures.hasList,
        hasGet: procedures.hasGet,
        procedures,
        procedureSignatures: buildProcedureSignatures(
            procedures,
            id,
            entityName
        ),
        itemFields,
        detailFields: fields,
        supportedFields: itemFields,
        defaultSortField: list?.defaultSort.field ?? spec.identifier,
        defaultSortOrder: list?.defaultSort.order ?? 'ASC',
        id
    };
};

export const generateRpgReadModule = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(
        templateName,
        buildCatalogReadTemplateModel(spec),
        templatesDirectory
    );
