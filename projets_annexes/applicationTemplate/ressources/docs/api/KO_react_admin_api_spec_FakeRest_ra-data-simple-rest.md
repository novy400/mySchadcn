# API REST FakeRest/ra-data-simple-rest - Guide Complet GET

## Format de Réponse Standard

Les réponses sont **des tableaux JSON directs** avec un header `Content-Range` obligatoire.

## 1. GET Collection - Liste Simple

### Appel basique
```
GET /posts
```

**Réponse :**
```json
[
  {
    "id": 1,
    "title": "Mon premier article",
    "content": "Contenu de l'article...",
    "author_id": 1,
    "status": "published",
    "created_at": "2023-01-15T10:30:00Z"
  },
  {
    "id": 2,
    "title": "Deuxième article",
    "content": "Autre contenu...",
    "author_id": 2,
    "status": "draft",
    "created_at": "2023-01-16T14:20:00Z"
  }
]
```

**Headers de réponse :**
```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Range: posts 0-1/2
Access-Control-Expose-Headers: Content-Range
```

## 2. GET Collection avec Paramètres

### Syntaxe générale
```
GET /[collection]?filter={...}&sort=[field,direction]&range=[start,end]&embed=[relations]
```

### 2.1 Filtrage Simple

**Filtre par égalité :**
```
GET /posts?filter={"author_id":5}
```

**Filtre multiple :**
```
GET /posts?filter={"author_id":5,"status":"published"}
```

**Recherche textuelle globale :**
```
GET /posts?filter={"q":"javascript"}
```

### 2.2 Filtres avec Opérateurs

**Supérieur ou égal (_gte) :**
```
GET /posts?filter={"views_gte":1000}
```

**Inférieur ou égal (_lte) :**
```
GET /posts?filter={"price_lte":50}
```

**Non égal (_ne) :**
```
GET /posts?filter={"status_ne":"draft"}
```

**Contient (_like) :**
```
GET /posts?filter={"title_like":"react"}
```

**Liste des opérateurs supportés :**
- `field`: égalité exacte
- `field_ne`: différent de
- `field_like`: contient (LIKE)
- `field_gte`: supérieur ou égal
- `field_lte`: inférieur ou égal
- `field_gt`: supérieur strict
- `field_lt`: inférieur strict
- `q`: recherche textuelle globale

### 2.3 Tri (Sort)

**Tri croissant :**
```
GET /posts?sort=["title","asc"]
```

**Tri décroissant :**
```
GET /posts?sort=["created_at","desc"]
```

**Exemples de tri par type de champ :**
```
GET /posts?sort=["id","asc"]           # Tri numérique croissant
GET /posts?sort=["title","desc"]       # Tri alphabétique décroissant
GET /posts?sort=["created_at","desc"]  # Tri par date décroissant
GET /posts?sort=["price","asc"]        # Tri par prix croissant
GET /posts?sort=["views","desc"]       # Tri par popularité décroissant
```

### 2.4 Pagination (Range)

**Avec paramètre range :**
```
GET /posts?range=[0,9]           # Les 10 premiers (0 à 9 inclus)
GET /posts?range=[10,19]         # Les 10 suivants (10 à 19 inclus)
GET /posts?range=[0,4]           # Les 5 premiers
```

**Avec header Range :**
```
GET /posts
Range: posts=0-9
```

**Réponse avec pagination :**
```
HTTP/1.1 206 Partial Content
Content-Range: posts 0-9/156
Content-Type: application/json

[...] // 10 éléments maximum
```

### 2.5 Relations Embarquées (Embed)

**Embarquer une relation :**
```
GET /posts?embed=["author"]
```

**Embarquer plusieurs relations :**
```
GET /posts?embed=["author","category"]
```

**Réponse avec relation embarquée :**
```json
[
  {
    "id": 1,
    "title": "Mon article",
    "author_id": 5,
    "author": {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
]
```

## 3. Combinaisons Complexes

### 3.1 Exemple Complet
```
GET /posts?filter={"status":"published","author_id":5}&sort=["created_at","desc"]&range=[0,9]&embed=["author"]
```

**Signification :**
- Articles publiés de l'auteur 5
- Triés par date de création décroissante
- Les 10 premiers résultats
- Avec les données de l'auteur embarquées

### 3.2 Recherche avec Filtres Avancés
```
GET /products?filter={"q":"smartphone","price_gte":200,"price_lte":800,"category_id":3}&sort=["price","asc"]&range=[0,19]
```

### 3.3 Filtrage par Date
```
GET /orders?filter={"created_at_gte":"2023-01-01","status_ne":"cancelled"}&sort=["created_at","desc"]
```

## 4. GET Ressource Unique

### 4.1 Par ID
```
GET /posts/123
```

**Réponse :**
```json
{
  "id": 123,
  "title": "Article spécifique",
  "content": "Contenu...",
  "author_id": 5
}
```

