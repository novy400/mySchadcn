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
    maxLength: number;
};

type FieldTemplateModel = FieldTypeTemplateModel & {
    name: string;
    rpgName: string;
    column: string;
    required: boolean;
    requiredCondition?: string;
    domainCondition?: string;
    writeValue: string;
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
    create: ProcedureSignatureTemplateModel;
    update: ProcedureSignatureTemplateModel;
    delete: ProcedureSignatureTemplateModel;
    isValid: ProcedureSignatureTemplateModel;
};

export type CatalogReadTemplateModel = {
    entityName: string;
    entityDisplayName: string;
    includeGuard: string;
    runtimeIncludes: {
        cmagic: string;
        global: string;
    };
    readInterfaceSource: string;
    table: string;
    hasList: boolean;
    hasGet: boolean;
    hasCreate: boolean;
    hasUpdate: boolean;
    hasDelete: boolean;
    hasMutation: boolean;
    hasDetail: boolean;
    actionListName: string;
    procedures: CatalogReadProcedures;
    procedureSignatures: ReadProcedureSignaturesTemplateModel;
    itemFields: FieldTemplateModel[];
    detailFields: FieldTemplateModel[];
    updateFields: FieldTemplateModel[];
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
                cmagicDataType: 'C',
                maxLength: type.length ?? 256
            };
        case 'integer':
            return {
                rpgType: 'int(20)',
                sqlDefault: '0',
                cmagicDataType: 'N',
                maxLength: 0
            };
        case 'decimal':
            return {
                rpgType: `packed(${type.precision}:${type.scale})`,
                sqlDefault: '0',
                cmagicDataType: 'N',
                maxLength: 0
            };
        case 'date':
            return {
                rpgType: 'date',
                sqlDefault: "DATE('0001-01-01')",
                cmagicDataType: 'D',
                maxLength: 0
            };
        case 'boolean':
            return {
                rpgType: 'char(1)',
                sqlDefault: "''",
                cmagicDataType: 'C',
                maxLength: 1
            };
        case 'enum':
            return {
                rpgType: `varchar(${Math.max(
                    1,
                    ...type.values.map(value => value.length)
                )})`,
                sqlDefault: "''",
                cmagicDataType: 'C',
                maxLength: Math.max(
                    1,
                    ...type.values.map(value => value.length)
                )
            };
    }
};

const fieldModel = (field: CatalogFieldSpec): FieldTemplateModel => {
    const hostValue = `:pDetail.${field.name}`;
    const allowedValues =
        field.type.kind === 'boolean'
            ? ['Y', 'N']
            : field.type.kind === 'enum'
              ? field.type.values
              : [];
    const domainCondition =
        allowedValues.length === 0
            ? undefined
            : `%trim(pAfterDetail.${field.name}) <> *blanks and ` +
              allowedValues
                  .map(
                      value =>
                          `pAfterDetail.${field.name} <> '${value}'`
                  )
                  .join(' and ');
    const writeValue =
        field.required || ['integer', 'decimal'].includes(field.type.kind)
            ? hostValue
            : field.type.kind === 'date'
              ? `NULLIF(${hostValue}, DATE('0001-01-01'))`
              : `NULLIF(${hostValue}, '')`;

    return {
        ...fieldTypeModel(field.type),
        name: field.name,
        rpgName: field.name,
        column: field.column,
        required: field.required,
        writeValue,
        ...(domainCondition === undefined ? {} : { domainCondition }),
        ...(field.required &&
        ['string', 'enum', 'boolean'].includes(field.type.kind)
            ? {
                  requiredCondition: `%trim(pAfterDetail.${field.name}) = *blanks`
              }
            : field.required && field.type.kind === 'date'
              ? {
                    requiredCondition: `pAfterDetail.${field.name} = d'0001-01-01'`
                }
              : {})
    };
};

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
    },
    create: {
        name: procedures.create,
        returnType: 'ind',
        parameters: [
            parameter('pDetail', `likeDS(${entityName}_detail_t)`, true),
            parameter('pId', id.rpgType),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    },
    update: {
        name: procedures.update,
        returnType: 'ind',
        parameters: [
            parameter('pId', id.rpgType, true),
            parameter('pDetail', `likeDS(${entityName}_detail_t)`, true),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    },
    delete: {
        name: procedures.delete,
        returnType: 'ind',
        parameters: [
            parameter('pId', id.rpgType, true),
            parameter('pErrors', 'likeDS(GLOBAL_listError)')
        ]
    },
    isValid: {
        name: procedures.isValid,
        returnType: 'ind',
        parameters: [
            parameter('pAction', 'like(GLOBAL_codeAction)', true),
            parameter('pBeforeDetail', `likeDS(${entityName}_detail_t)`, true),
            parameter('pAfterDetail', `likeDS(${entityName}_detail_t)`, true),
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
    const updateFields = fields.filter(field => field.name !== spec.identifier);

    if (procedures.hasUpdate && updateFields.length === 0) {
        throw new Error(
            `Catalog UPDATE capability requires a non-key field: ${spec.entity}`
        );
    }

    requireFields(fieldsByName, list?.searchFields ?? [], 'search');
    requireFields(fieldsByName, list?.filterFields ?? [], 'filter');
    requireFields(fieldsByName, list?.sortFields ?? [], 'sort');

    return {
        entityName,
        entityDisplayName: spec.entity,
        includeGuard: `${spec.entity.toUpperCase()}_READ_H_DEFINED`,
        runtimeIncludes: {
            cmagic: 'cmagic.rpgleinc',
            global: 'global.rpgleinc'
        },
        readInterfaceSource: catalogRpgReadInterfaceSourceName(spec.resource),
        table: spec.table,
        hasList: procedures.hasList,
        hasGet: procedures.hasGet,
        hasCreate: procedures.hasCreate,
        hasUpdate: procedures.hasUpdate,
        hasDelete: procedures.hasDelete,
        hasMutation: procedures.hasMutation,
        hasDetail: procedures.hasGet || procedures.hasMutation,
        actionListName: `${entityName}_listeAction`,
        procedures,
        procedureSignatures: buildProcedureSignatures(
            procedures,
            id,
            entityName
        ),
        itemFields,
        detailFields: fields,
        updateFields,
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
