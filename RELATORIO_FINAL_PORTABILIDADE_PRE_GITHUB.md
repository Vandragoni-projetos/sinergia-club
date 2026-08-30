# Relatório final de portabilidade — pré-GitHub

Fechamento dos bloqueadores de distribuição. Nenhuma regra de negócio (checkout, pagamentos, Order Bump, membros, PWA) foi alterada. Produção e DNS não foram tocados. O repositório GitHub **não** foi criado.

---

## 1. Alterações realizadas

| Arquivo | O quê |
|---------|--------|
| `helpers/license_helper.php` | URL e credenciais do webhook de licença saíram do código. Passam a ser lidas com `env()` (mesmo padrão de `config/env_loader.php`). Defaults vazios. Lógica de validação/ativação/login **inalterada**. |
| `.env.example` | Placeholders `LICENSE_WEBHOOK_URL`, `LICENSE_WEBHOOK_USER`, `LICENSE_WEBHOOK_PASS` (sem valores reais). |
| `.gitignore` | `.env.local` explícito; `tmp/`, `temp/`, `cache/`, `*.tmp`, `*.cache`. |
| `docs/INSTALACAO_COMPLETA.md` | Variáveis de licença, Composer/EasyPanel/`vendor/`, `ext-curl`, primeiro admin e pendência de produto. |
| `docker-compose.yml` | Chaves de licença vazias no serviço `app` (sem valores). |
| `docker/Dockerfile` | `libcurl4-openssl-dev` + `docker-php-ext-install curl` (Stripe e webhook de licença). |

---

## 2. Secrets removidos do código

Removidos de `helpers/license_helper.php` (não listamos valores):

- URL do webhook de ativação
- usuário HTTP Basic
- senha HTTP Basic

Agora: `.env` / variáveis de ambiente do EasyPanel. Sem esses valores, a ativação **remota** falha com o mesmo tipo de erro de conexão/auth de antes; o primeiro acesso via `GATEWAYPRO_MASTER_SECRET` **não** depende deles.

---

## 3. Variáveis novas no `.env.example`

```
LICENSE_WEBHOOK_URL=
LICENSE_WEBHOOK_USER=
LICENSE_WEBHOOK_PASS=
```

Já existiam (sem valor real): `GATEWAYPRO_MASTER_SECRET`, `TOKEN_AUTH_SECRET`, `DB_*`.

---

## 4. Situação do `.gitignore`

Cobre: `.env`, `.env.local`, `.env.*` (exceto `.env.example`), logs, `uploads/**` com exceção de `uploads/.gitkeep`, dumps/backups, `vendor/`, chaves `.pem`/`.p12`/`.key`, caches/temp, override Docker.

Um `git add .` neste diretório **não** deve incluir `.env`, logs nem o dump em `uploads/aula_files/`.

---

## 5. Arquivos locais que existem e não devem ir ao GitHub

Esta pasta **não tem `.git` próprio** (não foi possível `git ls-files` daqui). Há arquivos **no disco** que o `.gitignore` agora exclui:

- `.env`
- `webhook_log.txt`, `process_payment_log.txt`, `process_free_log.txt`
- `api_errors.log`, `admin_api_errors.log`, `notification_api_errors.log`
- `uploads/aula_files/` (dump SQL local)

**Não apagamos** nenhum arquivo local.

Se o novo repositório for criado **a partir de um Git que já rastrea** esses caminhos, **antes do primeiro push**:

```bash
git rm --cached --ignore-unmatch .env .env.local
git rm --cached --ignore-unmatch webhook_log.txt process_payment_log.txt process_free_log.txt
git rm --cached --ignore-unmatch api_errors.log admin_api_errors.log notification_api_errors.log
git rm --cached -r --ignore-unmatch uploads
git add uploads/.gitkeep
git rm --cached -r --ignore-unmatch vendor
```

Depois: `git status` e confirmar que só entram código, `.env.example`, `database/install.sql` e `uploads/.gitkeep`.

---

## 6. Validação de `database/install.sql`

**Não há banco local descartável acessível nesta sessão** (CLI MySQL/MariaDB não pôde ser executada; sandbox/terminal indisponível). **Não** foi usado o banco do Reino nem qualquer produção.

**Validação estática:**

- Sem `USE \`checkout\`` — serve qualquer nome de banco.
- SMTP seed vazio; `member_area_login_url` = `/member_login`.
- `usuarios.session_token` presente.
- DROP inclui PWA, funil, `checkout_sessions`, categorias.
- **54** `CREATE TABLE`.

### Funcionalidades recentes no instalador

