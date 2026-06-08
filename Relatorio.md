# Universidade Federal de Pernambuco
## Centro de Informática — CIn
 
**Banco de Preços em Saúde (BPS)**
 
### Relatório do Projeto de Integração
**Banco de Dados — 2026.1**
 
---
 
Lucas Matheus Soares Feliciano — lmsf

Lucas Santiago Monterazo — lsm6

José Guilherme Teixeira Nunes — jgtn

## 1. Descrição da Base de Dados Unificada

A base de dados resultante deste projeto é um **Data Warehouse analítico**, modelado em **Esquema Estrela (Star Schema)**, consolidado a partir dos dados do **Banco de Preços em Saúde (BPS)**, mantido pelo Ministério da Saúde (BPS/MS). A fonte reúne registros de compras públicas e privadas de medicamentos e dispositivos médicos realizadas por instituições de saúde de todo o Brasil, com atualização semestral e cobertura geográfica nacional.

O Data Warehouse integra os exercícios de **2023, 2024 e 2025** em uma estrutura única e padronizada, totalizando **84.465 registros** na tabela fato. O modelo é composto por uma tabela central de fatos (`fato_compras`), que armazena as métricas quantitativas da aquisição, circundada por quatro tabelas de dimensão que fornecem o contexto descritivo — o *quê* (produto), o *quem comprou* (instituição), o *de quem comprou* (fornecedor) e o *quando* (tempo).

### 1.1. Estrutura do Modelo Dimensional

* **Fato:** `fato_compras` — Granularidade: um item adquirido por transação de compra registrada no BPS.
* **Dimensões:**
  * `dim_produto`: características do medicamento/insumo (código CATMAT, descrição, apresentação).
  * `dim_instituicao`: entidade compradora, sua localização geográfica e esfera administrativa.
  * `dim_fornecedor`: empresa responsável pela venda e entrega do item.
  * `dim_tempo`: período de referência derivado do ano da compra.

### 1.2. Dicionário de Dados

#### Tabela Fato: `fato_compras`
Cada linha representa um item adquirido em uma transação de compra registrada no BPS. Armazena a chave primária própria, as chaves estrangeiras para as quatro dimensões e as métricas quantitativas da aquisição.

| Coluna | Tipo | Descrição | Origem/Transformação |
| :--- | :--- | :--- | :--- |
| **`id_fato`** | PK (Inteiro) | Chave primária substituta da tabela fato. | Gerado no pipeline ETL/ELT |
| **`id_produto`** | FK (Inteiro) | Chave estrangeira para `dim_produto`. | `dim_produto` |
| **`id_instituicao`** | FK (Inteiro) | Chave estrangeira para `dim_instituicao`. | `dim_instituicao` |
| **`id_fornecedor`** | FK (Inteiro) | Chave estrangeira para `dim_fornecedor`. | `dim_fornecedor` |
| **`id_tempo`** | FK (Inteiro) | Chave estrangeira para `dim_tempo`. | `dim_tempo` |
| `quantidade` | Inteiro | Quantidade do item adquirida na transação. | Bruto: `Qtd Itens Comprados` |
| `preco_unitario` | Decimal | Preço pago por unidade do item. | Bruto: `Preço Unitário` |
| `preco_total` | Decimal | Valor total da aquisição (`preco_unitario` × `quantidade`). | Bruto: `Preço Total` |
| `modalidade_compra` | Texto | Modalidade de aquisição (licitação, pregão, compra direta etc.). | Bruto: `Modalidade da Compra` |

#### Dimensão: `dim_produto`
Normaliza os medicamentos e insumos com base no Catálogo de Materiais (CATMAT).

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| **`id_produto`** | PK (Inteiro) | Chave substituta única para o produto. |
| `codigo_br` | Inteiro | Código BR / CATMAT — identificador padronizado do item no mercado de saúde brasileiro. |
| `descricao_produto` | Texto | Descrição oficial do medicamento ou insumo. |
| `principio_ativo` | Texto | Indicador de medicamento genérico (`S` / `N`), derivado do campo `generico` da fonte. |
| `apresentacao` | Texto | Forma de apresentação do produto (comprimido, ampola, frasco etc.). |

