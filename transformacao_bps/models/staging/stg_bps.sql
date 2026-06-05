{{ config(materialized='view') }}

WITH unificado AS (
    SELECT * FROM {{ source('dados_brutos_bps', 'raw_bps_2023') }}
    UNION ALL
    SELECT * FROM {{ source('dados_brutos_bps', 'raw_bps_2024') }}
    UNION ALL
    SELECT * FROM {{ source('dados_brutos_bps', 'raw_bps_2025') }}
)

SELECT
    -- Produto
    codigo_br,
    TRIM(UPPER(descricao_catmat))            AS descricao_produto,
    TRIM(UPPER(generico))                    AS principio_ativo,
    TRIM(UPPER(unidade_fornecimento))        AS apresentacao,
    TRIM(UPPER(tipo_compra))                 AS tipo_produto,
    anvisa,

    -- Instituição
    TRIM(cnpj_instituicao)                   AS cnpj_instituicao,
    TRIM(UPPER(nome_instituicao))            AS nome_instituicao,
    TRIM(UPPER(uf))                          AS uf_instituicao,
    TRIM(UPPER(municipio_instituicao))       AS municipio_instituicao,
    TRIM(UPPER(esfera))                      AS esfera_administrativa,

    -- Fornecedor
    TRIM(cnpj_fornecedor)                    AS cnpj_fornecedor,
    TRIM(UPPER(fornecedor))                  AS nome_fornecedor,
    TRIM(cnpj_fabricante)                    AS cnpj_fabricante,
    TRIM(UPPER(fabricante))                  AS nome_fabricante,

    -- Compra
    TRIM(UPPER(modalidade_compra))           AS modalidade_compra,
    TRIM(UPPER(compra))                      AS tipo_documento,

    -- Tempo
    ano_compra,
    CAST(insercao AS DATE)                   AS data_insercao,

    -- Métricas
    qtd_itens_comprados                      AS quantidade,
    preco_unitario,
    preco_total

FROM unificado
WHERE
    preco_unitario IS NOT NULL
    AND qtd_itens_comprados IS NOT NULL
    AND ano_compra IS NOT NULL
