**free
ctl-opt nomain option(*nodebugio:*srcstmt:*nounref) alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');

/include 'ciws.rpgleinc'
/include 'ckool.rpgleinc'

// ------------------------------------------------------------
// Prototypes privés
// ------------------------------------------------------------


// ------------------------------------------------------------
// API publique
// ------------------------------------------------------------
dcl-proc CIWS_initRestRequest export;
  dcl-pi *n ind;
    supportedFields likeDS(CMAGIC_supportedFields) const;
    context         likeDS(CMAGIC_context);
    errors          likeDS(GLOBAL_listError);
  end-pi;

  dcl-s queryString varchar(CIWS_MAX_QUERY_STRING);

  clear context;
  clear errors;

  context.pagination.numPage = 1;
  context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;

  queryString = CIWS_getQueryString();
  context = CIWS_parseQueryParams(queryString : supportedFields);

  if context.pagination.numPage < 1;
     context.pagination.numPage = 1;
  endif;

  if context.pagination.perPage < 1;
     context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
  endif;

  if context.pagination.perPage > 100;
     context.pagination.perPage = 100;
  endif;

  return *on;
end-proc;

// ------------------------------------------------------------
// Procédures privées
// ------------------------------------------------------------
dcl-proc CIWS_getQueryString;
  dcl-pi *n varchar(CIWS_MAX_QUERY_STRING);
  end-pi;

  dcl-pr getenv pointer extproc('getenv');
    pName pointer value options(*string);
  end-pr;

  dcl-s p pointer;
  dcl-s result varchar(CIWS_MAX_QUERY_STRING);

  clear result;
  p = getenv('QUERY_STRING');

  if p <> *null;
     result = %str(p);
  endif;

  return %trimr(result);
end-proc;

dcl-proc CIWS_parseQueryParams;
  dcl-pi *n likeDS(CMAGIC_context);
    queryString     varchar(CIWS_MAX_QUERY_STRING) const;
    supportedFields likeDS(CMAGIC_supportedFields) const;
  end-pi;

  dcl-ds context likeDS(CMAGIC_context) inz;
  dcl-ds fieldCfg likeDS(CMAGIC_supportedField) inz;

  dcl-s value       varchar(CIWS_MAX_PARAM_VALUE);
  dcl-s baseField   varchar(32);
  dcl-s sortField   varchar(100);
  dcl-s sortOrder   varchar(10);
  dcl-s filterIndex int(10) inz(1);
  dcl-s sortIndex   int(10) inz(1);
  dcl-s i           int(10);

  clear context;
  context.pagination.numPage = 1;
  context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;

  // Pagination
  value = CIWS_getQueryParameter(queryString : 'page');
  if %len(%trim(value)) > 0;
     monitor;
        context.pagination.numPage = %int(%trim(value));
     on-error;
        context.pagination.numPage = 1;
     endmon;
  endif;

  value = CIWS_getQueryParameter(queryString : 'perPage');
  if %len(%trim(value)) = 0;
     value = CIWS_getQueryParameter(queryString : 'perpage');
  endif;
  if %len(%trim(value)) = 0;
     value = CIWS_getQueryParameter(queryString : 'limit');
  endif;

  if %len(%trim(value)) > 0;
     monitor;
        context.pagination.perPage = %int(%trim(value));
     on-error;
        context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
     endmon;
  endif;

  // Tri principal
  sortField = CIWS_getQueryParameter(queryString : 'sort');
  sortOrder = CIWS_getQueryParameter(queryString : 'order');

  if %len(%trim(sortField)) > 0;
     context.sort(sortIndex).field = %trim(sortField);
     if %upper(%trim(sortOrder)) = 'DESC';
        context.sort(sortIndex).order = 'DESC';
     else;
        context.sort(sortIndex).order = 'ASC';
     endif;
     sortIndex += 1;
  endif;

  // Tris additionnels
  for i = 1 to 4;
     sortField = CIWS_getQueryParameter(queryString : 'sort' + %char(i));
     sortOrder = CIWS_getQueryParameter(queryString : 'order' + %char(i));

     if %len(%trim(sortField)) > 0 and sortIndex <= %elem(context.sort);
        context.sort(sortIndex).field = %trim(sortField);
        if %upper(%trim(sortOrder)) = 'DESC';
           context.sort(sortIndex).order = 'DESC';
        else;
           context.sort(sortIndex).order = 'ASC';
        endif;
        sortIndex += 1;
     endif;
  endfor;

  // Filtres dynamiques selon supportedFields
  for-each fieldCfg in supportedFields.supportedFields;
     if %len(%trim(fieldCfg.name)) = 0;
        leave;
     endif;

     baseField = %trim(fieldCfg.name);

     value = CIWS_getQueryParameter(queryString : baseField);
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_EQUAL;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_like');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_LIKE;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_gte');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_GREATER_EQUAL;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_lte');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_LESS_EQUAL;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_ne');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_NOT_EQUAL;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_gt');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_GREATER;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;

     value = CIWS_getQueryParameter(queryString : baseField + '_lt');
     if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
        context.filter(filterIndex).field    = baseField;
        context.filter(filterIndex).operator = CMAGIC_OP_LESS;
        context.filter(filterIndex).value    = %trim(value);
        filterIndex += 1;
     endif;
  endfor;

  // Recherche générale
  value = CIWS_getQueryParameter(queryString : 'q');
  if %len(%trim(value)) > 0 and filterIndex <= %elem(context.filter);
     context.filter(filterIndex).field    = 'q';
     context.filter(filterIndex).operator = CMAGIC_OP_LIKE;
     context.filter(filterIndex).value    = %trim(value);
  endif;

  return context;
