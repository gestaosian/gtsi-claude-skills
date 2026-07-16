# gtsi-claude-skills — diretrizes para sessões Claude Code

Este repositório é o marketplace interno de skills da equipe GTSI/Sian (Grupo HP).
Siga as regras abaixo em qualquer sessão de trabalho aqui — elas existem para
preservar tokens, manter o cache de prompt quente e reduzir alucinações em
trabalhos longos.

## Disciplina de tokens

### Modelo por tipo de tarefa

Default da sessão: **Sonnet** (`claude-sonnet-4-6`). Escale apenas quando a
tarefa pedir, e desça quando der:

- **Opus** (`claude-opus-4-7` ou superior) — arquitetura, design de skill nova,
  brainstorm complexo, review final de PR grande, escolha entre alternativas
  com trade-off real. Use também para o reviewer final em subagent-driven-development.
- **Sonnet** (`claude-sonnet-4-6`) — implementação que requer julgamento,
  integração entre arquivos, debugging, refactor não-trivial, reviewer de spec.
- **Haiku** (`claude-haiku-4-5`) — tarefa mecânica byte-for-byte (escrever
  conteúdo já especificado, lint, validar JSON, rodar comando e reportar).

Em workflows multi-agent, passe `model: 'haiku'` no `agent()` para os passos
mecânicos. Implementadores de SKILL.md que apenas copiam conteúdo do plano
são Haiku; reviewers de spec são Sonnet; reviewers finais e arquitetos são Opus.

### Janela de contexto: 200k, não 1M

A janela de 1M só vale a pena quando você de fato precisa ler todo o histórico
junto. Para o trabalho normal aqui:

- Mantenha o modelo em janela **200k** (default do `/model`).
- Cache de prompt da Anthropic tem TTL de 5min — janelas grandes invalidam o
  cache mais cedo e custam mais por turno.
- Se você sentir que precisa de 1M, primeiro pergunte: posso resumir o
  contexto que já não está sendo usado? Quase sempre dá.

### Sugerir `/compact` proativamente

Avise o usuário quando o contexto começar a pesar, sem esperar ele perceber:

- Ao ultrapassar **~60% da janela** (~120k tokens em 200k), sugira `/compact`
  no fim do turno: "contexto em ~120k, posso compactar agora antes da próxima
  fase?".
- Ao **terminar uma fase de trabalho** (PR aberto, plano concluído,
  investigação fechada): sugira `/compact` mesmo sem ter atingido o limite,
  pois o histórico denso de subagents/tool calls não precisa entrar na
  próxima fase.
- Ao **mudar de assunto** dentro da mesma sessão: sugira `/clear` (não
  `/compact`) — assuntos diferentes não se beneficiam da compactação.

Não compacte sem perguntar. A decisão é do usuário.

## Abordagem socrática para ideias novas

Quando o usuário trouxer uma ideia, proposta ou pedido de algo a construir
(mesmo que pareça simples), **não pule para implementação**. Faça 2-4 perguntas
curtas focadas em escopo e risco antes de produzir código, plano ou artefato.

Perguntas típicas:

- Qual problema isso resolve? (o que dói hoje, para quem)
- O que acontece se não fizer? (custo do não-agir)
- Em que casos isso quebra ou vira ruído? (limites, edge cases)
- Existe algo mais simples que já resolve 80%? (alternativa de menor escopo)

Pule a abordagem socrática quando:

- O pedido já vem concreto e fechado ("substitua X por Y no arquivo Z").
- É correção/bug fix com causa identificada.
- O diálogo já vai ser coberto por `/gtsi-brainstorm`, `/gtsi-analyze` ou `/gtsi-plan`.

Se a ideia for grande ou fuzzy, depois das 2-4 perguntas iniciais sugira
escalar para `/gtsi-brainstorm` — não tente reproduzir o diálogo completo
dentro de uma resposta inline.

## Skill routing

Quando o pedido do usuário casar com uma skill instalada, invoque via tool
`Skill`. Em dúvida, invoque.

Mapeamento principal:

- Brainstorm/ideia fuzzy → `/gtsi-brainstorm`
- Diagnóstico de problema operacional → `/gtsi-analyze`
- Plano executável → `/gtsi-plan`
- Produção de artefatos → `/gtsi-execute`
- Salvar/restaurar contexto → `/gtsi-context-save` ou `/gtsi-context-restore`
- Review de PR/diff → `/gtsi-code-review`
- Review de DAG SIAN → `/sian-dag-review`
- Status report semanal → `/gtsi-status-report`
- DAG SIAN (criar/modificar) → `/sian-dag-factory`
- Pedido de correção de dados → `/sian-data-correction-policy`
- Destino BigQuery → `/sian-data-destination`
- Setup Iceberg → `/sian-iceberg-setup`
- Novo sistema SIAN → `/sian-new-system-checklist`
- Criar, revisar, migrar ou padronizar `CLAUDE.md` e `.claude/rules/`
  → `/gtsi-claude-architect`

## Convenções de artefatos

Artefatos gerados por skills vivem em `.gtsi/<tipo>/<author-slug>/<date>-<slug>.md`:

- `context/` — efêmero, **gitignored**
- `specs/`, `reports/`, `reviews/`, `plans/` — versionados

Autor detectado via `git config user.name` (com fallback). Convenção codificada
em cada skill que grava.
