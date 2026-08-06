import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    generateCatalogIwsBindingDirectory,
    generateCatalogIwsBinder,
    generateCatalogIwsInterface,
    generateCatalogIwsWrapper
} from '../../src/catalog/index.js';
import { compileIwsServiceCatalog } from './test-utils.js';

describe('Catalogue IWS generator', () => {
    test('generates the PCML-visible LIST and GET interfaces', async () => {
        const source = generateCatalogIwsInterface(
            await compileIwsServiceCatalog()
        );

        expect(source).toContain('/define SERVICE_IWS_H_DEFINED');
        expect(source).toContain(
            'dcl-ds service_item_iws_t qualified template;'
        );
        expect(source).toContain('  id varchar(3);');
        expect(source).toContain('  nom varchar(36);');
        expect(source).toContain(
            'dcl-pr service_getlist_iws extproc(*dclcase);'
        );
        expect(source).toContain(
            'items likeDS(service_item_iws_t) dim(HTTPREST_MAX_ITEMS);'
        );
        expect(source).toContain(
            'httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);'
        );
        expect(source).toContain(
            'dcl-ds service_detail_iws_t qualified template;'
        );
        expect(source).toContain(
            'dcl-pr service_getone_iws extproc(*dclcase);'
        );
        expect(source).toContain('  id varchar(3) const;');
        expect(source).toContain(
            'item likeDS(service_detail_iws_t);'
        );
    });

    test('adapts QUERY_STRING to service_search through CIWS', async () => {
        const source = generateCatalogIwsWrapper(
            await compileIwsServiceCatalog()
        );

        expect(source).toContain('pgminfo(*pcml:*module:*dclcase)');
        expect(source).toContain("/include 'services.read.rpgleinc'");
        expect(source).toContain("/include 'services.iws.rpgleinc'");
        expect(source).toContain('dcl-proc service_getlist_iws export;');
        expect(source).toContain(
            'if not service_getSupportedFields('
        );
        expect(source).toContain(
            'if not CIWS_initRestRequest('
        );
        expect(source).toContain(
            'if not service_search('
        );
        expect(source).toContain(
            'eval-corr pItems(pItemsLength) = lSource;'
        );
        expect(source).toContain(
            'errors_LENGTH = CIWS_setErrors(lErrors : errors);'
        );
        expect(source).toContain(
            'CIWS_addCollectionHeaders(totalCount : httpHeaders);'
        );
        expect(source).not.toContain('dcl-proc service_copyIwsErrors;');
        expect(source).not.toContain(
            'dcl-proc service_addIwsCollectionHeaders;'
        );
        expect(source).toContain('list_dispose(lItems);');
        expect(source).toContain(
            'httpStatus = HTTPREST_SERVERERROR;'
        );
        expect(source).toContain('dcl-proc service_getone_iws export;');
        const getOneSource = source.slice(
            source.indexOf('dcl-proc service_getone_iws export;')
        );
        expect(getOneSource).toContain(
            'if not service_get(id : lDetail : lErrors);'
        );
        expect(getOneSource).toContain(
            "if lErrors.listError(1).nomZone = 'id';"
        );
        expect(getOneSource).toContain('httpStatus = HTTPREST_NOTFOUND;');
        expect(getOneSource).toContain(
            [
                '    else;',
                '      httpStatus = HTTPREST_SERVERERROR;',
                '    endif;'
            ].join('\n')
        );
        expect(getOneSource).toContain('eval-corr item = lDetail;');
        expect(getOneSource).toContain(
            "errors(1).nomZone = 'service_getone_iws';"
        );
        expect(getOneSource).toContain("errors(1).code = 'RNX9001';");
        expect(getOneSource).toContain(
            "'Unexpected error in service_getone_iws';"
        );
    });

    test('generates the IWS service program binder', async () => {
        const source = generateCatalogIwsBinder(
            await compileIwsServiceCatalog()
        );

        expect(source).toBe(
            [
                "STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('SERVIWS.0.0.1')",
                "  EXPORT SYMBOL('service_getlist_iws')",
                "  EXPORT SYMBOL('service_getone_iws')",
                'ENDPGMEXP',
                ''
            ].join('\n')
        );
    });

    test('generates a self-contained application binding directory', async () => {
        const source = generateCatalogIwsBindingDirectory(
            await compileIwsServiceCatalog()
        );

        expect(source).toContain('CRTBNDDIR BNDDIR(&O/&N)');
        expect(source).toContain(
            'OBJ((*LIBL/SERVICE *SRVPGM))'
        );
        expect(source).toContain(
            'OBJ((*LIBL/CIWS *SRVPGM))'
        );
        expect(source).not.toContain('SERVIWS');
    });

    test('keeps the published LIST-only interface unchanged without GET', async () => {
        const service = await compileIwsServiceCatalog();
        const listOnlyService = {
            ...service,
            capabilities: service.capabilities.filter(
                capability => capability !== 'get'
            )
        };

        expect(generateCatalogIwsInterface(listOnlyService)).not.toContain(
            'service_getone_iws'
        );
        expect(generateCatalogIwsWrapper(listOnlyService)).not.toContain(
            'service_getone_iws'
        );
        expect(generateCatalogIwsBinder(listOnlyService)).toBe(
            [
                "STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('SERVIWS.0.0.1')",
                "  EXPORT SYMBOL('service_getlist_iws')",
                'ENDPGMEXP',
                ''
            ].join('\n')
        );
    });

    test('renders all IWS files through replaceable templates', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-iws-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.rpgleinc.hbs'),
                '{{itemType}}|{{detailType}}|{{procedures.getListIws}}|{{procedures.getOneIws}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.sqlrpgle.hbs'),
                '{{interfaces.read}}|{{procedures.search}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.bnd.hbs'),
                '{{signature}}|{{#each exports}}{{this}}{{#unless @last}},{{/unless}}{{/each}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.bnddir.hbs'),
                '{{readObjectName}}|{{runtimeObjectName}}\n',
                'utf-8'
            );
            const service = await compileIwsServiceCatalog();

            expect(
                generateCatalogIwsInterface(service, temporaryDirectory)
            ).toBe(
                'service_item_iws_t|service_detail_iws_t|service_getlist_iws|service_getone_iws\n'
            );
            expect(
                generateCatalogIwsWrapper(service, temporaryDirectory)
            ).toBe('services.read.rpgleinc|service_search\n');
            expect(
                generateCatalogIwsBinder(service, temporaryDirectory)
            ).toBe(
                'SERVIWS.0.0.1|service_getlist_iws,service_getone_iws\n'
            );
            expect(
                generateCatalogIwsBindingDirectory(
                    service,
                    temporaryDirectory
                )
            ).toBe('SERVICE|CIWS\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
