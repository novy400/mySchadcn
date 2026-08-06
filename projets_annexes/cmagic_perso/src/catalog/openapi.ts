import type {
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogFilterOperator,
    CatalogSpec
} from './catalog-spec.js';

type OpenApiSchema = {
    type?: string;
    format?: string;
    maxLength?: number;
    minimum?: number;
    enum?: string[];
    properties?: Record<string, OpenApiSchema>;
    required?: string[];
    items?: OpenApiSchema;
    $ref?: string;
    'x-cmagic-precision'?: number;
    'x-cmagic-scale'?: number;
};

type OpenApiParameter = {
    name: string;
    in: 'query' | 'path';
    required: boolean;
    schema: OpenApiSchema;
    'x-cmagic-operators'?: CatalogFilterOperator[];
};

type OpenApiOperation = {
    operationId: string;
    parameters: OpenApiParameter[];
    requestBody?: {
        required: boolean;
        content: Record<string, { schema: OpenApiSchema }>;
    };
    responses: Record<string, unknown>;
};

type OpenApiPath = {
    get?: OpenApiOperation;
    post?: OpenApiOperation;
    put?: OpenApiOperation;
};

export type OpenApiDocument = {
    openapi: '3.1.0';
    info: {
        title: string;
        version: '1.0.0';
    };
    paths: Record<string, OpenApiPath>;
    components: {
        schemas: Record<string, OpenApiSchema>;
    };
};

const toOpenApiSchema = (type: CatalogFieldType): OpenApiSchema => {
    switch (type.kind) {
        case 'string':
            return {
                type: 'string',
                ...(type.length === undefined ? {} : { maxLength: type.length })
            };
        case 'integer':
            return { type: 'integer' };
        case 'decimal':
            return {
                type: 'number',
                format: 'decimal',
                'x-cmagic-precision': type.precision,
                'x-cmagic-scale': type.scale
            };
        case 'date':
            return { type: 'string', format: 'date' };
        case 'boolean':
            return { type: 'boolean' };
        case 'enum':
            return { type: 'string', enum: type.values };
    }
};

const queryParameter = (
    name: string,
    schema: OpenApiSchema,
    operators?: CatalogFilterOperator[]
): OpenApiParameter => ({
    name,
    in: 'query',
    required: false,
    schema,
    ...(operators ? { 'x-cmagic-operators': operators } : {})
});

const listParameters = (spec: CatalogSpec): OpenApiParameter[] => {
    if (!spec.list) {
        return [];
    }

    const fieldsByName = new Map(spec.fields.map(field => [field.name, field]));
    const parameters: OpenApiParameter[] = [
        queryParameter('page', { type: 'integer', minimum: 1 }),
        queryParameter('perPage', { type: 'integer', minimum: 1 }),
        queryParameter('sort', { type: 'string', enum: spec.list.sortFields }),
        queryParameter('order', { type: 'string', enum: ['ASC', 'DESC'] })
    ];

    if (spec.list.searchFields.length > 0) {
        parameters.push(queryParameter('q', { type: 'string' }, ['like']));
    }

    for (const fieldName of spec.list.filterFields) {
        const field = fieldsByName.get(fieldName) as CatalogFieldSpec;
        parameters.push(
            queryParameter(
                field.name,
                toOpenApiSchema(field.type),
                field.filterOperators
            )
        );
    }

    return parameters;
};

export const generateOpenApiDocument = (spec: CatalogSpec): OpenApiDocument => {
    const recordSchema: OpenApiSchema = {
        type: 'object',
        properties: Object.fromEntries(
            spec.fields.map(field => [field.name, toOpenApiSchema(field.type)])
        ),
        required: spec.fields
            .filter(field => field.required)
            .map(field => field.name)
    };
    const paths: Record<string, OpenApiPath> = {};
    const collectionPath = `/api/${spec.resource}`;
    const itemPath = `/api/${spec.resource}/{id}`;
    const recordReference = {
        $ref: `#/components/schemas/${spec.entity}`
    };
    const recordResponse = (description: string): unknown => ({
        description,
        content: {
            'application/json': {
                schema: {
                    type: 'object',
                    properties: {
                        data: recordReference
                    },
                    required: ['data']
                }
            }
        }
    });
    const identifierParameter: OpenApiParameter = {
        name: 'id',
        in: 'path',
        required: true,
        schema: toOpenApiSchema(
            spec.fields.find(field => field.name === spec.identifier)?.type ?? {
                kind: 'string'
            }
        )
    };

    if (spec.capabilities.includes('list')) {
        paths[collectionPath] = {
            ...paths[collectionPath],
            get: {
                operationId: `list${spec.entity}`,
                parameters: listParameters(spec),
                responses: {
                    '200': {
                        description: `Liste paginée de ${spec.resource}`,
                        content: {
                            'application/json': {
                                schema: {
                                    type: 'object',
                                    properties: {
                                        data: {
                                            type: 'array',
                                            items: recordReference
                                        },
                                        total: { type: 'integer' }
                                    },
                                    required: ['data', 'total']
                                }
                            }
                        }
                    }
                }
            }
        };
    }

    if (spec.capabilities.includes('get')) {
        paths[itemPath] = {
            ...paths[itemPath],
            get: {
                operationId: `get${spec.entity}`,
                parameters: [identifierParameter],
                responses: {
                    '200': recordResponse(`${spec.entity} trouvé`),
                    '404': {
                        description: `${spec.entity} inconnu`
                    }
                }
            }
        };
    }

    if (spec.capabilities.includes('create')) {
        paths[collectionPath] = {
            ...paths[collectionPath],
            post: {
                operationId: `create${spec.entity}`,
                parameters: [],
                requestBody: {
                    required: true,
                    content: {
                        'application/json': {
                            schema: recordReference
                        }
                    }
                },
                responses: {
                    '201': recordResponse(`${spec.entity} cree`),
                    '400': {
                        description: `Donnees ${spec.entity} invalides`
                    },
                    '409': {
                        description: `${spec.entity} existe deja`
                    },
                    '500': {
                        description: `Erreur technique pendant la creation de ${spec.entity}`
                    }
                }
            }
        };
    }

    if (spec.capabilities.includes('update')) {
        paths[itemPath] = {
            ...paths[itemPath],
            put: {
                operationId: `update${spec.entity}`,
                parameters: [identifierParameter],
                requestBody: {
                    required: true,
                    content: {
                        'application/json': {
                            schema: recordReference
                        }
                    }
                },
                responses: {
                    '200': recordResponse(`${spec.entity} modifie`),
                    '400': {
                        description: `Donnees ${spec.entity} invalides`
                    },
                    '404': {
                        description: `${spec.entity} inconnu`
                    },
                    '409': {
                        description: `Conflit pendant la modification de ${spec.entity}`
                    },
                    '500': {
                        description: `Erreur technique pendant la modification de ${spec.entity}`
                    }
                }
            }
        };
    }

    return {
        openapi: '3.1.0',
        info: {
            title: `${spec.entity} catalogue API`,
            version: '1.0.0'
        },
        paths,
        components: {
            schemas: {
                [spec.entity]: recordSchema
            }
        }
    };
};

export const generateOpenApiSource = (spec: CatalogSpec): string =>
    `${JSON.stringify(generateOpenApiDocument(spec), null, 2)}\n`;
