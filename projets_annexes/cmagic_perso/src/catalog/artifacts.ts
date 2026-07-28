import fs from 'node:fs';
import path from 'node:path';
import type { Model } from '../language/generated/ast.js';
import { buildCatalogSpecs } from './catalog-compiler.js';
import type { CatalogDiagnostic } from './catalog-spec.js';
import { generateCatalogDdl } from './ddl.js';
import { generateOpenApiSource } from './openapi.js';
import { generateResourceContractSource } from './resource-contract.js';
import { generateRpgReadModule } from './rpg-read.js';

export type GeneratedCatalogArtifactPaths = {
    spec: string;
    openApi: string;
    resourceContract: string;
    rpgRead: string;
    ddl: string;
};

export class CatalogCompilationError extends Error {
    readonly diagnostics: CatalogDiagnostic[];

    constructor(diagnostics: CatalogDiagnostic[]) {
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

export const generateCatalogArtifacts = (
    model: Model,
    destination: string
): GeneratedCatalogArtifactPaths[] => {
    const compilation = buildCatalogSpecs(model);
    if (compilation.diagnostics.length > 0) {
        throw new CatalogCompilationError(compilation.diagnostics);
    }

    return compilation.specs.map(spec => {
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
            rpgRead: path.join(resourceDirectory, `${spec.resource}.read.sqlrpgle`),
            ddl: path.join(resourceDirectory, `${spec.resource}.ddl.sql`)
        };

        writeArtifact(artifacts.spec, `${JSON.stringify(spec, null, 2)}\n`);
        writeArtifact(artifacts.openApi, generateOpenApiSource(spec));
        writeArtifact(
            artifacts.resourceContract,
            generateResourceContractSource(spec)
        );
        writeArtifact(artifacts.rpgRead, generateRpgReadModule(spec));
        writeArtifact(artifacts.ddl, generateCatalogDdl(spec));

        return artifacts;
    });
};