#### Dimensão: `dim_instituicao`
Identifica a entidade compradora, sua localização geográfica e classificação administrativa.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| **`id_instituicao`** | PK (Inteiro) | Chave substituta única para a instituição. |
| `cnpj_instituicao` | Texto | CNPJ da instituição compradora. |
| `nome_instituicao` | Texto | Nome da entidade compradora (hospitais, secretarias de saúde e outras entidades do SUS). |
| `uf_instituicao` | Texto | Unidade Federativa da instituição. Permite análises por estado. |
| `municipio_instituicao` | Texto | Município da instituição. Permite análises geográficas granulares. |
| `esfera_administrativa` | Texto | Esfera administrativa da instituição (estadual ou municipal). |

#### Dimensão: `dim_fornecedor`
Identifica a empresa que vendeu e entregou o item à instituição compradora.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| **`id_fornecedor`** | PK (Inteiro) | Chave substituta única para o fornecedor. |
| `cnpj_fornecedor` | Texto | CNPJ do fornecedor. |
| `nome_fornecedor` | Texto | Nome da empresa fornecedora. |

#### Dimensão: `dim_tempo`
Tabela auxiliar para navegação temporal das compras, organizada por ano de referência.

| Coluna | Tipo | Descrição |
| :--- | :--- | :--- |
| **`ano`** | PK (Inteiro) | Ano da compra — funciona diretamente como chave primária (2023, 2024, 2025). |
| `descricao_periodo` | Texto | Descrição textual do período (ex.: "Compras 2023"). |

## 2. Explicação Detalhada do Processo de Integração

O processo de integração foi conduzido por **dois pipelines paralelos** — um seguindo a abordagem **ETL** e outro a abordagem **ELT** —, ambos partindo dos mesmos arquivos CSV e convergindo para o mesmo Esquema Estrela no banco `bps_dw`. Esta seção descreve as **etapas do fluxo** de cada pipeline, da coleta à consolidação final. As técnicas de transformação aplicadas para garantir qualidade e consistência são detalhadas na Seção 4, e a análise comparativa entre as duas abordagens, na Seção 5.

### 2.1. Coleta dos Dados (Extração da Fonte)

Os dados foram obtidos diretamente do portal de dados abertos do **Banco de Preços em Saúde (BPS/MS)**, em três arquivos CSV correspondentes aos exercícios de 2023, 2024 e 2025, depositados na pasta `data/raw/` (não versionada no Git, por serem pesados) com os nomes `2023.csv`, `2024.csv` e `2025.csv`.

| Arquivo | Linhas | Colunas originais |
| :--- | :--- | :--- |
| `2023.csv` | 31.992 | 25 |
| `2024.csv` | 26.258 | 25 |
| `2025.csv` | 26.215 | 25 |
| **Total** | **84.465** | — |

Os arquivos seguem o padrão das bases do governo brasileiro: separador `;` (ponto e vírgula) e codificação `latin-1`. Esses parâmetros foram definidos explicitamente na leitura (`sep=';'`, `encoding='latin-1'`) em ambos os pipelines.

### 2.2. Fluxo do Pipeline ETL

Implementado no notebook `notebooks/ETL.ipynb`, este pipeline realiza toda a transformação **em memória** antes de gravar no banco. O fluxo segue quatro etapas:

1. **Extract** — os três CSVs são lidos individualmente, recebem uma coluna auxiliar `ano_origem` (rastreabilidade) e são concatenados em um único DataFrame unificado de 84.465 linhas.
2. **Transform** — o DataFrame unificado passa por limpeza e padronização com Pandas (as técnicas aplicadas estão detalhadas na Seção 4).
3. **Modelagem dimensional** — o DataFrame limpo é separado em quatro dimensões e uma tabela fato; cada dimensão recebe uma chave substituta sequencial, e a fato é remontada recuperando essas chaves.
4. **Load** — as tabelas são gravadas no PostgreSQL via `to_sql()`, respeitando a dependência referencial (dimensões antes da fato).

