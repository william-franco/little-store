# Little Store Backend

Backend para o projeto Little Store: API .NET com autenticação JWT + refresh token, catálogo de produtos, carrinho, pedidos e favoritos (SQLite + EF Core).

Execução local com `dotnet run` ou em container via **Kiri** (seção [Run with Kiri (Docker)](#run-with-kiri-docker) abaixo).

## Libraries

```
dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 10.0.0
dotnet add package Microsoft.EntityFrameworkCore.Design --version 10.0.0
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 10.0.0
dotnet add package Microsoft.IdentityModel.Tokens --version 8.7.0
dotnet add package System.IdentityModel.Tokens.Jwt --version 8.7.0
dotnet add package BCrypt.Net-Next --version 4.0.3
dotnet add package Scalar.AspNetCore --version 2.*
```


## Migrations

```
dotnet tool install --global dotnet-ef --version 10.*
or
dotnet tool update --global dotnet-ef --version 10.*
dotnet ef migrations add InitialCreate
dotnet ef database update
```


## Run Project

```
dotnet build
dotnet run
```

## Integration tests (E2E)

Testes de integração da API (xUnit + `WebApplicationFactory`, SQLite temporário):

```
cd LittleStoreBackend.IntegrationTests
dotnet test --configuration Release
```

No monorepo `flutter-apps`: `./flutter-backend-e2e.sh test little-store` (só .NET) ou `./flutter-backend-e2e.sh smoke little-store` (container + HTTP).

## Run with Kiri (Docker)

Com o [Kiri](https://kiri.dev) ativo (no Linux: `sudo kiri daemon` ou app aberto), na pasta deste backend:

```
kiri compose build
kiri compose up -d
```

Ou a partir da raiz do monorepo `flutter-apps`: `./flutter-backend-kiri.sh up little-store`.

O SQLite persiste no volume Docker; ambiente `Development` (Scalar/OpenAPI habilitados). Portas no host permanecem as mesmas abaixo.

Para encerrar: `kiri compose down` ou `./flutter-backend-kiri.sh down little-store`.

Opcional: `Jwt__Key` e demais chaves podem ser sobrescritas via `environment` no `compose.yaml`.

## Accessing

API: http://localhost:5064/api/v1 · OpenAPI: http://localhost:5064/openapi/v1.json · Scalar: http://localhost:5064/scalar


## Examples of commits

```
git add . && git commit -m ":rocket: Initial commit." && git push
git add . && git commit -m ":building_construction: Added initial project architecture." && git push
git add . && git commit -m ":building_construction: Update project architecture." && git push
git add . && git commit -m ":memo: Updated project documentation." && git push
git add . && git commit -m ":memo: Updated code documentation." && git push
git add . && git commit -m ":white_check_mark: Added feature xyz." && git push
git add . && git commit -m ":wrench: Fixed xyz usage." && git push
git add . && git commit -m ":heavy_minus_sign: Removed xyz." && git push
git add . && git commit -m ":memo: Adjusted project imports." && git push
git add . && git commit -m ":arrow_up: Updated dependencies." && git push
git add . && git commit -m ":arrow_down: Removed dependencies." && git push
git add . && git commit -m ":wastebasket: Removed unused code." && git push
```

## License

[MIT License](https://opensource.org/licenses/MIT)

Copyright (c) 2026 William Franco.

