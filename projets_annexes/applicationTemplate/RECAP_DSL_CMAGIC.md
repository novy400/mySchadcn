# Recap DSL CMagic

## Objectif
Le DSL CMagic sert a modeliser des entites metier IBM i, leurs vues, leurs operations standards, et leur workflow, puis a generer des artefacts RPG/SQL coherents.

## Regles principales

### 1. Entite comme concept metier
- Une `entity` represente un objet metier, pas seulement une table.
- Les metadonnees IBM i peuvent etre ajoutees via annotations (`@objectType`, `@objectSubType`, `@table`).

Exemple:
```cmagic
/**
 * @objectType '*FILE'
 * @objectSubType 'PF'
 * @table(name: 'EMPLOYEE')
 */
entity Employee {
  id: EmployeeId,
  prenom: String(12) required,
  nom: String(15) required
}
```

### 2. Types DSL a utiliser
- `entity` : modele principal
- `struct` : type composite reutilisable (adresse, id composite)
- `enum` : liste de valeurs fermee
- `view` : projection DTO pour API/ecran
- `operations` : CRUD + `WORK_WITH`
- `action` + `workflow` : logique metier et transitions d'etat

Exemple:
```cmagic
struct Address {
  ligne1: String(50) required,
  codePostal: String(10) required,
  ville: String(50) required
}

enum CustomerStatus {
  ACTIVE,
  INACTIVE,
  SUSPENDED
}

entity Customer {
  id: Int required,
  name: String(80) required,
  address: Address,
  status: CustomerStatus default(ACTIVE)
}

view item for Customer {
  id,
  name,
  status
}
```

### 3. Regles de champs
- `required` => obligatoire
- `default(...)` => valeur par defaut
- `unique` => unicite
- Les relations se font par reference d'entite
- L'id peut etre simple (`Int`, `Long`) ou composite via `struct`

Exemple id composite:
```cmagic
struct EmployeeId {
  code: String(6) required
}

entity Employee {
  id: EmployeeId,
  prenom: String(12) required,
  nom: String(15) required
}
```

### 4. Operations CUA standard
- `CREATE`, `CHANGE`, `DELETE`, `DISPLAY`
- `WORK_WITH` pour liste/recherche + actions de ligne + filtres

Exemple:
```cmagic
operations for Employee {
  CREATE,
  CHANGE,
  DELETE,
  DISPLAY,
  WORK_WITH {
    list_columns(id, prenom, nom),
    row_actions(CREATE, CHANGE, DELETE, DISPLAY),
    filters(id, prenom, nom)
  }
}
```

### 5. Workflow (machine a etats)
- Un workflow definit:
  - le champ de statut (`status_field`)
  - l'etat initial (`initial`)
  - les transitions autorisees (`transition ... from ... to ...`)
- Les transitions doivent cibler des etats definis dans l'enum.

Exemple:
```cmagic
enum OrderStatus {
  PENDING,
  CONFIRMED,
  APPROVED,
  SHIPPED,
  CANCELLED
}

workflow OrderLifecycle for CustomerOrder {
  status_field status,
  initial PENDING,

  transition 'submit' from PENDING to CONFIRMED,
  transition 'approve' from CONFIRMED to APPROVED,
  transition 'ship' from APPROVED to SHIPPED,
  transition 'cancel' from (PENDING, CONFIRMED, APPROVED) to CANCELLED
}
```

### 6. Sources de donnees (`@source`)
- `@source(db: 'TABLE.COL')` : champ mappe DB2
- `@source(api: 'Service.method')` : champ venant d'un service
- `@source(legacy: 'PGMNAME')` : champ venant d'un programme legacy
- Sans annotation, comportement par defaut base sur persistence DB2 du MVP.

Exemple:
```cmagic
entity Customer {
  id: Int required,                // @source(db: 'CUSTOMERP.CUSID')
  name: String(80),                // @source(db: 'CUSTOMERP.CUSNAM')
  creditStatus: String(20)         // @source(api: 'CreditCheckService.getStatus')
}
```

## Regles techniques CMAGIC cote RPG/REST

### 1. Contexte standard de requete
Le contexte CMAGIC contient:
- pagination
- tri
- filtres

### 2. Operateurs filtres supportes
- `=`
- `<>`
- `LIKE`
- `>=`
- `<=`
- `>`
- `<`

### 3. Hygiene et securite
- Pagination normalisee (valeurs par defaut si invalides)
- Tri whitelist (champs autorises uniquement)
- Filtres whitelist (champs autorises uniquement)
- Recherche globale `q` geree explicitement

### 4. REST standard associe
- GET collection => tableau JSON `[...]` + header `X-Total-Count`
- GET item => objet JSON `{...}`
- POST => `201 Created`
- PUT/DELETE => `200 OK`
- Parametres standards: `_page`, `_limit`, `_sort`, `_order`, `q`, `field_like`, `field_gte`, `field_lte`, `field_ne`

## Exemples disponibles dans le projet
- `src/employee/employee.cmagic`
- `src/customer/customer.cmagic`
- `includes/cmagic.rpgleinc`
- `src/cmagic/cmagic.sqlrpgle`
- `ressources/docs/dsl/docs/dsl_langium/prd_projet.md`
- `ressources/docs/dsl/docs/dsl_langium/mvp/prdMvp.md`
