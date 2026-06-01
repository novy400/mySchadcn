# Comment créer un nouveau projet à partir de mySchadcn

Ce projet a été conçu de manière modulaire afin de servir facilement de base (template) pour d'autres projets nécessitant **Vite + React 19 + TypeScript + shadcn-admin-kit**.

Vous disposez de **3 méthodes** pour générer un nouveau projet selon vos besoins.

---

## Méthode 1 : Utiliser le script d'extraction local (bash)

Si vous avez cloné ce dépôt localement et que vous avez fait des ajustements que vous souhaitez conserver dans un nouveau projet, vous pouvez utiliser le script bash fourni.

**Prérequis** : Avoir un terminal type **Git Bash** (sur Windows) ou un terminal classique sur MacOS/Linux.

1. Ouvrez votre terminal à la racine de l'actuel projet `mySchadcn`.
2. Donnez les droits d'exécution au script (une seule fois nécessaire) :
   ```bash
   chmod +x scripts/extract-project.sh
   ```
3. Exécutez le script en lui donnant le chemin de votre nouveau projet :
   ```bash
   ./scripts/extract-project.sh ../mon-nouveau-crm
   ```

**Ce que fait le script :**
- Il copie vos fichiers.
- Il supprime automatiquement le cache existant, les `node_modules`, et l'historique Git (`.git`).
- Il initialise un tout nouveau `git init`.
- Il modifie le le champ `name` du fichier `package.json` par le nom de votre dossier cible.

Ensuite, il suffit d'aller dans votre dossier (`cd ../mon-nouveau-crm`) et de lancer `npm install`.

---

## Méthode 2 : Télécharger via Degit (le plus rapide depuis GitHub)

Si `mySchadcn` est déposé sur GitHub et que vous voulez générer un projet flambant neuf **sans le cloner entièrement** et sans télécharger l'historique de commits.

1. Dans votre terminal, placez-vous dans votre dossier de projets (ex: `Documents/mesProjets/`).
2. Tapez la commande suivante :
   ```bash
   npx degit novy400/mySchadcn mon-nouveau-crm
   ```
3. Entrez dans le dossier, modifiez manuellement le `package.json` et installez !
   ```bash
   cd mon-nouveau-crm
   npm install
   ```

*Note : La commande degit va simplement récupérer la dernière version de la branche principale du repo github sans inclure le dossier .git.*

---

## Méthode 3 : Transformer ce dépôt GitHub en "Template Repository"

C'est la méthode idéale et la plus officielle offerte par GitHub. Elle fait de votre dépôt un "gabarit" réutilisable infiniment avec un simple bouton.

1. Allez sur la page GitHub de votre dépôt (`novy400/mySchadcn`).
2. Cliquez sur l'onglet **Settings** (Paramètres).
3. Dans la section **General**, cochez la case **"Template repository"**.
4. Désormais, sur la page d'accueil de ce dépôt sur GitHub, un gros bouton vert **"Use this template"** apparaîtra.
5. À chaque clic sur ce bouton, GitHub créera un tout nouveau dépôt (avec un nouveau nom) reprenant l'architecture de départ, sans l'historique des commits précédents.
