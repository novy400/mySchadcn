**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'

// test 1
dcl-proc option;
  dcl-pi *n ;
  end-pi;
      exec sql SET OPTION
        COMMIT = *NONE
        , DATFMT = *ISO;
end-proc;

dcl-proc cmagic_sanitizeContext export;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pSupportedFields likeDS(CMAGIC_supportedFields) const;
   pSanitizedContext likeDS(CMAGIC_context);
   pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lError likeds(errorItem) inz;
  dcl-ds lCleanContext likeDS(CMAGIC_context) inz;
  dcl-s ErrorHappened ind;
  dcl-ds lItemFiltre likeDS(CMAGIC_filter);
  dcl-ds lItemSort likeDS(CMAGIC_sort);
  dcl-s lIdx int(10);
  dcl-s lFound int(10);

  //initialisation
    clear pSanitizedContext;
    clear pErrors;
  // traitement 
    clear lCleanContext;
    
    // --- 1. Contrôle Pagination ---
    if pContext.pagination.numPage <= 0;
      lCleanContext.pagination.numPage = 1;
    else;
      lCleanContext.pagination.numPage = pContext.pagination.numPage;
    endif;
    
    if pContext.pagination.perPage <= 0;
      lCleanContext.pagination.perPage = CMAGIC_DEFAULT_LIMIT;
    else;
      lCleanContext.pagination.perPage = pContext.pagination.perPage;
    endif;

    // --- 2. Contrôle Sort (Whitelist) ---
    // On ne copie QUE les champs qui existent dans la configuration
    lIdx = 0;
    for-each lItemSort in pContext.sort;
      if lItemSort.field <> *blanks;
         // Vérifier si le champ est autorisé
         lFound = %lookup(lItemSort.field : pSupportedFields.supportedFields(*).name);
         if lFound > 0;
             lIdx += 1;
             if lIdx > %elem(lCleanContext.sort);
                leave;
             endif;
             
             lCleanContext.sort(lIdx).field = lItemSort.field;
             
             // Assainissement strict de la order (ASC/DESC uniquement)
             if %upper(%trim(lItemSort.order)) = 'DESC';
                 lCleanContext.sort(lIdx).order = 'DESC';
             else;
                 lCleanContext.sort(lIdx).order = 'ASC';
             endif;
         endif;
      endif;
    endfor;

    // --- 3. Contrôle Filtre (Whitelist) ---
    lIdx = 0;
    for-each lItemFiltre in pContext.filter;
       if lItemFiltre.field <> *blanks;
         
         // Cas spécial : 'q' est un champ virtuel autorisé par défaut
         if lItemFiltre.field = 'q';
             lIdx += 1;
             if lIdx > %elem(lCleanContext.filter);
                leave;
             endif;
             lCleanContext.filter(lIdx) = lItemFiltre;
             // Pas de validation operateur nécessaire pour q, 
             //c'est géré par cmagic_computeSqlClauses
         else;
             // Vérifier si le champ est autorisé
             lFound = %lookup(lItemFiltre.field : pSupportedFields.supportedFields(*).name);
             if lFound > 0;
                 lIdx += 1;
                 if lIdx > %elem(lCleanContext.filter);
                    leave;
                 endif;
                 
                 lCleanContext.filter(lIdx).field = lItemFiltre.field;
                 lCleanContext.filter(lIdx).value = lItemFiltre.value; 
                 lCleanContext.filter(lIdx).operator = lItemFiltre.operator; 
             endif;
         endif;
       endif;
    endfor;

  // finalisation
    pSanitizedContext = lCleanContext;
    return *on;
    on-exit ErrorHappened;
      if ErrorHappened;
        clear pSanitizedContext;
        return *off;
      endif;
end-proc;

