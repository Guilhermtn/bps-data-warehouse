{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER (ORDER BY codigo_br) AS id_produto,
    codigo_br,
    descricao_produto,
    principio_ativo,
    apresentacao
FROM (
    SELECT DISTINCT ON (codigo_br)
        codigo_br,
        descricao_produto,
        principio_ativo,
        apresentacao
    FROM {{ ref('stg_bps') }}
    WHERE codigo_br IS NOT NULL
    ORDER BY codigo_br
) AS produtos_unicos
