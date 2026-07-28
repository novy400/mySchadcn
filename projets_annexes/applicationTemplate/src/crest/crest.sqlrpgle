**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'NOXDB':'ILEASTIC');

/include 'crest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'ileastic/noxdb.rpgleinc'
// ========================================
// CREST - CMAGIC REST Framework
// Fusion de CMAGIC + ILEASTIC pour APIs REST standard IBM i
// ========================================

dcl-proc CREST_initRestRequest export;
  dcl-pi *N ind;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
    response likeds(IL_response);
    context likeDS(CMAGIC_context);
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT CREST_initRestRequest ===');
  
  // 1. Validation Accept header
  if (not validateAcceptHeader(request : response));
    CKOOL_logMessage('CREST_initRestRequest : échec validation Accept header');
    return *OFF;
  endif;
  
  // 2. Parsing centralisé des paramètres de requête
  context = parseQueryParams(request : supportedFields);
  CKOOL_logMessage('CREST_initRestRequest : parsing avec supportedFields');
  
  CKOOL_logMessage('=== FIN CREST_initRestRequest - Succès ===');
  return *ON;
end-proc;

dcl-proc CREST_initSimpleRestRequest export;
  dcl-pi *N ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT CREST_initSimpleRestRequest ===');
  
  // Validation Accept header uniquement
  if (not validateAcceptHeader(request : response));
    CKOOL_logMessage('CREST_initSimpleRestRequest : échec validation Accept header');
    return *OFF;
  endif;
  
  CKOOL_logMessage('=== FIN CREST_initSimpleRestRequest - Succès ===');
  return *ON;
end-proc;

dcl-proc CREST_initWriteRestRequest export;
  dcl-pi *N ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT CREST_initWriteRestRequest ===');
  
  // Validation Content-Type header pour les opérations d'écriture
  if (not validateContentType(request : response));
    CKOOL_logMessage('CREST_initWriteRestRequest : échec validation Content-Type header');
    return *OFF;
  endif;
  
  CKOOL_logMessage('=== FIN CREST_initWriteRestRequest - Succès ===');
  return *ON;
end-proc;


dcl-proc CREST_addHeaders export;
  dcl-pi *n;
    response likeds(IL_response);
    totalCount like(CMAGIC_totalCount) const options(*nopass);
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT CREST_addHeaders ===');
  
  // Headers CORS standards - API ILEastic officielle
  il_addHeader(response : 'Access-Control-Allow-Origin' : '*');
  il_addHeader(response : 'Access-Control-Allow-Methods' : 'GET, POST, PUT, DELETE, OPTIONS');
  il_addHeader(response : 'Access-Control-Allow-Headers' : 'Content-Type, Authorization');
  
  // Header X-Total-Count OBLIGATOIRE pour collections
  if (%parms() >= 2);
    il_addHeader(response : 'X-Total-Count' : %char(totalCount));
    il_addHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
    CKOOL_logMessage('X-Total-Count ajouté: ' + %char(totalCount));
  endif;
  
  CKOOL_logMessage('=== FIN CREST_addHeaders ===');
end-proc;

dcl-proc CREST_errorsToJson export;
  dcl-pi *n varchar(2048);
    errors likeds(GLOBAL_listError) const;
  end-pi;
  
  dcl-s json varchar(2048);
  dcl-ds lErrors likeds(GLOBAL_listError);
  dcl-ds lError likeds(errorItem);
  dcl-s first ind inz(*on);
  
  clear lErrors;
  lErrors = errors;
  json = '{"errors":[';
  
  for-each lError in lErrors.listError;
    if lError.text = *blanks;
      leave;
    endif;
    
    if (not first);
      json += ',';
    endif;
    
    json += '{';
    json += '"code":"' + escapeString(%trim(lError.code)) + '",';
    json += '"zone":"' + escapeString(%trim(lError.nomZone)) + '",';
    json += '"valeur":"' + escapeString(%trim(lError.valeur)) + '",';
    json += '"texte":"' + escapeString(%trim(lError.text)) + '",';
    json += '"texteUser":"' + escapeString(%trim(lError.textUser)) + '"';
    json += '}';
    
    first = *off;
  endfor;
  
  json += ']}';
  return json;
end-proc;

