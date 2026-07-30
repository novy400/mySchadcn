**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        datfmt(*ISO) timfmt(*ISO)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include 'client.rpgleinc'
/include 'sqlStates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'
/include 'sqludtf.rpgleinc'

// test 1
dcl-proc option;
  dcl-pi *n ;
  end-pi;
  exec sql SET OPTION
        COMMIT = *NONE
        , DATFMT = *ISO
        , TIMFMT = *ISO;
end-proc;

dcl-proc client_search export;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-s lSelect varchar(5000);
  dcl-s lSelCount like(lSelect);
  dcl-s lWhere like(lSelect);
  dcl-s lOrderBy like(lSelect);
  dcl-s lItems pointer;
  dcl-ds lItem likeDS(client_item_t);
  dcl-ds lItemSQL likeDS(client_item_sql_t);
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-ds lContext likeds(pContext);
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  //initialisation
  clear pTotalCount;
  clear pItems;
  clear pErrors;
  clear lItems;
  clear lContext;
  lItems = list_create();
  clear lSupportedFields;
  clear lErrors;
  if not client_getSupportedFields(lSupportedFields:lErrors);
  endif;
  
  // Context sanitization (security & defaults)
  if not cmagic_sanitizeContext(pContext: lSupportedFields: lContext: lErrors);
     pErrors = lErrors;
     return *off;
  endif;
   
  // traitement 
  clear lSelect;
 
  // ====================================================================
  // APPEL MODULAIRE : Construction dynamique SQL (Where / Order By)
  // déléguée à CMAGIC en utilisant la configuration des champs.
  // ====================================================================
  if not cmagic_computeSqlClauses(
            lContext: 
            lSupportedFields: 
            lSelect:
            lWhere: 
            lOrderBy: 
            lErrors);
     pErrors = lErrors;
     return *off;
  endif;
  // Construction requête finale
  lSelect += ' from client_liste';

  // Injection des clauses générées
  if lWhere <> *blanks;
    lSelect = %trim(lSelect) + ' ' + %trim(lWhere); 
  endif;
  
  lSelCount = 'select count(*) from (' + %trim(lSelect) +') a';
  
  if lOrderBy <> *blanks;
    lSelect = %trim(lSelect) + ' ' + %trim(lOrderBy); 
  endif;
    // la requete complete avec la pagination 
  lSelect = %trim(lSelect)  + 
  ' LIMIT ' + %char(lContext.pagination.perPage) + 
  ' OFFSET ' + %char((lContext.pagination.numPage - 1) * lContext.pagination.perPage);
  // optimisation 
  lSelect = %trim(lSelect)  + 
  ' FOR READ ONLY OPTIMIZE FOR ' + 
  %char(lContext.pagination.perPage) + 
  ' ROWS';  
   
  // DEBUG
  snd-msg *INFO ('LSELECT ' + %trim(lSelect) + '/');
  //Prepare
  Exec sql prepare SqlStmt From :lSelect;
  Exec sql declare cListe  cursor for SqlStmt;
  //Ouverture du curseur
  Exec SQL open cListe; 
  if (sqlState <> SQL_OK);
    clear lError;
    lError.code = %trim(sqlState);
    // exec sql GET DIAGNOSTICS CONDITION 1 :lError.text = MESSAGE_TEXT;
    CKOOL_ThrowError(lError);
  endif;
  dow (sqlState = SQL_OK);
    //ÂšLecture suivante du curseur
    clear lItemSQL;
    Exec SQL Fetch Next
    From cListe
    Into :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    // ajout de l'item dans la liste
    clear lItem;
    lItem = lItemSQL;
    list_add(lItems: %addr(lItem): %size(lItem));
  
  enddo;
  // comptage total                                       
  //Prepare
  Exec sql prepare SqlStmt2 From :lSelCount;
  //PrÃ©paration du curseur
  Exec sql declare cCountListe  cursor for SqlStmt2;
  //Ouverture du curseur
  Exec SQL open cCountListe; 
  //ÂšLecture suivante du curseur
  clear lCount;
  Exec SQL   FETCH cCountListe into :lCount;   

  // finalisation 
  pItems = lItems;
  pTotalCount = lCount;
  return *on;
  on-exit ErrorHappened;
      //fermeture  du curseur
    Exec SQL close cListe; 
      //fermeture  du curseur
    Exec SQL close cCountListe; 
    if ErrorHappened;
      list_dispose(lItems);
      return *off;
    endif;
