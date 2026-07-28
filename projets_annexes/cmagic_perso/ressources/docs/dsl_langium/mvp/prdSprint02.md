# 🏗️ **PRD Sprint 2 - Services CRUD + Pattern Double Couche**

**Sprint :** 2/6  
**Durée :** 2 semaines  
**Objectif :** Générer les services RPG avec pattern fichier unifié et zones protégées

---

## 🎯 **Objectifs du Sprint**

### **Objectif Principal**
Transformer l'entité `Customer` en service fonctionnel avec opérations CRUD complètes et pattern d'extensibilité moderne.

### **Objectifs Spécifiques**
1. ✅ **Services CRUD** : Générer toutes les opérations de base (_create, _getByID, _update, _delete, _search)
2. ✅ **Pattern Unifié** : Un seul fichier service avec code généré + zones manuelles
3. ✅ **Namespace RPG** : API publique `customer_*` vs implémentation `customer_*`
4. ✅ **Zones Protégées** : Délimiteurs `[CMAGIC:MANUAL_START/END]` préservés
5. ✅ **Tests Intégration** : Compilation et exécution sur IBM i réel

---

## 📋 **Scope du Sprint 2**

### **✅ In Scope (Must Have)**

#### **1. Extension Grammaire DSL**
```jdl
// Nouvelles constructions supportées
entity customer {
    // ... champs Sprint 1
}

// NOUVEAU: Bloc operations
operations for customer {
    CREATE,     // Génère customer_create
    CHANGE,     // Génère customer_update
    DELETE,     // Génère customer_delete
    DISPLAY,    // Génère customer_getByID
    SEARCH      // Génère customer_search (basique)
}
```

#### **2. Artefacts Générés (Extension Sprint 1)**
```
src/customer/
├── customer.rpgleinc # ✅ Sprint 1 - Structures 🆕 Sprint 2 - Prototypes publics
├── customer.sqlrpgle # 🆕 Sprint 2 - Service unifié
├── customer.sql      # ✅ Sprint 1 - DDL
└── tests/
    └── customer.test.sqlrpgle   # 🆕 Sprint 2 - Tests unitaires RPGUNIT
```

#### **3. Pattern Fichier Unifié**
- **API Publique** : Procédures `customer_*` exportées
- **Implémentation** : Procédures `customer_*_local` non exportées
- **Zones Protégées** : `[CMAGIC:MANUAL_START/END]` préservées lors régénération
- **Délégation** : API publique → implémentation interne

#### **4. CLI Extensions**
```bash
# Nouvelles commandes Sprint 2
cmagic generate --services customer.cmagic    # Services uniquement
cmagic test customer.cmagic                   # Génère tests unitaires
cmagic compile --target=rpg src/customer/     # Test compilation
```

### **❌ Out of Scope (Won't Have)**
- 🚫 Écrans DSPF (Sprint 3)
- 🚫 Relations entre entités (Sprint 4) 
- 🚫 Workflow et machine à états (Sprint 5)
- 🚫 WORK_WITH avec subfile (Sprint 3)
- 🚫 Validation métier complexe
- 🚫 Performance optimization

---

## 📝 **Spécifications Détaillées**

### **1. Extension DSL `customer.cmagic`**

```jdl
// customer.cmagic
/ Description : Entité Customer basique pour MVP Sprint 2

// Structure réutilisable pour adresse
struct Address {
    ligne1: String(50) required,
    ligne2: String(50),
    codePostal: String(10) required,
    ville: String(50) required,
    pays: String(3) default("FR")
}

// Énumération pour statut client
enum CustomerStatus {
    ACTIVE,      // Client actif
    INACTIVE,    // Client inactif
    SUSPENDED    // Client suspendu
}

// Entité principale Customer
entity Customer {
    id: Int required,                           // Clé primaire auto-increment
    code: String(10) required unique,   // Code client unique
    name: String(80) required,                  // Raison sociale
    address: Address required,                  // Adresse complète
    phone: String(20),                         // Téléphone
    email: String(100),                        // Email
    status: CustomerStatus default(ACTIVE),     // Statut client
    creationDate: Date required,               // Date de création
    creditLimit: Decimal(15,2) default(0),    // Limite de crédit
    isVip: Boolean default(false)              // Client VIP
}
// Vue pour la liste des commandes
view item for Customer {
    id,
    name,
    status,
    creationDate
    }
```

### **2. Génération Prototypes `customer.rpgleinc`**

