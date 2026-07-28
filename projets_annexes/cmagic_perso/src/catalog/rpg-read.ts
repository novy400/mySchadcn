import type {
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogFilterOperator,
    CatalogListSpec,
    CatalogSpec
} from './catalog-spec.js';
import { renderTemplate } from '../generation/template-renderer.js';

const templateName = 'catalog-read.sqlrpgle.hbs';
const sqlIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_$#@]*$/;

const operatorMetadata: Record<
    CatalogFilterOperator,
    { name: string; symbol?: string; sql: string }
> = {
    eq: { name: 'EQ', symbol: '=', sql: '=' },
    ne: { name: 'NE', symbol: '<>', sql: '<>' },
    like: { name: 'LIKE', sql: 'LIKE' },
    gte: { name: 'GTE', symbol: '>=', sql: '>=' },
    lte: { name: 'LTE', symbol: '<=', sql: '<=' },
    gt: { name: 'GT', symbol: '>', sql: '>' },
    lt: { name: 'LT', symbol: '<', sql: '<' }
};

type FieldTypeTemplateModel = {
    rpgType: string;
    sqlDefault: string;
    isText: boolean;
    isInteger: boolean;
    isDecimal: boolean;
    isDate: boolean;
    isBoolean: boolean;
    precision?: number;
    scale?: number;
    invalidValueMessage?: string;
};

type FieldTemplateModel = FieldTypeTemplateModel & {
    name: string;
    rpgName: string;
    column: string;
    required: boolean;
};

type FilterTemplateModel = FieldTypeTemplateModel & {
    column: string;
    suffix: string;
    useVariable: string;
    valueVariable: string;
    operatorName: string;
    operatorSymbol?: string;
    hasOperatorSymbol: boolean;
    sqlOperator: string;
};

type FilterFieldTemplateModel = {
    name: string;
    filters: FilterTemplateModel[];
};

type CatalogReadTemplateModel = {
    entityName: string;
    entityDisplayName: string;
    table: string;
    hasList: boolean;
    hasGet: boolean;
    hasSearch: boolean;
    hasSortFields: boolean;
    itemFields: FieldTemplateModel[];
    detailFields: FieldTemplateModel[];
    filterFields: FilterFieldTemplateModel[];
    filterBindings: FilterTemplateModel[];
    searchFields: FieldTemplateModel[];
    sortFields: FieldTemplateModel[];
    defaultSortField: string;
    defaultSortOrder: string;
    id: FieldTemplateModel;
};

const assertSqlIdentifier = (identifier: string): void => {
    const parts = identifier.split('.');
    if (
        parts.length > 2 ||
        parts.some(part => !sqlIdentifierPattern.test(part))
    ) {
        throw new Error(`Unsafe SQL identifier: ${identifier}`);
    }
};

const capitalize = (name: string): string =>
    `${name.charAt(0).toUpperCase()}${name.slice(1)}`;

const fieldTypeModel = (type: CatalogFieldType): FieldTypeTemplateModel => {
    const flags = {
        isText: false,
        isInteger: false,
        isDecimal: false,
        isDate: false,
        isBoolean: false
    };

    switch (type.kind) {
        case 'string':
            return {
                ...flags,
                rpgType: `varchar(${type.length ?? 256})`,
                sqlDefault: "''",
                isText: true
            };
        case 'integer':
            return {
                ...flags,
                rpgType: 'int(20)',
                sqlDefault: '0',
                isInteger: true,
                invalidValueMessage: 'Invalid integer value'
            };
        case 'decimal':
            return {
                ...flags,
                rpgType: `packed(${type.precision}:${type.scale})`,
                sqlDefault: '0',
                isDecimal: true,
                precision: type.precision,
                scale: type.scale,
                invalidValueMessage: 'Invalid decimal value'
            };
        case 'date':
            return {
                ...flags,
                rpgType: 'date',
                sqlDefault: "DATE('0001-01-01')",
                isDate: true,
                invalidValueMessage: 'Invalid ISO date'
            };
        case 'boolean':
            return {
                ...flags,
                rpgType: 'ind',
                sqlDefault: 'FALSE',
                isBoolean: true,
                invalidValueMessage: 'Invalid boolean value'
            };
        case 'enum':
            return {
                ...flags,
                rpgType: `varchar(${Math.max(
                    1,
                    ...type.values.map(value => value.length)
                )})`,
                sqlDefault: "''",
                isText: true
            };
    }
};

const fieldModel = (field: CatalogFieldSpec): FieldTemplateModel => ({
    ...fieldTypeModel(field.type),
    name: field.name,
    rpgName: field.name.toLowerCase(),
    column: field.column,
    required: field.required
});

const requireField = (
    fieldsByName: Map<string, FieldTemplateModel>,
    fieldName: string,
    role: string
): FieldTemplateModel => {
    const field = fieldsByName.get(fieldName);
    if (!field) {
        throw new Error(`Catalog ${role} field not found: ${fieldName}`);
    }
    return field;
};

const requireList = (spec: CatalogSpec): CatalogListSpec => {
    if (!spec.list) {
        throw new Error(`Catalog LIST capability requires a list view: ${spec.entity}`);
    }
    return spec.list;
};

const filterSuffix = (
    fieldName: string,
    operator: CatalogFilterOperator
): string => `${capitalize(fieldName)}${capitalize(operator)}`;

const buildTemplateModel = (spec: CatalogSpec): CatalogReadTemplateModel => {
    assertSqlIdentifier(spec.table);
    for (const field of spec.fields) {
        assertSqlIdentifier(field.column);
    }

    const hasList = spec.capabilities.includes('list');
    const hasGet = spec.capabilities.includes('get');
    const fields = spec.fields.map(fieldModel);
    const fieldsByName = new Map(fields.map(field => [field.name, field]));
    const id = requireField(fieldsByName, spec.identifier, 'identifier');
    const list = hasList ? requireList(spec) : undefined;
    const itemFields =
        list?.fields.map(name => requireField(fieldsByName, name, 'list')) ?? [];
    const searchFields =
        list?.searchFields.map(name => requireField(fieldsByName, name, 'search')) ??
        [];
    const sortFields =
        list?.sortFields.map(name => requireField(fieldsByName, name, 'sort')) ?? [];

    const filterFields = hasList
        ? spec.fields
              .map(field => ({
                  name: field.name,
                  filters: field.filterOperators.map(operator => {
                      const metadata = operatorMetadata[operator];
                      const suffix = filterSuffix(field.name, operator);
                      return {
                          ...fieldTypeModel(field.type),
                          column: field.column,
                          suffix,
                          useVariable: `lUse${suffix}`,
                          valueVariable: `l${suffix}`,
                          operatorName: metadata.name,
                          operatorSymbol: metadata.symbol,
                          hasOperatorSymbol: metadata.symbol !== undefined,
                          sqlOperator: metadata.sql
                      };
                  })
              }))
              .filter(field => field.filters.length > 0)
        : [];

    return {
        entityName: spec.entity.toLowerCase(),
        entityDisplayName: spec.entity,
        table: spec.table,
        hasList,
        hasGet,
        hasSearch: searchFields.length > 0,
        hasSortFields: sortFields.length > 0,
        itemFields,
        detailFields: fields,
        filterFields,
        filterBindings: filterFields.flatMap(field => field.filters),
        searchFields,
        sortFields,
        defaultSortField: list?.defaultSort.field ?? spec.identifier,
        defaultSortOrder: list?.defaultSort.order ?? 'ASC',
        id
    };
};

export const generateRpgReadModule = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
