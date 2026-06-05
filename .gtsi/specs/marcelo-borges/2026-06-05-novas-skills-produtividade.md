---
author: marcelo-borges
date: 2026-06-05
type: spec
branch: main
status: draft
---

# Spec: 6 novas skills de produtividade para gtsi-ops-plugin

## Contexto e motivação

O plugin `gtsi-ops-plugin` atualmente tem 8 skills (3 do copiloto operacional + 5 da plataforma SIAN). Falta cobertura de produtividade no dia a dia — salvar/restaurar contexto entre sessões, brainstorm de ideias, code review com lente operacional, status report e revisão de DAG.

Este spec define 6 novas skills, organizadas em 4 famílias, levando o plugin de 8 → 14 skills.

## Skills propostas

### Visão geral

| Família | Skill | Função |
|---|---|---|
| Copiloto operacional | `gtsi-brainstorm` | Ideia fuzzy → design refinado |
| Produtividade | `gtsi-context-save` | Salva estado de trabalho |
| Produtividade | `gtsi-context-restore` | Restaura estado salvo |
| Produtividade | `gtsi-code-review` | Revisa diff com lente operacional |
| Operacional | `gtsi-status-report` | Status report semanal estruturado |
| SIAN | `sian-dag-review` | Revisa DAG contra padrões da factory |

Fluxos naturais convergem em `gtsi-plan`:
- **Ideia nova** → `gtsi-brainstorm` → `gtsi-plan` → `gtsi-execute`
- **Problema existente** → `gtsi-analyze` → `gtsi-plan` → `gtsi-execute`

---

### 1. `gtsi-brainstorm`

**Description (frontmatter):**
> Use when the user has a fuzzy idea, feature request, or process improvement and needs to refine it into a concrete design before any planning — asks one clarifying question at a time, proposes 2-3 approaches with tradeoffs, presents the design in sections for approval, and writes a spec to `.gtsi/specs/<author>/`

**Comportamento:**
1. Explora contexto do projeto (git log, arquivos relevantes)
2. Faz perguntas de clarificação **uma por vez** (preferir múltipla escolha)
3. Propõe **2-3 abordagens** com tradeoffs e recomendação
4. Apresenta design por seções, pedindo aprovação a cada uma
5. Escreve spec em `.gtsi/specs/<author-slug>/<date>-<slug>.md`
6. Self-review do spec (placeholders, contradições, ambiguidade, escopo)
7. Pede revisão do usuário antes de transicionar
8. Transição: invoca `gtsi-plan` com a spec como contexto

**Hard gate:** Não escreve código, não cria arquivos além do spec, e não invoca `gtsi-plan` antes da aprovação explícita do usuário.

**Output principal:** spec em `.gtsi/specs/<author>/<date>-<slug>.md` (versionado).

---

### 2. `gtsi-context-save`

**Description:**
> Use when the user wants to save the current work state — pausing for the day, switching machines, end of work session, or before a risky operation — captures git state, active tasks, decisions made, and remaining work to a file that can be restored later by gtsi-context-restore

**O que captura:**
- Branch atual + `git status` (modificados, untracked, staged)
- Últimos 3 commits (`git log -3 --oneline`)
- Tarefas ativas via `TaskList`
- Decisões importantes da conversa atual (resumo escrito)
- Próximos passos (o que estava prestes a fazer)
- Bloqueios/dependências externas

**Antes de salvar:**
- Mostra ao usuário um resumo do que vai gravar
- Pede confirmação ou ajuste

**Output:** `.gtsi/context/<author>/<YYYY-MM-DD-HHMM>-<slug>.md`
- Slug derivado do branch ou tema da conversa
- Diretório `.gtsi/context/` recomendado no `.gitignore` (efêmero)

**Formato do arquivo:**
```markdown
---
author: marcelo-borges
date: 2026-06-05
time: 14:30
type: context
branch: refactor/dag-protheus
---

# Contexto: refactor/dag-protheus

## Git state
- Branch: refactor/dag-protheus
- Modificados: ...
- Untracked: ...
- Últimos commits: ...

## Tarefas ativas
- [ ] ...
- [x] ...

## Decisões
- ...

## Próximos passos
- ...

## Bloqueios
- ...
```

---

### 3. `gtsi-context-restore`