```rpgle
**free
// customer.rpgleinc
// ============================================
// customer headers - générée par cmagic v1.0
// source : customer.cmagic  
// date : 2024-12-20 14:30:00
// ============================================

/if defined(customer_h_defined)       
/eof                               
/endif                             
/define customer_h_defined  
/// ============================================
// includes standard
/// ============================================
/include 'cmagic.rpgleinc'
/include 'global.rpgleinc'
/include 'sqlstates.rpginc'
/include 'llist/llist_h.rpgle'
/include 'ckool.rpgleinc'
/// ========================================
// structures communes
/// ========================================

// structure address réutilisable
dcl-ds customer_address_t qualified template;
  ligne1 varchar(50);
  ligne2 varchar(50);
  codepostal varchar(10);
  ville varchar(50);
  pays varchar(3) inz('fr');
end-ds;

// structure audit réutilisable
dcl-ds audit_t qualified template;
  createdat timestamp;
  createdby char(10);
  updatedat timestamp;
  updateby char(10);
end-ds;
/// ========================================
// constantes énumération
///========================================

dcl-enum customer_status qualified;
  active 'active';
  inactive 'inactive';
  suspended 'suspended';
end-enum;

///========================================
// structures entité
///========================================

///
// structure de base customer (données métier)
///
dcl-ds customer_t qualified template;
  id int(10);
  code varchar(10);
  name varchar(80);
  address likeds(customer_address_t);
  phone varchar(20);
  email varchar(100);
  status varchar(20) 
    inz(customer_status.active);
  creationdate date;
  creditlimit packed(15:2) inz(0);
  isvip ind inz(*off);
end-ds;
///
// structure pour clé primaire
///
dcl-ds customer_id_t qualified template;
  id int(10);
end-ds;
///
// structure détaillée customer (avec métadonnées techniques)
///
dcl-ds customer_detail_t qualified template;
  // données métier héritées de customer_t
  detail likeds(customer_t);
  // métadonnées techniques
  audit likeds(audit_t);
end-ds;

///
// customer list item template (Sprint03 ???)
///
dcl-ds customer_item_t template qualified;
  id like(customer_t.id);
  name like(customer_t.name);
  status like(customer_t.status);
  creationdate like(customer_t.creationdate);
end-ds;

// ========================================
// api publique - procédures exportées
// ========================================
///
// Liste des opératinons supportées
//
dcl-enum customer_listeAction qualified;
  creation 'create';
  modification 'update';
  suppression 'delete';
  consultation 'read';
end-enum;
///
// Création d'un nouveau client
//
// Returns the id of created Customer
//
// @param Customer detail (IN)
// @param Customer ID (OUT)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_create ind extproc(*dclcase);
  detail likeds(customer_detail_t) const;
  id likeDS(customer_id_t);
  errors likeDS(GLOBAL_listError);
end-pr; 


///
// Récupération client par ID
//
// Returns a detail Customer
//
// @param Customer ID (IN)
// @param Customer detail (OUT)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_getByID ind extproc(*dclcase);
  id likeDS(customer_id_t) const;
  detail likeds(customer_detail_t);
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Mise à jour client existant
//
// Returns *on if ok, *off if error
//
// @param Customer ID (IN)
// @param Customer detail (IN)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_change ind extproc(*dclcase);
  id likeDS(customer_id_t) const;
  detail likeds(customer_detail_t) const;
  errors likeDS(GLOBAL_listError);
end-pr; 

///
// Suppression client
//
// Returns *on if ok, *off if error
//
// @param Customer ID (IN)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_delete ind extproc(*dclcase);
  id likeDS(customer_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr;

///
// Recherche clients (liste)
//
// Returns a paginate list of found customers
//  regarding the search critéria send in the context.
//
// @param (pagination,sort,filter) critérias (IN)
// @param count of item found (OUT)
// @param pointer to the linked list of item Customer (OUT)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_search ind extproc(*dclcase);
   context likeDS(CMAGIC_context) const;
   totalCount like(CMAGIC_totalCount);
   items pointer;
   errors likeDS(GLOBAL_listError);
end-pr;

///
// Validation action client.
//
// Returns a list of errors if Customer is not valid for the action
//
// @param Customer action (IN)
// @param before action (IN)
// @param after action (IN)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_isValid ind  extproc(*dclcase);
   action like(GLOBAL_codeAction) Const; // in customer_listeAction
   beforeDetail likeds(customer_detail_t) Const;
   afterDetail likeds(customer_detail_t) Const;
   errors likeDS(GLOBAL_listError);
end-pr;

///
// display  customer
//
// - calls getByID
// - display the detail Customer on screen
//
// @param Customer ID (IN)
// @param list of errors (OUT)
// @return *on if ok, *off if error
// @throws ....
// @tag Customer
// @tag CMAGIC
///
dcl-pr customer_display ind extproc(*dclcase);
  id likeDS(customer_id_t) const;
  errors likeDS(GLOBAL_listError);
end-pr; 
// ========================================
```

### **3. Service Unifié `customer.sqlrpgle`**

```rpgle
**FREE
// customer.sqlrpgle
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
```

```rpgle
// customer.bnd
STRPGMEXP  PGMLVL(*CURRENT) SIGNATURE('CUSTOMER.0.0.1')
  EXPORT SYMBOL('customer_search')
  EXPORT SYMBOL('customer_getByID')
  EXPORT SYMBOL('customer_change')
  EXPORT SYMBOL('customer_delete')
  EXPORT SYMBOL('customer_create')  
  EXPORT SYMBOL('customer_display')
  EXPORT SYMBOL('customer_isValid')  
ENDPGMEXP
```

### **4. Tests Unitaires `customer.test.sqlrpgle`**

