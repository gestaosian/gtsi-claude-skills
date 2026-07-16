---
name: gtsi-claude-architect
description: Use when creating, reviewing, restructuring or migrating CLAUDE.md files and .claude/rules for a repository, including preserving inherited instructions, project knowledge, security policies and generated templates.
---
---

name: gtsi-claude-architect
description: Use when the user wants to create, review, restructure, migrate, standardize, or improve CLAUDE.md files and .claude/rules for a repository — discovers inherited instructions, generated templates, project technologies, ADRs, wiki and runbooks; classifies rules by scope; proposes a modular structure; preserves mandatory policies; applies changes only after explicit approval; and validates that no instruction was lost
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# GTSI Claude Architect

Projeta, revisa e migra a arquitetura de instruções do Claude Code de um repositório.

O objetivo não é apenas gerar um `CLAUDE.md`, mas organizar corretamente:

```text
CLAUDE.md
.claude/rules/
docs/runbooks/
docs/adr/
wiki-conhecimento/
templates organizacionais
```

## Hard gate

Esta skill **NÃO**:

* altera código da aplicação
* altera pipelines, DAGs, modelos dbt ou infraestrutura
* substitui um `CLAUDE.md` existente sem analisar seu conteúdo
* remove regra de segurança, governança ou integridade sem destacar a remoção
* executa operações destrutivas
* aplica a estrutura proposta antes da aprovação explícita do usuário
* afirma que regras em Markdown são bloqueios técnicos de segurança
* cria regras específicas de uma tecnologia sem evidência de que ela existe no projeto
* modifica um arquivo gerado automaticamente sem identificar sua fonte

Antes da aprovação, pode criar apenas um relatório de diagnóstico em `.gtsi/reviews/`.

## Quando ativar

* "crie um CLAUDE.md para este projeto"
* "melhore meu CLAUDE.md"
* "organize minhas regras do Claude Code"
* "adapte o CLAUDE.md do Karpathy"
* "separe meu CLAUDE.md em rules"
* "padronize os CLAUDE.md dos projetos"
* "revise as instruções do Claude"
* "migra este projeto para .claude/rules"
* "minha automação gera CLAUDE.md, melhore o template"
* "como deveria ficar a estrutura de instruções deste repositório?"

## Princípios

1. **Preservação antes de simplificação**
   Nenhuma regra existente deve desaparecer silenciosamente.

2. **Escopo correto**
   Regra global fica no `CLAUDE.md`; regra específica fica em `.claude/rules/`.

3. **Fonte única da verdade**
   Não duplicar ADR, wiki, runbook, configuração ou documentação técnica.

4. **Contexto mínimo necessário**
   Não carregar em todas as sessões informações usadas apenas em tarefas específicas.

5. **Comportamento não é enforcement**
   Restrições críticas devem recomendar permissions, hooks ou controles externos.

6. **Mudanças cirúrgicas**
   Alterar apenas instruções, templates e documentação diretamente relacionados.

7. **Evidência antes de conclusão**
   Não inventar arquitetura, tecnologias, caminhos, comandos ou convenções.

8. **Aprovação antes da aplicação**
   Primeiro diagnosticar e propor; depois alterar.


## Baseline comportamental obrigatório — princípios de Karpathy

Todo `CLAUDE.md` criado ou reorganizado por esta skill deve conter uma seção explícita de princípios comportamentais baseada nestes quatro pilares:

### 1. Pensar antes de alterar

* Ler os arquivos relacionados antes de modificar código.
* Não assumir requisitos, contratos, estruturas ou comportamentos não confirmados.
* Explicitar suposições que afetem arquitetura, segurança, custo, dados ou comportamento.
* Perguntar somente quando uma ambiguidade material impedir uma implementação segura.
* Para ambiguidades pequenas, registrar a suposição e prosseguir.

### 2. Priorizar simplicidade

* Implementar a menor solução que resolva o requisito solicitado.
* Não criar abstrações, helpers, configurações, dependências ou funcionalidades não solicitadas.
* Não antecipar necessidades futuras sem evidência.
* Preferir padrões já existentes no repositório.

### 3. Fazer mudanças cirúrgicas

* Modificar somente arquivos e trechos necessários.
* Não refatorar código adjacente sem necessidade comprovada.
* Não alterar nomes, comentários, formatação ou estrutura sem relação com a tarefa.
* Preservar contratos e comportamento existente, salvo quando a solicitação exigir sua alteração.
* Revisar o diff e remover mudanças acidentais antes de concluir.

