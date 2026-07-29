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
    test('generates the PCML-visible LIST interface', async () => {
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
            "'X-Total-Count: ' + %trim(%char(pTotalCount));"
        );
        expect(source).toContain(
            "'Access-Control-Expose-Headers: X-Total-Count';"
        );
        expect(source).toContain('list_dispose(lItems);');
        expect(source).toContain(
            'httpStatus = HTTPREST_SERVERERROR;'
        );
        expect(source).not.toContain('service_getone_iws');
    });

    test('generates the IWS service program binder', async () => {
        const source = generateCatalogIwsBinder(
            await compileIwsServiceCatalog()
        );

        expect(source).toBe(
            [
                "STRPGMEXP PGMLVL(*CURRENT) SIGNATURE('SERVIWS.0.0.1')",
                "  EXPORT SYMBOL('service_getlist_iws')",
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

    test('renders all IWS files through replaceable templates', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-iws-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.rpgleinc.hbs'),
                '{{itemType}}|{{procedures.getListIws}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.sqlrpgle.hbs'),
                '{{interfaces.read}}|{{procedures.search}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog-iws.bnd.hbs'),
                '{{signature}}|{{export}}\n',
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
            ).toBe('service_item_iws_t|service_getlist_iws\n');
            expect(
                generateCatalogIwsWrapper(service, temporaryDirectory)
            ).toBe('services.read.rpgleinc|service_search\n');
            expect(
                generateCatalogIwsBinder(service, temporaryDirectory)
            ).toBe('SERVIWS.0.0.1|service_getlist_iws\n');
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
