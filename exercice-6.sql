-- Exercice 6 : Chercher une aiguille dans le catalogue (LIKE)
-- ● Scénario : Un client cherche tous les produits contenant le mot 'Cluster' avec WHERE nom LIKE '%Cluster%'.
-- ● Mission : Exécute EXPLAIN ANALYZE sur cette requête et constate le
-- balayage complet (Table scan / type = ALL). Réécris ensuite la recherche pour
-- trouver les produits commençant par 'Licence' (LIKE 'Licence%') et compare
-- les plans d'exécution.
-- ● Indice & Objectif : Un index B-Tree se lit de gauche à droite : un % au début
-- neutralise l'index.

EXPLAIN ANALYZE
SELECT *
FROM produits
WHERE nom LIKE "%Cluster%";

EXPLAIN ANALYZE
SELECT nom
FROM produits
WHERE nom LIKE "Licence%";