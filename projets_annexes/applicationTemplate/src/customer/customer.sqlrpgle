**FREE
// ============================================
// Customer Service - Code unifié (généré + manuel)
// Source : customer.cmagic
// Générée par CMagic v1.0 - Sprint 2
// ============================================
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include 'customer.rpgleinc'
// ========================================
// API PUBLIQUE - PROCÉDURES EXPORTÉES
// ========================================

// Création nouveau client
dcl-proc customer_create export;
  dcl-pi *N ind;
    pDetail likeds(customer_detail_t) const;
    pId likeDS(customer_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(customer_detail_t);
      dcl-ds lDetailAfter likeds(customer_detail_t);
      dcl-ds lId likeDS(customer_id_t);
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
        if not customer_isValid(customer_listeAction.creation
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // création métier
        clear lId;
        clear lErrors;
        if not customer_create_local(pDetail:lId:lErrors);
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

dcl-proc customer_isValid export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in customer_listeAction
    pBeforeDetail likeds(customer_detail_t) Const;
    pAfterDetail likeds(customer_detail_t) Const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear lErrors;
    // traitement
      if not customer_isValid_local(pAction
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

dcl-proc customer_getByID export;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pDetail likeds(customer_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pDetail;
      clear pErrors;
    // traitement
      if not customer_getByID_local(pId:pDetail:lErrors);
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

dcl-proc customer_change export;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pDetail likeds(customer_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(customer_detail_t);
      dcl-ds lDetailAfter likeds(customer_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la modification
      // contrôle de l'action - récupération de l'existant
        if not customer_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        lDetailAfter = pDetail;
        clear lErrors;
        if not customer_isValid_local(customer_listeAction.modification
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // modification métier
        clear lErrors;
        if not customer_change_local(pId:pDetail:lErrors);
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

dcl-proc customer_delete export;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lDetailBefore likeds(customer_detail_t);
      dcl-ds lDetailAfter likeds(customer_detail_t);
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement de la suppression
      // contrôle de l'action - récupération de l'existant
        if not customer_getByID_local(pId:lDetailBefore:lErrors);
          pErrors = lErrors;
          return *off;
        endif;
        clear lDetailAfter;
        lDetailAfter.detail.id = pId.id;
        clear lErrors;
        if not customer_isValid_local(customer_listeAction.suppression
          : lDetailBefore: lDetailAfter: lErrors);
          pErrors = lErrors;
          return *off;
        endif;
      // suppression métier
        clear lErrors;
        if not customer_delete_local(pId:lErrors);
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

dcl-proc customer_display export;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    // variables locales 
      dcl-s ErrorHappened ind;
      dcl-ds lErrors likeDS(GLOBAL_listError);
    // initialisation
      clear pErrors;
    // traitement
      if not customer_display_local(pId:lErrors);
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

dcl-proc customer_search export;
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
      if not customer_search_local(pContext:pTotalCount:pItems:lErrors);
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

// Implémentation interne - Création
dcl-proc customer_create_local;
  dcl-pi *N ind;
    pDetail likeds(customer_detail_t) const;
    pId likeDS(customer_id_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeDs(customer_t);
    dcl-ds lAdress likeDs(customer_address_t);
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
  
  // SQL query to create customer using FINAL TABLE to get the inserted record
  Exec SQL
    SELECT id
    INTO :lNewId
    FROM FINAL TABLE (
      INSERT INTO customer
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
      lError.textUser = 'Error creating customer';
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
      CKOOL_logMessage('customer created: ' + 
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

dcl-proc customer_isValid_local export;
  dcl-pi *N ind;
    pAction like(GLOBAL_codeAction) Const; // in customer_listeAction
    pBeforeDetail likeds(customer_detail_t) Const;
    pAfterDetail likeds(customer_detail_t) Const;
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
    when pAction = customer_listeAction.creation 
      or pAction = customer_listeAction.modification;
      
      // Code is mandatory
      if pAfterDetail.detail.code = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CUST001';
        pErrors.listError(it).textUser = 'Code client obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'code';
      endif;
      
      // Name is mandatory
      if pAfterDetail.detail.name = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CUST002';
        pErrors.listError(it).textUser = 'Nom client obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'name';
      endif;
      
      // Status must be valid
      if not (pAfterDetail.detail.status in customer_status);
        it += 1;
        pErrors.listError(it).code = 'CUST003';
        pErrors.listError(it).textUser = 'Statut invalide !';
        pErrors.listError(it).text = 'Valeur invalide';
        pErrors.listError(it).nomZone = 'status';
      endif;
      
      // Address ligne1 is mandatory
      if pAfterDetail.detail.address.ligne1 = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CUST004';
        pErrors.listError(it).textUser = 'Adresse ligne 1 obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'address.ligne1';
      endif;
      
      // Postal code is mandatory
      if pAfterDetail.detail.address.codepostal = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CUST005';
        pErrors.listError(it).textUser = 'Code postal obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'address.codepostal';
      endif;
      
      // City is mandatory
      if pAfterDetail.detail.address.ville = *blanks;
        it += 1;
        pErrors.listError(it).code = 'CUST006';
        pErrors.listError(it).textUser = 'Ville obligatoire !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'address.ville';
      endif;
      
      // Email format validation (basic)
      if pAfterDetail.detail.email <> *blanks
         and %scan('@': pAfterDetail.detail.email) = 0;
        it += 1;
        pErrors.listError(it).code = 'CUST007';
        pErrors.listError(it).textUser = 'Format email invalide !';
        pErrors.listError(it).text = 'Format invalide';
        pErrors.listError(it).nomZone = 'email';
      endif;
      
      // Credit limit must be positive or zero
      if pAfterDetail.detail.creditlimit < 0;
        it += 1;
        pErrors.listError(it).code = 'CUST008';
        pErrors.listError(it).textUser = 'Limite de crédit doit être positive !';
        pErrors.listError(it).text = 'Valeur invalide';
        pErrors.listError(it).nomZone = 'creditlimit';
      endif;
      
      // Creation date validation
      if pAfterDetail.detail.creationdate > %date();
        it += 1;
        pErrors.listError(it).code = 'CUST009';
        pErrors.listError(it).textUser = 'Date de création ne peut être future !';
        pErrors.listError(it).text = 'Date invalide';
        pErrors.listError(it).nomZone = 'creationdate';
      endif;
      
      
    when pAction = customer_listeAction.suppression;
      // For deletion, we only need to check if ID exists
      if pAfterDetail.detail.id = 0;
        it += 1;
        pErrors.listError(it).code = 'CUST010';
        pErrors.listError(it).textUser = 'ID client obligatoire pour suppression !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id';
      endif;
      
    when pAction = customer_listeAction.consultation;
      // For consultation, only ID is required
      if pAfterDetail.detail.id = 0;
        it += 1;
        pErrors.listError(it).code = 'CUST011';
        pErrors.listError(it).textUser = 'ID client obligatoire pour consultation !';
        pErrors.listError(it).text = 'Zone obligatoire';
        pErrors.listError(it).nomZone = 'id';
      endif;
      
    other;
      // Unknown action
      it += 1;
      pErrors.listError(it).code = 'CUST012';
      pErrors.listError(it).textUser = 'Action inconnue !';
      pErrors.listError(it).text = 'Action non supportée';
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

dcl-proc customer_getByID_local;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pDetail likeds(customer_detail_t);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  Dcl-Ds FCUSTOMER ExtName('CUSTOMER') Alias template Qualified end-ds;
  dcl-ds lDetailSQL qualified;
    id like(FCUSTOMER.id);
    code like(FCUSTOMER.code);
    name like(FCUSTOMER.name);
    addr_ligne1 like(FCUSTOMER.addr_ligne1);
    addr_ligne2 like(FCUSTOMER.addr_ligne2);
    addr_codepostal like(FCUSTOMER.addr_codepostal);
    addr_ville like(FCUSTOMER.addr_ville);
    addr_pays like(FCUSTOMER.addr_pays);
    phone like(FCUSTOMER.phone);
    email like(FCUSTOMER.email);
    status like(FCUSTOMER.status);
    creation_date like(FCUSTOMER.creation_date);
    credit_limit like(FCUSTOMER.credit_limit);
    is_vip like(FCUSTOMER.is_vip);
  end-ds;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pDetail;
  clear pErrors;
  
  // SQL query to get customer by ID
  Exec SQL
    SELECT id, code, name, addr_ligne1, addr_ligne2, addr_codepostal,
           addr_ville, addr_pays, phone, email, status,
           creation_date, credit_limit, is_vip
    INTO :lDetailSQL
    FROM customer
    WHERE id = :pId.id;
  // analyse des résultats de la requête
    clear lError;
    select;
      when (sqlState = SQL_NOT_FOUND);
        lError.code = 'CUST001';
        lError.text = 'Customer not found';
        pErrors.listError(1) = lError;
        return *off;
      when (sqlState <> SQL_OK);
        lError.code = sqlState;
        lError.textUser = 'Error retrieving customer';
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
        CKOOL_logMessage('Customer found: ' + 
          %char(lDetailSQL.id) + ' - ' + 
          %trim(lDetailSQL.name));
    endsl;

  
  // Map SQL result to output structure
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

dcl-proc customer_change_local;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pDetail likeds(customer_detail_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
    dcl-ds lDetail likeDs(customer_t);
    dcl-ds lAdress likeDs(customer_address_t);
  dcl-s lVipChar char(1);
  
  // initialisation
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
  
  // SQL query to update customer
  Exec SQL
    UPDATE customer
    SET code = :lDetail.code,
        name = :lDetail.name,
        addr_ligne1 = :lAdress.ligne1,
        addr_ligne2 = :lAdress.ligne2,
        addr_codepostal = :lAdress.codepostal,
        addr_ville = :lAdress.ville,
        addr_pays = :lAdress.pays,
        phone = :lDetail.phone,
        email = :lDetail.email,
        status = :lDetail.status,
        creation_date = :lDetail.creationdate,
        credit_limit = :lDetail.creditlimit,
        is_vip = :lVipChar
    WHERE id = :pId.id;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CUST001';
      lError.text = 'Customer not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error updating customer';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'CUST001';
        lError.text = 'Customer not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Customer updated: ' + 
        %char(pId.id) + ' - ' + 
        %trim(pDetail.detail.name));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc customer_delete_local;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lRowsAffected int(10);
  
  // initialisation
  clear pErrors;
  
  // SQL query to delete customer
  Exec SQL
    DELETE FROM customer
    WHERE id = :pId.id;
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState = SQL_NOT_FOUND);
      lError.code = 'CUST001';
      lError.text = 'Customer not found';
      pErrors.listError(1) = lError;
      return *off;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error deleting customer';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      // Log the error
      CKOOL_LogError(lError);
      return *off;
    other;
      // Vérifier le nombre de lignes affectées
      exec sql GET DIAGNOSTICS :lRowsAffected = ROW_COUNT;
      if lRowsAffected = 0;
        lError.code = 'CUST001';
        lError.text = 'Customer not found';
        pErrors.listError(1) = lError;
        return *off;
      endif;
      // on continue normalement
      CKOOL_logMessage('Customer deleted: ' + 
        %char(pId.id));
  endsl;
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc customer_display_local;
  dcl-pi *N ind;
    pId likeDS(customer_id_t) const;
    pErrors likeDS(GLOBAL_listError);
  end-pi;
  
  dcl-ds lDetail likeds(customer_detail_t);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  
  // initialisation
  clear pErrors;
  clear lDetail;
  
  // Call getByID to retrieve customer details
  if not customer_getByID_local(pId : lDetail : pErrors);
    return *off;
  endif;
  
  // Display customer details (simple console output)
  CKOOL_logMessage('=== Customer Details ===');
  CKOOL_logMessage('ID: ' + %char(lDetail.detail.id));
  CKOOL_logMessage('Code: ' + %trim(lDetail.detail.code));
  CKOOL_logMessage('Name: ' + %trim(lDetail.detail.name));
  CKOOL_logMessage('Address: ' + %trim(lDetail.detail.address.ligne1));
  if lDetail.detail.address.ligne2 <> *blanks;
    CKOOL_logMessage('         ' + %trim(lDetail.detail.address.ligne2));
  endif;
  CKOOL_logMessage('         ' + %trim(lDetail.detail.address.codepostal) + ' ' +
    %trim(lDetail.detail.address.ville));
  CKOOL_logMessage('         ' + %trim(lDetail.detail.address.pays));
  if lDetail.detail.phone <> *blanks;
    CKOOL_logMessage('Phone: ' + %trim(lDetail.detail.phone));
  endif;
  if lDetail.detail.email <> *blanks;
    CKOOL_logMessage('Email: ' + %trim(lDetail.detail.email));
  endif;
  CKOOL_logMessage('Status: ' + %trim(lDetail.detail.status));
  CKOOL_logMessage('Creation Date: ' + %char(lDetail.detail.creationdate));
  CKOOL_logMessage('Credit Limit: ' + %editc(lDetail.detail.creditlimit : 'L'));
  if lDetail.detail.isvip = *on;
    CKOOL_logMessage('VIP Customer: Yes');
  else;
    CKOOL_logMessage('VIP Customer: No');
  endif;
  CKOOL_logMessage('========================');
  
  return *on;
  
  on-exit ErrorHappened;
    if ErrorHappened;
      return *off;
    endif;
end-proc;

dcl-proc customer_search_local;
  dcl-pi *N ind;
   pContext likeDS(CMAGIC_context) const;
   pTotalCount like(CMAGIC_totalCount);
   pItems pointer;
   pErrors likeDS(GLOBAL_listError);
  end-pi;
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
  dcl-ds lItem likeDS(customer_item_t);

  dcl-ds lItemSQL qualified;
    id int(10);
    code varchar(10);
    name varchar(80);
    status varchar(20);
    creation_date date;
  end-ds;
  dcl-s lCount like(CMAGIC_totalCount);
  dcl-ds lError likeds(errorItem) inz;
  dcl-s lOperateur char(4);
  dcl-s ErrorHappened ind ;
  dcl-s lPos int(5);
  dcl-s lString like(CMAGIC_filter.value);

  //initialisation
    clear pTotalCount;
    clear pItems;
    clear pErrors;
    clear lItems;
    lItems = list_create();
  // contrôle context.
   
  // limit => number of rows per page
    lLimit = pContext.pagination.perPage;
  // offset start
    lOffset = (pContext.pagination.numPage - 1) * pContext.pagination.perPage;
    if lLimit < 1;
      lLimit = CMAGIC_DEFAULT_LIMIT;
    endif;    
  // traitement 
    clear lSelect;
    lSelect = 'select id, code, name, status, creation_date ' 
            + ' from customer';
    // filtre 
    clear lWhere;
    lFirst = *on;
    for-each lItemFiltre in pContext.filter;
      if lItemFiltre.field = *blanks;
        leave;
      endif;
      if lFirst;
        lWhere = 'Where';
        lFirst = *off;
      else;
        lWhere = %trim(lWhere) + ' and' ;
      endif;
      // si %XX% => like sinon =
      clear lPos;
      clear lString;
      lString = %upper(%trim(lItemFiltre.value));
      lPos = %scan('%' :%trim(lString));
      if lPos > 0;
        lOperateur = 'like';
      else;
        lOperateur = '=';
      endif;
      lWhere = ' ' +%trim(lWhere) + ' ' + %trim(lItemFiltre.field);
      lWhere = ' ' + %trim(lWhere) + ' ' + %trim(lOperateur);
      lWhere = ' ' + %trim(lWhere) + ' ' +
      GLOBAL_QUOTE +  %trim(lString) + GLOBAL_QUOTE; 
    endfor;
    if lWhere <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lWhere); 
    endif;
    lSelCount = 'select count(*) from (' +
    %trim(lSelect) +') a';
    // DEBUG
    snd-msg *INFO ('LSELECT ' + %trim(lSelect) + '/');
    // le tri 
    clear lOrderBy;
    lFirst = *on;
    for-each lItemSort in pContext.sort;
      if lItemSort.field = *blanks;
        leave;
      endif;
      if lFirst;
        lOrderBy = 'Order by';
        lFirst = *off;
      else;
        lOrderBy = %trim(lOrderBy) + ' ,' ;
      endif;
      lOrderBy = ' ' +%trim(lOrderBy) + ' ' + %trim(lItemSort.field);
      lOrderBy = ' ' + %trim(lOrderBy) + ' ' + %trim(lItemSort.order); 
    endfor;
    if lOrderBy <> *blanks;
      lSelect = %trim(lSelect) + ' ' + 
        %trim(lOrderBy); 
    endif;
    // la requete complete avec la pagination 
    lSelect = %trim(lSelect)  + 
  ' LIMIT ' + %char(lLimit) + 
  ' OFFSET ' + %char(lOffset);
  //Prepare
    Exec sql prepare SqlStmt From :lSelect;
  //Préparation du curseur
    Exec sql declare cListe  cursor for SqlStmt;
  //Ouverture du curseur
    Exec SQL open cListe; 
    if (sqlState <> SQL_OK);
    clear lError;
    lError.code = %trim(sqlState);
    exec sql GET DIAGNOSTICS CONDITION 1 :lError.text = MESSAGE_TEXT;
    pErrors.listError(1) = lError;
    CKOOL_LogError(lError);
    return *off;
  endif;
  dow (sqlState = SQL_OK);
    //Lecture suivante du curseur
     clear lItemSQL;
    Exec SQL Fetch Next
    From cListe
    Into :lItemSQL;
    if (sqlState <> SQL_OK);
      leave;
    endif;
    // ajout de l'item dans la liste
    clear lItem;
    lItem.id = lItemSQL.id;
    lItem.name = lItemSQL.name;
    lItem.status = lItemSQL.status;
    lItem.creationdate = lItemSQL.creation_date;
    list_add(lItems: %addr(lItem): %size(lItem));
  
    enddo;
  // comptage total                                       
  //Prepare
    Exec sql prepare SqlStmt2 From :lSelCount;
  //Préparation du curseur
    Exec sql declare cCountListe  cursor for SqlStmt2;
  //Ouverture du curseur
    Exec SQL open cCountListe; 
  //Lecture suivante du curseur
    clear lCount;
    Exec SQL   FETCH cCountListe into :lCount;   

  // finalisation 
    pItems = lItems;
    pTotalCount = lCount;
    return *on;
    on-exit ErrorHappened;
      //fermeture  du curseur
      Exec SQL close cListe; 
      //fermeture  du curseur
      Exec SQL close cCountListe; 
      if ErrorHappened;
          list_dispose(lItems);
          return *off;
      endif;
end-proc;



// [CMAGIC:MANUAL_END]