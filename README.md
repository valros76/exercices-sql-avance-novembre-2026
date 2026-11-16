# 🚀 Mission DataLab B2 : De Padawan SQL à Maître de l'Optimisation

Bienvenue chez DataLab B2, ton infrastructure e-commerce et datacenter ! 
Ton rôle : accompagner la croissance de l'entreprise en auditant et optimisant nos requêtes SQL sur la base advanced_sql (MySQL 8.4 / InnoDB).
Chaque exercice suit un fil conducteur métier réel et t'amène progressivement de l'écriture de requêtes propres jusqu'à la lecture chirurgicale des plans d'exécution avec EXPLAIN ANALYZE.

# 🌱 Acte I : Les fondamentaux d'un code propre (Exercices 1 à 4)
Avant de sortir le chronomètre EXPLAIN ANALYZE, assurons-nous que nos fondations sont saines et que nous ne gaspillons pas les ressources du serveur.

## Exercice 1 : Le réflexe anti-SELECT * (L'annuaire VIP)

**Scénario :** L'équipe marketing prépare une campagne de fidélisation et te demande simplement la liste des clients avec leur segment (Entreprise, Grand Compte, PME, Startup).
**Mission :** Écris la requête récupérant uniquement le nom et le segment des clients. 
Lance ensuite `EXPLAIN` devant ta requête et observe la colonne Extra.
**Indice & Objectif :** Repère l'index `idx_clients_covering` déjà présent dans ta base. 
Grâce à lui, InnoDB lit directement le sommaire sans ouvrir la table principale (`Using index` / `Index Only Scan`).

## Exercice 2 : Alerte rupture de stock !

**Scénario :** Le responsable logistique de l'entrepôt Paris-Nord craint des ruptures sur les équipements critiques. 
Il veut la liste des produits ayant un stock strictement inférieur à 25 unités, triés du stock le plus critique au plus confortable.
**Mission :** Affiche l'id, le nom et le stock des produits concernés.
**Indice & Objectif :** Maîtriser le filtrage (`WHERE`) et le tri (`ORDER BY`) en ne ramenant que les colonnes utiles.

## Exercice 3 : Valorisation financière par rayon

**Scénario :** La direction financière prépare le bilan trimestriel et veut connaître la valeur marchande totale dormant dans nos entrepôts pour chaque catégorie de matériel.
**Mission :** Calcule la somme de `prix_unitaire * stock` pour chaque catégorie, en affichant le nom de la catégorie et le montant total arrondi à 2 décimales.
**Indice & Objectif :** Réaliser une jointure propre (`INNER JOIN`) entre produits et categories couplée à un regroupement (`GROUP BY`).

## Exercice 4 : Le ménage de printemps dans les index

**Scénario :** En auditant la structure de la table produits, tu découvres que deux développeurs ont créé chacun leur propre index sur la même colonne nom (`idx_produits_nom` et `idx_p`).
**Mission :** Explique pourquoi ce doublon ralentit chaque ajout ou modification de produit, puis rédige la requête ALTER TABLE pour supprimer l'index redondant `idx_p`.
**Indice & Objectif :** Comprendre qu'un index accélère la lecture (SELECT), mais a un coût en écriture (INSERT, UPDATE, DELETE).

# 🕵️ Acte II : Déjouer les pièges classiques en production (Exercices 5 à 8)
Le trafic sur DataLab B2 augmente. Certaines requêtes commencent à ralentir le serveur à cause de mauvais réflexes de syntaxe.

## Exercice 5 : La machine à remonter le temps (Prédicats SARGables)

**Scénario :** Le service commercial veut retrouver les clients inscrits en 2024. 
Un stagiaire a écrit :
```sql
SELECT nom, email FROM clients WHERE YEAR(date_inscription) = 2024;
```
**Mission :** Ajoute un index sur `clients(date_inscription)`, explique pourquoi `YEAR(...)` rend cet index aveugle, puis réécris la requête avec des bornes d'intervalle (prédicat SARGable).
**Indice & Objectif :** Ne jamais enfermer une colonne indexée dans une fonction dans la clause `WHERE`.

