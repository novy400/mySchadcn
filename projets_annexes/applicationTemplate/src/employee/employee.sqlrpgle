**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL');
/include 'employee.rpgleinc'
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

dcl-proc employee_search export;
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
      if not employee_search_local(pContext:pTotalCount:pItems:lErrors);
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

dcl-proc employee_search_local;
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
  dcl-ds lItem likeDS(employee_detail_t);
  dcl-ds lItemSQL likeDS(employee_detail_sql_t);
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
  if not employee_getSupportedFields(lSupportedFields:lErrors);
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
  lSelect += ' FROM employee';

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
  // optimasation 
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


dcl-proc employee_getByID export;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pDetail likeds(employee_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pDetail;
      clear pErrors;
    // traitement
      if not employee_getByID_local(pId:pDetail:lErrors);
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

dcl-proc employee_getByID_local;
  dcl-pi *N ind;
    pId likeDS(employee_detail_t.id) const;
    pDetail likeds(employee_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lDetailSQL likeDS(employee_detail_sql_t);
   
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pDetail;
  clear pErrors;
  
  // SQL query to get employee by ID
  //*********************************************************************
  // TODO: 2.  Indiquer la requete pour le detail <entity>_detail_sql_t
  //           de l'entité.   c'est meiux avec une vue             
  Exec SQL
    SELECT empno,
      ifnull(firstnme, ''),
      ifnull(lastname, ''), 
      ifnull(midinit, ''),
      ifnull(workdept, ''),
      ifnull(phoneno, ''),
      ifnull(hiredate, '0001-01-01'),
      ifnull(job, ''),
      ifnull(edlevel, 0),
      ifnull(birthdate, '0001-01-01'),
      ifnull(sex, ''),
      ifnull(salary, 0),
      ifnull(bonus, 0),
      ifnull(comm, 0)
    INTO :lDetailSQL
    FROM employee
    WHERE empno = :pId.code;
  //*********************************************************************

  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'EMP001';
      lError.text = 'Employee not found';
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
      CKOOL_logMessage('Employee found: ' + 
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

dcl-proc employee_update export;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pDetail likeds(employee_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(employee_detail_t);
      dcl-ds lDetailAfter likeds(employee_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la modification
      // contrôle de l'action - récupération de l'existant
        if not employee_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        lDetailAfter = pDetail;
        clear lErrors;
        if not employee_isValid_local(employee_listeAction.modification
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // modification métier
        clear lErrors;
        if not employee_update_local(pId:pDetail:lErrors);
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
dcl-proc employee_update_local;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pDetail likeds(employee_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lRowsAffected int(10);
  dcl-ds lDetailSQL likeds(employee_detail_sql_t);  
  // initialisation
  clear pErrors;

  // SQL query to update employee
  clear lDetailSQL;
  entityToSQL(pDetail:lDetailSQL);

  Exec SQL
    UPDATE employee
    SET firstnme = :lDetailSQL.prenom,
        lastname = :lDetailSQL.nom,
        midinit = :lDetailSQL.initiale,
        workdept = :lDetailSQL.idService,
        phoneno = :lDetailSQL.numeroTelephone,        
        hiredate = :lDetailSQL.dateEmbauche,
        job=:lDetailSQL.profession, 
        edlevel=:lDetailSQL.niveau,         
        birthdate = :lDetailSQL.dateNaissance,
        sex = :lDetailSQL.genre,
        salary = :lDetailSQL.salaire,
        bonus = :lDetailSQL.prime,
        comm = :lDetailSQL.commission
    WHERE empno = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'EMP001';
      lError.text = 'Employee not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating employee';
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
        lError.code = 'EMP001';
        lError.text = 'Employee not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Employee updated: ' + 
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

dcl-proc employee_delete export;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(employee_detail_t);
      dcl-ds lDetailAfter likeds(employee_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la suppression
      // contrôle de l'action - récupération de l'existant
        if not employee_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        clear lDetailAfter;
        clear lErrors;
        if not employee_isValid_local(employee_listeAction.suppression
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // suppression métier
        clear lErrors;
        if not employee_delete_local(pId:lErrors);
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
dcl-proc employee_delete_local;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to delete employee
  Exec SQL
    DELETE FROM employee
    WHERE empno = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'EMP001';
      lError.text = 'Employee not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting employee';
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
        lError.code = 'EMP001';
        lError.text = 'Employee not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Employee deleted: ' + 
        %trim(pId.code));
  endsl;
  
  // finalisation
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;


dcl-proc employee_create export;
  dcl-pi *N ind;
    pDetail likeds(employee_detail_t) const;
    pId likeDS(employee_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(employee_detail_t);
      dcl-ds lDetailAfter likeds(employee_detail_t);
      dcl-ds lId likeDS(employee_id_t);
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
        if not employee_isValid(employee_listeAction.creation
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // création métier
        clear lId;
        clear lErrors;
        if not employee_create_local(pDetail:lId:lErrors);
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
dcl-proc employee_create_local;
  dcl-pi *N ind;
    pDetail likeds(employee_detail_t) const;
    pId likeDS(employee_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lNewCode char(6);
  dcl-s lEdLevel int(5);
  
  // initialisation
  clear pId;
  clear pErrors;

  // SQL query to create employee using FINAL TABLE to get the inserted record
  clear lEdLevel;
  lEdLevel = 18; 
  Exec SQL
    SELECT empno
    INTO :lNewCode
    FROM FINAL TABLE (
      INSERT INTO employee
      (empno, firstnme, lastname, midinit, workdept, 
      phoneno,
      hiredate, job, edlevel,
      birthdate, sex, 
      salary, bonus,comm)
      VALUES
      ((SELECT max(empno)  + 10 FROM employee), 
       :pDetail.prenom, :pDetail.nom, :pDetail.initiale, 
       :pDetail.idService, :pDetail.numeroTelephone,
       :pDetail.dateEmbauche, :pDetail.profession, :pDetail.niveau, 
       :pDetail.dateNaissance, :pDetail.genre,
       :pDetail.salaire, :pDetail.prime, :pDetail.commission)
    );
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error creating employee';
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
      CKOOL_logMessage('Employee created: ' + 
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


dcl-proc employee_display export;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement
      if not employee_display_local(pId:lErrors);
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
dcl-proc employee_display_local;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lError likeds(errorItem) inz;
  
  // initialisation
  clear pErrors;
  clear lDetail;
  
  // Call getByID to retrieve employee details
  if not employee_getByID_local(pId : lDetail : pErrors);
    return *off;
  endif;
  
  // Display employee details (simple console output)
  CKOOL_logMessage('=== Employee Details ===');
  CKOOL_logMessage('ID: ' + %trim(lDetail.id.code));
  CKOOL_logMessage('Nom: ' + %trim(lDetail.nom) + ' ' + 
    %trim(lDetail.nom));
  CKOOL_logMessage('Initial: ' + %trim(lDetail.initiale));
  CKOOL_logMessage('Service: ' + %trim(lDetail.idService));
  CKOOL_logMessage('Date embauche: ' + %char(lDetail.dateEmbauche));
  CKOOL_logMessage('Profession: ' + %trim(lDetail.profession));
  CKOOL_logMessage('Niveau: ' + %char(lDetail.niveau));  
  CKOOL_logMessage('Date naissance: ' + %char(lDetail.dateNaissance));
  CKOOL_logMessage('Genre: ' + %trim(lDetail.genre));
  CKOOL_logMessage('Salaire: ' + %editc(lDetail.salaire : 'L'));
  CKOOL_logMessage('Prime: ' + %editc(lDetail.prime : 'L'));
  CKOOL_logMessage('Commission: ' + %editc(lDetail.commission : 'L'));    
  CKOOL_logMessage('========================');
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc employee_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in employee_listeAction
    pBeforeDetail likeds(employee_detail_t) Const;
    pAfterDetail likeds(employee_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear lErrors;
    // traitement
      if not employee_isValid_local(pAction
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
dcl-proc employee_isValid_local;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in employee_listeAction
    pBeforeDetail likeds(employee_detail_t) Const;
    pAfterDetail likeds(employee_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s it int(3);
  dcl-s ErrorHappened ind;
  
  //initialisation
  clear pErrors;
  clear it;
  
  // Validate based on action type
  select;
    when pAction = employee_listeAction.creation 
      or pAction = employee_listeAction.modification;
      
      // Prenom is mandatory
      if pAfterDetail.prenom = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0001';
        pErrors.listError(it).textUser = 'Prénom obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'prenom';
      endif;
      
      // Nom is mandatory
      if pAfterDetail.nom = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0002';
        pErrors.listError(it).textUser = 'Nom obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'nom';
      endif;
      
      // Genre must be valid
      if not (pAfterDetail.genre in employee_listeGenre);
        it += 1;
        pErrors.listError(it).code = 'EMP0003';
        pErrors.listError(it).textUser = 'Genre invalide (M ou F) !';
        pErrors.listError(it).text = 'Valeur invalide';
        pErrors.listError(it).nomZone = 'genre';
      endif;
      
      // Service is mandatory
      if pAfterDetail.idService = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0004';
        pErrors.listError(it).textUser = 'Service obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'service';
      endif;
      
      // Salary must be positive
      if pAfterDetail.salaire <= 0;
        it += 1;
        pErrors.listError(it).code = 'EMP0005';
        pErrors.listError(it).textUser = 'Salaire doit être positif !';
        pErrors.listError(it).text = 'Valeur invalide';
        pErrors.listError(it).nomZone = 'salaire';
      endif;
      
      // Birth date must be in the past
      if pAfterDetail.dateNaissance >= %date();
        it += 1;
        pErrors.listError(it).code = 'EMP0006';
        pErrors.listError(it).textUser = 'Date de naissance invalide !';
        pErrors.listError(it).text = 'Date doit être antérieure à aujourd''hui';
        pErrors.listError(it).nomZone = 'dateNaissance';
      endif;
      
      // Hire date validation
      if pAfterDetail.dateEmbauche > %date();
        it += 1;
        pErrors.listError(it).code = 'EMP0007';
        pErrors.listError(it).textUser = 'Date d''embauche ne peut être future !';
        pErrors.listError(it).text = 'Date invalide';
        pErrors.listError(it).nomZone = 'dateEmbauche';
      endif;
      
    when pAction = employee_listeAction.suppression;
      // For deletion, we only need to check if ID exists
      if pBeforeDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0008';
        pErrors.listError(it).textUser = 'ID employé obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    when pAction = employee_listeAction.consultation;
      // For consultation, only ID is required
      if pBeforeDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0009';
        pErrors.listError(it).textUser = 'ID employé obligatoire pour consultation !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    other;
      // Unknown action
      it += 1;
      pErrors.listError(it).code = 'EMP0010';
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
// Configuration des champs supportés pour Employee
// ========================================

///
// Get Employee supported fields configuration
//
// Initializes a local supported fields configuration.
// Pure function with no side effects.
//
// @param **out** supportedFields  supported fields array to initialize
// @tag Employee
// @tag REST
// @tag Configuration
///
dcl-proc employee_getSupportedFields export;
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
  
    // Configuration des champs Employee pour filtres REST
  clear lSupportedFields;  
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'id';
  lSupportedFields.supportedFields(lIt).sqlField = 'empno';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'prenom';
  lSupportedFields.supportedFields(lIt).sqlField = 'firstnme';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'nom';
  lSupportedFields.supportedFields(lIt).sqlField = 'lastname';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'initiale';
  lSupportedFields.supportedFields(lIt).sqlField = 'midinit';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'idService';
  lSupportedFields.supportedFields(lIt).sqlField = 'workdept';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'numeroTelephone';
  lSupportedFields.supportedFields(lIt).sqlField = 'phoneno';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'dateEmbauche';
  lSupportedFields.supportedFields(lIt).sqlField = 'hiredate';
  lSupportedFields.supportedFields(lIt).dataType = 'D';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'profession';
  lSupportedFields.supportedFields(lIt).sqlField = 'job';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'niveau';
  lSupportedFields.supportedFields(lIt).sqlField = 'edlevel';
  lSupportedFields.supportedFields(lIt).dataType = 'N';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'dateNaissance';
  lSupportedFields.supportedFields(lIt).sqlField = 'birthdate';
  lSupportedFields.supportedFields(lIt).dataType = 'D';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'genre';
  lSupportedFields.supportedFields(lIt).sqlField = 'sex';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'salaire';
  lSupportedFields.supportedFields(lIt).sqlField = 'salary';
  lSupportedFields.supportedFields(lIt).dataType = 'N';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'prime';
  lSupportedFields.supportedFields(lIt).sqlField = 'bonus';
  lSupportedFields.supportedFields(lIt).dataType = 'N';
  lSupportedFields.supportedFields(lIt).orderTri = lIt; 
  lIt += 1;
  lSupportedFields.supportedFields(lIt).name = 'commission';
  lSupportedFields.supportedFields(lIt).sqlField = 'comm';
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


dcl-proc entityToSQL;
  dcl-pi *n ;
    pDetailEntity likeds(employee_detail_t) const;
    pDetailSQL likeDs(employee_detail_sql_t);
  end-pi;
  clear pDetailSQL;
  eval pDetailSQL = pDetailEntity;  // Automatique si noms identiques

end-proc;

dcl-proc SQLToEntity;
  dcl-pi *n ;
    pDetailSQL likeDs(employee_detail_sql_t) const;
    pDetailEntity likeds(employee_detail_t);
  end-pi;
  clear pDetailEntity;
  eval pDetailEntity = pDetailSQL;  // Automatique si noms identiques

end-proc;