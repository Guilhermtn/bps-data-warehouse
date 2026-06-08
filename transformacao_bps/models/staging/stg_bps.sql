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
    TRIM(convert_from(convert_to(descricao_catmat, 'LATIN1'), 'UTF8'))                                              AS descricao_produto,
    COALESCE(TRIM(generico), 'Não informado')                                                                       AS principio_ativo,
    COALESCE(TRIM(convert_from(convert_to(unidade_fornecimento, 'LATIN1'), 'UTF8')), 'Não informado')               AS apresentacao,
    TRIM(tipo_compra)                                                                                               AS tipo_produto,
    COALESCE(anvisa, 0)                                                                                             AS anvisa,
    COALESCE(TRIM(convert_from(convert_to(unidade_fornecimento_capacidade, 'LATIN1'), 'UTF8')), 'Não informado')    AS unidade_fornecimento_capacidade,
    COALESCE(TRIM(unidade_medida), 'Não informado')                                                                 AS unidade_medida,
    COALESCE(capacidade, 0.0)                                                                                       AS capacidade,

    -- Instituição
    REGEXP_REPLACE(cnpj_instituicao, '[^0-9]', '', 'g')         AS cnpj_instituicao,
    COALESCE(TRIM(nome_instituicao), 'Não informado')           AS nome_instituicao,
    TRIM(uf)                                                    AS uf_instituicao,
    TRIM(municipio_instituicao)                                 AS municipio_instituicao,
    TRIM(esfera)                                                AS esfera_administrativa,

    -- Fornecedor
    REGEXP_REPLACE(cnpj_fornecedor, '[^0-9]', '', 'g')          AS cnpj_fornecedor,
    TRIM(fornecedor)                                            AS nome_fornecedor,
    REGEXP_REPLACE(cnpj_fabricante, '[^0-9]', '', 'g')          AS cnpj_fabricante,
    TRIM(fabricante)                                            AS nome_fabricante,

    -- Compra
    TRIM(convert_from(convert_to(modalidade_compra, 'LATIN1'), 'UTF8'))  AS modalidade_compra,
    TRIM(compra)                                                AS tipo_documento,

    -- Tempo
    ano_compra,
    CAST(insercao AS DATE)                                      AS data_insercao,

    -- Métricas
    qtd_itens_comprados                                         AS quantidade,
    preco_unitario,
    preco_total

FROM unificado