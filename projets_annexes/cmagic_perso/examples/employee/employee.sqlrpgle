**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
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

// Implémentation locale - Recherche
dcl-proc employee_search_local;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-s lLimit int(10);
  dcl-s lOffset int(10);
  dcl-s lSelect char(5000);
  dcl-s lSelCount like(lSelect);
  dcl-s lWhere like(lSelect);
  dcl-s lOrderBy like(lSelect);
  dcl-s lFirst ind;
  dcl-ds lItemFiltre likeDS(CMAGIC_filter);
  dcl-ds lItemSort likeDS(CMAGIC_sort);
  dcl-s lItems pointer;
  dcl-ds lItem likeDS(employee_item_t);

  dcl-ds lItemSQL qualified;
    code char(6);
    prenom like(employee_detail_t.prenom);    
    nom like(employee_detail_t.nom);
    initiale like(employee_detail_t.initiale);
    service like(employee_detail_t.service);
  end-ds;
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);
  dcl-s dbFieldName varchar(32);
  dcl-s isNumericField ind;
  dcl-ds lContext likeds(pContext);
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lIt int(5);
  //initialisation
    clear pTotalCount;
    clear pItems;
    clear pErrors;
    clear lItems;
    clear lContext;
    lContext = pContext;
    lItems = list_create();
    clear lSupportedFields;
    clear lErrors;
    if not employee_getSupportedFields(lSupportedFields:lErrors);
    endif;
  // contrôle context.
   
  // limit => number of rows per page
    lLimit = pContext.pagination.perPage;
  // offset start
    lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
    if lLimit < 1;
      lLimit = CMAGIC_DEFAULT_LIMIT;
    endif;    
  // traitement 
    clear lSelect;
    lSelect = 'select empno, firstnme, lastname, midinit, workdept ' 
            + ' from employee';
    // filtre 
    clear lWhere;
    lFirst = *on;
    SORTA(D) lContext.filter(*).field; 
    for-each lItemFiltre in lContext.filter;
      if %len(%trim(lItemFiltre.field)) = *zeros;
        leave;
      endif;
      
      if lFirst;
        lWhere = 'WHERE';
        lFirst = *off;
      else;
        lWhere = %trim(lWhere) + ' AND' ;
      endif;
      
      // Traitement spécial pour la recherche générale 'q'
      if %trim(lItemFiltre.field) = 'q';
        // Recherche sur plusieurs champs pour 'q' (nom, prenom, service)
        lWhere = ' ' + %trim(lWhere) + ' (';
        lWhere = %trim(lWhere) + 'UPPER(lastname) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ' OR UPPER(firstnme) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ' OR UPPER(workdept) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
        lWhere = %trim(lWhere) + ')';
      else;
        // Filtres normaux avec operator explicite
        clear lString;
        lString = %trim(lItemFiltre.value);
        // chercher dans la liste des champs supportés
        isNumericField = *off;
        SORTA(D) lSupportedFields.supportedFields(*).name;  

        clear lIt;
        lIt = %lookup(%trim(lItemFiltre.field)
          :lSupportedFields.supportedFields(*).name);
        // Vérifier si le champ est numérique
        if lIt > 0;
          if lSupportedFields.supportedFields(lIt).dataType = typeChamp.NUMERIC;
            isNumericField = *on;
          endif;
          // Mapper les noms de champs vers les noms de colonnes DB
          clear dbFieldName;
          dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
        else;
          iter;
        endif;
        
        if not (%trim(lItemFiltre.operator) = CMAGIC_OP_LIKE);
          if not isNumericField;
            lWhere = ' ' + %trim(lWhere) + ' upper(' + %trim(dbFieldName) + ')';
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          else;  
            lWhere = ' ' + %trim(lWhere) + '  ' + %trim(dbFieldName) ;
          endif;
        else;  
          lWhere = ' ' + %trim(lWhere) + ' upper(' + %trim(dbFieldName) + ')';
        endif;
        // Utiliser l'operator du filtre
        select;
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LIKE;
            lWhere = ' ' + %trim(lWhere) + ' LIKE ';
            // S'assurer que la valeur contient des % pour LIKE
            if %scan('%' : %trim(lString)) = 0;
              lString = '%' + %trim(lString) + '%';
            endif;
            lWhere = %trim(lWhere) + ' UPPER(' 
              + GLOBAL_QUOTE + %upper(%trim(lString)) + GLOBAL_QUOTE + ')';
          when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' >= ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' <= ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_GREATER;
            lWhere = ' ' + %trim(lWhere) + ' > ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_LESS;
            lWhere = ' ' + %trim(lWhere) + ' < ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          when %trim(lItemFiltre.operator) = CMAGIC_OP_NOT_EQUAL;
            lWhere = ' ' + %trim(lWhere) + ' <> ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
          other; // CMAGIC_OP_EQUAL ou par défaut
            lWhere = ' ' + %trim(lWhere) + ' = ';
            lWhere = %trim(lWhere) + ' ' + %trim(lString);
        endsl;
      endif;
    endfor;
    if lWhere <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lWhere); 
    endif;
    lSelCount = 'select count(*) from (' +
    %trim(lSelect) +') a';
    // DEBUG
    snd-msg *INFO ('LSELECT ' + %trim(lSelect) + '/');
    // le tri 
    clear lOrderBy;
    lFirst = *on;
    SORTA(D) lContext.sort(*).field; 
    for-each lItemSort in lContext.sort;
      if %len(%trim(lItemSort.field)) = *zeros;
        leave;
      endif;
      // Mapper les noms de champs vers les noms de colonnes DB ***
      clear dbFieldName;
      clear lIt;
      lIt = %lookup(%trim(lItemSort.field)
         :lSupportedFields.supportedFields(*).name);
      if lIt > *zeros;
        dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
      else;
        iter;
      endif;  
      if lFirst;
        lOrderBy = 'Order by';
        lFirst = *off;
      else;
        lOrderBy = %trim(lOrderBy) + ' ,' ;
      endif;
      lOrderBy = ' ' +%trim(lOrderBy) + ' ' + %trim(dbFieldName);
      lOrderBy = ' ' + %trim(lOrderBy) + ' ' + %trim(lItemSort.order); 
    endfor;
    if lOrderBy <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lOrderBy); 
    endif;
    // la requete complete avec la pagination 
    lSelect = %trim(lSelect)  + 
  ' LIMIT ' + %char(lLimit) + 
  ' OFFSET ' + %char(lOffset);
  //Prepare
    Exec sql prepare SqlStmt From :lSelect;
  //PrÃ©paration du curseur
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

