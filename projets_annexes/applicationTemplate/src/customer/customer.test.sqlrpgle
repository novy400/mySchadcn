**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include qinclude,TESTCASE 
/include '/usr/local/include/customer.rpgleinc'

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
dcl-proc  test_customer_search_firstPage export;
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
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    assert(lCount = lContext.pagination.perPage
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');  
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_lastPage export;
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
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));
    // recherche des clients
    clear lContext;
    lContext.pagination.numPage = lLastPage;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Total items in list : ' + %char(lCount));
    assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_status_active export;
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
    // recherche du nombre total de clients actifs
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer where status = 'active';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'status';
    lContext.filter(1).value = 'active';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
     assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_order_name export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lCount int(10);
    dcl-c PERPAGE 10;
    dcl-ds lItem likeds(customer_item_t) based(lItemPtr);

    // initialisation
    // recherche de l'id a trouvé.
    clear lIdExpected;
    exec sql
      select id 
      into :lIdExpected
      from (
      select id from customer 
        order by name ) limit 1 offset 3;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du tri
    lContext.sort(1).field = 'name';
    lContext.sort(1).order = 'asc';
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    // verification troisième poste de la liste
    lItemPtr = list_get(list : 2);
    CKOOL_logMessage('Customer : ' + %char(lItem.id) + ' - ' + lItem.name);
    assert(lIdExpected = lItem.id
      : '<KO> Erreur dans le tri. Le client trouvé n''est pas celui attendu');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_name_like_TEST export;
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
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer where name like '%TEST%';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    CKOOL_logMessage('Expected Count: ' + %char(lTotalCountExpected));

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'name';
    lContext.filter(1).value = '%TEST%';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
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

