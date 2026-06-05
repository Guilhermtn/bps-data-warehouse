{{ config(materialized='table') }}

SELECT DISTINCT
    ano_compra                          AS ano,
    CASE
        WHEN ano_compra = 2023 THEN 'Compras 2023'
        WHEN ano_compra = 2024 THEN 'Compras 2024'
        WHEN ano_compra = 2025 THEN 'Compras 2025'
    END                                 AS descricao_periodo
FROM {{ ref('stg_bps') }}
WHERE ano_compra IS NOT NULL
