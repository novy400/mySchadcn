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
