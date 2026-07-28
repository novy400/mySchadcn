import type { Model , TypeDefinition, Entity, Field} from '../language/generated/ast.js';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'url'; 
import { extractDestinationAndName } from './cli-util.js';
import Handlebars from 'handlebars'; 

// Fonction pour enregistrer tous les helpers Handlebars
function registerHandlebarsHelpers() {
    console.log('=== REGISTERING HANDLEBARS HELPERS ===');
    
    Handlebars.registerHelper('toUpperCase', function (aString) {
        return aString.toUpperCase();
    });

    Handlebars.registerHelper('fieldConstraints', function (field: Field) {
        console.log('=== FIELDCONSTRAINTS HELPER CALLED ===');
        let constraints = [];
        
        // NOT NULL si required
        if (field.required) {
            constraints.push('NOT NULL');
        }
        
        // DEFAULT value si spécifié
        if (field.default && field.default.value) {
            const defaultVal = field.default.value;
            if (defaultVal.stringValue) {
                constraints.push(`DEFAULT '${defaultVal.stringValue.replace(/['"]/g, '')}'`);
            } else if (defaultVal.numberValue !== undefined) {
                constraints.push(`DEFAULT ${defaultVal.numberValue}`);
            } else if (defaultVal.booleanValue) {
                // DEBUG: Affichage des valeurs pour comprendre le problème
                console.log('=== DEBUG BOOLEAN DEFAULT ===');
                console.log('raw booleanValue:', defaultVal.booleanValue);
                console.log('typeof booleanValue:', typeof defaultVal.booleanValue);
                console.log('toString():', defaultVal.booleanValue.toString());
                console.log('toLowerCase():', defaultVal.booleanValue.toString().toLowerCase());
                
                // Conversion booléenne: true/false -> Y/N pour SQL
                // La valeur booleanValue est une string 'true' ou 'false'
                const boolStr = defaultVal.booleanValue.toString().toLowerCase();
                const boolVal = boolStr === 'true' ? 'Y' : 'N';
                console.log('boolStr:', boolStr);
                console.log('boolVal:', boolVal);
                console.log('=== END DEBUG ===');
                
                constraints.push(`DEFAULT '${boolVal}'`);
            } else if (defaultVal.enumValue) {
                constraints.push(`DEFAULT '${defaultVal.enumValue}'`);
            }
        }
        
        return constraints.length > 0 ? ' ' + constraints.join(' ') : '';
    });

    Handlebars.registerHelper('generateConstraints', function (entity: Entity) {
        let constraints = [];
        
        // PRIMARY KEY (on suppose que le champ 'id' est la clé primaire)
        const idField = entity.fields.find((f: Field) => f.name === 'id');
        if (idField) {
            constraints.push(`PRIMARY KEY (${idField.name.toUpperCase()})`);
        }
        
        // UNIQUE constraints
        entity.fields.forEach((field: Field) => {
            if (field.unique) {
                constraints.push(`UNIQUE (${field.name.toUpperCase()})`);
            }
        });
        
        // CHECK constraints pour Boolean (CHAR(1) doit être Y ou N)
        entity.fields.forEach((field: Field) => {
            if (field.type.typeName === 'Boolean') {
                constraints.push(`CHECK (${field.name.toUpperCase()} IN ('Y', 'N'))`);
            }
        });
        
        return constraints.length > 0 ? ',\n    ' + constraints.join(',\n    ') : '';
    });

    Handlebars.registerHelper('generateForeignKeys', function (model, entity) {
        let foreignKeys: string[] = [];
        
        entity.fields.forEach((field: Field) => {
            // Convention: si le champ se termine par "Id" et n'est pas "id", 
            // c'est probablement une clé étrangère
            if (field.name.endsWith('Id') && field.name !== 'id') {
                const entityName = field.name.replace(/Id$/, '');
                // Chercher une entité correspondante (insensible à la casse)
                const referencedEntity = model.entities.find((e: Entity) => 
                    e.name.toLowerCase() === entityName.toLowerCase()
                );
                
                if (referencedEntity) {
                    foreignKeys.push(
                        `ALTER TABLE ${entity.name.toUpperCase()}P ADD CONSTRAINT FK_${entity.name.toUpperCase()}_${field.name.toUpperCase()} ` +
                        `FOREIGN KEY (${field.name.toUpperCase()}) REFERENCES ${referencedEntity.name.toUpperCase()}P (ID);`
                    );
                    
                    // Ajouter un index sur la clé étrangère pour les performances
                    foreignKeys.push(
                        `CREATE INDEX ${entity.name.toUpperCase()}P_${field.name.toUpperCase()}_IDX ON ${entity.name.toUpperCase()}P (${field.name.toUpperCase()});`
                    );
                }
            }
        });
        
        return foreignKeys.length > 0 ? foreignKeys.join('\n') + '\n' : '';
    });

    Handlebars.registerHelper('toSqlType', function (typeDef: TypeDefinition) {
        // Le helper reçoit maintenant l'objet TypeDefinition complet
        switch (typeDef.typeName) {
            case 'String':
                // On vérifie si un argument (la longueur) a été fourni
                if (typeDef.args && typeDef.args.length > 0) {
                    const length = typeDef.args[0];
                    return `VARCHAR(${length})`;
                } else {
                    return 'VARCHAR(256)'; // Valeur par défaut si pas de longueur
                }
            case 'Int':
                return 'INTEGER';
            case 'Date':
                return 'DATE';
            case 'Boolean':
                return 'CHAR(1)';
            case 'Decimal':
                // Pour Decimal, on s'attend à avoir precision et scale
                if (typeDef.precision !== undefined && typeDef.scale !== undefined) {
                    return `DECIMAL(${typeDef.precision},${typeDef.scale})`;
                } else {
                    return 'DECIMAL(15,2)'; // Valeur par défaut
                }
            default:
                // Pour les types personnalisés (struct, enum, entity references)
                return 'VARCHAR(256)'; // Fallback
        }
    });

    // Helpers pour la génération RPG
    Handlebars.registerHelper('toRpgType', function (typeDef: TypeDefinition, options: any) {
        const enums = options.data.root.enums || [];
        
        switch (typeDef.typeName) {
            case 'String':
                if (typeDef.args && typeDef.args.length > 0) {
                    const length = typeDef.args[0];
                    return `VARCHAR(${length})`;
                } else {
                    return 'VARCHAR(256)';
                }
            case 'Int':
                return 'INT(10)';
            case 'Date':
                return 'DATE';
            case 'Boolean':
                return 'IND';
            case 'Decimal':
                if (typeDef.precision !== undefined && typeDef.scale !== undefined) {
                    return `PACKED(${typeDef.precision}:${typeDef.scale})`;
                } else {
                    return 'PACKED(15:2)';
                }
            default:
                // Vérifier si c'est un enum
                const isEnum = enums.some((e: any) => e.name === typeDef.typeName);
                if (isEnum) {
                    return 'VARCHAR(20)'; // Les enums sont stockés comme VARCHAR
                }
                // Pour les autres types personnalisés (struct, entity references)
                return `LIKEDS(${typeDef.typeName}_t)`;
        }
    });

    Handlebars.registerHelper('rpgFieldConstraints', function (field: Field) {
        let constraints = [];
        
        // INZ (initialisation) pour les valeurs par défaut
        if (field.default && field.default.value) {
            const defaultVal = field.default.value;
            if (defaultVal.stringValue) {
                constraints.push(`INZ('${defaultVal.stringValue.replace(/['"]/g, '')}')`);
            } else if (defaultVal.numberValue !== undefined) {
                constraints.push(`INZ(${defaultVal.numberValue})`);
            } else if (defaultVal.booleanValue) {
                // Pour RPG, garder la valeur textuelle true/false comme dans le DSL
                constraints.push(`INZ('${defaultVal.booleanValue}')`);
            } else if (defaultVal.enumValue) {
                constraints.push(`INZ('${defaultVal.enumValue}')`);
            }
        } else if (field.type.typeName === 'Boolean') {
            // Valeur par défaut pour Boolean si pas spécifiée
            constraints.push(`INZ('N')`);
        }
        
        return constraints.length > 0 ? ' ' + constraints.join(' ') : '';
    });

    Handlebars.registerHelper('eq', function (a, b) {
        return a === b;
    });

    Handlebars.registerHelper('or', function (a, b) {
        return a || b;
    });

    // Helper pour générer les déclarations DCL-ENUM
    Handlebars.registerHelper('generateEnumDeclarations', function (enums: any[]) {
        if (!enums || enums.length === 0) return '';
        
        return enums.map(enumDef => {
            const enumName = enumDef.name.toLowerCase();
            const values = enumDef.values.map((val: any) => `  ${val.name} '${val.name}';`).join('\n');
            return `dcl-enum ${enumName} qualified;\n${values}\nend-enum;`;
        }).join('\n\n');
    });
}

