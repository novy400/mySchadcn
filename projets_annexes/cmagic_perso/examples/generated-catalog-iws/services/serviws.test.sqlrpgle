**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'SERVICE':'CKOOL':'NOXDB');
/include qinclude,TESTCASE

/include 'includes/services.iws.rpgleinc'
/include 'includes/services.read.rpgleinc'
/include 'includes/ckool.rpgleinc'
/include 'includes/llist/llist_h.rpgle'
/include 'includes/httpRest.rpgleinc'

dcl-pr QCMDEXC extpgm;
    command char(32767) const;
    length packed(15: 5) const;
end-pr;
dcl-s gCmd varchar(512);

dcl-proc setQueryString;
    dcl-pi *N;
        pQueryString varchar(4096) const;
    end-pi;
    monitor;
        gCmd = 'ADDENVVAR ENVVAR(QUERY_STRING) VALUE('''
             + %trim(pQueryString)
             + ''') REPLACE(*YES)';
        QCMDEXC(gCmd : %len(gCmd));
    on-error;
        fail('Unable to set QUERY_STRING');
    endmon;
end-proc;

dcl-proc clearQueryString;
    dcl-pi *N;
    end-pi;
    monitor;
        gCmd = 'RMVENVVAR ENVVAR(QUERY_STRING)';
        QCMDEXC(gCmd : %len(gCmd));
    on-error;
        // Ignore if the variable is not defined.
    endmon;
end-proc;

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
    clearQueryString();
end-proc;

dcl-proc tearDownSuite export;
    dcl-pi *N;
    end-pi;
    clearQueryString();
end-proc;

// Ajoutez ici les tests RPGUnit adaptes aux donnees et regles du projet.
// [CMAGIC:MANUAL_START]
// [CMAGIC:MANUAL_END]
