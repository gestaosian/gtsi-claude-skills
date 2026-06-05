---
name: gtsi-code-review
description: Use when the user asks to review a diff, PR, or set of changes before merge — applies the operational/governance lens (data correction policy, SIAN factory patterns, security, governance, operational risks) and produces a verdict (approve, approve with caveats, refuse) with justification, saving the review to .gtsi/reviews/<author>/
---

# GTSI Code Review

Revisa diff ou PR com lente operacional GTSI/SIAN.

## Quando ativar

- "revisa esse PR", "code review"
- "olha esse diff antes do merge"
- "verifica essas mudanças"
- "está pronto para merge?"

## Lentes de revisão

### 1. Correção de dados (CRÍTICO)
Viola a `sian-data-correction-policy`?
- UPDATE/DELETE direto em tabela Silver ou Gold
- Override em modelo dbt com CASE WHEN para ignorar registro
- Script de correção em camada derivada
→ **Recusar.** Redirecionar para correção no sistema de origem.

### 2. Padrões SIAN
- DAG segue factory? (`sian-dag-factory`)
- Nomenclatura `{sistema}__{tabela}__{cliente}__{frequência}.py`?
- sys.path com profundidade correta?
- Destino de dado adequado? (`sian-data-destination`)
- Iceberg configurado corretamente? (`sian-iceberg-setup`)

### 3. Governança
- Credenciais hardcoded? (deve usar Airflow Variables)
- Novas variáveis Airflow documentadas no PR?
- DAG criada pausada por padrão?

### 4. Riscos operacionais
- Mudança destrutiva sem feature flag ou plano de rollback?
- Migração sem janela de manutenção definida?
- Quebra de contrato com consumidor downstream?

### 5. Geral (qualquer projeto)
- Erros de digitação em strings de log/exception
- Catch genérico engolindo erro
- Hardcoded values que deveriam ser configuração

## Fluxo

1. Identificar o que revisar: PR atual (`gh pr view`), diff de branch (`git diff main...HEAD`), ou arquivos específicos
2. Coletar contexto: ler diff completo, verificar arquivos modificados
3. Aplicar as 5 lentes
4. Emitir veredito
5. Detectar autor e gravar relatório em `.gtsi/reviews/<author>/`

### Detecção do autor

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

## Veredito

| Símbolo | Significado | Quando |
|---|---|---|
| ✅ | Aprovar | Nenhum problema relevante |
| ⚠️ | Aprovar com ressalvas | Pontos a melhorar antes do merge, mas não bloqueador |
| ❌ | Recusar | Violação de política, bug crítico, risco operacional |

## Formato do arquivo

Path: `.gtsi/reviews/<author-slug>/<YYYY-MM-DD>-<pr-id-ou-branch>.md`

````markdown
---
author: marcelo-borges
date: 2026-06-05
type: review
target: PR #42 (feat/dag-se1)
verdict: warning
---

# Code Review — PR #42

## Veredito: ⚠️ Aprovar com ressalvas

## Achados

### 🔴 Bloqueadores
(nenhum)

### 🟡 Pontos de atenção
- `dags/protheus/financeiro/protheus__se1__sian__daily.py:23` — `cluster_by` não definido, mas tabela vai para Iceberg. Adicionar pelo menos `D_E_L_E_T_` e a chave primária.
- `data/include/utils/protheus_dag_factory.py:87` — log message com typo: "Falaha" → "Falha"

### 🟢 Observações
- Boa cobertura de schema JSON
- Nomenclatura correta

## Recomendação
Corrigir os 2 pontos amarelos e mergear.
````

## Saída inline

Além de gravar o arquivo, **mostrar o veredito e os achados na conversa** — o usuário não deve precisar abrir o arquivo para saber o resultado.

## Não faça

- Não aprovar PRs com violação da `sian-data-correction-policy` — recusar
- Não revisar sem ter o diff em mãos — peça `git diff` ou número do PR
- Não inventar problemas — se está OK, aprovar é a resposta certa

## Exemplo de gatilho

- "revisa esse diff antes do merge"
- "code review do PR #42"
- "olha essas mudanças, está pronto?"
