import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import { generateCatalogRules } from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue Rules.mk generator', () => {
    test('generates the BOB rule for the catalog read module', async () => {
        const source = generateCatalogRules(await compileServiceCatalog());

        expect(source).toContain('# Service catalogue read module');
        expect(source).toContain(
            'SERVICE.MODULE: services.read.sqlrpgle'
        );
        expect(source).not.toContain('.SRVPGM:');
        expect(source).not.toContain('REST.MODULE:');
        expect(source).not.toContain('IWS.MODULE:');
    });

    test('rejects entity names that cannot be IBM i object names', async () => {
        const service = await compileServiceCatalog();

        expect(() =>
            generateCatalogRules({
                ...service,
                entity: 'VeryLongService'
            })
        ).toThrow('Invalid IBM i object name');
    });

    test('renders through a replaceable Handlebars template', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-rules-template-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog.Rules.mk.hbs'),
                '{{objectName}}|{{rpgReadSource}}\n',
                'utf-8'
            );

            expect(
                generateCatalogRules(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe('SERVICE|services.read.sqlrpgle\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
