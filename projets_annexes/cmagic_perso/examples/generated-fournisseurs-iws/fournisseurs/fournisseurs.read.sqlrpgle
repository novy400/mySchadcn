**free
// Generated from CatalogSpec with catalog-read.sqlrpgle.hbs. Do not edit.
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL');
/include 'fournisseurs.read.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'

exec sql set option commit = *none, datfmt = *iso, closqlcsr = *endmod;

dcl-proc fournis_reject_query;
  dcl-pi *n;
    pErrors likeDS(GLOBAL_listError);
    pField varchar(32) const;
    pMessage varchar(256) const;
  end-pi;
  pErrors.listError(1).code = 'CAT0001';
  pErrors.listError(1).nomZone = pField;
  pErrors.listError(1).text = pMessage;
  pErrors.listError(1).textUser = pMessage;
end-proc;

dcl-proc fournis_reject_mutation;
  dcl-pi *n;
    pErrors likeDS(GLOBAL_listError);
    pCode varchar(7) const;
    pField varchar(32) const;
    pMessage varchar(256) const;
  end-pi;
  pErrors.listError(1).code = pCode;
  pErrors.listError(1).nomZone = pField;
  pErrors.listError(1).text = pMessage;
  pErrors.listError(1).textUser = pMessage;
end-proc;

dcl-proc fournis_getSupportedFields export;
  dcl-pi *n ind;
    pSupportedFields likeDS(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s lIt int(10) inz(0);
  dcl-s ErrorHappened ind;

  clear pSupportedFields;
  clear pErrors;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'id';
  pSupportedFields.supportedFields(lIt).sqlField = 'ID';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 10;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'nom';
  pSupportedFields.supportedFields(lIt).sqlField = 'NOM';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 100;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'adresse';
  pSupportedFields.supportedFields(lIt).sqlField = 'ADRESSE';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 160;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'ville';
  pSupportedFields.supportedFields(lIt).sqlField = 'VILLE';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 80;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'telephone';
  pSupportedFields.supportedFields(lIt).sqlField = 'TELEPHONE';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 20;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'email';
  pSupportedFields.supportedFields(lIt).sqlField = 'EMAIL';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).maxLength = 254;
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  pSupportedFields.fieldsCount = lIt;
  sorta %subarr(pSupportedFields.supportedFields(*).orderTri
    : 1 : pSupportedFields.fieldsCount);
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      clear pSupportedFields;
      return *off;
    endif;
end-proc;

