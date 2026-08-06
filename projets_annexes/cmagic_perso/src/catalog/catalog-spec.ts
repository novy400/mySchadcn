export type CatalogCapability = 'list' | 'get' | 'create' | 'update' | 'delete';

export type CatalogFilterOperator =
    | 'eq'
    | 'ne'
    | 'like'
    | 'gte'
    | 'lte'
    | 'gt'
    | 'lt';

export type CatalogFieldType =
    | { kind: 'string'; length?: number }
    | { kind: 'integer' }
    | { kind: 'decimal'; precision: number; scale: number }
    | { kind: 'date' }
    | { kind: 'boolean' }
    | { kind: 'enum'; name: string; values: string[] };

export type CatalogFieldSpec = {
    name: string;
    column: string;
    type: CatalogFieldType;
    key: boolean;
    required: boolean;
    unique: boolean;
    searchable: boolean;
    sortable: boolean;
    filterOperators: CatalogFilterOperator[];
};

export type CatalogListSpec = {
    fields: string[];
    searchFields: string[];
    filterFields: string[];
    sortFields: string[];
    defaultSort: {
        field: string;
        order: 'ASC';
    };
};

export type CatalogSpec = {
    version: 1;
    entity: string;
    resource: string;
    table: string;
    ileasticObject?: string;
    iwsObject?: string;
    identifier: 'id';
    capabilities: CatalogCapability[];
    fields: CatalogFieldSpec[];
    list?: CatalogListSpec;
};

export type CatalogDiagnosticCode =
    | 'CATALOG_RESOURCE_REQUIRED'
    | 'CATALOG_TABLE_REQUIRED'
    | 'CATALOG_ILEASTIC_OBJECT_INVALID'
    | 'CATALOG_ILEASTIC_OBJECT_COLLISION'
    | 'CATALOG_IWS_OBJECT_INVALID'
    | 'CATALOG_IWS_OBJECT_COLLISION'
    | 'CATALOG_TRANSPORT_AMBIGUOUS'
    | 'CATALOG_ILEASTIC_CREATE_UNSUPPORTED'
    | 'CATALOG_IWS_LIST_REQUIRED'
    | 'CATALOG_IWS_CREATE_GET_REQUIRED'
    | 'CATALOG_KEY_REQUIRED'
    | 'CATALOG_KEY_AMBIGUOUS'
    | 'CATALOG_IDENTIFIER_MUST_BE_ID'
    | 'CATALOG_COLUMN_REQUIRED'
    | 'CATALOG_TYPE_UNSUPPORTED'
    | 'CATALOG_STRING_LENGTH_INVALID'
    | 'CATALOG_DECIMAL_SHAPE_INVALID'
    | 'CATALOG_ENUM_EMPTY'
    | 'CATALOG_FILTER_OPERATOR_INVALID'
    | 'CATALOG_SEARCH_FIELD_INVALID'
    | 'CATALOG_CAPABILITY_UNSUPPORTED'
    | 'CATALOG_LIST_VIEW_REQUIRED'
    | 'CATALOG_LIST_VIEW_EMPTY'
    | 'CATALOG_LIST_IDENTIFIER_REQUIRED'
    | 'CATALOG_VIEW_FIELD_UNKNOWN';

export type CatalogDiagnostic = {
    severity: 'error';
    code: CatalogDiagnosticCode;
    message: string;
    entity: string;
    field?: string;
};

export type CatalogCompilation = {
    specs: CatalogSpec[];
    diagnostics: CatalogDiagnostic[];
};
