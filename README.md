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

| Skill | Quando usa |
|---|---|
| **gtsi-ops** | Copiloto operacional corporativo — análise, planejamento e execução assistida em 3 modos (ANALYZE → PLAN → EXECUTE) |
| **sian-dag-factory** | Criar, modificar ou revisar DAGs no SIAN — garante padrão factory, nomenclatura e localização correta |
| **sian-data-correction-policy** | Pedidos de correção/patch de dados em qualquer camada (Raw/Silver/Gold) — define o que recusar e como redirecionar |
| **sian-data-destination** | Adicionar nova fonte/sistema/modelo dbt — decide entre `gcp-sian-dados` e projeto exclusivo da empresa |
| **sian-iceberg-setup** | Configurar formato de ingestão — escolhe entre BigQuery nativo e Iceberg Managed |
| **sian-new-system-checklist** | Adicionar novo sistema ou tabela ao SIAN — checklist completo de decisões e artefatos pré-código |

## Estrutura do repositório

```
.claude-plugin/
  marketplace.json              # define o marketplace
plugins/
  gtsi-ops-plugin/
    .claude-plugin/
      plugin.json               # metadados do plugin
    skills/
      gtsi-ops/SKILL.md
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
