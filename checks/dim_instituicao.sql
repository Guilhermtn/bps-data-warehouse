-- Chaves identicas = 0/0 esperado
-- Atributos descritivos podem divergir por inconsistencia da fonte (mesmo cnpj, atributos variáveis entre compras)
SELECT
    (SELECT COUNT(*) FROM (
        SELECT cnpj_instituicao FROM bps_etl.dim_instituicao
        EXCEPT
        SELECT cnpj_instituicao FROM bps_elt.dim_instituicao
    ) a) AS chaves_so_no_etl,
    (SELECT COUNT(*) FROM (
        SELECT cnpj_instituicao FROM bps_elt.dim_instituicao
        EXCEPT
        SELECT cnpj_instituicao FROM bps_etl.dim_instituicao
    ) b) AS chaves_so_no_elt;