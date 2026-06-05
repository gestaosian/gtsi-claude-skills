# 6 Novas Skills de Produtividade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar 6 novas skills (`gtsi-brainstorm`, `gtsi-context-save`, `gtsi-context-restore`, `gtsi-code-review`, `gtsi-status-report`, `sian-dag-review`) ao `gtsi-ops-plugin`, levando-o de 8 para 14 skills, com convenção de artefatos em `.gtsi/<tipo>/<author-slug>/<date>-<slug>.md`.

**Architecture:** Cada skill é um arquivo `SKILL.md` autocontido em markdown, com frontmatter padrão (`name`, `description: Use when …`) e corpo em português. Skills que geram artefatos embutem um bloco bash para detecção de autor via `git config user.name`. Validação via script de lint que confere frontmatter. Sem testes automatizados de comportamento (skills são prompts, não código) — validação é por smoke test manual + lint estrutural.

**Tech Stack:** Markdown, YAML frontmatter, Bash (lint + author detection), git, gh CLI.

**Spec:** `.gtsi/specs/marcelo-borges/2026-06-05-novas-skills-produtividade.md`

---

## File Structure

**Criar:**
- `plugins/gtsi-ops-plugin/skills/gtsi-brainstorm/SKILL.md`
- `plugins/gtsi-ops-plugin/skills/gtsi-context-save/SKILL.md`
- `plugins/gtsi-ops-plugin/skills/gtsi-context-restore/SKILL.md`
- `plugins/gtsi-ops-plugin/skills/gtsi-code-review/SKILL.md`
- `plugins/gtsi-ops-plugin/skills/gtsi-status-report/SKILL.md`
- `plugins/gtsi-ops-plugin/skills/sian-dag-review/SKILL.md`
- `.gitignore` (na raiz)
- `scripts/lint-skills.sh` (validador de frontmatter)

**Modificar:**
- `README.md` (tabela de skills, agora com 14 entradas)
- `plugins/gtsi-ops-plugin/.claude-plugin/plugin.json` (descrição + version 1.2.0 → 1.3.0)
- `.claude-plugin/marketplace.json` (descrição do plugin desatualizada)

---

## Convenção compartilhada: bloco bash de detecção do autor

Cada SKILL.md que gera artefato inclui esta seção idêntica, em um bloco `### Detecção do autor`:

````markdown
### Detecção do autor

Antes de gravar o arquivo, execute:

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

Se `AUTHOR_SLUG` for `unknown`, avise:
> ⚠️ git config user.name não configurado. Salvando como `unknown`. Configure com: `git config user.name 'Seu Nome'`
````

Esse bloco é repetido nas 5 skills que geram artefato (todas exceto `gtsi-context-restore`, que só lê).

---

## Branch e fluxo de PRs

Trabalhar em **uma única branch** `feat/skills-produtividade` com **um único PR** ao final, conforme decidido no spec.

```bash
git checkout -b feat/skills-produtividade
```

Cada task abaixo termina com um commit. Push e PR só na última task.

---

## Task 1: Criar .gitignore e atualizar marketplace.json

**Files:**
- Create: `.gitignore`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Criar branch de trabalho**

```bash
git checkout main && git pull origin main
git checkout -b feat/skills-produtividade
```

- [ ] **Step 2: Criar .gitignore**

Conteúdo de `.gitignore`:

```gitignore
# Contextos efêmeros do gtsi-context-save (work-in-progress, não versionado)
.gtsi/context/

# Artefatos de IDE
.idea/
.vscode/
*.swp
*.swo

# Sistema operacional
.DS_Store
Thumbs.db
```

- [ ] **Step 3: Atualizar marketplace.json**

Edit `.claude-plugin/marketplace.json` — substituir o campo `description` do plugin de:

```json
"description": "Skill operacional para análise, planejamento e execução assistida",
```

Por:

```json
"description": "Skills GTSI/Sian para Claude Code: copiloto operacional (brainstorm, analyze, plan, execute), produtividade (context save/restore, code review, status report) e padrões da plataforma SIAN",
```

- [ ] **Step 4: Validar JSON**

Run: `jq . .claude-plugin/marketplace.json`
Expected: JSON formatado sem erro.

- [ ] **Step 5: Commit**

```bash
git add .gitignore .claude-plugin/marketplace.json
git commit -m "chore(repo): adicionar .gitignore e atualizar descrição do marketplace"
```

