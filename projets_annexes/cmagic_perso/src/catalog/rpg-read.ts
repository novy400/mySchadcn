import type {
    CatalogFieldSpec,
    CatalogFieldType,
    CatalogFilterOperator,
    CatalogSpec
} from './catalog-spec.js';

const sqlIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_$#@]*$/;

const assertSqlIdentifier = (identifier: string): void => {
    const parts = identifier.split('.');
    if (
        parts.length > 2 ||
        parts.some(part => !sqlIdentifierPattern.test(part))
    ) {
        throw new Error(`Unsafe SQL identifier: ${identifier}`);
    }
};

const rpgName = (name: string): string =>
    `${name.charAt(0).toUpperCase()}${name.slice(1)}`;

const rpgType = (type: CatalogFieldType): string => {
    switch (type.kind) {
        case 'string':
            return `varchar(${type.length ?? 256})`;
        case 'integer':
            return 'int(20)';
        case 'decimal':
            return `packed(${type.precision}:${type.scale})`;
        case 'date':
            return 'date';
        case 'boolean':
            return 'ind';
        case 'enum':
            return `varchar(${Math.max(1, ...type.values.map(value => value.length))})`;
    }
};

const sqlDefault = (type: CatalogFieldType): string => {
    switch (type.kind) {
        case 'string':
        case 'enum':
            return "''";
        case 'integer':
        case 'decimal':
            return '0';
        case 'date':
            return "DATE('0001-01-01')";
        case 'boolean':
            return 'FALSE';
    }
};

const selectExpression = (field: CatalogFieldSpec): string =>
    field.required
        ? field.column
        : `COALESCE(${field.column}, ${sqlDefault(field.type)})`;

const sqlOperator: Record<CatalogFilterOperator, string> = {
    eq: '=',
    ne: '<>',
    like: 'LIKE',
    gte: '>=',
    lte: '<=',
    gt: '>',
    lt: '<'
};

const operatorCondition: Record<CatalogFilterOperator, string> = {
    eq: "(%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=')",
    ne: "(%upper(%trim(lFilter.operator)) = 'NE' or %trim(lFilter.operator) = '<>')",
    like: "%upper(%trim(lFilter.operator)) = 'LIKE'",
    gte: "(%upper(%trim(lFilter.operator)) = 'GTE' or %trim(lFilter.operator) = '>=')",
    lte: "(%upper(%trim(lFilter.operator)) = 'LTE' or %trim(lFilter.operator) = '<=')",
    gt: "(%upper(%trim(lFilter.operator)) = 'GT' or %trim(lFilter.operator) = '>')",
    lt: "(%upper(%trim(lFilter.operator)) = 'LT' or %trim(lFilter.operator) = '<')"
};

const filterValueAssignment = (
    entityName: string,
    field: CatalogFieldSpec,
    variable: string
): string[] => {
    switch (field.type.kind) {
        case 'string':
        case 'enum':
            return [`            ${variable} = %trim(lFilter.value);`];
        case 'integer':
            return [
                '          monitor;',
                `            ${variable} = %int(%trim(lFilter.value));`,
                '          on-error;',
                `            ${fieldErrorCall(entityName, field.name, 'Invalid integer value')}`,
                '            return *off;',
                '          endmon;'
            ];
        case 'decimal':
            return [
                '          monitor;',
                `            ${variable} = %dec(%trim(lFilter.value)`,
                `              : ${field.type.precision} : ${field.type.scale});`,
                '          on-error;',
                `            ${fieldErrorCall(entityName, field.name, 'Invalid decimal value')}`,
                '            return *off;',
                '          endmon;'
            ];
        case 'date':
            return [
                '          monitor;',
                `            ${variable} = %date(%trim(lFilter.value) : *ISO);`,
                '          on-error;',
                `            ${fieldErrorCall(entityName, field.name, 'Invalid ISO date')}`,
                '            return *off;',
                '          endmon;'
            ];
        case 'boolean':
            return [
                '          select;',
                "            when %upper(%trim(lFilter.value)) = 'TRUE'",
                "              or %trim(lFilter.value) = '1';",
                `              ${variable} = *on;`,
                "            when %upper(%trim(lFilter.value)) = 'FALSE'",
                "              or %trim(lFilter.value) = '0';",
                `              ${variable} = *off;`,
                '            other;',
                `              ${fieldErrorCall(entityName, field.name, 'Invalid boolean value')}`,
                '              return *off;',
                '          endsl;'
            ];
    }
};