```rpgle
**free
// customer.test.sqlrpgle
// Test program for customer management
ctl-opt nomain
        option(*nodebugio:*srcstmt:*nounref)
        alwnull(*usrctl)
        bnddir('QC2LE':'CKOOL');
/include qinclude,TESTCASE 
/include '/usr/local/include/customer.rpgleinc'

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
dcl-proc  test_customer_search_firstPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    // initialisation
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    assert(lCount = lContext.pagination.perPage
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');  
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_lastPage export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;
    // initialisation
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));
    // recherche des clients
    clear lContext;
    lContext.pagination.numPage = lLastPage;
    lContext.pagination.perPage = PERPAGE;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
    CKOOL_logMessage('Total items in list : ' + %char(lCount));
    assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_status_active export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);
    dcl-s lCount int(10);
    dcl-s lLastPage int(10);
    dcl-c PERPAGE 10;

    // initialisation
    // recherche du nombre total de clients actifs
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer where status = 'active';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    // calcul de la dernière page
    lLastPage = %div(lTotalCountExpected : PERPAGE) + 1;
    CKOOL_logMessage('Dernière page  : ' + %char(lLastPage));

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'status';
    lContext.filter(1).value = 'active';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    clear lCount;
    lCount = list_size(list);
     assert(lCount = lTotalCountExpected - (PERPAGE * (lLastPage - 1))
      : '<KO> Le nombre de clients d''une page est différent de celui attendu');
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_order_name export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lCount int(10);
    dcl-c PERPAGE 10;
    dcl-ds lItem likeds(customer_item_t) based(lItemPtr);

    // initialisation
    // recherche de l'id a trouvé.
    clear lIdExpected;
    exec sql
      select id 
      into :lIdExpected
      from (
      select id from customer 
        order by name ) limit 1 offset 3;
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du tri
    lContext.sort(1).field = 'name';
    lContext.sort(1).order = 'asc';
    CKOOL_logMessage('Ordre : ' + lContext.sort(1).field + ' = ' + lContext.sort(1).order);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    // verification troisième poste de la liste
    lItemPtr = list_get(list : 2);
    CKOOL_logMessage('Customer : ' + %char(lItem.id) + ' - ' + lItem.name);
    assert(lIdExpected = lItem.id
      : '<KO> Erreur dans le tri. Le client trouvé n''est pas celui attendu');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
end-proc;

dcl-proc  test_customer_search_name_like_TEST export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind ;
    dcl-ds lContext likeDS(CMAGIC_context) inz;
    dcl-s lTotalCount like(CMAGIC_totalCount);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s list pointer;
    dcl-s lOK ind;
    dcl-s lTotalCountExpected like(CMAGIC_totalCount) inz(0);

    // initialisation
    // recherche du nombre total de clients
    clear lTotalCountExpected;
    exec sql
      select count(*) into :lTotalCountExpected
      from customer where name like '%TEST%';
    if sqlcode <> 0;
       snd-msg *escape ('Horreur ! dans ' + %trim(%proc()) + ' : ' + %char(sqlcode));
        return;
    endif;
    CKOOL_logMessage('Expected Count: ' + %char(lTotalCountExpected));

    // recherche des clients 
    clear lContext;
    lContext.pagination.numPage = 1;
    lContext.pagination.perPage = 10;
    lContext.sort = *blanks;
    lContext.filter = *blanks;
    // ajout du filtre
    lContext.filter(1).field = 'name';
    lContext.filter(1).value = '%TEST%';
    CKOOL_logMessage('Filtre : ' + lContext.filter(1).field + ' = ' + lContext.filter(1).value);
    lOK = customer_search(lContext : lTotalCount : list : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_search');
    assert(lTotalCount = lTotalCountExpected
      : '<KO> Le nombre de clients retourné est différent de celui attendu');
    CKOOL_logMessage('retourné : ' + %char(lTotalCount));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
      list_dispose(list);           
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

dcl-proc test_customer_getByID_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    CKOOL_logMessage('Test avec client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_getByID');
    assert(lDetail.detail.id = lIdExpected
      : '<KO> L''ID du client retourné est différent de celui attendu');
    assert(lDetail.detail.name = lNameExpected
      : '<KO> Le nom du client retourné est différent de celui attendu');
    assert(lDetail.detail.code <> *blanks
      : '<KO> Le code du client devrait être renseigné');
      
    CKOOL_logMessage('Client trouvé : ' + %char(lDetail.detail.id) + ' - ' + 
                     %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
      
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_getByID_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test avec client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_getByID(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
    assert(lDetail.detail.id = 0
      : '<KO> Le détail du client devrait être vide');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_change_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lDetailOriginal likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNewName varchar(80);
    dcl-s lNewCode varchar(10);
    dcl-s lOriginalName varchar(80);
    dcl-s lOriginalCode varchar(10);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lOriginalName;
    clear lOriginalCode;
    exec sql
      select id, name, code
      into :lIdExpected, :lOriginalName, :lOriginalCode
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // récupération du détail original
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetailOriginal : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la récupération du détail original');
        return;
    endif;
    
    CKOOL_logMessage('Test modification client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lOriginalName));
    
    // préparation des nouvelles valeurs
    lNewName = 'TEST_COMPANY';
    lNewCode = 'TSTCMP';
    
    // modification des données
    lDetail = lDetailOriginal;
    lDetail.detail.name = lNewName;
    lDetail.detail.code = lNewCode;
    lDetail.detail.isvip = *on;
    
    // test de la procédure de modification
    lOK = customer_change(lId : lDetail : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_change');
    
    // vérification que la modification a bien été effectuée
    clear lDetail;
    lOK = customer_getByID(lId : lDetail : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la vérification de la modification');
    assert(lDetail.detail.name = lNewName
      : '<KO> Le nom n''a pas été modifié correctement');
    assert(lDetail.detail.code = lNewCode
      : '<KO> Le code n''a pas été modifié correctement');
    assert(lDetail.detail.isvip = *on
      : '<KO> Le statut VIP n''a pas été modifié correctement');
      
    CKOOL_logMessage('Client modifié avec succès : ' 
                     + %char(lDetail.detail.id) + ' - ' + 
                     %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
    
    // restauration des données originales
    lOK = customer_change(lId : lDetailOriginal : lErrors);
    assert(lOK = *on 
      : '<KO> Erreur lors de la restauration des données originales');
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          customer_change(lId : lDetailOriginal : lErrors);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_customer_change_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    // préparation des données à modifier
    clear lDetail;
    lDetail.detail.name = 'TEST_COMPANY';
    lDetail.detail.code = 'TSTCMP';
    lDetail.detail.address.ligne1 = '123 Test Street';
    lDetail.detail.address.ville = 'Test City';
    
    CKOOL_logMessage('Test modification client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_change(lId : lDetail : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_delete_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lDetailBackup likeds(customer_detail_t) inz;
    dcl-ds lDetailCustomer likeDs(customer_t);
    dcl-ds lAdress likeDs(customer_address_t);
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    dcl-s lVipChar char(1);
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    // sauvegarde du détail complet pour restauration
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_getByID(lId : lDetailBackup : lErrors);
    if not lOK;
       snd-msg *escape ('Erreur lors de la sauvegarde des données originales');
        return;
    endif;
    
    CKOOL_logMessage('Test suppression client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure de suppression
    lOK = customer_delete(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_delete');
    
    // vérification que le client n'existe plus
    clear lDetail;
    clear lErrors;
    lOK = customer_getByID(lId : lDetail : lErrors);
    assert(lOK = *off 
      : '<KO> Le client devrait être supprimé');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
      
    CKOOL_logMessage('Client supprimé avec succès : ' 
                     + %char(lIdExpected));
    
    // restauration des données pour ne pas affecter les autres tests
    clear lDetailCustomer;
    lDetailCustomer = lDetailBackup.detail;
    lAdress = lDetailCustomer.address;
    // Convert RPG indicator *on/*off to database 'O'/'N'
    if lDetailCustomer.isvip = *on;
      lVipChar = 'O';
    else;
      lVipChar = 'N';
    endif;
    exec sql
      INSERT INTO customer (id, code, name, addr_ligne1, addr_ligne2, 
                           addr_codepostal, addr_ville, addr_pays,
                           phone, email, status, creation_date, 
                           credit_limit, is_vip)
      VALUES (:lDetailCustomer.id, :lDetailCustomer.code, 
              :lDetailCustomer.name, :lAdress.ligne1,
              :lAdress.ligne2, :lAdress.codepostal,
              :lAdress.ville, :lAdress.pays,
              :lDetailCustomer.phone, :lDetailCustomer.email,
              :lDetailCustomer.status, :lDetailCustomer.creationdate,
              :lDetailCustomer.creditlimit, :lVipChar);
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la restauration des données : '
                         + %char(sqlcode));
    endif;
      
   on-exit ErrorHappened;
      if ErrorHappened;
        // tentative de restauration en cas d'erreur
        monitor;
          clear lDetailCustomer;
          lDetailCustomer = lDetailBackup.detail;
          lAdress = lDetailCustomer.address;
          // Convert RPG indicator *on/*off to database 'O'/'N'
          if lDetailCustomer.isvip = *on;
            lVipChar = 'O';
          else;
            lVipChar = 'N';
          endif;
          exec sql
            INSERT INTO customer (id, code, name, addr_ligne1, addr_ligne2, 
                                 addr_codepostal, addr_ville, addr_pays,
                                 phone, email, status, creation_date, 
                                 credit_limit, is_vip)
            VALUES (:lDetailCustomer.id, :lDetailCustomer.code, 
                    :lDetailCustomer.name, :lAdress.ligne1,
                    :lAdress.ligne2, :lAdress.codepostal,
                    :lAdress.ville, :lAdress.pays,
                    :lDetailCustomer.phone, :lDetailCustomer.email,
                    :lDetailCustomer.status, :lDetailCustomer.creationdate,
                    :lDetailCustomer.creditlimit, :lVipChar);
        on-error;
          // ignore les erreurs de restauration
        endmon;
      endif;
end-proc;

dcl-proc test_customer_delete_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test suppression client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_delete(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
    assert(lErrors.listError(1).code = 'CUST001'
      : '<KO> Le code d''erreur devrait être CUST001 pour client non trouvé');
    assert(lErrors.listError(1).text = 'Customer not found'
      : '<KO> Le message d''erreur devrait être "Customer not found"');
      
    CKOOL_logMessage('Erreur attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).text));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_valid export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-ds lDetailVerif likeds(customer_detail_t) inz;
    dcl-s lOK ind;
    
    // préparation des données de test
    clear lDetail;
    lDetail.detail.code = 'TST001';
    lDetail.detail.name = 'TEST COMPANY SA';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ligne2 = 'Bâtiment A';
    lDetail.detail.address.codepostal = '75001';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.pays = 'FR';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client : ' 
              + %trim(lDetail.detail.code) + ' ' + %trim(lDetail.detail.name));
    
    // test de la procédure de création
    lOK = customer_create(lDetail : lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_create');
    assert(lId.id <> 0
      : '<KO> L''ID du client créé ne devrait pas être zéro');
    
    CKOOL_logMessage('Client créé avec l''ID : ' + %char(lId.id));
    
    // vérification que le client a bien été créé
    clear lDetailVerif;
    clear lErrors;
    lOK = customer_getByID(lId : lDetailVerif : lErrors);
    assert(lOK = *on 
      : '<KO> Le client créé devrait être trouvé');
    assert(lDetailVerif.detail.code = lDetail.detail.code
      : '<KO> Le code du client créé ne correspond pas');
    assert(lDetailVerif.detail.name = lDetail.detail.name
      : '<KO> Le nom du client créé ne correspond pas');
    assert(lDetailVerif.detail.address.ville = lDetail.detail.address.ville
      : '<KO> La ville du client créé ne correspond pas');
    assert(lDetailVerif.detail.status = lDetail.detail.status
      : '<KO> Le statut du client créé ne correspond pas');
    assert(lDetailVerif.detail.creditlimit = lDetail.detail.creditlimit
      : '<KO> La limite de crédit du client créé ne correspond pas');
      
    CKOOL_logMessage('Client créé et vérifié avec succès : ' 
                     + %char(lDetailVerif.detail.id) + ' - ' + 
                     %trim(lDetailVerif.detail.code) + ' ' + %trim(lDetailVerif.detail.name));
    
   on-exit ErrorHappened;
      if ErrorHappened;
        // nettoyage : suppression du client créé en cas d'erreur
        if lId.id <> 0;
          monitor;
            customer_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      else;
        // nettoyage : suppression du client créé après test réussi
        if lId.id <> 0;
          monitor;
            customer_delete(lId : lErrors);
          on-error;
            // ignore les erreurs de nettoyage
          endmon;
        endif;
      endif;
end-proc;

dcl-proc test_customer_create_validation_error export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec des données invalides (nom vide)
    clear lDetail;
    lDetail.detail.code = 'TST002';
    lDetail.detail.name = *blanks;  // nom vide - devrait causer une erreur
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec nom vide');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un nom vide');
    assert(lErrors.listError(1).code = 'CUST002'
      : '<KO> Le code d''erreur devrait être CUST002 pour nom obligatoire');
    assert(lErrors.listError(1).textUser = 'Nom obligatoire !'
      : '<KO> Le message d''erreur devrait être "Nom obligatoire !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_invalid_creditlimit export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec une limite de crédit négative
    clear lDetail;
    lDetail.detail.code = 'TST003';
    lDetail.detail.name = 'TEST COMPANY INVALID';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'contact@testcompany.com';
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = -1000;  // limite négative - devrait causer une erreur
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec limite de crédit négative');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour une limite de crédit négative');
    assert(lErrors.listError(1).code = 'CUST008'
      : '<KO> Le code d''erreur devrait être CUST008 pour limite de crédit invalide');
    assert(lErrors.listError(1).textUser = 'Limite de crédit doit être positive !'
      : '<KO> Le message d''erreur devrait être "Limite de crédit doit être positive !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_create_invalid_email export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lDetail likeds(customer_detail_t) inz;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un email invalide
    clear lDetail;
    lDetail.detail.code = 'TST004';
    lDetail.detail.name = 'TEST COMPANY EMAIL';
    lDetail.detail.address.ligne1 = '123 rue de la Paix';
    lDetail.detail.address.ville = 'Paris';
    lDetail.detail.address.codepostal = '75011';
    lDetail.detail.phone = '+33123456789';
    lDetail.detail.email = 'invalid-email';  // email invalide - devrait causer une erreur
    lDetail.detail.status = customer_status.active;
    lDetail.detail.creationdate = %date();
    lDetail.detail.creditlimit = 50000;
    lDetail.detail.isvip = *off;
    
    CKOOL_logMessage('Test création client avec email invalide');
    
    // validation des données avant création
    lOK = customer_isValid(customer_listeAction.creation : lDetail : lDetail : lErrors);
    CKOOL_logListError(lErrors);
    SORTA(D) lErrors.listError(*).code;    
    assert(lOK = *off 
      : '<KO> La validation devrait échouer pour un email invalide');
    assert(lErrors.listError(1).code = 'CUST007'
      : '<KO> Le code d''erreur devrait être CUST007 pour email invalide');
    assert(lErrors.listError(1).textUser = 'Format email invalide !'
      : '<KO> Le message d''erreur devrait être "Format email invalide !"');
      
    CKOOL_logMessage('Erreur de validation attendue reçue : '
             + %trim(lErrors.listError(1).code) 
             + ' - ' + %trim(lErrors.listError(1).textUser));

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_display_existing export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    dcl-s lIdExpected int(10);
    dcl-s lNameExpected varchar(80);
    
    // initialisation - récupération d'un client existant
    clear lIdExpected;
    clear lNameExpected;
    exec sql
      select id, name 
      into :lIdExpected, :lNameExpected
      from customer 
      limit 1;
    if sqlcode <> 0;
       snd-msg *escape ('Erreur lors de la récupération d''un client de test : '
                         + %char(sqlcode));
        return;
    endif;
    
    CKOOL_logMessage('Test affichage client : ' 
              + %char(lIdExpected) + ' - ' + %trim(lNameExpected));
    
    // test de la procédure d'affichage
    clear lId;
    lId.id = lIdExpected;
    lOK = customer_display(lId : lErrors);
    
    assert(lOK = *on 
      : '<KO> Erreur dans l''appel de la procédure customer_display');
      
    CKOOL_logMessage('Affichage du client réussi');
      
   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

dcl-proc test_customer_display_notfound export;
    dcl-pi *N; 
    end-pi;
    dcl-s ErrorHappened ind;
    dcl-ds lId likeDS(customer_id_t) inz;
    dcl-ds lErrors likeDS(GLOBAL_listError) inz;
    dcl-s lOK ind;
    
    // test avec un ID inexistant
    clear lId;
    lId.id = 999999;  // ID qui n'existe pas
    
    CKOOL_logMessage('Test affichage client inexistant : '
                       + %char(lId.id));
    
    lOK = customer_display(lId : lErrors);
    
    assert(lOK = *off 
      : '<KO> La procédure devrait retourner *off pour un client inexistant');
      
    CKOOL_logMessage('Erreur d''affichage attendue pour client inexistant');

   on-exit ErrorHappened;
      if ErrorHappened;
      endif;
end-proc;

```
```json
// testing.json
{
    "rpgunit": {
        "rucrtrpg": {
            "tgtCcsid": "*JOB",
            "dbgView": "*SOURCE",
            "rpgPpOpt": "*LVL2",
            "cOption": [
                "*EVENTF"
            ]
        }
    },
    "codecov": {
        "module": [
            "CUSTOMER"
        ]
    }
}
```
## 5 build BoB
```yaml
// Rules.mk
CUSTOMER.MODULE: customer.sqlrpgle
CUSTOMER.SRVPGM: customer.bnd CUSTOMER.MODULE
CUSTOMER.FILE: customer.table
```
---