### 2.3. Fluxo do Pipeline ELT

Implementado no notebook `notebooks/ELT.ipynb` (etapa EL) e no projeto dbt `transformacao_bps/` (etapa T), este pipeline inverte a ordem: carrega o dado bruto primeiro e transforma dentro do banco.

1. **Extract + Load** — cada CSV é lido e despejado **sem qualquer transformação** em uma tabela bruta correspondente — `raw_bps_2023`, `raw_bps_2024` e `raw_bps_2025` —, preservando o dado original tal como veio da fonte.
2. **Transform (orquestrada pelo dbt)** — a transformação ocorre em duas camadas:
   * **Staging:** o model `stg_bps` (materializado como *view*) unifica as três tabelas brutas com `UNION ALL` e padroniza as colunas;
   * **Marts:** as quatro dimensões e a fato (materializadas como *tables*) são construídas a partir da view de staging, formando o Esquema Estrela.

   As transformações SQL específicas dessas camadas estão detalhadas na Seção 4.

### 2.4. Consolidação Final

Ambos os pipelines convergem para o mesmo modelo lógico (uma tabela fato e quatro dimensões) no banco `bps_dw`. A tabela `fato_compras` totaliza **84.465 registros** nas duas abordagens, confirmando que nenhum registro de compra foi perdido na integração. As diferenças de grão entre as dimensões geradas por cada pipeline são discutidas na Seção 5.

## 3. Justificativa da Escolha da Base de Dados

A escolha do **Banco de Preços em Saúde (BPS)** como base do projeto foi motivada por critérios técnicos e de relevância que a tornam particularmente adequada ao aprendizado das técnicas de Engenharia de Dados propostas pela disciplina:

**1. Desafio real de integração e qualidade de dados.** Diferente de datasets já tratados, as bases brutas do BPS apresentavam problemas característicos de dados públicos governamentais, que exigiram tratamento robusto: codificação corrompida nos caracteres acentuados (conflito `latin-1` / `utf-8`), preços em formato brasileiro (vírgula decimal), datas no padrão `dd/mm/aaaa`, CNPJs com pontuação, categorias duplicadas por grafia (ex.: `DOSE` e `DOSES`) e nulos concentrados em campos específicos. Essas inconsistências tornaram a base ideal para demonstrar, na prática, as etapas de limpeza e padronização tanto em Python quanto em SQL.

**2. Ausência de chaves confiáveis e oportunidade de modelagem.** Os registros do BPS são transacionais e não trazem chaves primárias próprias para as entidades (produto, instituição, fornecedor). Isso exigiu a criação de chaves substitutas e a deduplicação por chaves de negócio (CNPJ, código CATMAT), exercitando diretamente os conceitos centrais da modelagem dimensional.

**3. Adequação natural ao Esquema Estrela.** A estrutura dos dados favorece a modelagem dimensional: há entidades descritivas bem definidas — o produto comprado, a instituição compradora e o fornecedor — em torno de um evento transacional mensurável (a compra, com quantidade e preço). Essa separação entre contexto e métrica permitiu construir um Data Warehouse completo, com uma tabela fato cercada por dimensões, e ainda comparar as abordagens ETL e ELT sobre o mesmo modelo.

**4. Volume e temporalidade compatíveis com análises comparativas.** Com **84.465 registros** distribuídos em três anos consecutivos (2023, 2024 e 2025), o volume é suficiente para sustentar análises históricas, comparativas e geográficas — como a evolução de preços e o gasto por estado — sem inviabilizar o processamento em ambiente acadêmico local.

**5. Transparência e interesse público.** Por se tratar de dados abertos e reais de compras públicas de saúde, o projeto ganha relevância ao permitir análises com valor social concreto: comparação de preços entre fornecedores e regiões, identificação de concentração de gastos e apoio à transparência das aquisições no setor da saúde — simulando um cenário real de *Business Intelligence* governamental.

