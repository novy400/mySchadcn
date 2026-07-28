**free
//=======================================================================================
//\brief                                          
//\author novy                                                                           
//\date                                                                                  
//\warning No warning                                                                    
//---------------------------------------------------------------------------------------
//\info :                                                                                
//      
//---------------------------------------------------------------------------------------
//\info compilation :                                                                    
//      .................................................................................
//      .................................................................................
//---------------------------------------------------------------------------------------
//                                                                                       
//\rev  dd.mm.ccyy                                                                       
//      .................................................................................
//      .................................................................................
//=======================================================================================
/if defined(*CRTBNDRPG)
ctl-opt dftactgrp(*no)
         actgrp(*new);
/endif
Ctl-Opt BndDir('QC2LE':'CKOOL')
        Option(*nodebugio:*srcstmt:*nounref)
         main(main);
/include 'employee.rpgleinc'
dcl-f Display   workstn qualified
                extdesc('INVEMP')
                extfile(*extdesc) 
                indds(Dspf) 
                infds(fichierDs) 
                sfile(SFL01:SFRRN)
                usropn;

dcl-s SFRRN int(5);
dcl-ds Dspf qualified ;
  refresh ind pos(5) ;
  abort ind pos(12);
  sflDsp ind pos(30);
  sflDspCtl ind pos(31);
  sflClr ind pos(32);
  sflEnd ind pos(33);
  sflRollup ind pos(35);
  error ind pos(99);
end-ds;   
dcl-ds gSFL01_t   likerec(Display.SFL01: *all)    template;
dcl-ds gCTL01_t   likerec(Display.CTL01: *all)    template;
dcl-ds gWIN01_t   likerec(Display.WIN01: *all)    template;
dcl-ds gCVIDE_t  likerec(Display.CVIDE: *all)   template;
dcl-ds fichierDS qualified;
  ligne    INT(3) POS(370); // curseur : ligne
  colonne  INT(3) POS(371); // curseur : colonne
  rang_sfl INT(5) POS(376);
  premier_rang_affiche INT(5) POS(378); // placé dans SFLRCNBR on réaffiche même page !
  nbrcd_sfl INT(5) POS(380);
  // position curseur, mais dans la fenêtre active
  posCurseur  INT(5) POS(382); 
end-ds;
dcl-c gNBLIGNESOUSFICHIER  12; // SLFSIZE du sous-fichier
dcl-ds gLigneSFL template qualified;
  ID like(gSFL01_t.ID);
  LIB like(gSFL01_t.LIB);
end-ds;
dcl-ds gSflListe template qualified;
  dcl-ds SflItem dim(gNBLIGNESOUSFICHIER) likeds(gLigneSFL);
end-ds;
dcl-ds FMT_VUE ext extname('VEMP') qualified end-ds;
dcl-ds gIN qualified;
  codeDepartement like(FMT_VUE.WORKDEPT);
end-ds;
dcl-ds gOut qualified;
  numeroEmploye like(FMT_VUE.EMPNO);
end-ds;
dcl-s gRechargeCurseur ind;
dcl-s gCreateCurseur ind;
dcl-s gFinPgm ind;
dcl-s gFinListe ind;
dcl-ds gFiltreListe qualified;
  LIB like(gCTL01_t.LIB) inz;
end-ds;
dcl-ds gEntete qualified;
  $NOMPGM like(gCTL01_t.$NOMPGM) inz;
end-ds;
dcl-ds gSaveFiltreListe likeDS(gFiltreListe);
//------------------------------------------------------------- *
dcl-proc  main;
  dcl-pi *N;
    pIn likeDS(gIN) const;
    pOut likeDS(gOut);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lIn likeDs(gIN);
  dcl-ds lSFL01 likeDs(gSFL01_t) inz;
  dcl-ds lCTL01 likeDs(gCTL01_t) inz;
    // initialilisation
  clear pOut;
  lIn =pIn;
  if not initTrt(lIn);
    clear lError;
    lError.textUser = 'horreur !';
    userFeedBack(lError);
    snd-msg *escape (lError.textUser + %trim(%proc()));
    return;
  endif;
  open Display;
  // traitement general
  // initialisation du sous-fichier.
  if not initSfl();
    //horreur à gérer.
  endif;
  // chargement du sous-fichier.
  if not ChgtSfl();
    //horreur à gérer.
  endif;

  Dow not gFinPgm;
    if not AffSfl();
      leave;
    endif;
  EndDo;
  pOut = gOut;
  snd-msg *INFO %char(pOut);
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

dcl-proc initTrt;
  dcl-pi *N ind;
    pIn likeDS(gIN);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
    // initialisation des variables
  clear lError;
  clear gEntete;
   gEntete.$NOMPGM = %trim(GLOBAL_Pgm.ProcPgm);
  gFinPgm = *off;
  clear gSaveFiltreListe;
  clear gFiltreListe;
  gCreateCurseur = *on;
  if pIn.codeDepartement = *blanks;
      // erreur eventuelle à gérer mais là non !
    pIn.codeDepartement = 'A00';  
  endif;
  gIN = pIn;
  // clear LIB;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    else;
      return *on;
    endif;
end-proc;

  // FeedBack to the endUser.
dcl-proc userFeedBack;
  dcl-pi *N;
    pError likeDS(errorItem) Const;
  end-pi;
    //TODO: ajouter un format d'ecran pour restituer l'erreur 
  return;
end-proc;

