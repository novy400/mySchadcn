import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    generateCatalogDdl,
    generateRpgReadModule,
    type CatalogSpec
} from '../../src/catalog/index.js';
import { compileServiceCatalog } from './test-utils.js';

describe('Catalogue DDL generator', () => {
    test('generates deterministic Db2 DDL from mapped catalogue fields', async () => {
        const source = generateCatalogDdl(await compileServiceCatalog());

        expect(source).toContain('CREATE TABLE DEPARTMENT (');
        expect(source).toContain('DEPTNO VARCHAR(3) NOT NULL');
        expect(source).toContain('DEPTNAME VARCHAR(36) NOT NULL');
        expect(source).toContain('MGRNO VARCHAR(6)');
        expect(source).toContain('ADMRDEPT VARCHAR(3)');
        expect(source).toContain('LOCATION VARCHAR(16)');
        expect(source).toContain('PRIMARY KEY (DEPTNO)');
        expect(source).not.toContain('CREATE OR REPLACE');
        expect(source).not.toMatch(/generated (at|on)|généré le/i);
        expect(source.trimEnd()).toMatch(/\);$/);
    });

    test('rejects unsafe SQL identifiers before rendering', async () => {
        const service = await compileServiceCatalog();

        expect(() =>
            generateCatalogDdl({
                ...service,
                table: 'DEPARTMENT; DROP TABLE EMPLOYEE'
            })
        ).toThrow('Unsafe SQL identifier');
        expect(() =>
            generateCatalogDdl({
                ...service,
                fields: service.fields.map((field, index) =>
                    index === 0
                        ? { ...field, column: 'APP.DEPTNO' }
                        : field
                )
            })
        ).toThrow('Unsafe SQL column identifier');
    });

    test('maps scalar and enum types with their catalogue constraints', () => {
        const spec: CatalogSpec = {
            version: 1,
            entity: 'TypedCatalog',
            resource: 'typed-catalogs',
            table: 'APP.TYPED_CATALOG',
            identifier: 'id',
            capabilities: ['list', 'get'],
            fields: [
                {
                    name: 'id',
                    column: 'ID',
                    type: { kind: 'integer' },
                    key: true,
                    required: true,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'code',
                    column: 'CODE',
                    type: { kind: 'string', length: 10 },
                    key: false,
                    required: true,
                    unique: true,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'amount',
                    column: 'AMOUNT',
                    type: { kind: 'decimal', precision: 9, scale: 2 },
                    key: false,
                    required: false,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'startsOn',
                    column: 'STARTS_ON',
                    type: { kind: 'date' },
                    key: false,
                    required: false,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'enabled',
                    column: 'ENABLED',
                    type: { kind: 'boolean' },
                    key: false,
                    required: false,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                },
                {
                    name: 'status',
                    column: 'STATUS',
                    type: {
                        kind: 'enum',
                        name: 'Status',
                        values: ['ACTIVE', 'INACTIVE']
                    },
                    key: false,
                    required: false,
                    unique: false,
                    searchable: false,
                    sortable: false,
                    filterOperators: []
                }
            ],
            list: {
                fields: [
                    'id',
                    'code',
                    'amount',
                    'startsOn',
                    'enabled',
                    'status'
                ],
                searchFields: [],
                filterFields: [],
                sortFields: [],
                defaultSort: { field: 'id', order: 'ASC' }
            }
        };

        const source = generateCatalogDdl(spec);
        const rpgSource = generateRpgReadModule(spec);

        expect(source).toContain('ID INTEGER NOT NULL');
        expect(source).toContain('CODE VARCHAR(10) NOT NULL');
        expect(source).toContain('AMOUNT DECIMAL(9, 2)');
        expect(source).toContain('STARTS_ON DATE');
        expect(source).toContain('ENABLED CHAR(1)');
        expect(source).toContain('STATUS VARCHAR(8)');
        expect(source).toContain('PRIMARY KEY (ID)');
        expect(source).toContain('UNIQUE (CODE)');
        expect(source).toContain(
            "CHECK (STATUS IN ('ACTIVE', 'INACTIVE'))"
        );
        expect(source).toContain("CHECK (ENABLED IN ('Y', 'N'))");
        expect(rpgSource).toContain('enabled char(1);');
        expect(rpgSource).toMatch(
            /name = 'enabled';[\s\S]*sqlField = 'ENABLED';[\s\S]*dataType = 'C';/
        );
        expect(rpgSource).toContain("COALESCE(ENABLED, '')");
    });

    test('renders through a replaceable Handlebars template', async () => {
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-ddl-template-')
        );

        try {
            fs.writeFileSync(
                path.join(temporaryDirectory, 'catalog.ddl.sql.hbs'),
                '{{entityName}}|{{table}}|{{fields.length}}\n',
                'utf-8'
            );

            expect(
                generateCatalogDdl(
                    await compileServiceCatalog(),
                    temporaryDirectory
                )
            ).toBe('Service|DEPARTMENT|5\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
