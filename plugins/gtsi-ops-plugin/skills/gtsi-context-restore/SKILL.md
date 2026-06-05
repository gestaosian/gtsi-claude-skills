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

```bash
ls -t .gtsi/context/<author-slug>/*.md 2>/dev/null | head -5
```

Para `--all`:

```bash
ls -t .gtsi/context/*/*.md 2>/dev/null | head -10
```

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
