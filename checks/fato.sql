WITH etl AS (
    SELECT id_tempo AS ano, COUNT(*) AS linhas, SUM(quantidade) AS qtd, SUM(preco_total) AS preco
    FROM bps_etl.fato_compras GROUP BY id_tempo
),
elt AS (
    SELECT id_tempo AS ano, COUNT(*) AS linhas, SUM(quantidade) AS qtd, SUM(preco_total) AS preco
    FROM bps_elt.fato_compras GROUP BY id_tempo
)
SELECT
    COALESCE(e.ano, l.ano)  AS ano,
    e.linhas                AS linhas_etl,
    l.linhas                AS linhas_elt,
    e.qtd                   AS qtd_etl,
    l.qtd                   AS qtd_elt,
    ROUND(e.preco::numeric, 2) AS preco_etl,
    ROUND(l.preco::numeric, 2) AS preco_elt,
    ROUND((e.preco - l.preco)::numeric, 2) AS dif_preco
FROM etl e FULL OUTER JOIN elt l ON e.ano = l.ano
ORDER BY 1;