**Description:**
> Use when the user asks "where was I", "restore context", "resume", or starts a session and wants to pick up from a previously saved state — lists recent saved contexts (own author by default) and loads the chosen one, restoring TaskList if applicable

**Comportamento:**
1. Lista os últimos 5 contextos do **autor atual** (default)
2. Flag `--all` mostra contextos de todos os devs (útil em handoff)
3. Usuário seleciona qual restaurar
4. Apresenta resumo do contexto + recria `TaskList` se aplicável
5. Sugere próximo passo baseado no campo "Próximos passos"

**Cross-dev:** por padrão, só do autor atual (evita ruído). Handoff explícito usa `--all`.

**Nota sobre `TaskList`:** restauração cria **novas** tarefas baseadas no estado salvo (IDs são por sessão), não restaura IDs originais. O conteúdo da tarefa é preservado.

---

### 4. `gtsi-code-review`

**Description:**
> Use when the user asks to review a diff, PR, or set of changes before merge — applies the operational/governance lens (data correction policy, SIAN factory patterns, security, governance) and produces a verdict with justification

**Lentes de revisão:**
- **Correção de dados:** viola `sian-data-correction-policy`? (UPDATE direto em Silver/Gold, override em modelo dbt, etc.)
- **Padrões SIAN:** DAG segue factory? Destino de dado correto? Iceberg configurado certo?
- **Governança:** credenciais hardcoded? sys.path errado? variáveis Airflow novas não documentadas?
- **Riscos operacionais:** mudança destrutiva sem feature flag? Migração sem plano de rollback?

**Saída:**
- **Inline:** veredito + achados na conversa
- **Arquivo:** `.gtsi/reviews/<author>/<date>-<pr-id-ou-branch>.md`

**Veredito:**
- ✅ Aprovar
- ⚠️ Aprovar com ressalvas (lista pontos a corrigir antes do merge)
- ❌ Recusar (lista bloqueadores)

---

### 5. `gtsi-status-report`

**Description:**
> Use when the user asks for a weekly status report, sprint summary, or period activity report — gathers data from git log, completed tasks, and saved contexts to produce a structured report

**Fontes de dado:**
- `git log --author=<email> --since=<período>` no projeto
- Tarefas concluídas (`TaskList` filtrada por status)
- Contextos salvos no período
- PRs abertos/merged (via `gh pr list`)

**Formato:**
```markdown
# Status Report — Semana NN (DD/MM a DD/MM)

## Entregas
- ...

## Em andamento
- ...

## Bloqueios
- ...

## Riscos
- ...

## Próximos passos
- ...

## Pedidos de apoio
- ...
```

**Output:** `.gtsi/reports/<author>/<date>-<slug>.md` (ex: `2026-06-05-semana-23.md`)

**Período padrão:** última semana. Configurável via parâmetro.

---

### 6. `sian-dag-review`

**Description:**
> Use when the user asks to review a DAG file in the SIAN platform before commit or PR — applies the full sian-dag-factory checklist (naming, sys.path depth, factory usage, cluster_by, credential handling, pause-by-default) and references the related sian-* skills for context

**Checklist:**
- [ ] Nomenclatura `{sistema}__{tabela}__{cliente}__{frequência}.py`
- [ ] `dag_id` igual ao nome do arquivo sem `.py`
- [ ] `sys.path` com profundidade correta (3 `dirname()` para `dags/<sistema>/<domínio>/`)
- [ ] Usa factory (`create_protheus_dag`, `create_rm_dag`, etc.) — não constrói DAG manualmente
- [ ] Se Iceberg: `cluster_by` definido com colunas frequentes em filtros (≤ 4 colunas)
- [ ] Credenciais via Airflow Variables (não hardcoded)
- [ ] DAG pausada por padrão
- [ ] Localização em `dags/<sistema>/<domínio>/`

**Output:** inline + `.gtsi/reviews/<author>/<date>-dag-<nome>.md`

**Cross-references:** cita explicitamente `sian-dag-factory`, `sian-iceberg-setup`, `sian-new-system-checklist` quando relevante.

---

## Convenções compartilhadas

### Detecção do autor