// Implémentation locale - GetByID
dcl-proc employee_getByID_local;
  dcl-pi *N ind;
    pId likeDS(employee_id_t) const;
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
  Exec SQL
    SELECT empno, firstnme, lastname, midinit, workdept, 
           hiredate, birthdate, sex, salary
    INTO :lDetailSQL
    FROM employee
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
  eval-corr pDetail = lDetailSQL;
  pDetail.id.code = lDetailSQL.code;
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
  
  // initialisation
  clear pErrors;

  // SQL query to update employee
  Exec SQL
    UPDATE employee
    SET firstnme = :pDetail.prenom,
        lastname = :pDetail.nom,
        midinit = :pDetail.initiale,
        workdept = :pDetail.service,
        hiredate = :pDetail.dateEmbauche,
        birthdate = :pDetail.dateNaissance,
        sex = :pDetail.genre,
        salary = :pDetail.salaire
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
       hiredate, birthdate, sex, salary, edlevel)
      VALUES
      ((SELECT max(empno)  + 10 FROM employee), 
       :pDetail.prenom, :pDetail.nom, :pDetail.initiale, 
       :pDetail.service, :pDetail.dateEmbauche, :pDetail.dateNaissance, 
       :pDetail.genre, :pDetail.salaire, :lEdLevel)
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
  CKOOL_logMessage('Name: ' + %trim(lDetail.prenom) + ' ' + 
    %trim(lDetail.nom));
  CKOOL_logMessage('Initial: ' + %trim(lDetail.initiale));
  CKOOL_logMessage('Department: ' + %trim(lDetail.service));
  CKOOL_logMessage('Hire Date: ' + %char(lDetail.dateEmbauche));
  CKOOL_logMessage('Birth Date: ' + %char(lDetail.dateNaissance));
  CKOOL_logMessage('Gender: ' + %trim(lDetail.genre));
  CKOOL_logMessage('Salary: ' + %editc(lDetail.salaire : 'L'));
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
      if pAfterDetail.service = *blanks;
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
      if pAfterDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0008';
        pErrors.listError(it).textUser = 'ID employé obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    when pAction = employee_listeAction.consultation;
      // For consultation, only ID is required
      if pAfterDetail.id.code = *blanks;
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

  // Initialisation.
    clear pErrors;
    clear pSupportedFields; 

  // Traitement.
    // Clear and initialize local array
      clear lSupportedFields;
  
    // Configuration des champs Employee pour filtres REST
      clear lSupportedFields;  
      lSupportedFields.supportedFields(1).name = 'nom';
      lSupportedFields.supportedFields(1).sqlField = 'lastname';
      lSupportedFields.supportedFields(1).dataType = 'C';
      lSupportedFields.supportedFields(2).name = 'prenom';
      lSupportedFields.supportedFields(2).sqlField = 'firstnme';
      lSupportedFields.supportedFields(2).dataType = 'C';
      lSupportedFields.supportedFields(3).name = 'initiale';
      lSupportedFields.supportedFields(3).sqlField = 'midinit';
      lSupportedFields.supportedFields(3).dataType = 'C';
      lSupportedFields.supportedFields(4).name = 'service';
      lSupportedFields.supportedFields(4).sqlField = 'workdept';
      lSupportedFields.supportedFields(4).dataType = 'C';
      lSupportedFields.supportedFields(5).name = 'salaire';
      lSupportedFields.supportedFields(5).sqlField = 'salary';
      lSupportedFields.supportedFields(5).dataType = 'N';
      lSupportedFields.supportedFields(6).name = 'id';
      lSupportedFields.supportedFields(6).sqlField = 'empno';
      lSupportedFields.supportedFields(6).dataType = 'N';
      lSupportedFields.supportedFields(7).name = 'dateEmbauche';
      lSupportedFields.supportedFields(7).sqlField = 'hiredate';
      lSupportedFields.supportedFields(7).dataType = 'D';
      lSupportedFields.supportedFields(8).name = 'dateNaissance';
      lSupportedFields.supportedFields(8).sqlField = 'birthdate';
      lSupportedFields.supportedFields(8).dataType = 'D';
      lSupportedFields.supportedFields(9).name = 'genre';
      lSupportedFields.supportedFields(9).sqlField = 'sex';
      lSupportedFields.supportedFields(9).dataType = 'C';
    // tri par name 
      SORTA(D) lSupportedFields.supportedFields(*).name;  

  // Finalisation.
    pSupportedFields = lSupportedFields;
    return *on;
    
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;

end-proc;