## 4. Descrição dos Processos de Transformação Aplicados

Para garantir a qualidade e a consistência dos dados, foram aplicadas diversas transformações sobre a base bruta do BPS. Como os dois pipelines atuam em momentos distintos — o **ETL** transforma em memória (Pandas) antes da carga, e o **ELT** transforma dentro do banco (SQL/dbt) após a carga bruta — esta seção descreve as transformações de cada abordagem separadamente.

### 4.1. Transformações no Pipeline ETL (Python / Pandas)

Aplicadas sobre o DataFrame unificado de 84.465 linhas, no notebook `notebooks/ETL.ipynb`.

**Correção de encoding.** Quatro colunas (`descricao_catmat`, `unidade_fornecimento`, `modalidade_compra` e `unidade_fornecimento_capacidade`) apresentavam acentuação corrompida pelo conflito de codificação (ex.: `"PregÃ£o"` em vez de `"Pregão"`, `"CÃPSULA"` em vez de `"CÁPSULA"`). Foram corrigidas reaplicando a codificação correta via `.encode('latin-1').decode('utf-8')`.

**Conversão de tipos.**
* **Datas** (`compra` e `insercao`): convertidas de texto no formato brasileiro `dd/mm/aaaa` para `datetime`, com `errors='coerce'` para tratar valores inválidos.
* **Preços** (`preco_unitario` e `preco_total`): convertidos de texto com vírgula decimal para `float`, removendo o separador de milhar e substituindo a vírgula por ponto.
* **Quantidade** (`qtd_itens_comprados`): convertida para tipo numérico.

**Limpeza de CNPJ.** Toda a pontuação foi removida de `cnpj_instituicao`, `cnpj_fornecedor` e `cnpj_fabricante`, mantendo apenas os dígitos — padronizando a chave de negócio para a deduplicação.

**Padronização de categorias.** A categoria `'DOSE'` foi unificada em `'DOSES'` na coluna `unidade_medida`, eliminando duplicidade semântica.

**Tratamento de nulos.**
* Campos textuais (`nome_instituicao`, `unidade_fornecimento`, `generico`, `unidade_medida`, `unidade_fornecimento_capacidade`): preenchidos com `'Não informado'`.
* Campos numéricos (`anvisa`, `capacidade`): preenchidos com `0`.
* Os **2.008 nulos** da coluna `insercao` foram **mantidos como `NULL`** intencionalmente, por representarem ausência real da informação na fonte — imputar uma data fictícia distorceria o dado, e os demais campos da compra permanecem válidos.

**Remoção de colunas redundantes.** As colunas `ano_compra` (redundante, pois o ano já está contido na data `compra`) e `ano_origem` (auxiliar de rastreabilidade usada na concatenação) foram descartadas, restando 24 colunas.

**Deduplicação e chaves substitutas.** Cada dimensão foi criada por `drop_duplicates()` sobre o conjunto de colunas que a compõe, recebendo uma chave substituta sequencial (`id_*_sk`). A tabela fato foi remontada por sucessivos `merge()` do DataFrame limpo com cada dimensão, recuperando as chaves estrangeiras.

### 4.2. Transformações no Pipeline ELT (dbt / SQL)

Executadas dentro do PostgreSQL sobre as tabelas brutas `raw_bps_*`, organizadas em duas camadas dbt.

**Camada de Staging (`stg_bps`, materializada como view).**
* **Unificação:** as três tabelas brutas são combinadas com `UNION ALL`.
* **Normalização de texto:** `TRIM` e `UPPER` aplicados às colunas textuais (nomes, descrições, categorias), padronizando espaços e caixa.
* **Conversão de tipo:** a coluna `insercao` é convertida para `DATE` via `CAST`.
* **Renomeação e reorganização:** as colunas recebem nomes de negócio e são agrupadas por entidade (produto, instituição, fornecedor, compra, tempo e métricas).
* **Filtragem:** são descartados os registros sem `preco_unitario`, `quantidade` ou `ano_compra` — campos essenciais para a tabela fato.