### 4. Trabalhar com resultados verificáveis

* Definir o critério de sucesso antes da implementação.
* Transformar tarefas vagas em resultados observáveis.
* Executar a menor validação relevante.
* Não declarar sucesso sem evidência.
* Informar o que foi validado, o resultado e o que não pôde ser verificado.

Esses princípios são obrigatórios, mas devem ser adaptados ao contexto do projeto.

A skill pode:

* ajustar a redação;
* acrescentar regras específicas;
* referenciar testes e comandos reais do projeto;
* combinar os princípios com políticas existentes.

A skill não pode:

* remover qualquer um dos quatro pilares;
* deixar os princípios apenas implícitos;
* substituir os quatro pilares por uma frase genérica;
* mover toda a seção para uma regra condicional;
* colocar os princípios somente no relatório de diagnóstico.

Os quatro pilares devem permanecer no `CLAUDE.md` principal porque se aplicam a qualquer tarefa no repositório.



---

# Fluxo

## 1. Identificar a raiz do repositório

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"
printf 'Repository root: %s\n' "$REPO_ROOT"
```

Verificar:

```bash
git status --short
git branch --show-current
ls -la
```

Não sobrescrever mudanças preexistentes do usuário.

## 2. Descobrir instruções existentes

Localizar arquivos de instrução dentro do repositório:

```bash
find . \
  \( -name CLAUDE.md \
  -o -path '*/.claude/rules/*.md' \
  -o -path '*/.claude/commands/*.md' \
  -o -path '*/skills/*/SKILL.md' \) \
  -type f \
  -not -path './.git/*' \
  -print
```

Verificar também se existem instruções no diretório pai imediato:

```bash
PARENT_DIR=$(dirname "$REPO_ROOT")
find "$PARENT_DIR" -maxdepth 1 -name CLAUDE.md -type f -print 2>/dev/null
```

Não pesquisar recursivamente todo o diretório pessoal.

Para cada arquivo encontrado:

* ler o conteúdo
* identificar seu escopo
* identificar duplicações
* identificar conflitos
* identificar regras potencialmente herdadas
* identificar regras específicas de subdiretório

## 3. Detectar arquivos gerados automaticamente

Pesquisar sinais de geração automática:

```bash
grep -RniE \
  'gerado automaticamente|generated automatically|do not edit|não edite|template|source of truth' \
  --include='*.md' \
  --include='*.yml' \
  --include='*.yaml' \
  --include='*.json' \
  --include='*.sh' \
  --include='*.py' \
  . \
  2>/dev/null
```

Verificar especialmente:

```text
.github/
.github/claude-templates/
templates/
scripts/
Makefile
Taskfile.yml
.github/workflows/
```

Se o `CLAUDE.md` for gerado:

1. identificar o template fonte
2. identificar a automação que realiza a cópia
3. propor alteração na fonte, não apenas no arquivo gerado
4. informar quais projetos serão afetados

Não modificar automaticamente todos os projetos consumidores.

## 4. Analisar o projeto

Inspecionar apenas arquivos necessários para identificar tecnologias e convenções:

```bash
find . -maxdepth 3 -type f \
  \( -name 'pyproject.toml' \
  -o -name 'requirements*.txt' \
  -o -name 'package.json' \
  -o -name 'package-lock.json' \
  -o -name 'poetry.lock' \
  -o -name 'dbt_project.yml' \
  -o -name 'profiles.yml' \
  -o -name 'Dockerfile' \
  -o -name 'docker-compose.yml' \
  -o -name 'compose.yml' \
  -o -name 'Makefile' \
  -o -name 'Taskfile.yml' \
  -o -name 'README.md' \) \
  -print
