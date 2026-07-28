<#
.SYNOPSIS
    Génère une nouvelle ressource API REST conforme aux conventions ArchiAPI

.DESCRIPTION
    Crée l'ensemble des fichiers nécessaires pour une nouvelle ressource:
    - Module métier (.sqlrpgle)
    - Module REST (.rest.sqlrpgle)
    - Module routes (.route.sqlrpgle)
    - Prototypes et structures (.rpgleinc)
    - Binding source (.bnd)
    
    Basé sur les conventions extraites de src/employee

.PARAMETER Name
    Nom de la ressource (singulier, ex: "product", "customer")

.PARAMETER Table
    Nom de la table DB2 (ex: "PRODUCT", "CUSTOMER")

.PARAMETER PluralName
    Nom pluriel pour les routes (optionnel, auto-généré si absent)

.PARAMETER IdField
    Nom du champ ID dans la table (défaut: dérivé du nom)

.PARAMETER IdType
    Type du champ ID (défaut: "char(6)")

.PARAMETER OutputDir
    Répertoire de sortie (défaut: src/[name])

.EXAMPLE
    .\scripts\generate_resource.ps1 -Name "product" -Table "PRODUCT"
    
.EXAMPLE
    .\scripts\generate_resource.ps1 -Name "customer" -Table "CUSTOMER" -IdType "int(10)"

.NOTES
    Version: 1.0
    Date: 28 octobre 2025
    Basé sur: src/employee (conventions validées)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [string]$Table,
    
    [Parameter(Mandatory=$false)]
    [string]$PluralName,
    
    [Parameter(Mandatory=$false)]
    [string]$IdField,
    
    [Parameter(Mandatory=$false)]
    [string]$IdType = "char(6)",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir
)

# Configuration
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)  # false = no BOM

# Fonction utilitaire pour écrire des fichiers avec le bon encodage
function Write-FileUTF8NoBOM {
    param(
        [string]$Path,
        [string]$Content
    )
    
    # Pour PowerShell 5.x, utiliser System.IO.File pour avoir UTF-8 sans BOM
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Normalisation des noms
$resourceName = $Name.ToLower()
$resourceNameUpper = $Name.ToUpper()
$tableName = $Table.ToUpper()

# Génération nom pluriel si absent
if (-not $PluralName) {
    if ($resourceName -match "y$") {
        $pluralName = $resourceName -replace "y$", "ies"
    } else {
        $pluralName = "${resourceName}s"
    }
} else {
    $pluralName = $PluralName.ToLower()
}

# Génération nom champ ID si absent
if (-not $IdField) {
    $IdField = "${resourceName}no"
}

# Répertoire de sortie
if (-not $OutputDir) {
    $OutputDir = Join-Path $projectRoot "src\$resourceName"
}

Write-Host "Generation ressource API REST" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Ressource    : $resourceName" -ForegroundColor Green
Write-Host "Table DB2    : $tableName" -ForegroundColor Green
Write-Host "Routes API   : /api/$pluralName" -ForegroundColor Green
Write-Host "Champ ID     : $IdField ($IdType)" -ForegroundColor Green
Write-Host "Destination  : $OutputDir" -ForegroundColor Green
Write-Host ""

# Créer le répertoire si nécessaire
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "OK Repertoire cree: $OutputDir" -ForegroundColor Green
}

# ============================================================================
# GÉNÉRATION MODULE MÉTIER (.sqlrpgle)
# ============================================================================

$metierContent = @"
**free

///
// Module metier $resourceNameUpper
//
// @author Generated
// @date $(Get-Date -Format "yyyy-MM-dd")
// @version 1.0.0
//
// Responsabilites:
// - Requetes SQL (CRUD)
// - Validation des donnees
// - Logique metier
// - Transformations de donnees
///

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');

/include '$resourceName.rpgleinc'
/include 'sqlStates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'cmagic.rpgleinc'
/include 'ckool.rpgleinc'