export function generateCode(model: Model, filePath: string, destination: string | undefined): string {
    const data = extractDestinationAndName(filePath, destination);
    
    // 1. Générer les artefacts pour chaque entité individuellement
    for (const entity of model.entities) {
        // Générer le copybook RPG pour cette entité
        const rpgContent = generateRpgCopybook(entity, model, filePath);
        
        // Déterminer le chemin de sortie pour l'entité
        const entityFolderName = entity.name.toLowerCase();
        const entityDir = path.join(data.destination, entityFolderName);
        
        // S'assurer que le répertoire de l'entité existe
        if (!fs.existsSync(entityDir)) {
            fs.mkdirSync(entityDir, { recursive: true });
        }
        
        // Le chemin final du copybook RPG
        const rpgOutputPath = path.join(entityDir, `${entity.name}_H.rpgleinc`);

        // Écrire le copybook RPG
        fs.writeFileSync(rpgOutputPath, rpgContent);
        console.log(`Generated RPG copybook for ${entity.name} at: ${rpgOutputPath}`);
    }
    
    // 2. Générer le fichier SQL global
    const generatedFilePath = `${path.join(data.destination, data.name)}.sql`;
    const generatedSql = generateSqlFromTemplate(model);
    
    // Ensure the destination directory exists
    if (!fs.existsSync(data.destination)) {
        fs.mkdirSync(data.destination, { recursive: true });
    }
    
    fs.writeFileSync(generatedFilePath, generatedSql);
    console.log(`Generated SQL at: ${generatedFilePath}`);
    
    return generatedFilePath;
}

