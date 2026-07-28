**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include qinclude,TESTCASE 
/include 'employee.rpgleinc'

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
    dcl-s lCmd like(gCmd);
end-proc;

dcl-proc tearDown export;
    dcl-pi *N; 
    end-pi;

end-proc;

dcl-proc tearDownSuite export;
    dcl-pi *N; 
    end-pi;
end-proc;
// _______________________________________________________________________________________
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
    lContext.filter(1).field = 'workdept';
    lContext.filter(1).value = 'A00';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné est différent de celui attendu');
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
    dcl-ds lItem likeds(employee_item_t) based(lItemPtr);

    // initialisation
    // recherche de l'id a trouvé.
    clear lCodeExpected;
    exec sql
      select empno 
      into :lCodeExpected
      from (
      select empno from employee 
        order by lastname ) limit 1 offset 3;
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
    lContext.sort(1).field = 'lastname';
    lContext.sort(1).order = 'asc';
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    lOK = employee_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_search');
    // verification troisième poste de la liste
    lItemPtr = list_get(list : 2);
    CKOOL_logMessage('Employee : ' + lItem.id.code + ' - ' + lItem.nom);
    assert(lCodeExpected = lItem.id.code
      : '<KO> Erreur dans le tri. L''employé trouvé n''est pas celui attendu');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
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
    lContext.filter(1).field = 'workdept';
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