end-proc;

// ========================================
// Configuration des champs supportés pour client
// ========================================

///
// Get client supported fields configuration
//
// Initializes a local supported fields configuration.
// Pure function with no side effects.
//
// @param **out** supportedFields  supported fields array to initialize
// @tag client
// @tag REST
// @tag Configuration
///
dcl-proc client_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeds(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lIt int(5);

  // Initialisation.
  clear pErrors;
  clear pSupportedFields; 

  // Traitement.
    // Clear and initialize local array
  clear lSupportedFields;
  clear lIt;
  
    // Configuration des champs client pour filtres REST
  clear lSupportedFields;  
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'codeEtablissement';
  lSupportedFields.supportedFields(lIt).sqlField = 'codeta';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'numeroClient';
  lSupportedFields.supportedFields(lIt).sqlField = 'codcli';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'codeAgence';
  lSupportedFields.supportedFields(lIt).sqlField = 'codage';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'nom';
  lSupportedFields.supportedFields(lIt).sqlField = 'nom';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'prenom';
  lSupportedFields.supportedFields(lIt).sqlField = 'prenom';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'dateNaissance';
  lSupportedFields.supportedFields(lIt).sqlField = 'dtnaiss';
  lSupportedFields.supportedFields(lIt).dataType = 'D';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'codePaysNaissance';
  lSupportedFields.supportedFields(lIt).sqlField = 'paysnaiss';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt;   
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'villeNaissance';
  lSupportedFields.supportedFields(lIt).sqlField = 'vilnaiss';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt;   
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'villeResidence';
  lSupportedFields.supportedFields(lIt).sqlField = 'vilresid';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'telephone1';
  lSupportedFields.supportedFields(lIt).sqlField = 'numtel1';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'telephone2';
  lSupportedFields.supportedFields(lIt).sqlField = 'numtel2';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt;           
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'nombreContrats';
  lSupportedFields.supportedFields(lIt).sqlField = 'nbrctr';
  lSupportedFields.supportedFields(lIt).dataType = 'N';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'totalPret';
  lSupportedFields.supportedFields(lIt).sqlField = 'totPret';
  lSupportedFields.supportedFields(lIt).dataType = 'N';
  lSupportedFields.supportedFields(lIt).orderTri = lIt;
  // tri par name 
  lSupportedFields.fieldsCount = lIt;
  SORTA %SUBARR(lSupportedFields.supportedFields(*).orderTri 
                : 1 : lSupportedFields.fieldsCount);

  // Finalisation.
  pSupportedFields = lSupportedFields;
  return *on;
    
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;

end-proc;


///
// List of client used by UDTF.
//
// Returns pointer to supported fields configuration for client entity.
// Used by REST clients for filtering and validation.
//
// @return pointer to supported fields array
// @tag client
// @tag REST
// @tag Configuration
///
dcl-proc client_table export;
  dcl-pi *N;
    pCodeEtablissement char(3);
    pNumeroClient zoned(7:0);
    pNomClient varchar(38);
    // null indicateur for each parameter
    pNullCodeEtablissement int(5);
    pNullNumeroClient int(5);
    pNullNomClient int(5);
    // SQL parameters
    pStateSQL char(5);
    pFunction varchar(517) const;
    pSpecific varchar(128) const;
    pErrorMsg varchar(1000);
    pCallType int(10) const;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds Ctx likeds(client_table_UdtfCtx);

  // Initialisation.
    clear pCodeEtablissement;
    clear pNumeroClient;
    clear pNomClient;
    clear pNullCodeEtablissement;
    clear pNullNumeroClient;
    clear pNullNomClient;
    pNullNumeroClient = SQLUDTF_PARM_NULL; // Indicateur de null par défaut
    pNullNomClient = SQLUDTF_PARM_NULL;
    pNullCodeEtablissement = SQLUDTF_PARM_NULL;    // Indicateur de null par défaut 
    clear pStateSQL;
    clear pErrorMsg;

  // Traitement.
  exec sql
    declare C1 cursor for
      select 
      codeetablissement,
      numeroclient,nom
        from client_liste
       order by codeetablissement, numeroclient;

  clear Ctx;
  Ctx.NullCodeEtab     = SQLUDTF_PARM_NULL;
  Ctx.NullNumeroClient = SQLUDTF_PARM_NULL;
  Ctx.NullNomClient    = SQLUDTF_PARM_NULL;
  Ctx.StateSQL         = SQLUDTF_SQL_STATE_OK;

  select;
  when pCallType = SQLUDTF_CALL_OPEN;
    Open_Event(Ctx);

  when pCallType = SQLUDTF_CALL_FETCH;
    Fetch_Event(Ctx);

  when pCallType = SQLUDTF_CALL_CLOSE;
    Close_Event(Ctx);

  other;
    Ctx.StateSQL = SQLUDTF_SQL_STATE_ERR;
    Ctx.ErrorMsg = 'Call type non supporte';
  endsl;

  // Finalisation.
  pCodeEtablissement     = Ctx.CodeEtablissement;
  pNumeroClient          = Ctx.NumeroClient;
  pNomClient             = Ctx.NomClient;

  pNullCodeEtablissement = Ctx.NullCodeEtab;
  pNullNumeroClient      = Ctx.NullNumeroClient;
  pNullNomClient         = Ctx.NullNomClient;

  pStateSQL              = Ctx.StateSQL;
  pErrorMsg              = Ctx.ErrorMsg;

  return;
    
  on-exit ErrorHappened;
    if ErrorHappened;
      pStateSQL = SQLUDTF_SQL_STATE_ERR;
      pErrorMsg = 'Error in client_table.';
      return;
    endif;

end-proc;


dcl-proc entityToSQL;
  dcl-pi *n ;
    pDetailEntity likeds(client_detail_t) const;
    pDetailSQL likeDs(client_detail_sql_t);
  end-pi;
  clear pDetailSQL;
  eval pDetailSQL = pDetailEntity;  // Automatique si noms identiques

end-proc;

dcl-proc SQLToEntity;
  dcl-pi *n ;
    pDetailSQL likeDs(client_detail_sql_t) const;
    pDetailEntity likeds(client_detail_t);
  end-pi;
  clear pDetailEntity;
  eval pDetailEntity = pDetailSQL;  // Automatique si noms identiques

end-proc;

dcl-proc Open_Event;
  dcl-pi *n;
    pCtx likeds(client_table_UdtfCtx);
  end-pi;

  clear pCtx.StateSQL;
  clear pCtx.ErrorMsg;

  exec sql
    open C1;

  if sqlcode <> 0;
    pCtx.StateSQL = sqlstate;
    pCtx.ErrorMsg = 'Erreur OPEN sur C1';
    return;
  endif;

  pCtx.Opened   = *on;
  pCtx.StateSQL = SQLUDTF_SQL_STATE_OK;
end-proc;

dcl-proc Fetch_Event;
  dcl-pi *n;
    pCtx likeds(client_table_UdtfCtx);
  end-pi;

  clear pCtx.CodeEtablissement;
  clear pCtx.NumeroClient;
  clear pCtx.NomClient;

  pCtx.NullCodeEtab     = SQLUDTF_PARM_NOTNULL;
  pCtx.NullNumeroClient = SQLUDTF_PARM_NOTNULL;
  pCtx.NullNomClient    = SQLUDTF_PARM_NOTNULL;

  exec sql
    fetch C1
     into :pCtx.CodeEtablissement,
          :pCtx.NumeroClient,
          :pCtx.NomClient;

  select;
  when sqlcode = 0;
    pCtx.StateSQL = SQLUDTF_SQL_STATE_OK;

  when sqlcode = 100;
    pCtx.StateSQL = SQLUDTF_SQL_STATE_EOT;

  other;
    pCtx.StateSQL = sqlstate;
    pCtx.ErrorMsg = 'Erreur FETCH sur C1';
  endsl;
end-proc;

dcl-proc Close_Event;
  dcl-pi *n;
    pCtx likeds(client_table_UdtfCtx);
  end-pi;

  exec sql
    close C1;

  if sqlcode <> 0 and sqlcode <> 100;
    pCtx.StateSQL = sqlstate;
    pCtx.ErrorMsg = 'Erreur CLOSE sur C1';
    return;
  endif;

  pCtx.Opened   = *off;
  pCtx.StateSQL = SQLUDTF_SQL_STATE_OK;
end-proc;