dcl-proc CREST_errorsToReactAdmin export;
  dcl-pi *n pointer;
    pErrors likeds(GLOBAL_listError) const;
  end-pi;

  dcl-s lJsonRoot  pointer;
  dcl-s lJsonErrors pointer;
  dcl-s i          int(10);
  dcl-s lKey       varchar(100);
  dcl-s lMsg       varchar(256);
  dcl-ds lErrors likeds(GLOBAL_listError);
  dcl-ds lError likeds(errorItem);
  // initialisation 
  clear lErrors;
  lErrors = pErrors;
  // 1. Création de l'objet racine
  lJsonRoot = json_newObject();
  
  // 2. Ajout du message global (requis par certains dataProviders)
  json_setStr(lJsonRoot : 'message' : 'Erreur de validation des données');

  // 3. Création de l'objet "errors" (Map Clé/Valeur)
  lJsonErrors = json_newObject();

  // 4. Boucle sur ta liste d'erreurs interne
  sorta(D) lErrors.listError(*).nomZone;
  for-each lError in lErrors.listError;
    if lError.nomZone = *blanks;
      leave;  
    endif;
    // IMPORTANT : On utilise 'nomZone' comme CLÉ JSON
    // Cela suppose que 'nomZone' contient exactement le 'source' React-Admin (ex: 'address.ville')
    lKey = %trim(lError.nomZone);
    lMsg = %trim(lError.textUser);

    // Sécurité : si pas de nom de zone, on ne peut pas l'attacher à un champ
    If lKey <> *Blanks;
       json_setStr(lJsonErrors : lKey : lMsg);
    Endif;
   endfor;

  // 5. Attachement de l'objet errors à la racine
  json_MoveObjectInto(lJsonRoot : 'errors' : lJsonErrors);

  Return lJsonRoot;

end-proc;

dcl-proc CREST_simpleError export;
  dcl-pi *n varchar(1000);
    errorMessage varchar(500) const;
  end-pi;
  
  dcl-s json varchar(1000);
  
  json = '{"message":"' + escapeString(%trim(errorMessage)) + '"}';
  
  return json;
end-proc;


// ================================================================
// PROCÉDURES INTERNES SPÉCIALISÉES
// ================================================================


///
// Setup pagination parameters from HTTP request
//
// Extracts pagination parameters from HTTP request and populates 
// the CMAGIC context pagination structure with validated values.
// Supports both React Admin formats: simple REST (page/perPage) 
// and classic (_page/_limit).
///
dcl-proc setupPagination;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  dcl-ds lRequest likeDS(request);    
  dcl-s pageParam varchar(10);
  dcl-s limitParam varchar(10);
  
  // Initialisation.
  CKOOL_logMessage('=== DÉBUT setupPagination ===');
  clear lRequest;
  lRequest = request;
 
  // Valeurs par défaut CMAGIC
  context.pagination.numPage = 1;
  context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
  
  // Traitement.
  // 1. Format simple REST (priorité)
  pageParam = il_getQueryParameter(lRequest : 'page' : '');
  limitParam = il_getQueryParameter(lRequest : 'perPage' : '');
  
  if (%len(%trim(pageParam)) > 0 or %len(%trim(limitParam)) > 0);
    CKOOL_logMessage('Format simple REST détecté');
    monitor;
      if (%len(%trim(pageParam)) > 0);
        context.pagination.numPage = %int(%trim(pageParam));
        CKOOL_logMessage('page = ' + %trim(pageParam));
      endif;
      if (%len(%trim(limitParam)) > 0);
        context.pagination.perPage = %int(%trim(limitParam));
        CKOOL_logMessage('perPage = ' + %trim(limitParam));
      endif;
    on-error;
      CKOOL_logMessage('Erreur conversion simple REST, valeurs par défaut');
      context.pagination.numPage = 1;
      context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
    endmon;
  else;
    // 2. Format classique React Admin
    pageParam = il_getQueryParameter(lRequest : '_page' : '');
    limitParam = il_getQueryParameter(lRequest : '_limit' : '');
    
    monitor;
      if (%len(%trim(pageParam)) > 0);
        context.pagination.numPage = %int(%trim(pageParam));
        CKOOL_logMessage('_page = ' + %trim(pageParam));
      endif;
      if (%len(%trim(limitParam)) > 0);
        context.pagination.perPage = %int(%trim(limitParam));
        CKOOL_logMessage('_limit = ' + %trim(limitParam));
      endif;
    on-error;
      CKOOL_logMessage('Erreur conversion classique, valeurs par défaut');
      context.pagination.numPage = 1;
      context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
    endmon;
  endif;
  
  // Validation selon constantes CMAGIC
  if (context.pagination.numPage < 1);
    CKOOL_logMessage('Page invalide, correction à 1');
    context.pagination.numPage = 1;
  endif;
  if (context.pagination.perPage < 1);
    context.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
  endif;
  if (context.pagination.perPage > 100);
    CKOOL_logMessage('PerPage trop élevé, limitation à 100');
    context.pagination.perPage = 100;
  endif;
  
  CKOOL_logMessage('=== FIN setupPagination - Page: ' + %char(context.pagination.numPage) + 
                   ' PerPage: ' + %char(context.pagination.perPage) + ' ===');
