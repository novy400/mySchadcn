// Imports removed as they were unused

// Fonction helper pour décomposer les champs avec des structures
export function expandFieldsForSqlHelper(entity: any, structs: any[]): any[] {
    if (!entity || !entity.fields) return [];

    const expandedFields: any[] = [];

    entity.fields.forEach((field: any) => {
        // Vérifier si le type du champ est une structure
        const struct = structs?.find((s: any) => s.name === field.type.typeName);

        if (struct) {
            // C'est une structure, décomposer ses champs
            struct.fields.forEach((subField: any) => {
                expandedFields.push({
                    name: `${field.name}_${subField.name}`,
                    type: subField.type,
                    // Pour les structures : seuls les sous-champs explicitly requis sont requis
                    required: subField.required || false,
                    // Unique seulement si explicitement défini
                    unique: field.unique || subField.unique,
                    // Utiliser la valeur par défaut du sous-champ en priorité
                    defaultValue: subField.defaultValue || field.defaultValue,
                    default: subField.default || field.default, // Pour compatibilité avec fieldConstraints
                    sqlColumnName: `${field.name.toUpperCase()}_${subField.name.toUpperCase()}`
                });
            });
        } else {
            // Champ simple, garder tel quel
            expandedFields.push({
                ...field,
                sqlColumnName: field.name.toUpperCase()
            });
        }
    });

    return expandedFields;
}
