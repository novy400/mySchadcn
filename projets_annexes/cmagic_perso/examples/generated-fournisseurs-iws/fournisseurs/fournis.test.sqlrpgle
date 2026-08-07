**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'FOURNIS':'CKOOL');
/include qinclude,TESTCASE

/include 'includes/fournisseurs.read.rpgleinc'
/include 'includes/llist/llist_h.rpgle'
/include 'includes/ckool.rpgleinc'

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

// Ajoutez ici les tests RPGUnit adaptes aux donnees et regles du projet.
// [CMAGIC:MANUAL_START]
// [CMAGIC:MANUAL_END]
