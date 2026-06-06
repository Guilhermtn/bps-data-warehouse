-- Analise 1: Evolucao do preço medio dos produtos comprados por ano
-- Responde: como o preço medio e o gasto total evoluiram entre 2023 e 2025?

SELECT
    dt.ano,
    COUNT(fc.id_fato) AS total_compras,
    ROUND(AVG(fc.preco_unitario)::numeric, 2) AS preco_medio_unitario,
    ROUND(SUM(fc.preco_total)::numeric, 2) AS gasto_total,
    ROUND(SUM(fc.quantidade)::numeric, 0) AS total_itens_comprados
FROM fato_compras fc
JOIN dim_tempo dt ON fc.id_tempo = dt.ano
WHERE fc.preco_unitario > 0
GROUP BY dt.ano
ORDER BY dt.ano;