---

## Task 2: Criar script de lint de skills

**Files:**
- Create: `scripts/lint-skills.sh`

- [ ] **Step 1: Criar diretório scripts/**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Escrever scripts/lint-skills.sh**

```bash
#!/usr/bin/env bash
# Valida estrutura de frontmatter de todos os SKILL.md
# Uso: ./scripts/lint-skills.sh

set -e
SKILLS_DIR="plugins/gtsi-ops-plugin/skills"
errors=0
checked=0

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    skill=$(basename "$(dirname "$skill_md")")
    checked=$((checked + 1))

    # Primeira linha deve ser ---
    first=$(head -1 "$skill_md")
    if [ "$first" != "---" ]; then
        echo "❌ $skill: arquivo não começa com '---' (frontmatter ausente)"
        errors=$((errors + 1))
        continue
    fi

    # Extrai frontmatter (entre os primeiros dois ---)
    fm=$(awk '/^---$/{f++; next} f==1{print}' "$skill_md")

    # name presente?
    if ! echo "$fm" | grep -q "^name:"; then
        echo "❌ $skill: campo 'name' ausente no frontmatter"
        errors=$((errors + 1))
    fi

    # name bate com nome do diretório?
    declared_name=$(echo "$fm" | grep "^name:" | sed 's/^name: *//' | tr -d ' ')
    if [ "$declared_name" != "$skill" ]; then
        echo "❌ $skill: name='$declared_name' não bate com o diretório"
        errors=$((errors + 1))
    fi

    # description começa com "Use when"?
    if ! echo "$fm" | grep -qE "^description: *Use when"; then
        echo "❌ $skill: description deve começar com 'Use when ...'"
        errors=$((errors + 1))
    fi
done

echo ""
echo "Verificadas: $checked skills"
if [ $errors -eq 0 ]; then
    echo "✅ Todas válidas"
    exit 0
else
    echo "❌ $errors erro(s) encontrado(s)"
    exit 1
fi
```

- [ ] **Step 3: Tornar executável**

```bash
chmod +x scripts/lint-skills.sh
```

- [ ] **Step 4: Rodar o lint contra as skills atuais**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 8 skills
✅ Todas válidas
```

- [ ] **Step 5: Commit**

```bash
git add scripts/lint-skills.sh
git commit -m "chore(scripts): adicionar lint-skills.sh para validar frontmatter"
```

---

## Task 3: Skill gtsi-context-save

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/gtsi-context-save/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/gtsi-context-save
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
---
name: gtsi-context-save
description: Use when the user wants to save current work state — pausing for the day, switching machines, end of session, or before a risky operation — captures git state, active tasks, decisions made, and remaining work to a per-author file under .gtsi/context/ for later restore by gtsi-context-restore
---

# GTSI Context Save

Salva o estado de trabalho atual em um arquivo para retomar depois.

## Quando ativar

- "salvar contexto", "salva o que estou fazendo", "context save"
- "pausando por hoje", "vou trocar de máquina"
- "antes de fazer algo arriscado, salva o estado"

## O que captura

1. **Git state**: branch atual, modificados, untracked, staged
2. **Últimos 3 commits**: para situar onde a branch parou
3. **Tarefas ativas**: via TaskList (todas com status != completed)
4. **Decisões importantes da conversa**: resumir explicitamente
5. **Próximos passos**: o que ia fazer a seguir
6. **Bloqueios**: dependências externas, esperando alguém, etc.

## Fluxo

1. Coletar dados via Bash (git status, git log, etc.) e TaskList
2. Apresentar **resumo** do que vai salvar ao usuário
3. Pedir confirmação ou ajuste antes de gravar
4. Detectar autor (ver bloco abaixo)
5. Gravar arquivo em `.gtsi/context/<author-slug>/<YYYY-MM-DD-HHMM>-<slug>.md`
6. Confirmar caminho do arquivo gerado

### Detecção do autor

Antes de gravar o arquivo, execute:

