import fs from 'node:fs';
import path from 'node:path';
import type { Model } from '../language/generated/ast.js';
import {
    extractManualCode,
    injectManualCode
} from '../generation/manual-code.js';
import {
    catalogBinderSourceName,
    catalogIleasticInterfaceSourceName,
    catalogIleasticSourceName,
    catalogIwsBinderSourceName,
    catalogIwsBindingDirectorySourceName,
    catalogIwsReadBindingDirectorySourceName,
    catalogIwsInterfaceSourceName,
    catalogIwsSourceName,
    catalogIwsTestSourceName,
    catalogRpgReadInterfaceSourceName,
    catalogRpgReadSourceName,
    catalogRpgReadTestSourceName,
    catalogServerBaseName,
    catalogServerSourceName,
    catalogTestingSourceName
} from './artifact-names.js';
import { generateCatalogBinder } from './binder.js';
import { buildCatalogSpecs } from './catalog-compiler.js';
import type { CatalogDiagnostic, CatalogSpec } from './catalog-spec.js';
import { generateCatalogDdl } from './ddl.js';
import { generateCatalogIleasticInterface } from './ileastic-interface.js';
import { generateCatalogIleasticWrapper } from './ileastic.js';
import {
    generateCatalogIwsBindingDirectory,
    generateCatalogIwsReadBindingDirectory
} from './iws-binding-directory.js';
import { generateCatalogIwsBinder } from './iws-binder.js';
import {
    generateCatalogIwsInterface,
    generateCatalogTestIwsInterface
} from './iws-interface.js';
import { generateCatalogIwsTest } from './iws-test.js';
import { generateCatalogIwsWrapper } from './iws.js';
import { generateOpenApiSource } from './openapi.js';
import { generateResourceContractSource } from './resource-contract.js';
import {
    generateCatalogReadInterface,
    generateCatalogTestReadInterface
} from './read-interface.js';
import { generateRpgReadModule } from './rpg-read.js';
import { generateCatalogReadTest } from './read-test.js';
import { generateCatalogRules } from './rules.js';
import {
    generateCatalogTestingConfiguration,
    mergeCatalogTestingConfiguration
} from './testing.js';
import { buildCatalogServerSpecs } from './server-compiler.js';
import type {
    CatalogServerDiagnostic,
    CatalogServerSpec
} from './server-spec.js';
import {
    generateCatalogProjectRules,
    mergeCatalogProjectRules,
    generateCatalogServerMain,
    generateCatalogServerRules
} from './server.js';

