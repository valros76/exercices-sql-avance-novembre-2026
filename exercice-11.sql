-- Exercice 11 : Éliminer un Sort grâce à un index ordonné
-- ● Scénario : Sur le site web, la page de la catégorie 2 (Réseau & Sécurité) affiche toujours les produits classés du plus cher au moins cher (ORDER BY prix_unitaire DESC).
-- ● Mission : Lance EXPLAIN ANALYZE sur cette requête et repère le nœud de tri (Sort). Crée ensuite l'index composite (categorie_id, prix_unitaire) et vérifie dans EXPLAIN ANALYZE que le tri a disparu !

CREATE INDEX idx_produits_cat_prix ON produits(categorie_id, prix_unitaire DESC);
EXPLAIN ANALYZE
SELECT 
p.nom AS product_name,
c.nom AS category_name,
p.prix_unitaire AS product_price
FROM categories c
INNER JOIN produits p ON p.categorie_id = c.id
WHERE c.id = 2
ORDER BY p.prix_unitaire DESC;
