#!/bin/bash

# Script para resolver problema de push - SRE Desafio
# Remove arquivos grandes e faz push

echo "🔧 Resolvendo problema de push..."

# 1. Remover bfg.jar do tracking
echo "📁 Removendo bfg.jar do tracking..."
git rm --cached bfg.jar 2>/dev/null || true

# 2. Remover outros arquivos grandes
echo "🗑️  Removendo outros arquivos grandes..."
git rm --cached *.jar 2>/dev/null || true
git rm --cached *.war 2>/dev/null || true
git rm --cached *.ear 2>/dev/null || true
git rm --cached *.zip 2>/dev/null || true

# 3. Adicionar .gitignore atualizado
echo "📝 Adicionando .gitignore atualizado..."
git add .gitignore

# 4. Fazer commit
echo "💾 Fazendo commit..."
git commit -m "chore: remove large files and update .gitignore" || echo "Nenhuma mudança para commitar"

# 5. Fazer push com retry
echo "🚀 Fazendo push..."
for i in {1..3}; do
    echo "Tentativa $i/3..."
    if git push origin teste; then
        echo "✅ Push realizado com sucesso!"
        exit 0
    else
        echo "⚠️  Tentativa $i falhou. Aguardando 30 segundos..."
        sleep 30
    fi
done

echo "❌ Push falhou após 3 tentativas"
exit 1 