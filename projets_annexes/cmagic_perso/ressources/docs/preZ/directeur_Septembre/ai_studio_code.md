---
theme: black
enableMenu: false
parallaxBackgroundImage: https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg
parallaxBackgroundSize: 2100px 900px
parallaxBackgroundHorizontal: 200
parallaxBackgroundVertical: 50
---

# Ordre du Jour

1.  **Le Constat :** Notre atout, notre défi.
2.  **La Vision :** Moderniser sans remplacer, capitaliser sur nos acquis.
3.  **La Stratégie :** Les 3 piliers de notre transformation.
4.  **L'Accélérateur :** Comment nous allons le faire efficacement.
5.  **Les Bénéfices :** Ce que nous allons y gagner.
6.  **Le Plan d'Action & Notre Demande.**

Note:
Voici le plan que je vous propose de suivre. Nous commencerons par un état des lieux honnête, avant de vous présenter notre vision stratégique, la méthode concrète pour y parvenir, les bénéfices attendus, et enfin, le plan d'action et ce que nous attendons de vous.

---

## 1. Le Constat : Notre Atout, Notre Défi

Notre système IBM i est le cœur de nos opérations. Il est **fiable, robuste et performant**.

**Cependant, nous faisons face à une "dette technique" croissante.**

![Icône de dette](https://img.icons8.com/ios/100/debt.png)

C'est un investissement que nous devons faire pour éviter de payer des "intérêts" de plus en plus lourds à l'avenir.

Note:
Notre système actuel est un pilier. Il fonctionne, et il fonctionne bien. C'est le résultat de décennies d'investissement et de travail. Mais comme toute infrastructure critique, elle nécessite une maintenance et une évolution.
Le concept de "dette technique" est simple : chaque fois que nous choisissons une solution rapide au lieu d'une solution propre, nous contractons une petite dette. Aujourd'hui, l'accumulation de ces dettes commence à nous coûter cher.

----

### Les Impacts sur l'Entreprise

Cette dette technique n'est pas un problème informatique, c'est un **problème métier**.

| Ralentissement | Risque Accru | Dépendance |
| :---: | :---: | :---: |
| ![Icône de ralentissement](https://img.icons8.com/pastel-glyph/64/snail.png) | ![Icône de risque](https://img.icons8.com/ios/100/high-risk.png) | ![Icône de dépendance](https://img.icons8.com/dotty/80/dependency.png) |
| Lenteur à livrer de nouvelles fonctionnalités. | Plus de bugs, des corrections plus complexes. | Forte dépendance à quelques experts clés. |
| **Perte d'agilité** | **Impact sur la qualité** | **Difficulté à recruter et former** |

Note:
Concrètement, qu'est-ce que cela signifie pour l'entreprise ?
Cela signifie que répondre à une nouvelle demande du marché prend des mois au lieu de semaines.
Cela signifie que le risque qu'un bug impacte nos clients ou nos opérations augmente.
Et surtout, cela signifie que le savoir est concentré chez quelques personnes, ce qui est un risque majeur, et que nous avons du mal à attirer de nouveaux talents qui veulent travailler avec des technologies et des méthodes modernes.

---

## 2. Notre Vision : Moderniser, Pas Remplacer

Nous avons deux options :

| La Rupture (Risquée) | L'Évolution (Stratégique) |
| :---: | :---: |
| **"Tout Remplacer"** | **"Modernisation Progressive"** |
| <ul><li>Coûts exorbitants</li><li>Projet très long et risqué</li><li>Perte de la logique métier accumulée</li></ul> | <ul><li>**Notre choix**</li><li>Capitalise sur l'existant</li><li>Maîtrise des risques et des coûts</li><li>Apporte de la valeur rapidement</li></ul> |

**Notre philosophie : L'IBMi n'est pas le problème, c'est la base de la solution.**

Note:
Face à cette situation, beaucoup d'entreprises font le choix de la rupture : jeter le système existant et en reconstruire un nouveau. L'histoire est remplie d'échecs coûteux.
Nous proposons une voie plus intelligente et beaucoup moins risquée. Nous allons capitaliser sur la robustesse de notre plateforme IBM i et la moderniser de manière progressive. Nous ne jetons pas notre actif le plus précieux, nous le rénovons pour le futur.

---

## 3. La Stratégie : Nos 3 Piliers



Note:
Notre stratégie repose sur trois piliers d'action simultanés et complémentaires. C'est une approche holistique.
1.  D'abord, nous allons réorganiser notre code en "briques logicielles" métier, réutilisables et indépendantes. C'est comme passer d'une maison avec des murs porteurs partout à une structure ouverte et flexible.
2.  Ensuite, nous allons moderniser la manière dont nous accédons à nos données en utilisant le standard mondial : SQL. C'est plus performant et beaucoup plus simple pour les nouveaux développeurs.
3.  Enfin, nous allons offrir à nos utilisateurs des interfaces modernes, web et intuitives, qui améliorent drastiquement leur productivité et leur satisfaction.

----

### Pilier 1 : Modulariser le Cœur Applicatif

- **Avant :** Programmes monolithiques, code dupliqué.
- **Après :** Création de **Programmes de Service (SRVPGM)** par entité métier (Client, Facture, Produit...).
- **Bénéfice :** Un code plus propre, plus facile à maintenir et **réutilisable**.

### Pilier 2 : Moderniser l'Accès aux Données

- **Avant :** Accès aux fichiers "natifs", complexe pour les non-initiés.
- **Après :** Utilisation systématique de **SQL**, le standard universel.
- **Bénéfice :** **Performances améliorées** et simplification drastique pour les développeurs.

### Pilier 3 : Transformer l'Interface Utilisateur

- **Avant :** Écrans "verts" 5250, efficaces mais datés.
- **Après :** Interfaces **Web modernes** (type React Admin).
- **Bénéfice :** Meilleure **expérience utilisateur**, productivité accrue, image moderne.

---

## 4. L'Accélérateur : Le Projet "CMagic"

Pour mener à bien ces 3 piliers de manière **rapide, standardisée et industrielle**, nous ne nous contentons pas de moderniser : **nous construisons notre propre "usine de modernisation"**.

C'est le projet **CMagic**.

![Icône de baguette magique](https://img.icons8.com/ios-filled/100/magic-wand.png)

Un outil interne qui nous permettra de décrire une fonctionnalité métier en langage simple, et de **générer automatiquement 80% du code technique standardisé**.

Note:
Comment allons-nous réaliser cette transformation de manière efficace ? C'est ici qu'intervient notre véritable avantage stratégique : le projet CMagic.
Plutôt que de moderniser chaque programme à la main, de manière artisanale, nous créons un outil, un accélérateur.
CMagic nous permettra de décrire nos besoins métier - une entité "Client", une entité "Commande" - et de générer automatiquement tout le squelette technique moderne, robuste et standardisé.
Les développeurs n'auront plus qu'à se concentrer sur la logique métier à forte valeur ajoutée.

----

### CMagic en Action

Un processus simple et puissant :



**C'est la clé pour industrialiser nos bonnes pratiques et décupler notre productivité.**

Note:
Le principe est simple. Le développeur décrit le besoin dans un fichier de définition simple, comme on rédigerait une spécification. Il lance la commande CMagic, et l'outil génère les structures de données, les services, et même les tests de base.
C'est un investissement qui se rentabilise dès la deuxième fonctionnalité développée. Nous ne codons plus, nous modélisons.

---

## 5. Les Bénéfices Attendus

| Bénéfice | Description |
| :--- | :--- |
| **Agilité & Vitesse** | Livrer les nouvelles fonctionnalités **2x plus vite**. |
| **Réduction des Coûts** | Coûts de maintenance **réduits de 30%** à terme. |
| **Qualité & Fiabilité** | Moins de code manuel = **moins de bugs**. |
| **Attraction des Talents** | Un environnement de travail **moderne et motivant**. |
| **Pérennité** | Un système **documenté, compris et maîtrisable** par tous. |

Note:
Les bénéfices de cette approche sont directs et mesurables.
Nous serons plus rapides pour répondre aux besoins du marché.
Nous réduirons nos coûts opérationnels en simplifiant la maintenance.
Notre système sera plus fiable.
Nous deviendrons une entreprise attractive pour les nouveaux talents du numérique.
Et surtout, nous assurons la pérennité de notre système d'information en le rendant lisible et évolutif.

---

## 6. Le Plan d'Action

Nous avons une feuille de route claire et progressive, découpée en sprints.



Chaque étape apporte de la valeur et construit sur la précédente, sans "effet tunnel".

Note:
Ce n'est pas un projet flou. Nous avons une feuille de route précise, basée sur des sprints qui apportent de la valeur de manière incrémentale.
Nous commençons par les fondations (Sprints 1 & 2) pour construire l'usine CMagic. Puis nous ajoutons les interfaces (Sprint 3), les relations entre les objets (Sprint 4) et la logique métier (Sprint 5).
C'est une approche maîtrisée qui nous permettra de vous montrer des résultats concrets très rapidement.

----

### Notre Demande : Votre Soutien Actif

Ce projet est une transformation technique, mais surtout **culturelle**. Pour réussir, nous avons besoin de plus qu'un budget. Nous avons besoin de votre **soutien** et de votre **sponsorship**.

1.  **Valider la démarche stratégique** de modernisation progressive.
2.  **Accorder du temps aux équipes** pour se former et appliquer ces nouvelles pratiques.
3.  **Porter ce message** au sein de l'entreprise : c'est un projet prioritaire pour l'avenir.

Note:
Pour conclure, voici notre demande. Bien sûr, ce projet nécessite des ressources. Mais le plus important, c'est votre adhésion.
Nous avons besoin que vous validiez cette approche stratégique.
Nous avons besoin que vous nous aidiez à sanctuariser du temps pour que les équipes puissent non seulement travailler sur le projet, mais aussi se former et intégrer ces nouvelles façons de faire. Un développeur sous pression de livraison fera toujours "vite" au lieu de "bien".
Enfin, nous avons besoin que vous soyez les ambassadeurs de ce projet. Votre soutien est le facteur clé de succès le plus important.

---

## En Résumé

Nous ne subissons pas la dette technique, **nous investissons dans notre capital numérique**.

Ce projet va transformer notre système d'information d'un centre de coût à un **accélérateur de stratégie d'entreprise**.

**Merci.**

### Questions & Discussion

Note:
Pour résumer en une phrase : nous proposons de transformer notre système d'information d'une nécessité opérationnelle en un avantage concurrentiel.
Je vous remercie pour votre attention et je suis maintenant à votre disposition pour répondre à toutes vos questions.