## ✅ **Critères d'Acceptation**

### **1. Parsing Operations**
- [ ] Parse correctement `operations for Customer { CREATE, CHANGE, ... }`
- [ ] Validation des opérations supportées (CREATE, CHANGE, DELETE, DISPLAY, SEARCH)
- [ ] Messages d'erreur si opération non supportée
- [ ] Génération des métadonnées d'opérations dans l'AST

### **2. Génération Services**
- [ ] `Customer_S.sqlrpgle` compilable sans erreur sur RPG ILE
- [ ] API publique `_Customer_*` correctement exportée  
- [ ] Zones `[CMAGIC:MANUAL_START/END]` préservées lors régénération
- [ ] Délégation API publique → implémentation interne fonctionnelle
- [ ] Prototypes dans `Customer_PR.rpgleinc` cohérents

### **3. Pattern Double Couche**
- [ ] Namespace `_Customer_*` (public) vs `Customer_*` (interne) respecté
- [ ] Procédures internes non exportées (pas dans binder language)
- [ ] Validation paramètres dans couche publique
- [ ] Logique métier dans couche interne uniquement
- [ ] Séparation claire des responsabilités

### **4. Zones Protégées**
- [ ] Régénération préserve code manuel entre délimiteurs
- [ ] Nouveau code généré n'écrase pas zones manuelles
- [ ] Délimiteurs `[CMAGIC:MANUAL_START/END]` correctement positionnés
- [ ] Merge intelligent en cas de conflit (warning si nécessaire)
- [ ] Log de génération indique zones préservées

