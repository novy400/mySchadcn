**free

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
       datfmt(*iso)
        bnddir('QC2LE':'CKOOL':'NOXDB':'ILEASTIC':'CREST');

/include 'ileastic/ileastic.rpgle'
/include 'service.rpgleinc'
/include 'servrest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'crest.rpgleinc'
/include 'llist/llist_h.rpgle'
/include 'ileastic/noxdb.rpgleinc'

// GET /services - Search with pagination (React Admin compatible)
dcl-proc service_getlist_rest export;
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
  if not service_getSupportedFields(lSupportedFields:lErrors);
  endif; 
  // ⚡ CREST : Initialisation REST centralisée (validation + parsing)
  if (not CREST_initRestRequest(request : lSupportedFields
                                : response : lContext));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Debug log before calling service_search
  CKOOL_logMessage('About to call service_search with context');
  CKOOL_logMessage('Pagination numPage: ' + %char(lContext.pagination.numPage));
  CKOOL_logMessage('Pagination perPage: ' + %char(lContext.pagination.perPage));
  
  // Appel de votre procédure existante
  monitor;
    if not service_search(lContext : lTotalCount : lItems : lErrors);
      CKOOL_logMessage('service_search failed');
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      response.contentType = IL_MEDIA_TYPE_JSON;
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
      return;
    endif;
      CKOOL_logMessage('service_search succeeded - Total count: ' + %char(lTotalCount));
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
    // constitution du json liste des items.
    lJson = entitiesToJson(lItems);  
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

// GET /services/{id} - Get service detail
dcl-proc service_getone_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lDetail likeds(service_detail_t);
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
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
  
  if not service_getByID(lId : lDetail : lErrors);
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : 'No service with id ' + cId);
    return;
  endif;

  // Creation de la réponse JSON
  lJson = entityToJson(lDetail);
  // Envoi de la réponse
  response.status = IL_HTTP_OK;
  response.contentType = IL_MEDIA_TYPE_JSON;
  il_responseWrite(response : json_asJsonText(lJson));

  on-exit;
    json_close(lJson);

end-proc;

// POST /employees - Create new employee
dcl-proc service_create_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lId likeDS(service_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s create ind;
  dcl-s  lJson pointer;   
  // ⚡ CREST : Validation REST pour opérations d'écriture
  if (not CREST_initWriteRestRequest(request : response));
    return; // La validation a échoué, response déjà configurée
  endif;
  
  // Parse JSON from request body
  lJson = json_parseString(%char(il_getRequestContent(request)));
  lDetail = jsonToEntity(lJson);
  json_close(lJson);  
  create = (%len(%trim(lDetail.id.code)) = 0);
  
  monitor;
      // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);
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
     // Creation de la réponse JSON
      lJson = entityToJson(lDetail);
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

// PUT /services/{id} - Update service
dcl-proc service_update_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;
  
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lId likeDS(service_detail_t.id);
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
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
  
  // Parse JSON from request body
  lJson = json_parseString(%char(il_getRequestContent(request)));
  lDetail = jsonToEntity(lJson);
  json_close(lJson);  
  lDetail.id.code = cId; // Ensure ID matches URL
  monitor;
        // ⚡ Headers standardisés via CREST utilitaires
      CREST_addHeaders(response);

    if service_update(lId : lDetail : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      // Creation de la réponse JSON
      lJson = entityToJson(lDetail);
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
  dcl-s  lJson pointer;  
  
  // Get ID from URL
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : 'Invalid service id');
    return;
  endif;
  
  lId.code = cId;
  // ⚡ CREST : Validation REST simplifiée    
  CREST_addHeaders(response);
  // First get the service to return it in response
  if service_getByID(lId : lDetail : lErrors);
    if service_delete(lId : lErrors);
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
     // Creation de la réponse JSON
      lJson = entityToJson(lDetail);
      il_responseWrite(response : json_asJsonText(lJson));
      json_close(lJson);  
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : CREST_simpleError('No service with id ' + cId));
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
// @tag Service
// @tag JSON
// @tag Helper
///
dcl-proc entitiesToJson;
  dcl-pi *n pointer;
    entities pointer const;
  end-pi;
  dcl-s ljson pointer;
  dcl-ds lDetail likeds(service_detail_t) based(ptr);
  
  ljson = json_newArray();
  
  ptr = list_iterate(entities);
  dow (ptr <> *null);
    json_arrayPush(ljson : entityToJson(lDetail));
  
    ptr = list_iterate(entities);
  enddo;
  
  return ljson;

end-proc;

///
// Convert service detail to JSON
//
// Converts a single service detail structure to JSON format.
//
// @param **in**  service  service detail structure
// @return JSON pointer representation of service detail
// @tag Service
// @tag JSON
// @tag Helper Service
///
dcl-proc entityToJson;
  dcl-pi *n pointer;
    entity likeds(service_detail_t) const;
  end-pi;
  dcl-ds lDetailRest likeds(service_detail_rest_t) inz;
  dcl-s lHandle	char(1);
  dcl-s lJson pointer;

  clear lDetailRest;
  eval-corr lDetailRest = entity;
  data-gen lDetailRest %data(lHandle: '') %gen(json_DataGen(lJson));

  return lJson;
end-proc;


///
// Convert JSON string to service detail
//
// Parses a JSON string and converts it to service detail structure.
//
// @param **in**  jsonString  JSON string containing service data
// @return service detail structure
// @tag Service
// @tag JSON
// @tag Helper
///
dcl-proc jsonToEntity;
  dcl-pi *n likeds(service_detail_t);
    json pointer const;
  end-pi;
  dcl-ds lDetailRest likeds(service_detail_rest_t) inz;
  dcl-ds lDetail likeds(service_detail_t) inz;
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
