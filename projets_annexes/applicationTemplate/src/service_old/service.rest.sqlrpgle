**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include 'service.rpgleinc'
/include 'srvrest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'llist/llist_h.rpgle'


// GET /services - Search with pagination (React Admin compatible)
dcl-proc service_getlist_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s contentType varchar(100);
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s searchTerm varchar(100);
  dcl-s pageParam varchar(10);
  dcl-s perPageParam varchar(10);
  
  // Check Accept header
  contentType = il_getRequestHeader(request : 'Accept');
  if (contentType <> IL_MEDIA_TYPE_JSON and contentType <> IL_MEDIA_TYPE_ALL);
    response.status = IL_HTTP_UNSUPPORTED_MEDIA_TYPE;
    il_responseWrite(response : contentType + ' is not supported');
    return;
  endif;
  
  // React Admin pagination parameters - check both formats
  // Priority: Simple REST format (page/perPage) over classic format (_page/_limit)
  
  // Check if simple REST parameters are provided
  pageParam = il_getQueryParameter(request : 'page' : '');
  perPageParam = il_getQueryParameter(request : 'perPage' : '');
  
  // Debug logging
  CKOOL_logMessage('pageParam: ' + %trim(pageParam));
  CKOOL_logMessage('perPageParam: ' + %trim(perPageParam));
  
  // Initialize with defaults
  lContext.pagination.numPage = 1;
  lContext.pagination.perPage = 10;
  
  if (%len(%trim(pageParam)) > 0 or %len(%trim(perPageParam)) > 0);
    // Use simple REST format with safe conversion
    monitor;
      if (%len(%trim(pageParam)) > 0);
        lContext.pagination.numPage = %int(%trim(pageParam));
      endif;
      if (%len(%trim(perPageParam)) > 0);
        lContext.pagination.perPage = %int(%trim(perPageParam));
      endif;
    on-error;
      CKOOL_logMessage('Error converting pagination parameters, using defaults');
      lContext.pagination.numPage = 1;
      lContext.pagination.perPage = 10;
    endmon;
  else;
    // Fallback to classic React Admin format
    monitor;
      pageParam = il_getQueryParameter(request : '_page' : '1');
      perPageParam = il_getQueryParameter(request : '_limit' : '10');
      lContext.pagination.numPage = %int(%trim(pageParam));
      lContext.pagination.perPage = %int(%trim(perPageParam));
    on-error;
      CKOOL_logMessage('Error converting classic pagination parameters, using defaults');
      lContext.pagination.numPage = 1;
      lContext.pagination.perPage = 10;
    endmon;
  endif;
  
  // Ensure minimum valid values
  if (lContext.pagination.numPage < 1);
    lContext.pagination.numPage = 1;
  endif;
  if (lContext.pagination.perPage < 1);
    lContext.pagination.perPage = 10;
  endif;
  
  // Debug pagination values
  CKOOL_logMessage('Final pagination - Page: ' + %char(lContext.pagination.numPage) + 
                  ' PerPage: ' + %char(lContext.pagination.perPage));
  
  // Dynamic filtering - check for common service fields
  monitor;
    setupFilters(request : lContext);
    CKOOL_logMessage('setupFilters completed');
  on-error;
    CKOOL_logMessage('Error in setupFilters: ' + %trimr(%char(%error)));
    clear lContext.filter; // Clear filters if error
  endmon;
  
  // Search term (for general search) - can be used as additional filter
  searchTerm = il_getQueryParameter(request : 'q' : '');
  if (%len(%trim(searchTerm)) > 0);
    CKOOL_logMessage('Search term: ' + %trim(searchTerm));
    // Add general search as a filter if provided
    monitor;
      setupGeneralSearchFilter(lContext : searchTerm);
      CKOOL_logMessage('setupGeneralSearchFilter completed');
    on-error;
      CKOOL_logMessage('Error in setupGeneralSearchFilter: ' + %trimr(%char(%error)));
    endmon;
  endif;
  
  // Dynamic sorting - React Admin simple REST uses 'sort' and 'order'
  monitor;
    setupSorting(request : lContext);
    CKOOL_logMessage('setupSorting completed');
  on-error;
    CKOOL_logMessage('Error in setupSorting: ' + %trimr(%char(%error)));
    clear lContext.sort; // Clear sorts if error
  endmon;
  
  // Debug log before calling service_search
  CKOOL_logMessage('About to call service_search with context');
  CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));
  CKOOL_logMessage('Pagination perPage: ' + %char(lContext.pagination.perPage));
  
  // Appel de votre procÃ©dure existante
  monitor;
    if service_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('service_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      
      // Add React Admin simple REST provider required headers
      il_addHeader(response : 'X-Total-Count' : %char(lTotalCount));
      il_addHeader(response : 'Access-Control-Expose-Headers' : 'X-Total-Count');
      
      // Write array with total count header for React Admin
      il_responseWrite(response : servicesToJson(lItems : lTotalCount));
    else;
      CKOOL_logMessage('service_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    CKOOL_logMessage('Exception in service_search call: ' + %trimr(%char(%error)));
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Exception during search: ' + 
        %trimr(%char(%error)) + '"}');
  endmon;
  
  on-exit;
    // Clean up
    if (lItems <> *null);
      list_clear(lItems);
    endif;
end-proc;

// GET /services/{id} - Get service detail
dcl-proc service_getone_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s contentType varchar(100);
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // Check Accept header
  contentType = il_getRequestHeader(request : 'Accept');
  if (contentType <> IL_MEDIA_TYPE_JSON and contentType <> IL_MEDIA_TYPE_ALL);
    response.status = IL_HTTP_UNSUPPORTED_MEDIA_TYPE;
    il_responseWrite(response : contentType + ' is not supported');
    return;
  endif;
  
  // RÃ©cupÃ©ration ID depuis l'URL
  cId = il_getPathParameter(request : 'id' : '');
  CKOOL_logMessage('id :' + %char(cId));
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
  
  if service_getByID(lId : lDetail : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : serviceToJson(lDetail));
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : 'No service with id ' + cId);
  endif;