### **5. Tests et Qualité**
- [ ] Tests unitaires `Customer_T.sqlrpgle` générés et compilables
- [ ] Tests CRUD complets avec assertions
- [ ] Tests d'intégration avec base de données réelle
- [ ] Coverage > 80% des procédures générées
- [ ] Performance acceptable (< 1s par opération CRUD)

---

## 🧪 **Plan de Test Sprint 2**

### **Tests Unitaires TypeScript**
```typescript
// tests/operations-parser.test.ts
describe('Operations Parser', () => {
  test('should parse operations block', () => {
    const source = `
      entity Customer { id: Int }
      operations for Customer { CREATE, DISPLAY }
    `;
    const ast = parseCMagic(source);
    expect(ast.operations).toHaveLength(1);
    expect(ast.operations[0].operations).toContain('CREATE');
  });
});

// tests/service-generator.test.ts
describe('Service Generator', () => {
  test('should generate complete CRUD service', () => {
    const service = generateService(customerEntity);
    expect(service).toContain('DCL-PROC _Customer_create EXPORT');
    expect(service).toContain('[CMAGIC:MANUAL_START]');
  });
});
```

### **Tests d'Intégration RPG**
1. **Compilation** : Tous les fichiers générés compilent sans erreur
2. **Exécution CRUD** : Create → Read → Update → Delete cycle complet
3. **Tests métier** : Validation des règles business (unique, required, etc.)
4. **Performance** : Mesure temps d'exécution opérations

