import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, test } from 'vitest';
import {
    buildCatalogServerSpecs,
    buildCatalogSpecs,
    generateCatalogProjectArtifacts,
    generateCatalogProjectRules,
    generateCatalogServerMain,
    generateCatalogServerRules
} from '../../src/catalog/index.js';
import { parseCMagicString } from '../generating/test-utils.js';

const compileServerFixture = async () => {
    const model = await parseCMagicString(
        fs.readFileSync(
            path.resolve('examples/service-catalogue.cmagic'),
            'utf-8'
        )
    );
    const catalogs = buildCatalogSpecs(model);

    expect(catalogs.diagnostics).toEqual([]);
    return {
        model,
        compilation: buildCatalogServerSpecs(model, catalogs.specs)
    };
};

describe('Catalogue ILEastic server generator', () => {
    test('compiles an aggregate server from catalogue references', async () => {
        const { compilation } = await compileServerFixture();

        expect(compilation.diagnostics).toEqual([]);
        expect(compilation.specs).toEqual([
            {
                version: 1,
                name: 'ServiceApi',
                object: 'SERVAPI',
                port: 44000,
                host: '*ANY',
                catalogs: [
                    {
                        entity: 'Service',
                        resource: 'services',
                        readObject: 'SERVICE',
                        ileasticObject: 'SERVREST'
                    }
                ]
            }
        ]);
    });

    test('validates server object names, ports, contents and dependencies', async () => {
        const model = await parseCMagicString(`
            entity Service resource "services" table "DEPARTMENT"
                ileasticObject "SERVREST" {
                id: String(3) column "DEPTNO" key required
            }
            operations for Service { GET }

            entity Employee resource "employees" table "EMPLOYEE" {
                id: String(6) column "EMPNO" key required
            }
            operations for Employee { GET }

            server BadName object "TOO-LONG-NAME" port 44000 { Service }
            server BadPort object "BADPORT" port 0 { Service }
            server Empty object "EMPTYAPI" port 44000 {}
            server MissingRest object "EMPAPI" port 44000 { Employee }
            server Duplicate object "DUPAPI" port 44000 {
                Service, Service
            }
            server Collision object "SERVREST" port 44000 { Service }
        `);
        const catalogs = buildCatalogSpecs(model);

        const compilation = buildCatalogServerSpecs(model, catalogs.specs);

        expect(compilation.specs).toEqual([]);
        expect(compilation.diagnostics.map(diagnostic => diagnostic.code)).toEqual([
            'CATALOG_SERVER_OBJECT_INVALID',
            'CATALOG_SERVER_PORT_INVALID',
            'CATALOG_SERVER_EMPTY',
            'CATALOG_SERVER_ILEASTIC_OBJECT_REQUIRED',
            'CATALOG_SERVER_CATALOG_DUPLICATE',
            'CATALOG_SERVER_OBJECT_COLLISION'
        ]);
    });

    test('aggregates several catalogues in one server program', async () => {
        const model = await parseCMagicString(`
            entity Service resource "services" table "DEPARTMENT"
                ileasticObject "SERVREST" {
                id: String(3) column "DEPTNO" key required
            }
            operations for Service { GET }

            entity Employee resource "employees" table "EMPLOYEE"
                ileasticObject "EMPREST" {
                id: String(6) column "EMPNO" key required
            }
            operations for Employee { GET }

            server CatalogueApi object "CATAPI" port 44000 {
                Service, Employee
            }
        `);
        const catalogs = buildCatalogSpecs(model);
        const compilation = buildCatalogServerSpecs(model, catalogs.specs);
        const server = compilation.specs[0];

        expect(compilation.diagnostics).toEqual([]);
        expect(server?.catalogs.map(catalog => catalog.entity)).toEqual([
            'Service',
            'Employee'
        ]);
        expect(generateCatalogServerMain(server!)).toContain(
            'employee_registerRoutes(config);'
        );
        expect(generateCatalogServerRules(server!)).toContain(
            'CATAPI.PGM: CATAPI.MODULE SERVREST.MODULE SERVICE.SRVPGM EMPREST.MODULE EMPLOYEE.SRVPGM'
        );
    });

    test('renders the RPG main and BOB rules through replaceable templates', async () => {
        const { compilation } = await compileServerFixture();
        const server = compilation.specs[0];

        expect(server).toBeDefined();
        if (!server) {
            return;
        }

        const main = generateCatalogServerMain(server);
        const rules = generateCatalogServerRules(server);
        const projectRules = generateCatalogProjectRules(
            ['services', 'serviceapi']
        );

        expect(main).toContain("bnddir('QC2LE':'ILEASTIC')");
        expect(main).toContain("/include 'services.ileastic.rpgleinc'");
        expect(main).toContain('config.port = 44000;');
        expect(main).toContain("config.host = '*ANY';");
        expect(main).toContain('service_registerRoutes(config);');
        expect(main).toContain('il_listen(config);');
        expect(rules).toContain(
            'SERVAPI.MODULE: serviceapi.main.sqlrpgle'
        );
        expect(rules).toContain(
            'SERVAPI.PGM: SERVAPI.MODULE SERVREST.MODULE SERVICE.SRVPGM'
        );
        expect(projectRules).toBe('SUBDIRS = services serviceapi\n');

        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-server-template-')
        );
        try {
            fs.writeFileSync(
                path.join(
                    temporaryDirectory,
                    'catalog-server.main.sqlrpgle.hbs'
                ),
                '{{objectName}}|{{port}}|{{host}}|{{#each catalogs}}{{registerRoutes}}:{{interfaceSource}}{{/each}}\n',
                'utf-8'
            );

            expect(
                generateCatalogServerMain(server, temporaryDirectory)
            ).toBe(
                'SERVAPI|44000|*ANY|service_registerRoutes:services.ileastic.rpgleinc\n'
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('writes server and project artifacts without changing catalog artifacts', async () => {
        const { model } = await compileServerFixture();
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-server-')
        );

        try {
            const artifacts = generateCatalogProjectArtifacts(
                model,
                temporaryDirectory
            );

            expect(artifacts.catalogs).toHaveLength(1);
            expect(artifacts.servers).toEqual([
                {
                    main: path.join(
                        temporaryDirectory,
                        'serviceapi',
                        'serviceapi.main.sqlrpgle'
                    ),
                    rules: path.join(
                        temporaryDirectory,
                        'serviceapi',
                        'Rules.mk'
                    )
                }
            ]);
            expect(artifacts.projectRules).toBe(
                path.join(temporaryDirectory, 'Rules.mk')
            );
            expect(
                fs.readFileSync(artifacts.servers[0].main, 'utf-8')
            ).toContain('service_registerRoutes(config);');
            expect(
                fs.readFileSync(artifacts.servers[0].rules, 'utf-8')
            ).toContain(
                'SERVAPI.PGM: SERVAPI.MODULE SERVREST.MODULE SERVICE.SRVPGM'
            );
            expect(
                fs.readFileSync(artifacts.projectRules, 'utf-8')
            ).toBe('SUBDIRS = services serviceapi\n');
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });

    test('keeps project-level server artifacts optional', async () => {
        const model = await parseCMagicString(`
            entity Service resource "services" table "DEPARTMENT" {
                id: String(3) column "DEPTNO" key required
            }
            operations for Service { GET }
        `);
        const temporaryDirectory = fs.mkdtempSync(
            path.join(process.env.TEMP ?? process.cwd(), 'cmagic-no-server-')
        );

        try {
            const artifacts = generateCatalogProjectArtifacts(
                model,
                temporaryDirectory
            );

            expect(artifacts.catalogs).toHaveLength(1);
            expect(artifacts.servers).toEqual([]);
            expect(artifacts.projectRules).toBeUndefined();
            expect(fs.existsSync(path.join(temporaryDirectory, 'Rules.mk'))).toBe(
                false
            );
        } finally {
            fs.rmSync(temporaryDirectory, { recursive: true, force: true });
        }
    });
});
