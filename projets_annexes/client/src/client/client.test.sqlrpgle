**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        datfmt(*ISO) timfmt(*ISO)
        bnddir('QC2LE':'CLIENT':'CKOOL':'ILEASTIC');
/include qinclude,TESTCASE 
/include 'includes/client.rpgleinc'
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
    // CRTDUPFILE('CLIENTS':'CLIENTS');
    // OVRDBF('CLIENTS':'CLIENTS');
    // CRTDUPFILE('CLIEADR':'CLIEADR');
    // OVRDBF('CLIEADR':'CLIEADR');
    // CRTDUPFILE('CONTRAT':'CONTRAT');
    // OVRDBF('CONTRAT':'CONTRAT'); 
      exec sql SET OPTION
        COMMIT = *NONE
        , DATFMT = *ISO;
       
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
    // Nettoyage de la table de test
    // DLTFILE('CLIENTS');
end-proc;

// =============================================================================
// Tests de recherche (client_search)
// =============================================================================

dcl-proc test_client_search_firstPage export;
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
    
    // Initialisation - Recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from client_liste
      ;
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des clients');
    endif;
    
    // Recherche des clients - Première page
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    assert(lCount <= lContext.pagination.perPage
      : '<KO> Le nombre de clients d''une page est supérieur à celui attendu');
      
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_firstPage');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_client_search_lastPage export;
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
    
    // Initialisation - Recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from client_liste
      ;
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des clients');
    endif;
    
    // Calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page : ' + %char(lLastPage));
    
    // Recherche des clients - Dernière page
    clear lContext;
    lContext.pagination.numPage = lLastPage;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Total items in list : ' + %char(lCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_lastPage');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_client_etablissement_NAN export;
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
    dcl-s lCodeEtablissement char(3);
    dcl-c PERPAGE 10;
    dcl-s lMessage varchar(100);
    
    // Initialisation - Récupération du premier code client
    clear lCodeEtablissement;
    lCodeEtablissement ='NAN';
    CKOOL_logMessage('Code établissement pour le test : ' + lCodeEtablissement);   
    // Comptage des clients avec ce code (codmet est unique)
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from client_liste
      where CODEETABLISSEMENT = :lCodeEtablissement
      ;
    if sqlcode <> 0;
    ckool_logMessage('SQLCODE : ' + %char(sqlcode));
    ckool_logMessage('SQLSTATE : ' + %char(sqlstate));
    exec sql GET DIAGNOSTICS CONDITION 1 :lMessage = MESSAGE_TEXT;
    ckool_logMessage('MessageErreur : ' + %trim(lMessage));

      fail('Erreur SQL lors du comptage des clients filtrés');
    endif;
    
    CKOOL_logMessage('Expected Count with code établissement=' 
    + %trim(lCodeEtablissement) + ': ' + %char(lTotalCountExpected));
    
    // Recherche des clients avec filtre
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du filtre sur id
    lContext.filter(1).field = 'codeEtablissement';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = lCodeEtablissement;
    
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field 
    + ' ' + lContext.filter(1).operator 
      + ' ' + lContext.filter(1).value);
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search avec filtre');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients filtrés est différent de celui attendu');
    
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Nombre de clients retournés : ' + %char(lCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_filter_codeEtablissement');
      endif;
      list_dispose(list);
