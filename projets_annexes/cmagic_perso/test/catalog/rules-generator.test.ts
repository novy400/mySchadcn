import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import { generateCatalogRules } from '../../src/catalog/index.js';
import {
    compileIwsServiceCatalog,
    compileServiceCatalog
} from './test-utils.js';

describe('Catalogue Rules.mk generator', () => {
    test('generates the BOB rules for read and ILEastic modules', async () => {
        const source = generateCatalogRules(await compileServiceCatalog());

        expect(source).toContain('# Service catalogue read module');
        expect(source).toContain(
            'SERVICE.MODULE: services.read.sqlrpgle'
        );
        expect(source).toContain(
            'SERVICE.SRVPGM: services.bnd SERVICE.MODULE'
        );
        expect(source).toContain(
            'SERVREST.MODULE: services.ileastic.sqlrpgle'
        );
        expect(source).not.toContain('IWS.MODULE:');
    });

    test('omits the ILEastic target when no system object is declared', async () => {
        const service = await compileServiceCatalog();
        const source = generateCatalogRules({
            ...service,
            ileasticObject: undefined
        });

        expect(source).toContain('SERVICE.MODULE: services.read.sqlrpgle');
        expect(source).not.toContain('services.ileastic.sqlrpgle');
    });

    test('generates IWS instead of ILEastic when iwsObject is selected', async () => {
        const source = generateCatalogRules(
            await compileIwsServiceCatalog()
        );

        expect(source).toContain(
            'SERVIWS.MODULE: services.iws.sqlrpgle'
        );
        expect(source).toContain(
            'SERVICE.BNDDIR: services.read.bnddir SERVICE.SRVPGM'
        );
        expect(source).toContain(
            'SERVIWS.SRVPGM: services.iws.bnd SERVIWS.MODULE SERVICE.BNDDIR'
        );
        expect(source).toContain(
            'SERVIWS.BNDDIR: services.iws.bnddir SERVIWS.SRVPGM'
        );
        expect(source).not.toContain('CIWS.SRVPGM');
        expect(source).not.toContain('SERVREST.MODULE:');
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
                '{{objectName}}|{{ileasticObjectName}}|{{iwsObjectName}}|{{rpgReadSource}}|{{ileasticSource}}|{{iwsSource}}|{{iwsBinderSource}}|{{iwsReadBindingDirectorySource}}|{{iwsBindingDirectorySource}}|{{binderSource}}\n',
                'utf-8'
            );

            expect(
                generateCatalogRules(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe(
                'SERVICE|SERVREST||services.read.sqlrpgle|services.ileastic.sqlrpgle|services.iws.sqlrpgle|services.iws.bnd|services.read.bnddir|services.iws.bnddir|services.bnd\n'
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
