-- Correction de la requête initiale pour coller aux données réelles de la BDD
CREATE INDEX idx_characters_game_server_level_cov
ON characters (game_id, server_id, level_or_rank, character_name);

-- Mise à jour des statistiques dans l'index
ANALYZE TABLE characters;

-- Vérification de l'utilisation de "using Index"
EXPLAIN
SELECT character_name, level_or_rank
FROM characters
WHERE game_id = 1
  AND server_id = 2
  AND level_or_rank >= 70;

-- Vérification de l'exécution réelle
EXPLAIN ANALYZE
SELECT character_name, level_or_rank
FROM characters
WHERE game_id = 1
  AND server_id = 2
  AND level_or_rank >= 70;


-- Si un développeur lance ensuite SELECT character_name FROM player_characters WHERE server_id = 1; (sans game_id), cet index sera-t-il utilisé ?

-- Non, l'index ne peut pas être utilisé pour une recherche directe.
-- Un index B-Tree composite (game_id, server_id, ...) est trié d'abord par game_id, et server_id n'est trié qu'à l'intérieur de chaque valeur identique de game_id (comme un annuaire trié par Nom, puis par Prénom). Sans connaître game_id (le préfixe gauche), les entrées ayant server_id = 1 sont éparpillées dans tout l'index et ne forment pas un bloc contigu.