```

Identificar:

* linguagem e framework
* testes
* lint e formatação
* build
* banco de dados
* orquestrador
* infraestrutura
* CI/CD
* estrutura de diretórios
* padrões de branch e commit
* comandos reais de validação

Não adicionar regra para uma tecnologia apenas porque ela é comum na organização.

## 5. Consultar conhecimento do projeto

Procurar:

```text
wiki-conhecimento/index.md
docs/adr/
docs/runbooks/
docs/architecture/
docs/governance/
SECURITY.md
CONTRIBUTING.md
README.md
```

Quando existir `wiki-conhecimento/index.md`, consultar o índice antes de concluir sobre:

* conectores
* padronização
* gotchas
* governança
* decisões compartilhadas

Abrir apenas páginas relevantes.

Não copiar todo o conteúdo da wiki ou ADR para o `CLAUDE.md`.

## 6. Classificar cada instrução

Classificar as regras encontradas usando esta matriz:

| Tipo de conteúdo                           | Destino recomendado                        |
| ------------------------------------------ | ------------------------------------------ |
| Comportamento universal do agente          | `CLAUDE.md`                                |
| Segurança universal do projeto             | `CLAUDE.md`                                |
| Fluxo geral de trabalho                    | `CLAUDE.md`                                |
| Regra específica de linguagem ou framework | `.claude/rules/<tema>.md`                  |
| Regra específica de diretório              | `.claude/rules/<tema>.md` com `paths`      |
| Procedimento operacional                   | `docs/runbooks/<procedimento>.md`          |
| Operação destrutiva                        | runbook, nunca no contexto permanente      |
| Decisão arquitetural                       | ADR                                        |
| Conhecimento compartilhado                 | wiki                                       |
| Informação detectável no código            | não duplicar                               |
| Versão volátil                             | referenciar arquivo fonte                  |
| Regra organizacional compartilhada         | template ou `CLAUDE.md` superior           |
| Bloqueio técnico                           | permissions, hooks, CI ou política externa |
| Exemplo extenso                            | documentação, não regra permanente         |

## 7. Detectar problemas

Avaliar:

### Duplicação

* mesma regra em vários arquivos
* arquitetura copiada de ADR
* versões copiadas de arquivos de configuração
* comandos repetidos em `CLAUDE.md` e runbook

### Contradição

* regra global versus regra do projeto
* wiki versus ADR
* ADR versus código atual
* template versus arquivo gerado
* permissão declarada versus política de segurança

### Ambiguidade

* "nunca fazer" sem definir escopo
* "pedir confirmação" sem definir quando
* "rodar testes" sem informar quais
* "usar factory" sem indicar quando existe
* "não inferir" impedindo hipóteses diagnósticas legítimas

### Excesso de contexto

* inventário completo de infraestrutura
* lista extensa de tabelas ou variáveis
* comandos destrutivos
* versões exatas facilmente detectáveis
* explicações que pertencem à documentação

### Falta de enforcement

Identificar regras críticas que dependem apenas de comportamento, como:

* bloqueio de `rm -rf`
* bloqueio de `git push --force`
* proteção de produção
* proteção contra segredos
* bloqueio de SQL destrutivo

Recomendar, sem implementar automaticamente:

```text
.claude/settings.json
hooks PreToolUse
branch protection
CI
secret scanning
IAM
políticas de banco
```

## 8. Projetar a estrutura proposta

A estrutura padrão é:

```text
CLAUDE.md
.claude/
  rules/
    <regras-específicas>.md
docs/
  runbooks/
    <procedimentos>.md
```

Criar apenas arquivos necessários.

Exemplos possíveis:

```text
.claude/rules/python.md
.claude/rules/tests.md
.claude/rules/airflow.md
.claude/rules/dbt.md
.claude/rules/terraform.md
.claude/rules/api.md
.claude/rules/raw-iceberg.md
```

Não criar arquivos vazios ou genéricos.

## 9. Regras para o `CLAUDE.md` principal

O arquivo principal deve conter, no mínimo:

```markdown
# CLAUDE.md — <nome do projeto>

## Objetivo

## Princípios de trabalho
### Pensar antes de alterar
### Priorizar simplicidade
### Fazer mudanças cirúrgicas
### Trabalhar com resultados verificáveis

## Fluxo obrigatório

## Evidência e diagnóstico

## Segurança e limites de autorização

## Verificação

## Contexto arquitetural essencial

## Conhecimento compartilhado

## Regras específicas por área

## Git e PR

## Critérios de conclusão
```

Os quatro princípios comportamentais são obrigatórios e devem aparecer explicitamente no `CLAUDE.md`.

Não basta distribuir suas ideias em outras seções. A seção deve permitir que uma pessoa identifique claramente os quatro pilares ao ler o arquivo.


## 10. Regras condicionais

Arquivos em `.claude/rules/` devem conter frontmatter quando forem específicos por caminho:

```yaml
---
paths:
  - "data/dags/**/*.py"
  - "data/include/utils/**/*.py"
