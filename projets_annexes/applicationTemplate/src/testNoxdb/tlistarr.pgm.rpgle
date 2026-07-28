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
  dcl-DS lrow template qualified;
    id   int(10);
    name varchar(256);
  end-ds;
  dcl-DS lListRow dim(2) likeds(lrow) inz;
dcl-s ItemJson pointer;
dcl-s ListJson pointer;
  // initialilisation
  clear lListRow;
  // Make some data we can play with
  for i = 1 to %elem(lListRow) ;
    lListRow(i).id = i;
    lListRow(i).name = 'text : ' + %char(i);
  endfor;
  ListJson = json_newArray(); 
  ItemJson = json_newObject();
  for i = 1 to %elem(lListRow) ;
    json_setInt(ItemJson : 'id' : lListRow(i).id);
    json_setStr(ItemJson : 'name' : lListRow(i).name);
    json_arrayPush(ListJson : ItemJson);
  endfor;
  
  // traitement general

  // finalisation 
    json_joblog(ListJson);
  on-exit ErrorHappened;
    if ErrorHappened;
      snd-msg *escape ('Horreur ! dans ' +
                 %trim(GLOBAL_Pgm.ProcPgm) + '.' +
                 %trim(GLOBAL_Pgm.Proc));
    else;
    // cKool 
    endif;
    json_delete(ListJson);
    json_delete(ItemJson);

    return;
end-proc;         