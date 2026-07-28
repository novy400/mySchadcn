# CMAGIC note de cadrage

## object

- créer un template de projet complet pour dev sur Ibmi utilisant :
    - template de projet organisation github board ,issues, request pour l'oechestration des features,fix et livraiosn dans les environnements  (vision mutil-repo globale ) 
    - template de repo p^(projet ?)  type github comprenant tous les artefacts pour assusre la gestion des features et hotfix internees au projet repo 
    - ci/cd pilotée par make,ansible et githubactions
    - git, github 
    - gestion des branches pour les environnemetns (git flow)
    - RPGUNIT pour les tests 
    - Kanban pour la gestion du projet (github board)
l'accent etant mis sur l'utilisation des outils de github.    
il ya une grande volonté de simplifier et abstraire les concepts pour s'adapter au public concerné.
Les devs IBMI sont trés proches du métier mais pas toujours au fait des nouvelles techno.
Dans la mesure du possible il faut mettre en place des ouitls pour simplifier les différentes opérations sur les environnements.
- ouvrir une feature.
- tester une feature.
- monté en recette (UAT) 
- corriger une feature.
- abandonner une feature.
Par exemple il ne faut pas leur parler de création d'une branche de check out d'une branche de déplacement dans une branche mais plutôt d'ouverture de feature et tout le Le process se fait un peu comme les commandes de gitflow qui intègrent diverses commandes git dans une seule commande Donc si on arrive à faire ça et l'intégrer au workflow du projet Github et du projet Repo et des mecs et des github actions je pense qu'on aura gagné il faut au maximum simplifier mais pas simplifier en faisant une usine à gaz derrière simplifier en utilisant les concepts et concepts et les standards de fait de l'utilisation des branches par exemple pour gérer des des environnements Alors bien sûr auparavant il faudra des composer toutes ces ces ces ces cas d'utilisation avec les diverses implications qu'il y a dans le dans le process pour bien détailler et pour bien voir si c'est fluide et si ça répond à toutes les éventualités donc c'est évidemment il faudra faire une liste de tout des de tous les cas d'utilisation qu'on peut trouver dans le process
la création de ce template de projet va etre elaborée en collaboration avec des IAs :
    - Claude sonnet,github copilot,....
Lister tous les cas possibles sur un projet avec un seul dev.
Lister tous les cas avec plusieurs devs.
Décomposer les différents taches ==> cas d'utilisation en faire une bande dessinée
## organisation
Alors à quoi s'adresse ce projet ? Il s'appelle dresse principalement on est dans le cadre d'une modernisation d'un système d'information IBNI le parti pris qui est pris dans ce cas de de de modernisation c'est de laisser le système Legacy avec son ancienne organisation si je puis dire que ça soit pour les mises en production la gestion même du code source puisque ces ces sources sont générées généralement se trouvent dans des membres de fichiers natifs qui se trouvent sur la partie US 400 pour les nouveaux développements on va partir du principe qu'on va essayer de d'avoir une une vision d'architecture hexagonale c'est à dire de développer tout un tas de de projets autour satellite Ces projets étant des repo distant des Repo github et chaque repo par exemple va gérer une entité métier en lien avec le système Legacy par exemple on pourrait dire une entité métier de type client qui serait matérialisé ou au sens IBMI au sens github sous la forme d'un repo d'un projet on pourrait dire au sens OS 400 ce serait un ou plusieurs programmes de service qui dialoguerait avec le Legacy un peu avec sous un peu avec des adaptateurs si on veut pour voilà pour bien faire la distinction contre les nouveaux projets les projets satellites de modernisation et le Legacy c'est un peu une vision Voilà et donc il y aurait plusieurs modules comme ça c'est plusieurs modules là c'est plusieurs repos par exemple projet client facture se retrouveraient au niveau toutes ces features se retrouveraient par exemple matérialisées au niveau d'un d'un d'un d'un board de l'organisation par exemple on pourrait avoir une feature qui pourra avoir une feature à j'en trouve pas comme ça mais mise en place par exemple d'un CRM voilà et cette cette cette cette cette mise en place du CRM et Ben elle aura des des features pour chaque repo par exemple ça serait dans la partie clients et Ben ça serait remonter des clients pour la partie facture ça serait remonter des factures donc ça serait des features bien distantes au niveau de de ces repo mais elles seraient elles seraient voilà si c'est possible hein? Elle donnerait lieu à par exemple à une mise en prod qui serait gérée admise Ouais en production qui serait gérée au niveau de l'organisation et donc on puis on piloterait comme ça notre projet pour avoir l'importance de ce truc là c'est que l'avoir au board au bord de l'organisation c'est de permettre de rendre visible en fait ce qui se fait en détail en bas à aux gens par exemple du Ben du staff métier qui sont pas forcément vraiment qui ont pas besoin d'avoir une vision repo quoi y a plutot une vision un peu plus haute pour pouvoir voir ce qui se passe
- que représente le repo  (le projet  ? le périmétre application DDD)
- c quoi le projet 

