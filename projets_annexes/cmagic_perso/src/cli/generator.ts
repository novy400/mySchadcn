
import type { Model } from '../language/generated/ast.js';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { extractDestinationAndName } from './cli-util.js';
import { generateRpgCopybook, generateRpgService, generateRpgTest } from './generators/rpg.js';
import { generateEntitySql, generateSqlFromTemplate } from './generators/sql.js';

export { generateRpgCopybook, generateRpgService, generateRpgTest };
export { generateEntitySql, generateSqlFromTemplate };

export function generateCode(model: Model, filePath: string, destination: string | undefined, templatesDir?: string): string {
    const data = extractDestinationAndName(filePath, destination);

    // 1. Générer les artefacts pour chaque entité individuellement
    for (const entity of model.entities) {
        // Vérifier s'il y a des operations pour cette entité
        const entityOperations = model.operations?.find(ops => ops.entity.ref?.name === entity.name);

        // Générer le copybook RPG pour cette entité avec ses opérations
        const rpgContent = generateRpgCopybook(entity, model, filePath, templatesDir, entityOperations?.operations || []);

        // Déterminer le chemin de sortie pour l'entité
        const entityFolderName = entity.name.toLowerCase();
        const entityDir = path.join(data.destination, entityFolderName);

        // S'assurer que le répertoire de l'entité existe
        if (!fs.existsSync(entityDir)) {
            fs.mkdirSync(entityDir, { recursive: true });
        }

        // Le chemin final du copybook RPG (nom lowercase selon PRD Sprint02)
        const rpgOutputPath = path.join(entityDir, `${entity.name.toLowerCase()}.rpgleinc`);

        // Écrire le copybook RPG
        fs.writeFileSync(rpgOutputPath, rpgContent);
        console.log(`Generated RPG copybook for ${entity.name} at: ${rpgOutputPath}`);

        // 2. Générer les services si des opérations sont définies
        if (entityOperations && entityOperations.operations.length > 0) {
            // Générer le service RPG pour cette entité
            const serviceContent = generateRpgService(entity, entityOperations.operations, model, filePath, templatesDir);

            // Le chemin final du service RPG (nom lowercase selon PRD Sprint02)
            const serviceOutputPath = path.join(entityDir, `${entity.name.toLowerCase()}.sqlrpgle`);

            // Écrire le service RPG
            fs.writeFileSync(serviceOutputPath, serviceContent);
            console.log(`Generated RPG service for ${entity.name} at: ${serviceOutputPath}`);

            // Générer les tests RPG pour cette entité
            const testContent = generateRpgTest(entity, entityOperations.operations, model, filePath, templatesDir);

            // Le chemin final du test RPG
            const testOutputPath = path.join(entityDir, `${entity.name.toLowerCase()}.test.sqlrpgle`);

            // Écrire le test RPG
            fs.writeFileSync(testOutputPath, testContent);
            console.log(`Generated RPG test for ${entity.name} at: ${testOutputPath}`);
        }

        // 3. Générer le SQL d'entité individuel
        const entitySqlContent = generateEntitySql(entity, model, templatesDir);
        const entitySqlPath = path.join(entityDir, `${entity.name.toLowerCase()}.sql`);
        fs.writeFileSync(entitySqlPath, entitySqlContent);
        console.log(`Generated entity SQL for ${entity.name} at: ${entitySqlPath}`);
    }

    // 2. Générer le fichier SQL global
    const generatedFilePath = `${path.join(data.destination, data.name)}.sql`;
    const generatedSql = generateSqlFromTemplate(model, templatesDir);

    // Ensure the destination directory exists
    if (!fs.existsSync(data.destination)) {
        fs.mkdirSync(data.destination, { recursive: true });
    }

    fs.writeFileSync(generatedFilePath, generatedSql);
    console.log(`Generated SQL at: ${generatedFilePath}`);

    return generatedFilePath;
}
