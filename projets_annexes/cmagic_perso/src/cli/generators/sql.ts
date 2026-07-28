
import type { Model, Entity } from '../../language/generated/ast.js';
import { renderTemplate } from '../../generation/template-renderer.js';
import { registerHandlebarsHelpers } from './handlebars.js';

export function generateEntitySql(entity: Entity, model: Model, templatesDir?: string): string {
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();

    // Charger le template SQL d'entité

    // Préparer le contexte pour le template (juste cette entité)
    const context = {
        entities: [entity],
        structs: model.structs || [],
        enums: model.enums || []
    };

    // Compiler et appliquer le template
    const sqlCode = renderTemplate('entity.sql.tpl', context, templatesDir);

    return sqlCode;
}

export function generateSqlFromTemplate(model: Model, templatesDir?: string): string {
    // Charger le template depuis le disque

    // Enregistrer nos helpers personnalisés
    registerHandlebarsHelpers();

    // Compiler le template

    // Appliquer le modèle de données (notre AST) au template
    const sql = renderTemplate('schema.sql.tpl', model, templatesDir);

    return sql;
}
