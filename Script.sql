SELECT 
    carrier,
    round(AVG(EXTRACT(EPOCH FROM (NULLIF(delivered_at, '')::TIMESTAMP - NULLIF(shipped_at, '')::TIMESTAMP)) / 86400),1) AS delai_moyen_jours
FROM shipments
WHERE delivered_at IS NOT NULL 
  AND delivered_at <> '' 
  AND shipped_at IS NOT NULL 
  AND shipped_at <> ''
GROUP BY carrier;

--16.Délai Moyen de Livraison (Logistique) par pays et canal

SELECT    c.country, o.channel,

round(avg(s.delivered_at::date - s.shipped_at::date),1) as delai_moyen_livraison
FROM shipments s join orders o on s.order_id = o.order_id
join customers c on c.customer_id = o.customer_id
WHERE delivered_at IS NOT NULL 
  AND delivered_at <> '' 
  AND shipped_at IS NOT NULL 
  AND shipped_at <> ''
and o.order_id is not null
GROUP BY c.country, o.channel
order by delai_moyen_livraison desc;

--résultat : 48 lignes
--extrait : 

--17.Répartition du chiffre d'affaires par pays des clients (country)

select c.country, round(sum(o.total_amount::numeric),2) as CA_par_pays
from orders o 
join customers c on o.customer_id = c.customer_id
where o.status != 'cancelled' and o.status != 'returned'
group by c.country
order by CA_par_pays desc;

--résultat : 12 lignes

--18.Impact global des remises (discount_amount) par mois

SELECT 
    SUBSTRING(order_date::text, 1, 7) AS mois,
    ROUND(SUM(subtotal)::numeric, 2) AS sous_total_brut,
    ROUND(SUM(discount_amount)::numeric, 2) AS total_remises,
    ROUND(SUM(subtotal - discount_amount)::numeric, 2) AS sous_total_apres_remise,
    ROUND(SUM(total_amount)::numeric, 2) AS chiffre_affaires_net,
    ROUND(
        (SUM(discount_amount)::numeric / NULLIF(SUM(subtotal), 0)::numeric) * 100, 
        2
    ) AS taux_remise_moyen_pourcentage
FROM "orders"
WHERE status NOT IN ('cancelled', 'returned')
GROUP BY SUBSTRING(order_date::text, 1, 7)
ORDER BY mois ASC;

--résulat : 33 lignes

--19.Analyse du chiffre d'affaires et de la marge brute par marque (brand)

SELECT 
    p.brand, 
    ROUND(SUM(oi.line_total)::numeric, 2) AS CA_par_marque,
    ROUND(SUM(oi.line_total - (oi.quantity * p.unit_cost))::numeric, 2) AS marge_brute,
    ROUND(
        (SUM(oi.line_total - (oi.quantity * p.unit_cost))::numeric / NULLIF(SUM(oi.line_total), 0)::numeric) * 100, 
        2
    ) AS taux_de_marge_pourcentage
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled', 'returned')
GROUP BY p.brand
ORDER BY CA DESC;

--résultat : 12 lignes


--20.Panier moyen et nombre de lignes/articles moyennes par commande

SELECT 
    ROUND(AVG(nombre_references)::numeric, 2) AS moyenne_references_par_commande,
    ROUND(AVG(quantite_totale)::numeric, 2) AS moyenne_articles_par_commande
FROM (
    SELECT 
        oi.order_id,
        COUNT(DISTINCT oi.product_id) AS nombre_references,
        SUM(oi.quantity) AS quantite_totale
    FROM "order_items" oi
    JOIN "orders" o ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled', 'returned')
    GROUP BY oi.order_id
) sub;

--résultat : 1 ligne

2.21	3.69