// ============================================================================
// RECHERCHE AVEC FILTRES
// ============================================================================

dcl-proc ${resourceName}_search export;
  dcl-pi *N ind;
    pContext likeDS(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pItems pointer;
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-s lLimit int(10);
  dcl-s lOffset int(10);
  dcl-s lSelect char(5000);
  dcl-s lSelCount like(lSelect);
  dcl-s lWhere like(lSelect);
  dcl-s lOrderBy like(lSelect);
  dcl-s lFirst ind;
  dcl-ds lItemFiltre likeDS(CMAGIC_filter);
  dcl-ds lItemSort likeDS(CMAGIC_sort);
  dcl-s lItems pointer;
  dcl-ds lItem likeDS(${resourceName}_item_t);
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-s dbFieldName varchar(32);
  dcl-s isNumericField ind;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields) inz;
  dcl-s lIt int(5);
  dcl-s ErrorHappened ind;

  // Initialisation
  clear pTotalCount;
  clear pItems;
  clear pErrors;
  clear lItems;
  lItems = list_create();
  clear lSupportedFields;
  clear lErrors;

  // Configuration champs supportés
  if not ${resourceName}_getSupportedFields(lSupportedFields:lErrors);
    // Gérer erreur
  endif;

  // Pagination
  lLimit = pContext.pagination.perPage;
  lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
  if lLimit < 1;
    lLimit = CMAGIC_DEFAULT_LIMIT;
  endif;

  // Construction requête base
  lSelect = 'SELECT * FROM $tableName';

  // TODO: Implémenter filtres, tri, comptage, pagination
  // Voir employee.sqlrpgle pour référence complète

  // Comptage total
  lSelCount = 'SELECT COUNT(*) FROM (' + %trim(lSelect) + ') a';
  
  // TODO: Exécuter requêtes SQL avec curseurs
  
  // Finalisation
  pItems = lItems;
  pTotalCount = lCount;
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      list_dispose(lItems);
      return *off;
    endif;
end-proc;

// ============================================================================
// RÉCUPÉRATION PAR ID
// ============================================================================

