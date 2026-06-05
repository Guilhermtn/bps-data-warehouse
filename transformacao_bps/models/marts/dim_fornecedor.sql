{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER (ORDER BY cnpj_fornecedor) AS id_fornecedor,
    cnpj_fornecedor,
    nome_fornecedor
FROM (
    SELECT DISTINCT
        cnpj_fornecedor,
        nome_fornecedor
    FROM {{ ref('stg_bps') }}
    WHERE cnpj_fornecedor IS NOT NULL
) AS fornecedores_unicos