export type GeneratedCatalogArtifactPaths = {
    spec: string;
    openApi: string;
    resourceContract: string;
    rpgRead: string;
    rpgReadInterface: string;
    rpgTestReadInterface: string;
    rpgReadTest: string;
    testing: string;
    ileastic: string;
    ileasticInterface: string;
    iws?: string;
    iwsInterface?: string;
    iwsTest?: string;
    iwsTestInterface?: string;
    iwsBinder?: string;
    iwsReadBindingDirectory?: string;
    iwsBindingDirectory?: string;
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

type MissingManualMarkersPolicy = 'preserve-existing' | 'overwrite-generated';

const writeArtifactPreservingManualCode = (
    filePath: string,
    generatedContent: string,
    missingMarkersPolicy: MissingManualMarkersPolicy = 'preserve-existing'
): void => {
    const alreadyExists = fs.existsSync(filePath);
    const manualCode = extractManualCode(filePath);
    if (
        alreadyExists &&
        manualCode === null &&
        missingMarkersPolicy === 'preserve-existing'
    ) {
        return;
    }
    writeArtifact(
        filePath,
        manualCode === null
            ? generatedContent
            : injectManualCode(generatedContent, manualCode)
    );
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
): GeneratedCatalogArtifactPaths[] => {
    const testIncludesDirectory = path.join(destination, 'includes');
    fs.mkdirSync(testIncludesDirectory, { recursive: true });

    return specs.map(spec => {
        const resourceDirectory = path.join(destination, spec.resource);
        fs.mkdirSync(resourceDirectory, { recursive: true });

        const iwsArtifacts =
            spec.iwsObject === undefined
                ? {}
                : {
                      iws: path.join(
                          resourceDirectory,
                          catalogIwsSourceName(spec.resource)
                      ),
                      iwsInterface: path.join(
                          resourceDirectory,
                          catalogIwsInterfaceSourceName(spec.resource)
                      ),
                      iwsTest: path.join(
                          resourceDirectory,
                          catalogIwsTestSourceName(spec.iwsObject)
                      ),
                      iwsTestInterface: path.join(
                          testIncludesDirectory,
                          catalogIwsInterfaceSourceName(spec.resource)
                      ),
                      iwsBinder: path.join(
                          resourceDirectory,
                          catalogIwsBinderSourceName(spec.resource)
                      ),
                      iwsReadBindingDirectory: path.join(
                          resourceDirectory,
                          catalogIwsReadBindingDirectorySourceName(spec.resource)
                      ),
                      iwsBindingDirectory: path.join(
                          resourceDirectory,
                          catalogIwsBindingDirectorySourceName(spec.resource)
                      )
                  };
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
            rpgTestReadInterface: path.join(
                testIncludesDirectory,
                catalogRpgReadInterfaceSourceName(spec.resource)
            ),
            rpgReadTest: path.join(
                resourceDirectory,
                catalogRpgReadTestSourceName(spec.entity)
            ),
            testing: path.join(
                resourceDirectory,
                catalogTestingSourceName()
            ),
            ileastic: path.join(
                resourceDirectory,
                catalogIleasticSourceName(spec.resource)
            ),
            ileasticInterface: path.join(
                resourceDirectory,
                catalogIleasticInterfaceSourceName(spec.resource)
            ),
            ...iwsArtifacts,
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
        writeArtifact(
            artifacts.rpgTestReadInterface,
            generateCatalogTestReadInterface(spec)
        );
        writeArtifactPreservingManualCode(
            artifacts.rpgReadTest,
            generateCatalogReadTest(spec)
        );
        const generatedTesting = generateCatalogTestingConfiguration(spec);
        writeArtifact(
            artifacts.testing,
            fs.existsSync(artifacts.testing)
                ? mergeCatalogTestingConfiguration(
                      fs.readFileSync(artifacts.testing, 'utf-8'),
                      generatedTesting
                  )
                : generatedTesting
        );
        writeArtifactPreservingManualCode(
            artifacts.rpgRead,
            generateRpgReadModule(spec),
            'overwrite-generated'
        );
        writeArtifact(
            artifacts.ileasticInterface,
            generateCatalogIleasticInterface(spec)
        );
        writeArtifact(
            artifacts.ileastic,
            generateCatalogIleasticWrapper(spec)
        );
        if (
            artifacts.iws !== undefined &&
            artifacts.iwsInterface !== undefined &&
            artifacts.iwsBinder !== undefined &&
            artifacts.iwsReadBindingDirectory !== undefined &&
            artifacts.iwsBindingDirectory !== undefined
        ) {
            writeArtifact(
                artifacts.iwsInterface,
                generateCatalogIwsInterface(spec)
            );
            writeArtifact(artifacts.iws, generateCatalogIwsWrapper(spec));
            writeArtifact(
                artifacts.iwsBinder,
                generateCatalogIwsBinder(spec)
            );
            writeArtifact(
                artifacts.iwsReadBindingDirectory,
                generateCatalogIwsReadBindingDirectory(spec)
            );
            writeArtifact(
                artifacts.iwsBindingDirectory,
                generateCatalogIwsBindingDirectory(spec)
            );
        }
        if (
            artifacts.iwsTest !== undefined &&
            artifacts.iwsTestInterface !== undefined
        ) {
            writeArtifact(
                artifacts.iwsTestInterface,
                generateCatalogTestIwsInterface(spec)
            );
            writeArtifactPreservingManualCode(
                artifacts.iwsTest,
                generateCatalogIwsTest(spec)
            );
        }
        writeArtifact(artifacts.ddl, generateCatalogDdl(spec));
        writeArtifact(artifacts.binder, generateCatalogBinder(spec));
        writeArtifact(artifacts.rules, generateCatalogRules(spec));

        return artifacts;
    });
};

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
    if (catalogs.length === 0 && servers.length === 0) {
        return { catalogs, servers };
    }

    const projectRules = path.join(destination, 'Rules.mk');
    const generatedProjectRules = generateCatalogProjectRules([
        ...catalogSpecs.map(spec => spec.resource),
        ...serverCompilation.specs.map(spec =>
            catalogServerBaseName(spec.name)
        )
    ]);
    writeArtifact(
        projectRules,
        fs.existsSync(projectRules)
            ? mergeCatalogProjectRules(
                  fs.readFileSync(projectRules, 'utf-8'),
                  generatedProjectRules
              )
            : generatedProjectRules
    );
    return { catalogs, servers, projectRules };
};
