import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import { buildCatalogSpecs } from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

describe('Fournisseur IWS catalogue', () => {
    test('compiles the new FOURNIS table into the CRM resource contract', async () => {
        const source = fs.readFileSync(
            path.resolve('examples/fournisseur-catalogue-iws.cmagic'),
            'utf-8'
        );
        const compilation = buildCatalogSpecs(
            await parseCMagicString(source)
        );

        expect(compilation.diagnostics).toEqual([]);
        expect(compilation.specs).toEqual([
            expect.objectContaining({
                entity: 'Fournis',
                resource: 'fournisseurs',
                table: 'FOURNIS',
                iwsObject: 'FOURIWS',
                identifier: 'id',
                capabilities: ['list', 'get', 'create', 'update'],
                list: {
                    fields: [
                        'id',
                        'nom',
                        'adresse',
                        'ville',
                        'telephone',
                        'email'
                    ],
                    searchFields: [
                        'id',
                        'nom',
                        'adresse',
                        'ville',
                        'telephone',
                        'email'
                    ],
                    filterFields: ['ville'],
                    sortFields: ['nom'],
                    defaultSort: { field: 'id', order: 'ASC' }
                }
            })
        ]);
    });
});
