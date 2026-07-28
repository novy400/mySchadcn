**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include 'contfigdat.rpgleinc'
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

dcl-proc contfigdat_search export;
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
  dcl-ds lItem likeDS(contfigdat_item_t);

  dcl-ds lItemSQL likeDS(contfigdat_item_sql_t);
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);
  dcl-s dbFieldName varchar(32);
  dcl-s isNumericField ind;
  dcl-s isDateField ind;
  dcl-s isCharacterField ind;
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
  if not contfigdat_getSupportedFields(lSupportedFields:lErrors);
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
//*********************************************************************
// TODO: 1.  remplacer par la req select  pour la liste
//           de l'entité. mieux avec une vue ....

  lSelect = 'select id,codeetablissement,codeAgence,'
            + 'numeroClient,nomClient,'  
            + 'numeroContrat,positionContrat,'
            + 'montantContrat,dateEcheanceContrat,'
            + 'codeOpposition,'
            + 'datefigementcontrat,'
            + 'motiffigement'
            + ' from contfigdav'
            ;

//*********************************************************************
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
//*********************************************************************
// TODO: 2.  Indiquer la ou les zones pour la recherche par texte.
//           de l'entité.
        // Recherche sur plusieurs champs pour 'q' (nom, prenom, service)
      lWhere = ' ' + %trim(lWhere) + ' (';
      lWhere = %trim(lWhere) + 'UPPER(nomcli) LIKE UPPER(' 
        + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
      lWhere = %trim(lWhere) + ')';
