**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*iso)
        bnddir('QC2LE':'CKOOL':'NOXDB');

/include qinclude,TESTCASE
/include 'includes/serviws.rpgleinc'
/include 'includes/ciws.rpgleinc'
/include 'includes/service.rpgleinc'
/include 'includes/ckool.rpgleinc'

dcl-pr putenv int(10) extproc('putenv');
  envString pointer value options(*string);
end-pr;

dcl-proc setUp export;
  dcl-pi *n end-pi;
  dcl-s rc int(10);
  rc = putenv('QUERY_STRING=');
end-proc;

dcl-proc tearDown export;
  dcl-pi *n end-pi;
  dcl-s rc int(10);
  rc = putenv('QUERY_STRING=');
end-proc;

dcl-proc test_service_iws_getlist_nominal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s lExpectedCount like(CMAGIC_totalCount) inz(0);
  dcl-s rc int(10);

  exec sql
    select count(*) into :lExpectedCount
    from department;
  if sqlcode <> 0;
    fail('Erreur SQL lors du calcul du total attendu');
  endif;

  rc = putenv('QUERY_STRING=');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  iEqual(lExpectedCount : totalCount : 'totalCount doit correspondre au COUNT SQL');
  assert(items_LENGTH <= HTTPREST_MAX_ITEMS : 'items_LENGTH respecte la limite');
  assert(%scan('X-Total-Count:' : httpHeaders(1)) = 1
       : 'Header X-Total-Count manquant en position 1');
  assert(%scan('Access-Control-Expose-Headers: X-Total-Count' : httpHeaders(2)) = 1
       : 'Header expose CORS manquant en position 2');
end-proc;

dcl-proc test_service_iws_getlist_pagination_perPage3 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s rc int(10);
  rc = putenv('QUERY_STRING=page=1&perPage=3');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  assert(items_LENGTH <= 3 : 'Pagination perPage=3 non respectee');
end-proc;
// rrrrt
dcl-proc test_service_iws_getlist_filter_idServiceAdmin export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s lExpectedCount like(CMAGIC_totalCount) inz(0);
  dcl-s i int(10);
  dcl-s rc int(10);

  exec sql
    select count(*) into :lExpectedCount
    from department
    where admrdept = 'A00';
  if sqlcode <> 0;
    fail('Erreur SQL lors du calcul du total filtre');
  endif;

  rc = putenv('QUERY_STRING=idServiceAdmin=A00&perPage=100');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  iEqual(lExpectedCount : totalCount : 'totalCount filtre incorrect');

  for i = 1 to items_LENGTH;
    aEqual('A00' : %trim(items(i).idServiceAdmin)
         : 'Chaque element retourne doit avoir idServiceAdmin=A00');
  endfor;
end-proc;

dcl-proc test_service_iws_getlist_sort_nom_desc export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s lExpectedFirstCode char(3);
  dcl-s rc int(10);

  clear lExpectedFirstCode;
  exec sql
    select deptno into :lExpectedFirstCode
    from department
    order by deptname desc
    fetch first 1 row only;
  if sqlcode <> 0;
    fail('Erreur SQL lors du calcul du premier code attendu');
  endif;

  rc = putenv('QUERY_STRING=sort=nom&order=DESC&perPage=10');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  assert(items_LENGTH > 0 : 'La liste ne doit pas etre vide');
  aEqual(%trim(lExpectedFirstCode) : %trim(items(1).id)
       : 'Le premier element doit respecter le tri nom DESC');
end-proc;

dcl-proc test_service_iws_getlist_perPage_capped_to_100 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s rc int(10);
  rc = putenv('QUERY_STRING=page=1&perPage=999');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  assert(items_LENGTH <= 100 : 'perPage doit etre plafonne a 100');
end-proc;

dcl-proc test_service_iws_getlist_not_query_string export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-s items_LENGTH int(10);
  dcl-ds items likeDS(service_detail_rest_t) dim(HTTPREST_MAX_ITEMS);
  dcl-s totalCount like(CMAGIC_totalCount);
  dcl-s errors_LENGTH int(10);
  dcl-ds errors likeDS(errorItem) dim(HTTPREST_MAX_ERRORS);
  dcl-s httpStatus like(HTTPREST_httpStatus);
  dcl-s httpHeaders like(HTTPREST_httpHeader) dim(HTTPREST_nbHeaders);

  dcl-s rc int(10);
  // rc = putenv('QUERY_STRING=page=1&perPage=999');

  service_getlist_iws(
    items_LENGTH:
    items:
    totalCount:
    errors_LENGTH:
    errors:
    httpStatus:
    httpHeaders
  );

  iEqual(HTTPREST_OK : httpStatus : 'HTTP status doit etre 200');
  assert(items_LENGTH <= 100 : 'perPage doit etre plafonne a 100');
end-proc;