---
```

Cada regra deve:

* ter um único tema
* aplicar-se apenas aos caminhos necessários
* indicar fontes arquiteturais relevantes
* incluir validação mínima
* evitar repetir o `CLAUDE.md` principal

## 11. Produzir diagnóstico

Antes de alterar arquivos, apresentar:

```markdown
# Diagnóstico das instruções Claude Code

## Estrutura atual
## Instruções herdadas
## Arquivos gerados automaticamente
## Regras que serão preservadas
## Duplicações encontradas
## Contradições encontradas
## Riscos
## Estrutura proposta
## Arquivos a criar
## Arquivos a alterar
## Arquivos a remover ou arquivar
## Regras movidas e destino
## Controles técnicos recomendados
```

Mostrar também uma tabela de rastreabilidade:

| Regra original       | Origem      | Destino proposto | Ação      |
| -------------------- | ----------- | ---------------- | --------- |
| Consultar wiki       | `CLAUDE.md` | `CLAUDE.md`      | Preservar |
| Cutover Iceberg      | `CLAUDE.md` | runbook          | Mover     |
| Testes dbt           | `CLAUDE.md` | regra dbt        | Mover     |
| Proteção de segredos | `CLAUDE.md` | `CLAUDE.md`      | Preservar |

Nenhuma regra obrigatória pode desaparecer sem aparecer nessa tabela.

## 12. Pedir aprovação

Apresentar:

> "Diagnóstico concluído. A proposta altera `<arquivos>`, cria `<arquivos>` e preserva as políticas listadas na matriz de rastreabilidade. Posso aplicar essa estrutura?"

Esperar aprovação explícita.

Não interpretar silêncio ou pedido de explicação como aprovação.

## 13. Detectar autor

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

## 14. Salvar relatório

Path:

```text
.gtsi/reviews/<author-slug>/<YYYY-MM-DD>-claude-instructions-review.md
```

Frontmatter:

```yaml
---
author: <author-slug>
date: <YYYY-MM-DD>
type: claude-instructions-review
branch: <branch atual>
status: proposed
---
```

O relatório deve conter:

* diagnóstico
* inventário de instruções
* matriz de rastreabilidade
* estrutura proposta
* riscos
* aprovação recebida
* validações realizadas

## 15. Aplicar mudanças

Após aprovação:

1. criar backup lógico no relatório, não arquivo `.backup` versionado
2. criar diretórios necessários
3. atualizar o `CLAUDE.md`
4. criar ou atualizar `.claude/rules/`
5. mover procedimentos para runbooks
6. atualizar template fonte, quando estiver no mesmo repositório
7. não apagar documentação antiga antes de confirmar que não há referências
8. preservar mudanças preexistentes do usuário

Não criar commit, push ou PR sem solicitação explícita.

## 16. Validação obrigatória

Executar:

```bash
git diff --check
git status --short
git diff -- CLAUDE.md .claude docs
```

Validar:

* todos os arquivos referenciados existem
* todos os caminhos do frontmatter são plausíveis
* não há regra obrigatória perdida
* não há comandos destrutivos no contexto permanente
* não há segredos
* não há placeholders
* não há duplicações relevantes
* não há referências para ADRs inexistentes
* não há regras tecnológicas sem tecnologia correspondente
* arquivos gerados foram alterados na fonte correta
* regras de subdiretório não contradizem regras globais

Quando possível, orientar o usuário a executar no Claude Code:

```text
/memory
```

E testar:

```text
Sem alterar arquivos, resuma:
1. quais operações exigem autorização;
2. como investigar bugs;
3. quais regras se aplicam ao arquivo atual;
4. quais fontes de conhecimento devem ser consultadas.
```
### Validação do baseline comportamental

Confirmar que o `CLAUDE.md` final contém, explicitamente, os quatro pilares:

* pensar antes de alterar;
* priorizar simplicidade;
* fazer mudanças cirúrgicas;
* trabalhar com resultados verificáveis.

Executar uma verificação textual equivalente a:

```bash
grep -niE \
  'pensar antes|priorizar simplicidade|mudanças cirúrgicas|resultados verificáveis' \
  CLAUDE.md
