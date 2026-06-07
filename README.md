# 🏥 Data Warehouse: Banco de Preços em Saúde (BPS)

**Projeto de Integração — Banco de Dados (2026.1) - CIn/UFPE**

Este projeto implementa e compara duas arquiteturas fundamentais de Engenharia de Dados — **ETL Clássico** e **ELT Moderno** — para integrar, higienizar e modelar dados de compras de medicamentos e dispositivos médicos no Brasil.

O resultado final é uma **Modelagem Dimensional (Esquema Estrela)** que consolida as compras públicas de saúde dos anos de 2023, 2024 e 2025 em um Data Warehouse otimizado para análises e geração de insights.

---

## 🎯 Objetivo e Desafio

O objetivo foi integrar dados de compras públicas dispersos temporalmente para permitir análises históricas e comparativas sobre preços, fornecedores e instituições.

* **Fonte:** [Banco de Preços em Saúde (BPS) — Ministério da Saúde](https://dadosabertos.saude.gov.br/dataset/bps)
* **Dados Brutos:** Arquivos CSV separados por ano (2023, 2024 e 2025) contendo registros de compras públicas e privadas de medicamentos e dispositivos médicos.
* **Desafio Principal:** Os dados possuíam inconsistências de formato, variações de grafia em nomes de instituições e fornecedores, problemas de encoding e ausência de chaves primárias confiáveis para modelagem dimensional.

---

## 🏗️ Arquitetura da Solução

O projeto constrói o mesmo modelo final através de dois caminhos distintos para fins de comparação:

### 1. Abordagem ETL (Python Driven)

* **Extração:** Leitura dos CSVs brutos com tratamento de formatação.
* **Transformação (Pandas):**
    * Limpeza, padronização e tipagem dos dados.
    * Deduplicação e tratamento das dimensões.
    * **Modelagem Dimensional:** Criação das Tabelas Fato e Dimensão em memória.
* **Carga:** Inserção do Esquema Estrela no PostgreSQL via SQLAlchemy.

### 2. Abordagem ELT (Modern Data Stack)

* **Extração & Carga (EL):** Python carrega os dados brutos (`raw_bps_*`) diretamente no banco, sem transformação prévia.
* **Transformação (T):** O **dbt (data build tool)** orquestra as transformações diretamente no banco de dados:
    * **Staging:** Unificação dos três anos e padronização de colunas.
    * **Marts:** Materialização do Esquema Estrela (dimensões e fato).

---

## 📂 Estrutura do Projeto

```
bps-data-warehouse/
├── analysis/                           # Consultas SQL com as análises e insights
├── data/
│   └── raw/                            # CSVs brutos do BPS (ignorados no git)
├── notebooks/
│   ├── ETL.ipynb                       # Pipeline 1: ETL completo em Python/Pandas
│   └── ELT.ipynb                       # Pipeline 2: carga bruta para o dbt
├── transformacao_bps/                  # Projeto dbt (transformações do ELT)
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml             # Registro das tabelas raw_bps_*
│   │   │   └── stg_bps.sql             # View unificada e padronizada
│   │   └── marts/
│   │       ├── dim_produto.sql
│   │       ├── dim_instituicao.sql
│   │       ├── dim_fornecedor.sql
│   │       ├── dim_tempo.sql
│   │       └── fato_compras.sql
│   └── dbt_project.yml                 # Configuração do projeto dbt
├── .env.example                        # Modelo de variáveis de ambiente
├── .gitignore
├── requirements.txt                    # Dependências do Python
└── README.md
```
---

## 🚀 Como Executar

### 1. Pré-requisitos

* **Python 3.10+**
* **PostgreSQL** instalado e rodando localmente
* Os arquivos CSV do BPS (2023, 2024 e 2025) na pasta `data/raw/`

> Os CSVs não são versionados no Git por serem pesados. Baixe-os diretamente do [portal do BPS](https://dadosabertos.saude.gov.br/dataset/bps) e coloque em `data/raw/` com os nomes `2023.csv`, `2024.csv` e `2025.csv`.

### 2. Preparação do Ambiente Python

```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/bps-data-warehouse.git
cd bps-data-warehouse

# Crie e ative um ambiente virtual
python -m venv venv
source venv/bin/activate      # Linux/Mac
# venv\Scripts\activate       # Windows

# Instale as dependências
pip install -r requirements.txt
```

### 3. Configuração do Banco de Dados

1. Crie um banco de dados vazio chamado `bps_dw`:

```bash
createdb -U postgres bps_dw
```

2. Crie o arquivo `.env` na raiz do projeto a partir do modelo:

```bash
cp .env.example .env
```

3. Edite o `.env` e ajuste as credenciais conforme seu PostgreSQL local.

### 4. Execução dos Notebooks

Os pipelines estão documentados em notebooks na pasta `notebooks/`, executados localmente via **VS Code** ou **Jupyter**. Abra cada arquivo e execute as células sequencialmente, garantindo que o kernel está usando o ambiente virtual onde as dependências foram instaladas.

* **`ETL.ipynb`** — pipeline ETL completo. Lê os CSVs, transforma os dados em Python e carrega o Esquema Estrela final no PostgreSQL.
* **`ELT.ipynb`** — pipeline ELT. Carrega os dados brutos nas tabelas `raw_bps_*` para serem transformados pelo dbt.

### 5. Execução das Transformações (dbt)

Após rodar o `ELT.ipynb` (que carrega as tabelas brutas), execute o dbt para construir o Esquema Estrela via SQL:

```bash
# Configure o profiles.yml em ~/.dbt/ com as credenciais do PostgreSQL
cd transformacao_bps

# Teste a conexão
dbt debug

# Execute todos os models (staging + marts)
dbt run
```

Isso criará a view de staging (`stg_bps`) e as tabelas finais do Star Schema: `dim_produto`, `dim_instituicao`, `dim_fornecedor`, `dim_tempo` e `fato_compras`.

---

## 🔎 Análises Disponíveis

Após a execução dos pipelines, as consultas SQL disponíveis na pasta `analysis/`
podem ser rodadas diretamente em qualquer cliente de banco de dados (pgAdmin, DBeaver)
conectado ao `bps_dw`:

| Arquivo | Descrição |
|---|---|
| `evolucao_preco_por_ano.sql` | Evolução do preço médio e gasto total por ano (2023–2025) |
| `top_fornecedores_por_gasto.sql` | Top 10 fornecedores por volume de vendas com participação percentual |
| `gasto_por_uf.sql` | Gasto total por estado com preço médio e participação percentual |
| `evolucao_preco_por_produto.sql` | Produtos com maior gasto total e variação de preço entre 2023 e 2025 |
| `ranking_instituicoes_por_estado.sql` | Ranking de instituições por gasto dentro do próprio estado |

---

## 🛠️ Tecnologias

* **Linguagem:** Python 3.12
* **Banco de Dados:** PostgreSQL 16
* **Engenharia de Dados:** Pandas, SQLAlchemy, dbt-core 1.8.0
* **Ambiente de Execução:** Jupyter Notebook, VS Code