**Camada de Marts (dimensões e fato, materializadas como tabelas).**
* **Deduplicação por chave de negócio:** `dim_produto`, `dim_instituicao` e `dim_fornecedor` usam `DISTINCT ON` sobre a chave natural (respectivamente `codigo_br`, `cnpj_instituicao` e `cnpj_fornecedor`), mantendo uma única linha por chave.
* **Chaves substitutas:** geradas por `ROW_NUMBER()` — ordenado pela chave de negócio nas dimensões, e por `ROW_NUMBER() OVER ()` na fato (`id_fato`).
* **Dimensão de tempo:** construída por `DISTINCT` sobre `ano_compra`, com a descrição textual do período gerada via `CASE WHEN`.
* **Montagem da fato:** `LEFT JOIN` da staging com cada dimensão pela respectiva chave de negócio, trazendo as chaves estrangeiras e as métricas.

**Ajuste crítico — uso de `DISTINCT ON`.** Uma versão inicial das dimensões deduplicava com `DISTINCT` sobre múltiplas colunas, o que permitia mais de uma linha por chave de negócio. No `JOIN` com a fato, isso multiplicava os registros (de 84.465 para milhões de linhas). A correção foi adotar `DISTINCT ON (chave)`, garantindo exatamente uma linha por chave de negócio e restaurando a contagem correta de **84.465 registros** na `fato_compras`.

## 5. Comparativo entre ETL e ELT

O projeto implementou os dois pipelines até o mesmo Esquema Estrela, o que permite uma comparação direta entre as abordagens — não apenas teórica, mas baseada no comportamento observado em cada implementação.

### 5.1. Arquitetura e Fluxo de Dados

| Característica | Abordagem ETL (Python) | Abordagem ELT (dbt / SQL) |
| :--- | :--- | :--- |
| **Ordem de processamento** | Extract → Transform → Load | Extract → Load → Transform |
| **Local da transformação** | Memória RAM (Python / Pandas) | Motor do banco (PostgreSQL) |
| **Papel da carga** | Carrega o Esquema Estrela já pronto | Carrega o dado bruto em tabelas de *staging* (`raw_bps_*`) |
| **Paradigma da lógica** | Imperativo (funções Pandas, `merge`) | Declarativo (`SELECT`, `JOIN`, `DISTINCT ON`, `CASE WHEN`, *window functions*) |
| **Orquestração / camadas** | Sequência de células no notebook | Camadas versionadas no dbt (`staging` → `marts`) |

### 5.2. Vantagens e Desvantagens Observadas

**ETL (Python / Pandas)**
* **Vantagens:** flexibilidade total para manipulações finas linha a linha. Foi o que permitiu corrigir o encoding corrompido (`latin-1` → `utf-8`), remover a pontuação dos CNPJs e converter preços em formato brasileiro — operações trabalhosas de fazer em SQL puro.
* **Desvantagens:** todo o processamento ocorre em memória, o que limita a escala ao tamanho da RAM disponível. Além disso, a lógica de negócio fica "escondida" dentro do código imperativo, espalhada por células, o que dificulta a auditoria e o versionamento das regras.

**ELT (dbt / SQL)**
* **Vantagens:** usa o motor otimizado do banco para *joins* e agregações, escalando melhor com o volume. A organização em camadas (`staging` → `marts`) traz transparência, linhagem de dados, versionamento e testabilidade — cada regra de transformação é um arquivo SQL legível e rastreável.
* **Desvantagens:** exige carregar o dado bruto (e "sujo") no banco. Na nossa implementação, transformações finas ficaram pendentes: o `stg_bps` aplica apenas `TRIM`/`UPPER`, de modo que **o encoding corrompido não é corrigido** e os **CNPJs mantêm a pontuação original**.

### 5.3. Divergências Concretas Observadas

Por aplicarem transformações diferentes, os dois pipelines **não produzem dados idênticos**, embora cheguem ao mesmo modelo lógico:

