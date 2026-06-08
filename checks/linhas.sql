SELECT 'dim_produto' AS tabela,
       (SELECT COUNT(*) FROM bps_etl.dim_produto) AS qtd_etl,
       (SELECT COUNT(*) FROM bps_elt.dim_produto) AS qtd_elt
UNION ALL SELECT 'dim_instituicao',
       (SELECT COUNT(*) FROM bps_etl.dim_instituicao), (SELECT COUNT(*) FROM bps_elt.dim_instituicao)
UNION ALL SELECT 'dim_fornecedor',
       (SELECT COUNT(*) FROM bps_etl.dim_fornecedor), (SELECT COUNT(*) FROM bps_elt.dim_fornecedor)
UNION ALL SELECT 'dim_tempo',
       (SELECT COUNT(*) FROM bps_etl.dim_tempo), (SELECT COUNT(*) FROM bps_elt.dim_tempo)
UNION ALL SELECT 'fato_compras',
       (SELECT COUNT(*) FROM bps_etl.fato_compras), (SELECT COUNT(*) FROM bps_elt.fato_compras);