**free
// Generated from CatalogSpec with catalog-iws.sqlrpgle.hbs. Do not edit.
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        pgminfo(*pcml:*module:*dclcase)
        datfmt(*iso)
        bnddir('QC2LE':'SERVICE':'CKOOL':'NOXDB');

/include 'services.iws.rpgleinc'
/include 'services.read.rpgleinc'
/include 'ciws.rpgleinc'
/include 'llist/llist_h.rpgle'

dcl-proc service_getlist_iws export;
  dcl-pi *n;
    items_LENGTH int(10);
    items likeDS(service_item_iws_t) dim(HTTPREST_MAX_ITEMS);
    totalCount like(CMAGIC_totalCount);
    errors_LENGTH int(10);
    errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
    httpStatus like(HTTPREST_httpStatus);
    httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);
  end-pi;
  dcl-s lAbended ind inz(*off);
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-s lItems pointer inz(*null);

  clear items_LENGTH;
  clear items;
  clear totalCount;
  clear errors_LENGTH;
  clear errors;
  clear httpHeaders;
  httpStatus = HTTPREST_OK;

  if not service_getSupportedFields(
    lSupportedFields : lErrors);
    httpStatus = HTTPREST_SERVERERROR;
    errors_LENGTH = CIWS_setErrors(lErrors : errors);
    return;
  endif;

  if not CIWS_initRestRequest(
    lSupportedFields : lContext : lErrors);
    httpStatus = HTTPREST_BADREQUEST;
    errors_LENGTH = CIWS_setErrors(lErrors : errors);
    return;
  endif;

  if not service_search(
    lContext : totalCount : lItems : lErrors);
    if lErrors.listError(1).nomZone = 'sql';
      httpStatus = HTTPREST_SERVERERROR;
    else;
      httpStatus = HTTPREST_BADREQUEST;
    endif;
    errors_LENGTH = CIWS_setErrors(lErrors : errors);
    return;
  endif;

  service_copyIwsItems(lItems : items_LENGTH : items);
  CIWS_addCollectionHeaders(totalCount : httpHeaders);

  on-exit lAbended;
    if lItems <> *null;
      list_dispose(lItems);
    endif;
    if lAbended;
      httpStatus = HTTPREST_SERVERERROR;
      if errors_LENGTH = 0;
        errors_LENGTH = 1;
        errors(1).nomZone = 'service_getlist_iws';
        errors(1).code = 'RNX9001';
        errors(1).text =
          'Unexpected error in service_getlist_iws';
        errors(1).textUser = errors(1).text;
      endif;
    endif;
end-proc;

dcl-proc service_copyIwsItems;
  dcl-pi *n;
    pList pointer value;
    pItemsLength int(10);
    pItems likeDS(service_item_iws_t) dim(HTTPREST_MAX_ITEMS);
  end-pi;
  dcl-s lItemPointer pointer inz(*null);
  dcl-ds lSource likeDS(service_item_t)
    based(lItemPointer);

  clear pItemsLength;
  clear pItems;
  if pList = *null;
    return;
  endif;

  lItemPointer = list_iterate(pList);
  dow lItemPointer <> *null
    and pItemsLength < HTTPREST_MAX_ITEMS;
    pItemsLength += 1;
    eval-corr pItems(pItemsLength) = lSource;
    lItemPointer = list_iterate(pList);
  enddo;
end-proc;
dcl-proc service_getone_iws export;
  dcl-pi *n;
    id varchar(3) const;
    item likeDS(service_detail_iws_t);
    errors_LENGTH int(10);
    errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
    httpStatus like(HTTPREST_httpStatus);
    httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);
  end-pi;
  dcl-s lAbended ind inz(*off);
  dcl-ds lDetail likeDS(service_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;

  clear item;
  clear errors_LENGTH;
  clear errors;
  clear httpHeaders;
  httpStatus = HTTPREST_OK;

  if not service_get(id : lDetail : lErrors);
    if lErrors.listError(1).nomZone = 'id';
      httpStatus = HTTPREST_NOTFOUND;
    else;
      httpStatus = HTTPREST_SERVERERROR;
    endif;
    errors_LENGTH = CIWS_setErrors(lErrors : errors);
    return;
  endif;

  eval-corr item = lDetail;

  on-exit lAbended;
    if lAbended;
      httpStatus = HTTPREST_SERVERERROR;
      if errors_LENGTH = 0;
        errors_LENGTH = 1;
        errors(1).nomZone = 'service_getone_iws';
        errors(1).code = 'RNX9001';
        errors(1).text =
          'Unexpected error in service_getone_iws';
        errors(1).textUser = errors(1).text;
      endif;
    endif;
end-proc;
