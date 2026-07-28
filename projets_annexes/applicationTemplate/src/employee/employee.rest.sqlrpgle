**free

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL':'NOXDB':'ILEASTIC':'CREST');

/include 'ileastic/ileastic.rpgle'
/include 'employee.rpgleinc'
/include 'emprest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'crest.rpgleinc'
/include 'llist/llist_h.rpgle'
/include 'ileastic/noxdb.rpgleinc'

// GET /employees - Search with pagination (React Admin compatible)  hhh
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
  dcl-s lJson pointer;  
  dcl-ds lIterator likeds(json_iterator);

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
    if not employee_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('employee_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      response.contentType = IL_MEDIA_TYPE_JSON;
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
      return;
    endif;
      CKOOL_logMessage('employee_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
    // constitution du json liste des items.
    lJson = employeesToJson(lItems);  
    // ⚡ Headers standardisés via CREST utilitaires
    CREST_addHeaders(response : lTotalCount);
      
    //constitution de la reponse liste des items.
    il_responseWrite(response : %ucs2('['));
  
    lIterator = json_setIterator(lJson);
    dow (json_forEach(lIterator));
      il_responseWrite(response : json_asJsonText(lIterator.this));
 
      if (not lIterator.isLast);
        il_responseWrite(response : ',');
      endif;
    enddo;
    // Write array with total count header for React Admin
    il_responseWrite(response : %ucs2(']'));  
  on-error;
    CKOOL_logMessage('Exception in employee_search call: ' + %trimr(%char(%error)));
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Exception during search: ' + 
        %trimr(%char(%error)) + '"}');
  endmon;
  
  on-exit;
    // Clean up
    json_close(lJson);
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
  dcl-s  lJson pointer;  
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
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
  
  if not employee_getByID(lId : lDetail : lErrors);
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : 'No employee with id ' + cId);
    return;
  endif;

  // Creation de la réponse JSON
  lJson = employeeToJson(lDetail);
  // Envoi de la réponse
  response.status = IL_HTTP_OK;
  response.contentType = IL_MEDIA_TYPE_JSON;
  il_responseWrite(response : json_asJsonText(lJson));

  on-exit;
    json_close(lJson);

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
  dcl-s  lJson pointer;   
  // ⚡ CREST : Validation REST pour opérations d'écriture
  if (not CREST_initWriteRestRequest(request : response));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Parse JSON from request body
  lJson = json_parseString(%char(il_getRequestContent(request)));
  lDetail = jsonToEmployee(lJson);
  json_close(lJson);  
  create = (%len(%trim(lDetail.id.code)) = 0);
  
  monitor;
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
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
     // Creation de la réponse JSON
      lJson = employeeToJson(lDetail);
      il_responseWrite(response : json_asJsonText(lJson));
      json_close(lJson);  
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
  dcl-s  lJson pointer;  

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
  lJson = json_parseString(%char(il_getRequestContent(request)));
  lDetail = jsonToEmployee(lJson);
  json_close(lJson);  
  lDetail.id.code = cId; // Ensure ID matches URL
  monitor;
        // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);

    if employee_update(lId : lDetail : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      // Creation de la réponse JSON
      lJson = employeeToJson(lDetail);
      il_responseWrite(response : json_asJsonText(lJson));
      json_close(lJson); 
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      response.contentType = IL_MEDIA_TYPE_JSON;
      lJson = CREST_errorsToReactAdmin(lErrors);      
      il_responseWrite(response : json_asJsonText(lJson));
      json_close(lJson);
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
  dcl-s  lJson pointer;  
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid employee id');
    return;
  endif;
  
  lId.code = cId;
  // ⚡ CREST : Validation REST simplifiée    
  CREST_addHeaders(response);
  // First get the employee to return it in response
  if employee_getByID(lId : lDetail : lErrors);
    if employee_delete(lId : lErrors);
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
     // Creation de la réponse JSON
      lJson = employeeToJson(lDetail);
      il_responseWrite(response : Json_asJsonText(lJson));
      json_close(lJson);  
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
  dcl-pi *n pointer;
    employees pointer const;
  end-pi;
  dcl-s ljson pointer;
  dcl-ds lDetail likeds(employee_detail_t) based(ptr);
  
  ljson = json_newArray();
  
  ptr = list_iterate(employees);
  dow (ptr <> *null);
    json_arrayPush(ljson : employeeToJson(lDetail));
  
    ptr = list_iterate(employees);
  enddo;
  
  return ljson;

end-proc;

///
// Convert employee detail to JSON
//
// Converts a single employee detail structure to JSON format.
//
// @param **in**  employee  employee detail structure
// @return JSON pointer representation of employee detail
// @tag Employee
// @tag JSON
// @tag Helper
///
dcl-proc employeeToJson;
  dcl-pi *n pointer;
    employee likeds(employee_detail_t) const;
  end-pi;
  dcl-ds lDetailRest likeds(employee_detail_rest_t) inz;
  dcl-s lHandle	char(1);
  dcl-s lJson pointer;

  // lJson = nox_newObject();
  
  // json_setStr(lJson : 'id' : employee.id.code);
  // json_setStr(lJson : 'prenom' : employee.prenom);
  // json_setStr(lJson : 'nom' : employee.nom);
  // json_setStr(lJson : 'initiale' : employee.initiale);
  // json_setStr(lJson : 'idService' : employee.idService);
  // json_setStr(lJson : 'numeroTelephone' : employee.numeroTelephone);
  // json_setStr(lJson : 'dateEmbauche' : %char(employee.dateEmbauche : *iso));
  // json_setStr(lJson : 'profession' : employee.profession);
  // json_setStr(lJson : 'dateNaissance' : %char(employee.dateNaissance : *iso));
  // json_setStr(lJson : 'genre' : employee.genre);
  // json_setDec(lJson : 'salaire' : employee.salaire);
  // json_setDec(lJson : 'prime' : employee.prime);
  // json_setDec(lJson : 'commission' : employee.commission);
  clear lDetailRest;
  eval-corr lDetailRest = employee;
  data-gen lDetailRest %data(lHandle: '') %gen(json_DataGen(lJson));

  return lJson;
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
    json pointer const;
  end-pi;
  dcl-ds lDetailRest likeds(employee_detail_rest_t) inz;
  dcl-ds lDetail likeds(employee_detail_t) inz;
  // initialisation
  clear lDetailRest;
  clear lDetail;
  // traitement
  if (json = *null);
    return lDetail;
  endif;

  data-into lDetailRest %data('':'case=any allowextra=yes allowmissing=yes') 
                            %parser(json_DataInto(json));
  eval-corr lDetail = lDetailRest;                      

  // finalisation
  return lDetail;

end-proc;

// ========================================
// Les procédures utilitaires REST ont été déplacées vers le module CMAGIC_REST_UTILS
// ========================================
