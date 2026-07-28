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
3. ✅ **Namespace RPG** : API publique `_Customer_*` vs implémentation `Customer_*`
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
    CREATE,     // Génère _customer_create
    CHANGE,     // Génère _customer_update
    DELETE,     // Génère _customer_delete
    DISPLAY,    // Génère _customer_getByID
    SEARCH      // Génère _customer_search (basique)
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
// customer.cmagic - Version Sprint 2
struct Address {
    ligne1: String(50) required,
    ligne2: String(50),
    codePostal: String(10) required,
    ville: String(50) required,
    pays: String(3) default("FR")
}

enum CustomerStatus {
    ACTIVE, INACTIVE, SUSPENDED
}

entity Customer {
    id: Int required,
    customerCode: String(10) required unique,
    name: String(80) required,
    address: Address required,
    phone: String(20),
    email: String(100),
    status: CustomerStatus default(ACTIVE),
    creationDate: Date required,
    creditLimit: Decimal(15,2) default(0),
    isVip: Boolean default(false)
}

// NOUVEAU Sprint 2: Déclaration des opérations
operations for Customer {
    CREATE,    // Création nouveau client
    CHANGE,    // Modification client existant
    DELETE,    // Suppression client
    DISPLAY,   // Consultation client
    SEARCH     // Recherche clients (liste basique)
}
```

### **2. Génération Prototypes `customer.rpgleinc`**

```rpgle
**free
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
... # ✅ Sprint 1

/// ========================================
// structures communes
/// ========================================

... # ✅ Sprint 1
/// ========================================
// constantes énumération
///========================================

... # ✅ Sprint 1
///========================================
// structures entité
///========================================

... # ✅ Sprint 1

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
// @param **in** detail Customer detail
// @param **out**  id Customer ID
// @param **out** errors list of errors
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
// @param **in**  id Customer ID
// @param **out** detail Customer detail
// @param **out** errors list of errors
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
// @param **in**  id Customer ID
// @param **in** detail Customer detail
// @param **out** errors list of errors
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
// @param **in**  id Customer ID
// @param **out** errors list of errors
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
// @param **in**  context (pagination,sort,filter) critérias
// @param **out** itemCount count of item found based on filter critérias
// @param **out** items pointer to the linked list of item Customer
// @param **out** errors list of errors
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
// @param **in**  action Customer action
// @param **in** detail Customer detail after action
// @param **out** errors list of errors
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
// @param **in**  id Customer ID
// @param **out** errors list of errors
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
dcl-proc employee_create export;
  dcl-pi *N ind;
    pDetail likeds(employee_detail_t) const;
    pId likeDS(employee_detail_t.id);
    pErrors likeDS(GLOBAL_listError);
  end-pi;
    dcl-ds lDetailBefore likeds(employee_detail_t) const;
    dcl-ds lDetailAfter likeds(employee_detail_t) const;
    dcl-ds lId likeDS(employee_detail_t.id);
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
      if not customer_isValid(customer_listeAction.creation
        : lDetailBefore: lDetailAfter: lErrors);
        pErrors = lErrors;
        return *off;
      endif;

    lDetail = pDetail;
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

  // Logique métier pour création client
  dcl-ds lError likeds(errorItem) inz;
  dcl-s ErrorHappened ind;
  dcl-s lNewCode char(6);
  dcl-s lEdLevel int(5);
  
  // initialisation
  clear pId;
  clear pErrors;
  clear lEdLevel;
  lEdLevel = 18; 
  // SQL query to create employee using FINAL TABLE to get the inserted record
  Exec SQL
    SELECT empno
    INTO :lNewCode
    FROM FINAL TABLE (
      INSERT INTO employee
      (empno, firstnme, lastname, midinit, workdept, 
       hiredate, birthdate, sex, salary, edlevel)
      VALUES
      ((SELECT max(empno)  + 10 FROM employee), 
       :pDetail.prenom, :pDetail.nom, :pDetail.initiale, 
       :pDetail.service, :pDetail.dateEmbauche, :pDetail.dateNaissance, 
       :pDetail.genre, :pDetail.salaire, :lEdLevel)
    );
  
  // analyse des résultats de la requête
  clear lError;
  select;
    when (sqlState <> SQL_OK);
      lError.code = sqlState;
      lError.textUser = 'Error creating employee';
      lError.nomZone = %trim(%proc()) + '_'
        + 'ligne :' + GLOBAL_Pgm.SrcLineNbr;
      exec sql GET DIAGNOSTICS CONDITION 1 
      :lError.text = MESSAGE_TEXT;
      pErrors.listError(1) = lError;
      CKOOL_LogError(lError);
      return *off;
    other;
      // on continue normalement
      pId.code = lNewCode;
      CKOOL_logMessage('Employee created: ' + 
        %trim(lNewCode) + ' - ' + 
        %trim(pDetail.nom));
  endsl;

// [CMAGIC:MANUAL_END]
```

### **4. Tests Unitaires `Customer_T.sqlrpgle`**

```rpgle
**FREE
// ============================================
// Customer Service Tests
// Générée par CMagic v1.0 - Sprint 2
// ============================================

/copy CUSTOMER_H
/copy CUSTOMER_PR

// Programme de test principal
DCL-PROC CustomerTests EXPORT;
  
  // Test création client
  testCreateCustomer();
  
  // Test récupération client
  testGetCustomer();
  
  // Test mise à jour client
  testUpdateCustomer();
  
  // Test suppression client
  testDeleteCustomer();
  
END-PROC;

// Test création client
DCL-PROC testCreateCustomer;
  DCL-DS newCustomer LIKEDS(Customer_t);
  DCL-DS result LIKEDS(Customer_detail_t);
  
  // Préparation données test
  newCustomer.customerCode = 'TEST001';
  newCustomer.name = 'Client Test';
  newCustomer.address.ligne1 = '123 Rue Test';
  newCustomer.address.codePostal = '75001';
  newCustomer.address.ville = 'Paris';
  newCustomer.phone = '+33123456789';
  newCustomer.email = 'test@example.com';
  newCustomer.creationDate = %DATE();
  
  // Exécution test
  result = _Customer_create(newCustomer);
  
  // Assertions
  ASSERT(result.id > 0 : 'Customer should be created with valid ID');
  ASSERT(result.customerCode = 'TEST001' : 'Customer code should match');
  ASSERT(result.name = 'Client Test' : 'Customer name should match');
  
END-PROC;

// Utilitaire assertion simple
DCL-PROC ASSERT;
  DCL-PI *N;
    condition IND CONST;
    message VARCHAR(200) CONST;
  END-PI;
  
  IF NOT condition;
    dsply ('ASSERTION FAILED: ' + message);
  ELSE;
    dsply ('ASSERTION PASSED: ' + message);
  ENDIF;
END-PROC;
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
