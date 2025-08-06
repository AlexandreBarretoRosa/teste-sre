# Script para resolver problema de push - SRE Desafio
# Remove arquivos grandes e faz push

Write-Host "🔧 Resolvendo problema de push..." -ForegroundColor Blue

# 1. Remover bfg.jar do tracking
Write-Host "📁 Removendo bfg.jar do tracking..." -ForegroundColor Yellow
git rm --cached bfg.jar 2>$null

# 2. Remover outros arquivos grandes
Write-Host "🗑️  Removendo outros arquivos grandes..." -ForegroundColor Yellow
git rm --cached "*.jar" 2>$null
git rm --cached "*.war" 2>$null
git rm --cached "*.ear" 2>$null
git rm --cached "*.zip" 2>$null

# 3. Adicionar .gitignore atualizado
Write-Host "📝 Adicionando .gitignore atualizado..." -ForegroundColor Yellow
git add .gitignore

# 4. Fazer commit
Write-Host "💾 Fazendo commit..." -ForegroundColor Yellow
git commit -m "chore: remove large files and update .gitignore" 2>$null

# 5. Fazer push com retry
Write-Host "🚀 Fazendo push..." -ForegroundColor Yellow
for ($i = 1; $i -le 3; $i++) {
    Write-Host "Tentativa $i/3..." -ForegroundColor Cyan
    if (git push origin teste) {
        Write-Host "✅ Push realizado com sucesso!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "⚠️  Tentativa $i falhou. Aguardando 30 segundos..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
}

Write-Host "❌ Push falhou após 3 tentativas" -ForegroundColor Red
exit 1 