
import type { Model, Entity } from '../../language/generated/ast.js';
import * as path from 'node:path';
import { renderTemplate } from '../../generation/template-renderer.js';
import { registerHandlebarsHelpers } from './handlebars.js';
import { extractManualCode, injectManualCode } from './preservation.js';
import { extractDestinationAndName } from '../cli-util.js';

// Nouvelle fonction pour générer les copybooks RPG
export function generateRpgCopybook(entity: Entity, model: Model, sourceFile: string, templatesDir?: string, operations: string[] = []): string {
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();

    // Charger le template RPG simple avec commentaires

    // Préparer le contexte pour le template copybook simple
    const context = {
        name: entity.name,
        fields: entity.fields,
        sourceFile: path.basename(sourceFile),
        structs: model.structs || [],
        enums: model.enums || [],
        operations: operations // Operations directement dans le contexte
    };

    // Compiler et appliquer le template
    const rpgCode = renderTemplate('copybook.rpg.tpl', context, templatesDir);

    return rpgCode;
}

// Nouvelle fonction pour générer les services RPG
export function generateRpgService(entity: Entity, operations: string[], model: Model, sourceFile: string, templatesDir?: string): string {
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();

    // Charger le template service RPG conforme PRD Sprint 02 Phase 3

    // Préparer le contexte pour le template - EXPLICITE
    const context = {
        name: entity.name,
        fields: entity.fields,
        entity: entity, // Entité complète pour les helpers
        operations: operations,
        sourceFile: path.basename(sourceFile),
        structs: model.structs || [],
        enums: model.enums || []
    };

    // Compiler et appliquer le template
    let serviceCode = renderTemplate('service.sqlrpgle.tpl', context, templatesDir);

    // *** NOUVELLE FONCTIONNALITÉ: Préservation des zones protégées ***
    // Calculer le chemin du fichier service existant
    // Attention: adaptation pour le déplacement du fichier
    // On suppose que sourceFile est le chemin complet ou relatif correct
    const { destination } = extractDestinationAndName(sourceFile, 'generated');
    const entityName = entity.name.toLowerCase();
    const existingServicePath = path.join(destination, entityName, `${entityName}.sqlrpgle`);

    // Extraire le code manuel du fichier existant
    const existingManualCode = extractManualCode(existingServicePath);

    if (existingManualCode) {
        console.log(`🔧 Préservation du code manuel pour ${entity.name} service`);
        serviceCode = injectManualCode(serviceCode, existingManualCode);
    }

    return serviceCode;
}

// Nouvelle fonction pour générer les tests RPG
export function generateRpgTest(entity: Entity, operations: string[], model: Model, sourceFile: string, templatesDir?: string): string {
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();

    // Charger le template test RPG

    // Préparer le contexte pour le template
    const context = {
        ...entity,
        operations: operations,
        sourceFile: path.basename(sourceFile),
        structs: model.structs || [],
        enums: model.enums || []
    };

    // Compiler et appliquer le template
    const testCode = renderTemplate('test.sqlrpgle.tpl', context, templatesDir);

    return testCode;
}
