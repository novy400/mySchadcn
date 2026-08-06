import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import { generateCatalogBinder } from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue binder generator', () => {
    test('exports only the generated read procedures', async () => {
        const source = generateCatalogBinder(await compileServiceCatalog());

        expect(source).toBe(
            [
                "STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('SERVICE.0.0.1')",
                "  EXPORT SYMBOL('service_search')",
                "  EXPORT SYMBOL('service_getSupportedFields')",
                "  EXPORT SYMBOL('service_get')",
                'ENDPGMEXP',
                ''
            ].join('\n')
        );
        expect(source).not.toContain('service_create');
        expect(source).not.toContain('service_update');
        expect(source).not.toContain('service_delete');
    });

    test('derives exports from the declared capabilities', async () => {
        const service = await compileServiceCatalog();

        const listOnly = generateCatalogBinder({
            ...service,
            capabilities: ['list']
        });
        const getOnly = generateCatalogBinder({
            ...service,
            capabilities: ['get']
        });

        expect(listOnly).toContain("EXPORT SYMBOL('service_search')");
        expect(listOnly).toContain(
            "EXPORT SYMBOL('service_getSupportedFields')"
        );
        expect(listOnly).not.toContain("EXPORT SYMBOL('service_get')");
        expect(getOnly).toContain("EXPORT SYMBOL('service_get')");
        expect(getOnly).not.toContain("EXPORT SYMBOL('service_search')");
        expect(getOnly).not.toContain(
            "EXPORT SYMBOL('service_getSupportedFields')"
        );
    });

    test('appends the CREATE API without moving existing exports', async () => {
        const service = await compileServiceCatalog();
        const source = generateCatalogBinder({
            ...service,
            capabilities: [...service.capabilities, 'create']
        });

        expect(source).toBe(
            [
                "STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('SERVICE.0.0.1')",
                "  EXPORT SYMBOL('service_search')",
                "  EXPORT SYMBOL('service_getSupportedFields')",
                "  EXPORT SYMBOL('service_get')",
                "  EXPORT SYMBOL('service_create')",
                "  EXPORT SYMBOL('service_isValid')",
                'ENDPGMEXP',
                ''
            ].join('\n')
        );
    });

    test('rejects entity names that cannot be IBM i object names', async () => {
        const service = await compileServiceCatalog();

        expect(() =>
            generateCatalogBinder({
                ...service,
                entity: 'VeryLongService'
            })
        ).toThrow('Invalid IBM i object name');
    });

    test('renders through a replaceable Handlebars template', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-binder-template-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog.bnd.hbs'),
                '{{signature}}|{{#each exports}}{{this}}{{#unless @last}},{{/unless}}{{/each}}\n',
                'utf-8'
            );

            expect(
                generateCatalogBinder(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe(
                'SERVICE.0.0.1|' +
                    'service_search,service_getSupportedFields,service_get\n'
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
