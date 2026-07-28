**free
// Generated from CatalogSpec with catalog-read.sqlrpgle.hbs. Do not edit.
ctl-opt nomain option(*srcstmt:*nounref) alwnull(*usrctl);
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'

dcl-ds service_item_t qualified template;
  id varchar(3);
  nom varchar(36);
  idmanageur varchar(6);
  idserviceadmin varchar(3);
  site varchar(16);
end-ds;
dcl-ds service_detail_t qualified template;
  id varchar(3);
  nom varchar(36);
  idmanageur varchar(6);
  idserviceadmin varchar(3);
  site varchar(16);
end-ds;

exec sql set option commit = *none, datfmt = *iso, closqlcsr = *endmod;

dcl-proc service_reject_query;
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

dcl-proc service_getSupportedFields export;
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
  pSupportedFields.supportedFields(lIt).sqlField = 'DEPTNO';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'nom';
  pSupportedFields.supportedFields(lIt).sqlField = 'DEPTNAME';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'idManageur';
  pSupportedFields.supportedFields(lIt).sqlField = 'MGRNO';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'idServiceAdmin';
  pSupportedFields.supportedFields(lIt).sqlField = 'ADMRDEPT';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
  pSupportedFields.supportedFields(lIt).orderTri = lIt;
  lIt += 1;
  pSupportedFields.supportedFields(lIt).name = 'site';
  pSupportedFields.supportedFields(lIt).sqlField = 'LOCATION';
  pSupportedFields.supportedFields(lIt).dataType = 'C';
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

dcl-proc service_search export;
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
  dcl-ds lRow likeDS(service_item_t) inz;
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

  if not service_getSupportedFields(lSupportedFields : lErrors);
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

  lSelect += ' FROM DEPARTMENT';
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
    service_reject_query(
      pErrors : 'sql' : 'Unable to prepare search query');
    list_dispose(lItems);
    return *off;
  endif;

  exec sql declare CATALOG_LIST cursor for CATALOG_LIST_STATEMENT;
  exec sql open CATALOG_LIST;
  if sqlState <> SQL_OK;
    service_reject_query(
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
      service_reject_query(
        pErrors : 'sql' : 'Unable to fetch search row');
      list_dispose(lItems);
      return *off;
    endif;
    list_add(lItems : %addr(lRow) : %size(lRow));
  enddo;
  exec sql close CATALOG_LIST;

  exec sql prepare CATALOG_COUNT_STATEMENT from :lSelCount;
  if sqlState <> SQL_OK;
    service_reject_query(
      pErrors : 'sql' : 'Unable to prepare count query');
    list_dispose(lItems);
    return *off;
  endif;

  exec sql declare CATALOG_COUNT cursor for CATALOG_COUNT_STATEMENT;
  exec sql open CATALOG_COUNT;
  if sqlState <> SQL_OK;
    service_reject_query(
      pErrors : 'sql' : 'Unable to open count cursor');
    list_dispose(lItems);
    return *off;
  endif;
  exec sql fetch next from CATALOG_COUNT into :lCount;
  if sqlState <> SQL_OK and sqlState <> SQL_NOT_FOUND;
    exec sql close CATALOG_COUNT;
    service_reject_query(
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

dcl-proc service_get export;
  dcl-pi *n ind;
    pId varchar(3) const;
    pDetail likeDS(service_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  clear pDetail;
  clear pErrors;
  exec sql
    select
      DEPTNO,
      DEPTNAME,
      COALESCE(MGRNO, ''),
      COALESCE(ADMRDEPT, ''),
      COALESCE(LOCATION, '')
    into :pDetail
    FROM DEPARTMENT
    WHERE DEPTNO = :pId
    fetch first 1 row only;
  if sqlState = SQL_NOT_FOUND;
    service_reject_query(
      pErrors : 'id' : 'Service not found');
    return *off;
  endif;
  if sqlState <> SQL_OK;
    service_reject_query(
      pErrors : 'sql' : 'Unable to read Service');
    return *off;
  endif;
  return *on;
end-proc;