end-proc;

dcl-proc CIWS_getQueryParameter;
  dcl-pi *n varchar(CIWS_MAX_PARAM_VALUE);
    queryString varchar(CIWS_MAX_QUERY_STRING) const;
    name        varchar(CIWS_MAX_PARAM_NAME) const;
  end-pi;

  dcl-s startPos int(10) inz(1);
  dcl-s ampPos   int(10);
  dcl-s eqPos    int(10);
  dcl-s token    varchar(CIWS_MAX_QUERY_STRING);
  dcl-s rawName  varchar(CIWS_MAX_PARAM_NAME);
  dcl-s rawValue varchar(CIWS_MAX_PARAM_VALUE);

  dow startPos <= %len(%trimr(queryString));
     ampPos = %scan('&' : queryString : startPos);

     if ampPos = 0;
        token = %subst(queryString : startPos);
        startPos = %len(%trimr(queryString)) + 1;
     else;
        token = %subst(queryString : startPos : ampPos - startPos);
        startPos = ampPos + 1;
     endif;

     eqPos = %scan('=' : token);
     if eqPos > 0;
        rawName  = CIWS_urlDecode(%subst(token : 1 : eqPos - 1));
        rawValue = CIWS_urlDecode(%subst(token : eqPos + 1));
     else;
        rawName  = CIWS_urlDecode(token);
        rawValue = '';
     endif;

     if %lower(%trim(rawName)) = %lower(%trim(name));
        return %trim(rawValue);
     endif;
  enddo;

  return '';
end-proc;
dcl-proc CIWS_urlDecode;
  dcl-pi *n varchar(CIWS_MAX_QUERY_STRING);
    value varchar(CIWS_MAX_QUERY_STRING) const;
  end-pi;

  dcl-s work    varchar(CIWS_MAX_QUERY_STRING);
  dcl-s decoded varchar(CIWS_MAX_QUERY_STRING);
  dcl-s pos     int(10);

  work = value;

  // Query string classique: '+' représente un espace
  dow %scan('+' : work) > 0;
     pos = %scan('+' : work);
     %subst(work : pos : 1) = ' ';
  enddo;

  exec sql
     values URL_DECODE(:value)
     into :decoded;

  return decoded;
end-proc;

