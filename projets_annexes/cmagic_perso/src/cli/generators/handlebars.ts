
import Handlebars from 'handlebars';
import type { Field, Entity, TypeDefinition } from '../../language/generated/ast.js';
import { expandFieldsForSqlHelper } from './utils.js';

// Fonction pour enregistrer tous les helpers Handlebars
export function registerHandlebarsHelpers() {

    Handlebars.registerHelper('toUpperCase', function (aString) {
        if (!aString) return '';
        return aString.toUpperCase();
    });

    Handlebars.registerHelper('lowercase', function (aString) {
        return aString && typeof aString === 'string' ? aString.toLowerCase() : '';
    });

    Handlebars.registerHelper('fieldConstraints', function (field: Field) {
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
            } else if (defaultVal.booleanValue !== undefined) {
                // Conversion booléenne: true/false -> Y/N pour SQL
                const boolStr = defaultVal.booleanValue.toString().toLowerCase();
                const boolVal = boolStr === 'true' ? 'Y' : 'N';
                constraints.push(`DEFAULT '${boolVal}'`);
            } else if (defaultVal.enumValue) {
                // IMPORTANT: Les valeurs booléennes sont stockées comme enumValue dans l'AST !
                const enumVal = defaultVal.enumValue as any;
                if (enumVal === 'true' || enumVal === 'false' || enumVal === true || enumVal === false) {
                    // Conversion booléenne: 'true'/'false' ou true/false -> Y/N pour SQL
                    const boolVal = (enumVal === 'true' || enumVal === true) ? 'Y' : 'N';
                    constraints.push(`DEFAULT '${boolVal}'`);
                } else {
                    // C'est une vraie énumération
                    constraints.push(`DEFAULT '${defaultVal.enumValue}'`);
                }
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
        // Gérer le cas où options.data n'est pas disponible
        const enums = (options && options.data && options.data.root && options.data.root.enums) || [];

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
                return `LIKEDS(${typeDef.typeName.toLowerCase()}_t)`;
        }
    });

    // Helper pour les types RPG avec contexte d'entité (pour les structs préfixées)
    Handlebars.registerHelper('toRpgTypeWithEntity', function (typeDef: TypeDefinition, entityName: string, options: any) {
        // Gérer le cas où options.data n'est pas disponible
        const enums = (options && options.data && options.data.root && options.data.root.enums) || [];
        const structs = (options && options.data && options.data.root && options.data.root.structs) || [];

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
                // Vérifier si c'est un struct
                const isStruct = structs.some((s: any) => s.name === typeDef.typeName);
                if (isStruct) {
                    // Prefixer avec le nom de l'entité : customer_address_t
                    return `LIKEDS(${entityName.toLowerCase()}_${typeDef.typeName.toLowerCase()}_t)`;
                }
                // Pour les autres types personnalisés (entity references)
                return `LIKEDS(${typeDef.typeName.toLowerCase()}_t)`;
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
        } else if (defaultVal.booleanValue !== undefined) {
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

    // Helper pour vérifier si un type est une énumération
    Handlebars.registerHelper('isEnum', function (typeName: string, enums: any[]) {
        return enums && enums.some((e: any) => e.name === typeName);
    });

    // Helper pour décomposer les champs avec des structures complexes (pour SQL)
    Handlebars.registerHelper('expandFieldsForSql', function (entity: any, structs: any[]) {
        return expandFieldsForSqlHelper(entity, structs);
    });

    // Helper pour générer la validation dynamique basée sur les champs réels
    Handlebars.registerHelper('generateFieldValidation', function (entity: any, structs: any[]) {
        if (!entity || !entity.fields) return '';

        let validationCode = '';
        let errorCounter = 0;

        entity.fields.forEach((field: any) => {
            const fieldName = field.name;
            const fieldType = field.type.typeName;
            const isRequired = field.required;

            // Validation pour champs required
            if (isRequired) {
                errorCounter++;
                const errorCode = `CUST${String(errorCounter).padStart(3, '0')}`;

                if (fieldType === 'String') {
                    validationCode += `
        // ${fieldName} is mandatory
        if pAfterDetail.detail.${fieldName} = *blanks;
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = '${fieldName} obligatoire !';
          pErrors.listError(it).text = 'Zone obligatoire';
          pErrors.listError(it).nomZone = '${fieldName}';
        endif;`;
                } else if (fieldType === 'Int') {
                    validationCode += `
        // ${fieldName} is mandatory
        if pAfterDetail.detail.${fieldName} <= 0;
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = '${fieldName} obligatoire !';
          pErrors.listError(it).text = 'Zone obligatoire';
          pErrors.listError(it).nomZone = '${fieldName}';
        endif;`;
                } else if (fieldType === 'Date') {
                    validationCode += `
        // ${fieldName} is mandatory
        if pAfterDetail.detail.${fieldName} = d'0001-01-01';
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = '${fieldName} obligatoire !';
          pErrors.listError(it).text = 'Zone obligatoire';
          pErrors.listError(it).nomZone = '${fieldName}';
        endif;`;
                }
            }

            // Validation spécialisée par type de champ
            if (fieldName.toLowerCase().includes('email') && fieldType === 'String') {
                errorCounter++;
                const errorCode = `CUST${String(errorCounter).padStart(3, '0')}`;
                validationCode += `
        // Email format validation
        if pAfterDetail.detail.${fieldName} <> *blanks
           and %scan('@': pAfterDetail.detail.${fieldName}) = 0;
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = 'Format email invalide !';
          pErrors.listError(it).text = 'Format invalide';
          pErrors.listError(it).nomZone = '${fieldName}';
        endif;`;
            }

            if (fieldName.toLowerCase().includes('credit') && fieldType === 'Decimal') {
                errorCounter++;
                const errorCode = `CUST${String(errorCounter).padStart(3, '0')}`;
                validationCode += `
        // Credit limit must be positive or zero
        if pAfterDetail.detail.${fieldName} < 0;
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = 'Limite de crédit doit être positive !';
          pErrors.listError(it).text = 'Valeur invalide';
          pErrors.listError(it).nomZone = '${fieldName}';
        endif;`;
            }

            // Validation pour champs avec structure (Address)
            const struct = structs?.find((s: any) => s.name === fieldType);
            if (struct && isRequired) {
                struct.fields.forEach((subField: any) => {
                    if (subField.required) {
                        errorCounter++;
                        const errorCode = `CUST${String(errorCounter).padStart(3, '0')}`;
                        validationCode += `
        // ${fieldName}.${subField.name} is mandatory
        if pAfterDetail.detail.${fieldName}.${subField.name} = *blanks;
          it += 1;
          pErrors.listError(it).code = '${errorCode}';
          pErrors.listError(it).textUser = '${fieldName}.${subField.name} obligatoire !';
          pErrors.listError(it).text = 'Zone obligatoire';
          pErrors.listError(it).nomZone = '${fieldName}.${subField.name}';
        endif;`;
                    }
                });
            }
        });

        return validationCode;
    });

    // Helper pour générer la validation de suppression
    Handlebars.registerHelper('generateDeleteValidation', function (entity: any) {
        if (!entity) return '';

        const idField = entity.fields.find((f: any) => f.name === 'id');
        if (!idField) return '';

        return `
        // Validation rules for deletion
        // Ensure ID is provided and valid
        if pAfterDetail.detail.id <= 0;
          it += 1;
          pErrors.listError(it).code = 'CUST010';
          pErrors.listError(it).textUser = 'ID invalide pour suppression !';
          pErrors.listError(it).text = 'ID requis';
          pErrors.listError(it).nomZone = 'id';
        endif;`;
    });

    // Nouveaux helpers pour template dynamique

    // Helper pour récupérer les champs d'une structure d'entité
    Handlebars.registerHelper('getStructFields', function (entityName: string, structs: any[]) {
        if (!structs) return [];
        return structs.filter((s: any) => s.entityName === entityName);
    });

    // Helper pour capitaliser une chaîne
    Handlebars.registerHelper('capitalize', function (str: string) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    });

    // Helper pour générer les VALUES SQL dynamiques
    Handlebars.registerHelper('generateSqlValues', function (entity: any, structs: any[]) {
        const expandedFields = expandFieldsForSqlHelper(entity, structs);
        return expandedFields.map(f => {
            if (f.name.includes('_')) {
                // Champ de structure : address_ligne1 -> :lAddress.ligne1
                const parts = f.name.split('_');
                const structName = parts[0];
                const fieldName = parts.slice(1).join('_');
                return `:l${structName.charAt(0).toUpperCase() + structName.slice(1)}.${fieldName}`;
            } else {
                // Champ simple
                return `:lDetail.${f.name}`;
            }
        }).join(', ');
    });

    // Helper pour générer les colonnes SQL dynamiques
    Handlebars.registerHelper('generateSqlColumns', function (entity: any, structs: any[]) {
        const expandedFields = expandFieldsForSqlHelper(entity, structs);
        return expandedFields.map(f => f.sqlColumnName).join(', ');
    });

    // Helper pour générer les déclarations de variables locales
    Handlebars.registerHelper('generateLocalVars', function (entity: any, structs: any[]) {
        if (!structs || !entity) return '';

        // Trouver les structs utilisés par cette entité
        const usedStructs: any[] = [];
        if (entity.fields) {
            entity.fields.forEach((field: any) => {
                const fieldType = field.type?.typeName;
                const struct = structs.find((s: any) => s.name === fieldType);
                if (struct) {
                    usedStructs.push(struct);
                }
            });
        }

        const localVars = usedStructs.map(s =>
            `dcl-ds l${s.name.charAt(0).toUpperCase() + s.name.slice(1)} likeDs(${entity.name.toLowerCase()}_${s.name.toLowerCase()}_t);`
        ).join('\n    ');
        return new Handlebars.SafeString(localVars);
    });

    // Helper pour générer les affectations de structures
    Handlebars.registerHelper('generateStructAssignments', function (entity: any, structs: any[]) {
        if (!structs || !entity) return '';

        // Trouver les structs utilisés par cette entité en analysant les types des champs
        const usedStructs: any[] = [];
        if (entity.fields) {
            entity.fields.forEach((field: any) => {
                const fieldType = field.type?.typeName;
                const struct = structs.find((s: any) => s.name === fieldType);
                if (struct) {
                    usedStructs.push({ ...struct, fieldName: field.name });
                }
            });
        }

        const assignments = usedStructs.map(s =>
            `clear l${s.name.charAt(0).toUpperCase() + s.name.slice(1)};\n    l${s.name.charAt(0).toUpperCase() + s.name.slice(1)} = lDetail.${s.fieldName.toLowerCase()};`
        );
        return new Handlebars.SafeString(assignments.join('\n    '));
    });

    // Helper pour générer le mapping SQL vers RPG
    Handlebars.registerHelper('generateSqlToRpgMapping', function (entity: any, structs: any[]) {
        const expandedFields = expandFieldsForSqlHelper(entity, structs);
        return expandedFields.map(f => {
            if (f.name.includes('_')) {
                // Champ de structure : address_ligne1 -> address.ligne1
                const parts = f.name.split('_');
                const structName = parts[0];
                const fieldName = parts.slice(1).join('_');
                return `pDetail.detail.${structName}.${fieldName} = lDetailSQL.${f.sqlColumnName};`;
            } else {
                // Champ simple
                return `pDetail.detail.${f.name} = lDetailSQL.${f.sqlColumnName};`;
            }
        }).join('\n    ');
    });
}
