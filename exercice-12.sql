-- Exercice 12 : Décoder les boucles (loops) dans EXPLAIN ANALYZE
-- ● Scénario : Tu veux afficher le nom de chaque entrepôt ainsi que le nom et le stock de chaque produit qu'il héberge.
-- ● Mission : Exécute :
-- EXPLAIN ANALYZE
-- SELECT e.nom AS entrepot, p.nom AS produit, p.stock
-- FROM entrepots e
-- JOIN produits p ON p.entrepot_id = e.id;
-- Lis l'arbre de l'intérieur vers l'extérieur, identifie le nombre de loops sur la recherche d'index fk_produits_entrepot et calcule le temps réel total passé dans cette boucle.

EXPLAIN ANALYZE
SELECT e.nom AS entrepot, p.nom AS produit, p.stock
FROM entrepots e
JOIN produits p ON p.entrepot_id = e.id;

-- Table scan on e  (cost=0.65 rows=4) (actual time=0.0258..0.0273 rows=4 loops=1) 
-- Donc 0.0273 * 1 = 0.0273ms | 4 rows

-- Index lookup on p using fk_produits_entrepot | actual time=0.0127..0.0155 rows=6 loops=4
-- Donc 0.0155 * 4 = 0.062ms | 6 rows

-- Nested loop inner join  (cost=5.45 rows=24) (actual time=0.0548..0.0932 rows=24 loops=1)
-- Donc 0.0932ms réels en usage pour 4 * 6 = 24 rows