Cada skill que cria artefato detecta o autor com esta lógica (embutida nas instruções da skill, executada via Bash):

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')
```

Se `AUTHOR_SLUG` for vazio ou `unknown`, a skill avisa:
> ⚠️ git config user.name não configurado. Salvando como `unknown`. Configure com: `git config user.name 'Seu Nome'`

### Paths padrão

```
.gtsi/
  context/<author-slug>/<YYYY-MM-DD-HHMM>-<slug>.md   # gitignore
  specs/<author-slug>/<YYYY-MM-DD>-<slug>.md          # versionado
  reports/<author-slug>/<YYYY-MM-DD>-<slug>.md        # versionado
  reviews/<author-slug>/<YYYY-MM-DD>-<slug>.md        # versionado
```

### Frontmatter padrão (todo artefato)

```yaml
---
author: marcelo-borges
date: 2026-06-05
type: spec | context | review | report
branch: nome-da-branch
---
```

### Slug do título

- Lowercase
- Espaços → hífen
- Remove acentos (ASCII transliteration)
- Apenas `a-z0-9-`
- Sem hífens duplicados, sem hífen no início/fim

### `.gitignore` recomendado (a adicionar)

```
# gtsi-claude-skills artifacts
.gtsi/context/
```

`specs/`, `reports/`, `reviews/` ficam versionados — são documentação útil para a equipe.

---

## Plano de rollout

**Ordem de implementação sugerida** (cada item é um SKILL.md autocontido):

1. `gtsi-context-save` + `gtsi-context-restore` (par mais pedido)
2. `gtsi-brainstorm` (analógico ao superpowers, base do fluxo de design)
3. `gtsi-code-review` + `sian-dag-review` (qualidade)
4. `gtsi-status-report` (operacional)

Preferência: **um único PR**, junto com:
- Atualização do README (nova tabela com 14 skills, exemplos de uso)
- Atualização do `plugin.json` (descrição + bump 1.2.0 → 1.3.0)
- Adição de `.gitignore` na raiz com `.gtsi/context/`
- Atualização do `marketplace.json` (descrição do plugin desatualizada — ainda diz "Skill operacional...")

Aceitável split se o PR ficar grande demais para revisar:
- **PR 1** — `context-save` + `context-restore` + `.gitignore` + atualização do README/plugin.json (estabelece padrão de artefato)
- **PR 2** — `brainstorm` + `code-review` + `dag-review` + `status-report` (usa o padrão já mergeado)

---

## Riscos e tradeoffs

| Risco | Mitigação |
|---|---|
| 14 skills é muito? Pode poluir o roteamento automático | Descriptions bem específicas com `Use when …` minimiza colisão |
| Cada skill ter o bloco bash de autor duplicado | Aceitável — skills são markdown, não compartilham código; duplicar 3 linhas é melhor que abstrair |
| `.gtsi/` no projeto pode confundir quem não usa o plugin | README explica claramente; pasta tem nome único, baixa chance de conflito |
| Dev não tem `git config user.name` setado | Skill avisa e usa fallback `$USER` ou `unknown` |
| Skills geram muito artefato versionado | Apenas specs/reports/reviews ficam versionados; contexto (mais volumoso) é ignorado |

---

## Critérios de sucesso

1. **Adoção:** equipe usa pelo menos `context-save/restore` semanalmente em 30 dias
2. **Cobertura:** ≥ 80% das DAGs novas passam por `sian-dag-review` antes do PR
3. **Documentação:** ≥ 1 spec gerado por `gtsi-brainstorm` por sprint
4. **Qualidade:** `gtsi-code-review` flagra ≥ 1 violação real de política por mês
5. **Não-objetivo:** não buscamos cobrir 100% dos casos — buscamos reduzir fricção em tarefas recorrentes

---

## Não-escopo (deixar para depois)

- `sian-bq-cost-check` (estima custo de query antes de rodar) — útil mas requer integração com BigQuery API
- `sian-dbt-model-helper` (boilerplate de modelo Silver/Gold) — útil mas mais complexo
- `gtsi-incident-doc` (template pós-incidente) — útil mas menos frequente
- `gtsi-meeting-notes` (ata estruturada) — escopo fora de "desenvolvimento"
- `gtsi-ticket-draft` (descritivo de chamado Freshworks) — já coberto por `gtsi-plan`

Avaliar após 30 dias de uso do batch inicial.
