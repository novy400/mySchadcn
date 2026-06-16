# Comment créer un nouveau projet à partir de mySchadcn

`mySchadcn` peut servir de base à un nouveau projet admin/CRM basé sur :

- Vite
- React 19
- TypeScript
- Tailwind CSS
- `ra-core`
- shadcn-admin-kit / composants admin locaux
- `ra-data-fakerest` pour le prototype de données

Vous disposez de **3 méthodes** pour créer un nouveau projet selon votre contexte.

---

## Méthode 1 : utiliser le script d'extraction local

C'est la méthode recommandée si vous avez le dépôt `mySchadcn` en local et que vous voulez repartir de son état actuel.

### Prérequis

- Être placé à la racine de `mySchadcn`
- Avoir un terminal Bash : Git Bash sur Windows, ou terminal standard sur macOS/Linux
- Avoir Node.js disponible
- Avoir Git disponible si vous voulez initialiser automatiquement le nouveau dépôt

### Commande

```bash
chmod +x scripts/extract-project.sh
./scripts/extract-project.sh ../mon-nouveau-crm
```

### Ce que fait le script

Le script :

- copie les fichiers du projet courant vers le dossier cible ;
- refuse d'écrire dans un dossier cible déjà non vide ;
- exclut automatiquement les éléments locaux ou générés :
  - `.git`
  - `node_modules`
  - `dist`
  - `coverage`
  - `.vite`, `.turbo`, `.cache`
  - fichiers `*.log`
  - `.env`, `.env.local`, `.env.*.local`
- initialise un nouvel historique Git avec `git init` si Git est disponible ;
- renomme le package npm dans :
  - `package.json`
  - `package-lock.json`, si présent
- transforme le nom du dossier cible en nom npm valide, par exemple `Mon CRM` devient `mon-crm`.

### Étapes après extraction

```bash
cd ../mon-nouveau-crm
npm install
npm run dev
```

Vérifications recommandées :

```bash
npm run lint
npm run test
npm run build
```

---

## Méthode 2 : télécharger via Degit

Cette méthode est rapide si le dépôt est disponible sur GitHub et que vous voulez récupérer la dernière version sans l'historique Git.

```bash
npx degit novy400/mySchadcn mon-nouveau-crm
cd mon-nouveau-crm
npm install
npm run dev
```

À faire ensuite :

- modifier le champ `name` dans `package.json` ;
- modifier aussi `package-lock.json` si vous le conservez ;
- initialiser Git si nécessaire :

```bash
git init
```

---

## Méthode 3 : utiliser GitHub Template Repository

Cette méthode est pratique si `mySchadcn` doit être réutilisé régulièrement comme gabarit.

1. Aller sur la page GitHub du dépôt `novy400/mySchadcn`.
2. Ouvrir **Settings**.
3. Dans **General**, cocher **Template repository**.
4. Revenir sur la page principale du dépôt.
5. Cliquer sur **Use this template** pour créer un nouveau dépôt basé sur ce projet.

Le nouveau dépôt reprend l'architecture du projet sans l'historique Git initial.

---

## Nettoyage conseillé pour un vrai nouveau projet

Après création, adaptez au minimum :

- `package.json` : nom, description, scripts si besoin ;
- `README.md` : remplacer la documentation de `mySchadcn` par celle du nouveau projet ;
- `AGENTS.md` : ajuster les règles spécifiques au nouveau projet ;
- `src/data/raw/baseData.ts` : remplacer les données de démonstration ;
- `src/modules/crm/*` : supprimer ou renommer les ressources inutiles ;
- `ressources/doc/*` : conserver uniquement la documentation utile.

Gardez la suite suivante verte avant de commencer les développements métier :

```bash
npm run lint
npm run test
npm run build
```
