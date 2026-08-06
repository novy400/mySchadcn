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
                ileasticObject: 'SERVREST',
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

    test('validates explicit ILEastic IBM i object names', async () => {
        const model = await parseCMagicString(`
            entity BadRest resource "bad-rest" table "BADREST"
                ileasticObject "TOO-LONG-NAME" {
                id: Int column "ID" key required
            }
            operations for BadRest { GET }

            entity Collision resource "collisions" table "COLLISION"
                ileasticObject "COLLISION" {
                id: Int column "ID" key required
            }
            operations for Collision { GET }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_ILEASTIC_OBJECT_INVALID',
            'CATALOG_ILEASTIC_OBJECT_COLLISION'
        ]);
    });

    test('compiles IWS as an alternative transport for LIST and GET', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );

        const compilation = buildCatalogSpecs(model);

        expect(compilation.diagnostics).toEqual([]);
        expect(compilation.specs[0]).toEqual(
            expect.objectContaining({
                entity: 'Service',
                iwsObject: 'SERVIWS',
                capabilities: ['list', 'get']
            })
        );
        expect(compilation.specs[0]).not.toHaveProperty('ileasticObject');
    });

    test('validates the exclusive IWS transport choice', async () => {
        const model = await parseCMagicString(`
            entity BadIws resource "bad-iws" table "BADIWS"
                iwsObject "TOO-LONG-NAME" {
                id: Int column "ID" key required
            }
            view list for BadIws { id }
            operations for BadIws { LIST }

            entity Collision resource "collisions" table "COLLISION"
                iwsObject "COLLISION" {
                id: Int column "ID" key required
            }
            view list for Collision { id }
            operations for Collision { LIST }

            entity Both resource "both" table "BOTH"
                ileasticObject "BOTHREST" iwsObject "BOTHIWS" {
                id: Int column "ID" key required
            }
            view list for Both { id }
            operations for Both { LIST }

            entity NoList resource "no-list" table "NOLIST"
                iwsObject "NOLISTIWS" {
                id: Int column "ID" key required
            }
            operations for NoList { GET }
        `);

        const compilation = buildCatalogSpecs(model);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_IWS_OBJECT_INVALID',
            'CATALOG_IWS_OBJECT_COLLISION',
            'CATALOG_TRANSPORT_AMBIGUOUS',
            'CATALOG_IWS_LIST_REQUIRED'
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

    test('writes the thirteen deterministic catalogue artifacts', async () => {
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
                rpgTestReadInterface: path.join(
                    temporaryDirectory,
                    'includes',
                    'services.read.rpgleinc'
                ),
                rpgReadTest: path.join(
                    temporaryDirectory,
                    'services',
                    'service.test.sqlrpgle'
                ),
                testing: path.join(
                    temporaryDirectory,
                    'services',
                    'testing.json'
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
                fs.readFileSync(artifacts.ileasticInterface as string, 'utf-8')
            ).toContain('dcl-pr service_registerRoutes extproc(*dclcase);');
            expect(fs.readFileSync(artifacts.ileastic as string, 'utf-8')).toContain(
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
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).toContain(
                'SERVREST.MODULE: services.ileastic.sqlrpgle'
            );
            expect(
                JSON.parse(fs.readFileSync(artifacts.testing, 'utf-8'))
                    .codecov.module
            ).toEqual(['SERVICE']);
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('generates a data-free RPGUnit envelope for the read service', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-read-test-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );

            expect(artifacts.rpgReadTest).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'service.test.sqlrpgle'
                )
            );
            const source = fs.readFileSync(
                artifacts.rpgReadTest as string,
                'utf-8'
            );
            expect(source).toContain(
                "bnddir('QC2LE':'SERVICE':'CKOOL')"
            );
            expect(source).toContain('/include qinclude,TESTCASE');
            expect(source).toContain(
                "/include 'includes/services.read.rpgleinc'"
            );
            expect(source).toContain('dcl-proc setUpSuite export;');
            expect(source).toContain('// [CMAGIC:MANUAL_START]');
            expect(source).toContain('// [CMAGIC:MANUAL_END]');
            expect(source).not.toContain('A00');
            expect(source).not.toContain('DB2SAMPLE');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('adds the IWS runtime artifacts when iwsObject is selected', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-catalog-iws-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );

            expect(artifacts.iws).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'services.iws.sqlrpgle'
                )
            );
            expect(artifacts.iwsInterface).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'services.iws.rpgleinc'
                )
            );
            expect(artifacts.iwsBinder).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'services.iws.bnd'
                )
            );
            expect(artifacts.iwsBindingDirectory).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'services.iws.bnddir'
                )
            );
            expect(artifacts.iwsReadBindingDirectory).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'services.read.bnddir'
                )
            );
            expect(fs.readFileSync(artifacts.iws as string, 'utf-8')).toContain(
                'dcl-proc service_getlist_iws export;'
            );
            expect(fs.readFileSync(artifacts.iws as string, 'utf-8')).toContain(
                'dcl-proc service_getone_iws export;'
            );
            expect(
                fs.readFileSync(artifacts.iwsInterface as string, 'utf-8')
            ).toContain('dcl-pr service_getlist_iws extproc(*dclcase);');
            expect(
                fs.readFileSync(artifacts.iwsInterface as string, 'utf-8')
            ).toContain('dcl-pr service_getone_iws extproc(*dclcase);');
            expect(
                fs.readFileSync(artifacts.iwsBinder as string, 'utf-8')
            ).toContain("EXPORT SYMBOL('service_getlist_iws')");
            expect(
                fs.readFileSync(artifacts.iwsBinder as string, 'utf-8')
            ).toContain("EXPORT SYMBOL('service_getone_iws')");
            expect(
                fs.readFileSync(
                    artifacts.iwsReadBindingDirectory as string,
                    'utf-8'
                )
            ).toContain('OBJ((*LIBL/SERVICE *SRVPGM))');
            expect(
                fs.readFileSync(
                    artifacts.iwsBindingDirectory as string,
                    'utf-8'
                )
            ).toContain('OBJ((*LIBL/SERVICE *SRVPGM))');
            expect(
                fs.readFileSync(
                    artifacts.iwsBindingDirectory as string,
                    'utf-8'
                )
            ).toContain('OBJ((*LIBL/SERVIWS *SRVPGM))');
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).toContain(
                'SERVIWS.SRVPGM: services.iws.bnd SERVIWS.MODULE SERVICE.BNDDIR'
            );
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).toContain(
                'SERVICE.BNDDIR: services.read.bnddir SERVICE.SRVPGM'
            );
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).toContain(
                'SERVIWS.BNDDIR: services.iws.bnddir SERVIWS.SRVPGM'
            );
            expect(fs.readFileSync(artifacts.rules, 'utf-8')).not.toContain(
                'SERVREST.MODULE:'
            );
            expect(artifacts.ileastic).toBeDefined();
            expect(artifacts.ileasticInterface).toBeDefined();
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('generates the data-free RPGUnit IWS envelope and its test include', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-iws-test-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );

            expect(artifacts.iwsTest).toBe(
                path.join(
                    temporaryDirectory,
                    'services',
                    'serviws.test.sqlrpgle'
                )
            );
            expect(artifacts.iwsTestInterface).toBe(
                path.join(
                    temporaryDirectory,
                    'includes',
                    'services.iws.rpgleinc'
                )
            );

            const source = fs.readFileSync(
                artifacts.iwsTest as string,
                'utf-8'
            );
            expect(source).toContain(
                "bnddir('QC2LE':'SERVICE':'CKOOL':'NOXDB')"
            );
            expect(source).toContain(
                "/include 'includes/services.iws.rpgleinc'"
            );
            expect(source).toContain(
                "/include 'includes/services.read.rpgleinc'"
            );
            expect(source).toContain('dcl-proc setQueryString;');
            expect(source).toContain('dcl-proc clearQueryString;');
            expect(source).toContain('// [CMAGIC:MANUAL_START]');
            expect(source).not.toContain('A00');
            expect(source).not.toContain('DB2SAMPLE');

            const testInterface = fs.readFileSync(
                artifacts.iwsTestInterface as string,
                'utf-8'
            );
            expect(testInterface).toContain(
                "/include 'includes/httpRest.rpgleinc'"
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('generates RPGUnit link and coverage configuration for IWS tests', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-testing-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );

            expect({
                path: artifacts.testing,
                configuration: JSON.parse(
                    fs.readFileSync(artifacts.testing, 'utf-8')
                )
            }).toEqual({
                path: path.join(
                    temporaryDirectory,
                    'services',
                    'testing.json'
                ),
                configuration: {
                    rpgunit: {
                        rucrtrpg: {
                            tgtCcsid: '*JOB',
                            dbgView: '*SOURCE',
                            rpgPpOpt: '*LVL2',
                            cOption: ['*EVENTF'],
                            bndSrvPgm: ['SERVIWS']
                        }
                    },
                    codecov: {
                        module: ['SERVICE', 'SERVIWS']
                    }
                }
            });
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('preserves local RPGUnit options while adding generated coverage modules', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-testing-merge-')
        );
        const resourceDirectory = path.join(temporaryDirectory, 'services');
        const testingPath = path.join(resourceDirectory, 'testing.json');

        try {
            fs.mkdirSync(resourceDirectory, { recursive: true });
            fs.writeFileSync(
                testingPath,
                JSON.stringify({
                    rpgunit: {
                        rucrtrpg: {
                            dbgView: '*LIST',
                            incDir: ['custom/includes'],
                            bndSrvPgm: ['CUSTOMSRV']
                        },
                        rucalltst: {
                            detail: '*ALL'
                        }
                    },
                    codecov: {
                        module: ['CUSTOM'],
                        text: 'project coverage'
                    },
                    project: {
                        owner: 'developer'
                    }
                }),
                'utf-8'
            );

            generateCatalogArtifacts(model, temporaryDirectory);

            expect(JSON.parse(fs.readFileSync(testingPath, 'utf-8'))).toEqual({
                rpgunit: {
                    rucrtrpg: {
                        tgtCcsid: '*JOB',
                        dbgView: '*LIST',
                        rpgPpOpt: '*LVL2',
                        cOption: ['*EVENTF'],
                        incDir: ['custom/includes'],
                        bndSrvPgm: ['CUSTOMSRV', 'SERVIWS']
                    },
                    rucalltst: {
                        detail: '*ALL'
                    }
                },
                codecov: {
                    module: ['CUSTOM', 'SERVICE', 'SERVIWS'],
                    text: 'project coverage'
                },
                project: {
                    owner: 'developer'
                }
            });
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('preserves developer-owned RPGUnit cases when both envelopes are regenerated', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-test-preserve-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );
            const manualCase = `
dcl-proc test_project_case export;
    dcl-pi *N;
    end-pi;
    assert(*on : 'project-specific case');
end-proc;
`;
            const testPaths = [
                artifacts.rpgReadTest,
                artifacts.iwsTest as string
            ];

            for (const testPath of testPaths) {
                const generated = fs.readFileSync(testPath, 'utf-8');
                fs.writeFileSync(
                    testPath,
                    generated.replace(
                        '// [CMAGIC:MANUAL_START]\n// [CMAGIC:MANUAL_END]',
                        `// [CMAGIC:MANUAL_START]${manualCase}// [CMAGIC:MANUAL_END]`
                    ),
                    'utf-8'
                );
            }

            generateCatalogArtifacts(model, temporaryDirectory);

            expect(
                testPaths.map(testPath =>
                    fs.readFileSync(testPath, 'utf-8').includes(manualCase)
                )
            ).toEqual([true, true]);
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('does not overwrite existing RPGUnit files that predate manual markers', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-test-legacy-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );
            const legacyReadTest = '**free\n// Existing project read tests\n';
            const legacyIwsTest = '**free\n// Existing project IWS tests\n';
            fs.writeFileSync(artifacts.rpgReadTest, legacyReadTest, 'utf-8');
            fs.writeFileSync(
                artifacts.iwsTest as string,
                legacyIwsTest,
                'utf-8'
            );

            generateCatalogArtifacts(model, temporaryDirectory);

            expect([
                fs.readFileSync(artifacts.rpgReadTest, 'utf-8'),
                fs.readFileSync(artifacts.iwsTest as string, 'utf-8')
            ]).toEqual([legacyReadTest, legacyIwsTest]);
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('keeps the source read interface unchanged and writes a test include copy', async () => {
        const model = await parseCMagicString(
            fs.readFileSync(
                path.resolve('examples/service-catalogue-iws.cmagic'),
                'utf-8'
            )
        );
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-catalog-test-')
        );

        try {
            const [artifacts] = generateCatalogArtifacts(
                model,
                temporaryDirectory
            );
            const testInterface = artifacts.rpgTestReadInterface;

            expect(testInterface).toBe(
                path.join(
                    temporaryDirectory,
                    'includes',
                    'services.read.rpgleinc'
                )
            );
            expect(
                fs.readFileSync(artifacts.rpgReadInterface, 'utf-8')
            ).toContain("/include 'cmagic.rpgleinc'");
            expect(
                fs.readFileSync(artifacts.rpgReadInterface, 'utf-8')
            ).not.toContain("/include 'includes/cmagic.rpgleinc'");
            expect(testInterface).toBeDefined();
            expect(fs.readFileSync(testInterface as string, 'utf-8')).toContain(
                "/include 'includes/cmagic.rpgleinc'"
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
