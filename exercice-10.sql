-- Exercice 10 : Éviter le double saut d'InnoDB (Covering Index)
-- ● Scénario : L'agence de Lyon affiche en permanence sur son écran mural la
-- liste de ses clients locaux : SELECT nom, ville, email FROM clients WHERE ville = 'Lyon';.
-- ● Mission : Observe le plan actuel avec EXPLAIN, puis crée un index composite idx_clients_ville_couvrant permettant de répondre à cette requête sans jamais toucher à la table principale (Extra: Using index).

-- /!\ Si on ne met pas ville en premier index, on a une utilisation combinée du WHERE et de l'index. Avec ville en premier index, on évite le double saut du index et on passe en Index Scan ONLY !

CREATE INDEX idx_exercice_10 ON clients(ville, nom, email);
EXPLAIN
SELECT 
nom, ville, email 
FROM clients 
WHERE ville = 'Lyon';