**free
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');

/include qinclude,TESTCASE
/include 'includes/cmagic.rpgleinc'
/include 'includes/global.rpgleinc'

dcl-ds gSupportedFields likeDS(CMAGIC_supportedFields);

// Initialisation globale pour tous les tests
dcl-proc setUp export;
  dcl-pi *n end-pi;
  dcl-s i int(5);
  
  clear gSupportedFields;
  
  // Simulation de la config d'une entité (ex: Employee)
  i += 1;
  gSupportedFields.supportedFields(i).name = 'id';
  gSupportedFields.supportedFields(i).sqlField = 'empno';
  gSupportedFields.supportedFields(i).dataType = 'C'; 
  
  i += 1;
  gSupportedFields.supportedFields(i).name = 'nom';
  gSupportedFields.supportedFields(i).sqlField = 'lastname';
  gSupportedFields.supportedFields(i).dataType = 'C'; 
  
  i += 1;
  gSupportedFields.supportedFields(i).name = 'salaire';
  gSupportedFields.supportedFields(i).sqlField = 'salary';
  gSupportedFields.supportedFields(i).dataType = 'N'; 
  
  i += 1;
  gSupportedFields.supportedFields(i).name = 'dateEmbauche';
  gSupportedFields.supportedFields(i).sqlField = 'hiredate';
  gSupportedFields.supportedFields(i).dataType = 'D'; 

  gSupportedFields.fieldsCount = i;
end-proc;

dcl-proc tearDown export;
 dcl-pi *n end-pi;
end-proc;


// --------------------------------------------------------------------------------
// TESTS pour cmagic_sanitizeContext
// --------------------------------------------------------------------------------

dcl-proc test_sanitize_Nominal export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDs(CMAGIC_context) inz;
  dcl-ds lSanitizedContext likeDs(CMAGIC_context) inz;
  dcl-ds lErrors likeDs(GLOBAL_listError) inz;
  dcl-s ok ind;

  // -- ARRANGE --
  lContext.pagination.numPage = 1;
  lContext.pagination.perPage = 20;
  
  lContext.sort(1).field = 'nom';
  lContext.sort(1).order = 'ASC';
  
  lContext.filter(1).field = 'salaire';
  lContext.filter(1).operator = '>=';
  lContext.filter(1).value = '30000';

  // -- ACT --
  ok = cmagic_sanitizeContext(lContext : gSupportedFields 
            : lSanitizedContext : lErrors);

  // -- ASSERT --
  assert(ok : 'Sanitize doit reussir');
  iEqual(20 : lSanitizedContext.pagination.perPage : 'PerPage conservé');
  aEqual('nom' : lSanitizedContext.sort(1).field : 'Tri valide conservé');
  aEqual('salaire' : lSanitizedContext.filter(1).field : 'Filtre valide conservé');

end-proc;

dcl-proc test_sanitize_Inconnu_Ignore export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDs(CMAGIC_context) inz;
  dcl-ds lSanitizedContext likeDs(CMAGIC_context) inz;
  dcl-ds lErrors likeDs(GLOBAL_listError) inz;
  dcl-s ok ind;

  // -- ARRANGE --
  // Champ "hacker" qui n'existe pas dans gSupportedFields
  lContext.filter(1).field = 'password'; 
  lContext.filter(1).value = '123456';
  
  lContext.sort(1).field = 'injection_sql';
  lContext.sort(1).order = 'ASC';

  // -- ACT --
  ok = cmagic_sanitizeContext(lContext : gSupportedFields 
          : lSanitizedContext : lErrors);

  // -- ASSERT --
  assert(ok : 'Sanitize doit reussir meme avec champs inconnus');
  aEqual('' : lSanitizedContext.filter(1).field : 'Filtre inconnu doit être supprimé');
  aEqual('' : lSanitizedContext.sort(1).field : 'Tri inconnu doit être supprimé');

end-proc;

