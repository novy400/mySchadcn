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
Ctl-Opt BndDir('QC2LE':'CKOOL':'NOXDB')
        Option(*nodebugio:*srcstmt:*nounref)
         main(main);
/include 'ckool.rpgleinc'
/include 'ileastic/noxdb.rpgleinc'

//------------------------------------------------------------- *
dcl-proc  main;
  dcl-pi *N;
  end-pi;
  dcl-s ErrorHappened ind ;
  dcl-ds lError likeDS(errorItem);
  Dcl-S lMessage like(CKOOL_longMessage);
  dcl-s lJson pointer;
  // initialilisation
  // traitement general
      // Create a "hello world" object - and serialize it to the joblog
    lJson = json_newObject();
    json_setStr (lJson: 'text' : 'Hello world');
    json_joblog(lJson);


    // Now go and get the text from that object, and log the text:
    clear lMessage;
    lMessage = json_getStr  (lJson: 'text');
    json_joblog(lMessage);

  lMessage = 'Ceci est un long message de test ';
  CKOOL_displayLongMessage(lMessage);
  // finalisation 
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' +
                 %trim(GLOBAL_Pgm.ProcPgm) + '.' +
                 %trim(GLOBAL_Pgm.Proc));
    else;
    // cKool 
    endif;
    json_delete(lJson);

    return;
end-proc;         