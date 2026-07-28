{{!-- src/templates/service_prd_conforme.sqlrpgle.tpl - Version Phase 3 avec validation dynamique --}}
**FREE
// ============================================
// {{name}} Service - Code unifié (généré + manuel)
// Source : {{@root.sourceFile}}
// Générée par CMagic v1.0 - Sprint 2 Phase 3 - VALIDATION DYNAMIQUE
// ============================================
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include '{{lowercase name}}.rpgleinc'

// ========================================
// API PUBLIQUE - PROCÉDURES EXPORTÉES
// ========================================

{{#each operations}}
{{#if (eq this 'CREATE')}}
// Création nouveau {{lowercase ../name}}
dcl-proc {{lowercase ../name}}_create export;
  dcl-pi *N ind;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pId likeDS({{lowercase ../name}}_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lId likeDS({{lowercase ../name}}_id_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pId;
      clear pErrors;
      clear lId;
      clear lErrors;
    // traitement de la création
      // contrôle de l'action
        clear lDetailBefore;
        clear lDetailAfter;
        clear lErrors;
        lDetailBefore = pDetail;
        lDetailAfter = pDetail;
        if not {{lowercase ../name}}_isValid({{lowercase ../name}}_listeAction.creation
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // création métier
        clear lId;
        clear lErrors;
        if not {{lowercase ../name}}_create_local(pDetail:lId:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      pId = lId;
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'DISPLAY')}}
dcl-proc {{lowercase ../name}}_display export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement
      if not {{lowercase ../name}}_display_local(pId:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'CHANGE')}}
dcl-proc {{lowercase ../name}}_change export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la modification
      // contrôle de l'action - récupération de l'existant
        if not {{lowercase ../name}}_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        lDetailAfter = pDetail;
        clear lErrors;
        if not {{lowercase ../name}}_isValid_local({{lowercase ../name}}_listeAction.modification
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // modification métier
        clear lErrors;
        if not {{lowercase ../name}}_change_local(pId:pDetail:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'DELETE')}}
dcl-proc {{lowercase ../name}}_delete export;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds({{lowercase ../name}}_detail_t);
      dcl-ds lDetailAfter likeds({{lowercase ../name}}_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la suppression
      // contrôle de l'action - récupération de l'existant
        if not {{lowercase ../name}}_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        clear lDetailAfter;
        lDetailAfter.detail.id = pId.id;
        clear lErrors;
        if not {{lowercase ../name}}_isValid_local({{lowercase ../name}}_listeAction.suppression
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // suppression métier
        clear lErrors;
        if not {{lowercase ../name}}_delete_local(pId:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
    // finalisation
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'SEARCH')}}
dcl-proc {{lowercase ../name}}_search export;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pTotalCount;
      clear pItems;
      clear pErrors;
    // traitement
      if not {{lowercase ../name}}_search_local(pContext:pTotalCount:pItems:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in {{lowercase name}}_listeAction
    pBeforeDetail likeds({{lowercase name}}_detail_t) Const;
    pAfterDetail likeds({{lowercase name}}_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear lErrors;
    // traitement
      if not {{lowercase name}}_isValid_local(pAction
              :pBeforeDetail:pAfterDetail:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc {{lowercase name}}_getByID export;
  dcl-pi *N ind;
    pId likeDS({{lowercase name}}_id_t) const;
    pDetail likeds({{lowercase name}}_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pDetail;
      clear pErrors;
    // traitement
      if not {{lowercase name}}_getByID_local(pId:pDetail:lErrors);
            pErrors = lErrors;
            return *off;
      endif; 
    // finalisation  
      return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// ========================================
// ZONE MANUELLE - PRÉSERVÉE
// ========================================
// [CMAGIC:MANUAL_START]

{{#each operations}}
{{#if (eq this 'CREATE')}}
// Implémentation interne - Création
dcl-proc {{lowercase ../name}}_create_local;
  dcl-pi *N ind;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pId likeDS({{lowercase ../name}}_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeDs({{lowercase ../name}}_t);
    dcl-ds lAdress likeDs({{lowercase ../name}}_address_t);
    dcl-ds lError likeds(errorItem) inz;
    dcl-s lNewId like(pId.id);
    dcl-s lVipChar char(1);
  
    // initialisation
    clear pId;
    clear pErrors;
    clear lDetail;
    lDetail = pDetail.detail;
    clear lAdress;
    lAdress = lDetail.address;
  
    // Convert RPG indicator *on/*off to database 'O'/'N'
    if lDetail.isvip = *on;
      lVipChar = 'O';
    else;
      lVipChar = 'N';
    endif;
  
    // SQL query to create {{lowercase ../name}} using FINAL TABLE to get the inserted record
    Exec SQL
      SELECT id
      INTO :lNewId
      FROM FINAL TABLE (
        INSERT INTO {{lowercase ../name}}
        (code, name, addr_ligne1, addr_ligne2, addr_codepostal, 
         addr_ville, addr_pays, phone, email, status, 
         creation_date, credit_limit, is_vip)
        VALUES
        (:lDetail.code, :lDetail.name, 
         :lAdress.ligne1, :lAdress.ligne2,
         :lAdress.codepostal, :lAdress.ville,
         :lAdress.pays, :lDetail.phone, 
         :lDetail.email, :lDetail.status, 
         :lDetail.creationdate, :lDetail.creditlimit, 
         :lVipChar)
      );
  
    // analyse des résultats de la requête
    clear lError;
    select;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        lError.textUser = 'Error creating {{lowercase ../name}}';
        lError.nomZone = %trim(%proc()) + '_'
          + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
        exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
        pErrors.listError(1) = lError;
        CKOOL_LogError(lError);
        return *off;
      other;
        // on continue normalement
        pId.id = lNewId;
        CKOOL_logMessage('{{lowercase ../name}} created: ' + 
          %char(lNewId) + ' - ' + 
          %trim(pDetail.detail.name));
    endsl;
      // finalisation
      return *on;
  
    on-exit ErrorHappened;
      if ErrorHappened;
        return *off;
      endif;
end-proc;
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_isValid_local export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in {{lowercase name}}_listeAction
    pBeforeDetail likeds({{lowercase name}}_detail_t) Const;
    pAfterDetail likeds({{lowercase name}}_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
      dcl-s it int(3);
    // initialisation
      clear pErrors;
    // traitement
      clear lErrors;
      clear it;
    // Validate based on action type
    select;
      when pAction = {{lowercase name}}_listeAction.creation 
        or pAction = {{lowercase name}}_listeAction.modification;
        
        // VALIDATION DYNAMIQUE BASÉE SUR LES CHAMPS RÉELS
        {{{generateFieldValidation this @root.structs}}}
        
      when pAction = {{lowercase name}}_listeAction.suppression;
        {{{generateDeleteValidation this}}}
        
      other;
        // Unknown action
        it += 1;
        pErrors.listError(it).code = 'CUST999';
        pErrors.listError(it).textUser = 'Action non supportée !';
        pErrors.listError(it).text = 'Action invalide';
        pErrors.listError(it).nomZone = 'action';
    endsl;
    
    // finalisation  
    // If errors found, return false
    if it > 0;
      return *off;
    else;
      return *on;
    endif;
    
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

{{#each operations}}
{{#if (eq this 'DISPLAY')}}
dcl-proc {{lowercase ../name}}_display_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
    dcl-ds lDetail likeds({{lowercase ../name}}_detail_t);
    dcl-ds lError likeds(errorItem) inz;
    dcl-s ErrorHappened ind;
  
    // initialisation
    clear pErrors;
    clear lDetail;
  
    // Call getByID to retrieve {{lowercase ../name}} details
    if not {{lowercase ../name}}_getByID_local(pId : lDetail : pErrors);
      return *off;
    endif;
  
    // Display {{lowercase ../name}} details (simple console output)
    CKOOL_logMessage('=== {{name}} Details ===');
    CKOOL_logMessage('ID: ' + %char(lDetail.detail.id));
    CKOOL_logMessage('Code: ' + %trim(lDetail.detail.code));
    CKOOL_logMessage('Name: ' + %trim(lDetail.detail.name));
    CKOOL_logMessage('Status: ' + %trim(lDetail.detail.status));
    CKOOL_logMessage('========================');
  
    return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;
{{/if}}

{{#if (eq this 'CHANGE')}}
dcl-proc {{lowercase ../name}}_change_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pDetail likeds({{lowercase ../name}}_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
    // TODO: Implémentation locale à personnaliser
    CLEAR pErrors;
    RETURN *ON;
end-proc;
{{/if}}

{{#if (eq this 'DELETE')}}
dcl-proc {{lowercase ../name}}_delete_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase ../name}}_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
    // TODO: Implémentation locale à personnaliser
    CLEAR pErrors;
    RETURN *ON;
end-proc;
{{/if}}

{{#if (eq this 'SEARCH')}}
dcl-proc {{lowercase ../name}}_search_local;
  dcl-pi *N ind;
    pContext likeDS(CMAGIC_context) const;
    pTotalCount like(CMAGIC_totalCount);
    pItems pointer;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
    // TODO: Implémentation locale à personnaliser
    CLEAR pTotalCount;
    CLEAR pErrors;
    pItems = *NULL;
    RETURN *ON;
end-proc;
{{/if}}
{{/each}}

dcl-proc {{lowercase name}}_getByID_local;
  dcl-pi *N ind;
    pId likeDS({{lowercase name}}_id_t) const;
    pDetail likeds({{lowercase name}}_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    Dcl-Ds F{{toUpperCase name}} ExtName('{{toUpperCase name}}') Alias template Qualified end-ds;
    dcl-ds lDetailSQL qualified;
      id like(F{{toUpperCase name}}.id);
      code like(F{{toUpperCase name}}.code);
      name like(F{{toUpperCase name}}.name);
      addr_ligne1 like(F{{toUpperCase name}}.addr_ligne1);
      addr_ligne2 like(F{{toUpperCase name}}.addr_ligne2);
      addr_codepostal like(F{{toUpperCase name}}.addr_codepostal);
      addr_ville like(F{{toUpperCase name}}.addr_ville);
      addr_pays like(F{{toUpperCase name}}.addr_pays);
      phone like(F{{toUpperCase name}}.phone);
      email like(F{{toUpperCase name}}.email);
      status like(F{{toUpperCase name}}.status);
      creation_date like(F{{toUpperCase name}}.creation_date);
      credit_limit like(F{{toUpperCase name}}.credit_limit);
      is_vip like(F{{toUpperCase name}}.is_vip);
    end-ds;
    dcl-ds lError likeds(errorItem) inz;
    dcl-s ErrorHappened ind;
  
    // initialisation
    clear pDetail;
    clear pErrors;
    clear lDetailSQL;
  
    // SQL query to retrieve {{lowercase name}} by ID
    Exec SQL
      SELECT id, code, name, addr_ligne1, addr_ligne2, 
             addr_codepostal, addr_ville, addr_pays, phone, 
             email, status, creation_date, credit_limit, is_vip
      INTO :lDetailSQL
      FROM {{lowercase name}}
      WHERE id = :pId.id;
  
    // analyse des résultats de la requête
    clear lError;
    select;
      when (sqlState = SQL_NOT_FOUND);
        lError.code = 'CUST001';
        lError.text = '{{name}} not found';
        pErrors.listError(1) = lError;
        return *off;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        lError.textUser = 'Error retrieving {{lowercase name}}';
        lError.nomZone = %trim(%proc()) + '_'
          + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
        exec sql GET DIAGNOSTICS CONDITION 1 
        :lError.text = MESSAGE_TEXT;
        pErrors.listError(1) = lError;
        // Log the error
        CKOOL_LogError(lError);
        return *off;
      other;
        // on continue normalement
        CKOOL_logMessage('{{name}} found: ' + 
          %char(lDetailSQL.id) + ' - ' + 
          %trim(lDetailSQL.name));
    endsl;
  
    // Convert SQL result to RPG structure
    pDetail.detail.id = lDetailSQL.id;
    pDetail.detail.code = lDetailSQL.code;
    pDetail.detail.name = lDetailSQL.name;
    pDetail.detail.address.ligne1 = lDetailSQL.addr_ligne1;
    pDetail.detail.address.ligne2 = lDetailSQL.addr_ligne2;
    pDetail.detail.address.codepostal = lDetailSQL.addr_codepostal;
    pDetail.detail.address.ville = lDetailSQL.addr_ville;
    pDetail.detail.address.pays = lDetailSQL.addr_pays;
    pDetail.detail.phone = lDetailSQL.phone;
    pDetail.detail.email = lDetailSQL.email;
    pDetail.detail.status = lDetailSQL.status;
    pDetail.detail.creationdate = lDetailSQL.creation_date;
    pDetail.detail.creditlimit = lDetailSQL.credit_limit;
    // Convert database 'O'/'N' to RPG indicator *on/*off
    if lDetailSQL.is_vip = 'O';
      pDetail.detail.isvip = *on;
    else;
      pDetail.detail.isvip = *off;
    endif;
  
    return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

// [CMAGIC:MANUAL_END]