dcl-proc initSfl;
  dcl-pi *N ind;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lCTL01 likeds(gCTL01_t) inz;

  //initialisation
  clear lError;
  // traitement
  //Clear du sous fichier.
  clear SFRRN;
  clear lCTL01;
  Dspf.sflEnd = *on;
  Dspf.sflClr = *on;
  Dspf.sflDsp = *off;
  Dspf.sflDspctl = *off;
  Write Display.CTL01 lCTL01;
  Dspf.sflClr = *off;
  Dspf.sflDspctl = *on;
  gRechargeCurseur = *on;
 
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    else;
      return *on;
    endif;
end-proc;

dcl-proc ChgtSfl;
  dcl-pi *N ind;
  end-pi;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lListeSFL likeDs(gSflListe) inz;
  dcl-s ErrorHappened ind ;
  dcl-ds lItem likeDS(gSflListe.SflItem);
  dcl-ds lSFL01 likeDs(gSFL01_t) inz;
  dcl-ds lCTL01 likeDs(gCTL01_t) inz;
  dcl-ds lWIN01 likeDs(gWIN01_t) inz;
  dcl-ds lCVIDE likeDs(gCVIDE_t) inz;

  //Initialisation
  Dspf.SflDsp   = *on;
  clear lCVIDE;
  clear lWIN01;
    //Positionnement saisi ?
  If gFiltreListe <> gSaveFiltreListe
       and not dspf.sflRollup;
      // on recharge le curseur
    gRechargeCurseur = *on;
  Endif ;
  // chargement de la liste
  clear lListeSFL;
  gFinListe = getListeSousFichier(gFiltreListe
                    :gRechargeCurseur:lListeSFL);
  // chargement du sous-fichier
  SFRRN = fichierDS.nbrcd_sfl;
  for-each lItem in lListeSFL.SflItem;
    if lItem.ID = *blanks;
      gFinListe = *on;
      leave;
    endif;  
    SFRRN += 1;  
    clear lSFL01;
    eval-corr lSFL01 = lItem;
    Write Display.SFL01 lSFL01;
  endfor;
  Select;
    When fichierDS.nbrcd_sfl > *zeros and gFinListe = *on;
      dspf.sflEnd = *on;
    When fichierDS.nbrcd_sfl = *zeros;
      dspf.sflDsp = *off;
      Write Display.WIN01 lWIN01;
      Write Display.CVIDE lCVIDE;
    Other;
      dspf.sflEnd = *off;
  EndSl;
  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    else;
      return *on;
    endif;
end-proc;
dcl-proc affSfl;
  dcl-pi *N ind;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-ds lCTL01 likeDs(gCTL01_t) inz;
  dcl-ds lWIN01 likeDs(gWIN01_t) inz;

  clear lError;
  clear lCTL01;
  clear lWIN01;
  eval-corr lCTL01 = gFiltreListe;
  eval-corr lCTL01 = gEntete;

    //est ce qu'il y a des enregistrements ?
  if fichierDS.nbrcd_sfl > *zeros;
    lCTL01.pospage = fichierDS.nbrcd_sfl;
  endif;
    //Affichage de l'écran
  Write Display.WIN01 lWIN01;
  ExFmt Display.CTL01 lCTL01;

    //Sauvegarde de la page visualisée

  Select;
           //F05=Rafraichir
    When dspf.refresh;
      clear gFiltreListe;
      clear gSaveFiltreListe;
      InitSfl();
      ChgtSfl();

           //F12=Annuler
    When dspf.abort;
      gFinPgm = *on;

           //Rollup=pagination
    When dspf.sflRollup;
      ChgtSfl();

           //Other
    Other;
           // selection d'un enreg...
      If Dspf.sflDsp;
        lectSfl();
        if gFinPgm;
          return *on;
        endif;
      Endif;

           //Positionnement ?
      eval-corr gFiltreListe = lCTL01;     
      If gFiltreListe <> gSaveFiltreListe;
        initSfl();
        ChgtSfl();
      EndIf;
  EndSl;
  return *on;         
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    else;
      return *on;
    endif;
end-proc;
dcl-proc getListeSousFichier;
  dcl-pi *N ind;
    pFiltreListe likeds(gFiltreListe) const;
    pRechargeCurseur like(gRechargeCurseur) const;
    pListe likeDs(gSflListe);
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s lList pointer;
  dcl-ds lItem likeds(employee_item_t) based(lItemPtr);
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
  if pFiltreListe <> *blanks;
    lContext.filter(1).field = 'lastname';
    lContext.filter(1).value = %trim(pFiltreListe.lib);
  endif;
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
    pListe.SflItem(lIt).ID = lItem.id.code;
    pListe.SflItem(lIt).LIB = lItem.nom;
  enddo;
  // Finalisation
  Return *off;

  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *on; 
    endif;

end-proc; 
dcl-proc lectSfl;
  dcl-pi *N ind;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  dcl-s lLignePageModif like(SFRRN) inz;
  dcl-ds lSFL01 likeDs(gSFL01_t) inz;

    // Initialisation
  clear lError;
  clear lLignePageModif;
  Readc Display.SFL01 lSFL01;
  Dow not %eof();
    Select;
        //1 = Sélectionner
        //-----------------------
      When lSFL01.$CHOIX    = '1';
        gFinPgm    = *on;
        gOut.numeroEmploye = lSFL01.ID;
        leave;
    EndSl;
    clear lSFL01.$CHOIX;
    Update Display.SFL01 lSFL01;
    Readc Display.SFL01  lSFL01;
  EndDo;

  return *on;
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' + %trim(GLOBAL_Pgm.Proc));
      return *off; 
    else;
      return *on;
    endif;

end-proc;
