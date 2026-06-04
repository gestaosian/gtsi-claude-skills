---
name: sian-new-system-checklist
description: Use when adding a new data source system or new table to the SIAN platform — provides the complete checklist of decisions and artifacts required before writing any code
---

# SIAN New System Checklist

## Visão geral

Ao adicionar um novo sistema de ingestão ou uma nova tabela ao repositório SIAN, existem decisões arquiteturais e artefatos que devem ser criados **antes** de escrever as DAGs. Este checklist garante que nada seja esquecido.

## Antes de escrever código

### 1. Decidir o destino do dado (ADR 0012)

| Pergunta | Resposta → Destino |
|---|---|
| O sistema é usado por mais de uma empresa? | Sim → `gcp-sian-dados` |
| O sistema é exclusivo de uma empresa? | Sim → `gcp-sian-proj-<empresa>` |

### 2. Definir o formato de tabela (ADR 0013)

| Volume esperado | Padrão de carga | Formato |
|---|---|---|
| < ~10M linhas | Full diário | BigQuery nativo (`table_format="native"`) |
| > ~10M linhas ou crescimento contínuo | Delta incremental | Iceberg (`table_format="iceberg"`) |

### 3. Verificar se existe factory para o sistema (ADR 0015)

- Sistema já tem factory? → Criar apenas o arquivo de DAG individual (~15 linhas)
- Sistema novo? → Criar a factory em `data/include/utils/<sistema>_dag_factory.py` primeiro

### 4. Definir pool de concorrência (ADR 0017)

- A API/banco do sistema tem rate limit ou limite de conexões?
- Se sim: criar pool `<sistema>_pool` no Airflow (Admin > Pools) antes do deploy
- Definir número de slots com base no limite do sistema fonte

## Checklist completo

**Arquitetura:**
- [ ] Destino decidido (gcp-sian-dados ou gcp-sian-proj-<empresa>)
- [ ] Formato de tabela decidido (nativo ou Iceberg)
- [ ] Factory criada ou confirmada como existente
- [ ] Pool criado no Composer (se sistema com rate limit)

**Schema:**
- [ ] Schema JSON criado em `data/include/schemas/<Sistema>/<TABELA>.json`
- [ ] Campos e tipos validados contra a API/banco fonte

**DAG:**
- [ ] Nomenclatura: `{sistema}__{tabela}__{cliente}__{frequência}.py`
- [ ] Localização: `dags/<sistema>/<domínio>/`
- [ ] sys.path com profundidade correta (2 dirname para 2 níveis, 3 para 3 níveis)
- [ ] dag_id idêntico ao nome do arquivo sem `.py`
- [ ] Variáveis Airflow (credenciais) documentadas se novas

**dbt (camadas Silver/Gold):**
- [ ] Pasta criada em `models/sian/<sistema>/` ou `models/clients/<empresa>/<sistema>/`
- [ ] Source declarado em `sources.yml`
- [ ] Modelos usam `source()` e `ref()` — sem nomes literais de tabela (ADR 0010)
- [ ] `data_owner`, `data_domain`, `data_product` definidos nos modelos gold (ADR 0011)

**ADR:**
- [ ] Decisões não-óbvias do sistema documentadas em ADR (se justificado)

## Nomenclatura de referência

```
dags/
  <sistema>/
    <domínio>/
      <sistema>__<tabela>__<cliente>__<frequência>.py

data/include/
  schemas/<Sistema>/<TABELA>.json
  utils/<sistema>_dag_factory.py

data/include/dbt_project_dados/models/
  sian/<sistema>/          # dado compartilhado
    silver/
    gold/
  clients/<empresa>/<sistema>/  # dado exclusivo
    silver/
    gold/
```
