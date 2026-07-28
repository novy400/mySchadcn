grammar Cmagic

// Le point d'entrée contient les contrats de données et les serveurs applicatifs.
entry Model:
    (
        entities+=Entity
        | structs+=Struct
        | enums+=Enum
        | views+=View
        | operations+=Operations
        | servers+=IleasticServer
    )*;

// Une Entité a un nom et une liste de champs.
Entity:
    'entity' name=ID
    ('resource' resourceName=STRING)?
    ('table' tableName=STRING)?
    ('ileasticObject' ileasticObjectName=STRING)?
    '{'
        (fields+=Field (',')?)*
    '}';

// Un serveur ILEastic agrège les routes de plusieurs entités catalogue.
IleasticServer:
    'server' name=ID
    'object' objectName=STRING
    'port' port=NUMBER
    ('host' host=STRING)?
    '{'
        (entities+=[Entity:ID] (',' entities+=[Entity:ID])*)?
    '}';

// Une Structure (réutilisable) a un nom et une liste de champs.
Struct:
    'struct' name=ID '{'
        (fields+=Field (',')?)*
    '}';

// Une Énumération a un nom et une liste de valeurs.
Enum:
    'enum' name=ID '{'
        (values+=EnumValue (',' values+=EnumValue)*)?
    '}';

// Une valeur d'énumération avec commentaire optionnel.
EnumValue:
    name=ID;

// Une Vue définit une projection d'une entité.
View:
    'view' name=ID 'for' entity=[Entity:ID] '{'
        (fields+=ID (',' fields+=ID)*)?
    '}';

// Un bloc Operations définit les opérations disponibles pour une entité.
Operations:
    'operations' 'for' entity=[Entity:ID] '{'
        (operations+=OperationType (',' operations+=OperationType)*)?
    '}';

// Types d'opérations supportées.
OperationType returns string:
    'CREATE' | 'CHANGE' | 'UPDATE' | 'DELETE' | 'DISPLAY' | 'GET' | 'SEARCH' | 'LIST';

// Un Champ a un nom, une définition de type et des modifieurs optionnels.
Field:
    name=ID ':' type=TypeDefinition
    ('column' columnName=STRING)?
    (key?='key')?
    (required?='required')?
    (unique?='unique')?
    (searchable?='searchable')?
    (sortable?='sortable')?
    (filter=FilterDefinition)?
    (default=DefaultValue)?;

// Opérateurs autorisés pour un filtre exposé par le catalogue.
FilterDefinition:
    'filter' '(' operators+=FilterOperator (',' operators+=FilterOperator)* ')';

FilterOperator returns string:
    'EQ' | 'NE' | 'LIKE' | 'GTE' | 'LTE' | 'GT' | 'LT';

// Valeur par défaut.
DefaultValue:
    'default' '(' value=DefaultValueLiteral ')';

// Valeurs littérales pour les défauts.
DefaultValueLiteral:
    stringValue=STRING | numberValue=NUMBER | booleanValue=BOOLEAN | enumValue=ID;

// Définition de type étendue.
TypeDefinition:
    // Types primitifs avec arguments optionnels
    (typeName=('String' | 'Int' | 'Date' | 'Boolean') ('(' args+=NUMBER (',' args+=NUMBER)* ')')?) |
    // Type Decimal avec précision et échelle obligatoires
    (typeName='Decimal' '(' precision=NUMBER ',' scale=NUMBER ')') |
    // Référence à une structure ou entité
    typeName=ID;

// --- Terminaux ---
hidden terminal WS: /\s+/;
terminal ID: /[_a-zA-Z][\w_]*/;
terminal NUMBER returns number: /[0-9]+(\.[0-9]+)?/;
terminal STRING: /"[^"]*"|'[^']*'/;
terminal BOOLEAN: /'true'|'false'|'TRUE'|'FALSE'/;
hidden terminal SL_COMMENT: /\/\/.*/;
hidden terminal ML_COMMENT: /\/\*[^*]*\*+([^/*][^*]*\*+)*\//;
