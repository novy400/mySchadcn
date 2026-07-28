# CMagic DSL — Récapitulatif des règles

CMagic est un DSL déclaratif qui décrit des applications de gestion métier et génère du code RPG ILE / SQL pour IBM i.

---

## 1. Structure générale d'un fichier `.cmagic`

Un fichier est une suite libre de blocs (dans n'importe quel ordre) :

```
Model ::= (Entity | Struct | Enum | View | Operations)*
```

Les commentaires sont supportés :
- ligne : `// commentaire`
- bloc : `/* commentaire */`

---

## 2. `entity` — Entité principale

Représente une table/objet métier. **Le nom doit commencer par une majuscule** (warning sinon).

```cmagic
entity Customer {
    id:           Int required,
    code:         String(10) required unique,
    name:         String(80) required,
    creationDate: Date required,
    creditLimit:  Decimal(15,2) default(0),
    isVip:        Boolean default(false)
}
```

> La virgule entre les champs est **optionnelle**.

---

## 3. `struct` — Structure réutilisable

Définit un type composé réutilisable comme type d'un champ.

```cmagic
struct Address {
    ligne1:     String(50) required,
    ligne2:     String(50),
    codePostal: String(10) required,
    ville:      String(50) required,
    pays:       String(3) default("FR")
}
```

Utilisation dans une `entity` :

```cmagic
entity Customer {
    address: Address required
}
```

---

## 4. `enum` — Énumération

Définit un ensemble de valeurs nommées.

```cmagic
enum CustomerStatus {
    ACTIVE,
    INACTIVE,
    SUSPENDED
}

enum OrderStatus {
    PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
}
```

Utilisation comme type d'un champ avec valeur par défaut :

```cmagic
entity Customer {
    status: CustomerStatus default(ACTIVE)
}
```

---

## 5. `view` — Vue (projection)

Définit une projection partielle d'une entité (liste de champs à exposer).

```cmagic
view item for Customer {
    id,
    name,
    status,
    creationDate
}
```

- `for` référence une `entity` existante
- La liste de champs est séparée par des virgules

---

## 6. `operations` — Opérations CRUD

Déclare les opérations disponibles pour une entité.

```cmagic
operations for Customer {
    CREATE,
    DISPLAY,
    CHANGE,
    DELETE,
    SEARCH
}
```

Opérations supportées : `CREATE` | `CHANGE` | `DELETE` | `DISPLAY` | `SEARCH`

---

## 7. Définitions de champs

```
fieldName: TypeDef [required] [unique] [default(value)]
```

### Types disponibles

| Type | Syntaxe | Exemple |
|---|---|---|
| Entier | `Int` | `id: Int` |
| Chaîne (avec taille) | `String(longueur)` | `name: String(80)` |
| Chaîne (sans taille) | `String` | `ville: String` |
| Décimal | `Decimal(précision, échelle)` | `price: Decimal(15,2)` |
| Date | `Date` | `creationDate: Date` |
| Booléen | `Boolean` | `isVip: Boolean` |
| Struct / Enum | `NomDuType` (ID) | `address: Address` |

### Modificateurs

| Mot-clé | Signification |
|---|---|
| `required` | Champ obligatoire (NOT NULL) |
| `unique` | Contrainte d'unicité |
| `default(valeur)` | Valeur par défaut |

### Valeurs `default` possibles

```cmagic
status:    CustomerStatus  default(ACTIVE)    // enum value (ID)
pays:      String(3)       default("FR")      // string littérale
credit:    Decimal(15,2)   default(0)         // number
isVip:     Boolean         default(false)     // boolean : true / false / TRUE / FALSE
```

---

## 8. Exemple complet

```cmagic
// Enums
enum OrderStatus {
    PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
}

// Struct réutilisable
struct Address {
    ligne1:     String(50) required
    codePostal: String(10) required
    ville:      String(50) required
    pays:       String(3)  default("FR")
}

// Entité principale
entity CustomerOrder {
    id:          Int           required
    orderNumber: String(20)    required unique
    customerId:  Int           required
    address:     Address
    status:      OrderStatus   default(PENDING)
    orderDate:   Date          required
    totalAmount: Decimal(15,2) default(0)
    notes:       String(500)
}

// Vue liste
view list for CustomerOrder {
    id,
    orderNumber,
    status,
    orderDate
}

// Opérations disponibles
operations for CustomerOrder {
    CREATE,
    DISPLAY,
    CHANGE,
    DELETE,
    SEARCH
}
```

---

## 9. Règles de validation

| Règle | Niveau |
|---|---|
| Le nom d'une `entity` doit commencer par une majuscule | `warning` |
| `Decimal` doit avoir exactement `(précision, échelle)` | grammaire |
| `view … for X` : `X` doit référencer une `entity` existante | grammaire (cross-ref) |
| `operations for X` : `X` doit référencer une `entity` existante | grammaire (cross-ref) |

---

## 10. Terminaux (tokens)

| Terminal | Pattern | Description |
|---|---|---|
| `ID` | `/[_a-zA-Z][\w_]*/` | Identifiant (noms d'entités, champs, enums…) |
| `NUMBER` | `/[0-9]+(\.[0-9]+)?/` | Nombre entier ou décimal |
| `STRING` | `/"[^"]*"\|'[^']*'/` | Chaîne entre guillemets doubles ou simples |
| `BOOLEAN` | `'true'\|'false'\|'TRUE'\|'FALSE'` | Valeur booléenne |
