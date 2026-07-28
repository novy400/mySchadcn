import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    buildCatalogSpecs,
    generateRpgReadModule,
    type CatalogSpec
} from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

const compileService = async (): Promise<CatalogSpec> => {
    const source = fs.readFileSync(
        path.resolve('examples/service-catalogue.cmagic'),
        'utf-8'
    );
    const compilation = buildCatalogSpecs(await parseCMagicString(source));

    expect(compilation.diagnostics).toEqual([]);
    return compilation.specs[0];
};

describe('Catalogue RPG read generator', () => {
    test('generates LIST and GET with static SQL and bound values', async () => {
        const source = generateRpgReadModule(await compileService());

        expect(source).toContain('dcl-proc service_list export;');
        expect(source).toContain('dcl-proc service_get export;');
        expect(source).not.toContain('_local');
        expect(source).not.toMatch(/\bprepare\b/i);
        expect(source).not.toContain('GLOBAL_QUOTE');

        expect(source).toContain('FROM DEPARTMENT');
        expect(source).toContain("when %trim(lFilter.field) = 'id';");
        expect(source).toContain(
            "when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');"
        );
        expect(source).toContain('DEPTNO = :lIdEq');
        expect(source).toContain('DEPTNO LIKE :lIdLike');
        expect(source).toContain('UPPER(DEPTNO) LIKE UPPER(:lQ)');

        expect(source).toMatch(
            /CASE WHEN :lSortField = 'nom'\s+AND :lSortOrder = 'ASC'/
        );
        expect(source).toContain('OFFSET :lOffset ROWS');
        expect(source).toContain('FETCH NEXT :lPerPage ROWS ONLY');
        expect(source).toContain('WHERE DEPTNO = :pId');
        expect(source).toContain('COUNT(*) OVER()');
        expect(source).toContain('select COUNT(*)');
        expect(source).toContain('into :pTotalCount');
    });

    test('rejects SQL identifiers that cannot be safely generated', async () => {
        const service = await compileService();
        const unsafeSpec: CatalogSpec = {
            ...service,
            table: 'DEPARTMENT; DROP TABLE EMPLOYEE'
        };

        expect(() => generateRpgReadModule(unsafeSpec)).toThrow(
            'Unsafe SQL identifier'
        );
    });

    test('only exposes operations declared by the catalogue capabilities', async () => {
        const service = await compileService();

        const getOnly = generateRpgReadModule({
            ...service,
            capabilities: ['get'],
            list: undefined
        });
        const listOnly = generateRpgReadModule({
            ...service,
            capabilities: ['list']
        });
        const listWithoutSearch = generateRpgReadModule({
            ...service,
            capabilities: ['list'],
            fields: service.fields.map(field => ({ ...field, searchable: false })),
            list: service.list
                ? { ...service.list, searchFields: [] }
                : undefined
        });

        expect(getOnly).not.toContain('dcl-proc service_list export;');
        expect(getOnly).toContain('dcl-proc service_get export;');
        expect(listOnly).toContain('dcl-proc service_list export;');
        expect(listOnly).not.toContain('dcl-proc service_get export;');
        expect(listWithoutSearch).not.toContain(
            "when %trim(lFilter.field) = 'q';"
        );
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
                generateRpgReadModule(await compileService(), temporaryDirectory)
            ).toBe('service|DEPARTMENT|LIST|GET\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
