// tests/test-utils.ts


import { EmptyFileSystem, type LangiumDocument } from "langium";
import { createCmagicServices } from "../../src/language/cmagic-module.js";
import { Model } from '../../src/language/generated/ast.js';
import { parseHelper } from "langium/test";
import { generateSqlFromTemplate, generateRpgCopybook, generateRpgService } from '../../src/cli/generator.js';

let services: ReturnType<typeof createCmagicServices>;
let parse:    ReturnType<typeof parseHelper<Model>>;
let document: LangiumDocument<Model> | undefined;
// On importe la VRAIE fonction de génération de SQL qu'on a créée
// MAIS on va devoir la modifier un peu pour qu'elle soit exportable

/**
 * Fonction helper qui prend une chaîne de DSL en entrée,
 * la parse avec Langium, et retourne le SQL généré.
 */
export async function generateSqlFromString(dslString: string): Promise<string> {
    // Crée une instance "en mémoire" des services Langium pour les tests
    services = createCmagicServices(EmptyFileSystem);
    parse = parseHelper<Model>(services.Cmagic);    
    // Crée un document virtuel à partir de notre chaîne de caractères
    document = await parse(dslString);
    
    // Attend que Langium ait fini de parser et de lier le document
    await services.shared.workspace.DocumentBuilder.build([document], { validation: true });

    // Récupère l'AST (le modèle)
    const model = document.parseResult.value as Model;

    // Vérifie qu'il n'y a pas d'erreurs de parsing
    const errors = (document.diagnostics ?? []).filter(e => e.severity === 1);
    if (errors.length > 0) {
        throw new Error('DSL parsing error: ' + errors.map(e => e.message).join('\n'));
    }

    // Appelle notre fonction de génération existante
    return generateSqlFromTemplate(model);
}

/**
 * Fonction helper qui prend une chaîne de DSL en entrée,
 * la parse avec Langium, et retourne le copybook RPG généré pour une entité donnée.
 * Utilisée pour les tests Sprint 01 qui s'attendent à des copybooks (.rpgleinc)
 */
export async function generateRpgFromString(dslString: string, entityName: string): Promise<string> {
    // Crée une instance "en mémoire" des services Langium pour les tests
    services = createCmagicServices(EmptyFileSystem);
    parse = parseHelper<Model>(services.Cmagic);    
    // Crée un document virtuel à partir de notre chaîne de caractères
    document = await parse(dslString);
    
    // Attend que Langium ait fini de parser et de lier le document
    await services.shared.workspace.DocumentBuilder.build([document], { validation: true });

    // Récupère l'AST (le modèle)
    const model = document.parseResult.value as Model;

    // Vérifie qu'il n'y a pas d'erreurs de parsing
    const errors = (document.diagnostics ?? []).filter(e => e.severity === 1);
    if (errors.length > 0) {
        throw new Error('DSL parsing error: ' + errors.map(e => e.message).join('\n'));
    }

    // Trouve l'entité demandée
    const entity = model.entities.find(e => e.name === entityName);
    if (!entity) {
        throw new Error(`Entity ${entityName} not found in model`);
    }

    // Appelle la fonction de génération RPG copybook (Sprint 01)
    return generateRpgCopybook(entity, model, 'test.cmagic');
}

/**
 * Fonction helper qui prend une chaîne de DSL en entrée,
 * la parse avec Langium, et retourne le service RPG généré pour une entité donnée.
 * Utilisée pour les tests Sprint 02 qui s'attendent à des services (.sqlrpgle)
 */
export async function generateRpgServiceFromString(dslString: string, entityName: string): Promise<string> {
    // Crée une instance "en mémoire" des services Langium pour les tests
    services = createCmagicServices(EmptyFileSystem);
    parse = parseHelper<Model>(services.Cmagic);    
    // Crée un document virtuel à partir de notre chaîne de caractères
    document = await parse(dslString);
    
    // Attend que Langium ait fini de parser et de lier le document
    await services.shared.workspace.DocumentBuilder.build([document], { validation: true });

    // Récupère l'AST (le modèle)
    const model = document.parseResult.value as Model;

    // Vérifie qu'il n'y a pas d'erreurs de parsing
    const errors = (document.diagnostics ?? []).filter(e => e.severity === 1);
    if (errors.length > 0) {
        throw new Error('DSL parsing error: ' + errors.map(e => e.message).join('\n'));
    }

    // Trouve l'entité demandée
    const entity = model.entities.find(e => e.name === entityName);
    if (!entity) {
        throw new Error(`Entity ${entityName} not found in model`);
    }

    // Trouve les opérations pour cette entité
    const operationsBlock = model.operations.find(op => op.entity.ref?.name === entityName);
    const operations = operationsBlock ? operationsBlock.operations : [];

    // Appelle la fonction de génération RPG service (Sprint 02)
    return generateRpgService(entity, operations, model, 'test.cmagic');
}

/**
 * Fonction helper qui prend une chaîne de DSL en entrée,
 * la parse avec Langium, et retourne le modèle AST.
 */
export async function parseCMagicString(dslString: string): Promise<Model> {
    // Crée une instance "en mémoire" des services Langium pour les tests
    services = createCmagicServices(EmptyFileSystem);
    parse = parseHelper<Model>(services.Cmagic);    
    
    // Crée un document virtuel à partir de notre chaîne de caractères
    document = await parse(dslString);
    
    // Attend que Langium ait fini de parser et de lier le document
    await services.shared.workspace.DocumentBuilder.build([document], { validation: true });

    // Récupère l'AST (le modèle)
    const model = document.parseResult.value as Model;

    // Vérifie qu'il n'y a pas d'erreurs de parsing
    const errors = (document.diagnostics ?? []).filter(e => e.severity === 1);
    if (errors.length > 0) {
        throw new Error('DSL parsing error: ' + errors.map(e => e.message).join('\n'));
    }

    return model;
}