dcl-proc cmagic_computeSqlClauses export;
  dcl-pi *N ind;
    pContext likeDS(CMAGIC_context) const;
    pSupportedFields likeDS(CMAGIC_supportedFields) const;
    pSelect varchar(5000);
    pWhere varchar(5000);
    pOrderBy varchar(5000);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-s lFirst ind;
  dcl-ds lItemFiltre likeDS(CMAGIC_filter);
  dcl-ds lItemSort likeDS(CMAGIC_sort);
  dcl-s lString like(CMAGIC_filter.value);
  dcl-s dbFieldName varchar(64);
  dcl-s isNumericField ind;
  dcl-s isDateField ind;
  dcl-s isCharacterField ind;
  dcl-s lIt int(5);
  dcl-s lScanIt int(5);
  dcl-s lFirstOr ind;
  dcl-ds lContext likeds(pContext);
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;

  // Initialisation
  clear pSelect;
  clear pWhere;
  clear pOrderBy;
  clear pErrors;
  clear lContext;
  lContext = pContext;
  clear lSupportedFields;
  lSupportedFields = pSupportedFields;

  SORTA %SUBARR(lSupportedFields.supportedFields(*).orderTri 
                : 1 : lSupportedFields.fieldsCount);


  // 0. Construction du SELECT (NOUVEAU)
  // On itère sur tous les champs configurés pour construire la liste
  lFirst = *on;
  for lIt = 1 to lSupportedFields.fieldsCount;
     if lSupportedFields.supportedFields(lIt).name = *blanks;
        iter;
     endif;
      // Détermination de la syntaxe de colonne avec sécurité NULL
     dbFieldName = %trim(lSupportedFields.supportedFields(lIt).sqlField);
     
     select;
        // Cas Numérique : IFNULL(col, 0)
        when lSupportedFields.supportedFields(lIt).dataType = 'N';
           dbFieldName = 'IFNULL(' + dbFieldName + ', 0)';
           
        // Cas Date : IFNULL(col, '0001-01-01')
        when lSupportedFields.supportedFields(lIt).dataType = 'D';
           dbFieldName = 'IFNULL(' + dbFieldName + ', date(''0001-01-01''))';
           
        // Cas Charactère (défaut) : IFNULL(col, '')
        other;
           dbFieldName = 'IFNULL(' + dbFieldName + ', '''')';
     endsl;

     if lFirst;
        pSelect = 'SELECT ' + dbFieldName;
        lFirst = *off;
     else;
        pSelect += ', ' + dbFieldName;
     endif;
  endfor;
  
  // Si aucun champ configuré, on met * (sécurité)
  if lFirst; 
     pSelect = 'SELECT *';
  endif;


  // 1. Construction du WHERE
  lFirst = *on;
  sorta(d) lContext.filter(*).field;
  for-each lItemFiltre in lContext.filter;
    if %len(%trim(lItemFiltre.field)) = *zeros;
      leave;
    endif;
      
    if lFirst;
      pWhere = 'WHERE';
      lFirst = *off;
    else;
      pWhere = %trim(pWhere) + ' AND' ;
    endif;
      
    // Cas spécial : Recherche globale 'q'
    if %trim(lItemFiltre.field) = 'q';
      // Stratégie par défaut : On cherche "LIKE" sur tous les champs CHARACTÈRE configurés
      pWhere = ' ' + %trim(pWhere) + ' (';
      lFirstOr = *on;
      
      for lScanIt = 1 to lSupportedFields.fieldsCount;
         if lSupportedFields.supportedFields(lScanIt).name = *blanks;
            iter;
         endif;
         
         // On inclut uniquement les champs texte dans la recherche globale
         if lSupportedFields.supportedFields(lScanIt).dataType = 'C'; 
            if not lFirstOr;
               pWhere += ' OR ';
            endif;
            pWhere += 'UPPER(' + %trim(lSupportedFields.supportedFields(lScanIt).sqlField) 
                    + ') LIKE UPPER(' 
                   + GLOBAL_QUOTE + '%' + %trim(lItemFiltre.value) + '%' + GLOBAL_QUOTE + ')';
            lFirstOr = *off;
         endif;
      endfor;
      
      if lFirstOr; // Sécurité si aucun champ texte
         pWhere += '1=1'; 
      endif;
      pWhere += ')';
      
    else;
      // Filtres standards champ par champ
      clear lString;
      lString = %trim(lItemFiltre.value);
      
      // Chercher le champ dans la config
      clear lIt;
      lIt = %lookup(%trim(lItemFiltre.field) : lSupportedFields.supportedFields(*).name);
      
      if lIt = 0;
        iter; // Champ inconnu ignoré
      endif;

      // Déterminer le type et le nom SQL
      isNumericField = *off;
      isDateField = *off;
      isCharacterField = *off;
      dbFieldName = lSupportedFields.supportedFields(lIt).sqlField;

      select;
        when (lSupportedFields.supportedFields(lIt).dataType = 'N'); // CMAGIC_typeChamp.NUMERIC
          isNumericField = *on;
        when (lSupportedFields.supportedFields(lIt).dataType = 'D'); // CMAGIC_typeChamp.DATE
          isDateField = *on;
        other;
          isCharacterField = *on;
      endsl;

      // Préparation de la partie gauche (Colonne)
      if NOT (%trim(lItemFiltre.operator) = 'LIKE'); // CMAGIC_OP_LIKE
         select;
          when isCharacterField;
            pWhere = ' ' + %trim(pWhere) + ' upper(' + %trim(dbFieldName) + ')';
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          when isDateField;
            pWhere = ' ' + %trim(pWhere) + '  ' + %trim(dbFieldName) ;
            lstring = GLOBAL_QUOTE + %trim(%upper(lString)) + GLOBAL_QUOTE;
          when isNumericField;  
            pWhere = ' ' + %trim(pWhere) + '  ' + %trim(dbFieldName) ;
        endsl;
      else;
         // LIKE force le UPPER
         pWhere = ' ' + %trim(pWhere) + ' upper(' + %trim(dbFieldName) + ')';
      endif;

      // Préparation de la partie droite (Opérateur + Valeur)
      select;
        when %trim(lItemFiltre.operator) = 'LIKE';
          pWhere = ' ' + %trim(pWhere) + ' LIKE ';
          if %scan('%' : %trim(lString)) = 0;
            lString = '%' + %trim(lString) + '%';
          endif;
          pWhere += ' UPPER(' + GLOBAL_QUOTE + %upper(%trim(lString)) + GLOBAL_QUOTE + ')';

        when %trim(lItemFiltre.operator) = '>=';
          pWhere = ' ' + %trim(pWhere) + ' >= ' + %trim(lString);
        when %trim(lItemFiltre.operator) = '<=';
          pWhere = ' ' + %trim(pWhere) + ' <= ' + %trim(lString);
        when %trim(lItemFiltre.operator) = '>';
           pWhere = ' ' + %trim(pWhere) + ' > ' + %trim(lString);
        when %trim(lItemFiltre.operator) = '<';
           pWhere = ' ' + %trim(pWhere) + ' < ' + %trim(lString);
        when %trim(lItemFiltre.operator) = '<>';
           pWhere = ' ' + %trim(pWhere) + ' <> ' + %trim(lString);
        other; // EQUAL
           pWhere = ' ' + %trim(pWhere) + ' = ' + %trim(lString);
      endsl;
    endif;
  endfor;

  // 2. Construction du ORDER BY
  lFirst = *on;
  sorta(d) lContext.sort(*).field;
  for-each lItemSort in lContext.sort;
    if %len(%trim(lItemSort.field)) = *zeros;
      leave;
    endif;
    
    // Mapper les noms api -> sql
    clear lIt;
    lIt = %lookup(%trim(lItemSort.field) : pSupportedFields.supportedFields(*).name);
    
    if lIt > 0;
      dbFieldName = pSupportedFields.supportedFields(lIt).sqlField;
    else;
      iter;
    endif;  
    
    if lFirst;
      pOrderBy = 'Order by';
      lFirst = *off;
    else;
      pOrderBy = %trim(pOrderBy) + ' ,' ;
    endif;
    
    pOrderBy = ' ' + %trim(pOrderBy) + ' ' + %trim(dbFieldName) + ' ' + %trim(lItemSort.order); 
  endfor;

  return *on;
end-proc;
