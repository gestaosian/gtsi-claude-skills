# gtsi-claude-skills

Marketplace interno de skills [Claude Code](https://claude.com/claude-code) da **GTSI — Grupo HP**, com foco em análise operacional, planejamento, execução assistida e padrões da plataforma de dados SIAN.

## Autor

Criado por **Marcelo Borges**.
Equipe: GTSI — Sian
Organização: Grupo HP

## Instalação

No Claude Code, adicione o marketplace e instale o plugin:

```bash
/plugin marketplace add https://github.com/<org>/gtsi-claude-skills
/plugin install gtsi-ops-plugin@gtsi-claude-skills
```

Ou clone localmente e aponte o marketplace para o caminho:

```bash
git clone https://github.com/<org>/gtsi-claude-skills.git
/plugin marketplace add /caminho/para/gtsi-claude-skills
/plugin install gtsi-ops-plugin@gtsi-claude-skills
```

Após instalar, as skills ficam disponíveis automaticamente — o Claude decide quando aplicar cada uma com base na `description` do frontmatter.

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
| **gtsi-claude-architect** | Analisa e reorganiza `CLAUDE.md`, `.claude/rules/`, templates e runbooks, preservando políticas existentes |
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

```
.gtsi/
  context/<autor>/   # contextos salvos (gitignored — efêmero)
  specs/<autor>/     # designs do gtsi-brainstorm (versionado)
  reports/<autor>/   # status reports (versionado)
  reviews/<autor>/   # code reviews e DAG reviews (versionado)
  plans/<autor>/     # planos de implementação (versionado)
```

## Estrutura do repositório

```
.claude-plugin/
  marketplace.json              # define o marketplace
plugins/
  gtsi-ops-plugin/
    .claude-plugin/
      plugin.json               # metadados do plugin
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

## Como contribuir

1. Crie uma branch a partir de `main`
2. Adicione/edite a skill em `plugins/gtsi-ops-plugin/skills/<nome>/SKILL.md`
3. Mantenha o frontmatter no padrão:
   ```yaml
   ---
   name: nome-da-skill
   description: Use when ... — descreve o gatilho de ativação
   ---
   ```
4. Abra PR contra `main`

## Convenções

- **Skills SIAN**: descrição curta no padrão `Use when …`, conteúdo em português, exemplos de código reais
- **ADRs** referenciados nas skills vivem no repositório da plataforma SIAN (`docs/adr/`), não aqui
- **Versionamento**: bump no `plugin.json` a cada mudança não-trivial
