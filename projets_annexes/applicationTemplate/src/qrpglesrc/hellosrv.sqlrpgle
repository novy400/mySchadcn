**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE');
/include '../qrpgleref/HELLO.rpgleinc'
// /include QPrtSrc,risque

dcl-proc HELLO_proc1 export;
    dcl-pi *n ind;
        pMessage like(HELLO_message) const;
        pErrors likeDS(GLOBAL_listError);
    end-pi;
    dcl-ds lErrors likeDS(GLOBAL_listError);
    dcl-s lMessage like(pMessage);
    monitor;
    // initialisation
    clear pErrors;
    // controle de la demande

    // traitement
    clear lMessage;
    lMessage = %trim(%proc()) + '___' + 
        %trim(pMessage);

    // finalisation
    return *on;
    on-error;
        // 💥 horreur !
        clear pErrors;
        pErrors.listError(1).code= 'KOPROC1';
        snd-msg *info ('Horreur ! dans ' + %trim(%proc()));
        return *off;
    endmon;
end-proc;
dcl-proc HELLO_proc2 export;
    dcl-pi *n ind;
        pMessage like(HELLO_message) const;
        pErrors likeDS(GLOBAL_listError);
    end-pi;
    dcl-ds lErrors likeDS(GLOBAL_listError);
    dcl-s lMessage like(pMessage);
    dcl-s lQuotient int(3);
    dcl-s lDiviseur int(3);
    monitor;
    // initialisation
    clear pErrors;
    // controle de la demande

    // traitement
    clear lMessage;
    lMessage = %trim(%proc()) + '___' + 
        %trim(pMessage);
    // on fait sauter la banqsue  !
    clear lDiviseur; 
    lQuotient = 1 / lDiviseur;
    // finalisation
    return *on;
    on-error;
        // 💥 horreur !
        clear pErrors;
        pErrors.listError(1).code= 'KOPROC2';
        snd-msg *info ('Horreur ! dans ' + %trim(%proc()));
        return *off;
    endmon;
end-proc;