end-proc;

///
// Setup dynamic filters from HTTP request parameters
//
// Analyzes ILEastic request parameters to detect REST filters and 
// populates the CMAGIC context filter array.
///
dcl-proc setupFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;    
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-s filterIndex int(5) inz(1);
  dcl-s filterValue varchar(100);
  dcl-s baseField varchar(32);
  dcl-s i int(5);
  dcl-s fieldsCount int(5);
  dcl-ds lSupportedField likeDS(CMAGIC_supportedField) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-ds lRequest likeDS(request);
  
  // initialisation 
  CKOOL_logMessage('=== DÉBUT setupFilters ===');
  clear lRequest;
  lRequest = request;
  clear context.filter;
  lSupportedFields = supportedFields;
  
  // traitement
  // tri par name desc 
  SORTA(D) lSupportedFields.supportedFields(*).name;  
  // Parcourir tous les champs supportés
  for-each lSupportedField in lSupportedFields.supportedFields;
    if %len(%trim(lSupportedField.name)) = *zeros;
      leave;
    endif;
    baseField = %trim(lSupportedField.name);
    
    // 1. Filtre simple (égalité)
    filterValue = il_getQueryParameter(lRequest : baseField : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' = ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 2. Filtre LIKE
    filterValue = il_getQueryParameter(lRequest : baseField + '_like' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = 'LIKE';
      context.filter(filterIndex).value = '%' + %trim(filterValue) + '%';
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' LIKE ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 3. Filtre >=
    filterValue = il_getQueryParameter(lRequest : baseField + '_gte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '>=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' >= ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 4. Filtre <=
    filterValue = il_getQueryParameter(lRequest : baseField + '_lte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<=';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' <= ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 5. Filtre <>
    filterValue = il_getQueryParameter(lRequest : baseField + '_ne' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<>';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' <> ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 6. Filtre >
    filterValue = il_getQueryParameter(lRequest : baseField + '_gt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '>';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' > ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 7. Filtre <
    filterValue = il_getQueryParameter(lRequest : baseField + '_lt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = '<';
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre ' + %char(filterIndex) + ': ' + baseField + ' < ' 
        + %trim(filterValue));
      filterIndex += 1;
    endif;
  endfor;
  
  // Gestion de la recherche générale 'q'
  filterValue = il_getQueryParameter(lRequest : 'q' : '');
  if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
    context.filter(filterIndex).field = 'SEARCH';
    context.filter(filterIndex).operator = 'LIKE';
    context.filter(filterIndex).value = '%' + %trim(filterValue) + '%';
    CKOOL_logMessage('Recherche générale: ' + %trim(filterValue));
    filterIndex += 1;
  endif;
  
  CKOOL_logMessage('=== FIN setupFilters - ' + %char(filterIndex - 1) + ' filtres ===');
end-proc;

///
// Setup dynamic sorting from HTTP request parameters
//
// Extracts sorting parameters from request and populates CMAGIC context.
// Supports both React Admin formats.
///
dcl-proc setupSorting;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-s sortField varchar(100);
  dcl-s sortOrder varchar(10);
  dcl-s sortIndex int(5) inz(1);
  dcl-s i int(5);
  dcl-ds lRequest likeDS(request);

  // Initialisation.
  CKOOL_logMessage('=== DÉBUT setupSorting ===');
  clear lRequest;
  lRequest = request;  
  clear context.sort;
  
  // Traitement.
  // Format simple REST (priorité)
  sortField = il_getQueryParameter(lRequest : 'sort' : '');
  sortOrder = il_getQueryParameter(lRequest : 'order' : 'ASC');
  
  // Fallback format classique
  if (%len(%trim(sortField)) = 0);
    sortField = il_getQueryParameter(lRequest : '_sort' : '');
    sortOrder = il_getQueryParameter(lRequest : '_order' : 'ASC');
  endif;
  
  if (%len(%trim(sortField)) > 0);
    context.sort(sortIndex).field = %trim(sortField);
    context.sort(sortIndex).order = %trim(sortOrder);
    CKOOL_logMessage('Tri principal: ' + %trim(sortField) + ' ' + %trim(sortOrder));
    sortIndex = 2;
  endif;
  
  // Tris additionnels pour cas avancés
  // Format: ?sort1=field1&order1=ASC&sort2=field2&order2=DESC
  for i = 1 to 4; // Support jusqu'à 4 tris additionnels
    sortField = il_getQueryParameter(lRequest : 'sort' + %char(i) : '');
    sortOrder = il_getQueryParameter(lRequest : 'order' + %char(i) : 'ASC');
    if (%len(%trim(sortField)) > 0 and sortIndex <= %elem(context.sort));
      context.sort(sortIndex).field = %trim(sortField);
      context.sort(sortIndex).order = %trim(sortOrder);  
      CKOOL_logMessage('Tri ' + %char(i) + ': ' + %trim(sortField) + ' ' 
        + %trim(sortOrder));
      sortIndex += 1;
    endif;
  endfor;
  
  CKOOL_logMessage('=== FIN setupSorting ===');
end-proc;

///
// Setup general search filter from 'q' parameter
//
// Adds a general search filter to context based on 'q' parameter.
///
dcl-proc setupGeneralSearchFilter;
  dcl-pi *n;
    context likeDS(CMAGIC_context);
    searchTerm varchar(100) const;
  end-pi;
  
  dcl-s filterIndex int(5) inz(1);
  
  CKOOL_logMessage('=== DÉBUT setupGeneralSearchFilter ===');
  
  // Find next available filter slot
  for filterIndex = 1 to %elem(context.filter);
    if (%len(%trim(context.filter(filterIndex).field)) = 0);
      context.filter(filterIndex).field = 'SEARCH';
      context.filter(filterIndex).operator = 'LIKE';
      context.filter(filterIndex).value = '%' + %trim(searchTerm) + '%';
      CKOOL_logMessage('Recherche générale ajoutée: ' + %trim(searchTerm));
      leave;
    endif;
  endfor;
  
  CKOOL_logMessage('=== FIN setupGeneralSearchFilter ===');
end-proc;

///
// Set REST error response with proper HTTP status
//
// Sets HTTP status code and error message for REST error responses.
///
dcl-proc setError;
  dcl-pi *n;
    response likeds(IL_response);
    httpStatus int(10) const;
    errorMessage varchar(500) const;
  end-pi;
  
  CKOOL_logMessage('=== DÉBUT setError ===');
  
  response.status = httpStatus;
  response.contentType = IL_MEDIA_TYPE_JSON;
  
  // Add standard headers even for errors
  CREST_addHeaders(response);
  
  // Write error response JSON
  il_responseWrite(response : CREST_simpleError(errorMessage));
  
  CKOOL_logMessage('Erreur REST envoyée: ' + %char(httpStatus) + ' - ' 
    + %trim(errorMessage));
  CKOOL_logMessage('=== FIN setError ===');
end-proc;

// ========================================
// CREST JSON - Utilitaires JSON génériques  
// ========================================

///
// Escape JSON special characters
//
// Escapes special characters in strings for JSON compatibility.
///
dcl-proc escapeString export;
  dcl-pi *n varchar(1000);
    text varchar(1000) const;
  end-pi;
  
  dcl-s escaped varchar(1000);
  dcl-s i int(10);
  dcl-s char varchar(1);
  
  escaped = '';
  for i = 1 to %len(text);
    char = %subst(text : i : 1);
    select;
      when char = '"';
        escaped += '\"';
      when char = '\';
        escaped += '\\';
      when char = x'0A';
        escaped += '\n';
      when char = x'0D';
        escaped += '\r';
      when char = x'09';
        escaped += '\t';
      other;
        escaped += char;
    endsl;
  endfor;
  
  return escaped;
end-proc;

// ========================================
// Procédures de validation REST
// ========================================

///
// Validate Accept header for REST requests
//
// Validates that the request Accept header is compatible with JSON responses.
// Sets appropriate error response if validation fails.
///
dcl-proc validateAcceptHeader;
  dcl-pi *n ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
  end-pi;
  dcl-ds lRequest likeDS(request);  
  dcl-s acceptHeader varchar(200);
  
  // Initialisation.
  CKOOL_logMessage('=== DÉBUT validateAcceptHeader ===');
  clear lRequest;
  lRequest = request;

  // Traitement.
  acceptHeader = il_getRequestHeader(lRequest : 'Accept');
  CKOOL_logMessage('Accept header: ' + %trim(acceptHeader));
  
  // Si pas d'header Accept, on accepte (comportement permissif)
  if (%len(%trim(acceptHeader)) = 0);
    CKOOL_logMessage('Pas d''header Accept, validation OK');
    return *ON;
  endif;
  
  // Vérifier si JSON est accepté
  if (%scan('application/json' : %trim(acceptHeader)) > 0 or
      %scan('*/*' : %trim(acceptHeader)) > 0);
    CKOOL_logMessage('JSON accepté, validation OK');
    return *ON;
  endif;
  
  // Header Accept incompatible
  setError(response : IL_HTTP_NOT_ACCEPTABLE : 'JSON response required');
  CKOOL_logMessage('Header Accept incompatible, erreur 406 envoyée');
  return *OFF;
  
  return *ON;
end-proc;

///
// Validate Content-Type header for REST requests
//
// Validates that the request Content-Type header is compatible with expected type.
// Sets appropriate error response if validation fails.
///
dcl-proc validateContentType;
  dcl-pi *n ind;
    request likeds(IL_request) const;
    response likeds(IL_response);
    expectedType varchar(100) const options(*nopass);
  end-pi;
  dcl-ds lRequest likeDS(request);
  dcl-s contentType varchar(200);
  dcl-s expected varchar(100);
  
  // Initialisation.  
  CKOOL_logMessage('=== DÉBUT validateContentType ===');
  clear lRequest;
  lRequest = request;

  // Traitement.
  // Type attendu par défaut
  if (%parms() >= 3);
    expected = %trim(expectedType);
  else;
    expected = 'application/json';
  endif;
  
  contentType = il_getRequestHeader(lRequest : 'Content-Type');
  CKOOL_logMessage('Content-Type: ' + %trim(contentType));
  CKOOL_logMessage('Expected: ' + %trim(expected));
  
  // Si pas de contenu, pas de validation nécessaire
  if (%len(%trim(il_getRequestContent(lRequest))) = 0);
    CKOOL_logMessage('Pas de contenu, validation OK');
    return *ON;
  endif;
  
  // Vérifier si le type correspond
  if (%len(%trim(contentType)) > 0 and 
      %scan(%trim(expected) : %trim(contentType)) > 0);
    CKOOL_logMessage('Content-Type validé, validation OK'); 
    return *ON;
  endif;
  
  // Content-Type invalide
  setError(response : IL_HTTP_UNSUPPORTED_MEDIA_TYPE : 
                'Content-Type ' + %trim(expected) + ' required');
  CKOOL_logMessage('Content-Type invalide, erreur 415 envoyée');
  return *OFF;
  
  return *ON;
end-proc;

///
// Parse all REST query parameters into CMAGIC context
// Version modulaire avec procédures internes spécialisées
///
dcl-proc parseQueryParams;
  dcl-pi *n likeds(CMAGIC_context);
    request likeds(IL_request) const;
    supportedFields likeDs(CMAGIC_supportedFields) const;
  end-pi;
  
  dcl-ds context likeds(CMAGIC_context) inz;
  
  CKOOL_logMessage('=== DÉBUT parseQueryParams ===');
  
  // 1. Configuration pagination
  setupPagination(request : context);
  
  // 2. Configuration tri
  setupSorting(request : context);
  
  // 3. Configuration filtres (avec ou sans champs supportés)
  setupFilters(request : supportedFields : context );
  CKOOL_logMessage('Filtres configurés avec supportedFields');
  
  CKOOL_logMessage('=== FIN parseQueryParams ===');
  return context;
end-proc;


///
// Configure filters from all query parameters (auto-discovery mode)
// Procédure interne pour mode auto-discovery sans configuration
///
dcl-proc setupAllFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeds(CMAGIC_context);
  end-pi;
  dcl-s lRequest like(request);
  dcl-s searchValue varchar(100);
  
  // Initialisation.
  CKOOL_logMessage('Configuration filtres en mode auto-discovery...');
  clear lRequest;
  lRequest = request;
  clear context.filter;
  
  // Pour l'instant, juste la recherche générale 'q'
  // TODO: Étendre pour auto-discovery complète des paramètres
  searchValue = il_getQueryParameter(lRequest : 'q' : '');
  if (%len(%trim(searchValue)) > 0);
    context.filter(1).field = 'SEARCH';
    context.filter(1).operator = 'LIKE';
    context.filter(1).value = '%' + %trim(searchValue) + '%';
  endif;
  
  CKOOL_logMessage('Mode auto-discovery - filtres basiques configurés');
end-proc;

