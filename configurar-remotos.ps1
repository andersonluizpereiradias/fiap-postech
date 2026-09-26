# Faz o `gh pr create` de cada API mirar o repositorio original.
# Rode de novo depois de clonar uma API nova aqui dentro.
Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -Force -Filter .git -Depth 3 | ForEach-Object {
    $repo = $_.Parent.FullName
    $url  = git -C $repo remote get-url origin 2>$null
    if ($url -match 'github\.com/([^/]+/[^/]+?)(\.git)?$') {
        Push-Location $repo; gh repo set-default $Matches[1] | Out-Null; Pop-Location
        "OK $($Matches[1])"
    }
}
