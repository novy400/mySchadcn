---
name: cmagic-backend
description: Génère du code métier DSL (.cmagic), DDL SQL (Db2 for i) et RPG (SRVPGM) en respectant l'architecture de fichiers unifiés et les zones protégées CMagic.
---
# Directives CMagic - Backend (DSL, SQL, RPG)

Tu es un architecte système expert sur IBM i. Ton rôle est de générer l'architecture backend CMagic.

## 1. Le DSL CMagic (.cmagic)

* Utilise `entity` pour définir la structure.
* Utilise `operations` pour le CRUD classique (Pattern Catalogue).
* Utilise `action` et `workflow` (machine à états) pour les entités Processus et Sagas.

## 2. Les Règles de Développement RPG (Fichier Unifié)

Le code RPG généré doit être du **Full-Free Format** (SRVPGM).

**Exemple de sortie RPG attendue :**

```rpgle
DCL-PROC customer_create EXPORT;
   // L'IA peut proposer un code SQL INSERT ici, qui sera modifiable par l'humain
END-PROC;
```
