-- Exercice 15 : 🎯 Le Boss Final — Audit Stratégique & Organigramme
-- Économique
-- ● Scénario : La CTO, Claire Moreau (manager_id IS NULL), te demande un
-- rapport complet pour préparer la réorganisation annuelle de l'entreprise.
-- Elle veut visualiser l'ensemble de la chaîne hiérarchique depuis la direction
-- jusqu'au terrain, tout en comparant le salaire de chaque collaborateur à la
-- moyenne de son propre département.
-- ● Mission : Combine trois notions avancées dans une seule requête propre,
-- lisible et sécurisée :
-- 1. Récursivité (WITH RECURSIVE) : Pars de Claire Moreau (niveau = 1) et
-- descends toute la hiérarchie (employes) en construisant le fil d'Ariane
-- complet (chemin, ex. Claire Moreau > Marc Delacroix > Antoine
-- Renaud) et son niveau. Ajoute un garde-fou WHERE niveau < 10 contre
-- les boucles infinies.
-- 2. Fonction de fenêtrage (OVER) : Dans la requête finale, affiche pour
-- chaque employé son salaire, le salaire moyen de son departement
-- (AVG(salaire) OVER (PARTITION BY departement)), ainsi que l'écart en
-- euros entre son salaire et la moyenne de son équipe.
-- 3. Analyse de performance (EXPLAIN ANALYZE) : Exécute ton œuvre
-- avec EXPLAIN ANALYZE, repère l'étape la plus coûteuse (la récursivité
-- ou le Window aggregate / Sort) et vérifie qu'aucun SELECT * ni tri
-- superflu ne vient alourdir l'exécution.

EXPLAIN ANALYZE
WITH RECURSIVE Hierarchie AS (
    SELECT 
        id,
        nom,
        departement,
        salaire,
        1 AS niveau,
        CAST(nom AS CHAR(1000)) AS chemin
    FROM employes
    WHERE manager_id IS NULL
    UNION ALL
    SELECT 
        e.id,
        e.nom,
        e.departement,
        e.salaire,
        h.niveau + 1 AS niveau,
        CONCAT(h.chemin, ' > ', e.nom) AS chemin
    FROM employes e
    INNER JOIN Hierarchie h ON e.manager_id = h.id
    WHERE h.niveau < 10
)

SELECT 
    niveau,
    chemin,
    nom,
    departement,
    salaire,
    ROUND(AVG(salaire) OVER w, 2) AS moyenne_departement,
    ROUND(salaire - AVG(salaire) OVER w, 2) AS ecart_moyenne_euros
FROM Hierarchie
WINDOW w AS (PARTITION BY departement)
ORDER BY chemin ASC;

-- L'étape la plus coûteuse est le bloc Sort + Window aggregate (0,216 ms cumulés, soit environ 43 % du temps total), légèrement devant la récursivité (0,199 ms).