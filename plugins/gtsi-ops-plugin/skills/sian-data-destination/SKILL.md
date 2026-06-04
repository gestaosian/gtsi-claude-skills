---
name: sian-data-destination
description: Use when adding a new data source, system, or dbt model to the SIAN platform — determines whether data belongs in gcp-sian-dados or in a client-specific GCP project, and how to configure the dbt model accordingly
---

# SIAN Data Destination

## Overview

Na plataforma SIAN, onde um dado é materializado (qual projeto GCP) é uma decisão arquitetural com impacto de custo. O `gcp-sian-dados` tem custos compartilhados entre todas as empresas do grupo — dados exclusivos de uma empresa não devem ser armazenados lá.

## Critério de destino

| Tipo | Critério | Destino BigQuery |
|---|---|---|
| **Dado compartilhado** | Sistema usado por mais de uma empresa cliente | `gcp-sian-dados` |
| **Dado exclusivo** | Sistema usado por apenas uma empresa cliente | `gcp-sian-proj-<empresa>` |

**Exemplos:**

| Sistema | Tipo | Destino |
|---|---|---|
| Protheus (multi-empresa via CODEMP) | Compartilhado | `gcp-sian-dados` |
| RM | Compartilhado | `gcp-sian-dados` |
| Pontotel | Compartilhado | `gcp-sian-dados` |
| MIX Urbi | Exclusivo Urbi | `gcp-sian-proj-urbi` |
| MIX HP | Exclusivo HP | `gcp-sian-proj-hp` |

**Dúvida?** Se um sistema serve instâncias separadas por empresa (contas/contratos diferentes), é exclusivo → projeto da empresa.

## Como configurar no dbt

### Dado compartilhado → `models/sian/<sistema>/`

```yaml
# dbt_project.yml — já configurado por default
models:
  dados_flow:
    sian:
      +database: gcp-sian-dados
      novo_sistema:
        silver:
          +schema: silver
          +materialized: incremental
        gold:
          +schema: gold
          +materialized: table
```

### Dado exclusivo → `models/clients/<empresa>/`

```yaml
# dbt_project.yml — adicionar entrada para a empresa
models:
  dados_flow:
    clients:
      urbi:
        +database: gcp-sian-proj-urbi
        mix:
          silver:
            +schema: silver
            +materialized: incremental
```

## Onde criar os arquivos de modelo

```
data/include/dbt_project_dados/models/
  sian/                     ← dado compartilhado
    rm/
    protheus/
    novo_sistema_compartilhado/
  clients/                  ← dado exclusivo
    urbi/
      mix/
    hp/
      mix/
```

## Regras importantes

- A decisão de destino deve ser declarada no PR que adiciona o sistema — não é reversível sem migração de dados
- Tabelas Raw (ingestão via DAG) sempre vão para `gcp-sian-dados.raw` independente do sistema — a separação acontece nas camadas Silver/Gold do dbt
- Dados em `gcp-sian-proj-*` são acessados pelos times de negócio via permissão RBAC no projeto da empresa; não expor via `gcp-sian-dados`

## Verificação rápida

Antes de criar um novo sistema, responder:
1. Mais de uma empresa usa este sistema? → compartilhado → `gcp-sian-dados`
2. Apenas uma empresa usa? → exclusivo → `gcp-sian-proj-<empresa>`
3. O sistema tem instâncias separadas por empresa (contratos/contas diferentes)? → exclusivo mesmo que o nome do software seja igual (ex.: MIX Urbi ≠ MIX HP)
