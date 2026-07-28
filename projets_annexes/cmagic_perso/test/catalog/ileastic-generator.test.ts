import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    generateCatalogIleasticInterface,
    generateCatalogIleasticWrapper
} from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue ILEastic generator', () => {
    test('generates the public route registration interface', async () => {
        const source = generateCatalogIleasticInterface(
            await compileServiceCatalog()
        );

        expect(source).toContain('/define SERVICE_ILEASTIC_H_DEFINED');
        expect(source).toContain("/include 'ileastic/ileastic.rpgle'");
        expect(source).toContain(
            'dcl-pr service_registerRoutes extproc(*dclcase);'
        );
        expect(source).toContain('  config likeDS(IL_config);');
        expect(source).not.toContain('service_getlist_rest');
        expect(source).not.toContain('service_getone_rest');
    });

    test('publishes LIST and GET through the generated read interface', async () => {
        const source = generateCatalogIleasticWrapper(
            await compileServiceCatalog()
        );

        expect(source).toContain("/include 'services.read.rpgleinc'");
        expect(source).toContain("/include 'services.ileastic.rpgleinc'");
        expect(source).toContain('dcl-proc service_getlist_rest;');
        expect(source).toContain(
            'if not service_getSupportedFields(lSupportedFields : lErrors);'
        );
        expect(source).toContain(
            'if not CREST_initRestRequest(request : lSupportedFields'
        );
        expect(source).toContain(
            'if not service_search(lContext : lTotalCount : lItems : lErrors);'
        );
        expect(source).toContain(
            "if lErrors.listError(1).nomZone = 'sql';"
        );
        expect(source).toContain(
            'response.status = IL_HTTP_INTERNAL_SERVER_ERROR;'
        );
        expect(source).toContain(
            'dcl-ds lItem likeDS(service_item_t) based(lItemPointer);'
        );
        expect(source).toContain(
            "il_responseWrite(response : %ucs2('{\"data\":'));"
        );
        expect(source).toContain(
            "il_responseWrite(response : %ucs2(',\"total\":'));"
        );

        expect(source).toContain('dcl-proc service_getone_rest;');
        expect(source).toContain(
            "cId = il_getPathParameter(request : 'id' : '');"
        );
        expect(source).toContain('if not service_parseId(cId : lId);');
        expect(source).toContain(
            'if not service_get(lId : lDetail : lErrors);'
        );
        expect(source).toContain(
            'data-gen lDetail %data(lHandle : \'\') %gen(json_DataGen(lJson));'
        );

        expect(source).toContain('dcl-proc service_registerRoutes export;');
        expect(source).toContain(
            ": IL_GET : '^/api/services/?$');"
        );
        expect(source).toContain(
            ": IL_GET : '^/api/services/{id}$');"
        );
        expect(source).not.toContain('IL_POST');
        expect(source).not.toContain('IL_PUT');
        expect(source).not.toContain('IL_DELETE');
        expect(source).not.toContain('_local');
    });

    test('emits only routes backed by declared capabilities', async () => {
        const service = await compileServiceCatalog();
        const listOnly = generateCatalogIleasticWrapper({
            ...service,
            capabilities: ['list']
        });
        const getOnly = generateCatalogIleasticWrapper({
            ...service,
            capabilities: ['get'],
            list: undefined
        });

        expect(listOnly).toContain('dcl-proc service_getlist_rest;');
        expect(listOnly).not.toContain('dcl-proc service_getone_rest;');
        expect(listOnly).toContain("'^/api/services/?$'");
        expect(listOnly).not.toContain("'^/api/services/{id}$'");

        expect(getOnly).not.toContain('dcl-proc service_getlist_rest;');
        expect(getOnly).toContain('dcl-proc service_getone_rest;');
        expect(getOnly).not.toContain("'^/api/services/?$'");
        expect(getOnly).toContain("'^/api/services/{id}$'");
    });

    test('keeps route registration aligned and parses typed identifiers', async () => {
        const service = await compileServiceCatalog();
        const publicInterface = generateCatalogIleasticInterface(service);
        const wrapper = generateCatalogIleasticWrapper(service);
        const registration = publicInterface.match(
            /dcl-pr ([A-Za-z0-9_]+) extproc/
        )?.[1];

        expect(registration).toBe('service_registerRoutes');
        expect(wrapper).toContain(`dcl-proc ${registration} export;`);
        const prototypeParameters = publicInterface.match(
            /dcl-pr service_registerRoutes[^;]*;\n([\s\S]*?)end-pr;/
        )?.[1];
        const implementationParameters = wrapper.match(
            /dcl-proc service_registerRoutes export;\n\s+dcl-pi \*n;\n([\s\S]*?)\s+end-pi;/
        )?.[1];

        expect(prototypeParameters).toBeDefined();
        expect(implementationParameters).toBeDefined();
        expect(
            implementationParameters?.replace(/^  /gm, '').trimEnd()
        ).toBe(
            prototypeParameters?.trimEnd()
        );
        expect(wrapper).toContain('if %len(pValue) > 3;');

        const sourceForIdType = (
            type: (typeof service.fields)[number]['type']
        ): string =>
            generateCatalogIleasticWrapper({
                ...service,
                fields: service.fields.map(field =>
                    field.name === service.identifier
                        ? { ...field, type }
                        : field
                )
            });

        expect(sourceForIdType({ kind: 'integer' })).toContain(
            'pId = %dec(pValue : 20 : 0);'
        );
        expect(
            sourceForIdType({
                kind: 'decimal',
                precision: 9,
                scale: 2
            })
        ).toContain('pId = %dec(pValue : 9 : 2);');
        expect(sourceForIdType({ kind: 'date' })).toContain(
            'pId = %date(pValue : *iso);'
        );
        const booleanSource = sourceForIdType({ kind: 'boolean' });
        expect(booleanSource).toContain(
            "when %lower(%trim(pValue)) = 'true';"
        );
        expect(booleanSource).toContain(
            "json_setBool(lItemJson : 'id' : lItem.id = 'Y');"
        );
        expect(booleanSource).toContain(
            "json_setBool(lJson : 'id' : lDetail.id = 'Y');"
        );
        expect(
            sourceForIdType({
                kind: 'enum',
                name: 'Status',
                values: ['ACTIVE', 'INACTIVE']
            })
        ).toContain(
            "when pValue = 'ACTIVE';"
        );
    });

    test('renders both files through replaceable Handlebars templates', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-ileastic-')
        );

        try {
            fs.writeFileSync(
                path.join(
                    temporaryDirectory,
                    'catalog-ileastic.rpgleinc.hbs'
                ),
                '{{entityName}}|{{interfaces.ileastic}}|{{procedures.registerRoutes}}\n',
                'utf-8'
            );
            fs.writeFileSync(
                path.join(
                    temporaryDirectory,
                    'catalog-ileastic.sqlrpgle.hbs'
                ),
                '{{resource}}|{{interfaces.read}}|{{procedures.search}}|{{#if hasList}}LIST{{/if}}|{{#if hasGet}}GET{{/if}}\n',
                'utf-8'
            );
            const service = await compileServiceCatalog();

            expect(
                generateCatalogIleasticInterface(service, temporaryDirectory)
            ).toBe(
                'service|services.ileastic.rpgleinc|service_registerRoutes\n'
            );
            expect(
                generateCatalogIleasticWrapper(service, temporaryDirectory)
            ).toBe(
                'services|services.read.rpgleinc|service_search|LIST|GET\n'
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
