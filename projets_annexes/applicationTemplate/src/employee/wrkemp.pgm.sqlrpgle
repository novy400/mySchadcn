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
/include 'employee.rpgleinc'
//  /include QPrtSrc,global
/include 'ckool.rpgleinc'
/include 'llist/llist_h.rpgle'
dcl-f Display   workstn qualified
//*********************************************************************
// TODO: 1.  Indiquer le nom du DSPF.
                extdesc('WRKEMP')
//*********************************************************************
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
  protectF2 ind pos(38);
  protectSF ind pos(39);
  error ind pos(99);
end-ds;
dcl-ds gSFL01_t   likerec(Display.SFL01: *all)    template;
dcl-ds gCTL01_t   likerec(Display.CTL01: *all)    template;
dcl-ds gBASPAGE_t   likerec(Display.BASPAGE: *all)    template;
dcl-ds gFVIDE_t  likerec(Display.FVIDE: *all)   template;
dcl-ds gFMT02_t   likerec(Display.FMT02: *all)    template;
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
dcl-c GNBLIGNESOUSFICHIER  17;
dcl-c COLOR_BLUE x'3a';
dcl-c COLOR_BLUE_RI x'3b';
dcl-s FMTFIRSTNAME char(12);
dcl-s FMTnom char(15);

dcl-ds gFiltreListe qualified;
//*********************************************************************
//TODO: 2.  Ajouter les champs filtres de la liste.
  // champs pour filtrer les items de la liste
  code like(gCTL01_t.code) inz;
  prenom like(gCTL01_t.prenom) inz;
  nom like(gCTL01_t.nom) inz;
  initiale like(gCTL01_t.initiale) inz;
  idService like(gCTL01_t.idService) inz;
//*********************************************************************
end-ds;
// le filtre t-il été modifié ?
dcl-ds gSaveFiltreListe likeDS(gFiltreListe);
// champs d'entete de l'écran
dcl-ds gEntete qualified;
  $NOMPGM like(gCTL01_t.$NOMPGM) inz;
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
dcl-ds gLigneSFL template qualified;
//*********************************************************************
//TODO: 5.  Ajouter les champs de la liste.
// champs pour afficher les items de la liste (sous-fichier)
  code like(gSFL01_t.code) inz;
  prenom like(gSFL01_t.prenom) inz;
  nom like(gSFL01_t.nom) inz;
  initiale like(gSFL01_t.initiale) inz;
  idService like(gSFL01_t.idService) inz;
//*********************************************************************
end-ds;
dcl-ds gSflListe template qualified;
  // une page du sous-fichier
  dcl-ds SflItem dim(gNBLIGNESOUSFICHIER) likeds(gLigneSFL);
end-ds;
//*********************************************************************
dcl-ds gDspf_detail_t template qualified;
//*********************************************************************
// TODO: 6.  Ajouter les champs de détails de l'entité.
  code like(gFMT02_t.code) inz;
  prenom like(gFMT02_t.prenom) inz;
  nom like(gFMT02_t.nom) inz;
  initiale like(gFMT02_t.initiale) inz;
  idService like(gFMT02_t.idService) inz;
  datembauch like(gFMT02_t.datembauch) inz;
  datnaissan like(gFMT02_t.datnaissan) inz;
  genre like(gFMT02_t.genre) inz;
  salaire like(gFMT02_t.salaire) inz;
//*********************************************************************
end-ds;

