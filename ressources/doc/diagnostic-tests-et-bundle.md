# Diagnostic des tests CSS et du bundle

_Diagnostic réalisé le 2026-07-22 avec Vite 8 et Vitest 4._

## Résultat

Les deux avertissements historiques sont traités sans masquer une régression applicative :

- Vitest ne charge plus les feuilles CSS dans jsdom ;
- le build répartit les dépendances en groupes fonctionnels stables ;
- la suite active continue de vérifier le DOM et les interactions des composants concernés ;
- le build de production continue de compiler et minifier la totalité du CSS ;
- un smoke test du build vérifie la connexion et l'affichage du dashboard sans erreur console.

## Avertissement CSS sous jsdom

La reproduction minimale était :

```bash
npm run test -- --run src/components/rich-text-input/rich-text-input.test.tsx
```

Le test réussissait, mais jsdom affichait `Could not parse CSS stylesheet`. Le composant
importe la feuille Tailwind de l'éditeur riche, qui contient des constructions CSS modernes
destinées au navigateur. Les deux tests du rich-text input sont actuellement des smoke
tests d'import et de définition ; ils n'exercent ni le rendu DOM ni les styles.

`vitest.config.ts` utilise donc `css: false`. Les imports CSS restent résolus par Vite,
mais leur contenu n'est pas injecté dans jsdom. Cette décision est adaptée aux tests
actuels, qui ne font aucune assertion visuelle. Une future vérification de styles devra
utiliser un test navigateur, pas réactiver globalement l'analyse CSS de jsdom.

## Taille et découpage JavaScript

Mesure initiale : un chunk principal d'environ `950 kB` minifié et `297 kB` compressé.
L'analyse de la source map montre que le poids vient principalement du socle initial :
React, React DOM, React Router, `ra-core`, React Hook Form et les primitives UI.

Le poids total n'a pas été artificiellement présenté comme réduit. La correction porte
sur le découpage et la mise en cache :

| Chunk | Taille minifiée approximative |
| --- | ---: |
| application | 134 kB |
| React et routeur | 284 kB |
| React Admin et état/formulaires | 219 kB |
| primitives UI | 215 kB |
| autres dépendances | 103 kB |

La configuration `build.rolldownOptions.output.codeSplitting` suit le mécanisme recommandé
par [Vite](https://vite.dev/guide/build.html#chunking-strategy) et
[Rolldown](https://rolldown.rs/reference/OutputOptions.codeSplitting). Un premier essai de
découpage uniquement par taille produisait 24 micro-chunks ; il a été écarté au profit de
quatre groupes de dépendances lisibles et stables. Ils produisent cinq chunks principaux
avec le code applicatif, auxquels s'ajoute le petit runtime Rolldown.

## Vérifications

```bash
npm run lint
npm run test
npm run build
```

Le smoke test du build de production couvre également :

1. affichage de la page de connexion ;
2. connexion avec le compte Responsable de démonstration ;
3. affichage de `Dashboard CRM` ;
4. absence d'erreur ou d'avertissement dans la console du navigateur.
