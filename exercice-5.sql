-- Exercice 5 : La machine à remonter le temps (Prédicats SARGables)
-- ● Scénario : Le service commercial veut retrouver les clients inscrits en 2024.
-- Un stagiaire a écrit :
-- SELECT nom, email FROM clients WHERE YEAR(date_inscription) = 2024;
-- ● Mission : Ajoute un index sur clients(date_inscription), explique pourquoi
-- YEAR(...) rend cet index aveugle, puis réécris la requête avec des bornes
-- d'intervalle (prédicat SARGable).
-- ● Indice & Objectif : Ne jamais enfermer une colonne indexée dans une
-- fonction dans la clause WHERE.

CREATE INDEX idx_exercice_5 ON clients(date_inscription);
SELECT 
nom, email 
FROM clients 
WHERE date_inscription >= '2024-01-01' AND date_inscription <= '2024-12-31';