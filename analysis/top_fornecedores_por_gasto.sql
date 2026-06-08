-- Analise 2: Top 10 fornecedores por gasto total com participacao percentual
-- Responde: quais fornecedores concentram mais os gastos e qual e o peso de cada um no total?

SELECT
    df.nome_fornecedor,
    COUNT(fc.id_fato)                                        AS total_compras,
    ROUND(SUM(fc.preco_total)::numeric, 2)                   AS gasto_total,
    ROUND(
        (SUM(fc.preco_total) /
         SUM(SUM(fc.preco_total)) OVER () * 100)::numeric
    , 2)                                                     AS percentual_do_total
FROM bps_elt.fato_compras fc
JOIN bps_elt.dim_fornecedor df ON fc.id_fornecedor = df.id_fornecedor
WHERE fc.preco_total > 0
GROUP BY df.nome_fornecedor
ORDER BY gasto_total DESC
LIMIT 5;