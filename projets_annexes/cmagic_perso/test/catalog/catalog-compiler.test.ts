import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    buildCatalogSpecs,
    generateCatalogArtifacts,
    generateOpenApiDocument,
    generateResourceContract,
    generateResourceContractSource
} from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

describe('CMagic Catalogue v0', () => {
    test('compiles the Service example into a validated semantic contract', async () => {
        const source = fs.readFileSync(
            path.resolve('examples/service-catalogue.cmagic'),
            'utf-8'
        );
        const model = await parseCMagicString(source);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.diagnostics).toEqual([]);
        expect(compilation.specs).toEqual([
            {
                version: 1,
                entity: 'Service',
                resource: 'services',
                table: 'DEPARTMENT',
                identifier: 'id',
                capabilities: ['list', 'get'],
                fields: [
                    {
                        name: 'id',
                        column: 'DEPTNO',
                        type: { kind: 'string', length: 3 },
                        key: true,
                        required: true,
                        unique: false,
                        searchable: true,
                        sortable: true,
                        filterOperators: ['eq', 'like']
                    },
                    {
                        name: 'nom',
                        column: 'DEPTNAME',
                        type: { kind: 'string', length: 36 },
                        key: false,
                        required: true,
                        unique: false,
                        searchable: true,
                        sortable: true,
                        filterOperators: ['eq', 'like']
                    },
                    {
                        name: 'idManageur',
                        column: 'MGRNO',
                        type: { kind: 'string', length: 6 },
                        key: false,
                        required: false,
                        unique: false,
                        searchable: false,
                        sortable: false,
                        filterOperators: ['eq']
                    },
                    {
                        name: 'idServiceAdmin',
                        column: 'ADMRDEPT',
                        type: { kind: 'string', length: 3 },
                        key: false,
                        required: false,
                        unique: false,
                        searchable: false,
                        sortable: false,
                        filterOperators: ['eq']
                    },
                    {
                        name: 'site',
                        column: 'LOCATION',
                        type: { kind: 'string', length: 16 },
                        key: false,
                        required: false,
                        unique: false,
                        searchable: true,
                        sortable: false,
                        filterOperators: ['eq', 'like']
                    }
                ],
                list: {
                    fields: ['id', 'nom', 'idManageur', 'idServiceAdmin', 'site'],
                    searchFields: ['id', 'nom', 'site'],
                    filterFields: [
                        'id',
                        'nom',
                        'idManageur',
                        'idServiceAdmin',
                        'site'
                    ],
                    sortFields: ['id', 'nom'],
                    defaultSort: { field: 'id', order: 'ASC' }
                }
            }
        ]);
    });

    test('reports mapping errors before any generator runs', async () => {
        const model = await parseCMagicString(`
            entity Broken resource "broken" {
                id: Int column "ID" sortable filter(EQ, LIKE),
                label: String(20)
            }
            view list for Broken { id, missing }
            operations for Broken { LIST }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_TABLE_REQUIRED',
            'CATALOG_KEY_REQUIRED',
            'CATALOG_COLUMN_REQUIRED',
            'CATALOG_FILTER_OPERATOR_INVALID',
            'CATALOG_LIST_FIELD_UNKNOWN'
        ]);
    });

    test('keeps id as the canonical public identifier', async () => {
        const model = await parseCMagicString(`
            entity WrongId resource "wrong-ids" table "WRONGID" {
                code: String(10) column "CODE" key required
            }
            operations for WrongId { GET }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_IDENTIFIER_MUST_BE_ID'
        ]);
    });

    test('generates the OpenAPI and frontend contract from the same CatalogSpec', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(path.resolve('examples/service-catalogue.cmagic'), 'utf-8')
        );
        const [service] = buildCatalogSpecs(model).specs;

        const openApi = generateOpenApiDocument(service);
        const resourceContract = generateResourceContract(service);
        const resourceContractSource = generateResourceContractSource(service);

        expect(openApi.paths).toHaveProperty('/api/services');
        expect(openApi.paths).toHaveProperty('/api/services/{id}');
        expect(openApi.paths['/api/services'].get?.parameters).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ name: 'page', in: 'query', required: false }),
                expect.objectContaining({ name: 'perPage', in: 'query', required: false }),
                expect.objectContaining({ name: 'sort', in: 'query', required: false }),
                expect.objectContaining({ name: 'order', in: 'query', required: false }),
                expect.objectContaining({ name: 'q', in: 'query', required: false }),
                expect.objectContaining({
                    name: 'idManageur',
                    in: 'query',
                    required: false,
                    'x-cmagic-operators': ['eq']
                })
            ])
        );
        expect(openApi.components.schemas.Service.required).toEqual(['id', 'nom']);

        expect(resourceContract).toEqual({
            kind: 'entity',
            identifier: 'id',
            fields: ['id', 'nom', 'idManageur', 'idServiceAdmin', 'site'],
            capabilities: ['read'],
            list: {
                filters: [
                    'q',
                    'id',
                    'nom',
                    'idManageur',
                    'idServiceAdmin',
                    'site'
                ],
                sortFields: ['id', 'nom']
            }
        });
        expect(resourceContractSource).toContain(
            'export const servicesResourceContract ='
        );
        expect(resourceContractSource).toContain('as const;');
    });

    test('writes the three deterministic catalogue artifacts', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(path.resolve('examples/service-catalogue.cmagic'), 'utf-8')
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-catalog-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(model, temporaryDirectory);

            expect(artifacts).toEqual({
                spec: path.join(
                    temporaryDirectory,
                    'services',
                    'services.catalog-spec.json'
                ),
                openApi: path.join(
                    temporaryDirectory,
                    'services',
                    'services.openapi.json'
                ),
                resourceContract: path.join(
                    temporaryDirectory,
                    'services',
                    'services.resource-contract.ts'
                )
            });
            expect(JSON.parse(fs.readFileSync(artifacts.spec, 'utf-8'))).toEqual(
                buildCatalogSpecs(model).specs[0]
            );
            expect(fs.readFileSync(artifacts.resourceContract, 'utf-8')).toContain(
                'export const servicesResourceContract ='
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('describes mutation aliases consistently in both generated contracts', async () => {
        const model = await parseCMagicString(`
            entity Mutable resource "mutables" table "MUTABLE" {
                id: Int column "ID" key required
            }
            operations for Mutable { CREATE, UPDATE, DELETE }
        `);
        const [spec] = buildCatalogSpecs(model).specs;

        const openApi = generateOpenApiDocument(spec);
        const resourceContract = generateResourceContract(spec);

        expect(openApi.paths['/api/mutables']).toHaveProperty('post');
        expect(openApi.paths['/api/mutables/{id}']).toHaveProperty('patch');
        expect(openApi.paths['/api/mutables/{id}']).toHaveProperty('delete');
        expect(resourceContract.capabilities).toEqual([
            'create',
            'update',
            'delete'
        ]);
    });
});
