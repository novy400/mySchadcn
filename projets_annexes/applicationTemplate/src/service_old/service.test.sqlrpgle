**free

ctl-opt nomain;

/include qinclude,TESTCASE
/include 'src/qrpgleref/cmagic.rpgleinc'
/include 'ressources/docs/cuaPatterns/global.rpgleinc'

dcl-proc test_employee_search export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds pContext likeDs(CMAGIC_context);
  dcl-ds pTotalCount likeDs(CMAGIC_totalCount);
  dcl-s pItems pointer(true);
  dcl-ds pErrors likeDs(GLOBAL_listError);
  dcl-s actual ind(true);
  dcl-s expected ind(true);

  // Input
  pContext.pagination.page = 0;
  pContext.pagination.perPage = 0;
  pContext.sort.field = '';
  pContext.sort.order = '';
  pContext.filter.field = '';
  pContext.filter.value = '';
  pItems = *null;
  pErrors.listError.nomZone = '';
  pErrors.listError.code = '';

  // Actual results
  actual = employee_search(pContext : pTotalCount : pItems : pErrors);

  // Expected results
  expected = *off;

  // Assertions
  nEqual(expected : actual : 'actual');
end-proc;

dcl-proc test_employee_search_firstPage export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds pContext likeDs(CMAGIC_context);
  dcl-ds pTotalCount likeDs(CMAGIC_totalCount);
  dcl-s pItems pointer(true);
  dcl-ds pErrors likeDs(GLOBAL_listError);
  dcl-s actual ind(true);
  dcl-s expected ind(true);

  // Input
  pContext.pagination.page = 1;
  pContext.pagination.perPage = 10;
  pContext.sort.field = '';
  pContext.sort.order = '';
  pContext.filter.field = '';
  pContext.filter.value = '';
  pItems = *null;
  pErrors.listError.nomZone = '';
  pErrors.listError.code = '';

  // Actual results
  actual = employee_search(pContext : pTotalCount : pItems : pErrors);

  // Expected results
  expected = *off;

  // Assertions
  nEqual(expected : actual : 'actual');
end-proc;