dcl-proc fournis_search export;
  dcl-pi *n ind;
    pContext likeDS(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pItems pointer;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lRequestedContext likeDS(CMAGIC_context) inz;
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lSupportedFields likeDS(CMAGIC_supportedFields) inz;
  dcl-ds lRow likeDS(fournis_item_t) inz;
  dcl-s lSelect varchar(5000) inz;
  dcl-s lSelCount like(lSelect) inz;
  dcl-s lWhere like(lSelect) inz;
  dcl-s lOrderBy like(lSelect) inz;
  dcl-s lItems pointer inz;
  dcl-s lCount like(CMAGIC_totalCount) inz(0);
  dcl-s ErrorHappened ind;

  clear pTotalCount;
  clear pItems;
  clear pErrors;
  lRequestedContext = pContext;
  if %trim(lRequestedContext.sort(1).field) = *blanks;
    lRequestedContext.sort(1).field = 'id';
    lRequestedContext.sort(1).order = 'ASC';
  endif;

  if not fournis_getSupportedFields(lSupportedFields : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  if not cmagic_sanitizeContext(lRequestedContext : lSupportedFields
    : lContext : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  if not cmagic_computeSqlClauses(lContext : lSupportedFields
    : lSelect : lWhere : lOrderBy : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  lSelect += ' FROM FOURNIS';
  if lWhere <> *blanks;
    lSelect = %trim(lSelect) + ' ' + %trim(lWhere);
  endif;
  lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelect)
    + ') CATALOG_COUNT';
  if lOrderBy <> *blanks;
    lSelect = %trim(lSelect) + ' ' + %trim(lOrderBy);
  endif;
  lSelect = %trim(lSelect)
    + ' LIMIT ' + %char(lContext.pagination.perPage)
    + ' OFFSET ' + %char(
      (lContext.pagination.numPage - 1)
      * lContext.pagination.perPage)
    + ' FOR READ ONLY OPTIMIZE FOR '
    + %char(lContext.pagination.perPage) + ' ROWS';

  lItems = list_create();
  exec sql prepare CATALOG_LIST_STATEMENT from :lSelect;
  if sqlState <> SQL_OK;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to prepare search query');
    list_dispose(lItems);
    return *off;
  endif;

  exec sql declare CATALOG_LIST cursor for CATALOG_LIST_STATEMENT;
  exec sql open CATALOG_LIST;
  if sqlState <> SQL_OK;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to open search cursor');
    list_dispose(lItems);
    return *off;
  endif;

  dow sqlState = SQL_OK;
    clear lRow;
    exec sql fetch next from CATALOG_LIST into :lRow;
    if sqlState = SQL_NOT_FOUND;
      leave;
    endif;
    if sqlState <> SQL_OK;
      exec sql close CATALOG_LIST;
      fournis_reject_query(
        pErrors : 'sql' : 'Unable to fetch search row');
      list_dispose(lItems);
      return *off;
    endif;
    list_add(lItems : %addr(lRow) : %size(lRow));
  enddo;
  exec sql close CATALOG_LIST;

  exec sql prepare CATALOG_COUNT_STATEMENT from :lSelCount;
  if sqlState <> SQL_OK;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to prepare count query');
    list_dispose(lItems);
    return *off;
  endif;

  exec sql declare CATALOG_COUNT cursor for CATALOG_COUNT_STATEMENT;
  exec sql open CATALOG_COUNT;
  if sqlState <> SQL_OK;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to open count cursor');
    list_dispose(lItems);
    return *off;
  endif;
  exec sql fetch next from CATALOG_COUNT into :lCount;
  if sqlState <> SQL_OK and sqlState <> SQL_NOT_FOUND;
    exec sql close CATALOG_COUNT;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to fetch total count');
    list_dispose(lItems);
    return *off;
  endif;
  exec sql close CATALOG_COUNT;

  pItems = lItems;
  pTotalCount = lCount;
  return *on;

  on-exit ErrorHappened;
    exec sql close CATALOG_LIST;
    exec sql close CATALOG_COUNT;
    if ErrorHappened;
      if lItems <> *null;
        list_dispose(lItems);
      endif;
      return *off;
    endif;
end-proc;

dcl-proc fournis_get export;
  dcl-pi *n ind;
    pId varchar(10) const;
    pDetail likeDS(fournis_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  clear pDetail;
  clear pErrors;
  exec sql
    select
      ID,
      NOM,
      COALESCE(ADRESSE, ''),
      COALESCE(VILLE, ''),
      COALESCE(TELEPHONE, ''),
      COALESCE(EMAIL, '')
    into :pDetail
    FROM FOURNIS
    WHERE ID = :pId
    fetch first 1 row only;
  if sqlState = SQL_NOT_FOUND;
    fournis_reject_query(
      pErrors : 'id' : 'Fournis not found');
    return *off;
  endif;
  if sqlState <> SQL_OK;
    fournis_reject_query(
      pErrors : 'sql' : 'Unable to read Fournis');
    return *off;
  endif;
  return *on;
end-proc;
dcl-proc fournis_isValid export;
  dcl-pi *n ind;
    pAction like(GLOBAL_codeAction) const;
    pBeforeDetail likeDS(fournis_detail_t) const;
    pAfterDetail likeDS(fournis_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-s lErrorIndex int(10) inz(0);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s ErrorHappened ind;

  clear pErrors;
  select;
    when pAction = fournis_listeAction.creation
      or pAction = fournis_listeAction.modification;
      if %trim(pAfterDetail.id) = *blanks;
        lErrorIndex += 1;
        pErrors.listError(lErrorIndex).code = 'CAT1001';
        pErrors.listError(lErrorIndex).nomZone = 'id';
        pErrors.listError(lErrorIndex).text = 'id is required';
        pErrors.listError(lErrorIndex).textUser =
          pErrors.listError(lErrorIndex).text;
      endif;
      if %trim(pAfterDetail.nom) = *blanks;
        lErrorIndex += 1;
        pErrors.listError(lErrorIndex).code = 'CAT1001';
        pErrors.listError(lErrorIndex).nomZone = 'nom';
        pErrors.listError(lErrorIndex).text = 'nom is required';
        pErrors.listError(lErrorIndex).textUser =
          pErrors.listError(lErrorIndex).text;
      endif;
      if pAction = fournis_listeAction.modification
        and pBeforeDetail.id <> pAfterDetail.id;
        lErrorIndex += 1;
        pErrors.listError(lErrorIndex).code = 'CAT1005';
        pErrors.listError(lErrorIndex).nomZone = 'id';
        pErrors.listError(lErrorIndex).text =
          'id cannot be changed';
        pErrors.listError(lErrorIndex).textUser =
          pErrors.listError(lErrorIndex).text;
      endif;
    other;
      fournis_reject_mutation(
        pErrors : 'CAT1003' : 'action' : 'Unsupported mutation action');
      return *off;
  endsl;

  if lErrorIndex > 0;
    return *off;
  endif;
  if not fournis_isValid_business(
    pAction : pBeforeDetail : pAfterDetail : lErrors);
    pErrors = lErrors;
    return *off;
  endif;
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      fournis_reject_mutation(
        pErrors : 'RNX9001' : 'sql' :
        'Unexpected error while validating Fournis');
      return *off;
    endif;
end-proc;
dcl-proc fournis_create export;
  dcl-pi *n ind;
    pDetail likeDS(fournis_detail_t) const;
    pId varchar(10);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lBeforeDetail likeDS(fournis_detail_t) inz;
  dcl-ds lAfterDetail likeDS(fournis_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s ErrorHappened ind;

  clear pId;
  clear pErrors;
  lAfterDetail = pDetail;
  if not fournis_isValid(fournis_listeAction.creation
    : lBeforeDetail : lAfterDetail : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  exec sql
    INSERT INTO FOURNIS
    (ID, NOM, ADRESSE, VILLE, TELEPHONE, EMAIL)
    VALUES
    (:pDetail.id, :pDetail.nom, NULLIF(:pDetail.adresse, ''), NULLIF(:pDetail.ville, ''), NULLIF(:pDetail.telephone, ''), NULLIF(:pDetail.email, ''));
  select;
    when sqlState = '23505';
      fournis_reject_mutation(
        pErrors : 'CAT1002' : 'conflict' :
        'Fournis already exists');
      return *off;
    when sqlState <> SQL_OK;
      fournis_reject_mutation(
        pErrors : sqlState : 'sql' :
        'Unable to create Fournis');
      return *off;
  endsl;

  pId = pDetail.id;
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      fournis_reject_mutation(
        pErrors : 'RNX9001' : 'sql' :
        'Unexpected error while creating Fournis');
      return *off;
    endif;
end-proc;
dcl-proc fournis_update export;
  dcl-pi *n ind;
    pId varchar(10) const;
    pDetail likeDS(fournis_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lBeforeDetail likeDS(fournis_detail_t) inz;
  dcl-ds lAfterDetail likeDS(fournis_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s ErrorHappened ind;

  clear pErrors;
  if not fournis_get(pId : lBeforeDetail : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  lAfterDetail = pDetail;
  clear lErrors;
  if not fournis_isValid(fournis_listeAction.modification
    : lBeforeDetail : lAfterDetail : lErrors);
    pErrors = lErrors;
    return *off;
  endif;

  exec sql
    UPDATE FOURNIS
    SET
      NOM = :pDetail.nom,
      ADRESSE = NULLIF(:pDetail.adresse, ''),
      VILLE = NULLIF(:pDetail.ville, ''),
      TELEPHONE = NULLIF(:pDetail.telephone, ''),
      EMAIL = NULLIF(:pDetail.email, '')
    WHERE ID = :pId;
  select;
    when sqlState = '23505';
      fournis_reject_mutation(
        pErrors : 'CAT1002' : 'conflict' :
        'Fournis update conflicts with existing data');
      return *off;
    when sqlState <> SQL_OK;
      fournis_reject_mutation(
        pErrors : sqlState : 'sql' :
        'Unable to update Fournis');
      return *off;
  endsl;
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      fournis_reject_mutation(
        pErrors : 'RNX9001' : 'sql' :
        'Unexpected error while updating Fournis');
      return *off;
    endif;
end-proc;
// Ajoutez les regles metier specifiques dans cette procedure preservee.
// [CMAGIC:MANUAL_START]
dcl-proc fournis_isValid_business;
  dcl-pi *n ind;
    pAction like(GLOBAL_codeAction) const;
    pBeforeDetail likeDS(fournis_detail_t) const;
    pAfterDetail likeDS(fournis_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  clear pErrors;
  return *on;
end-proc;
// [CMAGIC:MANUAL_END]