* **Qualidade textual:** o ETL entrega texto com acentuação correta e CNPJs apenas com dígitos; o ELT preserva o encoding corrompido e a pontuação dos CNPJs.
* **Tratamento de ausências:** o ETL **preenche** nulos (`'Não informado'` / `0`) e mantém os dados; o ELT **descarta** registros sem `preco_unitario`, `quantidade` ou `ano_compra`.
* **Grão das dimensões:** o ETL deduplica pela combinação completa de atributos, enquanto o ELT deduplica pela chave de negócio (`DISTINCT ON`). Isso gera dimensões de tamanhos bem distintos:

| Dimensão | ETL (combinação de atributos) | ELT (chave de negócio) |
| :--- | :--- | :--- |
| `dim_produto` | 17.391 | ≈ 7.354 (por `codigo_br`) |
| `dim_instituicao` | 438 | uma linha por CNPJ (≈ 407) |
| `dim_fornecedor` | 19.604 | uma linha por CNPJ (≈ 1.929) |
| `dim_tempo` | 892 (datas) | 3 (por ano) |
| `fato_compras` | 84.465 | 84.465 |

A tabela fato coincide exatamente (84.465 registros) nas duas abordagens, confirmando que o evento transacional foi preservado de ponta a ponta. As dimensões divergem porque carregam níveis de detalhe diferentes — o ETL guarda variações de atributos descritivos, o ELT mantém uma entrada limpa por entidade.

### 5.4. Adequação ao Projeto

As duas abordagens se mostraram complementares, cada uma evidenciando os pontos fortes do seu paradigma. O **ETL** produziu, nesta implementação, dados de **maior qualidade textual**, graças à facilidade do Python para tratamentos finos. O **ELT com dbt**, por sua vez, trouxe **organização, transparência e manutenibilidade** superiores para a lógica de modelagem, ao expressar as regras como SQL declarativo versionado em camadas.

A conclusão, portanto, não é que uma abordagem seja absolutamente superior, mas que cada uma resolve melhor uma parte do problema: o tratamento físico e fino do dado (correção de encoding, limpeza de CNPJ) é mais natural no Python do ETL, enquanto a estruturação dimensional e a governança das regras de negócio são mais robustas no SQL/dbt do ELT. Uma solução madura combinaria as duas: a profundidade de limpeza do ETL com a arquitetura em camadas do ELT.

## 6. Apresentação de Três Análises e Insights

A partir do Data Warehouse consolidado, foram desenvolvidas consultas analíticas em SQL (disponíveis na pasta `analysis/`). Apresentam-se a seguir três análises distintas — cada uma explorando um ângulo diferente dos dados e uma técnica diferente de SQL — com os respectivos insights. As consultas foram executadas sobre as tabelas geradas pelo pipeline ELT.

> Observação: os nomes de produtos aparecem com acentuação corrompida nos resultados (ex.: `ÃCIDO`), pois — como discutido na Seção 5 — o pipeline ELT não corrige o encoding. Nos textos abaixo os nomes são apresentados de forma legível.

### Análise 1 — Evolução de Preço por Produto (2023–2025)

A consulta `evolucao_preco_por_produto.sql` lista os produtos com maior gasto total e, usando **pivotagem com `CASE WHEN`**, calcula o preço médio de cada ano em colunas separadas, além da variação percentual entre 2023 e 2025.

| Produto | Preço médio 2023 | Preço médio 2025 | Variação |
| :--- | ---: | ---: | ---: |
| Ácido Zoledrônico (sol. injetável) | R$ 451,00 | R$ 39.990,08 | +8.766,98% |
| Carfilzomibe (60 mg, pó p/ injetável) | R$ 2.404.419,76 | R$ 3.548,74 | −99,85% |
| Dapagliflozina (10 mg) | R$ 4,19 | R$ 61,69 | +1.372,16% |

