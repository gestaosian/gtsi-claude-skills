---
name: gtsi-status-report
description: Use when the user asks for a weekly status report, sprint summary, or period activity report — gathers data from git log, completed tasks, saved contexts and PRs to produce a structured report in .gtsi/reports/<author>/
---

# GTSI Status Report

Gera relatório de status do período (default: última semana) consolidando trabalho realizado.

## Quando ativar

- "status report", "relatório semanal", "status da semana"
- "o que fiz essa semana?"
- "monta o report para a reunião"
- "summary da sprint"

## Fontes de dado

1. **Git log do autor:**
   ```bash
   git log --author="$(git config user.email)" --since="1 week ago" --pretty=format:"%h %s" --no-merges
   ```
2. **PRs abertos/merged:**
   ```bash
   gh pr list --author "@me" --state all --search "created:>$(date -d '1 week ago' +%Y-%m-%d)"
   ```
3. **Contextos salvos no período:** `ls -t .gtsi/context/<author-slug>/` filtrado por data
4. **Tarefas concluídas:** via `TaskList` filtrada por `status: completed`

## Fluxo

1. Confirmar o período (default: última semana). Aceitar "última quinzena", "sprint atual", "mês"
2. Coletar dados das 4 fontes
3. Apresentar **rascunho** ao usuário (na conversa) para revisão e adição manual
4. Aplicar ajustes do usuário
5. Detectar autor e gravar em `.gtsi/reports/<author-slug>/<YYYY-MM-DD>-<slug>.md`

### Detecção do autor

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

### Slug do arquivo

Use o número da semana ISO quando aplicável:

```bash
WEEK=$(date +%V)
YEAR=$(date +%Y)
SLUG="semana-$WEEK"
```

Resultado: `.gtsi/reports/marcelo-borges/2026-06-05-semana-23.md`

## Formato do arquivo

````markdown
---
author: marcelo-borges
date: 2026-06-05
type: report
period: 2026-05-29 a 2026-06-05
---

# Status Report — Semana 23 (29/05 a 05/06)

## Entregas
- ✅ PR #42 mergeado: nova DAG Protheus SE1 com Iceberg
- ✅ Refatoração do factory de RM para suportar pool customizado
- ✅ Spec aprovado: 6 novas skills de produtividade

## Em andamento
- 🔄 Implementação das 6 novas skills (50% — 3 de 6 commitadas)
- 🔄 Validação de schema da tabela CT1 contra API Protheus

## Bloqueios
- ⛔ Aguardando pool `protheus_pool` no Composer (chamado #12345 aberto em 02/06)

## Riscos
- ⚠️ Janela de freeze pré-release começa quinta — priorizar conclusão até quarta

## Próximos passos (próxima semana)
- Finalizar implementação das skills restantes
- Validar deploy da DAG SE1 em produção
- Atualizar documentação interna

## Pedidos de apoio
- Revisão do PR #42 pela equipe (aberto há 2 dias)
````

## Estilo

- **Conciso, com bullets** — diretoria/líder lê em 30 segundos
- **Use ícones** para varredura rápida: ✅ entregue, 🔄 em andamento, ⛔ bloqueado, ⚠️ risco
- **Não invente dados** — se não tem PRs no período, escreva "(nenhum)"
- **Não substitua julgamento humano** — sempre apresentar rascunho para revisão antes de gravar

## Não faça

- Não gravar sem mostrar rascunho primeiro
- Não inferir/inventar status — pergunte se ficou ambíguo
- Não incluir informação confidencial (cliente, valor, dado pessoal) sem confirmação

## Exemplo de gatilho

- "monta o status da semana"
- "status report"
- "o que fiz nesse sprint"
- "relatório semanal"
