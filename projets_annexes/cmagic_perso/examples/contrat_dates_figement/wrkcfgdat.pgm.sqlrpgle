**free
// =======================================================================================
// \brief Projet CONSO REST with JSON/SQL                                                 
// \author novy                                                                           
// \date                                                                                  
// \warning No warning                                                                    
// ---------------------------------------------------------------------------------------
// \info :                                                                                
//      appelle de l'api rest https://fakerestapi.azurewebsites.net/index.html
//      liste des activités https://fakerestapi.azurewebsites.net/api/v1/Activities
// ---------------------------------------------------------------------------------------
// \info compilation :                                                                    
//      .................................................................................
//      .................................................................................
// ---------------------------------------------------------------------------------------
//                                                                                       
// \rev  dd.mm.ccyy                                                                       
//      .................................................................................
//      .................................................................................
// =======================================================================================
/if defined(*CRTBNDRPG)
ctl-opt dftactgrp(*no)
         actgrp(*new);
/endif                
ctl-opt option(*nodebugio:*srcstmt:*nounref)
        bnddir('QC2LE':'CKOOL')
        main(main);
/include 'contfigdat.rpgleinc'
//  /include QPrtSrc,global
/include 'ckool.rpgleinc'
/include 'llist/llist_h.rpgle'
dcl-f Display   workstn qualified
//*********************************************************************
// TODO: 1.  Indiquer le nom du DSPF.
                extdesc('WRKCFGDAT')
//*********************************************************************
                alias
                extfile(*extdesc) 
                indds(Dspf) 
                infds(fichierDs) 
                sfile(SFL01:SFRRN)
                usropn;
dcl-s SFRRN int(5); 
dcl-s gPosPage int(5);                
dcl-ds Dspf qualified ;
  exit ind pos(3) ;
  invite ind pos(4);
  refresh ind pos(5) ;
  add ind pos(6);
  confirm ind pos(9);
  abort ind pos(12);
  sflDsp ind pos(30);
  sflDspCtl ind pos(31);
  sflClr ind pos(32);
  sflEnd ind pos(33);
  sflNxtChg ind pos(34);
  sflRollup ind pos(35);
  consultationF2 ind pos(38);
  protectCtr ind pos(40);
  protectSF ind pos(39);
  error ind pos(99);
end-ds;
dcl-ds gSFL01_t   likerec(Display.SFL01: *all)    template;
dcl-ds gCTL01_t   likerec(Display.CTL01: *all)    template;
dcl-ds gBASPAGE_t   likerec(Display.BASPAGE: *all)    template;
dcl-ds gFVIDE_t  likerec(Display.FVIDE: *all)   template;
dcl-ds gFMT02_t   likerec(Display.FMT02: *all)    template;
dcl-ds gENT02_t   likerec(Display.ENT02: *all)    template;
dcl-ds gAUDIT_t   likerec(Display.AUDIT: *all)    template;
dcl-ds gCONFIRM_t   likerec(Display.CONFIRM: *all)    template;
dcl-ds fichierDS qualified;
  ligne    INT(3) POS(370); // curseur : ligne
  colonne  INT(3) POS(371); // curseur : colonne
  rang_sfl INT(5) POS(376);
  premier_rang_affiche INT(5) POS(378);
  nbrcd_sfl INT(5) POS(380);
  wlico     INT(5) POS(382); // position curseur, mais dans la fenêtre active
end-ds;
dcl-c C_NB_LIGNE_SOUSFICHIER  16;
dcl-c C_COLOR_BLUE x'3a';
dcl-c C_COLOR_BLUE_RI x'3b';

dcl-ds gFiltreListe qualified;
//*********************************************************************
//TODO: 2.  Ajouter les champs filtres de la liste.
  // champs pour filtrer les items de la liste
  id like(gCTL01_t.id) inz;
  numeroClient like(gCTL01_t.numeroClient) inz;
  nomClient like(gCTL01_t.nomClient) inz;
  numeroContrat like(gCTL01_t.numeroContrat) inz;
  positionContrat like(gCTL01_t.positionContrat) inz;
  dateEcheanceContrat like(gCTL01_t.dateEcheanceContrat) inz;
  montantContrat like(gCTL01_t.montantContrat) inz;
  codeOpposition like(gCTL01_t.codeOpposition) inz;
  dateFigement like(gCTL01_t.dateFigement) inz;
//*********************************************************************
end-ds;
// le filtre t-il été modifié ?
dcl-ds gSaveFiltreListe likeDS(gFiltreListe);
// champs d'entete de l'écran
dcl-ds gEntete qualified;
  $NOMPGM like(gCTL01_t.$NOMPGM) inz;
  ENVIRONMNT like(gCTL01_t.ENVIRONMNT) inz;
  NOMETA like(gCTL01_t.NOMETA) inz;
  NOMAGE like(gCTL01_t.NOMAGE) inz;
  MODE like(gCTL01_t.MODE) inz;
  ACTION like(gENT02_t.ACTION) inz;
//*********************************************************************
// TODO: 3.  Ajouter les champs d'entete de l'écran.
//*********************************************************************

end-ds;
dcl-ds gBasPage qualified;
  TFONCTIONS like(gBASPAGE_t.TFONCTIONS) inz;
//*********************************************************************
// TODO: 4.  Ajouter les champs du bas de page de l'écran.
//*********************************************************************

end-ds;
// dcl-ds gLigneSFL template qualified;
// //*********************************************************************
// //TODO: 5.  Ajouter les champs de la liste.
// // champs pour afficher les items de la liste (sous-fichier)
//   code like(gSFL01_t.code) inz;
//   prenom like(gSFL01_t.prenom) inz;
//   nom like(gSFL01_t.nom) inz;
//   initiale like(gSFL01_t.initiale) inz;
//   service like(gSFL01_t.service) inz;
// //*********************************************************************
// end-ds;
dcl-ds gSflListe template qualified;
  // une page du sous-fichier
  dcl-ds SflItem dim(C_NB_LIGNE_SOUSFICHIER) likeds(gSFL01_t);
