{{!-- src/templates/service.sqlrpgle.tpl - Version conforme PRD Sprint 02 --}}
**FREE
// ============================================
// {{name}} Service - Code unifié (généré + manuel)
// Source : {{@root.sourceFile}}
// Générée par CMagic v1.0 - Sprint 2
// ============================================
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include '{{lowercase name}}.rpgleinc'

// ========================================   
// API PUBLIQUE - PROCÉDURES EXPORTÉES
// ========================================

{{#each operations}}
{{#if (eq this 'CREATE')}}
// Création nouveau {{lowercase ../name}}
dcl-proc {{lowercase ../name}}_create export;
  dcl-pi *N ind;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pId likeDS({{lowercase ../name}}_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lId likeDS({{lowercase ../name}}_id_t);
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
        if not {{lowercase ../name}}_isValid({{lowercase ../name}}_listeAction.creation
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // création métier
        clear lId;
        clear lErrors;
        if not {{lowercase ../name}}_create_local(pDetail:lId:lErrors);
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
{{/if}}

{{#if (eq this 'DISPLAY')}}
dcl-proc {{lowercase ../name}}_display export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement
      if not {{lowercase ../name}}_display_local(pId:lErrors);
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
{{/if}}

{{#if (eq this 'CHANGE')}}
dcl-proc {{lowercase ../name}}_change export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la modification
      // contrôle de l'action - récupération de l'existant
        if not {{lowercase ../name}}_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        lDetailAfter = pDetail;
        clear lErrors;
        if not {{lowercase ../name}}_isValid_local({{lowercase ../name}}_listeAction.modification
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // modification métier
        clear lErrors;
        if not {{lowercase ../name}}_change_local(pId:pDetail:lErrors);
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
{{/if}}

{{#if (eq this 'DELETE')}}
dcl-proc {{lowercase ../name}}_delete export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la suppression
      // contrôle de l'action - récupération de l'existant
        if not {{lowercase ../name}}_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        clear lDetailAfter;
        lDetailAfter.detail.id = pId.id;
        clear lErrors;
        if not {{lowercase ../name}}_isValid_local({{lowercase ../name}}_listeAction.suppression
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // suppression métier
        clear lErrors;
        if not {{lowercase ../name}}_delete_local(pId:lErrors);
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
{{/if}}

{{#if (eq this 'SEARCH')}}
dcl-proc {{lowercase ../name}}_search export;
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
      if not {{lowercase ../name}}_search_local(pContext:pTotalCount:pItems:lErrors);
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
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in {{lowercase name}}_listeAction
    pBeforeDetail likeds({{lowercase name}}_detail_t) Const;
    pAfterDetail likeds({{lowercase name}}_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear lErrors;
    // traitement
      if not {{lowercase name}}_isValid_local(pAction
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

dcl-proc {{lowercase name}}_getByID export;
  dcl-pi *N ind;
    pId likeDS({{lowercase name}}_id_t) const;
    pDetail likeds({{lowercase name}}_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pDetail;
      clear pErrors;
    // traitement
      if not {{lowercase name}}_getByID_local(pId:pDetail:lErrors);
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

// ========================================
// ZONE MANUELLE - PRÉSERVÉE
// ========================================
// [CMAGIC:MANUAL_START]

{{#each operations}}
{{#if (eq this 'CREATE')}}
// Implémentation interne - Création
dcl-proc {{lowercase ../name}}_create_local;
  dcl-pi *N ind;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pId likeDS({{lowercase ../name}}_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeDs({{lowercase ../name}}_t);
    dcl-ds lAddress likeDs({{lowercase ../name}}_address_t);
    dcl-s lNewId like(pId.id);
    dcl-s lVipChar char(1);
  
    // initialisation
    clear pId;
    clear pErrors;
    clear lDetail;
    lDetail = pDetail.detail;
    clear lAddress;
    lAddress = lDetail.address;
  
    // Convert RPG indicator *on/*off to database 'O'/'N'
    if lDetail.isvip = *on;
      lVipChar = 'O';
    else;
      lVipChar = 'N';
    endif;
  
    // SQL query to create {{lowercase ../name}} using FINAL TABLE to get the inserted record
    Exec SQL
      SELECT id
      INTO :lNewId
      FROM FINAL TABLE (
        INSERT INTO {{lowercase ../name}}
        ({{{generateSqlColumns entity structs}}})
        VALUES
        ({{{generateSqlValues entity structs}}})
      );
  
    // analyse des résultats de la requête
    clear lError;
    select;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        lError.textUser = 'Error creating {{lowercase ../name}}';
        lError.nomZone = %trim(%proc()) + '_'
          + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
        exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
        pErrors.listError(1) = lError;
        CKOOL_LogError(lError);
        return *off;
      other;
        // on continue normalement
        pId.id = lNewId;
        CKOOL_logMessage('{{lowercase ../name}} created: ' + 
          %char(lNewId) + ' - ' + 
          %trim(pDetail.detail.name));
    endsl;
      // finalisation
      return *on;
  
    on-exit ErrorHappened;
      if ErrorHappened;
        return *off;
      endif;
end-proc;
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_isValid_local export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in {{lowercase name}}_listeAction
    pBeforeDetail likeds({{lowercase name}}_detail_t) Const;
    pAfterDetail likeds({{lowercase name}}_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
      dcl-s it int(3);
    // initialisation
      clear pErrors;
    // traitement
      clear lErrors;
      clear it;
    // Validate based on action type
    select;
      when pAction = {{lowercase name}}_listeAction.creation 
        or pAction = {{lowercase name}}_listeAction.modification;
        
        {{{generateFieldValidation entity structs}}}
        
      when pAction = {{lowercase name}}_listeAction.suppression;
        // Validation rules for deletion
        // For now, just ensure ID is provided
        if pAfterDetail.detail.id <= 0;
          it += 1;
          pErrors.listError(it).code = 'CUST010';
          pErrors.listError(it).textUser = 'ID invalide pour suppression !';
          pErrors.listError(it).text = 'ID requis';
          pErrors.listError(it).nomZone = 'id';
        endif;
        
      other;
        // Unknown action
        it += 1;
        pErrors.listError(it).code = 'CUST999';
        pErrors.listError(it).textUser = 'Action non supportée !';
        pErrors.listError(it).text = 'Action invalide';
        pErrors.listError(it).nomZone = 'action';
    endsl;
    
    // finalisation  
    // If errors found, return false
    if it > 0;
      return *off;
    else;
      return *on;
    endif;
    
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

{{#each operations}}
{{#if (eq this 'DISPLAY')}}
dcl-proc {{lowercase ../name}}_display_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
    dcl-ds lDetail likeds({{lowercase ../name}}_detail_t);
    dcl-ds lError likeds(errorItem) inz;
    dcl-s ErrorHappened ind;
  
    // initialisation
    clear pErrors;
    clear lDetail;
  
    // Call getByID to retrieve {{lowercase ../name}} details
    if not {{lowercase ../name}}_getByID_local(pId : lDetail : pErrors);
      return *off;
    endif;
  
    // Display {{lowercase ../name}} details (simple console output)
    CKOOL_logMessage('=== {{name}} Details ===');
    CKOOL_logMessage('ID: ' + %char(lDetail.detail.id));
    CKOOL_logMessage('Code: ' + %trim(lDetail.detail.code));
    CKOOL_logMessage('Name: ' + %trim(lDetail.detail.name));
    CKOOL_logMessage('Status: ' + %trim(lDetail.detail.status));
    CKOOL_logMessage('========================');
  
    return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'CHANGE')}}
dcl-proc {{lowercase ../name}}_change_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
    dcl-ds lDetail likeDs({{lowercase ../name}}_t);
    dcl-ds lAddress likeDs({{lowercase ../name}}_address_t);
  dcl-s lVipChar char(1);
  
  // initialisation
  clear pErrors;
  clear lDetail;
  lDetail = pDetail.detail;
  clear lAddress;
  lAddress = lDetail.address;
  
  // Convert RPG indicator *on/*off to database 'O'/'N'
  if lDetail.isvip = *on;
    lVipChar = 'O';
  else;
    lVipChar = 'N';
  endif;
  
  // SQL query to update {{lowercase ../name}}
  Exec SQL
    UPDATE {{lowercase ../name}}
    SET code = :lDetail.code,
        name = :lDetail.name,
        address_ligne1 = :lAddress.ligne1,
        address_ligne2 = :lAddress.ligne2,
        address_codepostal = :lAddress.codepostal,
        address_ville = :lAddress.ville,
        address_pays = :lAddress.pays,
        phone = :lDetail.phone,
        email = :lDetail.email,
        status = :lDetail.status,
        creationdate = :lDetail.creationdate,
        creditlimit = :lDetail.creditlimit,
        isvip = :lVipChar
    WHERE id = :pId.id;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CUST001';
      lError.text = '{{name}} not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating {{lowercase ../name}}';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'CUST001';
        lError.text = '{{name}} not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('{{name}} updated: ' + 
        %char(pId.id) + ' - ' + 
        %trim(pDetail.detail.name));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'DELETE')}}
dcl-proc {{lowercase ../name}}_delete_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to delete {{lowercase ../name}}
  Exec SQL
    DELETE FROM {{lowercase ../name}}
    WHERE id = :pId.id;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CUST001';
      lError.text = '{{name}} not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting {{lowercase ../name}}';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'CUST001';
        lError.text = '{{name}} not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('{{name}} deleted: ' + 
        %char(pId.id));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'SEARCH')}}
dcl-proc {{lowercase ../name}}_search_local;
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
  dcl-ds lItem likeDS({{lowercase ../name}}_item_t);

  dcl-ds lItemSQL qualified;
    id int(10);
    code varchar(10);
    name varchar(80);
    status varchar(20);
    creation_date date;
  end-ds;
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);

  //initialisation
    clear pTotalCount;
    clear pItems;
    clear pErrors;
    clear lItems;
    lItems = list_create();
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
    lSelect = 'select id, code, name, status, creation_date ' 
            + ' from {{lowercase ../name}}';
    // filtre 
    clear lWhere;
    lFirst = *on;
    for-each lItemFiltre in pContext.filter;
      if lItemFiltre.field = *blanks;
        leave;
      endif;
      if lFirst;
        lWhere = 'Where';
        lFirst = *off;
      else;
        lWhere = %trim(lWhere) + ' and' ;
      endif;
      // si %XX% => like sinon =
      clear lPos;
      clear lString;
      lString = %upper(%trim(lItemFiltre.value));
      lPos = %scan('%' :%trim(lString));
      if lPos > 0;
        lOperateur = 'like';
      else;
        lOperateur = '=';
      endif;
      lWhere = ' ' +%trim(lWhere) + ' ' + %trim(lItemFiltre.field);
      lWhere = ' ' + %trim(lWhere) + ' ' + %trim(lOperateur);
      lWhere = ' ' + %trim(lWhere) + ' ' +
      GLOBAL_QUOTE +  %trim(lString) + GLOBAL_QUOTE; 
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
    for-each lItemSort in pContext.sort;
      if lItemSort.field = *blanks;
        leave;
      endif;
      if lFirst;
        lOrderBy = 'Order by';
        lFirst = *off;
      else;
        lOrderBy = %trim(lOrderBy) + ' ,' ;
      endif;
      lOrderBy = ' ' +%trim(lOrderBy) + ' ' + %trim(lItemSort.field);
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
  //Préparation du curseur
    Exec sql declare cListe  cursor for SqlStmt;
  //Ouverture du curseur
    Exec SQL open cListe; 
    if (sqlState <> SQL_OK);
    clear lError;
    lError.code = %trim(sqlState);
    exec sql GET DIAGNOSTICS CONDITION 1 :lError.text = MESSAGE_TEXT;
    pErrors.listError(1) = lError;
    CKOOL_LogError(lError);
    return *off;
  endif;
  dow (sqlState = SQL_OK);
    //Lecture suivante du curseur
     clear lItemSQL;
    Exec SQL Fetch Next
    From cListe
    Into :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    // ajout de l'item dans la liste
    clear lItem;
    lItem.id = lItemSQL.id;
    lItem.name = lItemSQL.name;
    lItem.status = lItemSQL.status;
    lItem.creationdate = lItemSQL.creation_date;
    list_add(lItems: %addr(lItem): %size(lItem));
  
    enddo;
  // comptage total                                       
  //Prepare
    Exec sql prepare SqlStmt2 From :lSelCount;
  //Préparation du curseur
    Exec sql declare cCountListe  cursor for SqlStmt2;
  //Ouverture du curseur
    Exec SQL open cCountListe; 
  //Lecture suivante du curseur
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
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_getByID_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase name}}_id_t) const;
    pDetail likeds({{lowercase name}}_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    Dcl-Ds F{{toUpperCase name}} ExtName('{{toUpperCase name}}') Alias template Qualified end-ds;
    dcl-ds lDetailSQL qualified;
{{#each (expandFieldsForSql this structs)}}
      {{this.name}} like(F{{toUpperCase ../name}}.{{this.sqlColumnName}});
{{/each}}
    end-ds;
    dcl-ds lError likeds(errorItem) inz;
    dcl-s ErrorHappened ind;
  
    // initialisation
    clear pDetail;
    clear pErrors;
    clear lDetailSQL;
  
    // SQL query to retrieve {{lowercase name}} by ID
    Exec SQL
      SELECT {{{generateSqlColumns entity structs}}}
      INTO :lDetailSQL
      FROM {{lowercase name}}
      WHERE id = :pId.id;
  
    // analyse des résultats de la requête
    clear lError;
    select;
      when (sqlState = SQL_NOT_FOUND);
        lError.code = 'CUST001';
        lError.text = '{{name}} not found';
        pErrors.listError(1) = lError;
        return *off;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        lError.textUser = 'Error retrieving {{lowercase name}}';
        lError.nomZone = %trim(%proc()) + '_'
          + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
        exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
        pErrors.listError(1) = lError;
        // Log the error
        CKOOL_LogError(lError);
        return *off;
      other;
        // on continue normalement
        CKOOL_logMessage('{{name}} found: ' + 
          %char(lDetailSQL.id) + ' - ' + 
          %trim(lDetailSQL.name));
    endsl;
  
    // Convert SQL result to RPG structure
    {{{generateSqlToRpgMapping entity structs}}}
    // Convert database 'O'/'N' to RPG indicator *on/*off
    if lDetailSQL.is_vip = 'O';
      pDetail.detail.isvip = *on;
    else;
      pDetail.detail.isvip = *off;
    endif;
  
    return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// [CMAGIC:MANUAL_END]
