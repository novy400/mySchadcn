**free

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC':'CREST');

/include 'ileastic/ileastic.rpgle'
/include 'employee.rpgleinc'
/include 'emprest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'crest.rpgleinc'
/include 'llist/llist_h.rpgle'


// GET /employees - Search with pagination (React Admin compatible)
dcl-proc employee_getlist_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError);

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields); 
  // ⚡ Définir les champs supportés pour les filtres et tris
  clear lSupportedFields;
  clear lErrors;  
  if not employee_getSupportedFields(lSupportedFields:lErrors);
  endif; 
  // ⚡ CREST : Initialisation REST centralisée (validation + parsing)
  if (not CREST_initRestRequest(request : lSupportedFields
                                : response : lContext));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Debug log before calling employee_search
  CKOOL_logMessage('About to call employee_search with context');
  CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));
  CKOOL_logMessage('Pagination perPage: ' + %char(lContext.pagination.perPage));
  
  // Appel de votre procédure existante
  monitor;
    if employee_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('employee_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response : lTotalCount);
      
      // Write array with total count header for React Admin
      il_responseWrite(response : employeesToJson(lItems : lTotalCount));
    else;
      CKOOL_logMessage('employee_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    CKOOL_logMessage('Exception in employee_search call: ' + %trimr(%char(%error)));
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

// GET /employees/{id} - Get employee detail
dcl-proc employee_getone_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lId likeDS(employee_detail_t.id);
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // ⚡ CREST : Validation REST simplifiée
  if (not CREST_initSimpleRestRequest(request : response));
    return; // La validation a échoué, response déjà configurée  
  endif;
  
  // Récupération ID depuis l'URL
  cId = il_getPathParameter(request : 'id' : '');
  CKOOL_logMessage('id :' + %char(cId));
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid employee id');
    return;
  endif;
  
  lId.code = cId;
  
  if employee_getByID(lId : lDetail : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : employeeToJson(lDetail));
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : 'No employee with id ' + cId);
  endif;
end-proc;

// POST /employees - Create new employee
dcl-proc employee_create_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lId likeDS(employee_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s create ind;
  
  // ⚡ CREST : Validation REST pour opérations d'écriture
  if (not CREST_initWriteRestRequest(request : response));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Parse JSON from request body
  lDetail = jsonToEmployee(il_getRequestContent(request));
  create = (%len(%trim(lDetail.id.code)) = 0);
  
  monitor;
    if employee_create(lDetail : lId : lErrors);
      // Success - copy id back to detail
      lDetail.id = lId;
      
      exec sql COMMIT;
      
      if (create);
        response.status = IL_HTTP_CREATED;
      else;
        response.status = IL_HTTP_OK;
      endif;
      
      response.contentType = IL_MEDIA_TYPE_JSON;
      il_responseWrite(response : employeeToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;

// PUT /employees/{id} - Update employee
dcl-proc employee_update_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lId likeDS(employee_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // ⚡ CREST : Validation REST pour opérations d'écriture
  if (not CREST_initWriteRestRequest(request : response));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid employee id');
    return;
  endif;
  
  lId.code = cId;
  
  // Parse JSON from request body
  lDetail = jsonToEmployee(il_getRequestContent(request));
  lDetail.id.code = cId; // Ensure ID matches URL
  
  monitor;
    if employee_update(lId : lDetail : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      CREST_addHeaders(response);
      il_responseWrite(response : employeeToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;

// DELETE /employees/{id} - Delete employee
dcl-proc employee_delete_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-s abnormallyEnded ind;
  dcl-ds lId likeDS(employee_detail_t.id);
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid employee id');
    return;
  endif;
  
  lId.code = cId;
  
  // First get the employee to return it in response
  if employee_getByID(lId : lDetail : lErrors);
    if employee_delete(lId : lErrors);
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      CREST_addHeaders(response);
      il_responseWrite(response : employeeToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : CREST_simpleError('No employee with id ' + cId));
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
// Convert list of employees to JSON array
//
// Converts a linked list of employees to JSON format with total count
// for React Admin compatibility.
//
// @param **in**  employees   pointer to linked list of employee items
// @param **in**  totalCount  total number of employees found
// @return JSON string representation of employee list
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc employeesToJson;
  dcl-pi *n varchar(1048576);
    employees pointer const;
    totalCount like(CMAGIC_totalCount) const;
  end-pi;

  dcl-s json varchar(1048576);
  dcl-s first ind inz(*on);
  dcl-ds employee likeds(employee_item_t) based(ptr);
  
  json = '[';
  
  ptr = list_iterate(employees);
  dow (ptr <> *null);
    if (not first);
      json += ',';
    endif;
    json += employeeItemToJson(employee);
    first = *off;
    ptr = list_iterate(employees);
  enddo;
  
  json += ']';
  
  return json;
end-proc;

///
// Convert employee detail to JSON
//
// Converts a single employee detail structure to JSON format.
//
// @param **in**  employee  employee detail structure
// @return JSON string representation of employee detail
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc employeeToJson;
  dcl-pi *n varchar(4096);
    employee likeds(employee_detail_t) const;
  end-pi;

  dcl-s json varchar(4096);
  
  json = '{';
  json += '"id":"' + %trim(employee.id.code) + '",';
  json += '"prenom":"' + %trim(employee.prenom) + '",';
  json += '"nom":"' + %trim(employee.nom) + '",';
  json += '"initiale":"' + %trim(employee.initiale) + '",';
  json += '"service":"' + %trim(employee.service) + '",';
  json += '"dateEmbauche":"' + %char(employee.dateEmbauche : *iso) + '",';
  json += '"dateNaissance":"' + %char(employee.dateNaissance : *iso) + '",';
  json += '"genre":"' + %trim(employee.genre) + '",';
  json += '"salaire":' + %char(employee.salaire);
  json += '}';
  
  return json;
end-proc;

///
// Convert employee item to JSON
//
// Converts a single employee item structure to JSON format.
//
// @param **in**  employee  employee item structure
// @return JSON string representation of employee item
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc employeeItemToJson;
  dcl-pi *n varchar(2048);
    employee likeds(employee_item_t) const;
  end-pi;

  dcl-s json varchar(2048);
  
  json = '{';
  json += '"id":"' + %trim(employee.id.code) + '",';
  json += '"prenom":"' + %trim(employee.prenom) + '",';
  json += '"nom":"' + %trim(employee.nom) + '",';
  json += '"initiale":"' + %trim(employee.initiale) + '",';
  json += '"service":"' + %trim(employee.service) + '"';
  json += '}';
  
  return json;
end-proc;

///
// Convert JSON string to employee detail
//
// Parses a JSON string and converts it to employee detail structure.
//
// @param **in**  jsonString  JSON string containing employee data
// @return employee detail structure
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc jsonToEmployee;
  dcl-pi *n likeds(employee_detail_t);
    jsonString varchar(4096) const;
  end-pi;

  dcl-ds employee likeds(employee_detail_t) inz;
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
      employee.id.code = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract prenom
  pos = %scan('"prenom":"' : jsonString);
  if (pos > 0);
    pos += 10;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      employee.prenom = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract nom
  pos = %scan('"nom":"' : jsonString);
  if (pos > 0);
    pos += 7;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      employee.nom = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract initiale
  pos = %scan('"initiale":"' : jsonString);
  if (pos > 0);
    pos += 12;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      employee.initiale = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract service
  pos = %scan('"service":"' : jsonString);
  if (pos > 0);
    pos += 11;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      employee.service = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  // Extract genre
  pos = %scan('"genre":"' : jsonString);
  if (pos > 0);
    pos += 9;
    endPos = %scan('"' : jsonString : pos);
    if (endPos > pos);
      employee.genre = %subst(jsonString : pos : endPos - pos);
    endif;
  endif;
  
  return employee;
end-proc;

// ========================================
// Les procédures utilitaires REST ont été déplacées vers le module CMAGIC_REST_UTILS
// ========================================