end-ds;
//*********************************************************************
// dcl-ds gFMT02_t template qualified;
// //*********************************************************************
// // TODO: 6.  Ajouter les champs de détails de l'entité.
//   code like(gFMT02_t.code) inz;
//   prenom like(gFMT02_t.prenom) inz;
//   nom like(gFMT02_t.nom) inz;
//   initiale like(gFMT02_t.initiale) inz;
//   service like(gFMT02_t.service) inz;
//   datembauch like(gFMT02_t.datembauch) inz;
//   datnaissan like(gFMT02_t.datnaissan) inz;
//   genre like(gFMT02_t.genre) inz;
//   salaire like(gFMT02_t.salaire) inz;
// //*********************************************************************
// end-ds;

dcl-s gInit ind;
dcl-s gFin_Sfl ind;
dcl-s gFin_Pgm ind;
dcl-s gFin_Pgm2 ind;
dcl-s gSflEnd ind;
dcl-ds gIN qualified;
  codEtablissement like(GLOBAL_param_in.codeEtablissement);
  codAgence like(GLOBAL_param_in.codeAgence);
  codeMode like(GLOBAL_param_in.codeMode);
end-ds;
dcl-ds gOut qualified;
  pError likeDS(errorItem);
end-ds;
dcl-ds gContexte likeDS(GLOBAL_contexte) inz; 
dcl-C C_CODE_DROIT 20523; // droit d'accès au module
// pgm principal
dcl-proc  main;
  dcl-pi *N;
  //*********************************************************************
  // TODO: 7.  Ajouter les paramétres éventuels.
  // pIn likeDS(gIN) const;
  // pOut likeDS(gOut);
  // cf inviteEmp.
  //*********************************************************************
    pIn likeDS(gIN) const;
    pOut likeDS(gOut);
  end-pi;
  dcl-ds lError likeDS(errorItem);
  dcl-s ErrorHappened ind ;
  Exec sql
            SET OPTION DATFMT = *ISO, COMMIT = *NONE;
  // initialisation
  clear pOut;

  //*********************************************************************
  // TODO: 8. Facultatif ssi il ya des paramétres en entrée.
  // cf inviteEmp.
  //*********************************************************************
  if not initTrt(pIn);
    clear lError;
    lError.code = 'ERR9999';
    lError.text = 'Erreur inattendue dans le programme.';
    pOut.pError = lError;
    return;
  endif;
  open Display;
  // traitement general
  // initialisation du sous-fichier.
  initSfl();
  // chargement du sous-fichier.
  ChgtSfl();
  Dow not gFin_Pgm;
    affSfl();
  EndDo;
  on-exit ErrorHappened;
    if ErrorHappened;
    clear lError;
    lError.code = 'ERR9999';
    lError.text = 'Erreur inattendue dans le programme.';
    pOut.pError = lError;
      snd-msg *escape ('Horreur ! dans ' +
                 %trim(GLOBAL_Pgm.ProcPgm) + '.' +
                 %trim(GLOBAL_Pgm.Proc));
    else;
      // cKool 
    endif;
    close *all;
    return;

end-proc;

dcl-proc userFeedBack;
  // affichage d'un message utilisateur (fenétre)
  dcl-pi *N;
    pError likeDS(errorItem) Const;
  end-pi;
  CKOOL_displayError(pError);
  return;
end-proc;

dcl-proc initTrt;
  dcl-pi *N ind;
    pIn likeDS(gIN) const;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  // initialisation des variables
  clear lError;
  clear gFiltreListe;
  clear gSaveFiltreListe;
  clear gPosPage;
  clear gContexte;

  // chargement et contrôle du contexte
  eval-corr gContexte = pIn;
  if not getContexte(gContexte:lError);
    userFeedBack(lError);
    gFin_Pgm =*on;
    return *off;
  endif;  

  gFin_Pgm =*off;
  getInfosEntete();
  getInfosBasPage();
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;

dcl-proc getContexte;
  dcl-pi *N ind;
    pContexte likeDS(GLOBAL_contexte);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-s lEnv char(1);
  dcl-ds lContexte likeDS(GLOBAL_contexte);
  dcl-s lOkKo like(GLOBAL_cOkKo) inz('N');
  // initialisation des variables
  clear pError;
  // traitements
  clear lError;
  clear lContexte;
  lContexte = pContexte;
  // utlisateur courant.
  lContexte.codeUtilisateur = GLOBAL_Pgm.User;
  lContexte.codeDroit = C_CODE_DROIT;
  // contrôle du droit d'accès
  reset lOkKo ;
  GLOBAL_aDroit(lContexte.codeDroit
                :lContexte.codeUtilisateur:lOkKo);
  if (lOkKo <> 'O');
    // freed back user non autorisé
    return *off;
  endif;

  // environnement
  clear lEnv;
  GLOBAL_getEnvironnement(lEnv);
  select;
    when (lEnv = GLOBAL_listeEnv.dev);
    // Dev
      lContexte.environnement = GLOBAL_listeEnvironnement.dev;
    when (lEnv = GLOBAL_listeEnv.recette);
    // Test
      lContexte.environnement = GLOBAL_listeEnvironnement.recette;
    when (lEnv = GLOBAL_listeEnv.production);
    // Prod
      lContexte.environnement = GLOBAL_listeEnvironnement.production;
    other;
      lContexte.environnement = *ALL'?';
  endsl;
  // contrôle de l'etablissement.
  if lContexte.codeEtablissement = *blanks;
    // on prend l'établissement du profil utilisateur.
    GLOBAL_getEtablissementUtilisateur(lContexte.codeEtablissement
                                      :lContexte.nomEtablissement);  
  else;
    // on verifie que l'etablissement existe.
    clear lContexte.codeEtablissement;
    GLOBAL_getInfosEtablissement(lContexte.codeEtablissement
                                :lContexte.nomEtablissement
                                :lContexte.lettresEtablissement);
  endif; 

  // contrôle de l'agence.
  if lContexte.codeAgence = *blanks;
    // on prend l'agenceement du profil utilisateur.
    GLOBAL_getAgenceUtilisateur(lContexte.codeEtablissement
                                      :lContexte.codeAgence
                                      :lContexte.nomAgence);
  else;
    // On verifie que l'agence existe.
    if not getInfosAgence(lContexte.codeEtablissement
                         :lContexte.codeAgence
                         :lContexte.nomAgence);
        // erreur agence inconnue
    endif;                                                          
  endif;
  // finalisation 
  pContexte = lContexte;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;

