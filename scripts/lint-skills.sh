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