//*********************************************************************
    else;
        // Filtres normaux avec operator explicite
      clear lString;
      lString = %trim(lItemFiltre.value);
        // chercher dans la liste des champs supportés
      isNumericField = *off;
      isDateField = *off;
      isCharacterField = *off;
      SORTA(D) lSupportedFields.supportedFields(*).name;  

      clear lIt;
      lIt = %lookup(%trim(lItemFiltre.field)
          :lSupportedFields.supportedFields(*).name);
        // Vérifier si le champ est numérique
      if lIt > 0;
        select;
          when (lSupportedFields.supportedFields(lIt).dataType = 
              CMAGIC_typeChamp.NUMERIC);
            isNumericField = *on;
          when (lSupportedFields.supportedFields(lIt).dataType = 
              CMAGIC_typeChamp.DATE);
            isDateField = *on;
          other;
              // handle other conditions
            isCharacterField = *on;
        endsl;
          // Mapper les noms de champs vers les noms de colonnes DB
        clear dbFieldName;
        dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;
      else;
        iter;
      endif;
        
      if not (%trim(lItemFiltre.operator) = CMAGIC_OP_LIKE);
        select;
          when isCharacterField;
            lWhere = ' ' + %trim(lWhere) + ' upper(' + %trim(dbFieldName) + ')';
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          when isDateField;
            lWhere = ' ' + %trim(lWhere) + '  ' + %trim(dbFieldName) ;
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          when isNumericField;  
            lWhere = ' ' + %trim(lWhere) + '  ' + %trim(dbFieldName) ;
        endsl;
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
// jjj
dcl-proc contfigdat_getByID export;
  dcl-pi *N ind;
    pId likeDS(contfigdat_id_t) const;
    pDetail likeds(contfigdat_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lDetailSQL likeDS(contfigdat_detail_sql_t);
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pDetail;
  clear pErrors;
  
  // SQL query to get contfigdat by ID
//*********************************************************************
// TODO: 2.  Indiquer la requete pour le detail 
//           de l'entité.   c'est meiux avec une vue             
  Exec SQL
    select id,
      codeetablissement,nomEtablissement,
      codeAgence,nomAgence,
      numeroClient,nomClient,
      numeroContrat,positionContrat,
      dateEcheanceContrat,montantContrat,
      codeOpposition,ifnull(libelleOpposition, '') ,
      dateOpposition,
      datefigementcontrat,
      motiffigement
    into :lDetailSQL
    from contfigdav 
    WHERE id = :pId.code;
//*********************************************************************
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CFD0001';
      lError.text = 'contfigdat not found';
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
      CKOOL_logMessage('contfigdat found: ' + 
          %char(lDetailSQL.id) + ' - ' + 
          %char(lDetailSQL.numeroContrat) + ' - ' + 
          %char(lDetailSQL.dateFigement));
  endsl;

  
  // Map SQL result to output structure
  SQLToEntity(lDetailSQL:pDetail);
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc contfigdat_update export;
  dcl-pi *N ind;
    pId likeDS(contfigdat_id_t) const;
    pDetail likeds(contfigdat_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lDetailSQL likeDS(contfigdat_detail_sql_t);
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  dcl-ds lDetailBefore likeds(contfigdat_detail_t);
  dcl-ds lDetailAfter likeds(contfigdat_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  
  // initialisation
  clear pErrors;
  clear lDetailSQL;
  entityToSQL(pDetail:lDetailSQL);
  // contrôle avant modif 
  clear lDetailBefore;
  clear lErrors;
  if not contfigdat_getByID(pId:lDetailBefore:lErrors);
    pErrors = lErrors;
    return *off;
  endif;
  lDetailAfter = pDetail;
  clear lErrors;
  if not contfigdat_isValid(GLOBAL_listeMode.modification
        : lDetailBefore: lDetailAfter: lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  // SQL query to update contfigdat
//*********************************************************************
// TODO: 1. spécifier la req sql de mise à jour  
//          de l'entité.
  Exec SQL
    UPDATE contfigdat
    SET dateFigementContrat
           = :lDetailSQL.dateFigement,
        motifFigement
           = :lDetailSQL.motifFigement
    WHERE id = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CFD0001';
      lError.text
         = 'Date de figement Contrat non trouvée.';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating contfigdat';
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
        lError.code = 'CFD0001';
        lError.text 
          = 'Date de figement Contrat non trouvée.';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('contfigdat updated: ' + 
        %char(pId.code) + ' - ' + 
        %char(pDetail.contrat.numero));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc contfigdat_delete export;
  dcl-pi *N ind;
    pId likeDS(contfigdat_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  dcl-ds lDetailBefore likeds(contfigdat_detail_t);
  dcl-ds lDetailAfter likeds(contfigdat_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  
  // initialisation
  clear pErrors;

  // contrôle avant modif 
  clear lDetailBefore;
  clear lErrors;
  if not contfigdat_getByID(pId:lDetailBefore:lErrors);
    pErrors = lErrors;
    return *off;
  endif;
  clear lDetailAfter;
  clear lErrors;
  if not contfigdat_isValid(GLOBAL_listeMode.suppression
        : lDetailBefore: lDetailAfter: lErrors);
    pErrors = lErrors;
    return *off;
  endif;
  
  // SQL query to delete contfigdat
  Exec SQL
    DELETE FROM contfigdat
    WHERE id = :pId.code;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CFD0001';
      lError.text 
        = 'Date de figement Contrat non trouvée.';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting contfigdat';
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
        lError.code = 'CFD0001';
        lError.text 
          = 'Date de figement Contrat non trouvée.';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('contfigdat deleted: ' + 
        %char(pId.code));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc contfigdat_create export;
  dcl-pi *N ind;
    pDetail likeds(contfigdat_detail_t) const;
    pId likeDS(contfigdat_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lNewCode like(contfigdat_id_t.code);
  dcl-ds lDetailBefore likeds(contfigdat_detail_t);
  dcl-ds lDetailAfter likeds(contfigdat_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lDetailSQL likeds(contfigdat_detail_sql_t);
  // initialisation
  clear pId;
  clear pErrors;
  clear lDetailSQL;
  entityToSQL(pDetail:lDetailSQL);
  // contrôle avant modif 
  clear lDetailBefore;
  lDetailAfter = pDetail;
  clear lErrors;
  if not contfigdat_isValid(GLOBAL_listeMode.creation
        : lDetailBefore: lDetailAfter: lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  // SQL query to create contfigdat using FINAL TABLE to get the inserted record
  Exec SQL
    SELECT id
    INTO :lNewCode
    FROM FINAL TABLE (
      INSERT INTO contfigdat
      (codeEtablissement, numeroContrat, 
      dateFigementContrat, motifFigement)
      VALUES
      ( 
       :lDetailSQL.codeEtablissement,
       :lDetailSQL.numeroContrat,
       :lDetailSQL.dateFigement,
       :lDetailSQL.motifFigement
       ))
    ;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error creating contfigdat';
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
      CKOOL_logMessage('contfigdat created: ' + 
        %char(lNewCode) + ' - ' + 
        %char(pDetail.contrat.numero));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc contfigdat_display export;
  dcl-pi *N ind;
    pId likeDS(contfigdat_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lDetail likeds(contfigdat_detail_t);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pErrors;
  clear lDetail;
  
  // Call getByID to retrieve contfigdat details
  if not contfigdat_getByID(pId : lDetail : pErrors);
    return *off;
  endif;
  
  // Display contfigdat details (simple console output)
  CKOOL_logMessage('=== contfigdat Details ===');
  CKOOL_logMessage('ID: ' + %char(lDetail.id.code));
  CKOOL_logMessage('Etablissement: ' 
    + %trim(lDetail.etablissement.code) + ' ' 
    + %trim(lDetail.etablissement.nom));
  CKOOL_logMessage('Agence: ' 
    + %trim(lDetail.agence.code) + ' ' 
    + %trim(lDetail.agence.nom));  
  CKOOL_logMessage('Client: ' 
    + %char(lDetail.client.numero) + ' ' 
    + %trim(lDetail.client.nom));      
  CKOOL_logMessage('Contrat: ' 
    + %char(lDetail.contrat.numero) + ' ' 
    + %trim(lDetail.contrat.position) + ' ' 
    + %char(lDetail.contrat.dateEcheance) + ' ' 
    + %char(lDetail.contrat.montant));      
  CKOOL_logMessage('Opposition: ' 
    + %trim(lDetail.opposition.code) + ' ' 
    + %trim(lDetail.opposition.libelle)
    + %char(lDetail.opposition.date));  
  CKOOL_logMessage('Date figement: ' + %char(lDetail.dateFigement));
  CKOOL_logMessage('Motif: ' + %trim(lDetail.motifFigement));
  CKOOL_logMessage('========================');
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc contfigdat_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in contfigdat_listeAction
    pBeforeDetail likeds(contfigdat_detail_t) Const;
    pAfterDetail likeds(contfigdat_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-s it int(3);
  dcl-s ErrorHappened ind;
  dcl-ds lError likeds(errorItem) inz;
  dcl-ds lDetailEntity likeds(contfigdat_detail_t);
  
    //initialisation
  clear pErrors;
  clear it;
  
  // Validate based on action type
  select;
    when pAction = GLOBAL_listeMode.creation 
      or pAction = GLOBAL_listeMode.modification;
      
      // le code etablissement est obligatoire
      if pAfterDetail.etablissement.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CFD0002';
        pErrors.listError(it).textUser 
          = 'Etablissement obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'etablissement';
      endif;
      // TODO: l'établissement est valide.

      // le numéro de contrat est obligatoire
      if pAfterDetail.contrat.numero = *zeros;
        it += 1;
        pErrors.listError(it).code = 'CFD0003';
        pErrors.listError(it).textUser 
          = 'Contrat obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'contrat';
      endif;
      // TODO: le contrat est valide.
      clear lError;
      clear lDetailEntity;
      lDetailEntity.etablissement.code = pAfterDetail.etablissement.code;
      lDetailEntity.client.numero = pAfterDetail.client.numero;
      lDetailEntity.contrat.numero = pAfterDetail.contrat.numero;
      if not contfigdat_initDetailEntity(
          pAfterDetail.etablissement.code
          :pAfterDetail.client.numero
          :pAfterDetail.contrat.numero
          :lDetailEntity
          :lError);
        it += 1;
        pErrors.listError(it).code = 'STD0002';
        pErrors.listError(it).textUser = 'contrat invalide !';
        pErrors.listError(it).text = 'Zone invalide';
        pErrors.listError(it).nomZone = 'contrat';
      endif;
      // la date de figement est obligatoire
      if pAfterDetail.dateFigement = %date('0001-01-01');
        it += 1;
        pErrors.listError(it).code = 'STD0001';
        pErrors.listError(it).textUser = 'Date de figement obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'dateFigement';
      endif;
      // la date de figement doit être antérieure à la date d'écheance 
      if pAfterDetail.dateFigement >= 
          pAfterDetail.contrat.dateEcheance;
        it += 1;
        pErrors.listError(it).code = 'CFD0004';
        pErrors.listError(it).textUser = 
          'Date figement supérieure à la date d''écheance.';
        pErrors.listError(it).text = 'Zone invalide';
        pErrors.listError(it).nomZone = 'dateFigement';
      endif;
        
    when pAction = GLOBAL_listeMode.suppression;
      // For deletion, we only need to check if ID exists
      if pBeforeDetail.id.code = *zeros;
        it += 1;
        pErrors.listError(it).code = 'STD0001';
        pErrors.listError(it).textUser = 'ID obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id.code';
      endif;
      
    when pAction = GLOBAL_listeMode.consultation;
      // For consultation, only ID is required
      if pAfterDetail.id.code = *zeros;
        it += 1;
        pErrors.listError(it).code = 'STD0001';
        pErrors.listError(it).textUser = 'ID obligatoire pour consultation !';
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
// Configuration des champs supportés pour contfigdat
// ========================================

///
// Get contfigdat supported fields configuration
//
// Initializes a local supported fields configuration.
// Pure function with no side effects.
//
// @param **out** supportedFields  supported fields array to initialize
// @tag contfigdat
// @tag REST
// @tag Configuration
///
dcl-proc contfigdat_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeds(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lit int(5);

  // Initialisation.
  clear pErrors;
  clear pSupportedFields; 

  // Traitement.
    // Clear and initialize local array
  clear lSupportedFields;
  clear lIt;
    // Configuration des champs contfigdat pour filtres REST
  clear lSupportedFields; 
  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'id';
  lSupportedFields.supportedFields(lIt).sqlField = 'id';
  lSupportedFields.supportedFields(lIt).dataType = 'N';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'codeEtablissement';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'codeetablissement';
  lSupportedFields.supportedFields(lIt).dataType = 'C';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'codeAgence';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'codeAgence';
  lSupportedFields.supportedFields(lIt).dataType = 'C';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'numeroClient';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'numeroClient';
  lSupportedFields.supportedFields(lIt).dataType = 'N';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'nomClient';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'nomClient';
  lSupportedFields.supportedFields(lIt).dataType = 'C';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'numeroContrat';
  lSupportedFields.supportedFields(lIt).sqlField = 'numeroContrat';
  lSupportedFields.supportedFields(lIt).dataType = 'N';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'positionContrat';
  lSupportedFields.supportedFields(lIt).sqlField = 'positionContrat';
  lSupportedFields.supportedFields(lIt).dataType = 'C';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'montantContrat';
  lSupportedFields.supportedFields(lIt).sqlField = 'montantContrat';
  lSupportedFields.supportedFields(lIt).dataType = 'N';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'dateEcheanceContrat';
  lSupportedFields.supportedFields(lIt).sqlField = 'dateEcheanceContrat';
  lSupportedFields.supportedFields(lIt).dataType = 'D';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'codeOpposition';
  lSupportedFields.supportedFields(lIt).sqlField = 'codeOpposition';
  lSupportedFields.supportedFields(lIt).dataType = 'C';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'dateFigement';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'datefigementcontrat';
  lSupportedFields.supportedFields(lIt).dataType = 'D';

  lIt += 1; 
  lSupportedFields.supportedFields(lIt).name = 'motif';
  lSupportedFields.supportedFields(lIt).sqlField 
        = 'motiffigement';
  lSupportedFields.supportedFields(lIt).dataType = 'C';
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


dcl-proc entityToSQL;
  dcl-pi *n ;
    pDetailEntity likeds(contfigdat_detail_t) const;
    pDetailSQL likeDs(contfigdat_detail_sql_t);
  end-pi;
  clear pDetailSQL;
  eval pDetailSQL = pDetailEntity;  // Automatique si noms identiques

end-proc;

dcl-proc SQLToEntity;
  dcl-pi *n ;
    pDetailSQL likeDs(contfigdat_detail_sql_t) const;
    pDetailEntity likeds(contfigdat_detail_t);
  end-pi;
  clear pDetailEntity;
  eval pDetailEntity = pDetailSQL;  // Automatique si noms identiques

end-proc;

dcl-proc contfigdat_initDetailEntity export;
  dcl-pi *N ind;
    pCodeEtablissement like(contfigdat_etablissement_t.code) const;
    pNumeroClient like(contfigdat_client_t.numero) const;
    pNumeroContrat like(contfigdat_contrat_t.numero) const;
    pDetailEntity likeds(contfigdat_detail_t);
    pError likeds(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetailEntity likeds(contfigdat_detail_t);
  dcl-ds lDetailEtablissement likeds(contfigdat_etablissement_t);
  dcl-ds lDetailClient likeds(contfigdat_client_t);
  dcl-ds lDetailContrat likeds(contfigdat_contrat_t);
  dcl-ds lDetailOpposition likeds(contfigdat_opposition_t);
  // initialisation des variables
  clear pError;
  clear pDetailEntity;

  // traitements
  clear lDetailEntity;
  select;
    when (pNumeroContrat = *zeros and pNumeroClient <> *zeros);
    // recherche client
      clear lDetailEtablissement;
      clear lDetailClient;
      exec sql
        select cli.etacli, ets.nometa,
        cli.codcli, cli.nomcli
        into :lDetailEtablissement.code,
             :lDetailEtablissement.nom,
             :lDetailClient.numero,
             :lDetailClient.nom
        from clients cli 
        left join etablis ets
        on ets.codeta = cli.etacli
        where cli.etacli= :pCodeEtablissement 
        and cli.codcli= :pNumeroClient; 
    when (pNumeroContrat <> *zeros); 
      // recherche contrat
      clear lDetailEtablissement;
      clear lDetailClient;
      clear lDetailContrat;
      clear lDetailOpposition;
      exec sql
        select ctr.etacon, ets.nometa,
        ctr.clicon, cli.nomcli,
        ctr.numcon,ctr.poscon, ctr.daecon,ctr.mntcon,
        ctr.oppcon,ifnull(opp.libopm, '') ,ctr.dopcon 
        into :lDetailEtablissement.code,
             :lDetailEtablissement.nom,
             :lDetailClient.numero,
             :lDetailClient.nom,
             :lDetailContrat.numero,
             :lDetailContrat.position,
             :lDetailContrat.dateEcheance,
             :lDetailContrat.montant,
             :lDetailOpposition.code,
             :lDetailOpposition.libelle,
             :lDetailOpposition.date
        from contrat ctr 
        left join etablis ets
        on ets.codeta = ctr.etacon
        left join clients cli
        on cli.etacli = ctr.etacon and cli.codcli = ctr.clicon
        left join opmotif opp
        on opp.codopm = ctr.oppcon
        where ctr.etacon= :pCodeEtablissement 
        and ctr.numcon= :pNumeroContrat; 
    other;
      // handle other conditions
  endsl;
  select;
    when  SqlCode < 0;
      clear lError;
      exec sql
          get diagnostics condition 1 :lError.text = MESSAGE_TEXT;
      pError = lError;
      return *off;
    when  SqlCode = 100;
      return *off;
    other;
      lDetailEntity.etablissement = lDetailEtablissement;
      lDetailEntity.client = lDetailClient;
      lDetailEntity.contrat = lDetailContrat;
      lDetailEntity.opposition = lDetailOpposition;
      pDetailEntity = lDetailEntity;
  endsl;

  // finalisation
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off; 
    endif;
end-proc;


dcl-proc contfigdat_getDateFigementContrat export;
  dcl-pi *N ind;
    pCodeEtablissement like(contfigdat_etablissement_t.code) const;
    pNumeroContrat like(contfigdat_contrat_t.numero) const;
    pDateFigement like(contfigdat_detail_t.dateFigement);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-s  lDateFigement like(contfigdat_detail_t.dateFigement);

  // initialisation des variables
  clear pDateFigement;

  // traitements
  clear lDateFigement;
  exec sql
    select datefigementcontrat
    into :lDateFigement 
    from contrat_date_figement_calcul 
    where 
    codeetablissement= :pCodeEtablissement 
    and 
    numeroContrat= :pNumeroContrat; 
  select;
    when  SqlCode < 0;
      clear lError;
      exec sql
          get diagnostics condition 1 :lError.text = MESSAGE_TEXT;
      lError.code = 'STD0005';
      lError.textUser = 'Error retrieving date figement contrat'
       + '//Ctr : ' + %char(pNumeroContrat) + '/Ets :  ' + %char(pCodeEtablissement);
      lError.nomZone = 'contrat';    
      CKOOL_logError(lError);
      return *off;
    when  SqlCode = 100;
      lError.code = 'STD0005';
      lError.text = 'Date figement contrat not found';
      lError.textUser = 'Date figement contrat non trouvée'
       + '//Ctr : ' + %char(pNumeroContrat) + '/Ets :  ' + %char(pCodeEtablissement);
      lError.nomZone = 'contrat';    
      CKOOL_logError(lError);
      return *off;
    other;
      pDateFigement = lDateFigement;
  endsl;

  // finalisation
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off; 
    endif;
end-proc;