dcl-proc getInfosAgence;
  dcl-pi *N ind;
    pCodeEtablissement like(GLOBAL_contexte.codeEtablissement) const;
    pCodeAgence like(GLOBAL_contexte.codeAgence) const;
    pNomAgence like(GLOBAL_contexte.nomAgence);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-s lNomAgence like(GLOBAL_contexte.nomAgence);
  // initialisation des variables
  clear pNomAgence;

  // traitements
  clear lNomAgence;
  exec sql
    select nomage 
    into :pNomAgence
    from agences 
    where codeta= :pCodeEtablissement and codage = :pCodeAgence; 
    select;
      when  SqlCode < 0;
        clear lError;
        exec sql
          get diagnostics condition 1 :lError.text = MESSAGE_TEXT;
        return *off;
      when  SqlCode = 100;
        return *off;
      other;
    endsl;

  // finalisation
  pNomAgence = lNomAgence;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off; 
    endif;
end-proc;

dcl-proc initSfl;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lCTL01 likeDs(gCTL01_t) inz;
  // initialisation des variables
  clear lError;
  clear lCTL01;
  // Clear du sous fichier.
  clear SFRRN;
  Dspf.sflEnd = *on;
  Dspf.sflClr = *on;
  Dspf.sflDsp = *off;
  Dspf.sflDspctl = *off;
  Dspf.protectSF = *off;
  Write Display.CTL01 lCTL01;
  Dspf.sflClr = *off;
  Dspf.sflDspctl = *on;
  gInit = *on;
  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;
end-proc;

dcl-proc ChgtSfl;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lListeSFL likeDs(gSflListe) inz;
  dcl-s lItem like(SFRRN);
  dcl-s lNbLigneSFL like(SFRRN);
  dcl-ds lSFL01 likeDs(gSFL01_t) inz;
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;
  dcl-ds lFVide likeDs(gFVIDE_t) inz;
  dcl-s lFirst ind;
  // Initialisation des variables
  clear lError;
  Dspf.SflDsp   = *on;
  clear lNbLigneSFL;
  clear lSFL01;
  clear lBasPage;
  eval-corr lBasPage = gBasPage;
  clear lFVide;
  // Positionnement saisi ?
  If gFiltreListe <> gSaveFiltreListe
       and not Dspf.sflRollup;
    // on recharge la liste cad le curseur
    gInit = *on;
  Endif ;
  // chargement de la liste
  clear lListeSFL;
  gFin_Sfl = getListeSousFichier(gFiltreListe:gInit:lListeSFL);

  clear lItem;
  lItem = 1;
  SFRRN = fichierDS.nbrcd_sfl;
  lFirst = *on;
  Dow lNbLigneSFL < C_NB_LIGNE_SOUSFICHIER and
        lListeSFL.SflItem(lItem).id <> *zeros;
    SFRRN += 1;
    if lFirst;
      gPosPage = SFRRN;
      lFirst = *off;
    endif;
    lNbLigneSFL += 1;

    lSFL01.CHOIX    = *blanks;
    clear lSFL01;
    eval-corr lSFL01 = lListeSFL.SflItem(lItem);
    lItem += 1;

    Write Display.SFL01 lSFL01;
  EndDo;

  If lNbLigneSFL < C_NB_LIGNE_SOUSFICHIER;
    gFin_Sfl = *on;
  EndIf;
  // est ce qu'il y a des enregistrements ?
  Select;
    When fichierDS.nbrcd_sfl > *zeros and gFin_Sfl = *on;
      Dspf.sflEnd = *on;
    When fichierDS.nbrcd_sfl = *zeros;
      Dspf.sflDsp = *off;
      Write Display.BAsPage lBasPage;
      Write Display.Fvide lFVide;
    Other;
      Dspf.sflEnd = *off;
  EndSl;

  gInit = *off;

  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;
dcl-proc affSfl;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;
  dcl-ds lCTL01 likeDs(gCTL01_t) inz;
  dcl-ds lDetailEntity likeDs(contfigdat_detail_t) inz; 


  // Initialisation des variables
  clear lError;
  clear lBasPage;
  eval-corr lBasPage = gBasPage;
  clear lCTL01;
  eval-corr lCTL01 = gFiltreListe;
  eval-corr lCTL01 = gEntete;

  //est ce qu'il y a des enregistrements ?
  if fichierDS.nbrcd_sfl > *zeros;
    lCTL01.POSPAGE = gPosPage;
  endif;
  // Affichage de l'écran
  Write Display.BasPage lBasPage;
  ExFmt Display.CTL01 lCTL01;

  Select;
      // F3=Fin
    When Dspf.exit;
      gFin_Pgm = *on;

      // F05=Rafraichir
    When Dspf.refresh;
      clear gFiltreListe;
      clear gSaveFiltreListe;
      initSfl();
      ChgtSfl();

      // F6=Créer
    When Dspf.add;
      gFin_Pgm    = *off;
      clear lDetailEntity;
      if creation(lDetailEntity);
          // TODO: on recharge le sfl à partir de ?????.
        gFiltreListe.id = lDetailEntity.id.code;
        initSfl();
        ChgtSfl();
      endif;

      // F12=Annuler
    When Dspf.abort;
      gFin_Pgm = *on;

      // Rollup=pagination
    When Dspf.sflRollup;
      ChgtSfl();

      // Other
    Other;
      Dspf.error = *off;
      If Dspf.sflDsp;
        lectSfl();
      Endif;

      // Positionnement ?
      eval-corr gFiltreListe = lCTL01;     
      If gFiltreListe <> gSaveFiltreListe;
        initSfl();
        ChgtSfl();
      EndIf;

  EndSl;
  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;

