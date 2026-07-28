import fs from 'node:fs';
import path from 'node:path';
import type { Model } from '../language/generated/ast.js';
import {
    catalogBinderSourceName,
    catalogIleasticInterfaceSourceName,
    catalogIleasticSourceName,
    catalogRpgReadInterfaceSourceName,
    catalogRpgReadSourceName,
    catalogServerBaseName,
    catalogServerSourceName
} from './artifact-names.js';
import { generateCatalogBinder } from './binder.js';
import { buildCatalogSpecs } from './catalog-compiler.js';
import type { CatalogDiagnostic, CatalogSpec } from './catalog-spec.js';
import { generateCatalogDdl } from './ddl.js';
import { generateCatalogIleasticInterface } from './ileastic-interface.js';
import { generateCatalogIleasticWrapper } from './ileastic.js';
import { generateOpenApiSource } from './openapi.js';
import { generateResourceContractSource } from './resource-contract.js';
import { generateCatalogReadInterface } from './read-interface.js';
import { generateRpgReadModule } from './rpg-read.js';
import { generateCatalogRules } from './rules.js';
import { buildCatalogServerSpecs } from './server-compiler.js';
import type {
    CatalogServerDiagnostic,
    CatalogServerSpec
} from './server-spec.js';
import {
    generateCatalogProjectRules,
    generateCatalogServerMain,
    generateCatalogServerRules
} from './server.js';

export type GeneratedCatalogArtifactPaths = {
    spec: string;
    openApi: string;
    resourceContract: string;
    rpgRead: string;
    rpgReadInterface: string;
    ileastic: string;
    ileasticInterface: string;
    ddl: string;
    binder: string;
    rules: string;
};

export type GeneratedCatalogServerArtifactPaths = {
    main: string;
    rules: string;
};

export type GeneratedCatalogProjectArtifactPaths = {
    catalogs: GeneratedCatalogArtifactPaths[];
    servers: GeneratedCatalogServerArtifactPaths[];
    projectRules?: string;
};

export type CatalogProjectDiagnostic =
    | CatalogDiagnostic
    | CatalogServerDiagnostic;

export class CatalogCompilationError extends Error {
    readonly diagnostics: CatalogProjectDiagnostic[];

    constructor(diagnostics: CatalogProjectDiagnostic[]) {
        super(
            `Catalogue invalide:\n${diagnostics
                .map(item => `- [${item.code}] ${item.message}`)
                .join('\n')}`
        );
        this.name = 'CatalogCompilationError';
        this.diagnostics = diagnostics;
    }
}

const writeArtifact = (filePath: string, content: string): void => {
    fs.writeFileSync(filePath, content, 'utf-8');
};

const buildCatalogSpecsOrThrow = (model: Model): CatalogSpec[] => {
    const compilation = buildCatalogSpecs(model);
    if (compilation.diagnostics.length > 0) {
        throw new CatalogCompilationError(compilation.diagnostics);
    }
    return compilation.specs;
};

const writeCatalogArtifacts = (
    specs: readonly CatalogSpec[],
    destination: string
): GeneratedCatalogArtifactPaths[] =>
    specs.map(spec => {
        const resourceDirectory = path.join(destination, spec.resource);
        fs.mkdirSync(resourceDirectory, { recursive: true });

        const artifacts: GeneratedCatalogArtifactPaths = {
            spec: path.join(
                resourceDirectory,
                `${spec.resource}.catalog-spec.json`
            ),
            openApi: path.join(resourceDirectory, `${spec.resource}.openapi.json`),
            resourceContract: path.join(
                resourceDirectory,
                `${spec.resource}.resource-contract.ts`
            ),
            rpgRead: path.join(
                resourceDirectory,
                catalogRpgReadSourceName(spec.resource)
            ),
            rpgReadInterface: path.join(
                resourceDirectory,
                catalogRpgReadInterfaceSourceName(spec.resource)
            ),
            ileastic: path.join(
                resourceDirectory,
                catalogIleasticSourceName(spec.resource)
            ),
            ileasticInterface: path.join(
                resourceDirectory,
                catalogIleasticInterfaceSourceName(spec.resource)
            ),
            ddl: path.join(resourceDirectory, `${spec.resource}.ddl.sql`),
            binder: path.join(
                resourceDirectory,
                catalogBinderSourceName(spec.resource)
            ),
            rules: path.join(resourceDirectory, 'Rules.mk')
        };

        writeArtifact(artifacts.spec, `${JSON.stringify(spec, null, 2)}\n`);
        writeArtifact(artifacts.openApi, generateOpenApiSource(spec));
        writeArtifact(
            artifacts.resourceContract,
            generateResourceContractSource(spec)
        );
        writeArtifact(
            artifacts.rpgReadInterface,
            generateCatalogReadInterface(spec)
        );
        writeArtifact(artifacts.rpgRead, generateRpgReadModule(spec));
        writeArtifact(
            artifacts.ileasticInterface,
            generateCatalogIleasticInterface(spec)
        );
        writeArtifact(
            artifacts.ileastic,
            generateCatalogIleasticWrapper(spec)
        );
        writeArtifact(artifacts.ddl, generateCatalogDdl(spec));
        writeArtifact(artifacts.binder, generateCatalogBinder(spec));
        writeArtifact(artifacts.rules, generateCatalogRules(spec));

        return artifacts;
    });

const writeCatalogServerArtifacts = (
    specs: readonly CatalogServerSpec[],
    destination: string
): GeneratedCatalogServerArtifactPaths[] =>
    specs.map(spec => {
        const serverDirectory = path.join(
            destination,
            catalogServerBaseName(spec.name)
        );
        fs.mkdirSync(serverDirectory, { recursive: true });

        const artifacts: GeneratedCatalogServerArtifactPaths = {
            main: path.join(serverDirectory, catalogServerSourceName(spec.name)),
            rules: path.join(serverDirectory, 'Rules.mk')
        };
        writeArtifact(artifacts.main, generateCatalogServerMain(spec));
        writeArtifact(artifacts.rules, generateCatalogServerRules(spec));
        return artifacts;
    });

export const generateCatalogArtifacts = (
    model: Model,
    destination: string
): GeneratedCatalogArtifactPaths[] => {
    const specs = buildCatalogSpecsOrThrow(model);
    return writeCatalogArtifacts(specs, destination);
};

export const generateCatalogProjectArtifacts = (
    model: Model,
    destination: string
): GeneratedCatalogProjectArtifactPaths => {
    const catalogSpecs = buildCatalogSpecsOrThrow(model);
    const serverCompilation = buildCatalogServerSpecs(
        model,
        catalogSpecs
    );
    if (serverCompilation.diagnostics.length > 0) {
        throw new CatalogCompilationError(serverCompilation.diagnostics);
    }

    const catalogs = writeCatalogArtifacts(catalogSpecs, destination);
    const servers = writeCatalogServerArtifacts(
        serverCompilation.specs,
        destination
    );
    if (servers.length === 0) {
        return { catalogs, servers };
    }

    const projectRules = path.join(destination, 'Rules.mk');
    writeArtifact(
        projectRules,
        generateCatalogProjectRules([
            ...catalogSpecs.map(spec => spec.resource),
            ...serverCompilation.specs.map(spec =>
                catalogServerBaseName(spec.name)
            )
        ])
    );
    return { catalogs, servers, projectRules };
};
