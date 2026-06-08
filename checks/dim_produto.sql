-- Chaves identicas = 0/0 esperado
-- Atributos descritivos podem divergir por inconsistencia da fonte (mesmo codigo_br, atributos variáveis entre compras)
SELECT
    (SELECT COUNT(*) FROM (
        SELECT codigo_br FROM bps_etl.dim_produto
        EXCEPT
        SELECT codigo_br FROM bps_elt.dim_produto
    ) a) AS chaves_so_no_etl,
    (SELECT COUNT(*) FROM (
        SELECT codigo_br FROM bps_elt.dim_produto
        EXCEPT
        SELECT codigo_br FROM bps_etl.dim_produto
    ) b) AS chaves_so_no_elt;