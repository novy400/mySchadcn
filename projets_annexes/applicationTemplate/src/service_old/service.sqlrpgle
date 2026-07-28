**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
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
  // dcl-ds lItem likeds(service_item_t) inz;
//   dcl-ds lItem;
//     id likeDS(service_detail_t.id);
//     nom like(service_detail_t.nom);
// end-ds;
  dcl-ds lItem likeDS(service_item_t);

  dcl-ds lItemSQL qualified;
    code char(6);
    prenom like(service_detail_t.prenom);    
    nom like(service_detail_t.nom);
    initiale like(service_detail_t.initiale);
    service like(service_detail_t.service);
  end-ds;
//   dcl-ds lItem qualified;
//   dcl-ds id;
//     code char(6);
//   end-ds;
//     nom like(service_detail_t.nom);
// end-ds;
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);
  dcl-s dbFieldName varchar(32);
  dcl-s isNumericField ind;
  dcl-ds lContext likeds(pContext);

  //initialisation
    clear pTotalCount;
    clear pItems;
    clear pErrors;
    clear lItems;
    clear lContext;
    lContext = pContext;
    lItems = list_create();
  // contrÃ´le context.
   
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
            + ' from service';
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
      
      // Traitement spÃ©cial pour la recherche gÃ©nÃ©rale 'q'
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
        
        // Mapper les noms de champs vers les noms de colonnes DB
        isNumericField = *off;
        if %trim(lItemFiltre.field) in %list('salaire':'id');
            isNumericField = *on;
        endif;

        // Mapper les noms de champs vers les noms de colonnes DB
        clear dbFieldName;
        dbFieldName = getserviceDbFieldName(%trim(lItemFiltre.field));
        
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
          other; // CMAGIC_OP_EQUAL ou par dÃ©faut
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
      if lFirst;
        lOrderBy = 'Order by';
        lFirst = *off;
      else;
        lOrderBy = %trim(lOrderBy) + ' ,' ;
      endif;
      // Mapper les noms de champs vers les noms de colonnes DB ***
      clear dbFieldName;
      dbFieldName = getserviceDbFieldName(%trim(lItemSort.field));

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
  //PrÃƒÂ©paration du curseur
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
    //Ã‚Å¡Lecture suivante du curseur
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
  //PrÃƒÂ©paration du curseur
    Exec sql declare cCountListe  cursor for SqlStmt2;
  //Ouverture du curseur
    Exec SQL open cCountListe; 
  //Ã‚Å¡Lecture suivante du curseur
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
// jjj
dcl-proc service_getByID export;
  dcl-pi *N ind;
    pId likeDS(service_detail_t.id) const;
    pDetail likeds(service_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  Dcl-Ds Fservice ExtName('service') Alias template Qualified end-ds;
  dcl-ds lDetailSQL qualified;
    code like(Fservice.empno);
    prenom like(Fservice.firstnme);
    nom like(Fservice.lastname);
    initiale like(Fservice.midinit);
    service like(Fservice.workdept);
    dateEmbauche like(Fservice.hiredate);
    dateNaissance like(Fservice.birthdate);
    genre like(Fservice.sex);
    salaire like(Fservice.salary);
  end-ds;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pDetail;
  clear pErrors;
  
  // SQL query to get service by ID
  Exec SQL
    SELECT empno, firstnme, lastname, midinit, workdept, 
           hiredate, birthdate, sex, salary
    INTO :lDetailSQL
    FROM service
    WHERE empno = :pId.code;
  // analyse des rÃ©sultats de la requÃªte
    clear lError;
    select;
      when (sqlState = SQL_NOT_FOUND);
        lError.code = 'EMP001';
        lError.text = 'service not found';
        pErrors.listError(1) = lError;
        return *off;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
        pErrors.listError(1) = lError;
        // Log the error
        CKOOL_LogError(lError);
        // on lÃ¨ve une exception
        CKOOL_ThrowError(lError);
        return *off;
      other;
        // on continue normalement
        CKOOL_logMessage('service found: ' + 
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

dcl-proc service_change export;
  dcl-pi *N ind;
    pId likeDS(service_detail_t.id) const;
    pDetail likeds(service_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to update service
  Exec SQL
    UPDATE service
    SET firstnme = :pDetail.prenom,
        lastname = :pDetail.nom,
        midinit = :pDetail.initiale,
        workdept = :pDetail.service,
        hiredate = :pDetail.dateEmbauche,
        birthdate = :pDetail.dateNaissance,
        sex = :pDetail.genre,
        salary = :pDetail.salaire
    WHERE empno = :pId.code;
  
  // analyse des rÃ©sultats de la requÃªte
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'EMP001';
      lError.text = 'service not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating service';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      // // on lÃ¨ve une exception
      // CKOOL_ThrowError(lError);
      return *off;
    other;
      // VÃ©rifier le nombre de lignes affectÃ©es
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'EMP001';
        lError.text = 'service not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('service updated: ' + 
        %trim(pId.code) + ' - ' + 
        %trim(pDetail.nom));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_delete export;
  dcl-pi *N ind;
    pId likeDS(service_detail_t.id) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to delete service
  Exec SQL
    DELETE FROM service
    WHERE empno = :pId.code;
  
  // analyse des rÃ©sultats de la requÃªte
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'EMP001';
      lError.text = 'service not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting service';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      // // on lÃ¨ve une exception
      // CKOOL_ThrowError(lError);
      return *off;
    other;
      // VÃ©rifier le nombre de lignes affectÃ©es
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'EMP001';
        lError.text = 'service not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('service deleted: ' + 
        %trim(pId.code));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_create export;
  dcl-pi *N ind;
    pDetail likeds(service_detail_t) const;
    pId likeDS(service_detail_t.id);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lNewCode char(6);
  dcl-s lEdLevel int(5);
  
  // initialisation
  clear pId;
  clear pErrors;
  clear lEdLevel;
  lEdLevel = 18; 
  // SQL query to create service using FINAL TABLE to get the inserted record
  Exec SQL
    SELECT empno
    INTO :lNewCode
    FROM FINAL TABLE (
      INSERT INTO service
      (empno, firstnme, lastname, midinit, workdept, 
       hiredate, birthdate, sex, salary, edlevel)
      VALUES
      ((SELECT max(empno)  + 10 FROM service), 
       :pDetail.prenom, :pDetail.nom, :pDetail.initiale, 
       :pDetail.service, :pDetail.dateEmbauche, :pDetail.dateNaissance, 
       :pDetail.genre, :pDetail.salaire, :lEdLevel)
    );
  
  // analyse des rÃ©sultats de la requÃªte
  clear lError;
  select;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error creating service';
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
      CKOOL_logMessage('service created: ' + 
        %trim(lNewCode) + ' - ' + 
        %trim(pDetail.nom));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc service_display export;
  dcl-pi *N ind;
    pId likeDS(service_detail_t.id) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lDetail likeds(service_detail_t);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pErrors;
  clear lDetail;
  
  // Call getByID to retrieve service details
  if not service_getByID(pId : lDetail : pErrors);
    return *off;
  endif;
  
  // Display service details (simple console output)
  CKOOL_logMessage('=== service Details ===');
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

dcl-proc service_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in service_listeAction
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
      
      // Prenom is mandatory
      if pAfterDetail.prenom = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0001';
        pErrors.listError(it).textUser = 'PrÃ©nom obligatoire !';
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
      if not (pAfterDetail.genre in service_listeGenre);
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
        pErrors.listError(it).textUser = 'Salaire doit Ãªtre positif !';
        pErrors.listError(it).text = 'Valeur invalide';
        pErrors.listError(it).nomZone = 'salaire';
      endif;
      
      // Birth date must be in the past
      if pAfterDetail.dateNaissance >= %date();
        it += 1;
        pErrors.listError(it).code = 'EMP0006';
        pErrors.listError(it).textUser = 'Date de naissance invalide !';
        pErrors.listError(it).text = 'Date doit Ãªtre antÃ©rieure Ã  aujourd''hui';
        pErrors.listError(it).nomZone = 'dateNaissance';
      endif;
      
      // Hire date validation
      if pAfterDetail.dateEmbauche > %date();
        it += 1;
        pErrors.listError(it).code = 'EMP0007';
        pErrors.listError(it).textUser = 'Date d''embauche ne peut Ãªtre future !';
        pErrors.listError(it).text = 'Date invalide';
        pErrors.listError(it).nomZone = 'dateEmbauche';
      endif;
      
    when pAction = service_listeAction.suppression;
      // For deletion, we only need to check if ID exists
      if pAfterDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0008';
        pErrors.listError(it).textUser = 'ID employÃ© obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    when pAction = service_listeAction.consultation;
      // For consultation, only ID is required
      if pAfterDetail.id.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'EMP0009';
        pErrors.listError(it).textUser = 'ID employÃ© obligatoire pour consultation !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    other;
      // Unknown action
      it += 1;
      pErrors.listError(it).code = 'EMP0010';
      pErrors.listError(it).textUser = 'Action inconnue !';
      pErrors.listError(it).text = 'Action non supportÃ©e';
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


dcl-proc getserviceDbFieldName;
  dcl-pi *n varchar(32);
    apiFieldName varchar(32) const;
  end-pi;
  
  dcl-s dbFieldName varchar(32);
  
  select;
    when %trim(apiFieldName) = 'nom';
      dbFieldName = 'lastname';
    when %trim(apiFieldName) = 'prenom';
      dbFieldName = 'firstnme';
    when %trim(apiFieldName) = 'initiale';
      dbFieldName = 'midinit';
    when %trim(apiFieldName) = 'service';
      dbFieldName = 'workdept';
    when %trim(apiFieldName) = 'salaire';
      dbFieldName = 'salary';
    when %trim(apiFieldName) = 'id';
      dbFieldName = 'empno';
    when %trim(apiFieldName) = 'dateEmbauche';
      dbFieldName = 'hiredate';
    when %trim(apiFieldName) = 'dateNaissance';
      dbFieldName = 'birthdate';
    when %trim(apiFieldName) = 'genre';
      dbFieldName = 'sex';
    other;
      dbFieldName = %trim(apiFieldName); // Fallback
  endsl;
  
  return dbFieldName;
end-proc;