# Migrations

Há dois fluxos distintos. Não misture.

## Instalação nova (banco vazio)

Execute **somente** [`database/install.sql`](../database/install.sql).  
Guia: [`docs/INSTALACAO_COMPLETA.md`](../docs/INSTALACAO_COMPLETA.md).

Não execute os scripts desta pasta em uma instalação nova: o instalador já representa o schema atual.

## Atualização de instalação existente

Os arquivos `.sql` desta pasta são **histórico incremental**. Use-os só se a instalação já estiver no ar e faltar um incremento específico (ex.: coluna `session_token` em bancos antigos).

`Base_de_Dados_Instalacao.sql` na raiz é **LEGADO** (substituído por `database/install.sql`).

### Scripts incrementais (opcionais)

- **single_session.sql** — Adiciona coluna `session_token` na tabela `usuarios` para permitir apenas uma sessão ativa por usuário (novo login em outro navegador/dispositivo invalida as demais). Execute manualmente se quiser usar esse recurso.

- **nicho_separation.sql** — Separação por nicho (vitrine segmentada). Cria tabelas `nichos`, `categorias`, `produto_categorias` e adiciona `nicho_id` em `produtos` e `usuarios`. Usuários só veem produtos do seu nicho. Execute manualmente para habilitar esse recurso.

- **checkout_internacional.sql** — Checkout BR + Internacional. Adiciona feature flags (payment_routing_enabled, stripe_enabled, paypal_enabled), moedas, price_usd/eur em produtos e tabela payment_decline_logs. Ver docs/geral/PLANO_CHECKOUT_BR_INTERNACIONAL.md.

- **preco_order_bump.sql** — Preço secundário para Order Bump. Adiciona `produtos.preco_order_bump` (`DECIMAL(10,2) NULL`). `NULL` = usar `produtos.preco` no bump. Já incluso em `Base_de_Dados_Instalacao.sql` para instalações novas. Ver [docs/geral/PRECO_ORDER_BUMP.md](../docs/geral/PRECO_ORDER_BUMP.md).

- **produto_categorias_hierarquia.sql** — Categoria Principal + Subcategoria (taxonomia TEMÁTICA adicional, independente de `produtos.product_type`). Cria `product_main_categories`, `product_subcategories` e colunas opcionais `produtos.main_category_id` / `produtos.subcategory_id` (`INT NULL`, sem backfill). Isolamento por `usuario_id`. Não reutiliza `nicho_separation.sql`. Já incluso em `Base_de_Dados_Instalacao.sql` para instalações novas.

- **checkout_recovery_observe.sql** — Fundação de observação de checkout (Etapa 1B.1). Cria `checkout_sessions` e `checkout_session_events` (sem FK para `vendas`). Insere flags `checkout_recovery_observe=0` e `checkout_recovery_enabled=0`. Não cria `recovery_jobs`. Não altera pagamento, checkout, Pix nem UUID de venda. Já incluso em `Base_de_Dados_Instalacao.sql` para instalações novas.
