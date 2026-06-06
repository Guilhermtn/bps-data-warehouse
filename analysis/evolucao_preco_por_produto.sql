-- Analise: Produtos com maior gasto total e variacao de preco entre anos
-- Responde: quais produtos concentram mais gastos e como seu preco variou ao longo dos 3 anos?

SELECT
    dp.descricao_produto,
    ROUND(SUM(fc.preco_total)::numeric, 2)                        AS gasto_total,
    ROUND(AVG(CASE WHEN dt.ano = 2023 THEN fc.preco_unitario END)::numeric, 2) AS preco_medio_2023,
    ROUND(AVG(CASE WHEN dt.ano = 2024 THEN fc.preco_unitario END)::numeric, 2) AS preco_medio_2024,
    ROUND(AVG(CASE WHEN dt.ano = 2025 THEN fc.preco_unitario END)::numeric, 2) AS preco_medio_2025,
    ROUND(
        ((AVG(CASE WHEN dt.ano = 2025 THEN fc.preco_unitario END) -
          AVG(CASE WHEN dt.ano = 2023 THEN fc.preco_unitario END)) /
          NULLIF(AVG(CASE WHEN dt.ano = 2023 THEN fc.preco_unitario END), 0) * 100)::numeric
    , 2)                                                          AS variacao_percentual_2023_2025
FROM fato_compras fc
JOIN dim_produto dp ON fc.id_produto = dp.id_produto
JOIN dim_tempo   dt ON fc.id_tempo   = dt.ano
WHERE fc.preco_unitario > 1
GROUP BY dp.descricao_produto
HAVING
    AVG(CASE WHEN dt.ano = 2023 THEN fc.preco_unitario END) IS NOT NULL
    AND AVG(CASE WHEN dt.ano = 2025 THEN fc.preco_unitario END) IS NOT NULL
ORDER BY gasto_total DESC
LIMIT 10;
