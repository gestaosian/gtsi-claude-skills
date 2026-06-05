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

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "$USER" || echo "unknown")
AUTHOR_SLUG=$(echo "$AUTHOR" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')
[ -z "$AUTHOR_SLUG" ] && AUTHOR_SLUG="unknown"
```

### 6. Escrever spec

Path: `.gtsi/specs/<author-slug>/<YYYY-MM-DD>-<slug>.md`

Slug derivado do tema central do design (lowercase, hífen, ASCII).

Template:

````markdown
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
````

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