| Recurso | Presente |
|---------|----------|
| Categorias / subcategorias | `product_main_categories`, `product_subcategories`, FKs em `produtos` |
| Order Bump | `order_bumps` |
| Preço especial bump | `produtos.preco_order_bump` |
| Preço USD | `produtos.price_usd` (+ `price_eur`) |
| Checkout / ofertas | `produtos`, `produto_ofertas`, `checkout_hash` |
| Cupons | `cupons`, `cupom_produtos` |
| Área de membros / acesso | `alunos_acessos` |
| Progresso | `aluno_progresso`, `aluno_ultima_aula` |
| PWA / push | `pwa_config`, `pwa_push_subscriptions`, `pwa_push_notifications` |
| Observação de checkout | `checkout_sessions`, `checkout_session_events` |
| Vendedores | `usuarios` (tipo infoprodutor/admin) |
| Vendas / notificações | `vendas`, `notificacoes` |
| Configurações | `configuracoes`, `configuracoes_sistema` |

Inconsistências (não bloqueiam o schema):

- `pwa_config` / push: `id` sem AUTO_INCREMENT no `CREATE` (índice/AI vêm nos `ALTER` do dump) — igual ao dump original.
- `nicho_separation` (`nichos`) **não** está no instalador (código PHP atual não usa).
- AUTO_INCREMENT altos herdados do dump phpMyAdmin em tabelas vazias — inofensivo.

**Importação real:** pendência operacional na VPS (banco vazio + phpMyAdmin/mysql).

---

## 7. Primeiro admin

Seed: `admin@example.com` + senha de demonstração `password` (hash bcrypt conhecido).

- Instalação interna sinergia.club: uso **temporário** permitido.
- **Trocar no primeiro acesso** (documentado em `docs/INSTALACAO_COMPLETA.md`).
- Não há senha real de produção no Git.
- **Pendência de produto** (versão distribuível a alunos): não existe troca forçada automática; risco de a senha padrão ser esquecida. Sem wizard novo nesta etapa.

---

## 8. `GATEWAYPRO_MASTER_SECRET`

| | |
|--|--|
| Onde | `helpers/master_helper.php` → `getenv('GATEWAYPRO_MASTER_SECRET')` (o `env_loader` faz `putenv`) |
| `.env.example` | Sim, vazio, com comentário |
| Sem valor + `license_key` vazio | `checkLicenseOnLogin()` falha → `/ativacao` |
| Com valor + `license_key` vazio | `isMasterPanel()` verdadeiro → login admin segue |
| Instalação nova | Definir no `.env` / EasyPanel **antes** do primeiro login. Não gerar valor aqui. |

---

## 9. Composer / build

Clone novo:

```bash
composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
```

- `vendor/` **não** vai para o Git.
- EasyPanel: build `docker/Dockerfile` (já roda Composer; entrypoint refaz se `vendor/` faltar).
- Extensões: `pdo`, `pdo_mysql`, `mbstring`, `json`, `openssl`, `curl`, `zip`, `exif`.
- Gravável: `uploads/` (só `.gitkeep` no Git).
- `PHPMailer/` na raiz **é** versionado (não é Composer).

---

## 10. Teste final de portabilidade

**Pergunta:** ao criar um GitHub novo, clonar numa VPS limpa, criar banco vazio e seguir `docs/INSTALACAO_COMPLETA.md`, ainda é obrigatório algum segredo, arquivo ou conhecimento da instalação Reino?

**Não** — desde que:

1. O commit inicial respeite o `.gitignore` (não copie `.env`, logs nem `uploads/` do Reino).
2. Na VPS se preencham `DB_*` e `GATEWAYPRO_MASTER_SECRET` (valores **novos**, não os do Reino).
3. SMTP e gateways sejam configurados no painel da instância nova.

Opcional (não bloqueia o boot): `LICENSE_WEBHOOK_*` se for usar ativação remota; logo no admin (fallback de CDN de terceiros no PHP permanece, não é segredo).

Conhecimento implícito restante (não é dado do Reino): hostname interno do MySQL no EasyPanel.

---

## Pendências restantes (não bloqueiam o GitHub)

- Importar `install.sql` de verdade na VPS (validação estática apenas).
- Senha admin padrão: pendência de produto para kit de alunos.
- Logos fallback Vitrine Academy no PHP (marca, não secret).
- `Dockerfile.db` / Compose ainda inválidos para banco — já documentado; não usar no deploy EasyPanel.

---

## Status final

**🟢 LIBERADO PARA NOVO GITHUB**

Os secrets de licença não estão mais no código. O `.gitignore` impede o vazamento típico. O instalador cobre o schema das funcionalidades atuais. O que falta é preenchimento de `.env` e import SQL **na VPS nova**, não arquivo da pasta Reino.