end-proc;
dcl-proc test_client_order_by_nom_NAN export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lCodeExpected packed(7:0);
    dcl-ds lItem likeds(client_item_t) based(lItemPtr);
    dcl-s lItemPtr pointer;
    dcl-s lMessage varchar(100);    
    // Initialisation - Recherche du premier client par ordre alphabétique
    clear lCodeExpected;
    exec sql
      select NUMEROCLIENT into :lCodeExpected
      from client_liste 
      where CODEETABLISSEMENT = 'NAN'
      order by nom 
      fetch first 1 row only;      fetch first 1 row only;
    if sqlcode <> 0;
    ckool_logMessage('SQLCODE : ' + %char(sqlcode));
    ckool_logMessage('SQLSTATE : ' + %char(sqlstate));
    exec sql GET DIAGNOSTICS CONDITION 1 :lMessage = MESSAGE_TEXT;
    ckool_logMessage('MessageErreur : ' + %trim(lMessage));

      fail('Erreur SQL lors de la recherche du premier client');
    endif;
    
    CKOOL_logMessage('Code attendu en premier : ' 
         + %char(lCodeExpected));
    
    // Recherche des clients avec tri
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
 // Ajout du filtre sur id
    lContext.filter(1).field = 'codeEtablissement';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'NAN';    
    // Ajout du tri sur nom du client
    lContext.sort(1).field = 'nom';
    lContext.sort(1).order = 'asc';
    
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field 
    + ' = ' + lContext.sort(1).order);
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search avec tri');
    
    // Vérification du premier élément de la liste
    lItemPtr = list_get(list : 0);
    if lItemPtr <> *null;
      CKOOL_logMessage('client : ' + %char(lItem.id.numeroClient) 
      + ' - ' + %trim(lItem.nomClient));
      assert(lCodeExpected = lItem.id.numeroClient
        : '<KO> Le premier client ne correspond pas au tri attendu');
    else;
      fail('La liste est vide');
    endif;
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_order_by_name');
      endif;
      list_dispose(list);
end-proc;
dcl-proc test_client_order_by_nom export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lCodeExpected packed(7:0);
    dcl-ds lItem likeds(client_item_t) based(lItemPtr);
    dcl-s lItemPtr pointer;
    dcl-s lMessage varchar(100);    
    // Initialisation - Recherche du premier client par ordre alphabétique
    clear lCodeExpected;
    exec sql
      select NUMEROCLIENT into :lCodeExpected
      from client_liste order by nom 
      fetch first 1 row only;      fetch first 1 row only;
    if sqlcode <> 0;
    ckool_logMessage('SQLCODE : ' + %char(sqlcode));
    ckool_logMessage('SQLSTATE : ' + %char(sqlstate));
    exec sql GET DIAGNOSTICS CONDITION 1 :lMessage = MESSAGE_TEXT;
    ckool_logMessage('MessageErreur : ' + %trim(lMessage));

      fail('Erreur SQL lors de la recherche du premier client');
    endif;
    
    CKOOL_logMessage('Code attendu en premier : ' 
         + %char(lCodeExpected));
    
    // Recherche des clients avec tri
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du tri sur nom du client
    lContext.sort(1).field = 'nom';
    lContext.sort(1).order = 'asc';
    
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field 
    + ' = ' + lContext.sort(1).order);
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search avec tri');
    
    // Vérification du premier élément de la liste
    lItemPtr = list_get(list : 0);
    if lItemPtr <> *null;
      CKOOL_logMessage('client : ' + %char(lItem.id.numeroClient) 
      + ' - ' + %trim(lItem.nomClient));
      assert(lCodeExpected = lItem.id.numeroClient
        : '<KO> Le premier client ne correspond pas au tri attendu');
    else;
      fail('La liste est vide');
    endif;
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_order_by_name');
      endif;
      list_dispose(list);
end-proc;

dcl-proc test_client_like_nomClient export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    
    // Initialisation - Recherche du nombre de clients (filtre LIKE générique)
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from client_liste
      where upper(nom) like '%AMI%'
      ;
    if sqlcode <> 0;
      fail('Erreur SQL lors du comptage des clients avec LIKE');
    endif;
    
    CKOOL_logMessage('Expected Count with LIKE: ' 
    + %char(lTotalCountExpected));
    
    // Recherche des clients avec filtre LIKE
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    
    // Ajout du filtre LIKE sur nom du client
    lContext.filter(1).field = 'nom';
    lContext.filter(1).operator = 'LIKE';
    lContext.filter(1).value = 'AMI';
    
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' ' + 
      lContext.filter(1).operator + ' ' + lContext.filter(1).value);
    
    lOK = client_search(lContext : lTotalCount : list : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure client_search avec LIKE');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients avec LIKE est différent de celui attendu');
    
    CKOOL_logMessage('Nombre retourné : ' + %char(lTotalCount));
    
    on-exit ErrorHappened;
      if ErrorHappened;
        fail('Exception non gérée dans test_client_search_filter_like_name');
      endif;
      list_dispose(list);
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