end-proc;

// POST /services - Create new service
dcl-proc service_create_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s contentType varchar(100);
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s create ind;
  
  // Check Content-Type header
  contentType = il_getRequestHeader(request : 'Content-Type');
  if (contentType <> IL_MEDIA_TYPE_JSON);
    response.status = IL_HTTP_NOT_ACCEPTABLE;
    il_responseWrite(response : contentType + ' is not supported');
    return;
  endif;
  
  // Parse JSON from request body
  lDetail = jsonToservice(il_getRequestContent(request));
  create = (%len(%trim(lDetail.id.code)) = 0);
  
  monitor;
    if service_create(lDetail : lId : lErrors);
      // Success - copy id back to detail
      lDetail.id = lId;
      
      exec sql COMMIT;
      
      if (create);
        response.status = IL_HTTP_CREATED;
      else;
        response.status = IL_HTTP_OK;
      endif;
      
      response.contentType = IL_MEDIA_TYPE_JSON;
      il_responseWrite(response : serviceToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Internal server error"}');
  endmon;
end-proc;

// PUT /services/{id} - Update service
dcl-proc service_update_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s contentType varchar(100);
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // Check Content-Type header
  contentType = il_getRequestHeader(request : 'Content-Type');
  if (contentType <> IL_MEDIA_TYPE_JSON);
    response.status = IL_HTTP_NOT_ACCEPTABLE;
    il_responseWrite(response : contentType + ' is not supported');
    return;
  endif;
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
  
  // Parse JSON from request body
  lDetail = jsonToservice(il_getRequestContent(request));
  lDetail.id.code = cId; // Ensure ID matches URL
  
  monitor;
    if service_change(lId : lDetail : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      il_addHeader(response : 'Access-Control-Allow-Origin' : '*');
      il_responseWrite(response : serviceToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Internal server error"}');
  endmon;
end-proc;

// DELETE /services/{id} - Delete service
dcl-proc service_delete_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s abnormallyEnded ind;
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
  
  // First get the service to return it in response
  if service_getByID(lId : lDetail : lErrors);
    if service_delete(lId : lErrors);
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      il_responseWrite(response : serviceToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : errorsToJson(lErrors));
    endif;
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : 'No service with id ' + cId);
  endif;
  
  on-exit abnormallyEnded;
    if (abnormallyEnded);
      exec sql ROLLBACK;
    else;
      exec sql COMMIT;
    endif;
end-proc;

// Helper functions for JSON conversion

///
// Convert list of services to JSON array
//
// Converts a linked list of services to JSON format with total count
// for React Admin compatibility.
//
// @param **in**  services   pointer to linked list of service items
// @param **in**  totalCount  total number of services found
// @return JSON string representation of service list
// @tag service
// @tag JSON
// @tag Helper
///
dcl-proc servicesToJson;
  dcl-pi *n varchar(1048576);
    services pointer const;
    totalCount like(CMAGIC_totalCount) const;
  end-pi;

  dcl-s json varchar(1048576);
  dcl-s first ind inz(*on);
  dcl-ds service likeds(service_item_t) based(ptr);
  
  json = '[';
  
  ptr = list_iterate(services);
  dow (ptr <> *null);
    if (not first);
      json += ',';
    endif;
    json += serviceItemToJson(service);
    first = *off;
    ptr = list_iterate(services);
  enddo;
  
  json += ']';
  
  return json;
end-proc;

///
// Convert service detail to JSON
//
// Converts a single service detail structure to JSON format.
//
// @param **in**  service  service detail structure
// @return JSON string representation of service detail
// @tag service
// @tag JSON
// @tag Helper
///
dcl-proc serviceToJson;
  dcl-pi *n varchar(4096);
    service likeds(service_detail_t) const;
  end-pi;

  dcl-s json varchar(4096);
  
  json = '{';
  json += '"id":"' + %trim(service.id.code) + '",';
  json += '"nom":"' + %trim(service.nom) + '",';
  json += '"manager_id":"' + %trim(service.managerId) + '",';
  json += '"servicePrincipal_id":"' 
      + %trim(service.servicePrincipalId) + '",';
  json += '}';
  
  return json;
end-proc;

///
// Convert service item to JSON
//
// Converts a single service item structure to JSON format.
//
// @param **in**  service  service item structure
// @return JSON string representation of service item
// @tag service
// @tag JSON
// @tag Helper
///
dcl-proc serviceItemToJson;
  dcl-pi *n varchar(2048);
    service likeds(service_item_t) const;
  end-pi;

  dcl-s json varchar(2048);
  
  json = '{';
  json += '"id":"' + %trim(service.id.code) + '",';
  json += '"nom":"' + %trim(service.nom) + '",';
  json += '"manager_id":"' + %trim(service.managerId) + '",';
  json += '"servicePrincipal_id":"' 
      + %trim(service.servicePrincipalId) + '",';
  json += '}';
  
  return json;
end-proc;

///
// Convert JSON string to service detail
//
// Parses a JSON string and converts it to service detail structure.
//
// @param **in**  jsonString  JSON string containing service data
// @return service detail structure
// @tag service
// @tag JSON
// @tag Helper
///
dcl-proc jsonToservice;
  dcl-pi *n likeds(service_detail_t);
    jsonString varchar(4096) const;
  end-pi;

  dcl-ds service likeds(service_detail_t) inz;
  dcl-s pos int(10);
  dcl-s endPos int(10);
  dcl-s fieldValue varchar(100);
  
  // Simple JSON parsing - in production you'd want a proper JSON parser
  // This is a simplified version for demonstration
  
  // Extract id
  pos = %scan('"id":"' : jsonString);
  if (pos > 0);
    pos += 6;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.id.code = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract prenom
  pos = %scan('"prenom":"' : jsonString);
  if (pos > 0);
    pos += 10;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.prenom = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract nom
  pos = %scan('"nom":"' : jsonString);
  if (pos > 0);
    pos += 7;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.nom = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract initiale
  pos = %scan('"initiale":"' : jsonString);
  if (pos > 0);
    pos += 12;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.initiale = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract service
  pos = %scan('"service":"' : jsonString);
  if (pos > 0);
    pos += 11;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.service = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract genre
  pos = %scan('"genre":"' : jsonString);
  if (pos > 0);
    pos += 9;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      service.genre = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  return service;
end-proc;

///
// Convert errors to JSON
//
// Converts error list to JSON format for REST API responses.
//
// @param **in**  errors  list of errors
// @return JSON string representation of errors
// @tag service
// @tag JSON
// @tag Helper
///
dcl-proc errorsToJson;
  dcl-pi *n varchar(2048);
    errors likeds(GLOBAL_listError) const;
  end-pi;

  dcl-s json varchar(2048);
  dcl-ds lErrors likeds(GLOBAL_listError);
  dcl-ds lError likeds(errorItem);
  // initialisation
  clear lErrors;
  lErrors = errors;
  json = '{"errors":[';
  // traitement
  sorta(D) lErrors.listError(*).text; 
  for-each lError in lErrors;
    if lError.text = *blanks;
      leave;
    endif;  
    json += '{';
    json += '"code":"' + %trim(lError.code) + '",';
    json += '"Zone":"' + %trim(lError.nomZone) + '",';
    json += '"Valeur":"' + %trim(lError.valeur) + '",';    json += '"message":"' + escapeJson(%trim(errors.listError(i).textUser)) + '"';
    json += '"Texte":"' + %trim(lError.text) + '",';
    json += '"Texte User":"' + %trim(lError.textUser) + '",';
    json += '}';
  endfor;
  // Add error handling here based on your error structure
  json += ']}';
  
  return json;
end-proc;

// Helper function to setup dynamic filters based on request parameters
dcl-proc setupFilters;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  
  dcl-ds lRequest likeDs(request);
  dcl-s filterIndex int(5) inz(1);
  dcl-s filterValue varchar(100);
  dcl-s fieldName varchar(32);
  dcl-s operator varchar(10);
  dcl-s baseField varchar(32);
  dcl-s i int(5);
  
  // Clear existing filters
  clear lRequest;
  lRequest = request;
  clear context.filter;
  
  CKOOL_logMessage('=== DÃ‰BUT setupFilters ===');
  
  // Parcourir tous les paramÃ¨tres de requÃªte pour dÃ©tecter les filtres
  for i = 1 to %elem(empres_supportedFields);
    if (%len(%trim(empres_supportedFields(i))) = 0);
      leave;
    endif;
    
    baseField = %trim(empres_supportedFields(i));
    CKOOL_logMessage('VÃ©rification du champ: ' + baseField);
    
    // Tester chaque opÃ©rateur pour ce champ
    // 1. OpÃ©rateur EQUAL (champ seul)
    filterValue = il_getQueryParameter(lRequest : baseField : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_EQUAL;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre EQUAL dÃ©tectÃ©: ' + baseField + ' = ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 2. OpÃ©rateur LIKE (champ_like)
    filterValue = il_getQueryParameter(lRequest : baseField + '_like' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_LIKE;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre LIKE dÃ©tectÃ©: ' + baseField + ' LIKE ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 3. OpÃ©rateur GREATER_EQUAL (champ_gte)
    filterValue = il_getQueryParameter(lRequest : baseField + '_gte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_GREATER_EQUAL;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre GTE dÃ©tectÃ©: ' + baseField + ' >= ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 4. OpÃ©rateur LESS_EQUAL (champ_lte)
    filterValue = il_getQueryParameter(lRequest : baseField + '_lte' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_LESS_EQUAL;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre LTE dÃ©tectÃ©: ' + baseField + ' <= ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 5. OpÃ©rateur GREATER (champ_gt)
    filterValue = il_getQueryParameter(lRequest : baseField + '_gt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_GREATER;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre GT dÃ©tectÃ©: ' + baseField + ' > ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 6. OpÃ©rateur LESS (champ_lt)
    filterValue = il_getQueryParameter(lRequest : baseField + '_lt' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_LESS;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre LT dÃ©tectÃ©: ' + baseField + ' < ' + %trim(filterValue));
      filterIndex += 1;
    endif;
    
    // 7. OpÃ©rateur NOT_EQUAL (champ_ne)
    filterValue = il_getQueryParameter(lRequest : baseField + '_ne' : '');
    if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
      context.filter(filterIndex).field = baseField;
      context.filter(filterIndex).operator = CMAGIC_OP_NOT_EQUAL;
      context.filter(filterIndex).value = %trim(filterValue);
      CKOOL_logMessage('Filtre NE dÃ©tectÃ©: ' + baseField + ' <> ' + %trim(filterValue));
      filterIndex += 1;
    endif;
  endfor;
  
  // Gestion de la recherche gÃ©nÃ©rale 'q'
  filterValue = il_getQueryParameter(lRequest : 'q' : '');
  if (%len(%trim(filterValue)) > 0 and filterIndex <= %elem(context.filter));
    context.filter(filterIndex).field = 'q';
    context.filter(filterIndex).operator = CMAGIC_OP_LIKE;
    context.filter(filterIndex).value = %trim(filterValue);
    CKOOL_logMessage('Recherche gÃ©nÃ©rale dÃ©tectÃ©e: q = ' + %trim(filterValue));
    filterIndex += 1;
  endif;
  
  // Handle React Admin filter format: filter={field: "value"}
  // This is a simplified version - you might want to use a proper JSON parser
  filterValue = il_getQueryParameter(lRequest : 'filter' : '');
  if (%len(%trim(filterValue)) > 0);
    // Simple extraction - in production use proper JSON parsing
    // This is just a basic example
    CKOOL_logMessage('Filter parameter received: ' + %trim(filterValue));
  endif;
  
  CKOOL_logMessage('=== FIN setupFilters - ' + %char(filterIndex - 1) + ' filtres dÃ©tectÃ©s ===');
end-proc;

// Helper function to setup general search filter
dcl-proc setupGeneralSearchFilter;
  dcl-pi *n;
    context likeDS(CMAGIC_context);
    searchTerm varchar(100) const;
  end-pi;
  
  dcl-s filterIndex int(5) inz(1);
  
  // Find next available filter slot
  dow (filterIndex <= %elem(context.filter) and 
       %len(%trim(context.filter(filterIndex).field)) > 0);
    filterIndex += 1;
  enddo;
  
  // Add general search filter if slot available
  if (filterIndex <= %elem(context.filter));
    context.filter(filterIndex).field = 'q'; // Special field for general search
    context.filter(filterIndex).value = %trim(searchTerm);
  endif;
end-proc;

// Helper function to setup dynamic sorting
dcl-proc setupSorting;
  dcl-pi *n;
    request likeds(IL_request) const;
    context likeDS(CMAGIC_context);
  end-pi;
  dcl-ds lRequest likeDs(request);
  dcl-s sortField varchar(100);
  dcl-s sortOrder varchar(10);
  dcl-s i int(5);
  dcl-s sortIndex int(5) inz(1);
  
  // Clear existing sorts
  clear context.sort;
  lRequest = request;
  
  // React Admin simple REST provider uses 'sort' and 'order' parameters
  sortField = il_getQueryParameter(lRequest : 'sort' : '');
  sortOrder = il_getQueryParameter(lRequest : 'order' : 'ASC');
  
  // Fallback to React Admin classic format if simple REST not found
  if (%len(%trim(sortField)) = 0);
    sortField = il_getQueryParameter(lRequest : '_sort' : 'lastname');
    sortOrder = il_getQueryParameter(lRequest : '_order' : 'ASC');
  endif;
  
  if (%len(%trim(sortField)) > 0);
    context.sort(1).field = %trim(sortField);
    context.sort(1).order = %trim(sortOrder);
    sortIndex = 2;
  endif;
  
  // Additional sorts for advanced use cases
  // Format: ?sort1=field1&order1=ASC&sort2=field2&order2=DESC
  for i = 1 to 4; // Support up to 4 additional sorts
    sortField = il_getQueryParameter(lRequest : 'sort' + %char(i) : '');
    sortOrder = il_getQueryParameter(lRequest : 'order' + %char(i) : 'ASC');
    
    if (%len(%trim(sortField)) > 0 and sortIndex <= %elem(context.sort));
      context.sort(sortIndex).field = %trim(sortField);
      context.sort(sortIndex).order = %trim(sortOrder);
      sortIndex += 1;
    endif;
  endfor;
end-proc;