\`\`\`bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
\`\`\`

Se `AUTHOR_SLUG` for `unknown`, avise:
> ⚠️ git config user.name não configurado. Salvando como `unknown`. Configure com: `git config user.name 'Seu Nome'`

### Slug do arquivo

Derivado do branch atual ou do tema dominante da conversa.
Regra: lowercase, hífen, ASCII apenas, sem hífens duplicados.

Exemplos:
- branch `refactor/dag-protheus` → slug `refactor-dag-protheus`
- tema "debug do iceberg merge" → slug `debug-iceberg-merge`

## Formato do arquivo

\`\`\`markdown
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
- Modificados:
  - data/include/utils/protheus_dag_factory.py
- Untracked:
  - dags/protheus/financeiro/protheus__se1__sian__daily.py
- Últimos commits:
  - abc1234 refactor: extrair lógica de merge
  - def5678 fix: corrigir sys.path em DAGs novas

## Tarefas ativas
- [ ] Adicionar cluster_by para nova tabela SE1
- [ ] Validar schema JSON contra API Protheus
- [x] Definir destino de dados (gcp-sian-dados)

## Decisões
- Optei por Iceberg pelo volume estimado > 50M linhas
- cluster_by inclui D_E_L_E_T_ e E1_FILIAL

## Próximos passos
- Rodar a DAG no ambiente de dev
- Validar custo do MERGE inicial

## Bloqueios
- Aguardando criação do pool protheus_pool no Composer (chamado #12345)
\`\`\`

## Diretório

`.gtsi/context/` está no `.gitignore` — contextos NÃO são versionados (são WIP efêmero, pessoais por dev).

## Não faça

- Não grave sem confirmar com o usuário primeiro
- Não capture credenciais, tokens ou senhas eventualmente colados na conversa
- Não sobrescreva um arquivo existente sem avisar (use timestamp para garantir unicidade)

## Exemplo de gatilho

- "salva o contexto, vou sair"
- "context save antes do almoço"
- "pausa aqui, salva tudo"
```

> **Nota ao implementador:** No SKILL.md acima, os blocos de código bash dentro do bloco markdown precisam ser escapados conforme renderizado (backticks triplos dentro de bloco markdown). Verifique que o arquivo final está sintaticamente correto após escrever.

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 9 skills
✅ Todas válidas
```

- [ ] **Step 4: Smoke test mental**

Leia o SKILL.md e responda: se o usuário disser "salva o contexto", o Claude consegue identificar e seguir o fluxo? (Resposta esperada: sim — gatilho explícito e fluxo claro.)

- [ ] **Step 5: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/gtsi-context-save/
git commit -m "feat(skills): adicionar gtsi-context-save"
```

---

## Task 4: Skill gtsi-context-restore

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/gtsi-context-restore/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/gtsi-context-restore
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
---
name: gtsi-context-restore
description: Use when the user asks "where was I", "restore context", "resume", or starts a session and wants to pick up from a previously saved state — lists recent saved contexts (own author by default, all devs via --all) and loads the chosen one, recreating active TaskList entries
---

# GTSI Context Restore

Restaura um contexto salvo anteriormente pela `gtsi-context-save`.

## Quando ativar

- "restaura contexto", "context restore", "onde eu parei"
- "resume", "pega onde parei"
- "carrega o último contexto"

## Fluxo

1. Detectar autor atual (mesmo bloco bash de detecção; sem gravar)
2. Listar contextos salvos:
   - **Default:** últimos 5 do autor atual em `.gtsi/context/<author-slug>/`
   - **Flag `--all` ou "todos":** últimos 5 de cada autor em `.gtsi/context/*/`
3. Apresentar a lista numerada com data, hora, branch e slug
4. Pedir ao usuário qual restaurar (ou aceitar "último" / "1" para o mais recente)
5. Ler o arquivo selecionado
6. Apresentar resumo do contexto
7. **Recriar TaskList**: para cada item em "## Tarefas ativas" com `[ ]`, criar uma nova task via TaskCreate (IDs antigos NÃO são preservados — são por sessão)
8. Sugerir próximo passo baseado no campo "## Próximos passos"

## Como listar

\`\`\`bash
ls -t .gtsi/context/<author-slug>/*.md 2>/dev/null | head -5
\`\`\`

Para `--all`:

\`\`\`bash
ls -t .gtsi/context/*/*.md 2>/dev/null | head -10
\`\`\`

## Formato esperado da listagem

```
Contextos salvos (autor: marcelo-borges):

1. 2026-06-05 14:30 — refactor-dag-protheus (branch: refactor/dag-protheus)
2. 2026-06-04 18:00 — debug-iceberg-merge (branch: fix/iceberg-merge)
3. 2026-06-03 16:45 — schema-validation-rm (branch: feat/rm-validation)
...

