**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL');
/include 'service.rpgleinc'
/include 'sqlStates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'

// test 1
dcl-proc option;
  dcl-pi *n ;
  end-pi;
  exec sql SET OPTION
        COMMIT = *NONE
        , DATFMT = *ISO;
end-proc;

dcl-proc service_search export;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pTotalCount;
      clear pItems;
      clear pErrors;
    // traitement
      if not service_search_local(pContext:pTotalCount:pItems:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_search_local;
  dcl-pi *N ind;
    pContext likeDS(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pItems pointer;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-s lSelect varchar(5000);
  dcl-s lSelCount like(lSelect);
  dcl-s lWhere like(lSelect);
  dcl-s lOrderBy like(lSelect);
  dcl-s lItems pointer;
  dcl-ds lItem likeDS(service_detail_t);
  dcl-ds lItemSQL likeDS(service_detail_sql_t);
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind ;
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
  if not service_getSupportedFields(lSupportedFields:lErrors);
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
  lSelect += ' FROM department';

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


dcl-proc service_getByID export;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pDetail likeds(service_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pDetail;
      clear pErrors;
    // traitement
      if not service_getByID_local(pId:pDetail:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_getByID_local;
  dcl-pi *N ind;
    pId likeDS(service_detail_t.id) const;
    pDetail likeds(service_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lDetailSQL likeDS(service_detail_sql_t);
   
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pDetail;
  clear pErrors;
  
  // SQL query to get Service by ID
  //*********************************************************************
  // TODO: 2.  Indiquer la requete pour le detail <entity>_detail_sql_t
  //           de l'entité.   c'est meiux avec une vue             
  Exec SQL
    select deptno,
    ifnull(deptname, ''),
    ifnull(mgrno, ''),
    ifnull(admrdept, ''),
    ifnull(location, '')
    INTO :lDetailSQL
    FROM Department
    WHERE deptno = :pId.code;
  //*********************************************************************

  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'SER0001';
      lError.text = 'Service not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
        // Log the error
      CKOOL_LogError(lError);
        // on lève une exception
      CKOOL_ThrowError(lError);
      return *off;
    other;
        // on continue normalement
      CKOOL_logMessage('Service found: ' + 
          %trim(lDetailSQL.code) + ' - ' + 
          %trim(lDetailSQL.nom));
  endsl;

  
  // Map SQL result to output structure
  SQLToEntity(lDetailSQL:pDetail);
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_update export;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pDetail likeds(service_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(service_detail_t);
      dcl-ds lDetailAfter likeds(service_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la modification
      // contrôle de l'action - récupération de l'existant
        if not service_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        lDetailAfter = pDetail;
        clear lErrors;
        if not service_isValid_local(service_listeAction.modification
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // modification métier
        clear lErrors;
        if not service_update_local(pId:pDetail:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// Implémentation locale - Mise à jour
dcl-proc service_update_local;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pDetail likeds(service_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lRowsAffected int(10);
  dcl-ds lDetailSQL likeds(service_detail_sql_t);  
  
  // initialisation
  clear pErrors;

  // SQL query to update Service
  clear lDetailSQL;
  entityToSQL(pDetail:lDetailSQL);
  
  Exec SQL
    UPDATE Department
    SET DEPTNAME = :lDetailSQL.nom,
        MGRNO = :lDetailSQL.codeManageur,
        ADMRDEPT = :lDetailSQL.codeServiceAdmin,
        LOCATION = :lDetailSQL.site
    WHERE deptno = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'SER0001';
      lError.text = 'Service not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating Service';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      // // on lève une exception
      // CKOOL_ThrowError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'SER0001';
        lError.text = 'Service not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Service updated: ' + 
        %trim(pId.code) + ' - ' + 
        %trim(pDetail.nom));
  endsl;
  
  // finalisation
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_delete export;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(service_detail_t);
      dcl-ds lDetailAfter likeds(service_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la suppression
      // contrôle de l'action - récupération de l'existant
        if not service_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        clear lDetailAfter;
        clear lErrors;
        if not service_isValid_local(service_listeAction.suppression
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // suppression métier
        clear lErrors;
        if not service_delete_local(pId:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// Implémentation locale - Suppression
dcl-proc service_delete_local;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to delete Service
  Exec SQL
    DELETE FROM Department
    WHERE DEPTNO = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'SER0001';
      lError.text = 'Service not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting Service';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      // // on lève une exception
      // CKOOL_ThrowError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'SER0001';
        lError.text = 'Service not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Service deleted: ' + 
        %trim(pId.code));
  endsl;
  
  // finalisation
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;


dcl-proc service_create export;
  dcl-pi *N ind;
    pDetail likeds(service_detail_t) const;
    pId likeDS(service_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(service_detail_t);
      dcl-ds lDetailAfter likeds(service_detail_t);
      dcl-ds lId likeDS(service_id_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pId;
      clear pErrors;
      clear lId;
      clear lErrors;
    // traitement de la création
      // contrôle de l'action
        clear lDetailBefore;
        clear lDetailAfter;
        clear lErrors;
        lDetailBefore = pDetail;
        lDetailAfter = pDetail;
        if not service_isValid(service_listeAction.creation
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // création métier
        clear lId;
        clear lErrors;
        if not service_create_local(pDetail:lId:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      pId = lId;
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// Implémentation locale - Création
dcl-proc service_create_local;
  dcl-pi *N ind;
    pDetail likeds(service_detail_t) const;
    pId likeDS(service_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lNewCode char(6);
  
  // initialisation
  clear pId;
  clear pErrors;

  // SQL query to create Service using FINAL TABLE to get the inserted record
  Exec SQL
    SELECT DEPTNO
    INTO :lNewCode
    FROM FINAL TABLE (
      INSERT INTO Department
      (DEPTNO, DEPTNAME, MGRNO, ADMRDEPT, LOCATION)
      VALUES
      ((SELECT max(DEPTNO)  + 10 FROM Department), 
       :pDetail.nom, :pDetail.idManageur, 
       :pDetail.idServiceAdmin, :pDetail.site)
    );
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error creating Service';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      CKOOL_LogError(lError);
      return *off;
    other;
      // on continue normalement
      pId.code = lNewCode;
      CKOOL_logMessage('Service created: ' + 
        %trim(lNewCode) + ' - ' + 
        %trim(pDetail.nom));
  endsl;
  
  // finalisation
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;


dcl-proc service_display export;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement
      if not service_display_local(pId:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// Implémentation locale - Affichage
dcl-proc service_display_local;
  dcl-pi *N ind;
    pId likeDS(service_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lError likeds(errorItem) inz;
  
  // initialisation
  clear pErrors;
  clear lDetail;
  
  // Call getByID to retrieve Service details
  if not service_getByID_local(pId : lDetail : pErrors);
    return *off;
  endif;
  
  // Display Service details (simple console output)
  CKOOL_logMessage('=== Service Details ===');
  CKOOL_logMessage('ID: ' + %trim(lDetail.id.code));
  CKOOL_logMessage('Name: ' + %trim(lDetail.nom));
  CKOOL_logMessage('Manageur: ' + %trim(lDetail.idManageur));
  CKOOL_logMessage('Service Admin: ' + %trim(lDetail.idServiceAdmin));
  CKOOL_logMessage('Location: ' + %trim(lDetail.site));
  CKOOL_logMessage('========================');
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in service_listeAction
    pBeforeDetail likeds(service_detail_t) Const;
    pAfterDetail likeds(service_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear lErrors;
    // traitement
      if not service_isValid_local(pAction
              :pBeforeDetail:pAfterDetail:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// Implémentation locale - Validation
dcl-proc service_isValid_local;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in service_listeAction
    pBeforeDetail likeds(service_detail_t) Const;
    pAfterDetail likeds(service_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s it int(3);
  dcl-s ErrorHappened ind;
  
  //initialisation
  clear pErrors;
  clear it;
  
  // Validate based on action type
  select;
    when pAction = service_listeAction.creation 
      or pAction = service_listeAction.modification;
      
      
      // Nom is mandatory
      if pAfterDetail.nom = *blanks;
        it += 1;
        pErrors.listError(it).code = 'SERR0002';
        pErrors.listError(it).textUser = 'Nom obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'nom';
      endif;
      
      // Service Administratif is mandatory
      if pAfterDetail.idServiceAdmin = *blanks;
        it += 1;
        pErrors.listError(it).code = 'SERR0003';
        pErrors.listError(it).textUser = 'Service Administratif obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'idServiceAdmin';
      endif;

      // TODO: Service Administratif doit exister
      
    when pAction = service_listeAction.suppression;
      // For deletion, we only need to check if ID exists
      if pBeforeDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'SER0004';
        pErrors.listError(it).textUser = 'ID Service obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    when pAction = service_listeAction.consultation;
      // For consultation, only ID is required
      if pBeforeDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'SER0004';
        pErrors.listError(it).textUser = 'ID Service obligatoire pour consultation !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    other;
      // Unknown action
      it += 1;
      pErrors.listError(it).code = 'SER0010';
      pErrors.listError(it).textUser = 'Action inconnue !';
      pErrors.listError(it).text = 'Action non supportée';
      pErrors.listError(it).nomZone = 'action';
  endsl;
  
  // If errors found, return false
  if it > 0;
    return *off;
  endif;
  
  // finalisation  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;



// ========================================
// Configuration des champs supportés pour Service
// ========================================

///
// Get Service supported fields configuration
//
// Initializes a local supported fields configuration.
// Pure function with no side effects.
//
// @param **out** supportedFields  supported fields array to initialize
// @tag Service
// @tag REST
// @tag Configuration
///
dcl-proc service_getSupportedFields export;
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
  
    // Configuration des champs Service pour filtres REST
  clear lSupportedFields;  
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'id';
  lSupportedFields.supportedFields(lIt).sqlField = 'deptno';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'nom';
  lSupportedFields.supportedFields(lIt).sqlField = 'deptname';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'idManageur';
  lSupportedFields.supportedFields(lIt).sqlField = 'mgrno';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'idServiceAdmin';
  lSupportedFields.supportedFields(lIt).sqlField = 'admrdept';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'site';
  lSupportedFields.supportedFields(lIt).sqlField = 'location';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
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


dcl-proc entityToSQL;
  dcl-pi *n ;
    pDetailEntity likeds(service_detail_t) const;
    pDetailSQL likeDs(service_detail_sql_t);
  end-pi;
  clear pDetailSQL;
  eval pDetailSQL = pDetailEntity;  // Automatique si noms identiques

end-proc;

dcl-proc SQLToEntity;
  dcl-pi *n ;
    pDetailSQL likeDs(service_detail_sql_t) const;
    pDetailEntity likeds(service_detail_t);
  end-pi;
  clear pDetailEntity;
  eval pDetailEntity = pDetailSQL;  // Automatique si noms identiques

end-proc;