### 4.2 Avec Relations Embarquées
```
GET /posts/123?embed=["author","comments"]
```

**Réponse :**
```json
{
  "id": 123,
  "title": "Article spécifique",
  "author": {
    "id": 5,
    "name": "John Doe"
  },
  "comments": [
    {
      "id": 1,
      "content": "Super article !",
      "author": "Jane"
    }
  ]
}
```

## 5. Cas d'Usage par Type de Ressource

### 5.1 Articles/Posts
```
# Articles récents publiés
GET /posts?filter={"status":"published"}&sort=["created_at","desc"]&range=[0,9]

# Articles d'un auteur spécifique
GET /posts?filter={"author_id":5}&sort=["title","asc"]

# Recherche dans les articles
GET /posts?filter={"q":"javascript"}&sort=["views","desc"]
```

### 5.2 Utilisateurs
```
# Utilisateurs actifs triés par nom
GET /users?filter={"active":true}&sort=["last_name","asc"]

# Administrateurs
GET /users?filter={"role":"admin"}&sort=["created_at","desc"]

# Recherche d'utilisateurs
GET /users?filter={"q":"john"}&sort=["last_name","asc"]
```

### 5.3 Produits
```
# Produits en stock par catégorie
GET /products?filter={"category_id":2,"stock_gt":0}&sort=["name","asc"]

# Produits par gamme de prix
GET /products?filter={"price_gte":100,"price_lte":500}&sort=["price","asc"]

# Promotions
GET /products?filter={"on_sale":true}&sort=["discount_percent","desc"]
```

### 5.4 Commandes
```
# Commandes récentes
GET /orders?sort=["created_at","desc"]&range=[0,24]

# Commandes d'un client
GET /orders?filter={"customer_id":123}&sort=["created_at","desc"]

# Commandes en cours
GET /orders?filter={"status":"processing"}&sort=["priority","desc"]
```

## 6. Cas d'Erreur

### 6.1 Ressource Non Trouvée
```
GET /posts/999999
```

**Réponse :**
```
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "Not Found",
  "message": "Post with id 999999 not found"
}
```

### 6.2 Paramètres Invalides
```
GET /posts?sort=["invalid_field","asc"]
```

**Réponse :**
```
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Bad Request", 
  "message": "Invalid sort field: invalid_field"
}
```

### 6.3 Format JSON Invalide
```
GET /posts?filter={invalid_json}
```

**Réponse :**
```
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": "Bad Request",
  "message": "Invalid JSON in filter parameter"
}
```

## 7. Headers HTTP Importants

### 7.1 Requête Standard
```
GET /posts?filter={"status":"published"}&sort=["created_at","desc"]&range=[0,9]
Accept: application/json
Content-Type: application/json
```

### 7.2 Requête avec Range Header
```
GET /posts?filter={"status":"published"}&sort=["created_at","desc"]
Range: posts=0-9
Accept: application/json
```

### 7.3 Réponse avec CORS
```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Range: posts 0-9/156
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Content-Range
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

## 8. Bonnes Pratiques

### 8.1 Pagination Recommandée
```
# Éviter les grandes plages
GET /posts?range=[0,999]  # ❌ Trop lourd

# Préférer des pages raisonnables
GET /posts?range=[0,19]   # ✅ 20 éléments max
```

### 8.2 Filtres Efficaces
```
# Filtres spécifiques en premier
GET /posts?filter={"author_id":5,"status":"published"}&sort=["created_at","desc"]

# Éviter les filtres trop larges sans pagination
GET /posts?filter={"q":"the"}  # ❌ Peut retourner trop de résultats
```

### 8.3 Utilisation des Relations
```
# Embarquer seulement les relations nécessaires
GET /posts?embed=["author"]  # ✅ Relation utile

# Éviter trop de relations embarquées
GET /posts?embed=["author","comments","tags","category"]  # ❌ Peut être lourd
```

## 9. Exemples de Tests

### 9.1 Tests Basiques
```bash
# Test de base
curl "http://localhost:3000/api/posts"

# Test avec tri
curl "http://localhost:3000/api/posts?sort=[\"title\",\"asc\"]"

# Test avec filtre
curl "http://localhost:3000/api/posts?filter={\"author_id\":1}"
```

### 9.2 Tests Avancés
```bash
# Test pagination
curl -H "Range: posts=0-4" "http://localhost:3000/api/posts"

# Test complet
curl "http://localhost:3000/api/posts?filter={\"status\":\"published\"}&sort=[\"created_at\",\"desc\"]&range=[0,9]"

# Test avec embed
curl "http://localhost:3000/api/posts?embed=[\"author\"]"
```

Cette spécification couvre tous les cas d'usage possibles pour les appels GET avec FakeRest et ra-data-simple-rest, en respectant leur syntaxe officielle avec tri simple sur une colonne.