Qual restaurar? (número ou "último")
```

## Cross-dev (handoff)

Quando o usuário diz "restaura contexto do João" ou usa `--all`, listar de todos os autores:

```
Contextos salvos (todos os autores):

1. [marcelo-borges] 2026-06-05 14:30 — refactor-dag-protheus
2. [joao-silva]     2026-06-05 09:00 — debug-iceberg-merge
3. [marcelo-borges] 2026-06-04 18:00 — debug-iceberg-merge
...
```

## Não faça

- Não restaure sem perguntar qual contexto (a menos que haja apenas um)
- Não recrie tarefas já existentes na TaskList atual (compare por descrição)
- Não execute ações destrutivas mencionadas no contexto — apenas relate

## Exemplo de gatilho

- "onde eu parei?"
- "restaura o último contexto"
- "context restore"
- "pega o contexto do João" (cross-dev)
```

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 10 skills
✅ Todas válidas
```

- [ ] **Step 4: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/gtsi-context-restore/
git commit -m "feat(skills): adicionar gtsi-context-restore"
```

---

## Task 5: Skill gtsi-brainstorm

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/gtsi-brainstorm/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/gtsi-brainstorm
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
---
name: gtsi-brainstorm
description: Use when the user has a fuzzy idea, feature request, or process improvement and needs to refine it into a concrete design before any planning — asks one clarifying question at a time, proposes 2-3 approaches with tradeoffs, presents the design in sections for approval, writes a spec to .gtsi/specs/<author>/, and transitions to gtsi-plan after explicit approval
---

# GTSI Brainstorm

Transforma ideias fuzzy em designs aprovados, prontos para virar plano.

## Hard gate

Esta skill **NÃO**:
- escreve código
- cria arquivos (exceto a spec ao final)
- invoca `gtsi-plan` antes da aprovação explícita do usuário sobre o design

## Quando ativar

- "tenho uma ideia, ajuda a refinar"
- "brainstorm", "vamos pensar nisso"
- "queria fazer X mas não sei por onde começar"
- "como você abordaria Y?"

## Princípios

1. **Uma pergunta por vez** — não bombardear o usuário com múltiplas perguntas
2. **Múltipla escolha quando possível** — facilita a resposta
3. **YAGNI** — remover features desnecessárias do design
4. **Explorar 2-3 alternativas** — sempre propor opções com tradeoffs antes de fechar
5. **Validação incremental** — apresentar design por seções, aprovar uma de cada vez
6. **Flexibilidade** — voltar e clarificar se algo não fizer sentido

## Fluxo

### 1. Explorar contexto do projeto

```bash
git log --oneline -5
ls -la
```

Identificar: tipo de projeto, convenções, arquivos relacionados.

### 2. Perguntas de clarificação

Uma por mensagem. Foco: **propósito, restrições, critérios de sucesso**.

Se o escopo for muito amplo (múltiplos subsistemas independentes), pare e proponha decomposição:

> "Isso parece cobrir 3 subsistemas independentes (X, Y, Z). Sugiro tratar um por vez — cada um com seu spec, plano e implementação. Por qual quer começar?"

### 3. Propor 2-3 abordagens

Apresentar opções conversacionalmente, com sua recomendação primeiro e a justificativa:

```
## Abordagem A — [nome] [Recomendado]
[descrição em 2-4 linhas]
Tradeoffs: ...

## Abordagem B — [nome]
[descrição em 2-4 linhas]
Tradeoffs: ...

## Abordagem C — [nome]
[descrição em 2-4 linhas]
Tradeoffs: ...

Recomendo A porque [razão objetiva]. Qual seguimos?
```

### 4. Apresentar design por seções

Cobrir conforme a complexidade: arquitetura, componentes, fluxo de dados, tratamento de erro, teste. Pedir aprovação a cada seção.

Cada seção: **algumas frases se simples, até 200-300 palavras se nuançada.**

### 5. Detectar autor

