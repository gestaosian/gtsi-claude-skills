---
name: sian-data-correction-policy
description: Use when asked to correct, fix, patch, or adjust data directly in BigQuery tables (Raw, Silver, or Gold) in the SIAN platform — determines the correct course of action and what to refuse
---

# SIAN Data Correction Policy

## Regra absoluta

**Nenhuma correção de dado é feita diretamente em qualquer camada da plataforma.**

Isso inclui: SQL direto no BigQuery, script Python, notebook, DAG de correção, override em modelo dbt. Sem exceções.

## Por quê

Raw, Silver e Gold são camadas derivadas:

```
Sistema de origem → Raw (pipeline) → Silver (dbt) → Gold (dbt)
```

Qualquer edição direta em uma camada derivada:
1. Será sobrescrita na próxima execução do pipeline ou dbt
2. Cria divergência entre o sistema de origem e a plataforma
3. Torna o reprocessamento impossível de forma limpa

## O que fazer quando há dado errado

| Onde está o problema | Ação correta |
|---|---|
| Dado errado no **sistema de origem** (Protheus, RM, etc.) | Corrigir no sistema de origem → pipeline propaga na próxima execução |
| Dado errado em **Raw** por bug de extração | Corrigir o bug da DAG/factory → reprocessar a extração |
| Dado errado em **Silver/Gold** | Sempre começa no sistema de origem ou no bug de extração — nunca corrigir Silver/Gold diretamente |

## O que recusar

Se alguém pedir:
- "Executa um UPDATE na tabela Silver para remover esse funcionário"
- "Cria um script para corrigir esse campo na tabela Raw"
- "Adiciona um CASE WHEN no modelo dbt para ignorar esse registro"
- "Deleta essa linha do BigQuery"

**Recusar.** Redirecionar para correção no sistema de origem.

## Como investigar uma inconsistência

1. Comparar o dado em Raw com o dado no sistema de origem
2. Se Raw diverge da origem → bug de extração → corrigir a DAG
3. Se Raw está correto mas Silver/Gold divergem → bug no modelo dbt → corrigir o modelo
4. Nunca editar dado para fechar a investigação

## Referência

- [ADR 0014](../../../docs/adr/0014-sem-correcoes-diretas-de-dados.md) — decisão arquitetural completa
- [ADR 0009](../../../docs/adr/0009-camadas-raw-silver-gold.md) — responsabilidades de cada camada