dcl-proc test_employee_getByID_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lCodeExpected char(6);
    dcl-s lNomExpected varchar(15);
    
    // initialisation - récupération d'un employé existant
    clear lCodeExpected;
    clear lNomExpected;
    exec sql
      select empno, lastname 
      into :lCodeExpected, :lNomExpected
      from employee 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un employé de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    CKOOL_logMessage('Test avec employé : ' 
              + %trim(lCodeExpected) + ' - ' + %trim(lNomExpected));
    
    // test de la procédure
    clear lId;
    lId.code = lCodeExpected;
    lOK = employee_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_getByID');
    assert(lDetail.id.code = lCodeExpected
      : '<KO> L''ID de l''employé retourné est différent de celui attendu');
    assert(lDetail.nom = lNomExpected
      : '<KO> Le nom de l''employé retourné est différent de celui attendu');
    assert(lDetail.prenom <> *blanks
      : '<KO> Le prénom de l''employé devrait être renseigné');
      
    CKOOL_logMessage('Employé trouvé : ' + %trim(lDetail.id.code) + ' - ' + 
                     %trim(lDetail.prenom) + ' ' + %trim(lDetail.nom));
      
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_getByID_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.code = '999999';  // ID qui n'existe pas
    
    CKOOL_logMessage('Test avec employé inexistant : '
                       + %trim(lId.code));
    
    lOK = employee_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un employé inexistant');
    assert(lErrors.listError(1).code = 'EMP001'
      : '<KO> Le code d''erreur devrait être EMP001 pour employé non trouvé');
    assert(lErrors.listError(1).text = 'Employee not found'
      : '<KO> Le message d''erreur devrait être "Employee not found"');
    assert(lDetail.id.code = *blanks
      : '<KO> Le détail de l''employé devrait être vide');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_change_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lDetailOriginal likeds(employee_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lCodeExpected char(6);
    dcl-s lNewLastName varchar(15);
    dcl-s lNewFirstName varchar(12);
    dcl-s lOriginalLastName varchar(15);
    dcl-s lOriginalFirstName varchar(12);
    
    // initialisation - récupération d'un employé existant
    clear lCodeExpected;
    clear lOriginalLastName;
    clear lOriginalFirstName;
    exec sql
      select empno, lastname, firstnme
      into :lCodeExpected, :lOriginalLastName, :lOriginalFirstName
      from employee 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un employé de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // récupération du détail original
    clear lId;
    lId.code = lCodeExpected;
    lOK = employee_getByID(lId : lDetailOriginal : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la récupération du détail original');
        return;
    endif;
    
    CKOOL_logMessage('Test modification employé : ' 
              + %trim(lCodeExpected) + ' - ' + %trim(lOriginalLastName));
    
    // préparation des nouvelles valeurs
    lNewLastName = 'TEST_NOM';
    lNewFirstName = 'TEST_PRENOM';
    
    // modification des données
    lDetail = lDetailOriginal;
    lDetail.nom = lNewLastName;
    lDetail.prenom = lNewFirstName;
    lDetail.initiale = 'T';
    
    // test de la procédure de modification
    lOK = employee_change(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_change');
    
    // vérification que la modification a bien été effectuée
    clear lDetail;
    lOK = employee_getByID(lId : lDetail : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la vérification de la modification');
    assert(lDetail.nom = lNewLastName
      : '<KO> Le nom n''a pas été modifié correctement');
    assert(lDetail.prenom = lNewFirstName
      : '<KO> Le prénom n''a pas été modifié correctement');
    assert(lDetail.initiale = 'T'
      : '<KO> L''initiale n''a pas été modifiée correctement');
      
    CKOOL_logMessage('Employé modifié avec succès : ' 
                     + %trim(lDetail.id.code) + ' - ' + 
                     %trim(lDetail.prenom) + ' ' + %trim(lDetail.nom));
    
    // restauration des données originales
    lOK = employee_change(lId : lDetailOriginal : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la restauration des données originales');
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          employee_change(lId : lDetailOriginal : lErrors);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_employee_change_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.code = '999999';  // ID qui n'existe pas
    
    // préparation des données à modifier
    clear lDetail;
    lDetail.nom = 'TEST_NOM';
    lDetail.prenom = 'TEST_PRENOM';
    lDetail.initiale = 'T';
    lDetail.service = 'A00';
    
    CKOOL_logMessage('Test modification employé inexistant : '
                       + %trim(lId.code));
    
    lOK = employee_change(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un employé inexistant');
    assert(lErrors.listError(1).code = 'EMP001'
      : '<KO> Le code d''erreur devrait être EMP001 pour employé non trouvé');
    assert(lErrors.listError(1).text = 'Employee not found'
      : '<KO> Le message d''erreur devrait être "Employee not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_delete_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lDetailBackup likeds(employee_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lCodeExpected char(6);
    dcl-s lNomExpected varchar(15);
    
    // initialisation - récupération d'un employé existant
    clear lCodeExpected;
    clear lNomExpected;
    exec sql
      select empno, lastname 
      into :lCodeExpected, :lNomExpected
      from employee 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un employé de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // sauvegarde du détail complet pour restauration
    clear lId;
    lId.code = lCodeExpected;
    lOK = employee_getByID(lId : lDetailBackup : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la sauvegarde des données originales');
        return;
    endif;
    
    CKOOL_logMessage('Test suppression employé : ' 
              + %trim(lCodeExpected) + ' - ' + %trim(lNomExpected));
    
    // test de la procédure de suppression
    lOK = employee_delete(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_delete');
    
    // vérification que l'employé n'existe plus
    clear lDetail;
    clear lErrors;
    lOK = employee_getByID(lId : lDetail : lErrors);
    assert(lOK = *off 
      : '<KO> L''employé devrait être supprimé');
    assert(lErrors.listError(1).code = 'EMP001'
      : '<KO> Le code d''erreur devrait être EMP001 pour employé non trouvé');
      
    CKOOL_logMessage('Employé supprimé avec succès : ' 
                     + %trim(lCodeExpected));
    
    // restauration des données pour ne pas affecter les autres tests
    exec sql
      INSERT INTO employee (empno, firstnme, lastname, midinit, workdept, 
                           hiredate, birthdate, sex, salary)
      VALUES (:lId, :lDetailBackup.prenom, 
              :lDetailBackup.nom, :lDetailBackup.initiale, 
              :lDetailBackup.service, :lDetailBackup.dateEmbauche,
              :lDetailBackup.dateNaissance, :lDetailBackup.genre,
              :lDetailBackup.salaire);
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la restauration des données : '
                         + %char(sqlcode));
    endif;
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          exec sql
            INSERT INTO employee (empno, firstnme, lastname, midinit, workdept, 
                                 hiredate, birthdate, sex, salary)
            VALUES (:lId, :lDetailBackup.prenom, 
                    :lDetailBackup.nom, :lDetailBackup.initiale, 
                    :lDetailBackup.service, :lDetailBackup.dateEmbauche,
                    :lDetailBackup.dateNaissance, :lDetailBackup.genre,
                    :lDetailBackup.salaire);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_employee_delete_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.code = '999999';  // ID qui n'existe pas
    
    CKOOL_logMessage('Test suppression employé inexistant : '
                       + %trim(lId.code));
    
    lOK = employee_delete(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un employé inexistant');
    assert(lErrors.listError(1).code = 'EMP001'
      : '<KO> Le code d''erreur devrait être EMP001 pour employé non trouvé');
    assert(lErrors.listError(1).text = 'Employee not found'
      : '<KO> Le message d''erreur devrait être "Employee not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_create_valid export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-ds lDetailVerif likeds(employee_detail_t) inz;
    dcl-s lOK ind;
    
    // préparation des données de test
    clear lDetail;
    lDetail.prenom = 'Jean';
    lDetail.nom = 'DUPONT';
    lDetail.initiale = 'J';
    lDetail.service = 'A00';
    lDetail.dateEmbauche = %date('2023-01-15');
    lDetail.dateNaissance = %date('1990-03-20');
    lDetail.genre = 'M';
    lDetail.salaire = 45000;
    
    CKOOL_logMessage('Test création employé : ' 
              + %trim(lDetail.prenom) + ' ' + %trim(lDetail.nom));
    
    // test de la procédure de création
    lOK = employee_create(lDetail : lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure employee_create');
    assert(lId.code <> *blanks
      : '<KO> L''ID de l''employé créé ne devrait pas être vide');
    assert(%len(%trim(lId.code)) = 6
      : '<KO> L''ID de l''employé devrait faire 6 caractères');
    
    CKOOL_logMessage('Employé créé avec l''ID : ' + %trim(lId.code));
    
    // vérification que l'employé a bien été créé
    clear lDetailVerif;
    clear lErrors;
    lOK = employee_getByID(lId : lDetailVerif : lErrors);
    assert(lOK = *on 
      : '<KO> L''employé créé devrait être trouvé');
    assert(lDetailVerif.prenom = lDetail.prenom
      : '<KO> Le prénom de l''employé créé ne correspond pas');
    assert(lDetailVerif.nom = lDetail.nom
      : '<KO> Le nom de l''employé créé ne correspond pas');
    assert(lDetailVerif.service = lDetail.service
      : '<KO> Le service de l''employé créé ne correspond pas');
    assert(lDetailVerif.genre = lDetail.genre
      : '<KO> Le genre de l''employé créé ne correspond pas');
    assert(lDetailVerif.salaire = lDetail.salaire
      : '<KO> Le salaire de l''employé créé ne correspond pas');
      
    CKOOL_logMessage('Employé créé et vérifié avec succès : ' 
                     + %trim(lDetailVerif.id.code) + ' - ' + 
                     %trim(lDetailVerif.prenom) + ' ' + %trim(lDetailVerif.nom));
    
   on-exit ErrorHappened;
      if ErrorHappened;
        // nettoyage : suppression de l'employé créé en cas d'erreur
        if lId.code <> *blanks;
          monitor;
            employee_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      else;
        // nettoyage : suppression de l'employé créé après test réussi
        if lId.code <> *blanks;
          monitor;
            employee_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      endif;
end-proc;

dcl-proc test_employee_create_validation_error export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec des données invalides (nom vide)
    clear lDetail;
    lDetail.prenom = 'Jean';
    lDetail.nom = *blanks;  // nom vide - devrait causer une erreur
    lDetail.initiale = 'J';
    lDetail.service = 'A00';
    lDetail.dateEmbauche = %date('2023-01-15');
    lDetail.dateNaissance = %date('1990-03-20');
    lDetail.genre = 'M';
    lDetail.salaire = 45000;
    
    CKOOL_logMessage('Test création employé avec nom vide');
    
    // validation des données avant création
    lOK = employee_isValid(employee_listeAction.creation : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un nom vide');
    assert(lErrors.listError(1).code = 'EMP0002'
      : '<KO> Le code d''erreur devrait être EMP0002 pour nom obligatoire');
    assert(lErrors.listError(1).textUser = 'Nom obligatoire !'
      : '<KO> Le message d''erreur devrait être "Nom obligatoire !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_create_invalid_salary export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un salaire négatif
    clear lDetail;
    lDetail.prenom = 'Marie';
    lDetail.nom = 'MARTIN';
    lDetail.initiale = 'M';
    lDetail.service = 'B01';
    lDetail.dateEmbauche = %date('2023-01-15');
    lDetail.dateNaissance = %date('1985-07-10');
    lDetail.genre = 'F';
    lDetail.salaire = -1000;  // salaire négatif - devrait causer une erreur
    
    CKOOL_logMessage('Test création employé avec salaire négatif');
    
    // validation des données avant création
    lOK = employee_isValid(employee_listeAction.creation : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un salaire négatif');
    assert(lErrors.listError(1).code = 'EMP0005'
      : '<KO> Le code d''erreur devrait être EMP0005 pour salaire invalide');
    assert(lErrors.listError(1).textUser = 'Salaire doit être positif !'
      : '<KO> Le message d''erreur devrait être "Salaire doit être positif !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_create_invalid_gender export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un genre invalide
    clear lDetail;
    lDetail.prenom = 'Alex';
    lDetail.nom = 'BERNARD';
    lDetail.initiale = 'A';
    lDetail.service = 'C01';
    lDetail.dateEmbauche = %date('2023-01-15');
    lDetail.dateNaissance = %date('1992-11-05');
    lDetail.genre = 'X';  // genre invalide - devrait causer une erreur
    lDetail.salaire = 38000;
    
    CKOOL_logMessage('Test création employé avec genre invalide');
    
    // validation des données avant création
    lOK = employee_isValid(employee_listeAction.creation : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un genre invalide');
    assert(lErrors.listError(1).code = 'EMP0003'
      : '<KO> Le code d''erreur devrait être EMP0003 pour genre invalide');
    assert(lErrors.listError(1).textUser = 'Genre invalide (M ou F) !'
      : '<KO> Le message d''erreur devrait être "Genre invalide (M ou F) !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_employee_create_invalid_birthdate export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(employee_detail_t) inz;
    dcl-ds lId likeDS(employee_detail_t.id) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec une date de naissance future
    clear lDetail;
    lDetail.prenom = 'Paul';
    lDetail.nom = 'DURAND';
    lDetail.initiale = 'P';
    lDetail.service = 'D21';
    lDetail.dateEmbauche = %date('2023-01-15');
    lDetail.dateNaissance = %date('2030-01-01');  // date future - devrait causer une erreur
    lDetail.genre = 'M';
    lDetail.salaire = 42000;
    
    CKOOL_logMessage('Test création employé avec date de naissance future');
    
    // validation des données avant création
    lOK = employee_isValid(employee_listeAction.creation : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour une date de naissance future');
    assert(lErrors.listError(1).code = 'EMP0006'
      : '<KO> Le code d''erreur devrait être EMP0006 pour date de naissance invalide');
    assert(lErrors.listError(1).textUser = 'Date de naissance invalide !'
      : '<KO> Le message d''erreur devrait être "Date de naissance invalide !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;




