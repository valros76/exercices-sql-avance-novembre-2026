-- Exercice 3 : Valorisation financière par rayon
-- ● Scénario : La direction financière prépare le bilan trimestriel et veut
-- connaître la valeur marchande totale dormant dans nos entrepôts pour
-- chaque catégorie de matériel.
-- ● Mission : Calcule la somme de prix_unitaire * stock pour chaque catégorie, en affichant le nom de la catégorie et le montant total arrondi à 2 décimales.
-- ● Indice & Objectif : Réaliser une jointure propre (INNER JOIN) entre produits et categories couplée à un regroupement (GROUP BY).l

SELECT 
c.id AS category_id,
c.nom AS category_name,
SUM(prix_unitaire * stock) AS total_stock_value
FROM categories c
INNER JOIN produits p ON c.id = p.categorie_id
GROUP BY c.id, c.nom;