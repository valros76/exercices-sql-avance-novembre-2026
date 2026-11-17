WITH ca_clients AS ( 
  SELECT 
  client_id, 
  ROUND(SUM(montant_total), 2) AS ca_total 
  FROM commandes 
  WHERE statut = 'LIVREE' 
  GROUP BY client_id 
) 
SELECT 
c.nom, 
c.segment, 
cc.ca_total 
FROM ca_clients cc 
JOIN clients c ON c.id = cc.client_id 
WHERE cc.ca_total > 10000 
ORDER BY cc.ca_total DESC;