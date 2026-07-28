**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        pgminfo(*pcml:*module:*dclcase)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL':'NOXDB');

/include 'service.rpgleinc'
/include 'serviws.rpgleinc'
/include 'ciws.rpgleinc'
/include 'ckool.rpgleinc'
/include 'llist/llist_h.rpgle'



// ------------------------------------------------------------
// GET LIST
// ------------------------------------------------------------
dcl-proc service_getlist_iws export;
  dcl-pi *n;
    items_LENGTH int(10);
    items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
    totalCount like(CMAGIC_totalCount);
    errors_LENGTH int(10);
    errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
    httpStatus like(HTTPREST_httpStatus);
    httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);
  end-pi;

  dcl-s abended ind inz(*off);
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-s lItems pointer inz(*null);
  dcl-s ok ind;

  clear items_LENGTH;
  clear items;
  clear totalCount;
  clear errors_LENGTH;
  clear errors;
  clear httpStatus;
  clear httpHeaders;

  httpStatus = HTTPREST_OK;

  if not service_getSupportedFields(lSupportedFields : lErrors);
     httpStatus = HTTPREST_SERVERERROR;
     clear errors_LENGTH;
     errors_LENGTH = setErrors(lErrors:errors);
     return;
  endif;

  if not CIWS_initRestRequest(lSupportedFields : lContext : lErrors);
     httpStatus = HTTPREST_BADREQUEST;
     clear errors_LENGTH;
     errors_LENGTH = setErrors(lErrors:errors);
     return;
  endif;

  if not service_search(lContext : totalCount : lItems : lErrors);
     httpStatus = HTTPREST_BADREQUEST;
     clear errors_LENGTH;
     errors_LENGTH = setErrors(lErrors:errors);
     return;
  endif;

  copyItems(lItems : items_LENGTH : items);
  addCollectionHeaders(totalCount : httpHeaders);

  on-exit abended;
    if lItems <> *null;
       list_dispose(lItems);
    endif;

    if abended;
       httpStatus = HTTPREST_SERVERERROR;
       if errors_LENGTH = 0;
          errors_LENGTH = 1;
          errors(1).nomZone = 'service_getlist_iws';
          errors(1).code = 'RNX9001';
          errors(1).text = 'Unexpected error in serviws_getList';
          errors(1).textUser = 'Unexpected error in serviws_getList';
       endif;
    endif;
end-proc;

// ------------------------------------------------------------
// Helpers privés
// ------------------------------------------------------------
dcl-proc copyItems;
  dcl-pi *n;
    pList        pointer value;
    pItemsLength int(10);
    pItems       likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  end-pi;

  dcl-s pItem pointer;
  dcl-ds src likeDS(service_detail_t) based(pItem);

  clear pItemsLength;
  clear pItems;

  if pList = *null;
     return;
  endif;

  pItem = list_iterate(pList);
  dow pItem <> *null and pItemsLength < HTTPREST_MAX_ITEMS;
     pItemsLength += 1;
     pItems(pItemsLength)  = src;

     pItem = list_iterate(pList);
  enddo;
end-proc;


dcl-proc setErrors;
  dcl-pi *n int(10);
    pErrorsMetier likeDS(GLOBAL_listError) const;
    pErrorsResponse likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  end-pi;
  dcl-s lLength int(10);
  monitor;
    // initialisation
    clear pErrorsResponse;
    pErrorsResponse = pErrorsMetier.listError;

    // traitement
    clear lLength;
    sorta(D) pErrorsResponse(*).code;
    lLength = %LookUp(*blanks : pErrorsResponse(*).code
                : 1 : %elem(pErrorsResponse));
      if lLength > 0;          
        lLength -= 1;   
      endif;  
      if lLength = 0 and 
        pErrorsResponse(%elem(pErrorsResponse)).code <> *blanks;
        lLength = %elem(pErrorsResponse);
      endif;                 
    // finalisation 
    return lLength;
  on-error;
        // horreur !  
    clear pErrorsResponse;
    snd-msg *escape ('Horreur ! dans ' + %trim(%proc()));
    return *zeros;
  endmon;
  
end-proc;


dcl-proc addCollectionHeaders;
  dcl-pi *n;
    pTotalCount        like(CMAGIC_totalCount) const;
    pHeaders           like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);
  end-pi;

  clear pHeaders;

  if HTTPREST_nbHeaders >= 1;
     pHeaders(1) = 'X-Total-Count: ' + %trim(%char(pTotalCount));
     CKOOL_logMessage('X-Total-Count ajoute: ' + %trim(%char(pTotalCount)));
  endif;

  if HTTPREST_nbHeaders >= 2;
     pHeaders(2) =
       'Access-Control-Expose-Headers: X-Total-Count';
      CKOOL_logMessage('Header CORS ajoute: Access-Control-Expose-Headers: X-Total-Count');
  endif;
end-proc;