\`\`\`bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
\`\`\`

### 6. Escrever spec

Path: `.gtsi/specs/<author-slug>/<YYYY-MM-DD>-<slug>.md`

Slug derivado do tema central do design (lowercase, hífen, ASCII).

Template:

\`\`\`markdown
---
author: <author-slug>
date: <YYYY-MM-DD>
type: spec
branch: <branch atual>
status: draft
---

# Spec: <Título>

## Contexto e motivação
## Solução proposta
## Componentes/arquitetura
## Fluxo de dados
## Tratamento de erro
## Plano de rollout
## Riscos e tradeoffs
## Critérios de sucesso
## Não-escopo
\`\`\`

### 7. Self-review do spec

Antes de mostrar ao usuário, varrer:
- Placeholders ("TBD", "TODO", "fill in"): substitua
- Contradições internas: resolva
- Escopo: se ainda for grande demais, sugira decomposição
- Ambiguidade: torne explícito

Fix inline. Sem nova revisão — só corrigir e seguir.

### 8. Pedir revisão do usuário

> "Spec escrito em `<path>`. Por favor revise e me diga se quer ajustes antes de gerar o plano."

Esperar resposta. Se pedir mudança, ajustar e re-rodar self-review.

### 9. Transição

Após aprovação, invocar a skill `gtsi-plan` passando o caminho do spec como contexto.

## Não faça

- Não pular perguntas para "ir direto ao design"
- Não escrever código, criar diretórios além do necessário para a spec, ou invocar `gtsi-plan` sem aprovação
- Não escrever especs gigantes — escopo grande = decomposição em múltiplos specs

## Exemplo de gatilho

- "tenho uma ideia, ajuda a refinar"
- "vamos pensar em como adicionar X"
- "brainstorm sobre como melhorar Y"
```

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 11 skills
✅ Todas válidas
```

- [ ] **Step 4: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/gtsi-brainstorm/
git commit -m "feat(skills): adicionar gtsi-brainstorm"
```

---

## Task 6: Skill gtsi-code-review

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/gtsi-code-review/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/gtsi-code-review
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
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

\`\`\`bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
\`\`\`

## Veredito

| Símbolo | Significado | Quando |
|---|---|---|
| ✅ | Aprovar | Nenhum problema relevante |
| ⚠️ | Aprovar com ressalvas | Pontos a melhorar antes do merge, mas não bloqueador |
| ❌ | Recusar | Violação de política, bug crítico, risco operacional |

## Formato do arquivo

Path: `.gtsi/reviews/<author-slug>/<YYYY-MM-DD>-<pr-id-ou-branch>.md`

\`\`\`markdown
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
\`\`\`

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
```

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 12 skills
✅ Todas válidas
```

- [ ] **Step 4: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/gtsi-code-review/
git commit -m "feat(skills): adicionar gtsi-code-review"
```

---

## Task 7: Skill sian-dag-review

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/sian-dag-review/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/sian-dag-review
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
---
name: sian-dag-review
description: Use when the user asks to review a DAG file in the SIAN platform before commit or PR — applies the full sian-dag-factory checklist (naming, sys.path depth, factory usage, cluster_by, credential handling, pause-by-default) and references related sian-* skills for context
---

# SIAN DAG Review

Revisa um arquivo de DAG SIAN contra todos os padrões da plataforma.

## Quando ativar

- "revisa essa DAG", "dag review"
- "essa DAG está OK?"
- "antes de commitar essa DAG, dá uma olhada"

## Checklist completo

### Nomenclatura
- [ ] Nome do arquivo: `{sistema}__{tabela}__{cliente}__{frequência}.py`
- [ ] Sistema e tabela em **minúsculas**
- [ ] Separador é `__` (underline duplo)
- [ ] Frequência é `daily` ou `intraday`
- [ ] `dag_id` no código é **exatamente igual** ao nome do arquivo sem `.py`

### Localização
- [ ] Arquivo está em `dags/<sistema>/<domínio>/`
- [ ] Domínio escolhido bate com a área de negócio da tabela na origem

### sys.path
- [ ] Para DAGs em `dags/<sistema>/<domínio>/` (3 níveis abaixo da raiz): usar **3 `dirname()`**
- [ ] Para DAGs em `dags/<sistema>/` (2 níveis): usar **2 `dirname()`**

### Factory
- [ ] Usa a factory do sistema (`create_protheus_dag`, `create_rm_dag`, etc.)
- [ ] **Não** constrói a DAG manualmente quando a factory existe
- [ ] Sistemas com factory: Protheus, RM, Pontotel, TDMAX, Supabase

