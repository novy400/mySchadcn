import type {
    Entity,
    Field,
    Model,
    TypeDefinition
} from '../language/generated/ast.js';
import type {
    CatalogCapability,
    CatalogCompilation,
    CatalogDiagnostic,
    CatalogDiagnosticCode,
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogFilterOperator,
    CatalogSpec
} from './catalog-spec.js';

const capabilityAliases: Readonly<Record<string, CatalogCapability>> = {
    SEARCH: 'list',
    LIST: 'list',
    DISPLAY: 'get',
    GET: 'get',
    CREATE: 'create',
    CHANGE: 'update',
    UPDATE: 'update',
    DELETE: 'delete'
};

const capabilityOrder: CatalogCapability[] = [
    'list',
    'get',
    'create',
    'update',
    'delete'
];

const filterOperators = new Set<CatalogFilterOperator>([
    'eq',
    'ne',
    'like',
    'gte',
    'lte',
    'gt',
    'lt'
]);

const DB2_MAX_VARCHAR_LENGTH = 32739;
const DB2_MAX_DECIMAL_PRECISION = 63;

const diagnostic = (
    code: CatalogDiagnosticCode,
    entity: Entity,
    message: string,
    field?: Field
): CatalogDiagnostic => ({
    severity: 'error',
    code,
    message,
    entity: entity.name,
    ...(field ? { field: field.name } : {})
});

const toFieldType = (
    type: TypeDefinition,
    model: Model
): CatalogFieldType | undefined => {
    switch (type.typeName) {
        case 'String':
            return {
                kind: 'string',
                ...(type.args[0] === undefined ? {} : { length: type.args[0] })
            };
        case 'Int':
            return { kind: 'integer' };
        case 'Decimal':
            if (type.precision === undefined || type.scale === undefined) {
                return undefined;
            }
            return {
                kind: 'decimal',
                precision: type.precision,
                scale: type.scale
            };
        case 'Date':
            return { kind: 'date' };
        case 'Boolean':
            return { kind: 'boolean' };
        default: {
            const enumDefinition = model.enums.find(
                candidate => candidate.name === type.typeName
            );
            if (!enumDefinition) {
                return undefined;
            }
            return {
                kind: 'enum',
                name: enumDefinition.name,
                values: enumDefinition.values.map(value => value.name)
            };
        }
    }
};

const getCapabilities = (model: Model, entity: Entity): CatalogCapability[] => {
    const rawCapabilities = model.operations
        .filter(block => block.entity.ref === entity)
        .flatMap(block => block.operations)
        .map(operation => capabilityAliases[operation])
        .filter((capability): capability is CatalogCapability => capability !== undefined);
    const capabilities = new Set(rawCapabilities);

    return capabilityOrder.filter(capability => capabilities.has(capability));
};

const getFilterOperators = (field: Field): CatalogFilterOperator[] =>
    (field.filter?.operators ?? [])
        .map(operator => operator.toLowerCase())
        .filter(
            (operator): operator is CatalogFilterOperator =>
                filterOperators.has(operator as CatalogFilterOperator)
        );