export function generateSqlFromTemplate(model: Model): string {
    // Obtenir le chemin du répertoire actuel de manière compatible ES Modules
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    
    // Charger le template depuis le disque
    const templatePath = path.join(__dirname, '../templates/schema.sql.tpl');
    const templateSource = fs.readFileSync(templatePath, 'utf-8');

    // Enregistrer nos helpers personnalisés
    registerHandlebarsHelpers();

    // Compiler le template
    const compiledTemplate = Handlebars.compile(templateSource);

    // Appliquer le modèle de données (notre AST) au template
    const sql = compiledTemplate(model);
    
    return sql;
}

// Nouvelle fonction pour générer les copybooks RPG
export function generateRpgCopybook(entity: Entity, model: Model, sourceFile: string): string {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    
    // Enregistrer les helpers nécessaires
    registerHandlebarsHelpers();
    
    // Charger le template RPG
    const templatePath = path.join(__dirname, '../templates/copybook.rpg.tpl');
    const templateSource = fs.readFileSync(templatePath, 'utf-8');
    
    // Préparer le contexte pour le template
    const context = {
        ...entity,
        sourceFile: path.basename(sourceFile),
        generationDate: new Date().toISOString().split('T')[0],
        structs: model.structs || [],
        enums: model.enums || []
    };
    
    // Compiler et appliquer le template
    const compiledTemplate = Handlebars.compile(templateSource);
    const rpgCode = compiledTemplate(context);
    
    return rpgCode;
}
