# Configura cada repositorio FIAP do Joao para: buscar do Joao, enviar para Joao + fork pessoal,
# e abrir PR no repositorio do Joao. Idempotente: pode rodar de novo apos clonar algo novo.
$eu   = 'andersonluizpereiradias'
$joao = 'joao-malvetoni-alta-horizon'
$raiz = $PSScriptRoot

Get-ChildItem -LiteralPath $raiz -Recurse -Force -Directory -Filter .git -Depth 3 | ForEach-Object {
    $repo = $_.Parent.FullName
    $url  = git -C $repo remote get-url origin 2>$null
    if ($url -notmatch "github\.com/$joao/([^/]+?)(\.git)?$") { return }
    $nome = $Matches[1]
    $fork = if ($nome -eq 'FIAPCloudGames-fase3-Orchestration') { "$nome-joao" } else { $nome }
    $urlJoao = "https://github.com/$joao/$nome.git"
    $urlFork = "https://github.com/$eu/$fork.git"

    # origin: fetch do Joao; push para os dois
    git -C $repo remote set-url origin $urlJoao
    git -C $repo config --unset-all remote.origin.pushurl 2>$null
    git -C $repo remote set-url --add --push origin $urlJoao
    git -C $repo remote set-url --add --push origin $urlFork
    # remoto 'fork' so para consulta/fetch do seu lado
    if (git -C $repo remote | Select-String -SimpleMatch -Quiet 'fork') { git -C $repo remote set-url fork $urlFork }
    else { git -C $repo remote add fork $urlFork }
    # gh pr create passa a mirar o repositorio do Joao
    Push-Location $repo; gh repo set-default "$joao/$nome" | Out-Null; Pop-Location
    "OK $nome -> push: Joao + $eu/$fork"
}
