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

### Slug do arquivo

Derivado do branch atual ou do tema dominante da conversa.
Regra: lowercase, hífen, ASCII apenas, sem hífens duplicados.

Exemplos:
- branch `refactor/dag-protheus` → slug `refactor-dag-protheus`
- tema "debug do iceberg merge" → slug `debug-iceberg-merge`

## Formato do arquivo

````markdown
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
````

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
