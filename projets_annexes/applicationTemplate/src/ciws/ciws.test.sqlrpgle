**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');

/include qinclude,TESTCASE
/include 'includes/cmagic.rpgleinc'
/include 'includes/global.rpgleinc'
/include 'includes/ciws.rpgleinc'

// -----------------------------------------------------------------------------
// Tests CIWS
//
// Stratégie retenue:
// - On teste l'API publique réelle : CIWS_initRestRequest
// - On pilote QUERY_STRING via l'environnement du job
// - On vérifie le CMAGIC_context produit
// -----------------------------------------------------------------------------

// Prototype C pour positionner l'environnement du job
// putenv attend une chaîne du type 'NAME=VALUE'
dcl-pr putenv int(10) extproc('putenv');
  envString pointer value options(*string);
end-pr;

dcl-ds gSupportedFields likeDS(CMAGIC_supportedFields);

// -----------------------------------------------------------------------------
// Initialisation commune
// -----------------------------------------------------------------------------
dcl-proc setUp export;
  dcl-pi *n end-pi;
  dcl-s i int(5);
  dcl-s rc int(10);

  clear gSupportedFields;
  i = 0;

  i += 1;
  gSupportedFields.supportedFields(i).name = 'id';
  gSupportedFields.supportedFields(i).sqlField = 'empno';
  gSupportedFields.supportedFields(i).dataType = 'C';
  gSupportedFields.supportedFields(i).orderTri = i;

  i += 1;
  gSupportedFields.supportedFields(i).name = 'nom';
  gSupportedFields.supportedFields(i).sqlField = 'lastname';
  gSupportedFields.supportedFields(i).dataType = 'C';
  gSupportedFields.supportedFields(i).orderTri = i;

  i += 1;
  gSupportedFields.supportedFields(i).name = 'salaire';
  gSupportedFields.supportedFields(i).sqlField = 'salary';
  gSupportedFields.supportedFields(i).dataType = 'N';
  gSupportedFields.supportedFields(i).orderTri = i;

  i += 1;
  gSupportedFields.supportedFields(i).name = 'dateEmbauche';
  gSupportedFields.supportedFields(i).sqlField = 'hiredate';
  gSupportedFields.supportedFields(i).dataType = 'D';
  gSupportedFields.supportedFields(i).orderTri = i;

  gSupportedFields.fieldsCount = i;

  // Nettoyage par défaut entre tests
  rc = putenv('QUERY_STRING=');
end-proc;

dcl-proc tearDown export;
  dcl-pi *n end-pi;
  dcl-s rc int(10);

  rc = putenv('QUERY_STRING=');
end-proc;

// -----------------------------------------------------------------------------
// Pagination
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_Pagination_Nominal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=2&perPage=25');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(2  : lContext.pagination.numPage : 'Page = 2');
  iEqual(25 : lContext.pagination.perPage : 'PerPage = 25');
end-proc;

dcl-proc test_ciws_init_Pagination_Limit_Fallback export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=3&limit=15');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(3  : lContext.pagination.numPage : 'Page = 3');
  iEqual(15 : lContext.pagination.perPage : 'Fallback limit = 15');
end-proc;

dcl-proc test_ciws_init_Pagination_Defaults export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(1 : lContext.pagination.numPage : 'Page par défaut = 1');
  iEqual(CMAGIC_DEFAULT_LIMIT : lContext.pagination.perPage : 'PerPage par défaut');
end-proc;

dcl-proc test_ciws_init_Pagination_Max_100 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=1&perPage=999');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(100 : lContext.pagination.perPage : 'PerPage plafonné à 100');
end-proc;

// -----------------------------------------------------------------------------
// Tri
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_Sort_Nominal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=sort=nom&order=DESC');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('nom'  : %trim(lContext.sort(1).field) : 'Champ tri principal');
  aEqual('DESC' : %trim(lContext.sort(1).order) : 'Ordre DESC');
end-proc;

dcl-proc test_ciws_init_Sort_Default_Order export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=sort=nom');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('nom' : %trim(lContext.sort(1).field) : 'Champ tri principal');
  aEqual('ASC' : %trim(lContext.sort(1).order) : 'Ordre par défaut ASC');
end-proc;

// -----------------------------------------------------------------------------
// Filtres
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_Filter_Equal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=nom=Dupont');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('nom'    : %trim(lContext.filter(1).field) : 'Champ filtre');
  aEqual('='      : %trim(lContext.filter(1).operator) : 'Opérateur =');
  aEqual('Dupont' : %trim(lContext.filter(1).value) : 'Valeur filtre');
