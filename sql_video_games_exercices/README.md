# Jeu de données à utiliser

Vous pouvez récupérer le jeu de données dans `/sql_video_games_exercices/schema.sql`.

# 🎮 BRIEFING DE MISSION : LE FANGAME ULTIME
### *« Azeroth-Kama-Strike Simulator 2026 »*

Bienvenue dans l'équipe technique du studio indépendant **Nokta-Ankama-Blizz-Valve** !  
Vous venez d'être recrutés comme **Architectes Data & Développeurs SQL** pour propulser le portail communautaire d'un fangame crossover totalement improbable mélangeant :
* Les raids épiques de **World of Warcraft**,
* Les *rush B* millimétrés de **Counter-Strike 2**,
* La gestion stressante des rayons de **Supermarket Simulator**,
* Et le farm intensif de kamas de **Dofus**.

La base de données `sql_video_games` (80 000 lignes réparties sur 25 tables) tourne déjà en pré-production, mais les serveurs commencent à fumer comme un PC portable sur *Dofus Unity* avec 8 comptes ouverts. Votre mission : **optimiser, structurer et interroger** cette base à l'aide des armes des **Modules 1 à 4** de votre support de cours.

---

## 🛠️ Rappel de l'Arsenal SQL (Modules 1 à 4)
* **Module 1** : `EXPLAIN ANALYZE`, opérateurs (`Seq Scan`, `Index Scan`, `Index Only Scan`, `Hash Join`, `Nested Loop`), prédicats **SARGables** et élimination des 5 pièges classiques.
* **Module 2** : Normalisation (**1FN, 2FN, 3FN, BCNF**) et dénormalisation raisonnée.
* **Module 3** : Index B-Tree (simple, composite & règle du préfixe gauche, partiel `WHERE`, couvrant `INCLUDE`), **Vues Matérialisées** et **Partitionnement** (`RANGE`).
* **Module 4** : **CTE** (`WITH`), **Fonctions de fenêtrage** (`OVER`, `DENSE_RANK`, `LAG`, cumul glissant) et **Requêtes récursives** (`WITH RECURSIVE`).

---