**Insight.** Os produtos de maior gasto apresentam variações de preço extremas, e boa parte delas indica **anomalias de qualidade de dados**, não movimentos reais de mercado. O caso mais evidente é o Carfilzomibe, cujo preço médio "de 2023" (R$ 2,4 milhões por unidade) é claramente um erro de digitação — quando comparado aos R$ 3,5 mil de 2025, gera uma falsa queda de 99,85%. Da mesma forma, o salto do Ácido Zoledrônico para ~R$ 40 mil em 2025 (+8.766%) é um provável outlier. Por outro lado, aumentos como o da Dapagliflozina (+1.372%) podem refletir variação real de demanda e preço. A lição é que análises de preço médio precisam ser lidas com cautela e que a base se beneficiaria de um tratamento de outliers antes de conclusões de mercado.

### Análise 2 — Concentração de Gasto por Fornecedor

A consulta `top_fornecedores_por_gasto.sql` ordena os fornecedores por gasto total e, com a *window function* **`SUM(SUM(...)) OVER ()`**, calcula a participação percentual de cada um sobre o gasto nacional.

| Fornecedor | Compras | Gasto total | % do total |
| :--- | ---: | ---: | ---: |
| Agille Comércio de Medicamentos | 17 | R$ 22,8 bi | 46,80% |
| SP Hospitalar | 92 | R$ 3,8 bi | 7,73% |
| AstraZeneca do Brasil | 106 | R$ 3,0 bi | 6,16% |

**Insight.** O gasto é extremamente concentrado em poucos fornecedores. Um único fornecedor — a Agille Comércio de Medicamentos — responde por **46,8% de todo o gasto** da base, e o faz em **apenas 17 compras**, o que dá uma média superior a R$ 1,3 bilhão por transação. Os três maiores fornecedores somam cerca de 61% do total. Essa concentração de quase metade do gasto em transações de valor altíssimo e em volume tão baixo é um forte candidato a auditoria: pode representar contratos legítimos de grande porte (medicamentos de alto custo) ou, novamente, registros anômalos que distorcem o agregado.

### Análise 3 — Ranking de Instituições dentro de Cada Estado

A consulta `ranking_instituicoes_por_estado.sql` usa a *window function* **`RANK() OVER (PARTITION BY uf_instituicao ORDER BY gasto_total DESC)`** para posicionar cada instituição dentro do seu próprio estado, revelando quem lidera os gastos em cada UF.

| Instituição | UF | Esfera | Gasto total | Rank no estado |
| :--- | :--- | :--- | ---: | ---: |
| Secretaria de Estado da Saúde | PR | Estadual | R$ 24,5 bi | 1º |
| Secretaria de Estado da Saúde | SP | Estadual | R$ 11,2 bi | 1º |
| Secretaria de Estado de Saúde (SES) | RJ | Estadual | R$ 4,6 bi | 1º |

**Insight.** Os maiores gastos em quase todos os estados pertencem às **secretarias estaduais de saúde**, evidenciando um modelo de compra centralizado. O caso mais expressivo é a Secretaria de Estado da Saúde do Paraná: com R$ 24,5 bilhões, ela sozinha representa cerca de **metade de todo o gasto nacional** da base e praticamente a totalidade do gasto do Paraná. Isso explica a concentração geográfica observada na análise por UF (o Paraná responde por ~52% do gasto nacional): a concentração não é apenas regional, mas **institucional** — puxada por uma única secretaria. É provável que esse padrão reflita tanto a centralização das compras de alto custo quanto a completude com que cada ente reporta seus dados ao BPS, e não necessariamente uma atividade de compra uniforme pelo país.

---

*As análises acima representam três das cinco consultas desenvolvidas no projeto. As demais (`evolucao_preco_por_ano.sql` e `gasto_por_uf.sql`) complementam o panorama com a evolução temporal agregada e a distribuição geográfica do gasto.*

## 7. Reflexão sobre o Aprendizado

A execução deste projeto proporcionou uma visão prática dos desafios reais da Engenharia de Dados, indo além da teoria de construção de pipelines. As principais lições e dificuldades superadas são reunidas a seguir.

