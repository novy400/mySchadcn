**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');
/include qinclude,TESTCASE 
/include 'includes/service.rpgleinc'
/include 'includes/ileastic/ileastic.rpgle'
/include 'includes/llist/llist_h.rpgle'
/include 'includes/ckool.rpgleinc'

dcl-pr QCMDEXC extpgm;
    command char(32767) const;
    length packed(15: 5) const;
end-pr;
dcl-s gCmd varchar(256);

dcl-proc setUpSuite export;
    dcl-pi *N; 
    end-pi;
end-proc;

dcl-proc setUp export;
    dcl-pi *N; 
    end-pi;
end-proc;

dcl-proc tearDown export;
    dcl-pi *N; 
    end-pi;
end-proc;

dcl-proc tearDownSuite export;
    dcl-pi *N; 
    end-pi;
end-proc;

// =============================================================================
// Tests de recherche (service_search) rrr
// =============================================================================

dcl-proc test_service_search_firstPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    
    // Initialisation - Recherche du nombre total de services
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from department;
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des services');
    endif;
    
    // Recherche des services - Première page
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure service_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de services retourné est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    assert(lCount <= lContext.pagination.perPage
      : '<KO> Le nombre de services d''une page est supérieur à celui attendu');
      
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_firstPage');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_service_search_lastPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;
    
    // Initialisation - Recherche du nombre total de services
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from department;
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des services');
    endif;
    
    // Calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page : ' + %char(lLastPage));
    
    // Recherche des services - Dernière page
    clear lContext;
    lContext.pagination.numPage = lLastPage;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure service_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de services retourné est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Total items in list : ' + %char(lCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_lastPage');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_service_search_filter_admrdept export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-c PERPAGE 10;
    
    // Initialisation - Recherche du nombre de services avec admrdept = 'A00'
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from department where admrdept = 'A00';
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des services filtrés');
    endif;
    
    CKOOL_logMessage('Expected Count with admrdept=A00: ' + %char(lTotalCountExpected));
    
    // Recherche des services avec filtre
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du filtre sur idServiceAdmin
    lContext.filter(1).field = 'idServiceAdmin';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'A00';
    
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' ' + lContext.filter(1).operator 
      + ' ' + lContext.filter(1).value);
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure service_search avec filtre');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de services filtrés est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Nombre de services retournés : ' + %char(lCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_filter_admrdept');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_service_search_order_by_name export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lCodeExpected char(3);
    dcl-ds lItem likeds(service_item_t) based(lItemPtr);
    dcl-s lItemPtr pointer;
    
    // Initialisation - Recherche du premier service par ordre alphabétique
    clear lCodeExpected;
    exec sql
      select deptno into :lCodeExpected
      from department
      order by deptname
      fetch first 1 row only;
    if sqlcode <> 0;
      fail('Erreur SQL lors de la recherche du premier service');
    endif;
    
    CKOOL_logMessage('Code attendu en premier : ' + lCodeExpected);
    
    // Recherche des services avec tri
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du tri sur nom
    lContext.sort(1).field = 'nom';
    lContext.sort(1).order = 'asc';
    
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure service_search avec tri');
    
    // Vérification du premier élément de la liste
    lItemPtr = list_get(list : 0);
    if lItemPtr <> *null;
      CKOOL_logMessage('Service : ' + lItem.id.code + ' - ' + %trim(lItem.nom));
      assert(lCodeExpected = lItem.id.code
        : '<KO> Le premier service ne correspond pas au tri attendu');
    else;
      fail('La liste est vide');
    endif;
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_order_by_name');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_service_search_filter_like_name export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    
    // Initialisation - Recherche du nombre de services contenant 'SYSTEMS' dans le nom
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from department where deptname like '%SYSTEMS%';
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des services avec LIKE');
    endif;
    
    CKOOL_logMessage('Expected Count with LIKE SYSTEMS: ' + %char(lTotalCountExpected));
    
    // Recherche des services avec filtre LIKE
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du filtre LIKE sur nom
    lContext.filter(1).field = 'nom';
    lContext.filter(1).operator = 'LIKE';
    lContext.filter(1).value = '%SYSTEMS%';
    
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' ' + 
      lContext.filter(1).operator + ' ' + lContext.filter(1).value);
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure service_search avec LIKE');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de services avec LIKE est différent de celui attendu');
    
    CKOOL_logMessage('Nombre retourné : ' + %char(lTotalCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_filter_like_name');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_service_search_multiple_filters export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    
    // Initialisation - Recherche avec plusieurs filtres
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from department 
      where admrdept = 'A00' 
        and deptname like '%SYSTEMS%';
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage avec filtres multiples');
    endif;
    
    CKOOL_logMessage('Expected Count with multiple filters: ' + %char(lTotalCountExpected));
    
    // Recherche des services avec filtres multiples
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Premier filtre
    lContext.filter(1).field = 'idServiceAdmin';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'A00';
    
    // Deuxième filtre
    lContext.filter(2).field = 'nom';
    lContext.filter(2).operator = 'LIKE';
    lContext.filter(2).value = '%SYSTEMS%';
    
    lOK = service_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel avec filtres multiples');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre avec filtres multiples est différent de celui attendu');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_search_multiple_filters');
      endif;
      list_dispose(list);
end-proc;

// =============================================================================
// Tests CRUD (getByID, create, update, delete)
// =============================================================================

dcl-proc test_service_getByID_success export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lDetail likeDS(service_detail_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lCodeTest char(3);
    
    // Initialisation - Récupération d'un code existant
    clear lCodeTest;
    exec sql
      select deptno into :lCodeTest
      from department
      fetch first 1 row only;
    if sqlcode <> 0;
      fail('Erreur SQL lors de la recherche d''un service existant');
    endif;
    
    CKOOL_logMessage('Test getByID avec code : ' + lCodeTest);
    
    // Appel de service_getByID
    clear lId;
    lId.code = lCodeTest;
    
    lOK = service_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de service_getByID');
    assert(lDetail.id.code = lCodeTest
      : '<KO> Le code retourné ne correspond pas');
    assert(lDetail.nom <> *blanks
      : '<KO> Le nom du service est vide');
    
    CKOOL_logMessage('Service trouvé : ' + %trim(lDetail.nom));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_getByID_success');
      endif;
end-proc;

dcl-proc test_service_getByID_notFound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lDetail likeDS(service_detail_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // Initialisation - Code inexistant
    clear lId;
    lId.code = 'XXX';
    
    CKOOL_logMessage('Test getByID avec code inexistant : ' + lId.code);
    
    // Appel de service_getByID
    lOK = service_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> service_getByID devrait retourner *off pour un code inexistant');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_getByID_notFound');
      endif;
end-proc;

dcl-proc test_service_create_success export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeDS(service_detail_t);
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // TODO: Implémenter test de création
    // Note: Nécessite gestion de nettoyage pour éviter doublons
    
    CKOOL_logMessage('Test create - À implémenter');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_create_success');
      endif;
end-proc;

dcl-proc test_service_update_success export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lDetail likeDS(service_detail_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // TODO: Implémenter test de mise à jour
    // Note: Nécessite données de test et restauration après modif
    
    CKOOL_logMessage('Test update - À implémenter');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_update_success');
      endif;
end-proc;

dcl-proc test_service_update_notFound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lDetail likeDS(service_detail_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // Initialisation - Code inexistant
    clear lId;
    lId.code = 'XXX';
    clear lDetail;
    lDetail.nom = 'Test Service';
    
    CKOOL_logMessage('Test update avec code inexistant : ' + lId.code);
    
    // Appel de service_update
    lOK = service_update(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> service_update devrait retourner *off pour un code inexistant');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_update_notFound');
      endif;
end-proc;

dcl-proc test_service_delete_success export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    
    // TODO: Implémenter test de suppression
    // Note: Nécessite création préalable d'un service de test
    
    CKOOL_logMessage('Test delete - À implémenter');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_delete_success');
      endif;
end-proc;

dcl-proc test_service_delete_notFound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // Initialisation - Code inexistant
    clear lId;
    lId.code = 'XXX';
    
    CKOOL_logMessage('Test delete avec code inexistant : ' + lId.code);
    
    // Appel de service_delete
    lOK = service_delete(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> service_delete devrait retourner *off pour un code inexistant');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_delete_notFound');
      endif;
end-proc;

dcl-proc test_service_display_success export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(service_id_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lCodeTest char(3);
    
    // Initialisation - Récupération d'un code existant
    clear lCodeTest;
    exec sql
      select deptno into :lCodeTest
      from department
      fetch first 1 row only;
    if sqlcode <> 0;
      fail('Erreur SQL lors de la recherche d''un service existant');
    endif;
    
    CKOOL_logMessage('Test display avec code : ' + lCodeTest);
    
    // Appel de service_display
    clear lId;
    lId.code = lCodeTest;
    
    lOK = service_display(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de service_display');
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_service_display_success');
      endif;
end-proc;

// =============================================================================
// Procédures utilitaires (si nécessaire)
// =============================================================================

dcl-proc CRTDUPFILE;
    dcl-pi *N;
      pFromFile char(10) const;
      pToFile char(10) const;
    end-pi;
    monitor;
      gCmd = 'CRTDUPOBJ OBJ(' + %trim(pFromFile) 
        + ') FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) NEWOBJ(' 
        + %trim(pToFile) + ') DATA(*YES)';
      QCMDEXC(gCmd : %len(gCmd));
    on-error;
      // Ignore errors
    endmon;
end-proc;

dcl-proc OVRDBF;
    dcl-pi *N;
      pLogicalFile char(10) const;
      pPhysicalFile char(10) const;
    end-pi;
    monitor;
      gCmd = 'OVRDBF FILE(' + %trim(pLogicalFile) 
        + ') TOFILE(QTEMP/' + %trim(pPhysicalFile) + ')';
      QCMDEXC(gCmd : %len(gCmd));
    on-error;
      // Ignore errors
    endmon;
end-proc;

dcl-proc DLTFILE;
    dcl-pi *N;
      pFile char(10) const;
    end-pi;
    monitor;
      gCmd = 'DLTF FILE(QTEMP/' + %trim(pFile) + ')';
      QCMDEXC(gCmd : %len(gCmd));
    on-error;
      // Ignore errors
    endmon;
end-proc;