## Exercice 6 : Chercher une aiguille dans le catalogue (LIKE)

**Scénario :** Un client cherche tous les produits contenant le mot 'Cluster' avec `WHERE nom LIKE '%Cluster%'`.
**Mission :** Exécute EXPLAIN ANALYZE sur cette requête et constate le balayage complet (`Table scan` / `type = ALL`). 
Réécris ensuite la recherche pour trouver les produits commençant par `'Licence'` (`LIKE 'Licence%'`) et compare les plans d'exécution.
**Indice & Objectif :** Un index B-Tree se lit de gauche à droite : un `%` au début neutralise l'index.

## Exercice 7 : Le tri inutile avant le rangement

**Scénario :** Tu tombes sur cette requête dans le code d'un tableau de bord :
```sql
SELECT entrepot_id, COUNT(*) AS nb_references
FROM (SELECT entrepot_id, prix_unitaire FROM produits ORDER BY prix_unitaire DESC) t
GROUP BY entrepot_id;
```
**Mission :** Repère l'étape `Sort` inutile dans `EXPLAIN ANALYZE` et réécris la requête de façon optimale.
**Indice & Objectif :** `GROUP BY` regroupe les lignes sans se soucier de leur ordre initial.
Trier avant de regrouper consomme de la RAM (`sort_buffer_size`) pour rien.

## Exercice 8 : Le mystère des employés fantômes (NOT IN vs NULL)

**Scénario :** Les RH veulent la liste des employés qui n'encadrent personne (ceux qui ne sont pas managers). 
Un collègue lance :
```sql
SELECT id, nom FROM employes WHERE id NOT IN (SELECT manager_id FROM employes);
```
**Problème :** la requête renvoie 0 ligne, alors que plusieurs techniciens n'ont aucune équipe !
**Mission :** Explique pourquoi la présence de Claire Moreau (`manager_id IS NULL`) fait échouer le `NOT IN` (logique ternaire SQL), et corrige la requête avec `NOT EXISTS`.

# ⚙️ Acte III : Maîtriser les index composites et EXPLAIN ANALYZE (Exercices 9 à 12)
Tu passes en mode chirurgien : tu lis les arbres d'exécution de l'intérieur vers l'extérieur et tu sculptes tes index sur mesure.

## Exercice 9 : La règle du préfixe gauche

**Scénario :** La table commandes dispose déjà de l'index composite `idx_clients_commandes_livrees (statut, client_id, montant_total)`.
**Mission :** Analyse avec `EXPLAIN` ces deux requêtes et explique pourquoi la première est ultra-rapide alors que la seconde balaye tout l'index ou la table :
```sql
SELECT client_id, montant_total FROM commandes WHERE statut = 'LIVREE';
SELECT statut, montant_total FROM commandes WHERE client_id = 2;
```
**Indice & Objectif :** Un index composite fonctionne comme un annuaire trié par `Nom`, puis `Prénom` : impossible de chercher directement par prénom sans connaître le nom.

## Exercice 10 : Éviter le double saut d'InnoDB (Covering Index)

**Scénario :** L'agence de Lyon affiche en permanence sur son écran mural la liste de ses clients locaux : `SELECT nom, ville, email FROM clients WHERE ville = 'Lyon';`.
**Mission :** Observe le plan actuel avec `EXPLAIN`, puis crée un index composite `idx_clients_ville_couvrant` permettant de répondre à cette requête sans jamais toucher à la table principale (`Extra: Using index`).

## Exercice 11 : Éliminer un Sort grâce à un index ordonné

