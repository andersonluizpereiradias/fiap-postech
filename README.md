# FIAP Pos-Tech - FIAP Cloud Games

Indice dos repositorios do projeto por fase. Cada pasta e um submodulo apontando para o fork no meu perfil;
o desenvolvimento acontece no repositorio original (colunas da direita), com push replicado para o fork.

```
git clone --recurse-submodules https://github.com/andersonluizpereiradias/fiap-postech.git
```

## Fase 1

| Repositorio | Original |
|---|---|
| [FIAPCloudGames](https://github.com/andersonluizpereiradias/FIAPCloudGames) | [joao-malvetoni-alta-horizon/FIAPCloudGames](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames) |

## Fase 2

| Repositorio | Original |
|---|---|
| [CatalogAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-CatalogAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI) |
| [NotificationsAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-NotificationsAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI) |
| [Orchestration](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-Orchestration) | proprio |
| [PaymentsAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-PaymentsAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI) |
| [UsersAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-UsersAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI) |

## Fase 3

| Repositorio | Original |
|---|---|
| [CatalogAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-CatalogAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-CatalogAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-CatalogAPI) |
| [NotificationsAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-NotificationsAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-NotificationsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-NotificationsAPI) |
| [Orchestration](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-Orchestration-joao) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-Orchestration](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-Orchestration) |
| [Orchestration-anderson](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-Orchestration) | proprio |
| [PaymentsAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-PaymentsAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-PaymentsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-PaymentsAPI) |
| [UsersAPI](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase3-UsersAPI) | [joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-UsersAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase3-UsersAPI) |

## Scripts

- `configurar-remotos.ps1` - `origin` busca do original e envia para original + fork; `gh pr create` mira o original.
- `sincronizar-forks.ps1` - `gh repo sync` em todos os forks (rodar semanalmente).