dcl-proc ${resourceName}_getByID export;
  dcl-pi *N ind;
    pId likeDS(${resourceName}_detail_t.id) const;
    pDetail likeds(${resourceName}_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;

  // Initialisation
  clear pDetail;
  clear pErrors;

  // Requête SQL
  monitor;
    exec sql SELECT * INTO :pDetail
             FROM $tableName
             WHERE $IdField = :pId.code;

    if (sqlState = SQL_NOT_FOUND);
      lError.code = '${resourceNameUpper}001';
      lError.text = '$resourceNameUpper not found';
      pErrors.listError(1) = lError;
      return *off;
    elseif (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.text = 'Error retrieving $resourceName';
      pErrors.listError(1) = lError;
      CKOOL_logMessage('Error in ${resourceName}_getByID: ' + sqlState);
      return *off;
    endif;

  on-error;
    lError.code = 'EXCEPTION';
    lError.text = 'Exception in ${resourceName}_getByID';
    pErrors.listError(1) = lError;
    return *off;
  endmon;

  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// ============================================================================
// CRÉATION
// ============================================================================

dcl-proc ${resourceName}_create export;
  dcl-pi *N ind;
    pDetail likeds(${resourceName}_detail_t) const;
    pId likeDS(${resourceName}_detail_t.id);
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;

  // Initialisation
  clear pId;
  clear pErrors;

  // Validation
  if not ${resourceName}_isValid(pDetail : pErrors);
    return *off;
  endif;

  // TODO: Implémenter INSERT SQL
  // Voir employee_create pour référence

  CKOOL_logMessage('$resourceNameUpper created: ' + %trim(pId.code));
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// ============================================================================
// MISE À JOUR
// ============================================================================

dcl-proc ${resourceName}_update export;
  dcl-pi *N ind;
    pId likeDS(${resourceName}_detail_t.id) const;
    pDetail likeds(${resourceName}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);

  // Initialisation
  clear pErrors;

  // TODO: Implémenter UPDATE SQL
  // Voir employee_update pour référence

  CKOOL_logMessage('$resourceNameUpper updated: ' + %trim(pId.code));
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// ============================================================================
// SUPPRESSION
// ============================================================================

dcl-proc ${resourceName}_delete export;
  dcl-pi *N ind;
    pId likeDS(${resourceName}_detail_t.id) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);

  // Initialisation
  clear pErrors;

  // Requête SQL
  monitor;
    exec sql DELETE FROM $tableName
             WHERE $IdField = :pId.code;

    if (sqlState = SQL_NOT_FOUND);
      lError.code = '${resourceNameUpper}001';
      lError.text = '$resourceNameUpper not found';
      pErrors.listError(1) = lError;
      return *off;
    elseif (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.text = 'Error deleting $resourceName';
      pErrors.listError(1) = lError;
      return *off;
    endif;

    exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
    if lRowsAffected = 0;
      lError.code = '${resourceNameUpper}001';
      lError.text = '$resourceNameUpper not found';
      pErrors.listError(1) = lError;
      return *off;
    endif;

  on-error;
    return *off;
  endmon;

  CKOOL_logMessage('$resourceNameUpper deleted: ' + %trim(pId.code));
  return *on;

  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// ============================================================================
// VALIDATION
// ============================================================================

dcl-proc ${resourceName}_isValid export;
  dcl-pi *N ind;
    pDetail likeds(${resourceName}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  dcl-ds lError likeds(errorItem) inz;

  // Initialisation
  clear pErrors;

  // TODO: Ajouter validations métier spécifiques

  return *on;
end-proc;

// ============================================================================
// CONFIGURATION CHAMPS SUPPORTÉS
// ============================================================================

dcl-proc ${resourceName}_getSupportedFields export;
  dcl-pi *N ind;
    pSupportedFields likeDS(CMAGIC_supportedFields);
    pErrors likeDS(GLOBAL_listError);
  end-pi;

  // Initialisation
  clear pSupportedFields;

  // TODO: Configurer mapping champs API → SQL
  // Exemple:
  // pSupportedFields.supportedFields(1).name = 'id';
  // pSupportedFields.supportedFields(1).sqlField = '$IdField';
  // pSupportedFields.supportedFields(1).dataType = typeChamp.STRING;

  return *on;
end-proc;
"@

$metierFile = Join-Path $OutputDir "$resourceName.sqlrpgle"
Write-FileUTF8NoBOM -Path $metierFile -Content $metierContent
Write-Host "OK Genere: $resourceName.sqlrpgle" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION MODULE REST (.rest.sqlrpgle)
# ============================================================================

$restContent = @"
**free

///
// Module REST $resourceNameUpper
//
// @author Generated
// @date $(Get-Date -Format "yyyy-MM-dd")
// @version 1.0.0
//
// Responsabilités:
// - Parse requêtes HTTP
// - Génération JSON
// - Gestion erreurs HTTP
// - Appels modules métier
///

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC':'CREST');

/include 'ileastic/ileastic.rpgle'
/include '$resourceName.rpgleinc'
/include '${resourceName}rest.rpgleinc'
/include 'ckool.rpgleinc'
/include 'crest.rpgleinc'
/include 'llist/llist_h.rpgle'

// ============================================================================
// GET COLLECTION
// ============================================================================

dcl-proc ${resourceName}_getlist_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;

  dcl-ds lErrors likeDS(GLOBAL_listError);
  dcl-ds lContext likeDS(CMAGIC_context) inz;
  dcl-s lTotalCount like(CMAGIC_totalCount);
  dcl-s lItems pointer;
  dcl-ds lSupportedFields likeds(CMAGIC_supportedFields);

  // Configuration champs supportés
  clear lSupportedFields;
  clear lErrors;
  if not ${resourceName}_getSupportedFields(lSupportedFields:lErrors);
  endif;

  // Initialisation REST
  if (not CREST_initRestRequest(request : lSupportedFields
                                : response : lContext));
    return;
  endif;

  // Appel métier
  monitor;
    if ${resourceName}_search(lContext : lTotalCount : lItems : lErrors);
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      
      CREST_addHeaders(response : lTotalCount);
      
      il_responseWrite(response : ${pluralName}ToJson(lItems : lTotalCount));
    else;
      response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
      il_responseWrite(response : '{"error":"Search failed"}');
    endif;
  on-error;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : '{"error":"Exception during search"}');
  endmon;

  on-exit;
    if (lItems <> *null);
      list_clear(lItems);
    endif;
end-proc;

// ============================================================================
// GET ITEM
// ============================================================================

dcl-proc ${resourceName}_getone_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;

  dcl-ds lId likeDS(${resourceName}_detail_t.id);
  dcl-ds lDetail likeds(${resourceName}_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);

  // Validation REST
  if (not CREST_initSimpleRestRequest(request : response));
    return;
  endif;

  // Récupération ID
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : '{"error":"Invalid $resourceName id"}');
    return;
  endif;

  lId.code = cId;

  if ${resourceName}_getByID(lId : lDetail : lErrors);
    response.status = IL_HTTP_OK;
    response.contentType = IL_MEDIA_TYPE_JSON;
    il_responseWrite(response : ${resourceName}ToJson(lDetail));
  else;
    response.status = IL_HTTP_NOT_FOUND;
    il_responseWrite(response : '{"error":"No $resourceName with id ' + cId + '"}');
  endif;
end-proc;

// ============================================================================
// POST CREATE
// ============================================================================

dcl-proc ${resourceName}_create_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;

  dcl-ds lDetail likeds(${resourceName}_detail_t);
  dcl-ds lId likeDS(${resourceName}_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s create ind;

  // Validation REST
  if (not CREST_initWriteRestRequest(request : response));
    return;
  endif;

  // Parse JSON
  lDetail = jsonTo${resourceNameUpper}(il_getRequestContent(request));
  create = (%len(%trim(lDetail.id.code)) = 0);

  monitor;
    if ${resourceName}_create(lDetail : lId : lErrors);
      lDetail.id = lId;
      
      exec sql COMMIT;
      
      if (create);
        response.status = IL_HTTP_CREATED;
      else;
        response.status = IL_HTTP_OK;
      endif;

      response.contentType = IL_MEDIA_TYPE_JSON;
      il_responseWrite(response : ${resourceName}ToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;

// ============================================================================
// PUT UPDATE
// ============================================================================

dcl-proc ${resourceName}_update_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;

  dcl-ds lId likeDS(${resourceName}_detail_t.id);
  dcl-ds lDetail likeds(${resourceName}_detail_t);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);

  // Validation REST
  if (not CREST_initWriteRestRequest(request : response));
    return;
  endif;

  // Récupération ID
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : '{"error":"Invalid $resourceName id"}');
    return;
  endif;

  lId.code = cId;

  // Parse JSON
  lDetail = jsonTo${resourceNameUpper}(il_getRequestContent(request));
  lDetail.id.code = cId;

  monitor;
    if ${resourceName}_update(lId : lDetail : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      CREST_addHeaders(response);
      il_responseWrite(response : ${resourceName}ToJson(lDetail));
    else;
      response.status = IL_HTTP_BAD_REQUEST;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;

// ============================================================================
// DELETE
// ============================================================================

dcl-proc ${resourceName}_delete_rest export;
  dcl-pi *N;
    request likeds(IL_request);
    response likeds(IL_response);
  end-pi;

  dcl-ds lId likeDS(${resourceName}_detail_t.id);
  dcl-ds lErrors likeDS(GLOBAL_listError) inz;
  dcl-s cId varchar(10);

  // Validation REST
  if (not CREST_initSimpleRestRequest(request : response));
    return;
  endif;

  // Récupération ID
  cId = il_getPathParameter(request : 'id' : '');
  if (%len(%trim(cId)) = 0);
    response.status = IL_HTTP_BAD_REQUEST;
    il_responseWrite(response : '{"error":"Invalid $resourceName id"}');
    return;
  endif;

  lId.code = cId;

  monitor;
    if ${resourceName}_delete(lId : lErrors);
      exec sql COMMIT;
      
      response.status = IL_HTTP_OK;
      response.contentType = IL_MEDIA_TYPE_JSON;
      il_responseWrite(response : '{"message":"$resourceNameUpper deleted"}');
    else;
      response.status = IL_HTTP_NOT_FOUND;
      il_responseWrite(response : CREST_errorsToJson(lErrors));
    endif;
  on-error;
    exec sql ROLLBACK;
    response.status = IL_HTTP_INTERNAL_SERVER_ERROR;
    il_responseWrite(response : CREST_simpleError('Internal server error'));
  endmon;
end-proc;

// ============================================================================
// TODO: Implémenter fonctions de conversion JSON
// ============================================================================
// - ${pluralName}ToJson(lItems : lTotalCount)
// - ${resourceName}ToJson(lDetail)
// - jsonTo${resourceNameUpper}(jsonString)
"@

$restFile = Join-Path $OutputDir "$resourceName.rest.sqlrpgle"
Write-FileUTF8NoBOM -Path $restFile -Content $restContent
Write-Host "OK Genere: $resourceName.rest.sqlrpgle" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION MODULE ROUTES (.route.sqlrpgle)
# ============================================================================

$routeContent = @"
**free

///
// Module Routes $resourceNameUpper
//
// @author Generated
// @date $(Get-Date -Format "yyyy-MM-dd")
// @version 1.0.0
//
// Responsabilités:
// - Configuration routes ILEastic
// - Mapping URL → Handler
///

ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL':'ILEASTIC');

/include 'ileastic/ileastic.rpgle'
/include '$resourceName.rpgleinc'
/include '${resourceName}rest.rpgleinc'
/include '${resourceName}route.rpgleinc'
/include 'ckool.rpgleinc'

// ============================================================================
// CONFIGURATION ROUTES
// ============================================================================

dcl-proc ${resourceName}_setupRoutes export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;

  // Routes CRUD standard
  il_addRoute(config : %paddr('${resourceName}_getlist_rest')
    : IL_GET : '^/api/$pluralName/?$');
  il_addRoute(config : %paddr('${resourceName}_getone_rest')
    : IL_GET : '^/api/$pluralName/{id}$');
  il_addRoute(config : %paddr('${resourceName}_create_rest')
    : IL_POST : '^/api/$pluralName/?$');
  il_addRoute(config : %paddr('${resourceName}_update_rest')
    : IL_PUT : '^/api/$pluralName/{id}$');
  il_addRoute(config : %paddr('${resourceName}_delete_rest')
    : IL_DELETE : '^/api/$pluralName/{id}$');

end-proc;

// ============================================================================
// ENREGISTREMENT API
// ============================================================================

dcl-proc ${resourceName}_registerAPI export;
  dcl-pi *N;
    config likeds(il_config);
  end-pi;

  // Setup routes
  ${resourceName}_setupRoutes(config);

  // Log
  CKOOL_logMessage('$resourceNameUpper API routes registered successfully');

end-proc;
"@

$routeFile = Join-Path $OutputDir "$resourceName.route.sqlrpgle"
Write-FileUTF8NoBOM -Path $routeFile -Content $routeContent
Write-Host "OK Genere: $resourceName.route.sqlrpgle" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION INCLUDES (.rpgleinc)
# ============================================================================

$includeContent = @"
**free
/if defined(${resourceNameUpper}_H_DEFINED)
/eof
/endif
/define ${resourceNameUpper}_H_DEFINED

/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'

// ============================================================================
// STRUCTURES DE DONNÉES
// ============================================================================

///
// $resourceNameUpper Detail template
///
dcl-ds ${resourceName}_detail_t template qualified;
  dcl-ds id;
    code $IdType;
  end-ds;
  // TODO: Ajouter autres champs selon structure table $tableName
end-ds;

///
// $resourceNameUpper List Item template
///
dcl-ds ${resourceName}_item_t template qualified;
  id likeDS(${resourceName}_detail_t.id);
  // TODO: Ajouter champs affichage liste
end-ds;

// ============================================================================
// PROTOTYPES - MODULE MÉTIER
// ============================================================================

///
// Search ${resourceNameUpper}s
//
// @param **in**  context (pagination,sort,filter)
// @param **out** totalCount count of items found
// @param **out** items pointer to linked list
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_search ind extproc(*dclcase);
  context likeDS(CMAGIC_context) const;
  totalCount like(CMAGIC_totalCount);
  items pointer;
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Get $resourceNameUpper by ID
//
// @param **in**  id $resourceNameUpper ID
// @param **out** detail $resourceNameUpper detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_getByID ind extproc(*dclcase);
  id likeDS(${resourceName}_detail_t.id) const;
  detail likeds(${resourceName}_detail_t);
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Create $resourceNameUpper
//
// @param **in**  detail $resourceNameUpper detail
// @param **out** id generated ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_create ind extproc(*dclcase);
  detail likeds(${resourceName}_detail_t) const;
  id likeDS(${resourceName}_detail_t.id);
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Update $resourceNameUpper
//
// @param **in**  id $resourceNameUpper ID
// @param **in**  detail $resourceNameUpper detail
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_update ind extproc(*dclcase);
  id likeDS(${resourceName}_detail_t.id) const;
  detail likeds(${resourceName}_detail_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Delete $resourceNameUpper
//
// @param **in**  id $resourceNameUpper ID
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_delete ind extproc(*dclcase);
  id likeDS(${resourceName}_detail_t.id) const;
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Validate $resourceNameUpper
//
// @param **in**  detail $resourceNameUpper detail
// @param **out** errors list of errors
// @return *on if valid, *off if invalid
///
dcl-pr ${resourceName}_isValid ind extproc(*dclcase);
  detail likeds(${resourceName}_detail_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Get supported fields configuration
//
// @param **out** supportedFields fields configuration
// @param **out** errors list of errors
// @return *on if ok, *off if error
///
dcl-pr ${resourceName}_getSupportedFields ind extproc(*dclcase);
  supportedFields likeDS(CMAGIC_supportedFields);
  errors likeDS(GLOBAL_listError);
end-pr;
"@

$includeFile = Join-Path $projectRoot "includes\$resourceName.rpgleinc"
Write-FileUTF8NoBOM -Path $includeFile -Content $includeContent
Write-Host "OK Genere: includes\$resourceName.rpgleinc" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION BINDING SOURCE (.bnd)
# ============================================================================

$bindingContent = @"
STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('${resourceNameUpper}.1.0.0')
  EXPORT SYMBOL('${resourceName}_search')
  EXPORT SYMBOL('${resourceName}_getByID')
  EXPORT SYMBOL('${resourceName}_create')
  EXPORT SYMBOL('${resourceName}_update')
  EXPORT SYMBOL('${resourceName}_delete')
  EXPORT SYMBOL('${resourceName}_isValid')
  EXPORT SYMBOL('${resourceName}_getSupportedFields')
ENDPGMEXP
"@

$bindingFile = Join-Path $OutputDir "$resourceName.bnd"
Write-FileUTF8NoBOM -Path $bindingFile -Content $bindingContent
Write-Host "OK Genere: $resourceName.bnd" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION Rules.mk
# ============================================================================

$rulesContent = @"
# Generated Rules.mk for $resourceName resource
# Date: $(Get-Date -Format "yyyy-MM-dd")

RESOURCE = $resourceName
MODULES = `$(RESOURCE) `$(RESOURCE).rest `$(RESOURCE).route

# Service program
`$(RESOURCE).SRVPGM: `$(MODULES:%=%.MODULE)
	system "CRTSRVPGM SRVPGM(`$(BIN_LIB)/${resourceNameUpper}) +
	        MODULE(`$(BIN_LIB)/${resourceNameUpper} +
	               `$(BIN_LIB)/${resourceNameUpper}REST +
	               `$(BIN_LIB)/${resourceNameUpper}ROUTE) +
	        EXPORT(*ALL) +
	        BNDSRVPGM((ILEASTIC) (CMAGIC) (CKOOL) (CREST)) +
	        TEXT('Service Program $resourceNameUpper')"

# Modules individuels
`$(RESOURCE).MODULE: `$(RESOURCE).sqlrpgle
	system "CRTRPGMOD MODULE(`$(BIN_LIB)/${resourceNameUpper}) +
	        SRCSTMF('`$(SRC)/`$(RESOURCE)/`$(RESOURCE).sqlrpgle') +
	        DBGVIEW(*SOURCE)"

`$(RESOURCE).rest.MODULE: `$(RESOURCE).rest.sqlrpgle
	system "CRTRPGMOD MODULE(`$(BIN_LIB)/${resourceNameUpper}REST) +
	        SRCSTMF('`$(SRC)/`$(RESOURCE)/`$(RESOURCE).rest.sqlrpgle') +
	        DBGVIEW(*SOURCE)"

`$(RESOURCE).route.MODULE: `$(RESOURCE).route.sqlrpgle
	system "CRTRPGMOD MODULE(`$(BIN_LIB)/${resourceNameUpper}ROUTE) +
	        SRCSTMF('`$(SRC)/`$(RESOURCE)/`$(RESOURCE).route.sqlrpgle') +
	        DBGVIEW(*SOURCE)"

.PHONY: clean
clean:
	-system "DLTMOD MODULE(`$(BIN_LIB)/${resourceNameUpper})"
	-system "DLTMOD MODULE(`$(BIN_LIB)/${resourceNameUpper}REST)"
	-system "DLTMOD MODULE(`$(BIN_LIB)/${resourceNameUpper}ROUTE)"
	-system "DLTSRVPGM SRVPGM(`$(BIN_LIB)/${resourceNameUpper})"
"@

$rulesFile = Join-Path $OutputDir "Rules.mk"
Write-FileUTF8NoBOM -Path $rulesFile -Content $rulesContent
Write-Host "OK Genere: Rules.mk" -ForegroundColor Green

# ============================================================================
# GÉNÉRATION README
# ============================================================================

$readmeContent = @"
# API REST $resourceNameUpper

> **Ressource générée automatiquement** le $(Get-Date -Format "yyyy-MM-dd")

## 📋 Configuration

- **Table DB2**: ``$tableName``
- **Champ ID**: ``$IdField`` (``$IdType``)
- **Routes API**: ``/api/$pluralName``

## 🛣️ Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | ``/api/$pluralName`` | Liste avec pagination/filtres |
| GET | ``/api/$pluralName/{id}`` | Détail par ID |
| POST | ``/api/$pluralName`` | Création |
| PUT | ``/api/$pluralName/{id}`` | Mise à jour |
| DELETE | ``/api/$pluralName/{id}`` | Suppression |

## 📝 TODO

### 1. Compléter Structures de Données

Éditer ``includes/$resourceName.rpgleinc`` pour ajouter tous les champs:

``````rpg
dcl-ds ${resourceName}_detail_t template qualified;
  dcl-ds id;
    code $IdType;
  end-ds;
  // TODO: Ajouter champs de la table $tableName
  field1 varchar(50);
  field2 packed(9:2);
  // ...
end-ds;
``````

### 2. Implémenter SQL dans Module Métier

``$resourceName.sqlrpgle``:
- Compléter ``${resourceName}_search`` avec filtres/tri/pagination
- Implémenter ``${resourceName}_create`` avec INSERT
- Implémenter ``${resourceName}_update`` avec UPDATE
- Configurer ``${resourceName}_getSupportedFields`` (mapping API ↔ SQL)

**Référence**: ``src/employee/employee.sqlrpgle``

### 3. Implémenter Conversion JSON

Créer includes séparé pour fonctions JSON:
- ``${pluralName}ToJson(items : totalCount)`` → JSON array
- ``${resourceName}ToJson(detail)`` → JSON object
- ``jsonTo${resourceNameUpper}(jsonString)`` → structure

**Référence**: Voir ``emprest.rpgleinc``

### 4. Compiler

``````bash
cd /path/to/project
makei build -l src/$resourceName
``````

### 5. Enregistrer Routes

Ajouter dans le serveur principal:

``````rpg
/include '${resourceName}route.rpgleinc'

// Dans la configuration serveur:
${resourceName}_registerAPI(config);
``````

### 6. Tester

``````bash
# Collection
curl "http://server:44000/api/$pluralName?_page=1&_limit=10"

# Item
curl "http://server:44000/api/$pluralName/{id}"

# Création
curl -X POST "http://server:44000/api/$pluralName" \
  -H "Content-Type: application/json" \
  -d '{"field1": "value"}'

# Mise à jour
curl -X PUT "http://server:44000/api/$pluralName/{id}" \
  -H "Content-Type: application/json" \
  -d '{"field1": "new_value"}'

# Suppression
curl -X DELETE "http://server:44000/api/$pluralName/{id}"
``````

## 📚 Documentation

- **Guide RPG**: ``ressources/docs/guides/guide_rpg_bonnes_pratiques.md``
- **Conventions**: ``ressources/docs/guides/CONVENTIONS_REELLES_EXTRAITES.md``
- **Référence**: ``src/employee/*`` (code validé)

---

**Généré par**: ``scripts/generate_resource.ps1``
"@

$readmeFile = Join-Path $OutputDir "README.md"
Write-FileUTF8NoBOM -Path $readmeFile -Content $readmeContent
Write-Host "OK Genere: README.md" -ForegroundColor Green

# ============================================================================
# RÉSUMÉ
# ============================================================================

Write-Host ""
Write-Host "Generation terminee avec succes!" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers generes:" -ForegroundColor Cyan
Write-Host "  • $resourceName.sqlrpgle (module métier)" -ForegroundColor White
Write-Host "  • $resourceName.rest.sqlrpgle (module REST)" -ForegroundColor White
Write-Host "  • $resourceName.route.sqlrpgle (routes)" -ForegroundColor White
Write-Host "  • includes\$resourceName.rpgleinc (structures)" -ForegroundColor White
Write-Host "  • $resourceName.bnd (binding source)" -ForegroundColor White
Write-Host "  • Rules.mk (configuration build)" -ForegroundColor White
Write-Host "  • README.md (documentation)" -ForegroundColor White
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Yellow
Write-Host "  1. Editer includes\$resourceName.rpgleinc (ajouter champs)" -ForegroundColor White
Write-Host "  2. Completer SQL dans $resourceName.sqlrpgle" -ForegroundColor White
Write-Host "  3. Implementer fonctions JSON conversion" -ForegroundColor White
Write-Host "  4. Compiler: makei build -l src/$resourceName" -ForegroundColor White
Write-Host "  5. Enregistrer routes dans serveur principal" -ForegroundColor White
Write-Host "  6. Tester avec curl/bruno" -ForegroundColor White
Write-Host ""
Write-Host "Consulter: $OutputDir\README.md" -ForegroundColor Cyan
Write-Host ""