dcl-proc lectSfl;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lSFL01 likeDs(gSFL01_t) inz;

  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-ds lDetailEntity likeDs(contfigdat_detail_t) inz; 
  dcl-ds lIdEntity likeDs(contfigdat_detail_t.id) inz;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t) inz;
  dcl-s  lProtect ind;
  // Initialisation
  clear lError;
  clear lSFL01;
  clear lDetailEntity;
  clear lIdEntity;
  // Traitement
  Readc Display.SFL01 lSFL01;
  Dow not %eof();
    // on a lu un enregistrement du sous-fichier.
    gPosPage = fichierDS.rang_sfl;
    // on charge l'id.
    clear lDetailSql;
    eval-corr lDetailSql = lSFL01;
    clear lDetailEntity;
    sqlToEntity(lDetailSql:lDetailEntity);
    clear lIdEntity;
    lIdEntity = lDetailEntity.id;
    lProtect = *off;
    Select;
        // 2 = Modifier
        // -----------------------
      When lSFL01.CHOIX    = '2';
        gFin_Pgm    = *off;
        clear lDetailEntity;
        if modification(lIdEntity:lDetailEntity);
          // on recharge les zones modifiées.
          clear lDetailSql;
          entityToSql(lDetailEntity : lDetailSql);
          eval-corr lSFL01 = lDetailSql;
        endif;
        dspf.error = *off;
        // 4 = Supprimer
        // -----------------------
      When lSFL01.CHOIX    = '4';
        gFin_Pgm    = *off;
        clear lDetailEntity;
        if suppression(lIdEntity:lDetailEntity);
          // on recharge les zones modifiées.
          clear lDetailSql;
          entityToSql(lDetailEntity : lDetailSql);
          eval-corr lSFL01 = lDetailSql;
          lProtect = *on;
        endif;

        //             Suppression(SFL96ID);
        // 5 = Consulter
        // -----------------------
      When lSFL01.CHOIX    = '5';
        consultation(lIdEntity);
    EndSl;
    clear lSFL01.CHOIX;
    Dspf.sflNxtChg = *on;
    Dspf.protectSF = *off;
    if lProtect;
      Dspf.protectSF = *on;
    endif;
    Update Display.SFL01 lSFL01;
    Readc Display.SFL01  lSFL01;
  EndDo;

  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;


dcl-proc consultation;
  dcl-pi *N;
    pId likeDS(contfigdat_detail_t.id);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetail likeds(contfigdat_detail_t);
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-ds lENT02 likeDs(gENT02_t) inz; 
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;

  // Initialisation
  clear lError;
  Dspf.consultationF2 = *on;
  Dspf.protectCtr = *on;
  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lENT02;
  gEntete.ACTION = GLOBAL_listeMode.consultation;
  eval-corr lENT02 = gEntete;
  write Display.ENT02 lENT02;

  clear lBasPage;
  lBasPage.TfonctionS =
               'F3=Sortie  F12=Retour    ';
  write Display.BASPAGE lBasPage;

  clear lFMT02;
  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lBasPage.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;
  // Chargement de l'écran de consultation.
  clear lDetailSql;
  entityToSql(lDetail : lDetailSql);
  eval-corr lFMT02 = lDetailSql;
  // Consultation
  Dow 1=1; 
    Exfmt Display.FMT02 lFMT02;
    // Exfmt F2 f2DS;

    select;
      when Dspf.exit;
        gFin_Pgm = *on;
        return;
      when Dspf.abort;
        gFin_Pgm = *off;
        return;
    Endsl;
  Enddo;
  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;