### **Tests de Régénération**
```rpgle
// Scénario test zones protégées
1. Générer Customer_S.sqlrpgle
2. Ajouter code manuel dans [CMAGIC:MANUAL_START/END]
3. Modifier customer.cmagic 
4. Régénérer
5. ✅ Vérifier code manuel préservé
6. ✅ Vérifier nouveau code généré intégré
```

---

## 📊 **Métriques de Succès Sprint 2**

### **Métriques Techniques**
| Métrique | Cible | Mesure |
|----------|-------|--------|
| **Temps génération service** | < 2s | Customer_S.sqlrpgle complet |
| **Taille service généré** | < 500 lignes | Code lisible et maintenable |
| **Performance CRUD** | < 100ms | Opération sur table 1000 records |
| **Couverture tests** | > 85% | Tests unitaires + intégration |

### **Métriques Qualité**
- ✅ **0 erreur compilation** sur RPG ILE
- ✅ **0 régression** zones manuelles lors régénération
- ✅ **API cohérente** entre toutes les entités futures
- ✅ **Code généré** lisible et idiomatique

### **Métriques Métier**
- ✅ **CRUD complet** fonctionnel sur entité Customer
- ✅ **Pattern extensible** pour futures entités
- ✅ **Développeur** autonome sur implémentation manuelle
- ✅ **Architecture** prête pour Sprint 3 (écrans)

---

## 🎯 **Livrables Sprint 2**

### **Code Source Extensions**
- [ ] **Parser Operations** : Extension grammaire Langium
- [ ] **Service Generator** : Générateur services RPG complets
- [ ] **Template Engine** : Templates Handlebars pour services
- [ ] **Zone Protection** : Moteur de préservation code manuel
- [ ] **Test Generator** : Générateur tests unitaires RPG

### **Artefacts Customer Générés**
- [ ] **Customer_PR.rpgleinc** : Prototypes API publique
- [ ] **Customer_S.sqlrpgle** : Service CRUD complet avec zones
- [ ] **Customer_T.sqlrpgle** : Tests unitaires compilables
- [ ] **Service Binder** : Binding source pour SRVPGM

### **Documentation Sprint 2**
- [ ] **Service Pattern Guide** : Documentation pattern double couche
- [ ] **Manual Zone Tutorial** : Guide zones protégées
- [ ] **API Reference** : Documentation API Customer complète
- [ ] **Performance Guide** : Bonnes pratiques optimisation

### **Validation IBM i**
- [ ] **Compilation Tests** : Tous artefacts compilent
- [ ] **Runtime Tests** : CRUD fonctionnel en environnement réel
- [ ] **Performance Benchmark** : Mesures temps d'exécution
- [ ] **Memory Usage** : Profil consommation mémoire

---

## 🔮 **Préparation Sprint 3**

### **Architecture Écrans**
- ✅ **Service Layer** : Base solide pour écrans DSPF
- ✅ **CRUD Operations** : Prêt pour intégration UI
- ✅ **Data Structures** : Compatibles avec subfiles
- ✅ **Error Handling** : Framework d'erreurs extensible

### **Points d'Accroche Sprint 3**
- 🔗 **WORK_WITH Generator** : Infrastructure service prête
- 🔗 **Form Generators** : CREATE/CHANGE/DISPLAY basés sur services
- 🔗 **Navigation Flow** : Pattern d'appel services établi
- 🔗 **Data Binding** : Mapping structures ↔ écrans

---

**🎯 Sprint 2 transforme l'entité statique en service vivant, établissant le pattern fondamental qui sera réutilisé pour toutes les futures entités du système.**

---

## 🚀 **PLAN D'EXÉCUTION SPRINT 02**

### **📊 BILAN DE L'ÉTAT ACTUEL (Point de départ Sprint 02)**

#### **✅ Réalisé du Sprint 01 :**
1. **Grammaire Langium complète** : Entity, Struct, Enum, Field, types supportés ✅
2. **Générateur SQL fonctionnel** : DDL avec contraintes, FK, indexes ✅  
3. **Générateur RPG fonctionnel** : Copybooks .rpgleinc avec structures ✅
4. **CLI opérationnel** : `node bin/cli.js generate <file>` ✅
5. **Tests robustes** : 32 tests passent (parsing, validation, génération) ✅
6. **Artefacts générés** : SQL + RPG copybooks pour Customer/CustomerOrder ✅

#### **❌ Manque pour Sprint 02 :**
1. **Services RPG** : Pas de fichiers .sqlrpgle avec opérations CRUD ❌
2. **Grammaire `operations`** : Bloc operations not supporté dans DSL ❌
3. **Templates services** : Manque template pour services .sqlrpgle ❌
4. **API publique** : Pas de prototypes de procédures exportées ❌
5. **Zones protégées** : Système `[CMAGIC:MANUAL_START/END]` absent ❌

---

### **Phase 1: Extension Grammaire Operations (Priorité 1) - 2 jours**

#### **Tâche 1.1: Extension grammaire Langium**
- **Objectif** : Supporter le bloc `operations for EntityName { ... }`
- **Actions** :
  - Étendre `cmagic.langium` avec règle `Operations`
  - Ajouter référence entité dans Operations
  - Supporter liste d'opérations : CREATE, CHANGE, DELETE, DISPLAY, SEARCH
  - Régénérer AST avec `npm run langium:generate`
