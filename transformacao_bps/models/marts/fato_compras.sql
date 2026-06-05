{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER ()                AS id_fato,
    dp.id_produto,
    di.id_instituicao,
    df.id_fornecedor,
    dt.ano                              AS id_tempo,
    s.quantidade,
    s.preco_unitario,
    s.preco_total,
    s.modalidade_compra
FROM {{ ref('stg_bps') }} s
LEFT JOIN {{ ref('dim_produto') }}     dp
    ON s.codigo_br = dp.codigo_br
LEFT JOIN {{ ref('dim_instituicao') }} di
    ON s.cnpj_instituicao = di.cnpj_instituicao
LEFT JOIN {{ ref('dim_fornecedor') }}  df
    ON s.cnpj_fornecedor = df.cnpj_fornecedor
LEFT JOIN {{ ref('dim_tempo') }}       dt
    ON s.ano_compra = dt.ano