### Iceberg (se aplicável)
- [ ] `table_format="iceberg"` para tabelas grandes ou crescimento contínuo
- [ ] `cluster_by` definido com até 4 colunas (frequentemente filtradas)
- [ ] Hard delete handler configurado se a fonte deleta fisicamente

### Credenciais e variáveis
- [ ] Credenciais via Airflow Variables (não hardcoded)
- [ ] Variáveis novas documentadas (no PR ou em comentário)

### Operacional
- [ ] DAG pausada por padrão (despausar só após validação em ambiente)
- [ ] `default_start_date` razoável (não criando backfill enorme acidental)
- [ ] `schedule` correto para a janela de carga

## Fluxo

1. Pedir o arquivo (`@dags/protheus/financeiro/protheus__se1__sian__daily.py`) ou diff
2. Aplicar checklist
3. Emitir veredito (ver `gtsi-code-review` para o padrão)
4. Detectar autor e gravar relatório em `.gtsi/reviews/<author-slug>/<date>-dag-<nome>.md`

### Detecção do autor

\`\`\`bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
\`\`\`

## Skills relacionadas

Para detalhes de cada item do checklist, consultar:
- `sian-dag-factory` — padrão de factory por sistema, nomenclatura
- `sian-iceberg-setup` — quando usar Iceberg vs nativo, cluster_by
- `sian-new-system-checklist` — checklist completo de criação
- `sian-data-destination` — qual projeto BigQuery usar
- `sian-data-correction-policy` — quando recusar mudanças

## Veredito

Mesmo padrão de `gtsi-code-review`: ✅ Aprovar / ⚠️ Aprovar com ressalvas / ❌ Recusar.

## Saída inline

Mostrar resultado na conversa **e** gravar o arquivo. O usuário não deve precisar abrir o arquivo para ver o resultado.

## Não faça

- Não aprovar DAG sem factory quando o sistema tem uma
- Não aprovar credencial hardcoded
- Não aprovar DAG despausada por default

## Exemplo de gatilho

- "revisa essa DAG: @dags/protheus/financeiro/protheus__se1__sian__daily.py"
- "dá uma olhada nessa DAG antes de eu commitar"
- "sian-dag-review"
```

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 13 skills
✅ Todas válidas
```

- [ ] **Step 4: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/sian-dag-review/
git commit -m "feat(skills): adicionar sian-dag-review"
```

---

## Task 8: Skill gtsi-status-report

**Files:**
- Create: `plugins/gtsi-ops-plugin/skills/gtsi-status-report/SKILL.md`

- [ ] **Step 1: Criar diretório**

```bash
mkdir -p plugins/gtsi-ops-plugin/skills/gtsi-status-report
```

- [ ] **Step 2: Escrever SKILL.md**

```markdown
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
   \`\`\`bash
   git log --author="$(git config user.email)" --since="1 week ago" --pretty=format:"%h %s" --no-merges
   \`\`\`
2. **PRs abertos/merged:**
   \`\`\`bash
   gh pr list --author "@me" --state all --search "created:>$(date -d '1 week ago' +%Y-%m-%d)"
   \`\`\`
3. **Contextos salvos no período:** `ls -t .gtsi/context/<author-slug>/` filtrado por data
4. **Tarefas concluídas:** via `TaskList` filtrada por `status: completed`

## Fluxo

1. Confirmar o período (default: última semana). Aceitar "última quinzena", "sprint atual", "mês"
2. Coletar dados das 4 fontes
3. Apresentar **rascunho** ao usuário (na conversa) para revisão e adição manual
4. Aplicar ajustes do usuário
5. Detectar autor e gravar em `.gtsi/reports/<author-slug>/<YYYY-MM-DD>-<slug>.md`

### Detecção do autor

\`\`\`bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
\`\`\`

### Slug do arquivo

Use o número da semana ISO quando aplicável:

\`\`\`bash
WEEK=$(date +%V)
YEAR=$(date +%Y)
SLUG="semana-$WEEK"
\`\`\`

Resultado: `.gtsi/reports/marcelo-borges/2026-06-05-semana-23.md`

## Formato do arquivo

\`\`\`markdown
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
\`\`\`

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
```