end-proc;

dcl-proc test_ciws_init_Filter_Like export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=nom_like=dup');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('nom'  : %trim(lContext.filter(1).field) : 'Champ filtre LIKE');
  aEqual('LIKE' : %trim(lContext.filter(1).operator) : 'Opérateur LIKE');
  aEqual('dup'  : %trim(lContext.filter(1).value) : 'Valeur LIKE');
end-proc;

dcl-proc test_ciws_init_Filter_Range export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=salaire_gte=30000&salaire_lte=50000');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('salaire' : %trim(lContext.filter(1).field) : 'Filtre 1 champ');
  aEqual('>='      : %trim(lContext.filter(1).operator) : 'Filtre 1 opérateur');
  aEqual('30000'   : %trim(lContext.filter(1).value) : 'Filtre 1 valeur');

  aEqual('salaire' : %trim(lContext.filter(2).field) : 'Filtre 2 champ');
  aEqual('<='      : %trim(lContext.filter(2).operator) : 'Filtre 2 opérateur');
  aEqual('50000'   : %trim(lContext.filter(2).value) : 'Filtre 2 valeur');
end-proc;

// -----------------------------------------------------------------------------
// Recherche globale
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_Global_Search export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=q=Recherche');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('q'         : %trim(lContext.filter(1).field) : 'Champ q');
  aEqual('LIKE'      : %trim(lContext.filter(1).operator) : 'Opérateur LIKE');
  aEqual('Recherche' : %trim(lContext.filter(1).value) : 'Valeur q');
end-proc;

// -----------------------------------------------------------------------------
// Décodage URL
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_UrlDecode_Spaces export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=nom=Jean+Dupont');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('Jean Dupont' : %trim(lContext.filter(1).value) : 'Décodage + vers espace');
end-proc;

// -----------------------------------------------------------------------------
// Cas défensifs complémentaires
// -----------------------------------------------------------------------------
dcl-proc test_ciws_init_PerPage_Zero_Default export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=1&perPage=0');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(CMAGIC_DEFAULT_LIMIT : lContext.pagination.perPage
       : 'PerPage=0 doit retomber sur la valeur par défaut');
end-proc;


dcl-proc test_ciws_init_PerPage_Negative_Default export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=1&perPage=-5');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(CMAGIC_DEFAULT_LIMIT : lContext.pagination.perPage
       : 'PerPage négatif doit retomber sur la valeur par défaut');
end-proc;


dcl-proc test_ciws_init_Page_Zero_Reset_To_1 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=0&perPage=20');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(1 : lContext.pagination.numPage
       : 'Page=0 doit être repositionnée à 1');
  iEqual(20 : lContext.pagination.perPage : 'PerPage conservé');
end-proc;


dcl-proc test_ciws_init_Page_Negative_Reset_To_1 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=page=-3&perPage=20');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  iEqual(1 : lContext.pagination.numPage
       : 'Page négative doit être repositionnée à 1');
end-proc;


dcl-proc test_ciws_init_Order_Invalid_Default_ASC export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=sort=nom&order=XXX');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('nom' : %trim(lContext.sort(1).field) : 'Champ tri conservé');
  aEqual('ASC' : %trim(lContext.sort(1).order)
       : 'Ordre invalide doit retomber à ASC');
end-proc;


dcl-proc test_ciws_init_Unknown_Field_Not_Parsed export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=hack=1');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('' : %trim(lContext.filter(1).field)
       : 'Champ inconnu ne doit pas créer de filtre');
end-proc;


dcl-proc test_ciws_init_UrlDecode_Ampersand export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=nom=A%26B');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('A&B' : %trim(lContext.filter(1).value)
       : 'Décodage %26 vers &');
end-proc;


dcl-proc test_ciws_init_UrlDecode_Percent20 export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-ds lErrors  likeDS(GLOBAL_listError) inz;
  dcl-s ok ind;
  dcl-s rc int(10);

  // -- ARRANGE --
  rc = putenv('QUERY_STRING=q=Contrat%20IBM');

  // -- ACT --
  ok = CIWS_initRestRequest(gSupportedFields : lContext : lErrors);

  // -- ASSERT --
  assert(ok : 'CIWS_initRestRequest doit réussir');
  aEqual('Contrat IBM' : %trim(lContext.filter(1).value)
       : 'Décodage %20 vers espace');
end-proc;

