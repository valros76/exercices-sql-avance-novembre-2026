-- Requête initiale :
-- ventes_fangame_brutes (
--     ticket_id,
--     vendeur_id,
--     vendeur_pseudo,
--     vendeur_pays,
--     serveur_id,
--     serveur_nom,
--     gerant_serveur_id,     -- Règle métier : 1 serveur n'a qu'1 seul gérant unique, et 1 gérant ne gère qu'1 seul serveur !
--     objets_achetes_liste,  -- Ex: "AWP | Dragon Lore (x1), Caisse Kilowatt (x3)"
--     total_ticket
-- )

-- Anomalie de mise à jour : Si le vendeur ZywOo_6 déménage et change de pays, il faudra modifier la colonne vendeur_pays sur toutes les lignes correspondant à chacune de ses ventes passées. Si une seule ligne est oubliée lors de la mise à jour, la base de données devient incohérente (le même vendeur_id apparaissant simultanément avec deux pays différents).

-- Anomalie de suppression : Si ZywOo_6 n'a réalisé qu'une seule vente et que l'on supprime ce ticket suite à une annulation, on efface par la même occasion toutes les informations propres à ce vendeur (vendeur_id, vendeur_pseudo, vendeur_pays), ainsi que potentiellement les informations sur le serveur (serveur_id, serveur_nom, gerant_serveur_id) si c'était la seule vente enregistrée sur ce serveur.

-----------------------------------------
--Décomposition progressive jusqu'en BCNF
-----------------------------------------

-- Passage en 1FN

-- tickets (ticket_id, vendeur_id, vendeur_pseudo, vendeur_pays, serveur_id, serveur_nom, gerant_serveur_id, total_ticket)
-- lignes_vente (ticket_id, objet_nom, quantite)


------------------------------------------

-- Passage en 2FN puis 3FN

-- vendeurs (vendeur_id, vendeur_pseudo, vendeur_pays)
-- serveurs (serveur_id, serveur_nom, gerant_serveur_id)
-- tickets (ticket_id, vendeur_id, serveur_id, total_ticket)
-- lignes_vente (ticket_id, objet_nom, quantite)

------------------------------------------

-- Passage en BCNF

-- serveurs (serveur_id, serveur_nom)
-- affectation_gerants (gerant_serveur_id, serveur_id UNIQUE)
-- vendeurs (vendeur_id, vendeur_pseudo, vendeur_pays)
-- tickets (ticket_id, vendeur_id, serveur_id, total_ticket)
-- lignes_vente (ticket_id, objet_nom, quantite)

-------------------------------------------

-- Pourquoi unit_price dans market_transactions ne viole pas la 3FN ?

-- Il n'y a aucune dépendance fonctionnelle entre item_id et unit_price, car unit_price enregistre le prix réel négocié à l'instant T de la transaction (qui fluctue selon l'offre, la demande ou le vendeur), alors que base_virtual_value représente uniquement la valeur catalogue théorique de l'objet. Par conséquent, unit_price dépend exclusivement de la clé primaire transaction_id et non de item_id.