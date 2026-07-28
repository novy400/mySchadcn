**free
// Generated from CatalogSpec with catalog-ileastic.sqlrpgle.hbs. Do not edit.
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'NOXDB':'ILEASTIC':'CREST');

/include 'services.ileastic.rpgleinc'
/include 'services.read.rpgleinc'
/include 'crest.rpgleinc'
/include 'ileastic/noxdb.rpgleinc'
/include 'llist/llist_h.rpgle'

dcl-proc service_getlist_rest;
  dcl-pi *n;
    request likeDS(IL_request);
    response likeDS(IL_response);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount) inz(0);
  dcl-s lItems pointer inz(*null);
  dcl-s ErrorHappened ind;

  if not service_getSupportedFields(lSupportedFields : lErrors);
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    response.contentType = IL_MEDIA_TYPE_JSON;
    CREST_addHeaders(response);
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;

  if not CREST_initRestRequest(request : lSupportedFields
    : response : lContext);
    return;
  endif;

  if not service_search(lContext : lTotalCount : lItems : lErrors);
    response.contentType = IL_MEDIA_TYPE_JSON;
    CREST_addHeaders(response);
    if lErrors.listError(1).nomZone = 'sql';
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    else;
      response.status = IL_HTTP_BAD_REQUEST;
    endif;
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;

  service_writeListResponse(
    response : lItems : lTotalCount);

  on-exit ErrorHappened;
    if lItems <> *null;
      list_dispose(lItems);
    endif;
    if ErrorHappened;
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      response.contentType = IL_MEDIA_TYPE_JSON;
      CREST_addHeaders(response);
      il_responseWrite(
        response : CREST_simpleError('Unable to serialize response'));
    endif;
end-proc;

dcl-proc service_writeListResponse;
  dcl-pi *n;
    response likeDS(IL_response);
    pItems pointer const;
    pTotalCount like(CMAGIC_totalCount) const;
  end-pi;
  dcl-s lItemPointer pointer inz(*null);
  dcl-ds lItem likeDS(service_item_t) based(lItemPointer);
  dcl-s lDataJson pointer inz(*null);
  dcl-s lItemJson pointer inz(*null);
  dcl-s lHandle char(1);

  lDataJson = json_newArray();
  lItemPointer = list_iterate(pItems);
  dow lItemPointer <> *null;
    data-gen lItem %data(lHandle : '') %gen(json_DataGen(lItemJson));
    json_arrayPush(lDataJson : lItemJson);
    lItemJson = *null;
    lItemPointer = list_iterate(pItems);
  enddo;

  response.status = IL_HTTP_OK;
  response.contentType = IL_MEDIA_TYPE_JSON;
  CREST_addHeaders(response);
  il_responseWrite(response : %ucs2('{"data":'));
  il_responseWrite(response : json_asJsonText(lDataJson));
  il_responseWrite(response : %ucs2(',"total":'));
  il_responseWrite(response : %ucs2(%trim(%char(pTotalCount))));
  il_responseWrite(response : %ucs2('}'));

  on-exit;
    json_delete(lItemJson);
    json_delete(lDataJson);
end-proc;

dcl-proc service_getone_rest;
  dcl-pi *n;
    request likeDS(IL_request);
    response likeDS(IL_response);
  end-pi;
  dcl-s cId varchar(32767);
  dcl-s lId varchar(3);
  dcl-ds lDetail likeDS(service_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lJson pointer inz(*null);
  dcl-s lHandle char(1);
  dcl-s ErrorHappened ind;

  if not CREST_initSimpleRestRequest(request : response);
    return;
  endif;

  cId = il_getPathParameter(request : 'id' : '');
  if not service_parseId(cId : lId);
    response.status = IL_HTTP_BAD_REQUEST;
    response.contentType = IL_MEDIA_TYPE_JSON;
    CREST_addHeaders(response);
    il_responseWrite(
      response : CREST_simpleError('Invalid Service id'));
    return;
  endif;

  if not service_get(lId : lDetail : lErrors);
    response.contentType = IL_MEDIA_TYPE_JSON;
    CREST_addHeaders(response);
    if lErrors.listError(1).nomZone = 'id';
      response.status = IL_HTTP_NOT_FOUND;
    else;
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    endif;
    il_responseWrite(response : CREST_errorsToJson(lErrors));
    return;
  endif;

  data-gen lDetail %data(lHandle : '') %gen(json_DataGen(lJson));
  service_writeDetailResponse(response : lJson);

  on-exit ErrorHappened;
    json_delete(lJson);
    if ErrorHappened;
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      response.contentType = IL_MEDIA_TYPE_JSON;
      CREST_addHeaders(response);
      il_responseWrite(
        response : CREST_simpleError('Unable to serialize response'));
    endif;
end-proc;

// Convert and validate the public path identifier without silent truncation.
dcl-proc service_parseId;
  dcl-pi *n ind;
    pValue varchar(32767) const;
    pId varchar(3);
  end-pi;

  if %len(%trim(pValue)) = 0;
    return *off;
  endif;

  monitor;
    if %len(pValue) > 3;
      return *off;
    endif;
    pId = pValue;
  on-error;
    return *off;
  endmon;

  return *on;
end-proc;

dcl-proc service_writeDetailResponse;
  dcl-pi *n;
    response likeDS(IL_response);
    pJson pointer const;
  end-pi;

  response.status = IL_HTTP_OK;
  response.contentType = IL_MEDIA_TYPE_JSON;
  CREST_addHeaders(response);
  il_responseWrite(response : %ucs2('{"data":'));
  il_responseWrite(response : json_asJsonText(pJson));
  il_responseWrite(response : %ucs2('}'));
end-proc;

dcl-proc service_registerRoutes export;
  dcl-pi *n;
    config likeDS(IL_config);
  end-pi;
  il_addRoute(config : %paddr('service_getlist_rest')
    : IL_GET : '^/api/services/?$');
  il_addRoute(config : %paddr('service_getone_rest')
    : IL_GET : '^/api/services/{id}$');
end-proc;
