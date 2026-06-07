-- Analise: Instituicoes com maior gasto e ranking dentro do proprio estado
-- Responde: quais instituicoes mais gastaram e qual e sua posicao de gastos dentro do seu estado?

SELECT
    di.nome_instituicao,
    di.uf_instituicao,
    di.esfera_administrativa,
    ROUND(SUM(fc.preco_total)::numeric, 2)                        AS gasto_total,
    COUNT(fc.id_fato)                                             AS total_compras,
    RANK() OVER (
        PARTITION BY di.uf_instituicao
        ORDER BY SUM(fc.preco_total) DESC
    )                                                             AS ranking_no_estado
FROM fato_compras fc
JOIN dim_instituicao di ON fc.id_instituicao = di.id_instituicao
WHERE fc.preco_total > 0
GROUP BY di.nome_instituicao, di.uf_instituicao, di.esfera_administrativa
ORDER BY gasto_total DESC
LIMIT 15;
