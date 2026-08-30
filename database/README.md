# Banco de dados

## Instalação nova (banco vazio)

Execute **um único arquivo**, no banco vazio já selecionado:

```text
database/install.sql
```

Não execute as migrations históricas. Elas já estão refletidas neste instalador.

Guia completo: [docs/INSTALACAO_COMPLETA.md](../docs/INSTALACAO_COMPLETA.md)

## Atualização de instalação existente

Use os scripts em `migrations/` somente se a instalação já estiver no ar e faltar um incremento específico. Ver [migrations/README.md](../migrations/README.md).

## Arquivos na raiz (legado)

| Arquivo | Status |
|---------|--------|
| `Base_de_Dados_Instalacao.sql` | **LEGADO** — substituído por `database/install.sql`. Não usar em instalações novas. |
| `Base_de_Dados_Limpa_Tabelas_Operacionais.sql` | **LEGADO** — limpeza operacional; não é instalador. |