const fieldErrorCall = (
    entityName: string,
    field: string,
    message: string
): string =>
    `${entityName}_reject_query(pErrors : '${field}' : '${message}');`;

const generateFilterDeclarations = (spec: CatalogSpec): string[] =>
    spec.fields.flatMap(field =>
        field.filterOperators.flatMap(operator => {
            const suffix = `${rpgName(field.name)}${rpgName(operator)}`;
            return [
                `  dcl-s lUse${suffix} int(3) inz(0);`,
                `  dcl-s l${suffix} ${rpgType(field.type)} inz;`
            ];
        })
    );

const generateFieldFilterBranch = (
    entityName: string,
    field: CatalogFieldSpec
): string[] => {
    const lines = [`      when %trim(lFilter.field) = '${field.name}';`, '        select;'];

    for (const operator of field.filterOperators) {
        const suffix = `${rpgName(field.name)}${rpgName(operator)}`;
        lines.push(
            `          when ${operatorCondition[operator]};`,
            `            lUse${suffix} = 1;`,
            ...filterValueAssignment(entityName, field, `l${suffix}`)
        );
    }

    lines.push(
        '          other;',
        `            ${fieldErrorCall(entityName, field.name, 'Unsupported filter operator')}`,
        '            return *off;',
        '        endsl;'
    );
    return lines;
};

const generateFilterParsing = (spec: CatalogSpec, entityName: string): string[] => {
    const filterFields = spec.fields.filter(
        field => field.filterOperators.length > 0
    );
    const lines = [
        '  for-each lFilter in pContext.filter;',
        '    if %trim(lFilter.field) = *blanks;',
        '      leave;',
        '    endif;',
        '    select;'
    ];

    if (spec.list && spec.list.searchFields.length > 0) {
        lines.push(
            "      when %trim(lFilter.field) = 'q';",
            "        if %upper(%trim(lFilter.operator)) <> 'LIKE'",
            '          and %trim(lFilter.operator) <> *blanks;',
            `          ${fieldErrorCall(entityName, 'q', 'Unsupported filter operator')}`,
            '          return *off;',
            '        endif;',
            '        lUseQ = 1;',
            "        lQ = '%' + %trim(lFilter.value) + '%';"
        );
    }

    for (const field of filterFields) {
        lines.push(...generateFieldFilterBranch(entityName, field));
    }

    lines.push(
        '      other;',
        `        ${entityName}_reject_query(pErrors : %trim(lFilter.field)`,
        "          : 'Unsupported filter field');",
        '        return *off;',
        '    endsl;',
        '  endfor;'
    );
    return lines;
};

const generateSortParsing = (spec: CatalogSpec, entityName: string): string[] => {
    if (!spec.list) {
        return [];
    }
    const lines = [
        `  lSortField = '${spec.list.defaultSort.field}';`,
        `  lSortOrder = '${spec.list.defaultSort.order}';`,
        '  if %trim(pContext.sort(1).field) <> *blanks;',
        '    select;'
    ];

    for (const field of spec.list.sortFields) {
        lines.push(
            `      when %trim(pContext.sort(1).field) = '${field}';`,
            `        lSortField = '${field}';`
        );
    }

    lines.push(
        '      other;',
        `        ${entityName}_reject_query(pErrors : %trim(pContext.sort(1).field)`,
        "          : 'Unsupported sort field');",
        '        return *off;',
        '    endsl;',
        '  endif;',
        '  if %trim(pContext.sort(1).order) <> *blanks;',
        '    lSortOrder = %upper(%trim(pContext.sort(1).order));',
        "    if lSortOrder <> 'ASC' and lSortOrder <> 'DESC';",
        `      ${entityName}_reject_query(pErrors : 'order'`,
        "        : 'Sort order must be ASC or DESC');",
        '      return *off;',
        '    endif;',
        '  endif;'
    );
    return lines;
};

const generateWhereClause = (spec: CatalogSpec): string[] => {
    const conditions: string[] = [];
    if (spec.list && spec.list.searchFields.length > 0) {
        const search = spec.list.searchFields
            .map(fieldName => {
                const field = spec.fields.find(item => item.name === fieldName);
                return `UPPER(${field?.column}) LIKE UPPER(:lQ)`;
            })
            .join(' OR ');
        conditions.push(`(:lUseQ = 0 OR (${search}))`);
    }

    for (const field of spec.fields) {
        for (const operator of field.filterOperators) {
            const suffix = `${rpgName(field.name)}${rpgName(operator)}`;
            conditions.push(
                `(:lUse${suffix} = 0 OR ${field.column} ${sqlOperator[operator]} :l${suffix})`
            );
        }
    }

    if (conditions.length === 0) {
        return [];
    }
    return conditions.map((condition, index) =>
        `${index === 0 ? '    WHERE' : '      AND'} ${condition}`
    );
};

