{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER (ORDER BY cnpj_instituicao) AS id_instituicao,
    cnpj_instituicao,
    nome_instituicao,
    uf_instituicao,
    municipio_instituicao,
    esfera_administrativa
FROM (
    SELECT DISTINCT ON (cnpj_instituicao)
        cnpj_instituicao,
        nome_instituicao,
        uf_instituicao,
        municipio_instituicao,
        esfera_administrativa
    FROM {{ ref('stg_bps') }}
    WHERE cnpj_instituicao IS NOT NULL
    ORDER BY cnpj_instituicao
) AS instituicoes_unicas
