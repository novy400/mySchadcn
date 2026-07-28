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
            'CATALOG_VIEW_FIELD_UNKNOWN'
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

    test('rejects non-text search fields and unknown fields in every view', async () => {
        const model = await parseCMagicString(`
            entity InvalidSearch resource "invalid-search" table "INVALIDS" {
                id: Int column "ID" key required searchable
            }
            view summary for InvalidSearch { id, missing }
            operations for InvalidSearch { GET }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_SEARCH_FIELD_INVALID',
            'CATALOG_VIEW_FIELD_UNKNOWN'
        ]);
    });

    test('rejects catalogue type arguments that cannot produce valid Db2 DDL', async () => {
        const model = await parseCMagicString(`
            enum EmptyStatus {}
            entity InvalidTypes resource "invalid-types" table "INVALID_TYPES" {
                id: Int column "ID" key required,
                zeroLength: String(0) column "ZERO_LENGTH",
                fractionalLength: String(2.5) column "FRACTIONAL_LENGTH",
                excessiveLength: String(32740) column "EXCESSIVE_LENGTH",
                excessivePrecision: Decimal(64, 0) column "EXCESSIVE_PRECISION",
                invalidScale: Decimal(2, 5) column "INVALID_SCALE",
                fractionalDecimal: Decimal(5.5, 2) column "FRACTIONAL_DECIMAL",
                status: EmptyStatus column "STATUS"
            }
            operations for InvalidTypes { GET }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_STRING_LENGTH_INVALID',
            'CATALOG_STRING_LENGTH_INVALID',
            'CATALOG_STRING_LENGTH_INVALID',
            'CATALOG_DECIMAL_SHAPE_INVALID',
            'CATALOG_DECIMAL_SHAPE_INVALID',
            'CATALOG_DECIMAL_SHAPE_INVALID',
            'CATALOG_ENUM_EMPTY'
        ]);
    });

    test('limits free-text search to searchable fields exposed by the list view', async () => {
        const model = await parseCMagicString(`
            entity VisibleSearch resource "visible-search" table "VISIBLE_SEARCH" {
                id: Int column "ID" key required,
                label: String(40) column "LABEL" searchable,
                internalNote: String(80) column "INTERNAL_NOTE" searchable
            }
            view list for VisibleSearch { id, label }
            operations for VisibleSearch { LIST }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.diagnostics).toEqual([]);
        expect(compilation.specs[0].list?.searchFields).toEqual(['label']);
    });

    test('requires the canonical id in every list view', async () => {
        const model = await parseCMagicString(`
            entity MissingListId resource "missing-list-id" table "MISSING_ID" {
                id: Int column "ID" key required,
                label: String(40) column "LABEL"
            }
            view list for MissingListId { label }
            operations for MissingListId { LIST }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_LIST_IDENTIFIER_REQUIRED'
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
                expect.objectContaining({
                    name: 'page',
                    in: 'query',
                    required: false,
                    schema: expect.objectContaining({ minimum: 1 })
                }),
                expect.objectContaining({
                    name: 'perPage',
                    in: 'query',
                    required: false,
                    schema: expect.objectContaining({ minimum: 1 })
                }),
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

    test('writes the ten deterministic catalogue artifacts', async () => {
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
                ),
                rpgRead: path.join(
                    temporaryDirectory,
                    'services',
                    'services.read.sqlrpgle'
                ),
                rpgReadInterface: path.join(
                    temporaryDirectory,
                    'services',
                    'services.read.rpgleinc'
                ),
                ileastic: path.join(
                    temporaryDirectory,
                    'services',
                    'services.ileastic.sqlrpgle'
                ),
                ileasticInterface: path.join(
                    temporaryDirectory,
                    'services',
                    'services.ileastic.rpgleinc'
                ),
                ddl: path.join(
                    temporaryDirectory,
                    'services',
                    'services.ddl.sql'
                ),
                binder: path.join(
                    temporaryDirectory,
                    'services',
                    'services.bnd'
                ),
                rules: path.join(
                    temporaryDirectory,
                    'services',
                    'Rules.mk'
                )
            });
            expect(JSON.parse(fs.readFileSync(artifacts.spec, 'utf-8'))).toEqual(
                buildCatalogSpecs(model).specs[0]
            );
            expect(fs.readFileSync(artifacts.resourceContract, 'utf-8')).toContain(
                'export const servicesResourceContract ='
            );
            expect(fs.readFileSync(artifacts.rpgRead, 'utf-8')).toContain(
                'dcl-proc service_search export;'
            );
            expect(
                fs.readFileSync(artifacts.rpgReadInterface, 'utf-8')
            ).toContain('dcl-pr service_search ind extproc(*dclcase);');
            expect(fs.readFileSync(artifacts.rpgRead, 'utf-8')).toContain(
                'cmagic_computeSqlClauses(lContext : lSupportedFields'
            );
            expect(
                fs.readFileSync(artifacts.ileasticInterface, 'utf-8')
            ).toContain('dcl-pr service_registerRoutes extproc(*dclcase);');
            expect(fs.readFileSync(artifacts.ileastic, 'utf-8')).toContain(
                'dcl-proc service_registerRoutes export;'
            );
            expect(fs.readFileSync(artifacts.ddl, 'utf-8')).toContain(
                'CREATE TABLE DEPARTMENT'
            );
            expect(fs.readFileSync(artifacts.binder, 'utf-8')).toContain(
                "EXPORT SYMBOL('service_getSupportedFields')"
            );
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).toContain(
                'SERVICE.SRVPGM: services.bnd SERVICE.MODULE'
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('rejects mutations that are outside Catalogue v0', async () => {
        const model = await parseCMagicString(`
            entity Mutable resource "mutables" table "MUTABLE" {
                id: Int column "ID" key required
            }
            operations for Mutable { CREATE, UPDATE, DELETE }
        `);
        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_CAPABILITY_UNSUPPORTED'
        ]);
    });
});
