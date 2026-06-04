---
name: sian-dag-factory
description: Use when creating, modifying, or reviewing DAGs in the SIAN data platform — ensures factory pattern is followed, correct naming convention and folder placement are applied
---

# SIAN DAG Factory Pattern

## Overview

No sistema SIAN, DAGs não são criadas manualmente arquivo a arquivo. Cada sistema de origem tem uma **factory** que encapsula o padrão de extração, validação e carga. Criar uma DAG avulsa quando existe factory para o sistema é um erro arquitetural.

## Factories disponíveis

| Sistema | Factory | Função principal |
|---|---|---|
| Protheus | `protheus_dag_factory.py` | `create_protheus_dag()` |
| RM | `rm_dag_factory.py` | `create_rm_dag()` |
| Pontotel | `pontotel_dag_factory.py` | `create_pontotel_dag()` |
| TDMAX | `tdmax_dag_factory.py` | `create_tdmax_dag()` |
| Supabase | `supabase_dag_factory.py` | `create_supabase_dag()` |

Todas as factories ficam em `data/include/utils/`.

## Convenção de nomenclatura

```
{sistema}__{tabela}__{cliente}__{frequência}.py
```

Exemplos:
- `protheus__ct1__sian__daily.py`
- `protheus__sb1__sian__intraday.py`
- `rm__ra__sian__daily.py`

**Regras:**
- Separador duplo underline `__` entre partes
- Sistema e tabela em minúsculas
- Frequência: `daily` ou `intraday`
- dag_id igual ao nome do arquivo (sem `.py`)

## Onde criar a DAG

Estrutura: `dags/<sistema>/<domínio>/`

```
dags/
  protheus/
    controladoria/   → tabelas de controladoria (CT1, CT2, CQ0...)
    financeiro/      → tabelas financeiras
    manutencao/      → tabelas de manutenção
    operacao/        → tabelas operacionais
    facilites/       → tabelas de facilidades
    suprimentos/     → tabelas de suprimentos
  rm/
    <domínio>/
```

Escolher o domínio baseado no módulo/área de negócio da tabela no sistema de origem.

## Como criar uma DAG Protheus

```python
import os
import sys

try:
    _dag_file = os.path.abspath(__file__)
    _dags_root = os.path.dirname(os.path.dirname(os.path.dirname(_dag_file)))
    _project_root = os.path.dirname(_dags_root)
    for _p in (_project_root, "/home/airflow/gcs"):
        if _p and os.path.isdir(_p) and _p not in sys.path:
            sys.path.insert(0, _p)
except Exception as e:
    print(f"AVISO: falha ao configurar sys.path: {e}")

from data.include.utils.protheus_dag_factory import create_protheus_dag

dag = create_protheus_dag(
    dag_id="protheus__ct1__sian__daily",
    table_name="CT1",
    schedule="0 6 * * *",
    table_format="iceberg",       # "native" ou "iceberg" — ver sian-iceberg-setup
    cluster_by=["D_E_L_E_T_"],
)
```

**Parâmetros obrigatórios:** `dag_id`, `table_name`, `schedule`
**Parâmetros importantes:** `table_format`, `cluster_by`, `default_start_date`

## sys.path — profundidade correta

DAGs em `dags/<sistema>/<domínio>/` ficam 3 níveis abaixo da raiz. O bloco sys.path usa **3 `dirname()`**. Se a DAG estiver em `dags/<sistema>/` (2 níveis), usar **2 `dirname()`**.

## Regras críticas

- **Nunca** criar DAG avulsa para sistema que já tem factory
- **Nunca** hardcodar credenciais — usar Airflow Variables (`protheus_api_url_new`, `protheus_token_authorization`)
- A DAG deve ser pausada ao criar; despausar só após validação no ambiente
- dag_id deve ser **exatamente igual** ao nome do arquivo sem `.py`
