-- Chaves e atributos identicos = 0/0 esperado
SELECT
    (SELECT COUNT(*) FROM (
        SELECT cnpj_fornecedor, nome_fornecedor FROM bps_etl.dim_fornecedor
        EXCEPT
        SELECT cnpj_fornecedor, nome_fornecedor FROM bps_elt.dim_fornecedor
    ) a) AS so_no_etl,
    (SELECT COUNT(*) FROM (
        SELECT cnpj_fornecedor, nome_fornecedor FROM bps_elt.dim_fornecedor
        EXCEPT
        SELECT cnpj_fornecedor, nome_fornecedor FROM bps_etl.dim_fornecedor
    ) b) AS so_no_elt;