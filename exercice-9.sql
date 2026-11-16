-- Exercice 9 : La règle du préfixe gauche
-- ● Scénario : La table commandes dispose déjà de l'index composite
-- idx_clients_commandes_livrees (statut, client_id, montant_total).
-- ● Mission : Analyse avec EXPLAIN ces deux requêtes et explique pourquoi la
-- première est ultra-rapide alors que la seconde balaye tout l'index ou la table :
-- 1. SELECT client_id, montant_total FROM commandes WHERE statut =
-- 'LIVREE';
-- 2. SELECT statut, montant_total FROM commandes WHERE client_id = 2;
-- ● Indice & Objectif : Un index composite fonctionne comme un annuaire trié
-- par Nom, puis Prénom : impossible de chercher directement par prénom sans
-- connaître le nom.

-- L'index contient déjà le statut, et peut donc isoler les statut="LIVREE" pour utiliser un Scan Index, donc ne rentre même pas dans la table.
EXPLAIN
SELECT client_id, montant_total FROM commandes WHERE statut = 'LIVREE';

-- Ici, l'id du client ne suffit pas à récupérer une valeur dans l'index, car on manque d'informations pour piocher dedans, donc il relit la table client entière.
EXPLAIN
SELECT statut, montant_total FROM commandes WHERE client_id = 2;