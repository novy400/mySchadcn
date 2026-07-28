**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');
/include qinclude,TESTCASE 
/include 'includes/employee.rpgleinc'
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
// _______________________________
dcl-proc  test_employee_search_firstPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    // initialisation     dd
    // recherche du nombre total d'employés aie
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from employee;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // recherche des employes 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    assert(lCount = lContext.pagination.perPage
      : '<KO> Le nombre d''employés d''une page est différent de celui attendu');  
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_employee_search_lastPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;
    // initialisation
    // recherche du nombre total d'employés
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from employee;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));
    // recherche des employes
    clear lContext;
    lContext.pagination.numPage = lLastPage;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Total items in list : ' + %char(lCount));
    assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre d''employés d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_employee_search_workdept_A00 export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;

    // initialisation     
    // recherche du nombre total d'employés
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from employee where workdept = 'A00';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));

    // recherche des employes 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'idService';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'A00';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + lContext.filter(1).operator 
      + lContext.filter(1).value);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné ' +  %char(lTotalCount) 
        +  'est différent de celui attendu ' + %char(lTotalCountExpected)
        +'.');
    clear lCount;
    lCount = list_size(list);
     assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre d''employés d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_employee_search_order_lastName export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lCodeExpected char(6);
    dcl-s lCount int(10);
    dcl-c PERPAGE 10;
    dcl-ds lItem likeds(employee_detail_t) based(lItemPtr);

    // initialisation
    // recherche de l'id a trouvé.
    clear lCodeExpected;
    exec sql
      select empno 
      into :lCodeExpected
      from (
      select empno,lastname from employee 
        ) order by lastname  limit 1 offset 3;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;

    // recherche des employes 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.sort(1).field = 'nom';
    lContext.sort(1).order = 'asc';
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    // verification quatriéme  poste de la liste
    lItemPtr = list_get(list : 3);
    CKOOL_logMessage('Employee : ' + lItem.id.code + ' - ' + lItem.nom);
    assert(lCodeExpected = lItem.id.code
      : '<KO> Erreur dans le tri. L''employé trouvé n''est pas celui attendu');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list); 
                // bbb
end-proc;

dcl-proc  test_employee_search_workdept_like_E1 export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);

    // initialisation
    // recherche du nombre total d'employés
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from employee where workdept like '%E1%';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    CKOOL_logMessage('Expected Count: ' + %char(lTotalCountExpected));

    // recherche des employes 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'idService';
    lContext.filter(1).operator = 'LIKE';

    lContext.filter(1).value = '%E1%';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné est différent de celui attendu');
    CKOOL_logMessage('retourné : ' + %char(lTotalCount));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;
dcl-proc  test_employee_search_workdept_A00_lastname_HAAS export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;

    // initialisation     
    // recherche du nombre total d'employés
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from employee where workdept = 'A00' and lastname ='HAAS';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));

    // recherche des employes 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'idService';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'A00';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + lContext.filter(1).operator 
      + lContext.filter(1).value);
    lContext.filter(2).field = 'nom';
    lContext.filter(2).operator = '=';
    lContext.filter(2).value = 'HAAS';
   CKOOL_logMessage('Filtre : ' + lContext.filter(2).field + lContext.filter(2).operator 
      + lContext.filter(2).value);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné ' +  %char(lTotalCount) 
        +  'est différent de celui attendu ' + %char(lTotalCountExpected)
        +'.');
    clear lCount;
    lCount = list_size(list);
     assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre d''employés d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

// _______________________________________________________________________________________
dcl-proc CRTDUPFILE;
    dcl-pi *n ;
        pFichier char(10) const;
    end-pi;
    dcl-c THECMD 
    'CRTDUPOBJ OBJ(FICHIER) FROMLIB(*LIBL) OBJTYPE(*FILE) TOLIB(QTEMP) CST(*NO) TRG(*NO)';
    dcl-s lCmd like(gCmd) inz(THECMD);
    reset lCmd; 
    lCmd = %scanrpl('FICHIER': pFichier: lCmd);
    monitor;
        QCMDEXC(lCmd: %len(lCmd));
    on-error;
        snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + %trim(pFichier));
    endmon;
