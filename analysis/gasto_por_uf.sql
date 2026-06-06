-- Analise 3: Gasto total por UF com preço medio e total de compras
-- Responde: quais estados gastaram mais e existe diferença no preço medio pago entre regioes?

SELECT
    di.uf_instituicao,
    COUNT(fc.id_fato)                                        AS total_compras,
    ROUND(AVG(fc.preco_unitario)::numeric, 2)                AS preco_medio_unitario,
    ROUND(SUM(fc.preco_total)::numeric, 2)                   AS gasto_total,
    ROUND(
        (SUM(fc.preco_total) /
         SUM(SUM(fc.preco_total)) OVER () * 100)::numeric
    , 2)                                                     AS percentual_do_total
FROM fato_compras fc
JOIN dim_instituicao di ON fc.id_instituicao = di.id_instituicao
WHERE fc.preco_total > 0
GROUP BY di.uf_instituicao
ORDER BY gasto_total DESC;
