---
name: sian-iceberg-setup
description: Use when configuring table ingestion format in the SIAN platform — guides the choice between native BigQuery and Iceberg, and provides the correct connection, storage URI, and hard delete configuration
---

# SIAN Iceberg Setup

## Overview

Na plataforma SIAN, tabelas de ingestão na camada Raw podem usar dois formatos: **BigQuery nativo** (WRITE_TRUNCATE) ou **Apache Iceberg Managed** (MERGE incremental). A escolha errada aumenta custo desnecessariamente ou cria problemas de escala.

## Quando usar Iceberg vs. Nativo

| Critério | Nativo (`"native"`) | Iceberg (`"iceberg"`) |
|---|---|---|
| Volume total | Pequeno/médio (< ~10M linhas) | Grande ou crescimento contínuo |
| Padrão de carga | Full reload diário (WRITE_TRUNCATE) | Delta incremental por watermark (MERGE) |
| Hard deletes | Não aplicável | Necessário — configurar hard_delete_handler |
| Histórico preservado | Não (substituído a cada run) | Sim (upsert preserva registros não alterados) |

## Parâmetros obrigatórios para Iceberg

```python
dag = create_protheus_dag(
    dag_id="protheus__sc1__sian__daily",
    table_name="SC1",
    schedule="0 5 * * *",
    table_format="iceberg",
    cluster_by=["D_E_L_E_T_", "B1_COD"],  # até 4 colunas
)
```

Os parâmetros `connection_id` e `storage_uri` são calculados automaticamente pela factory:

| Parâmetro | Valor fixo |
|---|---|
| `connection_id` | `gcp-sian-dados.us-east1.iceberg-conn` |
| `storage_uri` | `gs://gcp-sian-dados-iceberg/raw/{sistema}/{tabela_lower}/` |

Exemplo SC1: `gs://gcp-sian-dados-iceberg/raw/protheus/sc1/`

## cluster_by — boas práticas

- Sempre incluir colunas usadas em filtros frequentes (ex.: `D_E_L_E_T_`, chave primária, data de referência)
- Máximo 4 colunas
- Reduz custo de scan nas queries Silver do dbt

## Hard Delete Handler

Tabelas Iceberg com deleções físicas na fonte precisam do `hard_delete_handler.py`.

```python
# Configurar no DAG ou em pipeline separado
from data.include.utils.hard_delete_handler import handle_hard_deletes

handle_hard_deletes(
    project="gcp-sian-dados",
    dataset="raw",
    table="SC1",
    source_keys=[...],   # chaves primárias retornadas pela API
    key_column="B1_COD",
)
```

Acionar quando: a fonte não marca registros deletados com flag — eles simplesmente somem da API.

## Infraestrutura necessária

| Recurso | Status |
|---|---|
| Bucket `gcp-sian-dados-iceberg` | Provisionado |
| BigLake connection `iceberg-conn` | Provisionada em `gcp-sian-dados.us-east1` |
| Dataset `raw_staging` (temp tables, 24h TTL) | Provisionado |

Não criar esses recursos manualmente — já existem. Se qualquer um estiver faltando, abrir chamado de infraestrutura.

## Erros comuns

| Erro | Causa provável |
|---|---|
| `table_format='iceberg' requer connection_id e storage_uri` | Usando `build_table_ddl` diretamente sem os parâmetros — usar factory |
| Tabela não aparece no BigQuery console | Tabela Iceberg aparece como "External table (BigLake)" — comportamento normal |
| Dados duplicados após rerun | watermark não foi salvo após MERGE — ver sian-dag-factory |
