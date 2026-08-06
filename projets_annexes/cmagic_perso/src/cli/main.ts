import type { Model } from '../language/generated/ast.js';
import chalk from 'chalk';
import { Command } from 'commander';
import { CmagicLanguageMetaData } from '../language/generated/module.js';
import { createCmagicServices } from '../language/cmagic-module.js';
import { extractAstNode } from './cli-util.js';
import { generateCode } from './generator.js';
import { generateCatalogProjectArtifacts } from '../catalog/index.js';
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
    const artifacts = generateCatalogProjectArtifacts(model, destination);

    for (const artifact of artifacts.catalogs) {
        console.log(chalk.green(`catalogue generated: ${artifact.spec}`));
        console.log(chalk.green(`OpenAPI generated: ${artifact.openApi}`));
        console.log(
            chalk.green(`resource contract generated: ${artifact.resourceContract}`)
        );
        console.log(
            chalk.green(
                `RPG read interface generated: ${artifact.rpgReadInterface}`
            )
        );
        console.log(
            chalk.green(
                `RPG test include generated: ${artifact.rpgTestReadInterface}`
            )
        );
        console.log(
            chalk.green(`RPGUnit read envelope generated: ${artifact.rpgReadTest}`)
        );
        console.log(
            chalk.green(`RPGUnit configuration generated: ${artifact.testing}`)
        );
        console.log(chalk.green(`RPG read module generated: ${artifact.rpgRead}`));
        console.log(
            chalk.green(
                `ILEastic interface generated: ${artifact.ileasticInterface}`
            )
        );
        console.log(
            chalk.green(`ILEastic wrapper generated: ${artifact.ileastic}`)
        );
        if (artifact.iwsInterface) {
            console.log(
                chalk.green(`IWS interface generated: ${artifact.iwsInterface}`)
            );
        }
        if (artifact.iwsTestInterface) {
            console.log(
                chalk.green(
                    `IWS test include generated: ${artifact.iwsTestInterface}`
                )
            );
        }
        if (artifact.iws) {
            console.log(chalk.green(`IWS wrapper generated: ${artifact.iws}`));
        }
        if (artifact.iwsTest) {
            console.log(
                chalk.green(`RPGUnit IWS envelope generated: ${artifact.iwsTest}`)
            );
        }
        if (artifact.iwsBinder) {
            console.log(
                chalk.green(`IWS binder generated: ${artifact.iwsBinder}`)
            );
        }
        if (artifact.iwsReadBindingDirectory) {
            console.log(
                chalk.green(
                    `IWS read binding directory generated: ${artifact.iwsReadBindingDirectory}`
                )
            );
        }
        if (artifact.iwsBindingDirectory) {
            console.log(
                chalk.green(
                    `IWS binding directory generated: ${artifact.iwsBindingDirectory}`
                )
            );
        }
        console.log(chalk.green(`Db2 DDL generated: ${artifact.ddl}`));
        console.log(chalk.green(`binder generated: ${artifact.binder}`));
        console.log(chalk.green(`BOB rules generated: ${artifact.rules}`));
    }
    for (const artifact of artifacts.servers) {
        console.log(
            chalk.green(`ILEastic server generated: ${artifact.main}`)
        );
        console.log(
            chalk.green(`ILEastic server BOB rules generated: ${artifact.rules}`)
        );
    }
    if (artifacts.projectRules) {
        console.log(
            chalk.green(`BOB project rules generated: ${artifacts.projectRules}`)
        );
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
            'generates catalogue contracts, RPG transport artifacts and optional ILEastic application server projects'
        )
        .action(generateCatalogAction);

    program.parse(process.argv);
}
