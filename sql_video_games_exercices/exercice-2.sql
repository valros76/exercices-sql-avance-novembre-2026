CREATE INDEX idx_game_sessions_long_recent
ON game_sessions (started_at DESC, duration_minutes, character_id, map_id);
EXPLAIN ANALYZE
SELECT
c.character_name AS nom_perso,
gmd.display_name AS nom_zone,
duration_minutes AS duree_session_en_mn
FROM game_sessions gs
INNER JOIN characters c ON c.id = gs.character_id
INNER JOIN game_maps_dungeons gmd ON gmd.id = gs.map_id
WHERE duration_minutes > 120
ORDER BY started_at DESC
LIMIT 15;

-- Grâce au LIMIT 15, MySQL choisit presque systématiquement des Nested Loop Joins (boucles imbriquées) pilotées par l'index de clé primaire (Index Scan / Index Only Scan) sur characters(id) et game_maps_dungeons(id).

-- Comme PostgreSQL, MySQL utilise un Nested Loop Inner Join piloté par les clés primaires (eq_ref sur c.id et gmd.id). Comme il n'y a que 15 lignes en sortie, il n'effectue que 15 lectures ponctuelles par clé primaire sur chaque table jointe (quasi instantané).

-- Sans index adapté, MySQL effectue un Table Scan complet sur game_sessions, filtre les lignes où duration_minutes > 120, puis applique un Sort (filesort) en mémoire (priority queue grâce au LIMIT 15). Même avec cette optimisation, il doit lire et tester les 10 millions de lignes sur le disque avant de s'arrêter.