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
  dcl-s lJson pointer;
  dcl-s i	        int(10);
  dcl-s handle	char(1);
  dcl-DS row  qualified inz;
    id   int(10);
    name varchar(256);
  end-ds;

  // initialilisation
  clear row;
  // Make some data we can play with
    row.id = 1;
    row.name = 'text : 1';


  // traitement general
   data-gen row %data(handle: '') %gen(json_DataGen(lJson));

  // finalisation 
    json_joblog(lJson);
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