dcl-proc test_customer_getByID_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    CKOOL_logMessage('Test avec client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_getByID');
    assert(lDetail.detail.id = lIdExpected
      : '<KO> L''ID du client retourné est différent de celui attendu');
    assert(lDetail.detail.name = lNameExpected
      : '<KO> Le nom du client retourné est différent de celui attendu');
    assert(lDetail.detail.code <> *blanks
      : '<KO> Le code du client devrait être renseigné');
      
    CKOOL_logMessage('Client trouvé : ' + %char(lDetail.detail.id) + ' - ' + 
                     %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
      
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_getByID_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test avec client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
    assert(lDetail.detail.id = 0
      : '<KO> Le détail du client devrait être vide');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_change_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lDetailOriginal likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNewName varchar(80);
    dcl-s lNewCode varchar(10);
    dcl-s lOriginalName varchar(80);
    dcl-s lOriginalCode varchar(10);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lOriginalName;
    clear lOriginalCode;
    exec sql
      select id, name, code
      into :lIdExpected, :lOriginalName, :lOriginalCode
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // récupération du détail original
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetailOriginal : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la récupération du détail original');
        return;
    endif;
    
    CKOOL_logMessage('Test modification client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lOriginalName));
    
    // préparation des nouvelles valeurs
    lNewName = 'TEST_COMPANY';
    lNewCode = 'TSTCMP';
    
    // modification des données
    lDetail = lDetailOriginal;
    lDetail.detail.name = lNewName;
    lDetail.detail.code = lNewCode;
    lDetail.detail.isvip = *on;
    
    // test de la procédure de modification
    lOK = customer_change(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_change');
    
    // vérification que la modification a bien été effectuée
    clear lDetail;
    lOK = customer_getByID(lId : lDetail : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la vérification de la modification');
    assert(lDetail.detail.name = lNewName
      : '<KO> Le nom n''a pas été modifié correctement');
    assert(lDetail.detail.code = lNewCode
      : '<KO> Le code n''a pas été modifié correctement');
    assert(lDetail.detail.isvip = *on
      : '<KO> Le statut VIP n''a pas été modifié correctement');
      
    CKOOL_logMessage('Client modifié avec succès : ' 
                     + %char(lDetail.detail.id) + ' - ' + 
                     %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
    
    // restauration des données originales
    lOK = customer_change(lId : lDetailOriginal : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la restauration des données originales');
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          customer_change(lId : lDetailOriginal : lErrors);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_customer_change_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    // préparation des données à modifier
    clear lDetail;
    lDetail.detail.name = 'TEST_COMPANY';
    lDetail.detail.code = 'TSTCMP';
    lDetail.detail.address.ligne1 = '123 Test Street';
    lDetail.detail.address.ville = 'Test City';
    
    CKOOL_logMessage('Test modification client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_change(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_delete_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lDetailBackup likeds(customer_detail_t) inz;
    dcl-ds lDetailCustomer likeDs(customer_t);
    dcl-ds lAdress likeDs(customer_address_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    dcl-s lVipChar char(1);
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // sauvegarde du détail complet pour restauration
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetailBackup : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la sauvegarde des données originales');
        return;
    endif;
    
    CKOOL_logMessage('Test suppression client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure de suppression
    lOK = customer_delete(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_delete');
    
    // vérification que le client n'existe plus
    clear lDetail;
    clear lErrors;
    lOK = customer_getByID(lId : lDetail : lErrors);
    assert(lOK = *off 
      : '<KO> Le client devrait être supprimé');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
      
    CKOOL_logMessage('Client supprimé avec succès : ' 
                     + %char(lIdExpected));
    
    // restauration des données pour ne pas affecter les autres tests
    clear lDetailCustomer;
    lDetailCustomer = lDetailBackup.detail;
    lAdress = lDetailCustomer.address;
    // Convert RPG indicator *on/*off to database 'O'/'N'
    if lDetailCustomer.isvip = *on;
      lVipChar = 'O';
    else;
      lVipChar = 'N';
    endif;
    exec sql
      INSERT INTO customer (id, code, name, addr_ligne1, addr_ligne2, 
                           addr_codepostal, addr_ville, addr_pays,
                           phone, email, status, creation_date, 
                           credit_limit, is_vip)
      VALUES (:lDetailCustomer.id, :lDetailCustomer.code, 
              :lDetailCustomer.name, :lAdress.ligne1,
              :lAdress.ligne2, :lAdress.codepostal,
              :lAdress.ville, :lAdress.pays,
              :lDetailCustomer.phone, :lDetailCustomer.email,
              :lDetailCustomer.status, :lDetailCustomer.creationdate,
              :lDetailCustomer.creditlimit, :lVipChar);
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la restauration des données : '
                         + %char(sqlcode));
    endif;
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          clear lDetailCustomer;
          lDetailCustomer = lDetailBackup.detail;
          lAdress = lDetailCustomer.address;
          // Convert RPG indicator *on/*off to database 'O'/'N'
          if lDetailCustomer.isvip = *on;
            lVipChar = 'O';
          else;
            lVipChar = 'N';
          endif;
          exec sql
            INSERT INTO customer (id, code, name, addr_ligne1, addr_ligne2, 
                                 addr_codepostal, addr_ville, addr_pays,
                                 phone, email, status, creation_date, 
                                 credit_limit, is_vip)
            VALUES (:lDetailCustomer.id, :lDetailCustomer.code, 
                    :lDetailCustomer.name, :lAdress.ligne1,
                    :lAdress.ligne2, :lAdress.codepostal,
                    :lAdress.ville, :lAdress.pays,
                    :lDetailCustomer.phone, :lDetailCustomer.email,
                    :lDetailCustomer.status, :lDetailCustomer.creationdate,
                    :lDetailCustomer.creditlimit, :lVipChar);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_customer_delete_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test suppression client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_delete(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_valid export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-ds lDetailVerif likeds(customer_detail_t) inz;
    dcl-s lOK ind;
    
    // préparation des données de test
    clear lDetail;
    lDetail.detail.code = 'TST001';
    lDetail.detail.name = 'TEST COMPANY SA';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ligne2 = 'Bâtiment A';
    lDetail.detail.address.codepostal = '75001';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.pays = 'FR';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client : ' 
              + %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
    
    // test de la procédure de création
    lOK = customer_create(lDetail : lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_create');
    assert(lId.id <> 0
      : '<KO> L''ID du client créé ne devrait pas être zéro');
    
    CKOOL_logMessage('Client créé avec l''ID : ' + %char(lId.id));
    
    // vérification que le client a bien été créé
    clear lDetailVerif;
    clear lErrors;
    lOK = customer_getByID(lId : lDetailVerif : lErrors);
    assert(lOK = *on 
      : '<KO> Le client créé devrait être trouvé');
    assert(lDetailVerif.detail.code = lDetail.detail.code
      : '<KO> Le code du client créé ne correspond pas');
    assert(lDetailVerif.detail.name = lDetail.detail.name
      : '<KO> Le nom du client créé ne correspond pas');
    assert(lDetailVerif.detail.address.ville = lDetail.detail.address.ville
      : '<KO> La ville du client créé ne correspond pas');
    assert(lDetailVerif.detail.status = lDetail.detail.status
      : '<KO> Le statut du client créé ne correspond pas');
    assert(lDetailVerif.detail.creditlimit = lDetail.detail.creditlimit
      : '<KO> La limite de crédit du client créé ne correspond pas');
      
    CKOOL_logMessage('Client créé et vérifié avec succès : ' 
                     + %char(lDetailVerif.detail.id) + ' - ' + 
                     %trim(lDetailVerif.detail.code) + ' ' + %trim(lDetailVerif.detail.name));
    
   on-exit ErrorHappened;
      if ErrorHappened;
        // nettoyage : suppression du client créé en cas d'erreur
        if lId.id <> 0;
          monitor;
            customer_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      else;
        // nettoyage : suppression du client créé après test réussi
        if lId.id <> 0;
          monitor;
            customer_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      endif;
end-proc;

dcl-proc test_customer_create_validation_error export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec des données invalides (nom vide)
    clear lDetail;
    lDetail.detail.code = 'TST002';
    lDetail.detail.name = *blanks;  // nom vide - devrait causer une erreur
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec nom vide');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un nom vide');
    assert(lErrors.listError(1).code = 'CUST002'
      : '<KO> Le code d''erreur devrait être CUST002 pour nom obligatoire');
    assert(lErrors.listError(1).textUser = 'Nom obligatoire !'
      : '<KO> Le message d''erreur devrait être "Nom obligatoire !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_invalid_creditlimit export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec une limite de crédit négative
    clear lDetail;
    lDetail.detail.code = 'TST003';
    lDetail.detail.name = 'TEST COMPANY INVALID';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = -1000;  // limite négative - devrait causer une erreur
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec limite de crédit négative');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour une limite de crédit négative');
    assert(lErrors.listError(1).code = 'CUST008'
      : '<KO> Le code d''erreur devrait être CUST008 pour limite de crédit invalide');
    assert(lErrors.listError(1).textUser = 'Limite de crédit doit être positive !'
      : '<KO> Le message d''erreur devrait être "Limite de crédit doit être positive !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_invalid_email export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un email invalide
    clear lDetail;
    lDetail.detail.code = 'TST004';
    lDetail.detail.name = 'TEST COMPANY EMAIL';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'invalid-email';  // email invalide - devrait causer une erreur
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec email invalide');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un email invalide');
    assert(lErrors.listError(1).code = 'CUST007'
      : '<KO> Le code d''erreur devrait être CUST007 pour email invalide');
    assert(lErrors.listError(1).textUser = 'Format email invalide !'
      : '<KO> Le message d''erreur devrait être "Format email invalide !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_display_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    CKOOL_logMessage('Test affichage client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure d'affichage
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_display(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_display');
      
    CKOOL_logMessage('Affichage du client réussi');
      
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_display_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test affichage client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_display(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
      
    CKOOL_logMessage('Erreur d''affichage attendue pour client inexistant');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;