- [ ] **Step 3: Validar com lint**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 14 skills
✅ Todas válidas
```

- [ ] **Step 4: Commit**

```bash
git add plugins/gtsi-ops-plugin/skills/gtsi-status-report/
git commit -m "feat(skills): adicionar gtsi-status-report"
```

---

## Task 9: Atualizar README com nova tabela de 14 skills

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Substituir a seção "Skills disponíveis" do README**

Edit `README.md` — substituir todo o bloco entre `## Skills disponíveis` e a próxima seção (`## Estrutura do repositório`) pela seguinte versão:

```markdown
## Skills disponíveis

O plugin `gtsi-ops-plugin` inclui as seguintes skills:

**Copiloto operacional (workflow):**

| Skill | Quando usa |
|---|---|
| **gtsi-brainstorm** | Ideia fuzzy → design refinado em spec (com aprovação por seção) |
| **gtsi-analyze** | Problema operacional ou situação confusa → diagnóstico estruturado |
| **gtsi-plan** | Problema diagnosticado ou design aprovado → plano executável |
| **gtsi-execute** | Após autorização explícita → produção de artefatos com execução incremental |

**Produtividade (qualquer projeto):**

| Skill | Quando usa |
|---|---|
| **gtsi-context-save** | Salvar estado de trabalho (git, tasks, decisões, próximos passos) em `.gtsi/context/<autor>/` |
| **gtsi-context-restore** | Restaurar contexto salvo — lista do autor atual por default, `--all` para handoff entre devs |
| **gtsi-code-review** | Revisar diff/PR com lente operacional (política de dados, padrões SIAN, governança, riscos) |

**Operacional (gestão):**

| Skill | Quando usa |
|---|---|
| **gtsi-status-report** | Gerar status report do período (default: última semana) consolidando git log, PRs e tarefas |

**Plataforma de dados SIAN:**

| Skill | Quando usa |
|---|---|
| **sian-dag-review** | Revisar arquivo de DAG contra checklist completo da factory |
| **sian-dag-factory** | Criar, modificar ou revisar DAGs no SIAN — garante padrão factory, nomenclatura e localização |
| **sian-data-correction-policy** | Pedidos de correção/patch de dados em qualquer camada — define o que recusar |
| **sian-data-destination** | Adicionar nova fonte/sistema/modelo dbt — decide entre `gcp-sian-dados` e projeto exclusivo |
| **sian-iceberg-setup** | Configurar formato de ingestão — escolhe entre BigQuery nativo e Iceberg Managed |
| **sian-new-system-checklist** | Adicionar novo sistema ou tabela — checklist completo pré-código |

## Artefatos gerados pelas skills

Skills que produzem documentos salvam em `.gtsi/`, organizado por autor (detectado via `git config user.name`):

\`\`\`
.gtsi/
  context/<autor>/   # contextos salvos (gitignored — efêmero)
  specs/<autor>/     # designs do gtsi-brainstorm (versionado)
  reports/<autor>/   # status reports (versionado)
  reviews/<autor>/   # code reviews e DAG reviews (versionado)
  plans/<autor>/     # planos de implementação (versionado)
\`\`\`
```

- [ ] **Step 2: Atualizar a árvore em "Estrutura do repositório"**

Edit `README.md` — substituir a seção `skills/` da árvore por:

```
    skills/
      gtsi-brainstorm/SKILL.md
      gtsi-analyze/SKILL.md
      gtsi-plan/SKILL.md
      gtsi-execute/SKILL.md
      gtsi-context-save/SKILL.md
      gtsi-context-restore/SKILL.md
      gtsi-code-review/SKILL.md
      gtsi-status-report/SKILL.md
      sian-dag-review/SKILL.md
      sian-dag-factory/SKILL.md
      sian-data-correction-policy/SKILL.md
      sian-data-destination/SKILL.md
      sian-iceberg-setup/SKILL.md
      sian-new-system-checklist/SKILL.md
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): atualizar lista de skills com as 6 novas (14 total)"
```

---

## Task 10: Bump plugin.json para 1.3.0

**Files:**
- Modify: `plugins/gtsi-ops-plugin/.claude-plugin/plugin.json`

- [ ] **Step 1: Escrever plugin.json**

Substituir o conteúdo de `plugins/gtsi-ops-plugin/.claude-plugin/plugin.json` por:

```json
{
  "name": "gtsi-ops-plugin",
  "description": "Skills GTSI/Sian para Claude Code: copiloto operacional (brainstorm, analyze, plan, execute), produtividade (context save/restore, code review, status report) e padrões da plataforma SIAN (DAG factory/review, política de correção de dados, destino de dados, setup Iceberg, checklist de novo sistema)",
  "version": "1.3.0"
}
```