- **Tests** : Parser correctement nouvelles constructions DSL
- **Livrable** : Extension grammaire fonctionnelle ✅

```langium
// Extension dans cmagic.langium
Operations:
    'operations' 'for' entity=[Entity:ID] '{'
        (operations+=OperationType (',' operations+=OperationType)*)?
    '}';

OperationType:
    'CREATE' | 'CHANGE' | 'DELETE' | 'DISPLAY' | 'SEARCH';
```

#### **Tâche 1.2: Tests parsing operations**
- **Objectif** : Valider parsing nouvelles constructions
- **Actions** :
  - Créer `operations-parser.test.ts`
  - Test parsing bloc operations simple
  - Test validation entité référencée existe
  - Test erreurs syntaxe operations
- **Tests** : Coverage parsing operations > 90%
- **Livrable** : Suite tests operations robuste ✅

---

### **Phase 2: Générateur Services RPG (Priorité 1) - 3 jours**

#### **Tâche 2.1: Template service .sqlrpgle**
- **Objectif** : Créer template service CRUD complet
- **Actions** :
  - Créer `service.sqlrpgle.tpl` dans `/templates`
  - Pattern double couche : API publique + implémentation
  - Zones protégées `[CMAGIC:MANUAL_START/END]`
  - Helpers Handlebars pour opérations CRUD
- **Tests** : Génération service compilable
- **Livrable** : Template service fonctionnel ✅

```handlebars
{{!-- service.sqlrpgle.tpl --}}
**FREE
// ============================================
// {{name}} Service - Generated by CMagic v1.0
// Source: {{@root.sourceFile}}
// ============================================

/if not defined({{toUpperCase name}}_SERVICE)
/define {{toUpperCase name}}_SERVICE

/include '{{name}}_PR.rpgleinc'

{{#each operations}}
{{#if (eq this 'CREATE')}}
// ----------------------------------------
// CREATE Operation - Public API
// ----------------------------------------
DCL-PROC _{{../name}}_create EXPORT;
  DCL-PI *N IND;
    p{{../name}} LIKEDS({{../name}}_t) CONST;
    pErrors LIKEDS(ErrorList_t);
  END-PI;
  
  return {{../name}}_create_local(p{{../name}} : pErrors);
END-PROC;

// [CMAGIC:MANUAL_START:{{../name}}_create_validation]
// Zone manuelle pour validation métier spécifique
// [CMAGIC:MANUAL_END:{{../name}}_create_validation]

DCL-PROC {{../name}}_create_local;
  DCL-PI *N IND;
    p{{../name}} LIKEDS({{../name}}_t) CONST;
    pErrors LIKEDS(ErrorList_t);
  END-PI;
  
  // [CMAGIC:MANUAL_START:{{../name}}_create_implementation]
  // TODO: Implémentation CREATE personnalisée
  return *ON;
  // [CMAGIC:MANUAL_END:{{../name}}_create_implementation]
END-PROC;
{{/if}}
{{/each}}

/endif
```

#### **Tâche 2.2: Extension générateur principal**
- **Objectif** : Intégrer génération services dans générateur
- **Actions** :
  - Étendre `generator.ts` avec fonction `generateService`
  - Intégration template service dans pipeline
  - Génération conditionnelle si operations définies
  - Helpers Handlebars spécifiques services
- **Tests** : Service généré pour Customer avec operations
- **Livrable** : Générateur services intégré ✅

#### **Tâche 2.3: Générateur prototypes API**
- **Objectif** : Générer prototypes .rpgleinc avec API publique
- **Actions** :
  - Template `prototypes.rpgleinc.tpl`
  - Prototypes `entityname_*` exportées uniquement
  - Intégration dans copybook principal
  - Documentation prototypes générée
- **Tests** : Prototypes compilables avec service
- **Livrable** : API publique cohérente ✅

---

### **Phase 3: Système Zones Protégées (Priorité 2) - 2 jours**

#### **Tâche 3.1: Parser zones manuelles**
- **Objectif** : Préserver code manuel lors régénération
- **Actions** :
  - Fonction `parseProtectedZones()` dans utils
  - Reconnaissance délimiteurs `[CMAGIC:MANUAL_START/END]`
  - Extraction et stockage code manuel existant
  - Merge intelligent nouveau/existant
- **Tests** : Préservation code manuel lors régénération
- **Livrable** : Moteur zones protégées ✅

```typescript
// protected-zones.ts
export interface ProtectedZone {
  id: string;
  content: string;
  startLine: number;
  endLine: number;
}

export function parseProtectedZones(fileContent: string): ProtectedZone[] {
  const zones: ProtectedZone[] = [];
  const lines = fileContent.split('\n');
  
  for (let i = 0; i < lines.length; i++) {
    const startMatch = lines[i].match(/\[CMAGIC:MANUAL_START:(\w+)\]/);
    if (startMatch) {
      const zoneId = startMatch[1];
      const startLine = i;
      
      // Find matching end
      for (let j = i + 1; j < lines.length; j++) {
        if (lines[j].includes(`[CMAGIC:MANUAL_END:${zoneId}]`)) {
          zones.push({
            id: zoneId,
            content: lines.slice(i + 1, j).join('\n'),
            startLine,
            endLine: j
          });
          break;
        }
      }
    }
  }
  
  return zones;
}
```

#### **Tâche 3.2: Intégration merge intelligent**
- **Objectif** : Intégrer zones protégées dans générateur
- **Actions** :
  - Modification générateur pour utiliser zones existantes
  - Helper Handlebars `protectedZone(id, defaultContent)`
  - Logging zones préservées vs régénérées
  - Gestion conflits (warning utilisateur)
- **Tests** : Cycle complet génération → modification → régénération
- **Livrable** : Régénération sans perte code manuel ✅

---

### **Phase 4: Tests et Validation (Priorité 1) - 2 jours**

