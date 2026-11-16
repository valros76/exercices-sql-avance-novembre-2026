-- Exercice 14 : Le podium sans écraser les lignes (CTE + DENSE_RANK)
-- ● Scénario : Le directeur commercial veut mettre en avant sur la page
-- d'accueil les 2 produits les plus chers de chaque catégorie, tout en
-- conservant leur prix et leur rang exact.
-- ● Mission : Construis une CTE (WITH) utilisant DENSE_RANK() OVER (PARTITION BY categorie_id ORDER BY prix_unitaire DESC), filtre les 2 premiers rangs de chaque catégorie et inspecte le nœud Window aggregate avec EXPLAIN ANALYZE.

EXPLAIN ANALYZE
WITH ClassementProduits AS (
    SELECT 
        categorie_id,
        nom,
        prix_unitaire,
        DENSE_RANK() OVER (
            PARTITION BY categorie_id 
            ORDER BY prix_unitaire DESC
        ) AS rang
    FROM produits
)
SELECT 
    categorie_id,
    nom,
    prix_unitaire,
    rang
FROM ClassementProduits
WHERE rang <= 2
ORDER BY categorie_id ASC, rang ASC;

-- -> Window aggregate: dense_rank() OVER (PARTITION BY produits.categorie_id ORDER BY produits.prix_unitaire desc )   (cost=0 rows=24) (actual time=0.081..0.0932 rows=24 loops=1)

-- et contient :
-- -> Sort: produits.categorie_id, produits.prix_unitaire DESC  (cost=2.65 rows=24) (actual time=0.0667..0.0684 rows=24 loops=1)
-- -> Table scan on produits  (cost=2.65 rows=24) (actual time=0.0311..0.0441 rows=24 loops=1)