## 🎯 EXERCICE 1 : Le Chasseur de Dofus Ocre qui faisait ramer le serveur
*(Module 1 — Plans d'exécution, `EXPLAIN ANALYZE` & Prédicats SARGables)*

### 📜 Contexte & Consigne
Un joueur nostalgique nommé *Goultard_42* cherche à afficher sur son profil toutes les transactions économiques (`market_transactions`) passées **au cours des 30 derniers jours** pour **Dofus** (`game_id = 4`), mais le stagiaire a écrit la requête suivante qui met le serveur à genoux :

```sql
EXPLAIN ANALYZE
SELECT *
FROM market_transactions
WHERE EXTRACT(YEAR FROM transacted_at) = 2026
  AND LOWER(currency_type) = 'kamas'
  AND item_id::TEXT LIKE '%19';
```

1. **Diagnostic** : Exécutez cette requête avec `EXPLAIN ANALYZE` et relevez **3 pièges classiques du Module 1** présents dans ce code (expliquez pourquoi ils empêchent l'optimiseur d'utiliser efficacement les index et la mémoire).
2. **Correction** : Réécrivez la requête de manière **100 % SARGable** (pour récupérer les transactions en `KAMAS` de l'année 2026 sur `item_id = 19`, le fameux *Dofus Ocre*), en ne sélectionnant que les colonnes utiles (`transaction_id`, `seller_character_id`, `buyer_character_id`, `quantity`, `unit_price`, `transacted_at`).

> 💡 **Indice du formateur** : *Ne mettez jamais de fonction (`EXTRACT`, `LOWER`, cast `::TEXT`) autour d'une colonne indexée dans le `WHERE`, et bannissez `SELECT *` comme un Ninja Looter en raid !*

---

## 🎯 EXERCICE 2 : Le Videur de la Porte d'Astrub
*(Module 1 — Jointures `Nested Loop` vs `Hash Join` & Clés étrangères non indexées)*

### 📜 Contexte & Consigne
Pour l'événement « *Foire du Trool & Caisses Automatiques* », la page d'accueil du fangame affiche les **15 dernières sessions de jeu** (`game_sessions`) ayant duré plus de 120 minutes, accompagnées du nom du personnage (`player_characters.character_name`) et du nom de la zone (`game_maps_zones.zone_name`).

1. Écrivez cette requête en limitant le résultat à `LIMIT 15` (trié par `started_at DESC`) et observez son plan d'exécution avec `EXPLAIN ANALYZE`.
2. Quels algorithmes de jointure (`Nested Loop` ou `Hash Join`) le moteur choisit-il ? Pourquoi PostgreSQL parvient-il à joindre `player_characters` très vite, alors que le tri initial sur `game_sessions` peut coûter cher si la table grossit à 10 millions de lignes ?
3. Proposez l'index exact à créer sur `game_sessions` pour transformer le tri (`Sort`) et le filtre (`duration_minutes > 120`) en une lecture quasi instantanée.

> 💡 **Indice du formateur** : *Pensez à l'index partiel (`WHERE duration_minutes > 120`) vu au Module 3, combiné à `started_at DESC` !*

---

## 🎯 EXERCICE 3 : Le Parchemin Maudit de l'Hôtel des Ventes
*(Module 2 — Normalisation 1FN, 2FN, 3FN et BCNF)*

### 📜 Contexte & Consigne
Avant d'utiliser notre belle base `sql_video_games` en 25 tables, l'ancien développeur du fangame avait stocké les ventes de skins CS2 et de céréales Chocopic dans une unique table Excel importée en SQL nommée `ventes_fangame_brutes` :

```text
ventes_fangame_brutes (
    ticket_id,
    vendeur_id,
    vendeur_pseudo,
    vendeur_pays,
    serveur_id,
    serveur_nom,
    gerant_serveur_id,     -- Règle métier : 1 serveur n'a qu'1 seul gérant unique, et 1 gérant ne gère qu'1 seul serveur !
    objets_achetes_liste,  -- Ex: "AWP | Dragon Lore (x1), Caisse Kilowatt (x3)"
    total_ticket
)
```

1. Identifiez **une anomalie de mise à jour** et **une anomalie de suppression** sur cette table si *ZywOo_6* change de pays ou annule son unique vente.
2. Décomposez ce schéma pour l'amener jusqu'en **BCNF (Forme Normale de Boyce-Codd)** en justifiant chaque étape :
   * **1FN** (éclatement de `objets_achetes_liste`),
   * **2FN / 3FN** (dépendances transitives liées au vendeur et au serveur),
   * **BCNF** (gestion du déterminant caché `gerant_serveur_id <-> serveur_id`).
3. Expliquez en 2 lignes pourquoi conserver `unit_price` dans `market_transactions` (alors que `base_virtual_value` existe déjà dans `game_items`) **n'est pas** une violation de la 3FN.

---

## 🎯 EXERCICE 4 : L'Annuaire des Serveurs Saturés (La Règle du Préfixe Gauche)
*(Module 3 — Index Composites, Index Couvrants `INCLUDE` & `Index Only Scan`)*

### 📜 Contexte & Consigne
Aux heures de pointe (quand tout le monde veut se connecter sur *Draconiros* ou *Hyjal-EU*), l'API du fangame exécute des milliers de fois par seconde la requête suivante pour afficher l'annuaire des personnages d'un jeu sur un serveur précis :

```sql
SELECT character_name, level, elo_or_gearscore
FROM player_characters
WHERE game_id = 1
  AND server_id = 1
  AND level >= 70;
```

1. Créez un **index composite couvrant** (`CREATE INDEX ... INCLUDE (...)`) permettant à PostgreSQL de résoudre cette requête **exclusivement via un `Index Only Scan`** (sans jamais aller ouvrir les pages de la table `player_characters`).
2. Vérifiez avec `EXPLAIN ANALYZE` que l'opérateur `Index Only Scan` apparaît bien (astuce : lancez `VACUUM ANALYZE player_characters;` juste avant pour mettre à jour la *Visibility Map* !).
3. **Question piège** : Si un développeur lance ensuite `SELECT character_name FROM player_characters WHERE server_id = 1;` (sans `game_id`), cet index sera-t-il utilisé ? Justifiez grâce à la **règle du préfixe gauche** du Module 3.

---

## 🎯 EXERCICE 5 : La Photo Imprimée du Board des Investisseurs
*(Module 3 — Vues Classiques vs Vues Matérialisées)*

### 📜 Contexte & Consigne
Les sponsors du fangame veulent un tableau de bord affichant, pour chacun des **4 jeux** (`games.title`) et chaque **devise** (`currency_type`), le nombre total de transactions, le volume total d'objets échangés et le chiffre d'affaires virtuel global (`SUM(quantity * unit_price)`), classé par chiffre d'affaires décroissant.

1. Rédigez la création d'une **Vue Matérialisée** nommée `mv_economie_globale_jeux` encapsulant ce calcul lourd sur `market_transactions` et `games`.
2. Simulez une nouvelle vente record d'un *AWP | Dragon Lore* (`item_id = 8`, `game_id = 2`, quantité `1`, prix `12500.00`, devise `'EUR_STEAM'`) entre le personnage `2` et le personnage `6`.
3. Interrogez `mv_economie_globale_jeux` : pourquoi le chiffre d'affaires de *Counter-Strike 2* n'a-t-il pas bougé ? Quelle commande SQL devez-vous exécuter pour mettre à jour cette « photo imprimée » ?

---

## 🎯 EXERCICE 6 : L'Armoire à Archives des Sessions de Jeu
*(Module 3 — Partitionnement `RANGE` et *Partition Pruning*)*

### 📜 Contexte & Consigne
La table `game_sessions` contient 10 000 lignes aujourd'hui, mais avec l'arrivée de la saison 2 de *Supermarket Simulator*, le studio prévoit **50 millions de sessions par an**. Le chef de projet veut découper la table par année grâce au **partitionnement `RANGE`** sur la colonne `started_at`.

1. Écrivez le script DDL complet permettant de créer :
   * La table mère partitionnée `game_sessions_part` (n'oubliez pas la règle d'or sur la `PRIMARY KEY` lors d'un partitionnement !),
   * Trois partitions physiques : `game_sessions_2025`, `game_sessions_2026` et `game_sessions_2027`.
2. Copiez les données de `game_sessions` vers `game_sessions_part` via un `INSERT INTO ... SELECT ...`.
3. Lancez un `EXPLAIN ANALYZE` sur une recherche filtrant uniquement `WHERE started_at >= '2026-06-01' AND started_at < '2026-07-01'`. Quel mécanisme du Module 3 observez-vous dans le plan d'exécution, et quel est l'avantage si la CNIL vous demande demain de purger tout l'historique de 2025 ?

---

## 🎯 EXERCICE 7 : La Recette des « Baleines » du Fangame
*(Module 4 — Common Table Expressions `WITH` en cascade)*

### 📜 Contexte & Consigne
L'équipe marketing veut identifier les **joueurs les plus influents et actifs** (« les Baleines d'Azeroth & d'Amakna ») pour leur offrir un badge exclusif *Caissier d'Or*. Un joueur est éligible s'il cumule **simultanément** :
* Au moins **2 personnages** dans `player_characters`,
* Au moins **100 minutes** cumulées en session de jeu (`game_sessions`),
* Au moins **2 likes** attribués à des jeux catégorisés (`categorized_game_likes`).

1. Construisez une requête ultra-lisible en utilisant **3 CTE chaînées (`WITH`)** :
   * `stats_personnages` (comptage des personnages par `user_id`),
   * `stats_temps_jeu` (somme des `duration_minutes` par `user_id` via `player_characters`),
   * `stats_likes` (comptage des likes par `user_id`).
2. Joignez ces 3 bols d'ingrédients à la table `users` (en filtrant `account_status = 'ACTIVE'`) pour afficher le `username`, le pays, le nombre de persos, le temps de jeu total et le nombre de likes, triés par temps de jeu décroissant (`LIMIT 20`).

---

## 🎯 EXERCICE 8 : Le Podium des Meilleurs Gérants & Gladiateurs (Sans Écraser les Ex-Aequo !)
*(Module 4 — Fonctions de Fenêtrage `DENSE_RANK() OVER`)*

### 📜 Contexte & Consigne
Pour le panneau d'affichage en jeu, vous devez établir le **Top 3 des personnages les plus riches** (`virtual_wallet_balance`) **au sein de chaque jeu** (`games.title`), tout en conservant le nom de leur serveur (`game_servers.server_name`) et leur classe (`game_classes.class_name`).

1. Expliquez en une phrase pourquoi `DENSE_RANK()` est préférable à `ROW_NUMBER()` et à `RANK()` pour établir un « Top 3 » officiel avec gestion équitable des ex-aequo.
2. Écrivez la requête combinant une **CTE** et `DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)` pour afficher le podium complet (12 lignes attendues : 3 par jeu, plus d'éventuels ex-aequo), avec le rang calculé et le solde formaté.

---

## 🎯 EXERCICE 9 : La Météo des Trésoreries & L'Effet Boule de Neige
*(Module 4 — Fonctions de Fenêtrage `LAG()` et Cumul Glissant `SUM() OVER`)*

### 📜 Contexte & Consigne
Le Ministère des Finances de *Supermarket Simulator* (`game_id = 3`) souhaite analyser l'évolution quotidienne du chiffre d'affaires des ventes en rayon (`currency_type = 'USD_STORE'`) sur les **15 derniers jours d'activité**.

1. Dans une première CTE `ca_journalier`, agrégez par jour (`DATE(transacted_at)`) le chiffre d'affaires quotidien (`ca_jour = SUM(quantity * unit_price)`).
2. Dans la requête principale, utilisez des **fonctions de fenêtrage** (sans aucune auto-jointure !) pour afficher pour chaque jour :
   * La date du jour,
   * Le chiffre d'affaires du jour (`ca_jour`),
   * Le chiffre d'affaires de la veille (`ca_veille` via `LAG(..., 1, 0)`),
   * L'écart financier par rapport à la veille (`ca_jour - ca_veille`),
   * Le **chiffre d'affaires cumulé progressif** depuis le début de la période (`SUM(ca_jour) OVER (ORDER BY jour ASC)`).

---

## 🎯 EXERCICE 10 : L'Arbre des Genres & La Chasse aux Amis d'Amis
*(Module 4 — Requêtes Récursives `WITH RECURSIVE`)*

### 📜 Contexte & Consigne
Les requêtes récursives sont l'arme ultime pour explorer des hiérarchies ou des graphes sociaux sur une profondeur inconnue. Vous avez deux missions récursives :

1. **Mission A (Arborescence des catégories)** : La table `categories` possède une auto-référence `parent_category_id` (ex: *Action -> Tir à la première personne (FPS) -> Shooter Tactique*). Écrivez une requête `WITH RECURSIVE` qui part des catégories racines (`parent_category_id IS NULL`) et affiche chaque catégorie avec son **niveau de profondeur** (`niveau`) et son **fil d'Ariane complet** (ex: `Action > Tir à la première personne (FPS) > Shooter Tactique`).
2. **Mission B (Réseau d'amitiés à 3 degrés — Prévention de boucle infinie !)** : À partir de l'utilisateur `user_id = 1` (*Kaelthas_1*), explorez la table `user_friendships` (uniquement les relations `status = 'ACCEPTED'`) pour trouver ses amis directs (degré 1), les amis de ses amis (degré 2) et les amis des amis de ses amis (degré 3).
   * **Attention au piège mortel du Module 4** : Les amitiés forment des cycles (A est ami avec B, B est ami avec C, C est ami avec A) ! Intégrez impérativement une **condition d'arrêt sur la profondeur** (`niveau < 3`) et un tableau de chemin parcouru (`ARRAY[requester_id]`) pour éviter de revisiter un joueur déjà croisé.

---
---

# 🔐 CORRIGÉ TYPE & EXPLICATIONS PÉDAGOGIQUES

### Corrigé Exercice 1
1. **Les 3 pièges identifiés :**
   * **Prédicats non-SARGables (`EXTRACT(...)`, `LOWER(...)`, `item_id::TEXT`)** : Appliquer une fonction ou un transtypage sur la colonne indexée empêche PostgreSQL de descendre l'arbre B-Tree (`idx_market_game_date`), forçant un `Seq Scan` coûteux en $O(N)$.
   * **`SELECT *` par réflexe** : Force la lecture complète de toutes les colonnes de la table (*Heap Fetch*), empêchant tout `Index Only Scan` et surchargeant la mémoire/le réseau.
   * **Wildcard `%` en début de `LIKE` (`LIKE '%19'`)** : Un index B-Tree se lit de gauche à droite ; avec `%` au début, l'index est aveugle.
2. **Requête SARGable optimisée :**
```sql
EXPLAIN ANALYZE
SELECT transaction_id, seller_character_id, buyer_character_id, quantity, unit_price, transacted_at
FROM market_transactions
WHERE game_id = 4
  AND transacted_at >= '2026-01-01 00:00:00+00'
  AND transacted_at <  '2027-01-01 00:00:00+00'
  AND currency_type = 'KAMAS'
  AND item_id = 19;
```

### Corrigé Exercice 2
1. **Requête initiale :**
```sql
EXPLAIN ANALYZE
SELECT gs.session_id, pc.character_name, zm.zone_name, gs.duration_minutes, gs.started_at
FROM game_sessions gs
JOIN player_characters pc ON pc.character_id = gs.character_id
JOIN game_maps_zones zm ON zm.zone_id = gs.zone_id
WHERE gs.duration_minutes > 120
ORDER BY gs.started_at DESC
LIMIT 15;
```
2. **Analyse du plan :** Grâce au `LIMIT 15` (Top-N Heapsort), l'entrée externe ne produit que 15 lignes. PostgreSQL utilise donc un **`Nested Loop`** redoutablement efficace ($O(N \log M)$) en s'appuyant sur les clés primaires indexées (`player_characters_pkey` et `game_maps_zones_pkey`). En revanche, sur `game_sessions`, il doit effectuer un `Seq Scan` + `Sort` complet car ni `duration_minutes` ni `started_at` seul ne sont indexés.
3. **Index partiel optimal :**
```sql
CREATE INDEX idx_sessions_longues_recentes
ON game_sessions (started_at DESC)
WHERE duration_minutes > 120;
```

### Corrigé Exercice 3
1. **Anomalies :**
   * *Anomalie de mise à jour* : Si *ZywOo_6* déménage, il faut modifier toutes ses lignes de vente ; en cas de coupure à mi-parcours, sa nationalité devient incohérente dans la base.
   * *Anomalie de suppression* : Si on supprime l'unique vente d'un joueur, on perd définitivement son pseudo et son pays.
2. **Décomposition BCNF :**
   * **1FN** : Création de `lignes_ventes(ticket_id, item_id, quantite)` pour supprimer la liste à virgules `objets_achetes_liste`.
   * **2FN / 3FN** : Extraction des attributs transitifs dans `vendeurs(vendeur_id PK, vendeur_pseudo, vendeur_pays)` et `serveurs(serveur_id PK, serveur_nom)`.
   * **BCNF** : Comme `gerant_serveur_id <-> serveur_id` est une bijection (déterminant caché), on isole une table dédiée `serveur_gerants(gerant_serveur_id PK, serveur_id UNIQUE REFERENCES serveurs(serveur_id))`.
3. **Historisation métier (Dénormalisation raisonnée)** : `unit_price` dans `market_transactions` représente le **prix historique payé au moment T** de la transaction, tandis que `base_virtual_value` dans `game_items` est le **prix catalogue actuel** (qui peut évoluer à chaque patch). Ce sont deux informations distinctes.

### Corrigé Exercice 4
1. **Création de l'index composite couvrant :**
```sql
CREATE INDEX idx_chars_game_server_lvl_covering
ON player_characters (game_id, server_id, level)
INCLUDE (character_name, elo_or_gearscore);

VACUUM ANALYZE player_characters;
```
2. **Vérification :** `EXPLAIN ANALYZE` affiche désormais `Index Only Scan using idx_chars_game_server_lvl_covering on player_characters` avec `Heap Fetches: 0`.
3. **Règle du préfixe gauche :** **Non**, l'index ne sera pas utilisé pour un filtre uniquement sur `server_id = 1`, car `game_id` est la colonne de tête (à gauche) de l'index composite. Sans la valeur de `game_id`, les `server_id` sont dispersés sous chaque `game_id`.

### Corrigé Exercice 5
```sql
-- 1. Création de la vue matérialisée
CREATE MATERIALIZED VIEW mv_economie_globale_jeux AS
SELECT
    g.title AS jeu,
    mt.currency_type AS devise,
    COUNT(mt.transaction_id) AS nb_transactions,
    SUM(mt.quantity) AS volume_objets_echanges,
    ROUND(SUM(mt.quantity * mt.unit_price), 2) AS ca_virtuel_total
FROM market_transactions mt
JOIN games g ON g.game_id = mt.game_id
GROUP BY g.title, mt.currency_type
ORDER BY ca_virtuel_total DESC;

-- 2. Simulation de vente
INSERT INTO market_transactions (game_id, seller_character_id, buyer_character_id, item_id, quantity, unit_price, currency_type)
VALUES (2, 2, 6, 8, 1, 12500.00, 'EUR_STEAM');

-- 3. Rafraîchissement de la vue matérialisée (photo réimprimée)
REFRESH MATERIALIZED VIEW mv_economie_globale_jeux;
SELECT * FROM mv_economie_globale_jeux;
```

### Corrigé Exercice 6
```sql
-- 1. Table mère et partitions
CREATE TABLE game_sessions_part (
    session_id INT GENERATED BY DEFAULT AS IDENTITY,
    character_id INT NOT NULL,
    zone_id INT,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INT NOT NULL,
    outcome VARCHAR(20),
    score_or_profit NUMERIC(12, 2),
    PRIMARY KEY (session_id, started_at) -- Clé de partition obligatoire dans la PK !
) PARTITION BY RANGE (started_at);

CREATE TABLE game_sessions_2025 PARTITION OF game_sessions_part
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

CREATE TABLE game_sessions_2026 PARTITION OF game_sessions_part
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE game_sessions_2027 PARTITION OF game_sessions_part
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');

-- 2. Alimentation
INSERT INTO game_sessions_part
SELECT session_id, character_id, zone_id, started_at, duration_minutes, outcome, score_or_profit
FROM game_sessions;

-- 3. Vérification du Partition Pruning
EXPLAIN ANALYZE
SELECT COUNT(*) FROM game_sessions_part
WHERE started_at >= '2026-06-01 00:00:00+00' AND started_at < '2026-07-01 00:00:00+00';
```
*Explication :* PostgreSQL applique le **Partition Pruning** (il n'ouvre que `game_sessions_2026` et ignore les tiroirs 2025 et 2027). Pour purger 2025, un simple `DROP TABLE game_sessions_2025;` supprime toutes les archives en quelques millisecondes sans verrouiller la table.

### Corrigé Exercice 7
```sql
WITH stats_personnages AS (
    SELECT user_id, COUNT(*) AS nb_persos
    FROM player_characters
    GROUP BY user_id
    HAVING COUNT(*) >= 2
),
stats_temps_jeu AS (
    SELECT pc.user_id, SUM(gs.duration_minutes) AS total_minutes
    FROM game_sessions gs
    JOIN player_characters pc ON pc.character_id = gs.character_id
    GROUP BY pc.user_id
    HAVING SUM(gs.duration_minutes) >= 100
),
stats_likes AS (
    SELECT user_id, COUNT(*) AS nb_likes
    FROM categorized_game_likes
    GROUP BY user_id
    HAVING COUNT(*) >= 2
)
SELECT
    u.username,
    u.country_code,
    sp.nb_persos,
    st.total_minutes,
    sl.nb_likes
FROM users u
JOIN stats_personnages sp ON sp.user_id = u.user_id
JOIN stats_temps_jeu st   ON st.user_id = u.user_id
JOIN stats_likes sl       ON sl.user_id = u.user_id
WHERE u.account_status = 'ACTIVE'
ORDER BY st.total_minutes DESC
LIMIT 20;
```

### Corrigé Exercice 8
1. **Justification :** `DENSE_RANK()` attribue le même rang aux ex-aequo sans sauter de numéro ensuite (`1, 2, 2, 3`), garantissant d'afficher les 3 meilleurs niveaux de richesse réels contrairement à `ROW_NUMBER()` (qui départage arbitrairement) ou `RANK()` (qui saute le rang 3 en cas d'égalité en 2e position).
2. **Requête :**
```sql
WITH classement_richesse AS (
    SELECT
        g.title AS jeu,
        gs.server_name AS serveur,
        gc.class_name AS classe,
        pc.character_name AS personnage,
        pc.virtual_wallet_balance AS fortune,
        DENSE_RANK() OVER (
            PARTITION BY pc.game_id
            ORDER BY pc.virtual_wallet_balance DESC
        ) AS rang_richesse
    FROM player_characters pc
    JOIN games g ON g.game_id = pc.game_id
    JOIN game_servers gs ON gs.server_id = pc.server_id
    LEFT JOIN game_classes gc ON gc.class_id = pc.class_id
)
SELECT jeu, rang_richesse, personnage, classe, serveur, fortune
FROM classement_richesse
WHERE rang_richesse <= 3
ORDER BY jeu ASC, rang_richesse ASC, personnage ASC;
```

### Corrigé Exercice 9
```sql
WITH ca_journalier AS (
    SELECT
        DATE(transacted_at) AS jour,
        ROUND(SUM(quantity * unit_price), 2) AS ca_jour
    FROM market_transactions
    WHERE game_id = 3
      AND currency_type = 'USD_STORE'
    GROUP BY DATE(transacted_at)
    ORDER BY jour DESC
    LIMIT 15
)
SELECT
    jour,
    ca_jour,
    LAG(ca_jour, 1, 0.00) OVER (ORDER BY jour ASC) AS ca_veille,
    ca_jour - LAG(ca_jour, 1, 0.00) OVER (ORDER BY jour ASC) AS evolution_quotidienne,
    SUM(ca_jour) OVER (ORDER BY jour ASC) AS ca_cumule_glissant
FROM ca_journalier
ORDER BY jour ASC;
```

### Corrigé Exercice 10
```sql
-- Mission A : Arborescence complète des catégories
WITH RECURSIVE arbre_categories AS (
    -- 1. Ancrage (Catégories racines)
    SELECT
        category_id,
        category_name,
        parent_category_id,
        1 AS niveau,
        category_name::TEXT AS fil_ariane
    FROM categories
    WHERE parent_category_id IS NULL

    UNION ALL

    -- 2. Récursion
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        ac.niveau + 1,
        ac.fil_ariane || ' > ' || c.category_name
    FROM categories c
    JOIN arbre_categories ac ON c.parent_category_id = ac.category_id
    WHERE ac.niveau < 10 -- Garde-fou anti-boucle
)
SELECT category_id, niveau, fil_ariane
FROM arbre_categories
ORDER BY fil_ariane ASC;

-- Mission B : Réseau d'amitiés à 3 degrés autour de user_id = 1 (avec protection anti-cycles)
WITH RECURSIVE reseau_amis AS (
    -- 1. Ancrage : amis directs de user_id = 1
    SELECT
        uf.addressee_id AS ami_id,
        1 AS degre_separation,
        ARRAY[1, uf.addressee_id] AS chemin_visite
    FROM user_friendships uf
    WHERE uf.requester_id = 1
      AND uf.status = 'ACCEPTED'

    UNION ALL

    -- 2. Récursion : amis des amis jusqu'au degré 3 sans repasser par un nœud déjà visité
    SELECT
        uf.addressee_id AS ami_id,
        ra.degre_separation + 1,
        ra.chemin_visite || uf.addressee_id
    FROM user_friendships uf
    JOIN reseau_amis ra ON uf.requester_id = ra.ami_id
    WHERE uf.status = 'ACCEPTED'
      AND ra.degre_separation < 3
      AND NOT (uf.addressee_id = ANY(ra.chemin_visite)) -- Bloque les cycles !
)
SELECT DISTINCT
    ra.degre_separation,
    u.user_id,
    u.username,
    u.country_code
FROM reseau_amis ra
JOIN users u ON u.user_id = ra.ami_id
ORDER BY ra.degre_separation ASC, u.user_id ASC;
```