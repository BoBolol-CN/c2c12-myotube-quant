$ErrorActionPreference = 'Stop'
Write-Host 'Install this skill for Claude Code and Codex using Skills CLI (Node.js 22.20+ required).'
npx skills add https://raw.githubusercontent.com/BoBolol-CN/c2c12-myotube-quant/main/c2c12-myotube-quant.zip -g -a claude-code codex --copy
if ($LASTEXITCODE -ne 0) { throw 'Skills CLI installation failed. See README for ZIP/manual installation.' }
