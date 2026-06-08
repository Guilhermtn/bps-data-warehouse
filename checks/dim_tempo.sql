SELECT
    (SELECT COUNT(*) FROM (
        SELECT ano, descricao_periodo FROM bps_etl.dim_tempo
        EXCEPT
        SELECT ano, descricao_periodo FROM bps_elt.dim_tempo
    ) a) AS so_no_etl,
    (SELECT COUNT(*) FROM (
        SELECT ano, descricao_periodo FROM bps_elt.dim_tempo
        EXCEPT
        SELECT ano, descricao_periodo FROM bps_etl.dim_tempo
    ) b) AS so_no_elt;