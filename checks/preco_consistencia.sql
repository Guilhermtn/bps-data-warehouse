SELECT
    COUNT(*) AS total_linhas,
    SUM(CASE WHEN ABS(preco_total - (preco_unitario * quantidade)) < 0.01 THEN 1 ELSE 0 END) AS bate_centavo,
    SUM(CASE WHEN ABS(preco_total - (preco_unitario * quantidade)) >= 0.01 THEN 1 ELSE 0 END) AS divergente,
    MAX(ABS(preco_total - (preco_unitario * quantidade))) AS maior_diferenca
FROM bps_elt.fato_compras;