end-proc;
dcl-proc OVRDBF;
    dcl-pi *n ;
        pFichier char(10) const;
    end-pi;
    dcl-c THECMD 'OVRDBF FILE(FICHIER) TOFILE(QTEMP/FICHIER)';
    dcl-s lCmd like(gCmd) inz(THECMD);
    reset lCmd; 
    lCmd = %scanrpl('FICHIER': pFichier: lCmd);
    monitor;
        QCMDEXC(lCmd: %len(lCmd));
    on-error;
        snd-msg *escape ('Horreur ! dans ' + %trim(%proc()));
    endmon;
end-proc;
dcl-proc DLTFILE;
    dcl-pi *n ;
        pFichier char(10) const;
    end-pi;
    dcl-c THECMD 'DLTOBJ OBJ(QTEMP/FICHIER) OBJTYPE(*FILE)';
    dcl-s lCmd like(gCmd) inz(THECMD);
    reset lCmd; 
    lCmd = %scanrpl('FICHIER': pFichier: lCmd);
    monitor;
        QCMDEXC(lCmd: %len(lCmd));
    on-error;
        snd-msg *escape ('Horreur ! dans ' + %trim(%proc()));
    endmon;
end-proc;





// Tests pour employee_getByID
dcl-proc test_employee_getByID_success export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lId likeDS(employee_id_t) inz;
  dcl-ds lDetail likeDS(employee_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-s lCodeExpected char(6);

  // Récupérer un employé existant
  exec sql
    select empno into :lCodeExpected
    from employee
    fetch first 1 row only;
  if sqlcode <> 0;
    snd-msg *escape ('Erreur dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
    return;
  endif;

  // Test de récupération
  clear lId;
  lId.code = lCodeExpected;
  lOK = employee_getByID(lId : lDetail : lErrors);
  
  assert(lOK = *on
    : '<KO> Erreur dans l''appel de employee_getByID');
  assert(lDetail.id.code = lCodeExpected
    : '<KO> Le code de l''employé retourné est différent de celui attendu');
  assert(%len(%trim(lDetail.nom)) > 0
    : '<KO> Le nom de l''employé ne devrait pas être vide');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

dcl-proc test_employee_getByID_notFound export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lId likeDS(employee_id_t) inz;
  dcl-ds lDetail likeDS(employee_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;

  // Test avec un code inexistant
  clear lId;
  lId.code = '999999';
  lOK = employee_getByID(lId : lDetail : lErrors);
  
  assert(lOK = *off
    : '<KO> La procédure devrait retourner *OFF pour un employé inexistant');
  assert(lErrors.listError(1).code = 'EMP001'
    : '<KO> Le code d''erreur devrait être EMP001');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

// Tests pour employee_create
dcl-proc test_employee_create_success export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lDetail likeDS(employee_detail_t) inz;
  dcl-ds lId likeDS(employee_id_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-ds lDetailVerif likeDS(employee_detail_t);

  // Préparation des données
  clear lDetail;
  lDetail.prenom = 'John';
  lDetail.nom = 'DOE';
  lDetail.initiale = 'J';
  lDetail.idService = 'D11';
  lDetail.dateEmbauche = d'2024-01-15';
  lDetail.numeroTelephone = '0123';
  lDetail.dateNaissance = d'1990-05-20';
  lDetail.genre = 'M';
  lDetail.salaire = 50000.00;

  // Test de création
  lOK = employee_create(lDetail : lId : lErrors);
  
  assert(lOK = *on
    : '<KO> Erreur dans la création de l''employé');
  assert(%len(%trim(lId.code)) > 0
    : '<KO> L''ID de l''employé créé ne devrait pas être vide');
  
  // Vérification que l'employé a bien été créé
  clear lErrors;
  lOK = employee_getByID(lId : lDetailVerif : lErrors);
  assert(lOK = *on
    : '<KO> L''employé créé devrait être récupérable');
  assert(lDetailVerif.nom = lDetail.nom
    : '<KO> Le nom de l''employé créé est différent');

  // Nettoyage
  clear lErrors;
  employee_delete(lId : lErrors);

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

// Tests pour employee_update
dcl-proc test_employee_update_success export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lId likeDS(employee_id_t) inz;
  dcl-ds lDetail likeDS(employee_detail_t);
  dcl-ds lDetailUpdated likeDS(employee_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-s lCodeExpected char(6);
  dcl-s lNewSalaire packed(9:2);

  // Récupérer un employé existant
  exec sql
    select empno into :lCodeExpected
    from employee
    where workdept = 'D11'
    fetch first 1 row only;
  if sqlcode <> 0;
    snd-msg *escape ('Erreur dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
    return;
  endif;

  // Récupérer les détails de l'employé
  clear lId;
  lId.code = lCodeExpected;
  lOK = employee_getByID(lId : lDetail : lErrors);
  assert(lOK = *on : '<KO> Impossible de récupérer l''employé');

  // Modifier le salaire
  lNewSalaire = lDetail.salaire + 5000.00;
  lDetail.salaire = lNewSalaire;

  // Test de mise à jour
  clear lErrors;
  lOK = employee_update(lId : lDetail : lErrors);
  assert(lOK = *on
    : '<KO> Erreur dans la mise à jour de l''employé');

  // Vérification de la mise à jour
  clear lErrors;
  lOK = employee_getByID(lId : lDetailUpdated : lErrors);
  assert(lOK = *on : '<KO> Impossible de récupérer l''employé mis à jour');
  assert(lDetailUpdated.salaire = lNewSalaire
    : '<KO> Le salaire n''a pas été mis à jour correctement');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

dcl-proc test_employee_update_notFound export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lId likeDS(employee_id_t) inz;
  dcl-ds lDetail likeDS(employee_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;

  // Test avec un code inexistant
  clear lId;
  lId.code = '999999';
  lDetail.nom = 'TEST';
  lDetail.prenom = 'Test';
  
  lOK = employee_update(lId : lDetail : lErrors);
  
  assert(lOK = *off
    : '<KO> La mise à jour devrait échouer pour un employé inexistant');
  assert(lErrors.listError(1).code = 'EMP001'
    : '<KO> Le code d''erreur devrait être EMP001');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

// Tests pour employee_delete
dcl-proc test_employee_delete_success export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lDetail likeDS(employee_detail_t) inz;
  dcl-ds lId likeDS(employee_id_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-ds lDetailVerif likeDS(employee_detail_t);

  // Créer un employé pour le test
  clear lDetail;
  lDetail.prenom = 'ToDelete';
  lDetail.nom = 'TESTDEL';
  lDetail.initiale = 'T';
  lDetail.idService = 'D11';
  lDetail.numeroTelephone = '0123';  
  lDetail.dateEmbauche = d'2024-01-15';
  lDetail.dateNaissance = d'1990-05-20';
  lDetail.genre = 'M';
  lDetail.salaire = 40000.00;

  lOK = employee_create(lDetail : lId : lErrors);
  assert(lOK = *on : '<KO> Impossible de créer l''employé de test');

  // Test de suppression
  clear lErrors;
  lOK = employee_delete(lId : lErrors);
  assert(lOK = *on
    : '<KO> Erreur dans la suppression de l''employé');

  // Vérification que l'employé a été supprimé
  clear lErrors;
  lOK = employee_getByID(lId : lDetailVerif : lErrors);
  assert(lOK = *off
    : '<KO> L''employé devrait être introuvable après suppression');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

dcl-proc test_employee_delete_notFound export;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-ds lId likeDS(employee_id_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;

  // Test avec un code inexistant
  clear lId;
  lId.code = '999999';
  
  lOK = employee_delete(lId : lErrors);
  
  assert(lOK = *off
    : '<KO> La suppression devrait échouer pour un employé inexistant');
  assert(lErrors.listError(1).code = 'EMP001'
    : '<KO> Le code d''erreur devrait être EMP001');

  on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;
