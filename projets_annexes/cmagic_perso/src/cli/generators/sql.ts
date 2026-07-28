
import type { Model, Entity } from '../../language/generated/ast.js';
import * as path from 'node:path';
import * as fs from 'node:fs';
import Handlebars from 'handlebars';
import { registerHandlebarsHelpers } from './handlebars.js';
import { resolveTemplatesDirectory } from './template-directory.js';

export function generateEntitySql(entity: Entity, model: Model, templatesDir?: string): string {
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();

    // Charger le template SQL d'entité
    const templatePath = path.join(resolveTemplatesDirectory(templatesDir), 'entity.sql.tpl');
    const templateSource = fs.readFileSync(templatePath, 'utf-8');

    // Préparer le contexte pour le template (juste cette entité)
    const context = {
        entities: [entity],
        structs: model.structs || [],
        enums: model.enums || []
    };

    // Compiler et appliquer le template
    const compiledTemplate = Handlebars.compile(templateSource);
    const sqlCode = compiledTemplate(context);

    return sqlCode;
}

export function generateSqlFromTemplate(model: Model, templatesDir?: string): string {
    // Charger le template depuis le disque
    const templatePath = path.join(resolveTemplatesDirectory(templatesDir), 'schema.sql.tpl');
    const templateSource = fs.readFileSync(templatePath, 'utf-8');

    // Enregistrer nos helpers personnalisés
    registerHandlebarsHelpers();

    // Compiler le template
    const compiledTemplate = Handlebars.compile(templateSource);

    // Appliquer le modèle de données (notre AST) au template
    const sql = compiledTemplate(model);

    return sql;
}