### 7.1. A Qualidade dos Dados é o Coração do Projeto

O maior aprendizado foi constatar que **a maior parte do esforço está no tratamento do dado, não na arquitetura**. As bases do BPS chegaram com problemas típicos de dados públicos: codificação corrompida nos acentos (`latin-1` lido como `utf-8`), preços em formato brasileiro, datas em texto, CNPJs com pontuação e categorias duplicadas por grafia. Cada um exigiu uma decisão de tratamento.

* **Desafio superado:** identificar o padrão do encoding corrompido (a presença do caractere `Ã`) e corrigi-lo com `.encode('latin-1').decode('utf-8')`.
* **Lição:** decisões de qualidade nem sempre são "limpar tudo". Mantivemos os 2.008 nulos de `insercao` propositalmente, porque imputar uma data fictícia seria pior do que registrar a ausência real — qualidade de dados também é saber o que **não** alterar.

### 7.2. Modelagem Orientada à Realidade dos Dados

Construir o Esquema Estrela exigiu traduzir dados transacionais sem chaves próprias em dimensões e fato consistentes.

* **Desafio superado:** o bug em que a deduplicação por múltiplas colunas multiplicava as linhas da fato (de 84.465 para milhões) ao fazer o `JOIN`. A correção — usar `DISTINCT ON (chave_de_negócio)` para garantir uma linha por chave — foi um dos pontos técnicos mais importantes do projeto.
* **Lição:** o nome de uma coluna não garante o seu conteúdo. Ao revisar o modelo, percebemos que a coluna `principio_ativo` na verdade carregava o indicador de genérico da fonte — um lembrete de que cada mapeamento de coluna precisa ser conferido contra o dado real, e não assumido pelo rótulo.

### 7.3. Maturidade na Escolha entre ETL e ELT

Implementar as duas abordagens em paralelo esclareceu, na prática, onde cada uma brilha — e desfez a ideia de que uma seja simplesmente "melhor".

* **Lição:** o Python (ETL) foi insubstituível para os tratamentos físicos e finos do dado (encoding, limpeza de CNPJ, parsing de preços), que seriam trabalhosos em SQL. Já o dbt (ELT) trouxe transparência, versionamento e organização em camadas muito superiores para a lógica de modelagem. A solução ideal não é escolher uma, mas combinar a profundidade de limpeza do ETL com a arquitetura declarativa e auditável do ELT.

### 7.4. Ceticismo Analítico Diante dos Resultados

As análises finais ensinaram que um número impressionante nem sempre é um insight — às vezes é um erro.

* **Desafio superado:** ao analisar a evolução de preços, encontramos valores implausíveis, como o Carfilzomibe a R$ 2,4 milhões por unidade em 2023 e a concentração de 46,8% do gasto total em um único fornecedor, em apenas 17 compras. Em vez de tratá-los como verdades, reconhecemos que são prováveis anomalias ou casos que demandam auditoria.
* **Lição:** o papel do engenheiro/analista de dados não é só produzir o número, mas questioná-lo. Médias são sensíveis a outliers, e concentrações extremas pedem investigação antes de virarem conclusão. Essa postura crítica foi tão importante quanto o domínio técnico das *window functions* e dos `JOINs`.

### 7.5. O Ambiente e as Ferramentas

Por fim, parte do aprendizado veio do próprio ambiente de desenvolvimento.

* **Desafio superado:** o conflito de versões do dbt (a linha Fusion mais nova não oferecia suporte estável ao PostgreSQL no nosso contexto), resolvido fixando `dbt-core` e `dbt-postgres` na versão 1.8 no `requirements.txt`. Some-se a isso o gerenciamento de credenciais via `.env` (fora do versionamento) e a configuração da conexão local com o PostgreSQL.
* **Lição:** reprodutibilidade exige disciplina de ambiente — dependências fixadas, segredos fora do Git e um repositório organizado são parte do trabalho de engenharia, não um detalhe posterior.