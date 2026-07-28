import type { Model } from '../language/generated/ast.js';
import chalk from 'chalk';
import { Command } from 'commander';
import { CmagicLanguageMetaData } from '../language/generated/module.js';
import { createCmagicServices } from '../language/cmagic-module.js';
import { extractAstNode } from './cli-util.js';
import { generateCode } from './generator.js';
import { generateCatalogArtifacts } from '../catalog/index.js';
import { NodeFileSystem } from 'langium/node';
import * as url from 'node:url';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
const __dirname = url.fileURLToPath(new URL('.', import.meta.url));

const packagePath = path.resolve(__dirname, '..', '..', 'package.json');
const packageContent = await fs.readFile(packagePath, 'utf-8');

export const generateAction = async (fileName: string, opts: GenerateOptions): Promise<void> => {
    console.log(`Starting generation for: ${fileName}`);
    console.log(`Options:`, opts);

    const services = createCmagicServices(NodeFileSystem).Cmagic;
    const model = await extractAstNode<Model>(fileName, services);

    console.log(`Model extracted, entities: ${model.entities?.length || 0}`);
    console.log(`Operations: ${model.operations?.length || 0}`);

    const templatesDir = path.join(__dirname, '..', 'templates');
    const generatedFilePath = generateCode(model, fileName, opts.destination, templatesDir);
    console.log(chalk.green(`all code generated successfully: ${generatedFilePath}`));
};

export const generateCatalogAction = async (
    fileName: string,
    opts: GenerateOptions
): Promise<void> => {
    const services = createCmagicServices(NodeFileSystem).Cmagic;
    const model = await extractAstNode<Model>(fileName, services);
    const destination =
        opts.destination ?? path.join(path.dirname(fileName), 'generated-catalog');
    const artifacts = generateCatalogArtifacts(model, destination);

    for (const artifact of artifacts) {
        console.log(chalk.green(`catalogue generated: ${artifact.spec}`));
        console.log(chalk.green(`OpenAPI generated: ${artifact.openApi}`));
        console.log(
            chalk.green(`resource contract generated: ${artifact.resourceContract}`)
        );
        console.log(chalk.green(`RPG read module generated: ${artifact.rpgRead}`));
        console.log(chalk.green(`Db2 DDL generated: ${artifact.ddl}`));
        console.log(chalk.green(`BOB rules generated: ${artifact.rules}`));
    }
};

export type GenerateOptions = {
    destination?: string;
}

export default function (): void {
    const program = new Command();

    program.version(JSON.parse(packageContent).version);

    const fileExtensions = CmagicLanguageMetaData.fileExtensions.join(', ');
    program
        .command('generate')
        .argument('<file>', `source file (possible file extensions: ${fileExtensions})`)
        .option('-d, --destination <dir>', 'destination directory of generating')
        .description('generates JavaScript code that prints "Hello, {name}!" for each greeting in a source file')
        .action(generateAction);

    program
        .command('generate-catalog')
        .argument('<file>', `source file (possible file extensions: ${fileExtensions})`)
        .option('-d, --destination <dir>', 'catalogue output directory')
        .description(
            'generates CatalogSpec, OpenAPI, frontend contracts, RPG read modules, Db2 DDL and BOB rules'
        )
        .action(generateCatalogAction);

    program.parse(process.argv);
}