**Scénario :** Sur le site web, la page de la catégorie 2 (`Réseau & Sécurité`) affiche toujours les produits classés du plus cher au moins cher (`ORDER BY prix_unitaire DESC`).
**Mission :** Lance `EXPLAIN ANALYZE` sur cette requête et repère le nœud de tri (`Sort`). 
Crée ensuite l'index composite (`categorie_id, prix_unitaire`) et vérifie dans `EXPLAIN ANALYZE` que le tri a disparu !

## Exercice 12 : Décoder les boucles (loops) dans EXPLAIN ANALYZE

**Scénario :** Tu veux afficher le nom de chaque entrepôt ainsi que le nom et le stock de chaque produit qu'il héberge.
**Mission :** 
Exécute :
```sql
EXPLAIN ANALYZE
SELECT e.nom AS entrepot, p.nom AS produit, p.stock
FROM entrepots e
JOIN produits p ON p.entrepot_id = e.id;
```
Lis l'arbre de l'intérieur vers l'extérieur, identifie le nombre de loops sur la recherche d'index `fk_produits_entrepot` et calcule le temps réel total passé dans cette boucle.

# 🏆 Acte IV : SQL Analytique & Défi Final (Exercices 13 à 15)

Place aux fonctionnalités avancées du SQL moderne pour le pilotage stratégique de DataLab B2.

## Exercice 13 : La pagination infinie sans essoufflement (Keyset Pagination)

**Scénario :** Le catalogue web pagine les produits 5 par 5. 
Sur une table de millions de lignes, `SELECT id, nom FROM produits ORDER BY id LIMIT 5 OFFSET 15;` oblige le moteur à lire et jeter les 15 premières lignes avant d'afficher les 5 suivantes.
**Mission :** Remplace ce `OFFSET` coûteux par la technique du `Keyset Pagination` (en supposant que le dernier id affiché sur la page précédente était 15) et compare le nombre de lignes parcourues (`rows`) dans `EXPLAIN ANALYZE`.


## Exercice 14 : Le podium sans écraser les lignes (CTE + DENSE_RANK)

**Scénario :** Le directeur commercial veut mettre en avant sur la page d'accueil les 2 produits les plus chers de chaque catégorie, tout en conservant leur prix et leur rang exact.
**Mission :** Construis une `CTE` (`WITH`) utilisant `DENSE_RANK() OVER (PARTITION BY categorie_id ORDER BY prix_unitaire DESC)`, filtre les 2 premiers rangs de chaque catégorie et inspecte le nœud `Window aggregate` avec `EXPLAIN ANALYZE`.

## Exercice 15 : 🎯 Le Boss Final — Audit Stratégique & Organigramme Économique

**Scénario :** La CTO, Claire Moreau (`manager_id IS NULL`), te demande un rapport complet pour préparer la réorganisation annuelle de l'entreprise. Elle veut visualiser l'ensemble de la chaîne hiérarchique depuis la direction jusqu'au terrain, tout en comparant le salaire de chaque collaborateur à la moyenne de son propre département.
**Mission :** Combine trois notions avancées dans une seule requête propre, lisible et sécurisée :
- Récursivité (`WITH RECURSIVE`) : Pars de Claire Moreau (`niveau = 1`) et descends toute la hiérarchie (`employes`) en construisant le fil d'Ariane complet (`chemin, ex. Claire Moreau > Marc Delacroix > Antoine Renaud`) et son niveau. 
- Ajoute un garde-fou `WHERE niveau < 10` contre les boucles infinies.
- Fonction de fenêtrage (`OVER`) : Dans la requête finale, affiche pour chaque employé son salaire, le salaire moyen de son departement (`AVG(salaire) OVER (PARTITION BY departement)`), ainsi que l'écart en euros entre son salaire et la moyenne de son équipe.
- Analyse de performance (`EXPLAIN ANALYZE`) : Exécute ton œuvre avec `EXPLAIN ANALYZE`, repère l'étape la plus coûteuse (la récursivité ou le `Window aggregate` / `Sort`) et vérifie qu'aucun `SELECT *` ni tri superflu ne vient alourdir l'exécution.