dcl-proc modification;
  dcl-pi *N ind;
    pId likeDS(contfigdat_detail_t.id) const;
    pDetail likeDs(contfigdat_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lDetail likeDs(contfigdat_detail_t) inz;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-ds lENT02 likeDs(gENT02_t) inz; 
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;

  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.consultationF2 = *off;
  Dspf.protectCtr = *on;

  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lENT02;
  gEntete.ACTION = GLOBAL_listeMode.MODIFICATION;
  eval-corr lENT02 = gEntete;
  write Display.ENT02 lENT02;

  clear lBasPage;
  lBasPage.TfonctionS =
                 'F3=Sortie '+ C_COLOR_BLUE_RI+'F9=VALIDER'+ C_COLOR_BLUE + '       '
                    + '                F12=Retour ' ;

  clear lFMT02;
  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lBasPage.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;  
  // Chargement de l'écran de modification. 
  clear lDetailSql;
  entityToSql(lDetail : lDetailSql);
  eval-corr lFMT02 = lDetailSql;
  // Consultation
  Dow 1=1; 

    write Display.BASPAGE lBasPage;
    Exfmt Display.FMT02 lFMT02;
    select;
      when Dspf.invite;
        invite(lFMT02);
      when Dspf.exit;
        gFin_Pgm = *on;
        return *off;
      when Dspf.abort;
        gFin_Pgm = *off;
        return *off;
        // Validation Modification
      When Dspf.confirm;
        // controle des infos.
        dspf.error = *off;
        clear lError;
        if not isValidSaisieDetail(gEntete.ACTION
                                  :lFMT02:lError);
          lBasPage.WMSG = lError.code;                        
          Dspf.error = *on;
          iter;
        endif;
        // Demande de confirmation  ?
        if isConfirm();
          // mise à jour.
          clear lDetail;
          eval-corr lDetailSql = lFMT02;
          sqlToEntity(lDetailSql:lDetail);
          clear lError;
          if not modifieEntity(pId:lDetail:lError);
            // erreur de modification.
            // on affiche les erreurs.
          lBasPage.WMSG = 'STD0004';
          Dspf.error = *on;
          iter;
          endif;
          pDetail = lDetail;
          // retour ecran precedent.
          return *on;
        endif;
      other;
        // controle des infos.
        dspf.error = *off;
        clear lError;
        if not isValidSaisieDetail(gEntete.ACTION:lFMT02:lError);
          Dspf.error = *on;
          lBasPage.WMSG = lError.code;                        
          iter;
        endif;
    Endsl;
  Enddo;
  return *off;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;

dcl-proc suppression;
  dcl-pi *N ind;
    pId likeDS(contfigdat_detail_t.id) const;
    pDetail likeDs(contfigdat_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetail likeDs(contfigdat_detail_t) inz;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-ds lENT02 likeDs(gENT02_t) inz; 
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;

  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.consultationF2 = *on;
  Dspf.protectCtr = *on;
  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lENT02;
  gEntete.ACTION = GLOBAL_listeMode.SUPPRESSION;
  eval-corr lENT02 = gEntete;
  write Display.ENT02 lENT02;

  clear lBasPage;
  lBasPage.TfonctionS =
                 'F3=Sortie '+ C_COLOR_BLUE_RI+'F9=VALIDER'+ C_COLOR_BLUE + '       '
                    + '                F12=Retour ' ;

  clear lFMT02;
  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lBasPage.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;  
  // Chargement de l'écran de modification. 
  clear lDetailSql;
  entityToSql(lDetail : lDetailSql);
  eval-corr lFMT02 = lDetailSql;
  // Consultation
  Dow 1=1; 
    write Display.BASPAGE lBasPage;
    Exfmt Display.FMT02 lFMT02;
    select;
      when Dspf.exit;
        gFin_Pgm = *on;
        return *off;
      when Dspf.abort;
        gFin_Pgm = *off;
        return *off;
        // Validation Modification
      When Dspf.confirm And not dspf.error;
        // controle des infos.
        clear lError;
        Dspf.error = *off;
        // Demande de confirmation  ?
        if isConfirm();
          // mise à jour.
          clear lDetail;
          eval-corr lDetailSql = lFMT02;
          sqlToEntity(lDetailSql:lDetail);
          clear lError;
          if not supprimeEntity(pId:lDetail:lError);
            // erreur de suppression.
            // on affiche les erreurs.
          lBasPage.WMSG = 'STD0004';
          Dspf.error = *on;
          iter;
          endif;
          // retour ecran precedent.
          lDetail.client.nom = '-- Supprimé --';
          return *on;
        endif;
    Endsl;
  Enddo;
  return *off;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;


dcl-proc creation;
  dcl-pi *N ind;
    pDetail likeDs(contfigdat_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lDetail likeDs(contfigdat_detail_t) inz;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-ds lENT02 likeDs(gENT02_t) inz; 
  dcl-ds lBasPage likeDs(gBASPAGE_t) inz;
  dcl-ds lId likeDS(contfigdat_detail_t.id);

  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.consultationF2 = *off;
  Dspf.protectCtr = *off;

  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lENT02;
  gEntete.ACTION = GLOBAL_listeMode.CREATION;
  eval-corr lENT02 = gEntete;
  write Display.ENT02 lENT02;

  clear lBasPage;
  lBasPage.TfonctionS =
                 'F3=Sortie '+ C_COLOR_BLUE_RI+'F9=VALIDER'+ C_COLOR_BLUE + '       '
                    + '                F12=Retour ' ;

  clear lFMT02;
  clear lDetail;
  // Chargement de l'écran de creation. 
  clear lDetailSql;
  eval-corr lFMT02 = lDetailSql;
  // Consultation
  Dow 1=1; 
    write Display.BASPAGE lBasPage;
    Exfmt Display.FMT02 lFMT02;
    select;
      when Dspf.invite;
        invite(lFMT02);
      when Dspf.exit;
        gFin_Pgm = *on;
        return *off;
      when Dspf.abort;
        gFin_Pgm = *off;
        return *off;
        // Validation Modification
      When Dspf.confirm;
        // controle des infos.
        dspf.error = *off;
        clear lError;
        if not isValidSaisieDetail(gEntete.ACTION:lFMT02:lError);
          lBasPage.WMSG = lError.code;
          Dspf.error = *on;
          iter;
        endif;
        // Demande de confirmation  ?
        if isConfirm();
          // mise à jour.
          clear lDetail;
          eval-corr lDetailSql = lFMT02;
          eval-corr lDetailSql = gContexte;
          sqlToEntity(lDetailSql:lDetail);
          clear lId;
          clear lError;
          if not creeEntity(lDetail:lId:lError);
            // erreur de création.
            // on affiche les erreurs.
          lBasPage.WMSG = 'STD0004';
          Dspf.error = *on;
          iter;
          endif;
          lDetail.id = lId;
          pDetail = lDetail;
          // retour ecran precedent.
          return *on;
        endif;
      other;
        // controle des infos.
        dspf.error = *off;
        clear lError; 
        if not isValidSaisieDetail(gEntete.ACTION:lFMT02:lError);
          lBasPage.WMSG = lError.code;
          Dspf.error = *on;
          iter;
        endif;
    Endsl;
  Enddo;
  return *off;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;


dcl-proc isValidSaisieDetail;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) const;
    pFMT02 likeDs(gFMT02_t);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetailSQL likeDs(contfigdat_detail_sql_t) inz;
  dcl-ds lDetail likeDs(contfigdat_detail_t) inz;
  dcl-ds lDetailEntity likeDs(contfigdat_detail_t) inz;

  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  // initialisation
  clear pError;
  lFMT02 = pFMT02;
  // traitement 
  clear lDetail;
  eval-corr lDetailSQL = lFMT02;
  eval-corr lDetailSQL = gContexte;
  sqlToEntity(lDetailSQL:lDetail);
  
  // initialisation des champs  contrat.
  clear lError;
  clear lDetailEntity;
  if not contfigdat_initDetailEntity(
                      lDetail.etablissement.code
                      :lDetail.client.numero
                      :lDetail.contrat.numero
                      :lDetailEntity
                      :lError);
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
    pFMT02 = lFMT02;
    pError = lError;
    return *off;
  endif;
  if lDetailEntity <> lDetail;
    lDetail.etablissement = lDetailEntity.etablissement;
    lDetail.client = lDetailEntity.client;
    lDetail.contrat = lDetailEntity.contrat; 
    lDetail.opposition = lDetailEntity.opposition; 
    clear lDetailSql;
    entityToSql(lDetail: lDetailSql);
    eval-corr lFMT02 = lDetailSql;
    lFmt02.dateFigement = pFmt02.dateFigement;
    lFmt02.motifFigement = pFmt02.motifFigement;  
    pFMT02 = lFMT02;
  endif;  
  // controle de l'entité.  
  clear lErrors;
  if not isValidEntity(pAction:lDetail:lErrors);
    clear lError;
    lError = lErrors.listError(1);
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
    pFMT02 = lFMT02;
    pError = lError;
    return *off;        
  endif;

  // finalisation 
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;

end-proc;

dcl-proc invite;
  dcl-pi *N;
    pFmt02 likeDS(gFMT02_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-s lCodeEtablissement like(GLOBAL_contexte.codeEtablissement);
  dcl-s lCodeAgence like(GLOBAL_contexte.codeAgence); 
  dcl-s lNumeroClient packed(7:0);  
  dcl-s lNumeroContrat packed(9:0);
  dcl-s lMdus char(11);
  dcl-s lPose1 char(3);
  dcl-s lPose2 char(3);
  dcl-s lPose3 char(3);
  dcl-s lPose4 char(3);
  dcl-s lPose5 char(3);  
  dcl-ds lDetailEntity likeDs(contfigdat_detail_t) inz;
  dcl-ds lDetailSQL likeDs(contfigdat_detail_sql_t) inz;
  dcl-ds lFmt02 likeDS(gFMT02_t);
  dcl-ds lDetail likeDs(contfigdat_detail_t) inz;

  // dcl-ds lSearchClientIN likeDS(GLOBAL_searchClientIn) inz;
  // dcl-ds lSearchClientOUT likeDS(GLOBAL_searchClientOut) inz;

  //*********************************************************************
  // TODO: 9. definir prototype et parametres de chaque programme d'invite 
  // dcl-s lCodeDepartement like(gFMT02_t.service);
  // dcl-s lNumerorEmploye like(gFMT02_t.code);
  // dcl-pr getEmploye extpgm('INVEMP');
  //   pCodeDepartement like(gFMT02_t.service);
  //   pNumerorEmploye like(gFMT02_t.code);
  // end-pr;
  //*********************************************************************
  clear lError;
  select;
  //*********************************************************************
  // TODO: 9. definir appel du programme d'invite en fonction de la zone  
  // du formaulaire
    // when pFmt02.rec= 'FMT02' and pFmt02.fld ='CODCLI';
    //   clear lSearchClientIN;
    //   lSearchClientIN.codeEtablissement = gContexte.codeEtablissement;
    //   clear lSearchClientOUT;  
    //   GLOBAL_searchClient(lSearchClientIN:lSearchClientOUT);
    //   if lSearchClientOUT.numeroClient <> *zeros;
    //      pFmt02.numeroClient = lSearchClientOUT.numeroClient;
    //   endif;

    when pFmt02.rec= 'FMT02' and pFmt02.fld ='NUMCON';
      clear lCodeEtablissement;
      lCodeEtablissement = gContexte.codeEtablissement;
      clear lCodeAgence;  
      lCodeAgence = gContexte.codeAgence;
      clear lNumeroClient;
      lNumeroClient = pFmt02.numeroClient;
      clear lNumeroContrat;
      clear lMdus;
      clear lPose1;
      clear lPose2;
      clear lPose3;
      clear lPose4;
      clear lPose5;
      GLOBAL_searchContrat(lCodeEtablissement:lCodeAgence
      :lNumeroClient:lNumeroContrat:lMdus:lPose1:lPose2:lPose3:lPose4:lPose5);
      if lNumeroContrat <> 0;
        pFmt02.numeroContrat = lNumeroContrat;
        pFmt02.numeroClient = lNumeroClient;
      endif;
      clear lDetailEntity;
      clear lError;
      if not contfigdat_initDetailEntity(
                          lCodeEtablissement
                          :lNumeroClient
                          :lNumeroContrat
                          :lDetailEntity
                          :lError);
        getPositionZone('FMT02':lError.nomZone
                :pFMT02.row:pFMT02.col);
        return;
      endif;
      clear lDetail;
      eval-corr lDetailSQL = pFMT02;
      eval-corr lDetailSQL = gContexte;
      sqlToEntity(lDetailSQL:lDetail);
      clear lDetailSql;
      clear lFmt02;
      lDetail.etablissement = lDetailEntity.etablissement;
      lDetail.client = lDetailEntity.client;
      lDetail.contrat = lDetailEntity.contrat; 
      lDetail.opposition = lDetailEntity.opposition; 
      entityToSql(lDetail : lDetailSql);
      eval-corr lFMT02 = lDetailSql;
      pFmt02 = lFmt02;
      // clear lCodeDepartement;
      // clear lNumerorEmploye;
      // getEmploye(lCodeDepartement:lNumerorEmploye);
      // if lNumerorEmploye <> *blanks;
      //   pFmt02.nom = lNumerorEmploye;
      // endif;
  //*********************************************************************
    other;
  endsl;  
  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;

dcl-proc modifieEntity;
  dcl-pi *N ind;
    pId likeDS(contfigdat_detail_t.id) const;
    pDetail likeDs(contfigdat_detail_t);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  // initialisation
  clear pError;
  clear pDetail;

  // traitement
  clear lError;
  clear lErrors;
  
  // Use contfigdat_update procedure instead of direct SQL
  if not contfigdat_update(pId : pDetail : lErrors);
    CKOOL_displayListError(lErrors);
    pError = lErrors.listError(1);
    return *off;
  endif;  

  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off;
    endif;

end-proc;

dcl-proc supprimeEntity;
  dcl-pi *N ind;
    pId likeDS(contfigdat_detail_t.id) const;
    pDetail likeDs(contfigdat_detail_t);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  // initialisation
  clear pError;
  clear pDetail;
  
  // traitement
  clear lError;
  clear lErrors;
  
  // Use contfigdat_delete procedure instead of direct SQL
  if not contfigdat_delete(pId : lErrors);
    CKOOL_displayListError(lErrors);
    pError = lErrors.listError(1);
    return *off;
  endif;

  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;

dcl-proc creeEntity;
  dcl-pi *N ind;
    pDetail likeDs(contfigdat_detail_t) const;
    pId likeDS(contfigdat_detail_t.id);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-ds lId likeDS(contfigdat_detail_t.id);
  // initialisation
  clear pId;
  clear pError;

  // traitement
  clear lError;
  clear lErrors;
    // Use contfigdat_update procedure instead of direct SQL
  clear lId;
  if not contfigdat_create(pDetail :lId :lErrors);
    CKOOL_displayListError(lErrors);
    pError = lErrors.listError(1);
    return *off;
  endif;  
  pId = lId;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off;
    endif;

end-proc; 

dcl-proc isValidEntity;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) const;
    pDetail likeDs(contfigdat_detail_t) const;
    pErrors likeDS(GLOBAL_listError); 
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lBefore likeDs(contfigdat_detail_t) inz;
  
  clear pErrors;
  clear lErrors;
  
  // Use contfigdat_isValid for validation
  clear lBefore;
  if contfigdat_isValid(pAction :lBefore :pDetail 
                  : lErrors);
    clear pErrors;
    return *on;
  else;
    CKOOL_displayListError(lErrors);
    pErrors = lErrors;
    return *off;
  endif;    
  
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;
end-proc;



dcl-proc isConfirm;
  dcl-pi *N ind;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);

  clear lError;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    endif;

end-proc;

dcl-proc chargementDetailEntity;
  dcl-pi *N;
    pId likeDS(contfigdat_detail_t.id) const;
    pDetail likeDs(contfigdat_detail_t);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lId likeDS(contfigdat_detail_t.id) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lDetail likeds(contfigdat_detail_t) inz;
  // Initialisation
  clear pError;
  clear pDetail;
  // traitement 
  clear lId;
  clear lErrors;
  clear lDetail;
  lId = pId;
  if not contfigdat_getByID(lId : lDetail : lErrors);
    CKOOL_displayListError(lErrors);
    pError.code = 'DFN0137';
    pError.text = 'Erreur dans le chargement de l''''entité.';
    pError.nomZone = 'EMPLOYE';
    Dspf.error = *on;
    return;
  endif;
  // chargement de l'entité 
  clear pDetail;
  pDetail= lDetail;

  return;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return; 
    endif;

end-proc;
dcl-proc getListeSousFichier;
  dcl-pi *N ind;
    pFiltreListe likeds(gFiltreListe) const;
    isInit like(gInit) const;
    pListe likeDs(gSflListe);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lList pointer;
  dcl-ds lItemEntity likeds(contfigdat_item_t) based(lItemPtr);
  dcl-ds lItemDspf likeDs(gSFL01_t) inz;
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lIt int(5);
  dcl-s lNextPage int(5);
  // initialisation
  clear pListe;
  clear lErrors;
  clear lContext;
  lContext.pagination.perPage = C_NB_LIGNE_SOUSFICHIER;
  // ajout du filtre
  getFiltreContext(pFiltreListe:lContext);

  // attention à calculer ....page suivante....
  clear lNextPage;
  lNextPage = %div(fichierDS.nbrcd_sfl : C_NB_LIGNE_SOUSFICHIER) + 1;
  lContext.pagination.numPage = lNextPage;

  // Traitement
  clear lErrors;
  clear lList;
  clear lTotalCount;
  if not  contfigdat_search(lContext : lTotalCount : lList : lErrors);
    CKOOL_displayListError(lErrors);
  endif;
  // chargement de la liste
  clear lIt;
  clear pListe;
  dow (1 <> 0);
    lItemPtr = list_iterate(lList);
    if lItemPtr = *null;
      leave;
    endif;
    lIt += 1;
    if lIt > C_NB_LIGNE_SOUSFICHIER;
      leave;
    endif;
    // on charge l'item dans le sous-fichier
    clear lItemDspf;
    eval-corr lItemDspf = lItemEntity;
    lItemDspf.id = lItemEntity.id.code;
    eval-corr pListe.SflItem(lIt) = lItemDspf;
  enddo;
  // Finalisation
  Return *off;

  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *on; 
    endif;
end-proc; 


dcl-proc entityToSql;
  dcl-pi *n ;
    pDetailEntity likeds(contfigdat_detail_t) const;
    pDetailSql likeDS(contfigdat_detail_sql_t);
  end-pi;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t);
  clear pDetailSql;
  clear lDetailSql;
  lDetailSql = pDetailEntity;
  eval-corr pDetailSql = lDetailSql;  // Automatique si noms identiques
end-proc;

dcl-proc sqlToEntity;
  dcl-pi *n ;
    pDetailSql likeDS(contfigdat_detail_sql_t) const;
    pDetailEntity likeds(contfigdat_detail_t);
  end-pi;
  dcl-ds lDetailSql likeDS(contfigdat_detail_sql_t);
  clear pDetailEntity;
  clear lDetailSql;
  eval-corr lDetailSql = pDetailSql;  // Automatique si noms identiques
  pDetailEntity = lDetailSql;

end-proc;

dcl-proc getInfosEntete;
  dcl-pi *n ;
  end-pi;
  clear gEntete;  
  gEntete.$NOMPGM = %trim(GLOBAL_Pgm.ProcPgm);
  gEntete.ENVIRONMNT = gContexte.environnement;
  gEntete.NOMETA = gContexte.nomEtablissement;
  gEntete.NOMAGE = gContexte.nomAgence;
  gEntete.MODE = gContexte.codeMode; 
  gEntete.ACTION = gContexte.codeAction;
    //*********************************************************************
    // TODO: 9. Renseigner les champs de  l'entete. CTL01 et FMT02
    //*********************************************************************
end-proc;

dcl-proc getInfosBasPage;
  dcl-pi *n ;
  end-pi;
  clear gBasPage;
  gBasPage.TFONCTIONS = 'F3=Sortie F5=Réafficher F6=Ajouter              '+
              '   F12=Retour ' ;
    //*********************************************************************
    // TODO: 10. Renseigner les champs du Bas de Page. BASPAGE
    //*********************************************************************
end-proc;

dcl-proc getPositionZone;
  dcl-pi *n ;
    pFormat char(10) const;
    pNomZone like(errorItem.nomZone) const;
    pligne like(gFMT02_t.row);
    pcolonne like(gFMT02_t.col);
  end-pi;
  clear pligne;
  clear pcolonne; 
  select;
    //*********************************************************************
    // TODO: 1.  positionner ligne et colonne des champs du formulaire.
    When pNomZone ='contrat';
      pligne = 11;
      pcolonne = 10;
    When pNomZone ='dateFigement';
      pligne = 15;
      pcolonne = 16;
    //*********************************************************************
    other;
  endsl;
  return ;
end-proc;


dcl-proc getFiltreContext;
  dcl-pi *n ;
    pFiltreListe likeds(gFiltreListe) const;
    pContexte likeDS(CMAGIC_context);
  end-pi;
  dcl-ds lContexte likeDS(CMAGIC_context);
  dcl-s lIt int(5);
  // initialisation
  clear lContexte;
  lContexte = pContexte;
  clear lIt;
  // traitement
  // code etablissement
  lIt += 1;
  lContexte.filter(lIt).field = 'codeEtablissement';
  lContexte.filter(lIt).operator = CMAGIC_OP_EQUAL;
  lContexte.filter(lIt).value = gContexte.codeEtablissement;
  lContexte.sort(lIt).field = lContexte.filter(lIt).field;
  lContexte.sort(lIt).order = 'asc';
  // code agence
  lIt += 1;
  lContexte.filter(lIt).field = 'codeAgence';
  lContexte.filter(lIt).operator = CMAGIC_OP_EQUAL;
  lContexte.filter(lIt).value = gContexte.codeAgence;
  lContexte.sort(lIt).field = lContexte.filter(lIt).field;
  lContexte.sort(lIt).order = 'asc';

  if pFiltreListe <> *blanks;
    if pFiltreListe.id <> *zeros;
      lIt += 1;
      lContexte.filter(lIt).field = 'id';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.id);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.numeroClient <> *zeros;
      lIt += 1;
      lContexte.filter(lIt).field = 'numeroClient';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.numeroClient);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.nomClient <> *blanks;
      lIt += 1;
      lContexte.filter(lIt).field = 'nomClient';
      lContexte.filter(lIt).operator = CMAGIC_OP_LIKE;
      lContexte.filter(lIt).value = %trim(pFiltreListe.nomClient);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;
    if pFiltreListe.numeroContrat <> *zeros;
      lIt += 1;
      lContexte.filter(lIt).field = 'numeroContrat';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.numeroContrat);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.positionContrat <> *blanks;
      lIt += 1;
      lContexte.filter(lIt).field = 'positionContrat';
      lContexte.filter(lIt).operator = CMAGIC_OP_EQUAL;
      lContexte.filter(lIt).value = %trim(pFiltreListe.positionContrat);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.dateEcheanceContrat <> %date('0001-01-01');
      lIt += 1;
      lContexte.filter(lIt).field = 'dateEcheanceContrat';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.dateEcheanceContrat);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.montantContrat <> *zeros;
      lIt += 1;
      lContexte.filter(lIt).field = 'montantContrat';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.montantContrat);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.codeOpposition <> *blanks;
      lIt += 1;
      lContexte.filter(lIt).field = 'codeOpposition';
      lContexte.filter(lIt).operator = CMAGIC_OP_EQUAL;
      lContexte.filter(lIt).value = %trim(pFiltreListe.codeOpposition);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
    if pFiltreListe.dateFigement <> %date('0001-01-01');
      lIt += 1;
      lContexte.filter(lIt).field = 'dateFigement';
      lContexte.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lContexte.filter(lIt).value = %char(pFiltreListe.dateFigement);
      lContexte.sort(lIt).field = lContexte.filter(lIt).field;
      lContexte.sort(lIt).order = 'asc';
    endif;  
  endif;

  // finalisation
  pContexte.filter = lContexte.filter;
  pContexte.sort = lContexte.sort;
  return ;
end-proc;

