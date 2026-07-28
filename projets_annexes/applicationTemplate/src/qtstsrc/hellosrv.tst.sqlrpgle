**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'HELLO');
/include qinclude,TESTCASE 
/include '../qrpgleref/HELLO.rpgleinc'

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
dcl-proc  test_proc1_vide export;
    dcl-pi *N; 
    end-pi;
    dcl-ds lErrors likeDS(GLOBAL_listError);
    dcl-s lOK ind inz(*off);
    dcl-s lmessage like(HELLO_message);

    monitor;
    // initialisation

    // traitement
        clear lMessage;
        clear lErrors;
        clear lOk;
        lOK = HELLO_proc1(lMessage:lErrors);

    // finalisation 
        assert(lOK = *on : 'KO cela ne marche pas !');
        // assert(lError.listError(1).nomZone =  'etablissement');
        // assert(lError.listError(1).text =  'Zone obligatoire');
    
    on-error;
    // 💥 hooreur !
        snd-msg *escape ('Horreur ! dans ' + %trim(%proc()));
    endmon;
end-proc;
dcl-proc  test_proc2_vide export;
    dcl-pi *N; 
    end-pi;
    dcl-ds lErrors likeDS(GLOBAL_listError);
    dcl-s lOK ind inz(*off);
    dcl-s lmessage like(HELLO_message);

    monitor;
    // initialisation

    // traitement
        clear lMessage;
        clear lErrors;
        clear lOk;
        lOK = HELLO_proc2(lMessage:lErrors);

    // finalisation 
        assert(lOK = *off : 'KO cela ne marche pas !');
        assert(lErrors.listError(1).code =  'KOPROC2');

    on-error;
    // 💥 hooreur !
        snd-msg *escape ('Horreur ! dans ' + %trim(%proc()));
    endmon;
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




