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

dcl-proc service_list export;
  dcl-pi *n ind;
    pContext likeDS(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pItems pointer;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  dcl-ds lRow likeDS(service_item_t) inz;
  dcl-ds lFilter likeDS(CMAGIC_filter) inz;
  dcl-s lItems pointer inz;
  dcl-s lWindowTotal like(CMAGIC_totalCount) inz(0);
  dcl-s lPage int(10) inz(1);
  dcl-s lPerPage int(10) inz(CMAGIC_DEFAULT_LIMIT);
  dcl-s lOffset int(20) inz(0);
  dcl-s lSortField varchar(32) inz;
  dcl-s lSortOrder char(4) inz;
  dcl-s lUseQ int(3) inz(0);
  dcl-s lQ varchar(100) inz;
  dcl-s lUseIdEq int(3) inz(0);
  dcl-s lIdEq varchar(3) inz;
  dcl-s lUseIdLike int(3) inz(0);
  dcl-s lIdLike varchar(3) inz;
  dcl-s lUseNomEq int(3) inz(0);
  dcl-s lNomEq varchar(36) inz;
  dcl-s lUseNomLike int(3) inz(0);
  dcl-s lNomLike varchar(36) inz;
  dcl-s lUseIdManageurEq int(3) inz(0);
  dcl-s lIdManageurEq varchar(6) inz;
  dcl-s lUseIdServiceAdminEq int(3) inz(0);
  dcl-s lIdServiceAdminEq varchar(3) inz;
  dcl-s lUseSiteEq int(3) inz(0);
  dcl-s lSiteEq varchar(16) inz;
  dcl-s lUseSiteLike int(3) inz(0);
  dcl-s lSiteLike varchar(16) inz;

  clear pTotalCount;
  clear pItems;
  clear pErrors;
  lPage = pContext.pagination.numPage;
  lPerPage = pContext.pagination.perPage;
  if lPage < 1;
    lPage = 1;
  endif;
  if lPerPage < 1;
    lPerPage = CMAGIC_DEFAULT_LIMIT;
  endif;
  lOffset = (lPage - 1) * lPerPage;

  lSortField = 'id';
  lSortOrder = 'ASC';
  if %trim(pContext.sort(1).field) <> *blanks;
    select;
      when %trim(pContext.sort(1).field) = 'id';
        lSortField = 'id';
      when %trim(pContext.sort(1).field) = 'nom';
        lSortField = 'nom';
      other;
        service_reject_query(pErrors : %trim(pContext.sort(1).field)
          : 'Unsupported sort field');
        return *off;
    endsl;
  endif;
  if %trim(pContext.sort(1).order) <> *blanks;
    lSortOrder = %upper(%trim(pContext.sort(1).order));
    if lSortOrder <> 'ASC' and lSortOrder <> 'DESC';
      service_reject_query(pErrors : 'order'
        : 'Sort order must be ASC or DESC');
      return *off;
    endif;
  endif;

  for-each lFilter in pContext.filter;
    if %trim(lFilter.field) = *blanks;
      leave;
    endif;
    select;
      when %trim(lFilter.field) = 'q';
        if %upper(%trim(lFilter.operator)) <> 'LIKE'
          and %trim(lFilter.operator) <> *blanks;
          service_reject_query(
            pErrors : 'q' : 'Unsupported filter operator');
          return *off;
        endif;
        lUseQ = 1;
        lQ = '%' + %trim(lFilter.value) + '%';
      when %trim(lFilter.field) = 'id';
        select;
          when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');
            lUseIdEq = 1;
            lIdEq = %trim(lFilter.value);
          when %upper(%trim(lFilter.operator)) = 'LIKE';
            lUseIdLike = 1;
            lIdLike = %trim(lFilter.value);
          other;
            service_reject_query(
              pErrors : 'id' : 'Unsupported filter operator');
            return *off;
        endsl;
      when %trim(lFilter.field) = 'nom';
        select;
          when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');
            lUseNomEq = 1;
            lNomEq = %trim(lFilter.value);
          when %upper(%trim(lFilter.operator)) = 'LIKE';
            lUseNomLike = 1;
            lNomLike = %trim(lFilter.value);
          other;
            service_reject_query(
              pErrors : 'nom' : 'Unsupported filter operator');
            return *off;
        endsl;
      when %trim(lFilter.field) = 'idManageur';
        select;
          when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');
            lUseIdManageurEq = 1;
            lIdManageurEq = %trim(lFilter.value);
          other;
            service_reject_query(
              pErrors : 'idManageur' : 'Unsupported filter operator');
            return *off;
        endsl;
      when %trim(lFilter.field) = 'idServiceAdmin';
        select;
          when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');
            lUseIdServiceAdminEq = 1;
            lIdServiceAdminEq = %trim(lFilter.value);
          other;
            service_reject_query(
              pErrors : 'idServiceAdmin' : 'Unsupported filter operator');
            return *off;
        endsl;
      when %trim(lFilter.field) = 'site';
        select;
          when (%upper(%trim(lFilter.operator)) = 'EQ' or %trim(lFilter.operator) = '=');
            lUseSiteEq = 1;
            lSiteEq = %trim(lFilter.value);
          when %upper(%trim(lFilter.operator)) = 'LIKE';
            lUseSiteLike = 1;
            lSiteLike = %trim(lFilter.value);
          other;
            service_reject_query(
              pErrors : 'site' : 'Unsupported filter operator');
            return *off;
        endsl;
      other;
        service_reject_query(pErrors : %trim(lFilter.field)
          : 'Unsupported filter field');
        return *off;
    endsl;
  endfor;

  lItems = list_create();
  exec sql declare CATALOG_LIST cursor for
    select
      DEPTNO,
      DEPTNAME,
      COALESCE(MGRNO, ''),
      COALESCE(ADMRDEPT, ''),
      COALESCE(LOCATION, ''),
      COUNT(*) OVER()
    FROM DEPARTMENT
    WHERE (:lUseQ = 0 OR (
      UPPER(DEPTNO) LIKE UPPER(:lQ) OR
      UPPER(DEPTNAME) LIKE UPPER(:lQ) OR
      UPPER(LOCATION) LIKE UPPER(:lQ)
    ))
      AND (:lUseIdEq = 0 OR DEPTNO = :lIdEq)
      AND (:lUseIdLike = 0 OR DEPTNO LIKE :lIdLike)
      AND (:lUseNomEq = 0 OR DEPTNAME = :lNomEq)
      AND (:lUseNomLike = 0 OR DEPTNAME LIKE :lNomLike)
      AND (:lUseIdManageurEq = 0 OR MGRNO = :lIdManageurEq)
      AND (:lUseIdServiceAdminEq = 0 OR ADMRDEPT = :lIdServiceAdminEq)
      AND (:lUseSiteEq = 0 OR LOCATION = :lSiteEq)
      AND (:lUseSiteLike = 0 OR LOCATION LIKE :lSiteLike)
    ORDER BY
      CASE WHEN :lSortField = 'id'
        AND :lSortOrder = 'ASC' THEN DEPTNO END ASC
      , CASE WHEN :lSortField = 'id'
        AND :lSortOrder = 'DESC' THEN DEPTNO END DESC
      , CASE WHEN :lSortField = 'nom'
        AND :lSortOrder = 'ASC' THEN DEPTNAME END ASC
      , CASE WHEN :lSortField = 'nom'
        AND :lSortOrder = 'DESC' THEN DEPTNAME END DESC
      , DEPTNO ASC
    OFFSET :lOffset ROWS
    FETCH NEXT :lPerPage ROWS ONLY
    FOR READ ONLY;

  exec sql open CATALOG_LIST;
  if sqlState <> SQL_OK;
    service_reject_query(
      pErrors : 'sql' : 'Unable to open list cursor');
    list_dispose(lItems);
    return *off;
  endif;

  dow sqlState = SQL_OK;
    clear lRow;
    exec sql fetch next from CATALOG_LIST into :lRow, :lWindowTotal;
    if sqlState = SQL_NOT_FOUND;
      leave;
    endif;
    if sqlState <> SQL_OK;
      service_reject_query(
        pErrors : 'sql' : 'Unable to fetch list row');
      exec sql close CATALOG_LIST;
      list_dispose(lItems);
      return *off;
    endif;
    pTotalCount = lWindowTotal;
    list_add(lItems : %addr(lRow) : %size(lRow));
  enddo;
  exec sql close CATALOG_LIST;

  if pTotalCount = 0;
    exec sql
      select COUNT(*)
      into :pTotalCount
      FROM DEPARTMENT
    WHERE (:lUseQ = 0 OR (
      UPPER(DEPTNO) LIKE UPPER(:lQ) OR
      UPPER(DEPTNAME) LIKE UPPER(:lQ) OR
      UPPER(LOCATION) LIKE UPPER(:lQ)
    ))
      AND (:lUseIdEq = 0 OR DEPTNO = :lIdEq)
      AND (:lUseIdLike = 0 OR DEPTNO LIKE :lIdLike)
      AND (:lUseNomEq = 0 OR DEPTNAME = :lNomEq)
      AND (:lUseNomLike = 0 OR DEPTNAME LIKE :lNomLike)
      AND (:lUseIdManageurEq = 0 OR MGRNO = :lIdManageurEq)
      AND (:lUseIdServiceAdminEq = 0 OR ADMRDEPT = :lIdServiceAdminEq)
      AND (:lUseSiteEq = 0 OR LOCATION = :lSiteEq)
      AND (:lUseSiteLike = 0 OR LOCATION LIKE :lSiteLike)
    ;
    if sqlState <> SQL_OK;
      service_reject_query(
        pErrors : 'sql' : 'Unable to count list rows');
      list_dispose(lItems);
      return *off;
    endif;
  endif;

  pItems = lItems;
  return *on;
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