const generateOrderBy = (spec: CatalogSpec): string[] => {
    if (!spec.list) {
        return [];
    }
    const fieldsByName = new Map(spec.fields.map(field => [field.name, field]));
    const clauses: string[] = [];

    for (const fieldName of spec.list.sortFields) {
        const column = fieldsByName.get(fieldName)?.column;
        clauses.push(
            `CASE WHEN :lSortField = '${fieldName}' AND :lSortOrder = 'ASC' THEN ${column} END ASC`,
            `CASE WHEN :lSortField = '${fieldName}' AND :lSortOrder = 'DESC' THEN ${column} END DESC`
        );
    }
    clauses.push(`${fieldsByName.get(spec.identifier)?.column} ASC`);

    return clauses.map((clause, index) =>
        `${index === 0 ? '    ORDER BY' : '      ,'} ${clause}`
    );
};

const generateRowStructure = (
    structureName: string,
    fields: CatalogFieldSpec[]
): string[] => [
    `dcl-ds ${structureName} qualified template;`,
    ...fields.map(
        field => `  ${field.name.toLowerCase()} ${rpgType(field.type)};`
    ),
    'end-ds;'
];

const generateListProcedure = (
    spec: CatalogSpec,
    entityName: string,
    selectList: string,
    whereClause: string[],
    orderBy: string[]
): string[] => [
    `dcl-proc ${entityName}_list export;`,
    '  dcl-pi *n ind;',
    '    pContext likeDS(CMAGIC_context) const;',
    '    pTotalCount like(CMAGIC_totalCount);',
    '    pItems pointer;',
    '    pErrors likeDS(GLOBAL_listError);',
    '  end-pi;',
    `  dcl-ds lRow likeDS(${entityName}_item_t) inz;`,
    '  dcl-ds lFilter likeDS(CMAGIC_filter) inz;',
    '  dcl-s lItems pointer inz;',
    '  dcl-s lWindowTotal like(CMAGIC_totalCount) inz(0);',
    '  dcl-s lPage int(10) inz(1);',
    '  dcl-s lPerPage int(10) inz(CMAGIC_DEFAULT_LIMIT);',
    '  dcl-s lOffset int(20) inz(0);',
    '  dcl-s lSortField varchar(32) inz;',
    '  dcl-s lSortOrder char(4) inz;',
    '  dcl-s lUseQ int(3) inz(0);',
    '  dcl-s lQ varchar(100) inz;',
    ...generateFilterDeclarations(spec),
    '',
    '  clear pTotalCount;',
    '  clear pItems;',
    '  clear pErrors;',
    '  lPage = pContext.pagination.numPage;',
    '  lPerPage = pContext.pagination.perPage;',
    '  if lPage < 1;',
    '    lPage = 1;',
    '  endif;',
    '  if lPerPage < 1;',
    '    lPerPage = CMAGIC_DEFAULT_LIMIT;',
    '  endif;',
    '  lOffset = (lPage - 1) * lPerPage;',
    '',
    ...generateSortParsing(spec, entityName),
    '',
    ...generateFilterParsing(spec, entityName),
    '',
    '  lItems = list_create();',
    '  exec sql declare CATALOG_LIST cursor for',
    '    select',
    `      ${selectList},`,
    '      COUNT(*) OVER()',
    `    FROM ${spec.table}`,
    ...whereClause,
    ...orderBy,
    '    OFFSET :lOffset ROWS',
    '    FETCH NEXT :lPerPage ROWS ONLY',
    '    FOR READ ONLY;',
    '',
    '  exec sql open CATALOG_LIST;',
    '  if sqlState <> SQL_OK;',
    `    ${entityName}_reject_query(pErrors : 'sql' : 'Unable to open list cursor');`,
    '    list_dispose(lItems);',
    '    return *off;',
    '  endif;',
    '',
    '  dow sqlState = SQL_OK;',
    '    clear lRow;',
    '    exec sql fetch next from CATALOG_LIST into :lRow, :lWindowTotal;',
    '    if sqlState = SQL_NOT_FOUND;',
    '      leave;',
    '    endif;',
    '    if sqlState <> SQL_OK;',
    `      ${entityName}_reject_query(pErrors : 'sql' : 'Unable to fetch list row');`,
    '      exec sql close CATALOG_LIST;',
    '      list_dispose(lItems);',
    '      return *off;',
    '    endif;',
    '    pTotalCount = lWindowTotal;',
    '    list_add(lItems : %addr(lRow) : %size(lRow));',
    '  enddo;',
    '  exec sql close CATALOG_LIST;',
    '  pItems = lItems;',
    '  return *on;',
    'end-proc;',
    ''
];

