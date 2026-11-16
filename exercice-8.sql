-- Exercice 8 : Le mystère des employés fantômes (NOT IN vs NULL)
-- ● Scénario : Les RH veulent la liste des employés qui n'encadrent personne
-- (ceux qui ne sont pas managers). Un collègue lance :
-- SELECT id, nom FROM employes WHERE id NOT IN (SELECT manager_id FROM employes);
-- Problème : la requête renvoie 0 ligne, alors que plusieurs techniciens n'ont
-- aucune équipe !
-- ● Mission : Explique pourquoi la présence de Claire Moreau (manager_id IS
-- NULL) fait échouer le NOT IN (logique ternaire SQL), et corrige la requête
-- avec NOT EXISTS.

-- SELECT id, nom FROM employes WHERE id NOT IN (SELECT manager_id FROM employes);
-- NOT IN exécute une boucle, s'il tombe sur NULL, il invalide la boucle, car il renvoie UNKNOWN en valeur sortante.

SELECT e.id, e.nom
FROM employes e
WHERE NOT EXISTS (
    SELECT 1 
    FROM employes sub 
    WHERE sub.manager_id = e.id
);