dcl-proc test_sanitize_Tri_Injection export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDs(CMAGIC_context) inz;
  dcl-ds lSanitizedContext likeDs(CMAGIC_context) inz;
  dcl-ds lErrors likeDs(GLOBAL_listError) inz;
  dcl-s ok ind;

  // -- ARRANGE --
  lContext.sort(1).field = 'nom';
  // Tentative d'injection dans la order
  lContext.sort(1).order = 'ASC; DELETE FROM USERS'; 

  // -- ACT --
  ok = cmagic_sanitizeContext(lContext : gSupportedFields 
            : lSanitizedContext : lErrors);

  // -- ASSERT --
  assert(ok : 'Sanitize doit reussir');
  aEqual('nom' : lSanitizedContext.sort(1).field : 'Nom conservé');
  aEqual('ASC' : lSanitizedContext.sort(1).order 
              : 'order nettoyée (forcée à ASC)');

end-proc;


// --------------------------------------------------------------------------------
// TESTS pour cmagic_computeSqlClauses
// --------------------------------------------------------------------------------

dcl-proc test_sql_Simple_Filter export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDs(CMAGIC_context) inz;
  dcl-s lSelect varchar(5000);
  dcl-s lWhere varchar(5000);
  dcl-s lOrderBy varchar(5000);
  dcl-ds lErrors likeDs(GLOBAL_listError) inz;
  dcl-s ok ind;

  // -- ARRANGE --
  lContext.filter(1).field = 'nom'; 
  lContext.filter(1).operator = 'LIKE';
  lContext.filter(1).value = 'DUPONT';
  
  lContext.sort(1).field = 'salaire';
  lContext.sort(1).order = 'DESC';

  // -- ACT --
  ok = cmagic_computeSqlClauses(lContext : gSupportedFields
              : lSelect : lWhere : lOrderBy : lErrors);

  // -- ASSERT --
  assert(ok : 'Calcul SQL doit reussir');
  
  // Vérif SELECT : doit gérer les NULLs
  assert(%scan('IFNULL(empno, '''')' : lSelect) > 0 : 'Select gère NULL Char');
  assert(%scan('IFNULL(salary, 0)' : lSelect) > 0 : 'Select gère NULL Num');

  // Vérif WHERE : doit contenir le nom SQL 'lastname' et des quotes
  assert(%scan('lastname' : lWhere) > 0 : 'SQL doit utiliser le col name lastname');
  assert(%scan('UPPER(' + '''' + '%DUPONT%' + '''' + ')':lWhere) > 0 
            : 'Valeur quotée et wildcards');
  
  // Vérif ORDER
  aEqual(' Order by salary DESC' : lOrderBy : 'Order by correct');

end-proc;

dcl-proc test_sql_Global_Search export;
  dcl-pi *n extproc(*dclcase) end-pi;

  dcl-ds lContext likeDs(CMAGIC_context) inz;
  dcl-s lSelect varchar(5000);
  dcl-s lWhere varchar(5000);
  dcl-s lOrderBy varchar(5000);
  dcl-ds lErrors likeDs(GLOBAL_listError) inz;
  dcl-s ok ind;

  // -- ARRANGE --
  lContext.filter(1).field = 'q'; 
  lContext.filter(1).value = 'Recherche';

  // -- ACT --
  ok = cmagic_computeSqlClauses(lContext : gSupportedFields 
        : lSelect : lWhere : lOrderBy : lErrors);

  // -- ASSERT --
  assert(ok : 'Calcul SQL doit reussir');
  
  // Doit chercher dans id (Text), nom (Text), mais PAS salaire (Num) ni date
  // Note: Dans mon setup, 'id' est 'C'har
  assert(%scan('empno' : lWhere) > 0 : 'Doit chercher dans empno');
  assert(%scan('lastname' : lWhere) > 0 : 'Doit chercher dans lastname');
  assert(%scan('salary' : lWhere) = 0 : 'NE DOIT PAS chercher dans salary (Num)');
  
  assert(%scan('OR' : lWhere) > 0 : 'Doit utiliser des OR');

end-proc;