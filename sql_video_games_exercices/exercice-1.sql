-- Requête du stagiaire :
-- EXPLAIN ANALYZE
-- SELECT *
-- FROM market_transactions
-- WHERE EXTRACT(YEAR FROM transacted_at) = 2026
--   AND LOWER(currency_type) = 'kamas'
--   AND item_id::TEXT LIKE '%19';

-- Non fonctionnelle, car ne correspond pas aux tables réelles et comporte des erreurs de syntaxe.

-- Pour récupérer les données réelles de la base, il faut la corriger en : 
-- EXPLAIN ANALYZE
-- SELECT *
-- FROM market_listings
-- WHERE EXTRACT(YEAR FROM sold_at) = 2026
--   AND LOWER(currency_code) = 'kamas'
--   AND item_id LIKE '%19';
-- -> Filter: ((extract(year from market_listings.sold_at) = 2026) and (lower(market_listings.currency_code) = 'kamas') and (market_listings.item_id like '%19'))  (cost=828 rows=893) (actual time=7.11..7.11 rows=0 loops=1)
--     -> Table scan on market_listings  (cost=828 rows=8038) (actual time=0.569..6.32 rows=8000 loops=1)
-- Donc use WHERE, type=ALL, sans index.
-- Comporte l'utilisation de EXTRACT() et LOWER(), paramètre de filtre, donc empêcherait l'utilisation d'index dans tous les cas, car mutation de la valeur initiale.

-- Index optimisé en postgreSQL
-- CREATE INDEX idx_ventes_item13_2026 
-- ON market_listings (sold_at) 
-- INCLUDE (id, quantity, unit_price)
-- WHERE item_id = 13 
--   AND status = 'SOLD' 
--   AND currency_code = 'KAMAS'
--   AND sold_at >= '2026-01-01' 
--   AND sold_at <= '2026-12-31';

CREATE INDEX idx_market_listings_sales 
ON market_listings (item_id, status, currency_code, sold_at, quantity, unit_price);
EXPLAIN ANALYZE
SELECT id, quantity, unit_price, sold_at
FROM market_listings
WHERE item_id = 13
  AND status = 'SOLD'
  AND currency_code = 'KAMAS'
  AND sold_at >= '2026-01-01' 
  AND sold_at <= '2026-12-31';
  -- -> Filter: ((market_listings.item_id = 13) and (market_listings.`status` = 'SOLD') and (market_listings.currency_code = 'KAMAS') and (market_listings.sold_at >= TIMESTAMP'2026-01-01 00:00:00') and (market_listings.sold_at <= TIMESTAMP'2026-12-31 00:00:00'))  (cost=1.17 rows=1) (actual time=0.0306..0.0306 rows=0 loops=1)
  --   -> Covering index range scan on market_listings using idx_market_listings_sales over (item_id = 13 AND status = 'SOLD' AND currency_code = 'KAMAS' AND '2026-01-01 00:00:00' <= sold_at <= '2026-12-31 00:00:00')  (cost=1.17 rows=1) (actual time=0.0299..0.0299 rows=0 loops=1)

-- Pour 2026, aucunes données, si on essaie sur 2024, avec des données :
-- -> Filter: ((market_listings.item_id = 13) and (market_listings.`status` = 'SOLD') and (market_listings.currency_code = 'KAMAS') and (market_listings.sold_at >= TIMESTAMP'2024-01-01 00:00:00') and (market_listings.sold_at <= TIMESTAMP'2024-12-31 00:00:00'))  (cost=147 rows=667) (actual time=0.0703..1.01 rows=667 loops=1)
--     -> Covering index range scan on market_listings using idx_market_listings_sales over (item_id = 13 AND status = 'SOLD' AND currency_code = 'KAMAS' AND '2024-01-01 00:00:00' <= sold_at <= '2024-12-31 00:00:00')  (cost=147 rows=667) (actual time=0.0674..0.696 rows=667 loops=1)

-- Exemple d'utilisation du SUM() OVER () pour calculer le montant global de chaque transaction
-- SELECT id, quantity, unit_price, sold_at, SUM(quantity * unit_price) OVER (ORDER BY id) AS chiffre_affaires_cumule
-- FROM market_listings
-- WHERE item_id = 13
--   AND status = 'SOLD'
--   AND currency_code = 'KAMAS'
--   AND sold_at >= '2024-01-01' 
--   AND sold_at <= '2024-12-31';
-- -> Window aggregate with buffering: sum(`(market_listings.quantity * market_listings.unit_price)`) OVER (ORDER BY market_listings.id )   (cost=0 rows=667) (actual time=2.91..4.74 rows=667 loops=1)
--     -> Sort: market_listings.id  (cost=147 rows=667) (actual time=1.71..1.85 rows=667 loops=1)
--         -> Filter: ((market_listings.item_id = 13) and (market_listings.`status` = 'SOLD') and (market_listings.currency_code = 'KAMAS') and (market_listings.sold_at >= TIMESTAMP'2024-01-01 00:00:00') and (market_listings.sold_at <= TIMESTAMP'2024-12-31 00:00:00'))  (cost=147 rows=667) (actual time=0.101..1.42 rows=667 loops=1)
--             -> Covering index range scan on market_listings using idx_market_listings_sales over (item_id = 13 AND status = 'SOLD' AND currency_code = 'KAMAS' AND '2024-01-01 00:00:00' <= sold_at <= '2024-12-31 00:00:00')  (cost=147 rows=667) (actual time=0.0969..0.983 rows=667 loops=1)