const generateGetProcedure = (
    spec: CatalogSpec,
    entityName: string,
    idField: CatalogFieldSpec,
    detailSelectList: string
): string[] => [
    `dcl-proc ${entityName}_get export;`,
    '  dcl-pi *n ind;',
    `    pId ${rpgType(idField.type)} const;`,
    `    pDetail likeDS(${entityName}_detail_t);`,
    '    pErrors likeDS(GLOBAL_listError);',
    '  end-pi;',
    '  clear pDetail;',
    '  clear pErrors;',
    '  exec sql',
    '    select',
    `      ${detailSelectList}`,
    '    into :pDetail',
    `    FROM ${spec.table}`,
    `    WHERE ${idField.column} = :pId`,
    '    fetch first 1 row only;',
    '  if sqlState = SQL_NOT_FOUND;',
    `    ${entityName}_reject_query(pErrors : 'id' : '${spec.entity} not found');`,
    '    return *off;',
    '  endif;',
    '  if sqlState <> SQL_OK;',
    `    ${entityName}_reject_query(pErrors : 'sql' : 'Unable to read ${spec.entity}');`,
    '    return *off;',
    '  endif;',
    '  return *on;',
    'end-proc;',
    ''
];

export const generateRpgReadModule = (spec: CatalogSpec): string => {
    assertSqlIdentifier(spec.table);
    for (const field of spec.fields) {
        assertSqlIdentifier(field.column);
    }

    const entityName = spec.entity.toLowerCase();
    const idField = spec.fields.find(field => field.name === spec.identifier);
    if (!idField) {
        throw new Error(`Catalog identifier not found: ${spec.identifier}`);
    }
    const projectedFields =
        spec.list?.fields.map(fieldName => {
            const field = spec.fields.find(candidate => candidate.name === fieldName);
            if (!field) {
                throw new Error(`Catalog list field not found: ${fieldName}`);
            }
            return field;
        }) ?? spec.fields;
    const selectList = projectedFields
        .map(field => selectExpression(field))
        .join(',\n      ');
    const detailSelectList = spec.fields
        .map(field => selectExpression(field))
        .join(',\n      ');
    const whereClause = generateWhereClause(spec);
    const orderBy = generateOrderBy(spec);

    const lines = [
        '**free',
        '// Generated from CatalogSpec. Do not edit.',
        'ctl-opt nomain option(*srcstmt:*nounref) alwnull(*usrctl);',
        "/include 'cmagic.rpgleinc'",
        "/include 'global.rpgleinc'",
        "/include 'sqlstates.rpginc'",
        "/include 'llist/llist_h.rpgle'",
        '',
        ...(spec.capabilities.includes('list')
            ? generateRowStructure(`${entityName}_item_t`, projectedFields)
            : []),
        ...(spec.capabilities.includes('get')
            ? generateRowStructure(`${entityName}_detail_t`, spec.fields)
            : []),
        '',
        `dcl-proc ${entityName}_sql_options;`,
        '  exec sql set option commit = *none, datfmt = *iso, closqlcsr = *endmod;',
        'end-proc;',
        '',
        `dcl-proc ${entityName}_reject_query;`,
        '  dcl-pi *n;',
        '    pErrors likeDS(GLOBAL_listError);',
        '    pField varchar(32) const;',
        '    pMessage varchar(256) const;',
        '  end-pi;',
        "  pErrors.listError(1).code = 'CAT0001';",
        '  pErrors.listError(1).nomZone = pField;',
        '  pErrors.listError(1).text = pMessage;',
        '  pErrors.listError(1).textUser = pMessage;',
        'end-proc;',
        '',
        ...(spec.capabilities.includes('list')
              ? generateListProcedure(
                  spec,
                  entityName,
                  selectList,
                  whereClause,
                  orderBy
              )
            : []),
        ...(spec.capabilities.includes('get')
            ? generateGetProcedure(spec, entityName, idField, detailSelectList)
            : [])
    ];

    return lines.join('\n');
};
