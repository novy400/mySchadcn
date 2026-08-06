import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    generateCatalogReadInterface,
    generateCatalogTestReadInterface,
    generateRpgReadModule
} from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue RPG read interface generator', () => {
    test('declares the shared read structures and prototypes', async () => {
        const source = generateCatalogReadInterface(
            await compileServiceCatalog()
        );

        expect(source).toContain('/define SERVICE_READ_H_DEFINED');
        expect(source).toContain("/include 'cmagic.rpgleinc'");
        expect(source).toContain("/include 'global.rpgleinc'");
        expect(source).toContain('dcl-ds service_item_t qualified template;');
        expect(source).toContain('  id varchar(3);');
        expect(source).toContain('  nom varchar(36);');
        expect(source).toContain('  idManageur varchar(6);');
        expect(source).not.toContain('  idmanageur varchar(6);');
        expect(source).toContain('dcl-ds service_detail_t qualified template;');
        expect(source).toContain(
            'dcl-pr service_getSupportedFields ind extproc(*dclcase);'
        );
        expect(source).toContain(
            'dcl-pr service_search ind extproc(*dclcase);'
        );
        expect(source).toContain(
            'dcl-pr service_get ind extproc(*dclcase);'
        );
        expect(source).not.toContain('_local');
    });

    test('uses project-root include paths in the test copy', async () => {
        const source = generateCatalogTestReadInterface(
            await compileServiceCatalog()
        );

        expect(source).toContain("/include 'includes/cmagic.rpgleinc'");
        expect(source).toContain("/include 'includes/global.rpgleinc'");
    });

    test('declares only capabilities exposed by the catalogue', async () => {
        const service = await compileServiceCatalog();

        const listOnly = generateCatalogReadInterface({
            ...service,
            capabilities: ['list']
        });
        const getOnly = generateCatalogReadInterface({
            ...service,
            capabilities: ['get'],
            list: undefined
        });

        expect(listOnly).toContain('dcl-pr service_search ind');
        expect(listOnly).toContain('dcl-pr service_getSupportedFields ind');
        expect(listOnly).not.toContain('dcl-pr service_get ind');
        expect(getOnly).toContain('dcl-pr service_get ind');
        expect(getOnly).not.toContain('dcl-pr service_search ind');
        expect(getOnly).not.toContain('dcl-pr service_getSupportedFields ind');
    });

    test('publishes the CREATE validation contract', async () => {
        const service = await compileServiceCatalog();
        const source = generateCatalogReadInterface({
            ...service,
            capabilities: ['create'],
            list: undefined
        });

        expect(source).toContain('dcl-ds service_detail_t qualified template;');
        expect(source).toContain('dcl-enum service_listeAction qualified;');
        expect(source).toContain("  creation 'create';");
        expect(source).toContain(
            'dcl-pr service_isValid ind extproc(*dclcase);'
        );
        expect(source).toContain(
            'dcl-pr service_create ind extproc(*dclcase);'
        );
        expect(source).toContain('  pDetail likeDS(service_detail_t) const;');
        expect(source).toContain('  pId varchar(3);');
        expect(source).not.toContain('dcl-pr service_get ind');
    });

    test('publishes the UPDATE validation contract', async () => {
        const service = await compileServiceCatalog();
        const source = generateCatalogReadInterface({
            ...service,
            capabilities: ['get', 'update'],
            list: undefined
        });

        expect(source).toContain('dcl-ds service_detail_t qualified template;');
        expect(source).toContain('dcl-enum service_listeAction qualified;');
        expect(source).toContain("  modification 'update';");
        expect(source).toContain(
            'dcl-pr service_isValid ind extproc(*dclcase);'
        );
        expect(source).toContain(
            'dcl-pr service_update ind extproc(*dclcase);'
        );
        expect(source).toContain('  pId varchar(3) const;');
        expect(source).toContain('  pDetail likeDS(service_detail_t) const;');
    });

    test('keeps public prototypes aligned with implementation interfaces', async () => {
        const service = await compileServiceCatalog();
        const publicInterface = generateCatalogReadInterface(service);
        const implementation = generateRpgReadModule(service);

        for (const procedure of [
            'service_getSupportedFields',
            'service_search',
            'service_get'
        ]) {
            const prototypeParameters = publicInterface.match(
                new RegExp(
                    `dcl-pr ${procedure}\\s+[^;]*;\\n([\\s\\S]*?)end-pr;`
                )
            )?.[1];
            const implementationParameters = implementation.match(
                new RegExp(
                    `dcl-proc ${procedure} export;\\n` +
                        `  dcl-pi \\*n [^;]*;\\n([\\s\\S]*?)  end-pi;`
                )
            )?.[1];

            expect(implementationParameters?.replace(/^  /gm, '')).toBe(
                prototypeParameters
            );
        }
    });

    test('renders through a replaceable Handlebars template', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-read-interface-')
        );

        try {
            fs.writeFileSync(
                path.join(
                    temporaryDirectory,
                    'catalog-read.rpgleinc.hbs'
                ),
                '{{entityName}}|{{readInterfaceSource}}|{{#if hasList}}LIST{{/if}}|{{#if hasGet}}GET{{/if}}\n',
                'utf-8'
            );

            expect(
                generateCatalogReadInterface(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe('service|services.read.rpgleinc|LIST|GET\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