dcl-s gInit ind;
dcl-s gFin_Sfl ind;
dcl-s gFin_Pgm ind;
dcl-s gFin_Pgm2 ind;
dcl-s gSflEnd ind;
dcl-c GQUOTE '''';
dcl-enum GMODE qualified;
  CREATION '***   CREATION   ***';
  MODIFICATION '*** MODIFICATION ***';
  CONSULTATION '*** CONSULTATION ***';
  SUPPRESSION '*** SUPPRESSION ***';
end-enum;

// pgm principal
dcl-proc  main;
  dcl-pi *N;
  //*********************************************************************
  // TODO: 7.  Ajouter les paramétres éventuels.
  // pIn likeDS(gIN) const;
  // pOut likeDS(gOut);
  // cf inviteEmp.
  //*********************************************************************
  end-pi;
  dcl-ds lError likeDS(errorItem);
  dcl-s ErrorHappened ind ;
  Exec sql
            SET OPTION DATFMT = *ISO, COMMIT = *NONE;
  // initailisation
  //*********************************************************************
  // TODO: 8. Facultatif ssi il ya des paramétres en entrée.
  // cf inviteEmp.
  //*********************************************************************
  if not initTrt();
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
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  // initialisation des variables
  clear lError;
  clear gFiltreListe;
  clear gSaveFiltreListe;
  clear gPosPage;
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
  Dow lNbLigneSFL < gNBLIGNESOUSFICHIER and
        lListeSFL.SflItem(lItem).code <> *blanks;
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

  If lNbLigneSFL < gNBLIGNESOUSFICHIER;
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
  dcl-ds lDetailEntity likeDs(employee_detail_t) inz; 


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
        gFiltreListe.code = lDetailEntity.id.code;
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
  dcl-ds lDetailEntity likeDs(employee_detail_t) inz; 
  dcl-ds lIdEntity likeDs(employee_detail_t.id) inz;
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
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
    // on le met dans la zone de détail.
    clear lDetailDspf;
    eval-corr lDetailDspf = lSFL01;
    clear lDetailEntity;
    dspfToEntity(lDetailDspf:lDetailEntity);
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
          clear lDetailDspf;
          entityToDspf(lDetailEntity : lDetailDspf);
          eval-corr lSFL01 = lDetailDspf;
        endif;
        dspf.error = *off;
        // 4 = Supprimer
        // -----------------------
      When lSFL01.CHOIX    = '4';
        gFin_Pgm    = *off;
        clear lDetailEntity;
        if suppression(lIdEntity:lDetailEntity);
          // on recharge les zones modifiées.
          clear lDetailDspf;
          entityToDspf(lDetailEntity : lDetailDspf);
          eval-corr lSFL01 = lDetailDspf;
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
    pId likeDS(employee_detail_t.id);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetail likeds(employee_detail_t);
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 

  // Initialisation
  clear lError;
  Dspf.protectF2 = *on;
  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lFMT02;
  lFMT02.mode = GMODE.CONSULTATION;
  eval-corr lFMT02 = gEntete;  
  lFMT02.Tfonctions = 'F3=Sortie  F12=Retour    ';

  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lFMT02.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;
  // Chargement de l'écran de consultation.
  clear lDetailDspf;
  entityToDspf(lDetail : lDetailDspf);
  eval-corr lFMT02 = lDetailDspf;
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
    pId likeDS(employee_detail_t.id) const;
    pDetail likeDs(employee_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lDetail likeDs(employee_detail_t) inz;
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-s lAction like(GLOBAL_codeAction) inz;
  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.protectF2 = *off;

  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lFMT02;
  lFMT02.mode = GMODE.MODIFICATION;
  lAction = employee_listeAction.modification;
  eval-corr lFMT02 = gEntete;
  lFMT02.TfonctionS =
                 'F3=Sortie '+ COLOR_BLUE_RI+'F9=VALIDER'+ COLOR_BLUE + '       '
                    + '                F12=Retour ' ;
  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lFMT02.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;  
  // Chargement de l'écran de modification. 
  clear lDetailDspf;
  entityToDspf(lDetail : lDetailDspf);
  eval-corr lFMT02 = lDetailDspf;
  // Consultation
  Dow 1=1; 
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
        if not isValidSaisieDetail(lAction:lFMT02);
          Dspf.error = *on;
          iter;
        endif;
        // Demande de confirmation  ?
        if isConfirm();
          // mise à jour.
          clear lDetail;
          eval-corr lDetailDspf = lFMT02;
          dspfToEntity(lDetailDspf:lDetail);
          if not modifieEntity(pId:lDetail);
            // erreur de modification.
            // on affiche les erreurs.
            return *off;
          endif;
          pDetail = lDetail;
          // retour ecran precedent.
          return *on;
        endif;
      other;
        // controle des infos.
        dspf.error = *off;
        if not isValidSaisieDetail(lAction:lFMT02);
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

dcl-proc suppression;
  dcl-pi *N ind;
    pId likeDS(employee_detail_t.id) const;
    pDetail likeDs(employee_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetail likeDs(employee_detail_t) inz;
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.protectF2 = *on;
  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lFMT02;
  lFMT02.mode = GMODE.SUPPRESSION;
  eval-corr lFMT02 = gEntete;
  lFMT02.TfonctionS =
                 'F3=Sortie '+ COLOR_BLUE_RI+'F9=VALIDER'+ COLOR_BLUE + '       '
                    + '                F12=Retour ' ;
  clear lDetail;
  chargementDetailEntity(pId:lDetail:lError);
  if lError.code <> *blanks;
    Dspf.error = *on;
    lFMT02.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
  endif;  
  // Chargement de l'écran de modification. 
  clear lDetailDspf;
  entityToDspf(lDetail : lDetailDspf);
  eval-corr lFMT02 = lDetailDspf;
  // Consultation
  Dow 1=1; 
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
          eval-corr lDetailDspf = lFMT02;
          dspfToEntity(lDetailDspf:lDetail);
          if not supprimeEntity(pId:lDetail);
            // erreur de suppression.
            // on affiche les erreurs.
            return *off;
          endif;
          // retour ecran precedent.
          lDetail.nom = '-- Supprimé --';
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
    pDetail likeDs(employee_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lDetail likeDs(employee_detail_t) inz;
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  dcl-s lAction like(GLOBAL_codeAction) inz;
  dcl-ds lId likeDS(employee_detail_t.id);

  // Initialisation
  clear pDetail;
  clear lError;
  Dspf.protectF2 = *off;

  Dspf.error = *off;
  // Chargement des zones de l'écran.
  clear lFMT02;
  lFMT02.mode = GMODE.CREATION;
  lAction = employee_listeAction.creation;
  eval-corr lFMT02 = gEntete;
  lFMT02.TfonctionS =
                 'F3=Sortie '+ COLOR_BLUE_RI+'F9=VALIDER'+ COLOR_BLUE + '       '
                    + '                F12=Retour ' ;
  clear lDetail;
  // Chargement de l'écran de creation. 
  clear lDetailDspf;
  eval-corr lFMT02 = lDetailDspf;
  // Consultation
  Dow 1=1; 
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
        if not isValidSaisieDetail(lAction:lFMT02);
          Dspf.error = *on;
          iter;
        endif;
        // Demande de confirmation  ?
        if isConfirm();
          // mise à jour.
          clear lDetail;
          eval-corr lDetailDspf = lFMT02;
          dspfToEntity(lDetailDspf:lDetail);
          clear lId;
          if not creeEntity(lDetail:lId);
            // erreur de création.
            // on affiche les erreurs.
            return *off;
          endif;
          lDetail.id = lId;
          pDetail = lDetail;
          // retour ecran precedent.
          return *on;
        endif;
      other;
        // controle des infos.
        dspf.error = *off;
        if not isValidSaisieDetail(lAction:lFMT02);
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
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lDetail likeDs(employee_detail_t) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lFMT02 likeDs(gFMT02_t) inz; 
  // initialisation
  lFMT02 = pFMT02;
  // traitement 
  clear lDetail;
  eval-corr lDetailDspf = lFMT02;
  dspfToEntity(lDetailDspf:lDetail);
        // controle de l'entité.  
  clear lErrors;
  if not isValidEntity(pAction:lDetail:lErrors);
    clear lError;
    lError = lErrors.listError(1);
    lFMT02.WMSG = lError.code;
    getPositionZone('FMT02':lError.nomZone
            :lFMT02.row:lFMT02.col);
    pFMT02 = lFMT02;
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
  //*********************************************************************
  // TODO: 9. definir prototype et parametres de chaque programme d'invite 
  dcl-s lCodeDepartement like(gFMT02_t.idservice);
  dcl-s lNumerorEmploye like(gFMT02_t.code);
  dcl-pr getEmploye extpgm('INVEMP');
    pCodeDepartement like(gFMT02_t.idservice);
    pNumerorEmploye like(gFMT02_t.code);
  end-pr;
  //*********************************************************************
  clear lError;
  select;
  //*********************************************************************
  // TODO: 9. definir appel du programme d'invite en fonction de la zone  
  // du formaulaire
    when pFmt02.rec= 'FMT02' and pFmt02.fld ='nom';
      clear lCodeDepartement;
      clear lNumerorEmploye;
      getEmploye(lCodeDepartement:lNumerorEmploye);
      if lNumerorEmploye <> *blanks;
        pFmt02.nom = lNumerorEmploye;
      endif;
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
    pId likeDS(employee_detail_t.id) const;
    pDetail likeDs(employee_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;

  clear lError;
  clear lErrors;
  
  // Use employee_update procedure instead of direct SQL
  if not employee_update(pId : pDetail : lErrors);
    CKOOL_displayListError(lErrors);
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
    pId likeDS(employee_detail_t.id) const;
    pDetail likeDs(employee_detail_t);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;

  clear lError;
  clear lErrors;
  
  // Use employee_delete procedure instead of direct SQL
  if not employee_delete(pId : lErrors);
    CKOOL_displayListError(lErrors);
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
    pDetail likeDs(employee_detail_t) const;
    pId likeDS(employee_detail_t.id);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lOK ind;
  dcl-ds lId likeDS(employee_detail_t.id);

  clear lError;
  clear lErrors;
  
  // Use employee_update procedure instead of direct SQL
  clear lId;
  if not employee_create(pDetail :lId :lErrors);
    CKOOL_displayListError(lErrors);
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
    pDetail likeDs(employee_detail_t) const;
    pErrors likeDS(GLOBAL_listError); 
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lBefore likeDs(employee_detail_t) inz;
  
  clear pErrors;
  clear lErrors;
  
  // Use employee_isValid for validation
  clear lBefore;
  if employee_isValid(pAction :lBefore :pDetail 
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
    pId likeDS(employee_detail_t.id) const;
    pDetail likeDs(employee_detail_t);
    pError likeDS(errorItem);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lId likeDS(employee_detail_t.id) inz;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-ds lDetail likeds(employee_detail_t) inz;
  // Initialisation
  clear pError;
  clear pDetail;
  // traitement 
  clear lId;
  clear lErrors;
  clear lDetail;
  lId = pId;
  if not employee_getByID(lId : lDetail : lErrors);
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
  dcl-ds lItemEntity likeds(employee_item_t) based(lItemPtr);
  dcl-ds lDetailEntity likeDS(employee_detail_t) inz;
  dcl-ds lDetailDspf likeDs(gDspf_detail_t) inz;
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lIt int(5);
  dcl-s lNextPage int(5);
  // initialisation
  clear pListe;
  clear lErrors;
  clear lContext;
  lContext.pagination.perPage = gNBLIGNESOUSFICHIER;
  // ajout du filtre
  getFiltreContext(pFiltreListe:lContext);

  // attention à calculer ....page suivante....
  clear lNextPage;
  lNextPage = %div(fichierDS.nbrcd_sfl : gNBLIGNESOUSFICHIER) + 1;
  lContext.pagination.numPage = lNextPage;

  // Traitement
  clear lErrors;
  clear lList;
  clear lTotalCount;
  if not  employee_search(lContext : lTotalCount : lList : lErrors);
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
    if lIt > gNBLIGNESOUSFICHIER;
      leave;
    endif;
    // on charge l'item dans le sous-fichier
    clear lDetailEntity;
    eval-corr lDetailEntity = lItemEntity;
    clear lDetailDspf;
    entityToDspf(lDetailEntity : lDetailDspf);
    eval-corr pListe.SflItem(lIt) = lDetailDspf;
  enddo;
  // Finalisation
  Return *off;

  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *on; 
    endif;
end-proc; 


dcl-proc entityToDspf;
  dcl-pi *n ;
    pDetailEntity likeds(employee_detail_t) const;
    pDetailDspf likeDs(gDspf_detail_t);
  end-pi;
  clear pDetailDspf;
  eval-corr pDetailDspf = pDetailEntity;  // Automatique si noms identiques
  
  // Mappings spécifiques seulement si nécessaires
  pDetailDspf.code = pDetailEntity.id.code;
  pDetailDspf.datembauch = pDetailEntity.dateEmbauche;  
  pDetailDspf.datnaissan = pDetailEntity.dateNaissance;    
end-proc;

dcl-proc dspfToEntity;
  dcl-pi *n ;
    pDetailDspf likeDs(gDspf_detail_t) const;
    pDetailEntity likeds(employee_detail_t);
  end-pi;
  clear pDetailEntity;
  eval-corr pDetailEntity = pDetailDspf;  // Automatique si noms identiques
  
  // Mappings spécifiques seulement si nécessaires
  pDetailEntity.id.code = pDetailDspf.code;
  pDetailEntity.dateEmbauche  = pDetailDspf.datembauch;  
  pDetailEntity.dateNaissance = pDetailDspf.datnaissan;    

end-proc;

dcl-proc getInfosEntete;
  dcl-pi *n ;
  end-pi;
  clear gEntete;  
  gEntete.$NOMPGM = %trim(GLOBAL_Pgm.ProcPgm);
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
    pNomZone char(10) const;
    pligne like(gFMT02_t.row);
    pcolonne like(gFMT02_t.col);
  end-pi;
  clear pligne;
  clear pcolonne; 
  select;
    //*********************************************************************
    // TODO: 1.  positionner ligne et colonne des champs du formulaire.
    When pNomZone ='nom';
      pligne = 10;
      pcolonne = 6;
    When pNomZone ='prenom';
      pligne = 12;
      pcolonne = 9;
    When pNomZone ='initiale';
      pligne = 14;
      pcolonne = 11;
    When pNomZone ='idService';
      pligne = 16;
      pcolonne = 10;
    When pNomZone ='genre';
      pligne = 20;
      pcolonne = 8;
    When pNomZone ='salaire';
      pligne = 21;
      pcolonne = 10;

    //*********************************************************************
    other;
  endsl;
  return ;
end-proc;


dcl-proc getFiltreContext;
  dcl-pi *n ;
    pFiltreListe likeds(gFiltreListe) const;
    pFiltre likeDS(CMAGIC_context);
  end-pi;
  dcl-ds lFiltre likeDS(CMAGIC_context);
  dcl-s lIt int(5);
  // initialisation
  clear lFiltre;
  lFiltre = pFiltre;
  // traitement
  if pFiltreListe <> *blanks;
    clear lIt;
    if pFiltreListe.code <> *blanks;
      lIt += 1;
      lFiltre.filter(lIt).field = 'id';
      lFiltre.filter(lIt).operator = CMAGIC_OP_GREATER_EQUAL;
      lFiltre.filter(lIt).value = %trim(pFiltreListe.code);
    endif;  
    if pFiltreListe.prenom <> *blanks;
      lIt += 1;
      lFiltre.filter(lIt).field = 'prenom';
      lFiltre.filter(lIt).operator = CMAGIC_OP_LIKE;
      lFiltre.filter(lIt).value = %trim(pFiltreListe.prenom);
    endif;
    if pFiltreListe.nom <> *blanks;
      lIt += 1;
      lFiltre.filter(lIt).field = 'nom';
      lFiltre.filter(lIt).operator = CMAGIC_OP_LIKE;
      lFiltre.filter(lIt).value = %trim(pFiltreListe.nom);
    endif;  
    if pFiltreListe.initiale <> *blanks;
      lIt += 1;
      lFiltre.filter(lIt).field = 'initiale';
      lFiltre.filter(lIt).operator = CMAGIC_OP_EQUAL;
      lFiltre.filter(lIt).value = %trim(pFiltreListe.initiale);
    endif;  
    if pFiltreListe.idService <> *blanks;
      lIt += 1;
      lFiltre.filter(lIt).field = 'idService';
      lFiltre.filter(lIt).operator = CMAGIC_OP_EQUAL;
      lFiltre.filter(lIt).value = %trim(pFiltreListe.idService);
    endif;  
  endif;

  // finalisation
  pFiltre = lFiltre;
  return ;
end-proc;