```

A validação falha quando:

* algum pilar não está presente;
* os princípios existem somente em `.claude/rules/`;
* os princípios aparecem apenas no relatório;
* foram reduzidos a uma frase genérica sem regras operacionais;
* a reorganização enfraqueceu seu significado.

A skill não deve declarar a arquitetura concluída enquanto essa validação falhar.


## 17. Self-review

Antes de concluir, verificar:

* alguma regra original desapareceu?
* alguma regra foi enfraquecida?
* alguma política virou apenas comentário?
* alguma informação volátil foi copiada?
* algum comando destrutivo permaneceu no `CLAUDE.md`?
* alguma regra específica deveria estar em `.claude/rules/`?
* algum conteúdo pertence a ADR, wiki ou runbook?
* o template fonte foi identificado?
* o diff está limitado às instruções?
* a proposta funciona para este projeto específico?
* os quatro princípios comportamentais obrigatórios aparecem explicitamente no `CLAUDE.md`?
* cada princípio possui instruções operacionais, e não apenas um título?
* alguma regra específica do projeto contradiz simplicidade ou mudanças cirúrgicas?

Corrigir inline antes de apresentar o resultado.

## 18. Entrega

Responder com:

```markdown
## Estrutura aplicada

<árvore de arquivos>

## Arquivos alterados

- `<arquivo>` — <mudança>

## Regras preservadas

- <regra>

## Regras movidas

- <origem> → <destino>

## Validações

- <comando>: passou/falhou/não executado

## Riscos ou pendências

- <item>

## Próximo passo recomendado

<uma ação concreta>
```

---

# Regras especiais

## Wiki de conhecimento

Quando existir esta regra ou equivalente:

```markdown
Antes de responder sobre conector, padronização, gotcha ou decisão de
governança, consulte primeiro `wiki-conhecimento/index.md`.
```

Preservá-la como regra transversal no `CLAUDE.md`.

Pode aprimorar para incluir alterações de código e conflitos entre fontes, mas não deve mudar seu propósito.

## Projetos SIAN

Aplicar regras SIAN somente quando houver evidência de que o projeto pertence à Plataforma de Dados SIAN.

Verificar:

* factories
* Airflow
* dbt
* BigQuery
* Apache Iceberg
* ADRs SIAN
* `wiki-conhecimento`
* projetos `gcp-sian-*`

Não aplicar essas regras a projetos genéricos.

## Arquivos organizacionais

Quando o projeto recebe `CLAUDE.md` de uma automação organizacional:

* atualizar o template fonte
* preservar mecanismo de distribuição
* evitar customização local que será sobrescrita
* separar regras globais das regras específicas do projeto
* informar o impacto nos projetos consumidores

## Operações destrutivas

Comandos como:

```text
rm -rf
git reset --hard
git clean -fd
git push --force
bq rm
DROP TABLE
TRUNCATE TABLE
gsutil rm
```

não devem ficar como instruções executáveis no `CLAUDE.md`.

Quando necessários, devem ficar em runbook com:

* pré-condições
* aprovação
* backup
* rollback
* validação
* pós-condições

---

# Não faça

* Não gerar um `CLAUDE.md` genérico sem analisar o repositório.
* Não copiar o mesmo template para todos os projetos.
* Não apagar regras existentes para reduzir linhas.
* Não confundir popularidade de um prompt com eficácia comprovada.
* Não copiar cegamente o `CLAUDE.md` inspirado no Karpathy.
* Não transformar documentação extensa em contexto permanente.
* Não carregar toda a wiki em cada sessão.
* Não criar dezenas de arquivos `.claude/rules/`.
* Não alterar aplicação, infraestrutura ou dados.
* Não aplicar antes da aprovação.
* Não criar commit ou PR sem solicitação.
* Não declarar segurança garantida apenas por instruções textuais.
* Não deixar referências quebradas.
* Não esconder conflitos entre código, wiki, ADR e template.

## Exemplos de gatilho

* "melhore o CLAUDE.md deste projeto"
* "adapte o arquivo do Karpathy ao meu repositório"
* "separe as regras de Airflow e dbt"
* "crie um padrão de CLAUDE.md para meus projetos"
* "revise se minhas instruções estão muito grandes"
* "minha automação sobrescreve o CLAUDE.md"
* "organize CLAUDE.md, rules e runbooks"