- [ ] **Step 2: Validar JSON**

Run: `jq . plugins/gtsi-ops-plugin/.claude-plugin/plugin.json`
Expected: JSON formatado sem erro.

- [ ] **Step 3: Commit**

```bash
git add plugins/gtsi-ops-plugin/.claude-plugin/plugin.json
git commit -m "chore(plugin): bump 1.2.0 → 1.3.0 (6 novas skills)"
```

---

## Task 11: Validação final, push, PR

**Files:** (nenhum modificado — só verificações)

- [ ] **Step 1: Rodar lint final**

Run: `./scripts/lint-skills.sh`
Expected:
```
Verificadas: 14 skills
✅ Todas válidas
```

- [ ] **Step 2: Verificar git status**

Run: `git status`
Expected: working tree clean, branch ahead de main.

- [ ] **Step 3: Verificar commits**

Run: `git log --oneline main..HEAD`
Expected: 10 commits (1 por task + ajustes), em ordem cronológica fazendo sentido.

- [ ] **Step 4: Push da branch**

```bash
git push -u origin feat/skills-produtividade
```

- [ ] **Step 5: Abrir PR**

```bash
gh pr create --title "feat(skills): adicionar 6 skills de produtividade (8 → 14 skills)" --body "$(cat <<'EOF'
## Resumo

Adiciona 6 novas skills ao plugin, organizadas em 4 famílias:

**Copiloto operacional:**
- `gtsi-brainstorm` — ideia fuzzy → design refinado

**Produtividade:**
- `gtsi-context-save` — salva estado de trabalho
- `gtsi-context-restore` — restaura contexto salvo
- `gtsi-code-review` — revisa diff com lente operacional

**Operacional:**
- `gtsi-status-report` — status report semanal estruturado

**SIAN:**
- `sian-dag-review` — revisa DAG contra padrões da factory

## Convenções estabelecidas

- Artefatos em `.gtsi/<tipo>/<author-slug>/<date>-<slug>.md`
- Autor detectado via `git config user.name` (com fallback)
- Contextos efêmeros no `.gitignore`; specs/reports/reviews versionados

## Acompanha

- `.gitignore` na raiz
- `scripts/lint-skills.sh` (validador de frontmatter)
- `marketplace.json` atualizado (descrição estava obsoleta)
- `plugin.json` versão 1.2.0 → 1.3.0
- README atualizado com as 14 skills

## Spec

`.gtsi/specs/marcelo-borges/2026-06-05-novas-skills-produtividade.md`

## Test plan

- [ ] Rodar `./scripts/lint-skills.sh` localmente — todas 14 válidas
- [ ] Validar JSON: `jq . .claude-plugin/marketplace.json plugins/gtsi-ops-plugin/.claude-plugin/plugin.json`
- [ ] Reinstalar o plugin no Claude Code e verificar que as 6 novas aparecem
- [ ] Disparar cada skill com um gatilho de exemplo

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 6: Reportar URL do PR**

Capturar a URL retornada por `gh pr create` e reportar ao usuário.

---

## Self-Review do plano

**1. Spec coverage:**
- ✅ 6 skills do spec → 6 tasks (Tasks 3-8)
- ✅ `.gitignore` → Task 1
- ✅ `marketplace.json` update → Task 1
- ✅ `plugin.json` bump → Task 10
- ✅ README update → Task 9
- ✅ Lint de frontmatter (não estava no spec mas é a "validação" das skills) → Task 2
- ✅ Convenção de autor (bash block) → repetido em cada skill que grava
- ✅ Critérios de sucesso (frontmatter válido, smoke test mental) → Steps 3-4 de cada task de skill

**2. Placeholder scan:** Nenhum TBD, TODO, "implement later" ou "add appropriate error handling". Cada step tem conteúdo completo.

**3. Type consistency:** Nomes de skills, paths e formato de frontmatter são consistentes em todas as tasks.

**4. Order check:** Skills produtividade primeiro (context-save/restore), depois workflow (brainstorm), depois qualidade (code-review, dag-review), depois operacional (status-report), depois documentação (README, plugin.json), depois release (push, PR). Faz sentido.

**Plano OK.**
