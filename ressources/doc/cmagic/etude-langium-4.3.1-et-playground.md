# Étude Langium 4.3.1 et IHM Web pour les fichiers `.cmagic`

_Statut : décision mise en œuvre pour le lot A — 6 août 2026._

## Décision proposée

Oui, il est raisonnable de faire évoluer CMagic de Langium 3.5 vers Langium 4.3.1,
mais sous la forme d'une tranche de maintenance dédiée, pas d'une mise à jour isolée dans
`package.json`.

Les raisons principales sont le renouvellement d'un socle désormais ancien, le correctif de
pollution de prototype livré dans 4.3.1 et les améliorations de complétion, de mémoire et de
diagnostic accumulées depuis 3.5. Le besoin n'est cependant pas bloquant à très court terme :
la syntaxe CMagic actuelle n'a pas besoin des nouvelles références multiples ni des règles
infixes pour fonctionner. Les nouveautés et ruptures sont recensées dans le
[changelog officiel de Langium](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v400-jul-2025),
et les deux correctifs propres à 4.3.1 sont visibles dans les commits officiels
[#2175](https://github.com/eclipse-langium/langium/commit/3314308e0ecd22e9e04a7b456e5a1e493a58880d)
et [#2181](https://github.com/eclipse-langium/langium/commit/d750a4226eb2dfb3c50b67a0adb7711ff44053b2).

Pour l'IHM, le Playground Langium est un excellent banc d'essai de grammaire et une bonne
source d'inspiration, mais ce n'est pas une IHM de production à embarquer telle quelle. La
bonne direction est de conserver la grammaire CMagic fixe et de faire évoluer le client
Monaco/Web Worker déjà présent dans `cmagic_perso` en un « CMagic Studio » centré sur la
saisie, la validation, l'import/export et la génération.

## État constaté dans le dépôt

Le projet [`cmagic_perso`](../../../projets_annexes/cmagic_perso/package.json) déclare :

| Élément | Version déclarée / verrouillée |
| --- | --- |
| `langium` | `~3.5.0` / `3.5.0` |
| `langium-cli` | `~3.5.0` / `3.5.2` |
| TypeScript | `~5.1.6` / `5.1.6` |
| Node / npm via Volta | `18.19.1` / `10.2.4` |
| `vscode-languageserver` | `~9.0.1` / `9.0.1` |
| `monaco-languageclient` | `~8.1.1` / `8.1.1` |
| `monaco-editor-wrapper` | `~4.0.2` / `4.0.2` |

Le dépôt possède déjà les briques essentielles d'un éditeur Web : un
[serveur Langium pour Web Worker](../../../projets_annexes/cmagic_perso/src/language/main-browser.ts),
deux [configurations Monaco](../../../projets_annexes/cmagic_perso/src/setupExtended.ts) et
une [construction Vite](../../../projets_annexes/cmagic_perso/vite.config.ts). Il n'est donc
pas nécessaire de repartir du code du Playground.

L'audit statique du code CMagic n'a trouvé aucun usage direct de `PrecomputedScopes`,
`References.findDeclaration`, `DefaultCompletionProvider`, du `singleton` du registre de
services, ni des anciens champs CST supprimés. La grammaire s'appelle `Cmagic` et aucune de
ses règles ne porte ce nom, elle respecte donc déjà la nouvelle contrainte d'unicité. Le seul
usage local à surveiller après régénération est l'interpolation des constantes de types AST
dans deux messages de tests : en version 4, la chaîne du type est disponible via
`Model.$type`. Ce changement est documenté dans les
[ruptures de Langium 4.0](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#breaking-changes-2).

Cet audit est un indicateur de risque, pas une preuve de compatibilité : seule une
régénération suivie de la compilation et de tous les tests pourra la confirmer.

## Ce qui change de 3.5 à 4.3.1

### Prérequis obligatoires

| Sujet | Langium 3.5 | Langium 4.3.1 | Conséquence CMagic |
| --- | --- | --- | --- |
| Node.js | `>=18` | `>=20.10` | remplacer le pin Volta `18.19.1` |
| npm | pas de minimum dans le paquet `langium` | `>=10.2.3` | la version locale `10.2.4` convient |
| TypeScript | le projet CMagic est en 5.1.6 | `>=5.8` | passer au minimum en 5.8, de préférence 5.9 |
| LSP serveur | 9.0 / protocole 3.17 | 10.0 / protocole 3.18 | aligner serveur, protocole et types LSP |

Les exigences Node/npm sont portées par les métadonnées du
[paquet Langium 4.3.1 publié](https://registry.npmjs.org/langium/4.3.1) et l'exigence
TypeScript est explicitée par le
[changelog 4.0](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#breaking-changes-2).
Langium 4.3.1 dépend précisément de `vscode-languageserver ~10.0.1`,
`vscode-languageserver-protocol ~3.18.1` et `vscode-languageserver-types ~3.18.0` ; Langium
4.3 a introduit cette rupture LSP dans son
[changelog de juin 2026](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v430-jun-2026).

Il ne faut pas choisir Node 20 uniquement parce qu'il satisfait le minimum : Node 18 est en
fin de vie depuis le 30 avril 2025 et Node 20 depuis le 30 avril 2026. Au 6 août 2026,
Node 22 est en maintenance LTS jusqu'au 30 avril 2027 et Node 24 est en LTS active jusqu'en
octobre 2026, puis supporté jusqu'au 30 avril 2028. Pour une nouvelle base, Node 24 offre le
plus de durée de support ; Node 22 est l'option conservatrice si une dépendance périphérique
n'est pas encore qualifiée sur 24. Ces dates proviennent du
[calendrier officiel Node.js](https://github.com/nodejs/Release#release-schedule).

### Ruptures d'API en Langium 4.0

La liste officielle complète se trouve dans le
[changelog 4.0.0](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#breaking-changes-2).
Les points à contrôler dans CMagic et ses futures extensions sont :

- `PrecomputedScopes` devient `LocalSymbols` ;
- les références manipulées par le linker et le scope provider deviennent
  `Reference | MultiReference` ;
- `References.findDeclaration` devient `findDeclarations` et renvoie un tableau ;
- les constantes générées dans `ast.ts` deviennent des descripteurs : la chaîne autrefois
  portée par `TypeName` se lit désormais par `TypeName.$type` ; l'AST officiel généré en
  4.3 illustre cette forme dans
  [`examples/domainmodel/.../generated/ast.ts`](https://github.com/eclipse-langium/langium/blob/main/examples/domainmodel/src/language-server/generated/ast.ts) ;
- les noms de grammaires doivent être uniques et une règle ne peut plus porter le même nom
  que sa grammaire ;
- `DefaultCompletionProvider.createReferenceCompletionItem` reçoit davantage d'arguments ;
- le `singleton` de `DefaultServiceRegistry` disparaît et un `FileSystemProvider` personnalisé
  doit implémenter l'interface étendue ;
- les alias CST dépréciés `parent`, `feature`, `element`, `children` et la fonction de test
  `expectFunction` sont supprimés par
  [#1991](https://github.com/eclipse-langium/langium/pull/1991).

La nouvelle syntaxe de références multiples (`[+Type]`) et les règles `infix` sont
optionnelles. Les anciennes formes restent utilisables ; l'intérêt pour CMagic apparaîtrait
plus tard si le langage accepte des déclarations partielles ou de vraies expressions. Les
détails et exemples sont dans le
[changelog 4.0.0](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v400-jul-2025).

### Améliorations pertinentes

- Langium 4.1 ajoute un profileur du parsing, du linking et de la validation, ainsi que la
  possibilité d'éviter certaines validations pour améliorer les performances. Cela sera
  utile lorsque les modèles CMagic et leurs validations métier grossiront
  ([changelog 4.1](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v410-sep-2025)).
- Langium 4.2 corrige et améliore la complétion lorsque des règles ont des préfixes communs ;
  CMagic possède justement des mots-clés proches tels que `GT`/`GTE`, `GET` et plusieurs
  opérations apparentées
  ([changelog 4.2](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v420-jan-2026)).
- Langium 4.3 réduit l'usage mémoire des références, ajoute `AstReflection.isComplete` et
  adopte LSP 3.18
  ([changelog 4.3](https://github.com/eclipse-langium/langium/blob/main/packages/langium/CHANGELOG.md#v430-jun-2026)).
- Le correctif 4.3.1 ignore `__proto__`, `constructor` et `prototype` lors de la fusion des
  modules d'injection, afin d'empêcher une pollution de prototype
  ([commit #2175](https://github.com/eclipse-langium/langium/commit/3314308e0ecd22e9e04a7b456e5a1e493a58880d)).
  L'exposition actuelle est limitée car les modules CMagic sont statiques, mais ce correctif
  devient plus important si l'outil accepte un jour des extensions ou configurations non
  maîtrisées.
- Le même patch répare la désérialisation JSON des références multiples
  ([commit #2181](https://github.com/eclipse-langium/langium/commit/d750a4226eb2dfb3c50b67a0adb7711ff44053b2)).

### Particularité de version 4.3.1

Au 6 août 2026, `langium` 4.3.1 est publié sur npm, mais le dernier `langium-cli` publié est
4.3.0 ; le changelog du dépôt décrit également 4.3.0 comme dernière entrée de la série.
Il faut donc viser `langium ~4.3.1` avec `langium-cli ~4.3.0`, et non demander un
`langium-cli@4.3.1` inexistant. Les registres officiels confirment les versions disponibles
de [`langium`](https://www.npmjs.com/package/langium?activeTab=versions) et
[`langium-cli`](https://www.npmjs.com/package/langium-cli?activeTab=versions).

## Chemin de migration recommandé

La migration devrait être réalisée en deux lots pour distinguer le moteur du langage de
l'IHM Web.

### Lot A — moteur Langium, CLI et extension VS Code

1. Créer une branche dédiée et enregistrer un résultat de référence des tests, de la
   génération d'artefacts catalogue/IWS, du build VS Code et du build Web.
2. Passer Volta et la CI à Node 24 LTS, ou Node 22 si une dépendance ne passe pas encore sur
   24 ; conserver npm au moins en 10.2.3.
3. Passer TypeScript en 5.9, `langium` en `~4.3.1` et `langium-cli` en `~4.3.0`.
4. Aligner les paquets LSP serveur sur les versions exigées par le paquet Langium 4.3.1.
   Pour l'extension VS Code, comparer le résultat au
   [gabarit officiel actuel](https://github.com/eclipse-langium/langium/blob/main/packages/generator-langium/templates/packages/extension/package.json),
   qui emploie la famille 10 du client et du serveur.
5. Exécuter `npm run langium:generate`, examiner le diff de `generated/ast.ts`, du module
   généré et des grammaires TextMate/Monarch. Adapter les messages utilisant `Model` en
   chaîne vers `Model.$type` si nécessaire.
6. Corriger les erreurs TypeScript sans refactor métier, puis exécuter les tests et les builds
   CLI, extension et Web. Comparer aussi les artefacts RPG, SQL, OpenAPI et contrats générés
   sur les exemples existants afin d'exclure une dérive silencieuse.
7. Tester manuellement dans VS Code : diagnostics, complétion, navigation vers une entité,
   survol, commande `CMagic: Generate Code`, puis ouverture d'un fichier invalide.

Ce lot paraît de risque **modéré** : le code métier CMagic est peu couplé aux API cassées,
mais la régénération de l'AST, TypeScript 5.9 et la nouvelle famille LSP doivent être validés
ensemble.

### Lot B — modernisation de l'éditeur Web

Le lot Web est distinct parce que `monaco-languageclient` a abandonné
`monaco-editor-wrapper` en version 10.0.0. Le projet CMagic emploie encore
`monaco-languageclient 8.1.1` et `monaco-editor-wrapper 4.0.2`. La
[matrice officielle TypeFox](https://github.com/TypeFox/monaco-languageclient/blob/main/docs/versions-and-history.md)
donne actuellement `monaco-languageclient 10.7.0` avec l'API Monaco/VS Code 25.1.2, tandis
que le guide maintenu montre les nouveaux objets `MonacoVscodeApiWrapper`,
`LanguageClientWrapper` et `EditorApp` dans
[Running a Langium Language Server in the Browser](https://github.com/TypeFox/monaco-languageclient/blob/main/docs/guides/langium/running-langium-ls-in-browser.md).

Il faut donc porter `setupClassic.ts`/`setupExtended.ts` vers cette API actuelle dans un lot
séparé, puis vérifier le chargement du Web Worker, TextMate, les diagnostics, la complétion
et le build Vite. Cela évite de confondre une éventuelle régression Langium avec une rupture
de l'enveloppe Monaco.

## Ce que fait réellement le Playground

Le [Playground officiel](https://langium.org/playground/) affiche trois surfaces : une
grammaire Langium éditable, le contenu utilisant cette grammaire et, en option, son arbre de
syntaxe. Son code source montre qu'il :

- crée dynamiquement les services à partir du texte de la grammaire et régénère un serveur
  de langage dans un Web Worker
  ([`common.ts`](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/common.ts),
  [`user-worker.ts`](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/user-worker.ts)) ;
- fournit l'édition Monaco, la coloration TextMate, la validation, la complétion et la
  sérialisation de l'AST ; ces fonctions reposent sur les capacités LSP que Langium fournit
  aux éditeurs
  ([fonctionnalités Langium](https://langium.org/docs/features/)) ;
- fonctionne dans le navigateur avec un système de fichiers vide et un document en mémoire,
  selon l'architecture Web Worker également décrite par le
  [guide d'intégration actuel](https://github.com/TypeFox/monaco-languageclient/blob/main/docs/guides/langium/running-langium-ls-in-browser.md) ;
- partage l'état en compressant la grammaire et le contenu dans les paramètres de l'URL,
  puis copie cette URL dans le presse-papiers
  ([`utils.ts`](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/utils.ts)).

Ces capacités en font un très bon outil pour tester la grammaire CMagic, montrer la
complétion à des utilisateurs et inspecter l'AST attendu avant de modifier les générateurs.

## Pourquoi ne pas en faire directement l'IHM CMagic

Le Playground officiel n'embarque pas le module CMagic compilé. Il construit un langage
générique à partir de la seule grammaire et remplace le validateur par
`PlaygroundValidator`, qui transforme notamment les erreurs de linking en avertissements
([source du validateur](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/user-validator.ts)).
Il n'exécute donc ni `CmagicValidator`, ni les compilateurs catalogue/IWS, ni les gabarits RPG
et SQL du dépôt.

Son interface et son code ne fournissent pas non plus de gestion de vrais fichiers, de
workspace multi-fichiers, de stockage, d'authentification, d'autorisation, d'historique, de
verrouillage concurrent ou de piste d'audit. Le code officiel ne conserve que la grammaire
et le contenu courants en mémoire ; son action « partager » place les données compressées,
mais non chiffrées, dans une URL. C'est adapté à un exemple partageable, pas à des sources
métier confidentielles
([`_index.html`](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/_index.html),
[`utils.ts`](https://github.com/eclipse-langium/langium-website/blob/main/hugo/content/playground/utils.ts)).

Enfin, le tutoriel historique Langium + Monaco du site avertit lui-même que ses exemples ont
été écrits pour Langium 2.0.2 et `monaco-editor-wrapper 3.1.0` et ne fonctionnent pas avec les
versions actuelles. Il faut s'appuyer sur le guide TypeFox maintenu, pas recopier ce tutoriel
ancien
([avertissement officiel](https://langium.org/docs/learn/minilogo/langium_and_monaco/)).

## IHM CMagic recommandée

Le premier incrément devrait être un éditeur dédié et simple, bâti sur le serveur CMagic
compilé, pas sur une grammaire modifiable par l'utilisateur :

```text
CMagic Studio (Vite, puis intégration React si souhaitée)
  ├─ éditeur Monaco d'un document *.cmagic
  ├─ client LSP
  ├─ Web Worker CMagic avec grammaire et CmagicValidator fixes
  ├─ panneau diagnostics / aperçu AST ou catalogue
  └─ actions Ouvrir, Enregistrer/Télécharger, Valider et Générer
```

Ordre de valeur recommandé :

1. **Prototype utilisable localement** : un seul document, exemples prêts à charger,
   complétion, diagnostics CMagic, import d'un `.cmagic`, téléchargement du fichier et
   conservation locale explicite.
2. **Aperçu métier** : remplacer l'AST brut par un aperçu « entités, champs, opérations,
   routes et artefacts prévus », plus parlant pour un utilisateur CMagic.
3. **Génération contrôlée** : exposer la génération seulement si le document ne contient
   aucune erreur et présenter les artefacts avant téléchargement. Langium permet de brancher
   une génération sur la phase de validation et de notifier le client, mais son ancien
   tutoriel Web est explicitement obsolète ; il décrit le principe, pas une implémentation à
   copier
   ([Generation in the Web](https://langium.org/docs/learn/minilogo/generation_in_the_web/)).
4. **Industrialisation éventuelle** : ajouter côté serveur le stockage, le versionnage,
   l'authentification, les autorisations, la génération reproductible et l'audit si les
   fichiers deviennent des actifs partagés. Le Web Worker peut rester responsable du retour
   immédiat de saisie.

Pour aller vite, cette IHM peut d'abord rester une application Vite séparée issue de
`cmagic_perso`, accessible depuis mySchadcn par un lien. Une intégration React directe devient
pertinente après validation de l'expérience de saisie ; la variante React officielle de la
pile Monaco est `@typefox/monaco-editor-react`, versionnée dans la même
[matrice de compatibilité](https://github.com/TypeFox/monaco-languageclient/blob/main/docs/versions-and-history.md).

## Critères de décision et de recette

La migration Langium est acceptée lorsque :

- la grammaire se régénère sans avertissement nouveau ;
- tous les exemples `.cmagic` valides restent valides et les invalides produisent les mêmes
  erreurs métier ;
- les artefacts générés sont identiques ou leurs différences sont expliquées et acceptées ;
- la CLI, l'extension VS Code et le Web Worker démarrent sur une version Node encore
  supportée ;
- complétion, linking, diagnostics, navigation et commande de génération fonctionnent ;
- les builds et tests du projet restent verts.

Le prototype d'IHM est accepté lorsque l'utilisateur peut ouvrir ou démarrer un `.cmagic`,
être guidé par la complétion, comprendre et corriger les diagnostics, sauvegarder son texte et
prévisualiser ou générer les artefacts sans perdre son travail. Le Playground peut servir à
valider ces interactions, mais ne doit pas devenir le stockage ni l'exécuteur de production.

## Compte rendu du lot A — moteur Langium, CLI et extension

La migration a été réalisée depuis le point fixe
`f35429f58c57f3b240f37169c10e4912c8c72cad`, sur la branche
`codex/docs-restructuration`. Node 24 s'est montré compatible avec l'ensemble des tests et
builds ; le repli vers Node 22 n'a donc pas été nécessaire.

### Versions retenues et verrouillées

| Élément | Déclaration | Version résolue |
| --- | --- | --- |
| Node via Volta | `24.18.0` | `24.18.0` pendant la recette |
| npm via Volta | `11.16.0` | `11.16.0` pendant la recette |
| TypeScript | `~5.9.3` | `5.9.3` |
| `langium` | `~4.3.1` | `4.3.1` |
| `langium-cli` | `~4.3.0` | `4.3.0` |
| `vscode-languageclient` | `~10.0.0` | `10.0.1` |
| `vscode-languageserver` | `~10.0.1` | `10.0.1` |
| protocole / types LSP | transitifs | `3.18.1` ou `3.18.2` / `3.18.0` |
| `@types/node` | `^24.0.0` | `24.13.3` |
| `@types/vscode` | `~1.91.0` | `1.91.0` |

Le moteur VS Code minimal de l'extension passe de `^1.67.0` à `^1.91.0`, contrainte
déclarée par `vscode-languageclient 10.0.1`. Les paquets ESLint TypeScript passent en
`8.57.2` afin de prendre officiellement en charge TypeScript 5.9.

### Adaptations imposées

`npm run langium:generate` termine sans avertissement. Les sorties générées restent
ignorées par Git, comme avant la migration ; un diff temporaire a donc été produit entre
`langium-cli 3.5.2` et `4.3.0` :

- `ast.ts` remplace les constantes chaînes des treize types AST par des descripteurs
  contenant `$type` et les noms de propriétés, puis adopte la nouvelle métadonnée de
  réflexion Langium 4 ;
- `grammar.ts` adopte la représentation sérialisée Langium 4 (`isMulti`,
  `parenthesized` et omission de valeurs par défaut devenues inutiles), sans modification
  de la grammaire source ;
- `module.ts` ne change que son en-tête de version ;
- les grammaires TextMate et Monarch conservent exactement les mêmes SHA-256.

Le code suivi a nécessité seulement deux adaptations d'API : les sous-chemins LSP 10
`vscode-languageclient/node` et `vscode-languageserver/{node,browser}` ne portent plus le
suffixe `.js`, et deux diagnostics de tests interpolent désormais `Model.$type`. Aucun
validateur, compilateur catalogue/IWS, gabarit ni fichier `.langium` n'a changé. Le fichier
de build incrémental `*.tsbuildinfo` désormais émis par TypeScript 5.9 est ignoré.

### Résultats de recette

- référence avant migration : 18 fichiers et 141 tests CMagic, lint et build verts ;
- après migration : les mêmes 18 fichiers et 141 tests passent, y compris les modèles
  valides, les erreurs de syntaxe, le linking et les validations métier ;
- CLI : compilation verte et commande `generate-catalog` disponible ;
- extension VS Code : serveur et extension bundlés, prépublication minifiée et lint verts ;
- Web existant : build Vite vert, avec émission du Web Worker `main-browser` ;
- racine mySchadcn : référence et vérification finale vertes avec 38 fichiers et 85 tests,
  lint et build inclus ;
- les 21 artefacts catalogue/IWS ont été régénérés deux fois : aucun SHA-256 ne diffère du
  point fixe et aucune différence n'existe entre les deux exécutions. Le SHA-256 du
  manifeste trié des 21 hashes est
  `d307369698fb09a5833976d768058c337b584fcc7fb57c51637f06ab59743a04`.

### Limites conservées

Le client Web reste volontairement sur `monaco-languageclient 8.1.1` et
`monaco-editor-wrapper 4.0.2`. Leur sous-arbre conserve donc le protocole LSP 3.17, tandis
que Langium, le serveur et l'extension VS Code utilisent la famille 3.18. La modernisation
Monaco et la réduction du gros chunk Vite du wrapper appartiennent au lot B.

La recette automatise le parsing, la validation, la génération et les builds, mais ne
remplace pas une session interactive VS Code pour les diagnostics, la complétion, la
navigation, le survol et la commande de génération. Enfin, `npm install` signale 30
vulnérabilités dans l'arbre historique, principalement conservé pour le lot Monaco ; leur
remédiation générale dépasserait le périmètre de cette migration ciblée.

Le DataProvider IBM i, CMagic Studio, la grammaire métier et les artefacts synchronisés dans
`cMagicIws` n'ont pas été modifiés.

## Conclusion

La recommandation est donc : **planifier Langium 4.3.1 maintenant**, en séparant le lot
« moteur/CLI/LSP » du lot « Monaco/IHM ». Le gain immédiat est surtout la remise sur un socle
supporté et corrigé ; les nouveautés de langage sont un bénéfice secondaire. Pour la saisie
des `.cmagic`, **reprendre les idées du Playground, mais faire évoluer l'éditeur Web CMagic
déjà présent** avec une grammaire fixe, les validations métier et un vrai cycle
ouvrir–valider–enregistrer–générer.
