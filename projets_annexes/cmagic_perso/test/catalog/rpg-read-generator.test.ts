import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    generateRpgReadModule,
    type CatalogSpec
} from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue RPG read generator', () => {
    test('delegates LIST query preparation to the shared CMagic procedures', async () => {
        const source = generateRpgReadModule(await compileServiceCatalog());

        expect(source).toContain(
            "ctl-opt nomain\n" +
                "        option(*nodebugio:*srcstmt:*nounref)\n" +
                "        alwnull(*usrctl)\n" +
                "        datfmt(*iso)\n" +
                "        bnddir('QC2LE':'CKOOL');"
        );
        expect(source).toContain('dcl-proc service_search export;');
        expect(source).toContain('dcl-proc service_getSupportedFields export;');
        expect(source).toContain('dcl-proc service_get export;');
        expect(source).not.toContain('_local');
        expect(source).toContain("/include 'services.read.rpgleinc'");
        expect(source).not.toContain(
            'dcl-ds service_item_t qualified template;'
        );
        expect(source).not.toContain(
            'dcl-ds service_detail_t qualified template;'
        );

        expect(source).toContain(
            'service_getSupportedFields(lSupportedFields : lErrors)'
        );
        expect(source).toContain(
            'cmagic_sanitizeContext(lRequestedContext : lSupportedFields'
        );
        expect(source).toContain(
            'cmagic_computeSqlClauses(lContext : lSupportedFields'
        );
        expect(source).toContain("lSelect += ' FROM DEPARTMENT';");
        expect(source).toContain(
            "lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelect)"
        );
        expect(source).toMatch(/exec sql prepare CATALOG_LIST_STATEMENT/i);
        expect(source).toMatch(/exec sql prepare CATALOG_COUNT_STATEMENT/i);

        expect(source).toContain(
            "pSupportedFields.supportedFields(lIt).name = 'id';"
        );
        expect(source).toContain(
            "pSupportedFields.supportedFields(lIt).sqlField = 'DEPTNO';"
        );
        expect(source).toContain(
            "pSupportedFields.supportedFields(lIt).dataType = 'C';"
        );
        expect(source).toContain(
            "lRequestedContext.sort(1).field = 'id';"
        );
        expect(source).toContain(
            "lRequestedContext.sort(1).order = 'ASC';"
        );
        expect(source).not.toContain('lUseIdEq');
        expect(source).not.toContain("when %trim(lFilter.field) = 'id';");

        expect(source).toContain('WHERE DEPTNO = :pId');
    });

    test('publishes catalogue field lengths to the generic sanitizer', async () => {
        const source = generateRpgReadModule(await compileServiceCatalog());

        expect(source).toContain(
            'pSupportedFields.supportedFields(lIt).maxLength = 3;'
        );
        expect(source).not.toContain('dcl-s lFilterIndex int(10);');
        expect(source).not.toContain('Filter value exceeds maximum length');
    });

    test('rejects SQL identifiers that cannot be safely generated', async () => {
        const service = await compileServiceCatalog();
        const unsafeSpec: CatalogSpec = {
            ...service,
            table: 'DEPARTMENT; DROP TABLE EMPLOYEE'
        };

        expect(() => generateRpgReadModule(unsafeSpec)).toThrow(
            'Unsafe SQL identifier'
        );
    });

    test('only exposes operations declared by the catalogue capabilities', async () => {
        const service = await compileServiceCatalog();

        const getOnly = generateRpgReadModule({
            ...service,
            capabilities: ['get'],
            list: undefined
        });
        const listOnly = generateRpgReadModule({
            ...service,
            capabilities: ['list']
        });

        expect(getOnly).not.toContain('dcl-proc service_search export;');
        expect(getOnly).not.toContain(
            'dcl-proc service_getSupportedFields export;'
        );
        expect(getOnly).toContain('dcl-proc service_get export;');
        expect(listOnly).toContain('dcl-proc service_search export;');
        expect(listOnly).toContain(
            'dcl-proc service_getSupportedFields export;'
        );
        expect(listOnly).not.toContain('dcl-proc service_get export;');
        expect(listOnly).not.toMatch(/\n\n$/);
    });

    test('validates CREATE before inserting the natural identifier', async () => {
        const service = await compileServiceCatalog();
        const source = generateRpgReadModule({
            ...service,
            capabilities: [...service.capabilities, 'create']
        });

        expect(source).toContain('dcl-proc service_create export;');
        expect(source).toContain('dcl-proc service_isValid export;');
        expect(source).not.toContain('dcl-pr service_isValid_business ind;');
        expect(source).toContain('dcl-proc service_isValid_business;');
        expect(source).toContain(
            'service_isValid(service_listeAction.creation'
        );
        expect(source).toContain("pErrors.listError(lErrorIndex).nomZone = 'id';");
        expect(source).toContain("pErrors.listError(lErrorIndex).nomZone = 'nom';");
        expect(source).toContain('if not service_isValid_business(');
        expect(source).toContain('// [CMAGIC:MANUAL_START]');
        expect(source).toContain('// [CMAGIC:MANUAL_END]');
        expect(source).toContain('INSERT INTO DEPARTMENT');
        expect(source).toContain('(DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)');
        expect(source).toContain(
            "(:pDetail.id, :pDetail.nom, NULLIF(:pDetail.idManageur, ''), NULLIF(:pDetail.idServiceAdmin, ''), NULLIF(:pDetail.site, ''))"
        );
        expect(source).toContain("when sqlState = '23505';");
        expect(source).toContain("pErrors : 'CAT1002' : 'conflict'");

        expect(source.indexOf('service_isValid(service_listeAction.creation')).toBeLessThan(
            source.indexOf('INSERT INTO DEPARTMENT')
        );
    });

    test('loads and validates UPDATE before changing non-key fields', async () => {
        const service = await compileServiceCatalog();
        const source = generateRpgReadModule({
            ...service,
            capabilities: [...service.capabilities, 'update']
        });

        expect(source).toContain('dcl-proc service_update export;');
        expect(source).toContain(
            'if not service_get(pId : lBeforeDetail : lErrors);'
        );
        expect(source).toContain(
            'service_isValid(service_listeAction.modification'
        );
        expect(source).toContain(
            "pErrors.listError(lErrorIndex).code = 'CAT1005';"
        );
        expect(source).toContain(
            "pErrors.listError(lErrorIndex).nomZone = 'id';"
        );
        expect(source).toContain('UPDATE DEPARTMENT');
        expect(source).toContain('DEPTNAME = :pDetail.nom,');
        expect(source).toContain(
            "MGRNO = NULLIF(:pDetail.idManageur, ''),"
        );
        expect(source).toContain(
            "ADMRDEPT = NULLIF(:pDetail.idServiceAdmin, ''),"
        );
        expect(source).toContain(
            "LOCATION = NULLIF(:pDetail.site, '')"
        );
        expect(source).toContain('WHERE DEPTNO = :pId');
        expect(source).not.toContain('SET DEPTNO =');
        expect(source).toContain("when sqlState = '23505';");
        expect(source).toContain("pErrors : 'CAT1002' : 'conflict'");

        expect(
            source.indexOf('service_get(pId : lBeforeDetail : lErrors)')
        ).toBeLessThan(
            source.indexOf('service_isValid(service_listeAction.modification')
        );
        expect(
            source.indexOf('service_isValid(service_listeAction.modification')
        ).toBeLessThan(source.indexOf('UPDATE DEPARTMENT'));
    });

    test('rejects UPDATE generation without a non-key field', async () => {
        const service = await compileServiceCatalog();

        expect(() =>
            generateRpgReadModule({
                ...service,
                capabilities: ['get', 'update'],
                list: undefined,
                fields: service.fields.filter(field => field.key)
            })
        ).toThrow('Catalog UPDATE capability requires a non-key field');
    });

    test('generates basic Boolean and enum domain validation', async () => {
        const service = await compileServiceCatalog();
        const source = generateRpgReadModule({
            ...service,
            capabilities: ['create'],
            list: undefined,
            fields: [
                ...service.fields,
                {
                    name: 'actif',
                    column: 'ACTIVE',
                    type: { kind: 'boolean' },
                    key: false,
                    required: true,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'statut',
                    column: 'STATUS',
                    type: {
                        kind: 'enum',
                        name: 'ServiceStatus',
                        values: ['OPEN', 'CLOSED']
                    },
                    key: false,
                    required: false,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                }
            ]
        });

        expect(source).toContain(
            "pAfterDetail.actif <> 'Y' and pAfterDetail.actif <> 'N'"
        );
        expect(source).toContain(
            "pAfterDetail.statut <> 'OPEN' and pAfterDetail.statut <> 'CLOSED'"
        );
        expect(source).toContain(".code = 'CAT1004';");
        expect(source).toContain(".nomZone = 'actif';");
        expect(source).toContain(".nomZone = 'statut';");
    });

    test('renders the artifact through a replaceable Handlebars template', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-template-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-read.sqlrpgle.hbs'),
                '{{entityName}}|{{table}}|{{#if hasList}}LIST{{/if}}|{{#if hasGet}}GET{{/if}}\n',
                'utf-8'
            );

            expect(
                generateRpgReadModule(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe('service|DEPARTMENT|LIST|GET\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