const compileEntity = (
    model: Model,
    entity: Entity
): { spec?: CatalogSpec; diagnostics: CatalogDiagnostic[] } => {
    const diagnostics: CatalogDiagnostic[] = [];

    if (!entity.resourceName) {
        diagnostics.push(
            diagnostic(
                'CATALOG_RESOURCE_REQUIRED',
                entity,
                `L'entité catalogue ${entity.name} doit déclarer une ressource.`
            )
        );
    }
    if (!entity.tableName) {
        diagnostics.push(
            diagnostic(
                'CATALOG_TABLE_REQUIRED',
                entity,
                `L'entité catalogue ${entity.name} doit déclarer une table.`
            )
        );
    }

    const keyFields = entity.fields.filter(field => field.key);
    if (keyFields.length === 0) {
        diagnostics.push(
            diagnostic(
                'CATALOG_KEY_REQUIRED',
                entity,
                `L'entité catalogue ${entity.name} doit avoir un identifiant.`
            )
        );
    } else if (keyFields.length > 1) {
        diagnostics.push(
            diagnostic(
                'CATALOG_KEY_AMBIGUOUS',
                entity,
                `L'entité catalogue ${entity.name} ne peut avoir qu'un identifiant.`
            )
        );
    } else if (keyFields[0].name !== 'id') {
        diagnostics.push(
            diagnostic(
                'CATALOG_IDENTIFIER_MUST_BE_ID',
                entity,
                `L'identifiant public de ${entity.name} doit s'appeler id.`,
                keyFields[0]
            )
        );
    }

    for (const field of entity.fields) {
        if (!field.columnName) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_COLUMN_REQUIRED',
                    entity,
                    `Le champ ${field.name} doit déclarer une colonne Db2.`,
                    field
                )
            );
        }
    }

    const fieldTypes = new Map<Field, CatalogFieldType>();
    for (const field of entity.fields) {
        const fieldType = toFieldType(field.type, model);
        if (!fieldType) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_TYPE_UNSUPPORTED',
                    entity,
                    `Le type ${field.type.typeName} n'est pas supporté par Catalogue v0.`,
                    field
                )
            );
        } else {
            fieldTypes.set(field, fieldType);
        }
    }

    for (const field of entity.fields) {
        const operators = getFilterOperators(field);
        const fieldType = fieldTypes.get(field);
        if (
            fieldType?.kind === 'string' &&
            fieldType.length !== undefined &&
            (!Number.isInteger(fieldType.length) ||
                fieldType.length < 1 ||
                fieldType.length > DB2_MAX_VARCHAR_LENGTH)
        ) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_STRING_LENGTH_INVALID',
                    entity,
                    `La longueur String de ${field.name} doit être un entier entre 1 et ${DB2_MAX_VARCHAR_LENGTH}.`,
                    field
                )
            );
        }
        if (
            fieldType?.kind === 'decimal' &&
            (!Number.isInteger(fieldType.precision) ||
                !Number.isInteger(fieldType.scale) ||
                fieldType.precision < 1 ||
                fieldType.precision > DB2_MAX_DECIMAL_PRECISION ||
                fieldType.scale < 0 ||
                fieldType.scale > fieldType.precision)
        ) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_DECIMAL_SHAPE_INVALID',
                    entity,
                    `Le type Decimal de ${field.name} exige une précision entière entre 1 et ${DB2_MAX_DECIMAL_PRECISION} et une échelle entière comprise entre 0 et la précision.`,
                    field
                )
            );
        }
        if (fieldType?.kind === 'enum' && fieldType.values.length === 0) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_ENUM_EMPTY',
                    entity,
                    `L'enum ${fieldType.name} utilisé par ${field.name} doit déclarer au moins une valeur.`,
                    field
                )
            );
        }
        if (operators.includes('like') && fieldType?.kind !== 'string') {
            diagnostics.push(
                diagnostic(
                    'CATALOG_FILTER_OPERATOR_INVALID',
                    entity,
                    `L'opérateur LIKE exige un champ de type String.`,
                    field
                )
            );
        }
        if (field.searchable && fieldType?.kind !== 'string') {
            diagnostics.push(
                diagnostic(
                    'CATALOG_SEARCH_FIELD_INVALID',
                    entity,
                    `La recherche q exige un champ de type String.`,
                    field
                )
            );
        }
    }

    const capabilities = getCapabilities(model, entity);
    const unsupportedCapabilities = capabilities.filter(
        capability => capability !== 'list' && capability !== 'get'
    );
    if (unsupportedCapabilities.length > 0) {
        diagnostics.push(
            diagnostic(
                'CATALOG_CAPABILITY_UNSUPPORTED',
                entity,
                `Catalogue v0 ne supporte pas encore: ${unsupportedCapabilities.join(', ')}.`
            )
        );
    }

    const fieldNames = new Set(entity.fields.map(field => field.name));
    const entityViews = model.views.filter(view => view.entity.ref === entity);
    for (const view of entityViews) {
        for (const fieldName of view.fields) {
            if (!fieldNames.has(fieldName)) {
                diagnostics.push({
                    severity: 'error',
                    code: 'CATALOG_VIEW_FIELD_UNKNOWN',
                    message: `Le champ ${fieldName} de la vue ${view.name} n'existe pas.`,
                    entity: entity.name,
                    field: fieldName
                });
            }
        }
    }

    const listView = model.views.find(
        view => view.entity.ref === entity && view.name.toLowerCase() === 'list'
    );
    if (capabilities.includes('list')) {
        if (!listView) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_LIST_VIEW_REQUIRED',
                    entity,
                    `La capacité LIST exige une vue list.`
                )
            );
        } else if (listView.fields.length === 0) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_LIST_VIEW_EMPTY',
                    entity,
                    `La vue list doit exposer au moins un champ.`
                )
            );
        } else if (!listView.fields.includes('id')) {
            diagnostics.push(
                diagnostic(
                    'CATALOG_LIST_IDENTIFIER_REQUIRED',
                    entity,
                    `La vue list doit exposer l'identifiant public id.`
                )
            );
        }
    }

    if (
        diagnostics.length > 0 ||
        !entity.resourceName ||
        !entity.tableName ||
        keyFields.length !== 1 ||
        keyFields[0].name !== 'id'
    ) {
        return { diagnostics };
    }

    const fields: CatalogFieldSpec[] = entity.fields.map(field => ({
        name: field.name,
        column: field.columnName as string,
        type: fieldTypes.get(field) as CatalogFieldType,
        key: field.key,
        required: field.required,
        unique: field.unique,
        searchable: field.searchable,
        sortable: field.sortable,
        filterOperators: getFilterOperators(field)
    }));

    const spec: CatalogSpec = {
        version: 1,
        entity: entity.name,
        resource: entity.resourceName,
        table: entity.tableName,
        identifier: 'id',
        capabilities,
        fields
    };

    if (capabilities.includes('list') && listView) {
        spec.list = {
            fields: [...listView.fields],
            searchFields: fields
                .filter(
                    field =>
                        field.searchable && listView.fields.includes(field.name)
                )
                .map(field => field.name),
            filterFields: fields
                .filter(field => field.filterOperators.length > 0)
                .map(field => field.name),
            sortFields: fields.filter(field => field.sortable).map(field => field.name),
            defaultSort: {
                field: spec.identifier,
                order: 'ASC'
            }
        };
    }

    return { spec, diagnostics };
};

export const buildCatalogSpecs = (model: Model): CatalogCompilation => {
    const catalogEntities = model.entities.filter(
        entity => entity.resourceName !== undefined || entity.tableName !== undefined
    );
    const compilation = catalogEntities.map(entity => compileEntity(model, entity));

    return {
        specs: compilation.flatMap(result => (result.spec ? [result.spec] : [])),
        diagnostics: compilation.flatMap(result => result.diagnostics)
    };
};