#### **Tâche 4.1: Tests générateur services**
- **Objectif** : Suite tests complète génération services
- **Actions** :
  - Tests génération Customer_S.sqlrpgle complet
  - Validation syntaxe RPG générée
  - Tests pattern double couche (public/privé)
  - Tests zones protégées multiples
- **Tests** : Coverage > 85% générateur services
- **Livrable** : Suite tests services robuste ✅

#### **Tâche 4.2: Tests intégration end-to-end**
- **Objectif** : Validation workflow complet
- **Actions** :
  - Test CLI avec nouvelles fonctionnalités
  - Génération complète Customer avec operations
  - Validation compilation RPG (si possible)
  - Tests régénération préservation code
- **Tests** : Workflow end-to-end fonctionnel
- **Livrable** : Sprint 02 validé ✅

#### **Tâche 4.3: Générateur tests unitaires RPG**
- **Objectif** : Générer tests unitaires RPG automatiquement
- **Actions** :
  - Template `tests.sqlrpgle.tpl` pour RPGUNIT
  - Tests CRUD générés automatiquement
  - Framework assertions et mock data
  - Intégration générateur principal
- **Tests** : Tests unitaires RPG compilables
- **Livrable** : Tests automatiques RPG ✅

---

### **Phase 5: Extension CLI et Documentation (Priorité 3) - 1 jour**

#### **Tâche 5.1: Extension commandes CLI**
- **Objectif** : Nouvelles commandes Sprint 02
- **Actions** :
  - `--services` flag pour génération services uniquement
  - `--tests` flag pour génération tests
  - `--preserve-manual` pour debugging zones
  - Messages informatifs génération
- **Tests** : Toutes nouvelles commandes fonctionnelles
- **Livrable** : CLI enrichi Sprint 02 ✅

#### **Tâche 5.2: Documentation et exemples**
- **Objectif** : Documentation complète Sprint 02
- **Actions** :
  - Guide pattern services double couche
  - Exemples zones manuelles
  - Bonnes pratiques API RPG
  - Migration guide Sprint 01 → 02
- **Tests** : Documentation validée par exemple concret
- **Livrable** : Documentation Sprint 02 complète ✅

---

## 📋 **Critères d'Acceptation Sprint 02 Détaillés**

### **Must Have ✅**
1. ✅ **Grammaire operations** : `operations for Customer { CREATE, DISPLAY, ... }` parsing
2. ✅ **Service Customer** : Customer_S.sqlrpgle généré avec CRUD complet
3. ✅ **API publique** : Prototypes `_Customer_*` dans Customer_PR.rpgleinc
4. ✅ **Zones protégées** : Code manuel préservé lors régénération
5. ✅ **Tests > 85%** : Coverage services + zones protégées
6. ✅ **CLI extended** : Nouvelles commandes --services, --tests

### **Should Have 📋**
- ⚠️ **Tests RPG** : Tests unitaires RPGUNIT générés automatiquement
- ⚠️ **Performance** : Génération service < 3s
- ⚠️ **Documentation** : Guide complet pattern services

### **Could Have 🎯**
- 🔄 **Validation syntax** : Vérification syntaxe RPG générée
- 🔄 **Service binding** : Génération binding source automatique
- 🔄 **Multi-operations** : Support opérations personnalisées

---

## 🧪 **Plan de Test Sprint 02 Détaillé**

### **Tests Automatiques TypeScript**
```bash
# Phase 1 - Tests parsing
npm test -- operations-parser.test.ts
npm test -- ast-operations.test.ts

# Phase 2 - Tests génération
npm test -- service-generator.test.ts  
npm test -- prototypes-generator.test.ts

# Phase 3 - Tests zones protégées
npm test -- protected-zones.test.ts
npm test -- merge-engine.test.ts

# Phase 4 - Tests intégration
npm test -- end-to-end.test.ts
npm test -- cli-extended.test.ts
```

### **Tests Manuels CLI**
```bash
# Test 1: Génération complète avec operations
echo 'entity Customer { id: Int }
operations for Customer { CREATE, DISPLAY }' > test-ops.cmagic

node bin/cli.js generate test-ops.cmagic
# ✅ Vérifier Customer_S.sqlrpgle généré

# Test 2: Zones protégées
# Modifier manuellement Customer_S.sqlrpgle (ajouter code dans zones)
node bin/cli.js generate test-ops.cmagic  
# ✅ Vérifier code manuel préservé

# Test 3: Nouvelles commandes
node bin/cli.js generate --services test-ops.cmagic
node bin/cli.js generate --tests test-ops.cmagic
# ✅ Vérifier génération sélective
```

### **Tests Validation RPG (si environnement disponible)**
```bash
# Compilation test (nécessite IBM i ou émulateur)
CRTRPGMOD MODULE(MYLIB/CUSTOMER) SRCFILE(MYLIB/QRPGSRC)
CRTSRVPGM SRVPGM(MYLIB/CUSTOMER) MODULE(MYLIB/CUSTOMER)
# ✅ Compilation sans erreur
```

---

## 📈 **Métriques Success Sprint 02**

| Métrique | Cible Sprint 02 | Mesure |
|----------|-----------------|---------|
| **Tests Coverage** | > 85% | Services + Zones protégées |
| **Temps génération** | < 3s | Service complet Customer |
| **Lignes service généré** | 300-500 | Code lisible structuré |
| **Zones protégées** | 100% | Préservation code manuel |
| **API cohérence** | 100% | Pattern `_Entity_*` respecté |

---

## 🎯 **Ordre d'Exécution Recommandé**

### **Semaine 1**
- **Jour 1-2** : Phase 1 (Grammaire operations)
- **Jour 3-5** : Phase 2 (Générateur services)

### **Semaine 2**  
- **Jour 1-2** : Phase 3 (Zones protégées)
- **Jour 3-4** : Phase 4 (Tests validation)
- **Jour 5** : Phase 5 (CLI + Documentation)

### **Validation Continue**
- Tests automatiques après chaque tâche
- Tests manuels CLI après chaque phase  
- Régression tests quotidiens
- Code review avant merge

**🎯 Ce plan transforme progressivement l'infrastructure Sprint 01 en véritable générateur de services avec pattern extensible pour tous les sprints futurs.**
