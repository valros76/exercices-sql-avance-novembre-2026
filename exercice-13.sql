-- Exercice 13 : La pagination infinie sans essoufflement (Keyset
-- Pagination)
-- ● Scénario : Le catalogue web pagine les produits 5 par 5. Sur une table de millions de lignes, SELECT id, nom FROM produits ORDER BY id LIMIT 5
-- OFFSET 15; oblige le moteur à lire et jeter les 15 premières lignes avant
-- d'afficher les 5 suivantes.
-- ● Mission : Remplace ce OFFSET coûteux par la technique du Keyset
-- Pagination (en supposant que le dernier id affiché sur la page précédente
-- était 15) et compare le nombre de lignes parcourues (rows) dans EXPLAIN
-- ANALYZE.

-- EXPLAIN ANALYZE
-- SELECT id, nom FROM produits ORDER BY id LIMIT 5 OFFSET 15;
-- Limit/Offset: 5/15 row(s)  (cost=1.88 rows=5) (actual time=0.039..0.0415 rows=5 loops=1)
-- -> Index scan on produits using PRIMARY  (cost=1.88 rows=20) (actual time=0.0304..0.0395 rows=20 loops=1)

EXPLAIN ANALYZE
SELECT id, nom 
FROM produits 
WHERE id > 15 
ORDER BY id ASC 
LIMIT 5;
-- -> Limit: 5 row(s)  (cost=2.06 rows=5) (actual time=0.0212..0.0232 rows=5 loops=1)
--     -> Filter: (produits.id > 15)  (cost=2.06 rows=9) (actual time=0.0204..0.0222 rows=5 loops=1)
--         -> Index range scan on produits using PRIMARY over (15 < id)  (cost=2.06 rows=9) (actual time=0.0193..0.0207 rows=5 loops=1)