## gestion des environnements
- (DEV,UAT,OAT,PROD)

- ces environnements peuvent être matérialisés par :
    - la méme liste de bibliothéques (cf `JOBD` ) sur des systémes différents.
    - des listes de biblioothéques différentes sur le méme systéme. 
    - une combinaison des 2 (??)

- sur le systéme de `DEV`
    - Le périmétre applicatif correspond à une liste de bibliothéques matérialisées dans une jobd. 
    - cette jobd doit être la référence lors de la compilation des différents objets du projet.
    - Chaque développeur posséde sa bibliothéque.
    - Chaque `FEATURE` posséde sa bibliothéque.


### Feature
- une `FEATURE` est une nouvelle fonctionnalité.
- on doit pouvoir permettre les développements de plusieurs features en paralléles.
- ? doit on permettre de regrouper les features d'un proejt pour montée dans l'environnement suivant (UAT, OAT et PROD) 


### HotFix
- un `HOTFIX` correspond à un bug.

## ressources


## existant, état de l'art
Pas alors oui pour l'existant pour l'état de l'art En fait c'est un peu ça on va partir du principe qu'on qu'on qu'on va viser par exemple une petite PME qui a un système Legacy qui peut être développé en RPG 3 Les sources se retrouvent dans des membres natifs de l'i BMI il peut avoir 111 gestionnaire pour ses sources de type Arcade ou ne carrément ne pas avoir de de de de de gestionnaire de source mais peut être une une organisation maison de la gestion des membres de l'organisation des livraisons de l'organisation des des des des synchronisations d'environnement et des environnements les membres de ces équipes sont en général des membres des des gens qui sont très très proches alors il y a un peu 2 clientèles on va dire il y a 2 clientèles un les les anciens si on puis dire c'est des gens qui sont très très proches du métier qui savent bien coder en RPG 3 avec les vieux outils mais qui sont pas toujours au fait des nouvelles technologies et aussi pas seulement qui ne sont pas au fait mais qui sont un peu hermétiques à toutes ces évolutions Pour eux les anciennes technologies Ben elles font des systèmes qui marchent depuis 20 ans Donc à quoi bon ? Est ce vraiment nécessaire d'apprendre de nouvelles manières à de faire surtout qu'on est assez proche de la retraite et qu'on pense déjà à à à d'autres choses le 2nd public c'est des petits jeunes qui ont été petits jeunes ou moins jeunes qui ont été formés très récemment aux technologies de Libye amies pour répondre à un besoin criant dans ces technologies donc on les a formés un peu succinctement aux aux anciennes technologies Je veux dire PG 3 et tout ça et ces gens là en fait ils veulent utiliser les nouvelles technologies ils veulent utiliser les vscode ils veulent utiliser des voilà ils trouvent que c'est un peu compliqué la façon de gérer les sources que voilà donc c'est pour ça qu'on a que que je scinde un peu le le le système en 2 je me dis bah on va garder le Legacy comme ça c'est pas vraiment on n'a pas sauf si bon sauf dans des cas extrêmes mais est ce qu'on a vraiment besoin de dire de faire un un de 2 tout refondre notre système est ce qu'on pourrait pas essayer d'abord de dire bon OK c'est un Legacy mais on va développer au dessus pour le travailler avec voilà et donc Ben cette cette solution que ce que je propose c'est des de développer un peu des de prendre un peu une architecture hexagonale et de développer des petits hexagones des modèles des entités métier en fait des par projets par qui représenteraient des entités métier un peu comme du domaine driven développement Alors je disais domaine anti métier mais plutot un domaine quoi par exemple y a le domaine je sais pas après ça dépend de plein de choses mais voilà ça serait alors ce qui est visé en fait dans dans dans dans ce projet aussi ce qu'il faut voir c'est viser à mon sens c'est c'est c'est dépasser la vision technique la technique elle est au service du métier Pourquoi les nouveaux arrivants ils arrivent pas à comprendre ce qui se passe ? Bah ils arrivent pas à comprendre ce qu'il y a ce que le métier comment il est traduit dans la technologie et c'est pour ça que je parle souvent de de domaines driven développement parce que justement je veux que à la limite dans mes modules dans mes dans mes programmes de service mes entités métier et Ben que les termes utilisés vraiment pour ces procédures et Ben ça respire le métier et pratiquement que quand la personne même si elle vient d'arriver si elle discute avec le métier Ben elle va retrouver un peu dans les dans les dans les dans les dans les sources en fait un peu la vision du métier alors pourquoi je veux faire ça ? Parce que en fait avant si vous voulez on on était dans l'état de l'art ses anciens là c'est des gens qui sont arrivés il y a 20 ans dans la boîte ils sont toujours dans la boîte donc le métier ils le connaissent par cœur voir c'est eux qui ont qui ont dicté le métier Voilà des fois on se retrouve même des des gens du métier qui savent même plus ce qui se fait en fait ils demandent à l'informatique qu'est ce qui se fait vraiment dans dans nos dans notre métier voir parce qu'elles ont tellement trang transgressé leurs besoins métiers parce que en fait on leur répondait par des pesos techniques et ils sont adaptés et maintenant le nouveau public à mon avis c'est un un nouveau public qui qui qui pas déjà qui s'inquiète bizarrement ne s'intéresse pas trop au métier et je pense qu'il faut les intéresser de cette manière là faut pas trop les mettre dans la technique et c'est à mon avis à mon sens c'est un public qui va avoir beaucoup beaucoup beaucoup de turn over Je pense que c'est des gens qui qui qui qui qui qui vont changer de boîte comme ça dès que ça va leur leur dire ils vont pas trop s'embêter et donc bah effectivement le le la compréhension du modèle métier va être très très importante et surtout la compréhension modèle métier et et et technique et en plus maintenant il y a aussi un 2e truc c'est qu'avec l'apport des des des technologies de type IA si on fait pas cet effort là au bout d'un moment on va plus comprendre ce que fait le métier on va plus comprendre vraiment Il est traduit dans le dans le dans le dans le dans le système donc c'est pour ça que je veux faire des je veux mettre en place tout un workflow avec des des des documents qui permettent de transcrire qu'est ce qu'on a fait c'est que soit les choix qu'on a fait et comment on les a 30 transposés dans la technique justement pour permettre pourquoi pas un dialogue avec une IA lui dire Ben par exemple moi je vais faire tel cas d'utilisation et lui il va le commencer à l'implémenter et il va dessus en de fait on va avoir un un dialogue et on va avoir une compréhension et une traçabilité une visibilité de qu'est ce qui a été les choix qui ont été faits pourquoi ils ont été faits de cette manière là



