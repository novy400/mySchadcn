import type {
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogSpec
} from './catalog-spec.js';
import { renderTemplate } from '../generation/template-renderer.js';
import {
    assertSqlColumnIdentifier,
    assertSqlObjectIdentifier
} from './sql-identifier.js';

const templateName = 'catalog.ddl.sql.hbs';

type DdlFieldTemplateModel = {
    name: string;
    column: string;
    sqlType: string;
    required: boolean;
    hasFollowingDefinition: boolean;
};

type DdlConstraintTemplateModel = {
    isPrimaryKey: boolean;
    isUnique: boolean;
    isValueCheck: boolean;
    columns: string[];
    column?: string;
    enumValues?: string[];
    hasFollowingDefinition: boolean;
};

type CatalogDdlTemplateModel = {
    entityName: string;
    table: string;
    fields: DdlFieldTemplateModel[];
    constraints: DdlConstraintTemplateModel[];
};

const sqlType = (type: CatalogFieldType): string => {
    switch (type.kind) {
        case 'string':
            return `VARCHAR(${type.length ?? 256})`;
        case 'integer':
            return 'INTEGER';
        case 'decimal':
            return `DECIMAL(${type.precision}, ${type.scale})`;
        case 'date':
            return 'DATE';
        case 'boolean':
            return 'CHAR(1)';
        case 'enum':
            return `VARCHAR(${Math.max(
                1,
                ...type.values.map(value => value.length)
            )})`;
    }
};

const escapeSqlLiteral = (value: string): string =>
    value.replaceAll("'", "''");

const buildConstraints = (
    fields: CatalogFieldSpec[]
): Omit<DdlConstraintTemplateModel, 'hasFollowingDefinition'>[] => {
    const primaryKeyColumns = fields
        .filter(field => field.key)
        .map(field => field.column);
    const primaryKey =
        primaryKeyColumns.length > 0
            ? [
                  {
                      isPrimaryKey: true,
                      isUnique: false,
                      isValueCheck: false,
                      columns: primaryKeyColumns
                  }
              ]
            : [];
    const uniqueConstraints = fields
        .filter(field => field.unique && !field.key)
        .map(field => ({
            isPrimaryKey: false,
            isUnique: true,
            isValueCheck: false,
            columns: [field.column]
        }));
    const valueCheckConstraints = fields
        .filter(
            (
                field
            ): field is CatalogFieldSpec & {
                type: Extract<
                    CatalogFieldType,
                    { kind: 'boolean' | 'enum' }
                >;
            } =>
                field.type.kind === 'boolean' ||
                (field.type.kind === 'enum' && field.type.values.length > 0)
        )
        .map(field => ({
            isPrimaryKey: false,
            isUnique: false,
            isValueCheck: true,
            columns: [field.column],
            column: field.column,
            enumValues:
                field.type.kind === 'boolean'
                    ? ['Y', 'N']
                    : field.type.values.map(escapeSqlLiteral)
        }));

    return [...primaryKey, ...uniqueConstraints, ...valueCheckConstraints];
};

const buildTemplateModel = (spec: CatalogSpec): CatalogDdlTemplateModel => {
    assertSqlObjectIdentifier(spec.table);
    for (const field of spec.fields) {
        assertSqlColumnIdentifier(field.column);
    }

    const constraints = buildConstraints(spec.fields);
    const fields = spec.fields.map((field, index) => ({
        name: field.name,
        column: field.column,
        sqlType: sqlType(field.type),
        required: field.required,
        hasFollowingDefinition:
            index < spec.fields.length - 1 || constraints.length > 0
    }));

    return {
        entityName: spec.entity,
        table: spec.table,
        fields,
        constraints: constraints.map((constraint, index) => ({
            ...constraint,
            hasFollowingDefinition: index < constraints.length - 1
        }))
    };
};

export const generateCatalogDdl = (
    spec: CatalogSpec,
    templatesDirectory?: string
): string =>
    renderTemplate(templateName, buildTemplateModel(spec), templatesDirectory);
