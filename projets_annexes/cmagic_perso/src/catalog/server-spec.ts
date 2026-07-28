export type CatalogServerCatalogSpec = {
    entity: string;
    resource: string;
    readObject: string;
    ileasticObject: string;
};

export type CatalogServerSpec = {
    version: 1;
    name: string;
    object: string;
    port: number;
    host: string;
    catalogs: CatalogServerCatalogSpec[];
};

export type CatalogServerDiagnosticCode =
    | 'CATALOG_SERVER_OBJECT_INVALID'
    | 'CATALOG_SERVER_PORT_INVALID'
    | 'CATALOG_SERVER_EMPTY'
    | 'CATALOG_SERVER_CATALOG_REQUIRED'
    | 'CATALOG_SERVER_CATALOG_DUPLICATE'
    | 'CATALOG_SERVER_ILEASTIC_OBJECT_REQUIRED'
    | 'CATALOG_SERVER_OBJECT_COLLISION';

export type CatalogServerDiagnostic = {
    severity: 'error';
    code: CatalogServerDiagnosticCode;
    message: string;
    server: string;
    entity?: string;
};

export type CatalogServerCompilation = {
    specs: CatalogServerSpec[];
    diagnostics: CatalogServerDiagnostic[];
};
