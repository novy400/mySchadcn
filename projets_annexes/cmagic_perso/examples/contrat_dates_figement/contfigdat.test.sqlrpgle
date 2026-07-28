**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');
/include qinclude,TESTCASE 
/include 'includes/contfigdat.rpgleinc'
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
// _______________________________________________________________________________________
dcl-proc  test_contfigdat_search_firstPage export;
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
      from contfigdat;
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
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
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

dcl-proc  test_contfigdat_search_lastPage export;
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
      from contfigdat;
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
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
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

dcl-proc  test_contfigdat_search_codEtablissement_TOU export;
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
      from contfigdat where codeEtablissement = 'TOU';
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
    // ajout du filtre
    lContext.filter(1).field = 'codeEtablissement';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'TOU';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + lContext.filter(1).operator 
      + lContext.filter(1).value);
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
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

dcl-proc  test_contfigdat_search_order_numeroContrat export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lCodeExpected like(contfigdat_id_t.code);
    dcl-s lCount int(10);
    dcl-c PERPAGE 10;
    dcl-ds lItem likeds(contfigdat_item_t) based(lItemPtr);

    // initialisation
    // recherche de l'id a trouvé.
    clear lCodeExpected;
    exec sql
      select id 
      into :lCodeExpected
      from (
      select id from contfigdat 
        order by numeroContrat ) limit 1 offset 3;
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
    lContext.sort(1).field = 'numeroContrat';
    lContext.sort(1).order = 'asc';
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
    // verification quatriéme  poste de la liste
    lItemPtr = list_get(list : 3);
    CKOOL_logMessage('contfigdat : ' + %char(lItem.id.code) + ' - ' + %char(lItem.numeroContrat));
    assert(lCodeExpected = lItem.id.code
      : '<KO> Erreur dans le tri. Le contrat trouvé n''est pas celui attendu');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list); 
                // bbb
end-proc;

dcl-proc  test_contfigdat_search_nomClient_like_MARTIN export;
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
        from contfigdat fig 
        left join
         contrat ctr
         on fig.codeetablissement = ctr.etacon 
         and fig.numerocontrat = ctr.numcon
        left join
         clients cli
        on cli.etacli = fig.codeetablissement 
        and cli.codcli = ctr.clicon
        left join 
          agences age
        on age.codeta = fig.codeetablissement 
        and age.codage = ctr.agecon 
        where cli.nomcli like '%MARTIN%';
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
    lContext.filter(1).field = 'nomClient';
    lContext.filter(1).operator = 'LIKE';

    lContext.filter(1).value = '%MARTIN%';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre d''employés retourné est différent de celui attendu');
    CKOOL_logMessage('retourné : ' + %char(lTotalCount));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;
dcl-proc  test_contfigdat_search_codeEtablissement_TOU_numeroClient_9760 export;
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
    EXEC sql
      select count(*) into :lTotalCountExpected
        from contfigdat fig 
        left join
         contrat ctr
         on fig.codeetablissement = ctr.etacon 
         and fig.numerocontrat = ctr.numcon
        left join
         clients cli
        on cli.etacli = fig.codeetablissement 
        and cli.codcli = ctr.clicon
        left join 
          agences age
        on age.codeta = fig.codeetablissement 
        and age.codage = ctr.agecon 
        where fig.codeetablissement = 'TOU' 
        and cli.codcli = 9760
        ;
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
    lContext.filter(1).field = 'codeEtablissement';
    lContext.filter(1).operator = '=';
    lContext.filter(1).value = 'TOU';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + lContext.filter(1).operator 
      + lContext.filter(1).value);
    lContext.filter(2).field = 'numeroClient';
    lContext.filter(2).operator = '=';
    lContext.filter(2).value = '9760';
   CKOOL_logMessage('Filtre : ' + lContext.filter(2).field + lContext.filter(2).operator 
      + lContext.filter(2).value);
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
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

dcl-proc  test_contfigdat_search_motif_JUD export;
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
    EXEC sql
      select count(*) into :lTotalCountExpected
        from contfigdav 
        where motif like '%JUD%' 
        ;
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
    // ajout du filtre
    lContext.filter(1).field = 'motif';
    lContext.filter(1).operator = CMAGIC_OP_LIKE;
    lContext.filter(1).value = 'JUD';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + lContext.filter(1).operator 
      + lContext.filter(1).value);
    lOK = contfigdat_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure contfigdat_search');
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





dcl-proc test_contfigdat_getDateFigementContrat_valid export;
  dcl-pi *N; 
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-s lCodeEtablissement like(contfigdat_etablissement_t.code);
  dcl-s lNumeroContrat like(contfigdat_contrat_t.numero);
  dcl-s lDateFigement like(contfigdat_detail_t.dateFigement);
  dcl-s lDateFigementExpected like(contfigdat_detail_t.dateFigement);
  dcl-s lOK ind;

  // initialisation - récupération d'un contrat existant
  clear lCodeEtablissement;
  clear lNumeroContrat;
  clear lDateFigementExpected;
  exec sql
    select codeetablissement, numerocontrat, datefigementcontrat
    into :lCodeEtablissement, :lNumeroContrat, :lDateFigementExpected
    from contrat_date_figement_calcul
    fetch first 1 row only;
  if sqlcode <> 0;
     snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
     return;
  endif;

  // test
  clear lDateFigement;
  lOK = contfigdat_getDateFigementContrat(lCodeEtablissement
                       : lNumeroContrat
                       : lDateFigement);
  
  // assertions
  assert(lOK = *on
    : '<KO> Erreur dans l''appel de contfigdat_getDateFigementContrat');
  assert(lDateFigement = lDateFigementExpected
    : '<KO> La date de figement retournée est différente de celle attendue');
  
   on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

dcl-proc test_contfigdat_getDateFigementContrat_notFound export;
  dcl-pi *N; 
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-s lCodeEtablissement like(contfigdat_etablissement_t.code);
  dcl-s lNumeroContrat like(contfigdat_contrat_t.numero);
  dcl-s lDateFigement like(contfigdat_detail_t.dateFigement);
  dcl-s lOK ind;

  // initialisation - utilisation de valeurs inexistantes
  lCodeEtablissement = 'XXX';
  lNumeroContrat = 999999999;

  // test
  clear lDateFigement;
  lOK = contfigdat_getDateFigementContrat(lCodeEtablissement
                       : lNumeroContrat
                       : lDateFigement);
  
  // assertions
  assert(lOK = *off
    : '<KO> La procédure aurait dû retourner *off pour un contrat inexistant');
  assert(lDateFigement = *loval
    : '<KO> La date de figement aurait dû rester vide');
  
   on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;

dcl-proc test_contfigdat_getDateFigementContrat_emptyParams export;
  dcl-pi *N; 
  end-pi;
  dcl-s ErrorHappened ind;
  dcl-s lCodeEtablissement like(contfigdat_etablissement_t.code);
  dcl-s lNumeroContrat like(contfigdat_contrat_t.numero);
  dcl-s lDateFigement like(contfigdat_detail_t.dateFigement);
  dcl-s lOK ind;

  // initialisation - paramètres vides
  clear lCodeEtablissement;
  lNumeroContrat = 0;

  // test
  clear lDateFigement;
  lOK = contfigdat_getDateFigementContrat(lCodeEtablissement
                       : lNumeroContrat
                       : lDateFigement);
  
  // assertions
  assert(lOK = *off
    : '<KO> La procédure aurait dû retourner *off pour des paramètres vides');
  
   on-exit ErrorHappened;
    if ErrorHappened;
    endif;
end-proc;
