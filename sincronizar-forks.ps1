# Traz para os forks pessoais o que foi mergeado no repositorio do Joao (inclusive PRs de outras pessoas).
# Rodar no ritual de sexta-feira.
$eu = 'andersonluizpereiradias'
gh repo list $eu --fork --limit 100 --json name --jq '.[].name' | Where-Object { $_ -like 'FIAPCloudGames*' } | ForEach-Object {
    gh repo sync "$eu/$_" 2>&1 | Select-Object -Last 1
}
