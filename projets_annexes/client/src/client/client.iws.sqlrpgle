**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        pgminfo(*pcml:*module:*dclcase)
        datfmt(*iso)
        bnddir('QC2LE':'CLIENT':'CKOOL':'NOXDB');

/include 'client.rpgleinc'
/include 'clientiws.rpgleinc'
/include 'ciws.rpgleinc'
/include 'ckool.rpgleinc'
/include 'clog.rpgleinc'
/include 'llist/llist_h.rpgle'
/include 'ileastic/noxdb.rpgleinc'



// ------------------------------------------------------------
// GET LIST
// ------------------------------------------------------------
dcl-proc client_getlist_iws export;
  dcl-pi *n;
    items_LENGTH int(10);
    items likeDS(client_item_rest_t) dim(HTTPREST_MAX_ITEMS);
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
  dcl-ds lEvent likeDS(CLOG_event);
  dcl-ds lOptions likeds(CKOOL_dsToCharOptions_t);

  //initialisation des paramètres de sortie
  clear items_LENGTH;
  clear items;
  clear totalCount;
  clear errors_LENGTH;
  clear errors;
  clear httpStatus;
  clear httpHeaders;
  httpStatus = HTTPREST_OK;
  clear lOptions;
  lOptions.quote = '''';
  lOptions.separator = ' - ';


  if not client_getSupportedFields(lSupportedFields : lErrors);
     httpStatus = HTTPREST_SERVERERROR;
     clear errors_LENGTH;
     errors_LENGTH = setErrors(lErrors:errors);
     clear lEvent;
     CLOG_logError(%proc() :'client_getSupportedFields' 
        : 'Failed to get supported fields configuration for client'
        : %char(lErrors));
     return;
  endif;

  // test ok 
  clear lEvent;
  data-gen lSupportedFields %data(lEvent.details)
           %gen(CKOOL_genDsToChar : lOptions);
  CLOG_logInfo(%proc() :'client_getlist_iws' 
        : 'Determination of supported fields for client entity'
        : %char(lEvent.details));

  if not CIWS_initRestRequest(lSupportedFields : lContext : lErrors);
     httpStatus = HTTPREST_BADREQUEST;
     clear errors_LENGTH;
     errors_LENGTH = setErrors(lErrors:errors);
     return;
  endif;
  // test ok 
  clear lEvent;
  data-gen lContext %data(lEvent.details)
           %gen(CKOOL_genDsToChar : lOptions);
  CLOG_logInfo(%proc() :'client_getlist_iws' 
        : 'Calcul du contexte de recherche pour client'
        : %char(lEvent.details));

  if not client_search(lContext : totalCount : lItems : lErrors);
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
          errors(1).nomZone = 'client_getlist_iws';
          errors(1).code = 'RNX9001';
          errors(1).text = 'Unexpected error in clientiws_getList';
          errors(1).textUser = 'Unexpected error in clientiws_getList';
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
    pItems       likeDS(client_item_rest_t) dim(HTTPREST_MAX_ITEMS);
  end-pi;

  dcl-s pItem pointer;
  dcl-ds src likeDS(client_detail_t) based(pItem);
  dcl-ds lDetailRest likeDS(client_item_rest_t) inz;
  

  clear pItemsLength;
  clear pItems;

  if pList = *null;
     return;
  endif;

  pItem = list_iterate(pList);
  dow pItem <> *null and pItemsLength < HTTPREST_MAX_ITEMS;
     pItemsLength += 1;
     // TODO: client metier vers client iw liste   
     clear lDetailRest;
     entityToRest(src : lDetailRest);
     pItems(pItemsLength)  = lDetailRest;

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

dcl-proc entityToRest;
  dcl-pi *n ;
    pDetailEntity likeds(client_detail_t) const;
    pDetailRest likeDs(client_item_rest_t);
  end-pi;
  dcl-ds lDetailRest likeDS(client_item_rest_t) inz;
  dcl-ds lDetailSql likeds(client_detail_sql_t) inz;
  dcl-ds lDetailID likeds(client_id_t) inz;

  clear pDetailRest;
  // on aplatit l'id pour faciliter l'exposition IWS
  clear lDetailID;
  lDetailID = pDetailEntity.id;
  clear lDetailSql;
  lDetailSql = pDetailEntity;
  clear lDetailRest;
  eval-corr lDetailRest = lDetailSql;
  lDetailRest.nom = lDetailSql.nomClient;
  lDetailRest.prenom = lDetailSql.prenomClient;
  lDetailRest.id = lDetailID; 
  eval pDetailRest = lDetailRest;  // Automatique si noms identiques

end-proc;