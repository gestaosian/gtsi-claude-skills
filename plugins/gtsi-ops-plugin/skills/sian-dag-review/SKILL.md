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

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

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
