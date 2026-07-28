# Note d’architecture — Adaptateur CIWS pour IWS et CMAGIC

## Objet

Cette note décrit les choix d’architecture retenus pour exposer des programmes IBM i via Integrated Web Services (IWS) tout en conservant un contrat d’URL compatible avec un data provider de type React Admin.

Le principe retenu consiste à introduire un service program `CIWS` jouant le rôle d’adaptateur entre IWS et la couche métier existante fondée sur `CMAGIC_context`, `CMAGIC` et `service.sqlrpgle`.

## Problème à résoudre

La couche REST existante s’appuie sur ILEastic et construit le contexte métier à partir des paramètres HTTP en utilisant `CRESTinitRestRequest()` puis `parseQueryParams()`.

Dans un contexte IWS, l’objectif est de conserver les mêmes URLs, les mêmes conventions de pagination, de tri et de filtrage, sans réécrire la logique métier ni la logique SQL déjà centralisées dans `CMAGIC` et `service.sqlrpgle`.
## Choix d’architecture

Le choix principal est de créer un service program `CIWS` dédié au parsing de la `QUERY_STRING` fournie par IWS via les métadonnées de transport et récupérable par le programme ILE avec `getenv('QUERY_STRING')`.

Cette couche `CIWS` n’embarque aucune logique métier et ne produit pas directement le SQL ; elle reconstruit uniquement un `CMAGIC_context` conforme au contrat attendu par la couche existante.

L’architecture cible sépare donc clairement trois responsabilités :

- IWS pour l’exposition HTTP et le transport.
- `CIWS` pour l’adaptation HTTP vers contexte interne.
- `CMAGIC` et `service.sqlrpgle` pour la sanitization, la génération SQL et le traitement métier.

## Contrat d’URL conservé

Le contrat d’URL existant a été conservé afin d’éviter tout changement côté front et de garantir la compatibilité avec le data provider déjà en place.

Les conventions retenues sont les suivantes :

- Pagination via `page` et `perPage`, avec compatibilité complémentaire `perpage` et `limit`.
- Tri principal via `sort` et `order`, avec support complémentaire de `sort1/order1` à `sort4/order4`.
- Filtres dynamiques par suffixes : `_like`, `_gte`, `_lte`, `_gt`, `_lt`, `_ne`.
- Recherche générale via le paramètre `q`.

Ce choix permet à `CIWS` de produire le même type de contexte logique que celui construit auparavant par la couche CREST/ILEastic.

## Contrat interne stable

Le pivot de l’architecture reste `CMAGIC_context`, qui contient les composantes `pagination`, `sort(*)` et `filter(*)`.

Ce contexte est ensuite transmis à `cmagicsanitizeContext()` pour le contrôle de la whitelist des champs et à `cmagiccomputeSqlClauses()` pour la génération des clauses SQL dynamiques.

Le service métier `servicesearch()` reste inchangé : il reçoit le contexte, exécute la recherche, remplit une liste chaînée d’éléments métier et retourne également le `totalCount`.

## Responsabilités du service program CIWS

Le service program `CIWS` a été pensé comme une brique réutilisable contenant des procédures du type :

- `CIWSgetQueryString()` pour récupérer la chaîne brute issue d’IWS.
- `CIWSgetQueryParameter()` pour extraire une valeur individuelle depuis la query string.
- `CIWSparseQueryParams()` pour transformer les paramètres HTTP en `CMAGIC_context`.
- `CIWSinitRestRequest()` pour initialiser le contexte complet à transmettre à la couche métier.

L’objectif est de rendre `CIWS` générique, afin qu’il puisse être réutilisé dans plusieurs services exposés via IWS tout en conservant un comportement homogène.

## Pagination et bornes techniques

Une borne maximale de 100 éléments par page a été retenue pour simplifier le design des services, limiter la taille des réponses et faciliter la standardisation des prototypes IWS.
Cette borne est cohérente avec le choix de retourner, côté IWS, des tableaux RPG dimensionnés à 100 éléments maximum, accompagnés d’un compteur `items_LENGTH` indiquant le nombre réel d’éléments retournés.

## Choix pour les programmes IWS

Pour les wrappers de type `service.iws.sqlrpgle`, le choix retenu est d’exposer un prototype standard avec :

- `items_LENGTH`
- `items dim(100)`
- `totalCount`
- `errors_LENGTH`
- `errors dim(...)`
- `httpStatus`

Cette approche correspond bien au mode de fonctionnement IWS/PCML pour les tableaux de sortie, IBM recommandant un compteur séparé pour décrire la longueur effective du tableau retourné.

Elle présente aussi l’avantage d’être facilement industrialisable dans des templates de services IBM i.

## Bénéfices attendus

Les bénéfices recherchés avec cette architecture sont les suivants :

- Conservation du contrat d’URL côté client et compatibilité avec React Admin.
- Réutilisation sans modification de la logique métier existante.
- Centralisation du parsing HTTP dans une couche dédiée et factorisable.
- Meilleure séparation entre transport, adaptation et métier.
- Standardisation des programmes IWS de sortie à travers des templates homogènes.

## Décision synthétique

La décision d’architecture retenue consiste à faire de `CIWS` un adaptateur spécialisé entre IWS et `CMAGIC` : IWS expose le programme, `CIWS` lit et parse la `QUERY_STRING`, reconstruit un `CMAGIC_context` compatible avec le contrat REST existant, puis délègue le traitement à `CMAGIC` et à `service.sqlrpgle`.

Cette décision permet de moderniser la couche d’exposition sans remettre en cause le modèle métier ni le contrat fonctionnel déjà stabilisé.
