# Instalação completa (instância nova)

Este é o **guia mestre**. Uma pessoa com VPS, domínio e acesso ao GitHub deve conseguir subir a plataforma **sem consultar a instalação Reino Sinergia**.

- SQL inicial: [`database/install.sql`](../database/install.sql)
- Checklist: [`CHECKLIST_POS_INSTALACAO.md`](CHECKLIST_POS_INSTALACAO.md)
- Relatório de checkup: [`../RELATÓRIO_CHECKUP_PROJETO.md`](../RELATÓRIO_CHECKUP_PROJETO.md)

Documentos em `docs/deploy/`, `INSTALL.md` (raiz) e `Base_de_Dados_Instalacao.sql` são **legado**. Não os use como fonte primária.

Não altere a instalação em produção (reino.sinergia.club) com este guia.

---

## 1. Pré-requisitos

### VPS e painel

- VPS Linux (Ubuntu 22.04 LTS ou equivalente).
- Painel **EasyPanel** (ou Apache/PHP equivalente).
- Domínio apontando para o IP da VPS (registro A).
- Git e conta GitHub com o repositório da plataforma.

### PHP e Apache

O `docker/Dockerfile` da aplicação usa **PHP 8.2 + Apache**. Recomendado na VPS:

| Item | Valor |
|------|--------|
| PHP | **8.2** (mínimo prático: 8.1; `composer.json` declara `>=7.4`, mas Stripe PHP 19 e Web Push exigem stack moderna) |
| Apache | `mod_rewrite` ativo; `AllowOverride All` no DocumentRoot |
| Document root | **raiz do projeto** (onde estão `index.php`, `checkout.php`, `.htaccess`) |

Extensões PHP usadas de fato:

- `pdo`, `pdo_mysql`, `mbstring`, `json`, `openssl`
- `curl` (SDK Stripe / HTTP)
- `zip`, `exif` (imagem Docker)
- `gd` ou equivalente se o painel gerar imagens (não está no Dockerfile; não é bloqueador do core)

### Banco

- **MariaDB 10.6+** ou **MySQL 8**.
- Charset **utf8mb4**.
- Um banco **vazio** (nome livre — o instalador **não** faz `USE checkout`).

### Composer

Na raiz do projeto:

```bash
composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
```

Dependências (`composer.json`): `minishlink/web-push`, `stripe/stripe-php`.  
`PHPMailer/` na raiz é vendored (não vem do Composer). Não apague.

Se a pasta `vendor/` não existir após o clone, a aplicação quebra (autoloader Stripe/Web Push).

### Git

Clone a **branch** acordada (em geral `main`). Não copie uploads, `.env` nem dumps da instalação Reino.

---

## 2. Criar o projeto no EasyPanel

Passos que a plataforma realmente precisa (não inventar serviços extras):

1. No EasyPanel, crie um **App** (serviço de aplicação).
2. Tipo de build: **Dockerfile** com arquivo `docker/Dockerfile`, contexto = **raiz do repositório**.
3. A imagem já instala Composer, habilita `mod_rewrite` e define DocumentRoot na raiz.
4. Crie um **serviço de banco** separado (MySQL/MariaDB do EasyPanel). **Não** use `docker/Dockerfile.db`: esse arquivo está duplicado da imagem PHP e **não** sobe MariaDB.
5. **Não** use `docker-compose.yml` como blueprint de produção (senhas de exemplo no Compose; serviço `db` apontando para o Dockerfile errado).
6. Porta interna da app: **80** (o EasyPanel mapeia o domínio).
7. Volume persistente: monte um volume em `/var/www/html/uploads` (uploads de usuários, certificados Efí `.p12`, mídia). O entrypoint cria `uploads/config` e ajusta dono/permissões (`www-data`, `775`) na subida — necessário para o upload de logo em Configurações.
8. Após o primeiro deploy, o banco ainda está vazio — importe `database/install.sql` (seção 4).

Não há health check HTTP definido na imagem da aplicação. O Compose local só tem healthcheck no serviço de banco (e esse serviço Compose não é confiável).

Restart: use a política padrão do EasyPanel (reiniciar o app após deploy).

---

## 3. GitHub

1. Crie o repositório **novo** (esta etapa não cria o GitHub por você).
2. Confirme que `.gitignore` está no commit inicial (`.env`, `uploads/**`, `vendor/`, logs, dumps).
3. No EasyPanel, conecte o repositório: source GitHub, **branch** de produção, deploy automático opcional.
4. Após o clone no servidor, rode `composer install` se o build **não** usar o `docker/Dockerfile` (o Dockerfile já roda Composer).

Arquivos que **não** devem ir para o GitHub novo: `.env`, logs `*_log.txt`, conteúdo de `uploads/`, dumps SQL com dados reais, certificados `.p12`/`.pem`.

---

## 4. Banco

1. Crie um banco vazio, charset `utf8mb4`, collation `utf8mb4_unicode_ci` (ou `utf8mb4_general_ci` — o dump mistura as duas; ambas funcionam).
2. Crie um usuário com permissão total **somente** nesse banco.
3. No phpMyAdmin ou CLI, **selecione o banco**.
4. Importe **somente**:

```text
database/install.sql
```

5. Confirme tabelas (**54** `CREATE TABLE`) e seeds: `communities`, `banner_badges`, `configuracoes`, `configuracoes_sistema`, `saas_planos`, `plugins`, 1 linha em `usuarios`.

Validação deste instalador no checkup de portabilidade: **estática** (cruzamento com o PHP). Não foi importado em banco local nesta máquina. Antes do go-live de sinergia.club, importe uma vez num banco **vazio descartável** (nunca no Reino) para confirmar zero erros de SQL.

**Não execute** a pasta `migrations/` em instalação nova.

**Não execute** este SQL em um banco que já tem dados.

Instalações antigas: use `migrations/` conforme [`migrations/README.md`](../migrations/README.md).

---

## 5. Configuração

Na raiz, copie `.env.example` para `.env` (o arquivo `.env` **não** é versionado).

| Variável | Obrigatória | Função |
|----------|-------------|--------|
| `DB_HOST` | Sim | Host do MySQL (no EasyPanel, o hostname interno do serviço de banco) |
| `DB_USER` | Sim | Usuário do banco |
| `DB_PASS` | Sim | Senha do banco |
| `DB_NAME` | Sim | Nome do banco |
| `APP_TIMEZONE` | Recomendado | Ex.: `America/Sao_Paulo` |
| `GATEWAYPRO_MASTER_SECRET` | **Sim no primeiro acesso** | Lido em `helpers/master_helper.php` via `getenv`. Sem chave de licença no banco (`license_key` vazio), o login admin/infoprodutor redireciona para `/ativacao` — **exceto** se este valor estiver preenchido (bypass de instalação nova). Use um segredo longo e aleatório. Não commitar `.env`. |
| `LICENSE_WEBHOOK_URL` | Só se for ativar licença remota | URL do webhook de validação (`helpers/license_helper.php`). Vazio no exemplo. |
| `LICENSE_WEBHOOK_USER` | Só se for ativar licença remota | Usuário HTTP Basic do webhook. |
| `LICENSE_WEBHOOK_PASS` | Só se for ativar licença remota | Senha HTTP Basic do webhook. Não coloque valor real no `.env.example`. |
| `TOKEN_AUTH_SECRET` | Opcional | APIs que usam token |
| `APP_DEBUG` | Não | Deixe desligado em produção |

Gateways (Efí, Stripe, Mercado Pago, etc.) **não** ficam no `.env`. São gravados por vendedor em `usuarios` via painel **Integrações**.

SMTP **não** fica no `.env`. Fica na tabela `configuracoes` (Admin → configurações de e-mail). O instalador deixa SMTP **vazio**.

Fallbacks em `config/config.php` (usuário/senha padrão se `.env` faltar) existem só para não quebrar o parse. **Sempre** use `.env` em produção.

---

## 6. Domínio, DNS e SSL

1. DNS: registro **A** do domínio (ex.: `sinergia.club`) para o IP da VPS.
2. No EasyPanel, associe o domínio ao App.
3. Ative HTTPS (Let's Encrypt no EasyPanel, ou proxy Cloudflare com SSL).
4. Checkout, webhooks e PWA usam `HTTP_HOST` em runtime — não é preciso editar PHP para trocar de `reino.sinergia.club` para `sinergia.club`.
5. Se usar Cloudflare, o SSL deve chegar até a origem (Full). Webhooks de gateways precisam alcançar `https://SEU_DOMINIO/notification`.

---

## 7. Permissões

Diretório gravável pelo PHP (`www-data` na imagem Docker):

```text
uploads/
```

Inclui subpastas criadas em runtime (`aula_files`, `certificados`, logos, etc.). O `.gitignore` versiona só `uploads/.gitkeep`.

A pasta `config/` não precisa ser gravável; o Apache bloqueia acesso HTTP via `config/.htaccess` e regras no `.htaccess` da raiz.

---

## 8. Primeiro administrador

O `database/install.sql` insere:

- E-mail/login: `admin@example.com`
- Senha inicial: a palavra **`password`** (hash bcrypt de demonstração, o mesmo usado em exemplos Laravel)
- Tipo: `admin`

Procedimento seguro:

1. Defina `GATEWAYPRO_MASTER_SECRET` no `.env` **antes** do primeiro login (senão `/login` manda para `/ativacao`).
2. Acesse `https://SEU_DOMINIO/login`.
3. Entre com o admin seed.
4. **Troque a senha imediatamente** no perfil/admin.
5. Opcional: altere o e-mail `admin@example.com`.
6. Para não usar a senha de demonstração, gere um hash local e substitua o `INSERT` **antes** de importar:

```bash
php -r "echo password_hash('SUA_SENHA_FORTE', PASSWORD_DEFAULT), PHP_EOL;"
```

Não commite senhas reais. Não deixe `password` em produção.

Para a instalação interna (sinergia.club) este seed pode ser usado **temporariamente**.  
Para distribuição futura a alunos/clientes: é **pendência de produto** — a senha padrão conhecida não deve permanecer esquecida; exigir troca no primeiro acesso (não há mecanismo automático nesta versão). Não foi criado wizard de instalação.

Não há assistente de instalação web. Não há usuário hardcoded no PHP.

---

## 9. E-mail

1. No admin, configure SMTP (`smtp_host`, `smtp_port`, `smtp_username`, `smtp_password`, `smtp_from_email`, `smtp_from_name`, `smtp_encryption`).
2. `member_area_login_url` no seed é `/member_login` (relativo). Ajuste se a área de membros usar outro host.
3. O template HTML de entrega vem no seed (placeholders `{CLIENT_NAME}`, `{PRODUCT_NAME}`, etc.). Pode ser editado no painel.
4. Sem SMTP, cadastro/recuperação/entrega por e-mail falham — a UI e o checkout continuam.

---

## 10. Gateways

Configure **no painel do vendedor** (Integrações), não no Git:

- Mercado Pago, Efí (Pix/cartão + certificado `.p12` em `uploads/certificados/`), Stripe, Pagar.me, PayPal, Beehive, Hypercash, PushinPay, Evolution.

Não coloque secrets no repositório.

Marque testes de pagamento como **“validar após configuração”**.

---

## 11. Webhooks

URLs públicas (o `.htaccess` mapeia para os `.php` na raiz):

| Uso | URL |
|-----|-----|
| Notificações de gateway (principal) | `https://SEU_DOMINIO/notification` |
| Processamento de pagamento (POST do checkout / alguns gateways) | `https://SEU_DOMINIO/process_payment` |
| Consulta de status | `https://SEU_DOMINIO/check_status` |

Stripe: o secret de webhook é **por vendedor** (`usuarios.stripe_webhook_secret`), configurado no painel. No Dashboard Stripe, o endpoint deve ser `https://SEU_DOMINIO/notification`.

Não use `api/process_payment.php` como URL de produção (arquivo legado, sem o mesmo fluxo da raiz).

---

## 12. Cron jobs

Não há `cron*.php` obrigatório para o core (checkout, membros, produtos).

A observação de recuperação de checkout (`checkout_recovery_observe`) nasce **desligada** (0). Não configure fila/WhatsApp até haver autorização de produto.

Operação recomendada (fora da aplicação): backup periódico do banco e do volume `uploads/`.

---

## 13. PWA

- Manifest dinâmico: `/pwa/manifest.php` (e `manifest.json` estático na raiz, com ícones de fallback).
- Service worker: `/pwa/sw.js`.
- Tabelas: `pwa_config`, `pwa_push_subscriptions`, `pwa_push_notifications` (vazias no seed).
- Flag `pwa_activated` nasce `0`. Ative no admin e gere chaves VAPID no painel se for usar push.
- HTTPS é necessário fora de localhost.

---

## 14. Testes pós-instalação

Siga [`CHECKLIST_POS_INSTALACAO.md`](CHECKLIST_POS_INSTALACAO.md).

---

## 15. Troubleshooting

| Sintoma | Causa típica |
|---------|----------------|
| “Não foi possível conectar ao banco” | `.env` ausente ou `DB_*` errado (hostname EasyPanel ≠ `localhost`) |
| Login admin vai para `/ativacao` | `GATEWAYPRO_MASTER_SECRET` vazio e `license_key` vazio no banco |
| `/ativacao` não valida chave remota | `LICENSE_WEBHOOK_URL` / user / pass vazios no `.env` |
| 404 em `/checkout` ou `/notification` | Apache sem `mod_rewrite` / `AllowOverride` |
| Logo quebrada / marca antiga | Fallback hardcoded para CDN Vitrine Academy no PHP (não é o SQL). Envie logo no admin (`logo_url`) |
| Stripe/Web Push fatal error | `composer install` não rodou / sem `vendor/` |
| Upload falha | `uploads/` não gravável ou volume EasyPanel não montado |
| E-mail não sai | SMTP ainda vazio em `configuracoes` |
| `docker compose up` no banco falha | `Dockerfile.db` não é imagem MariaDB — use MySQL do EasyPanel + `install.sql` |

---

## EasyPanel — resumo do que a app precisa

| Item | Valor real no projeto |
|------|------------------------|
| Source | GitHub, branch de produção |
| Build | `docker/Dockerfile`, contexto raiz |
| Porta | 80 |
| Volume | `/var/www/html/uploads` |
| Banco | Serviço MySQL/MariaDB **separado** |
| Variáveis | `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`, `APP_TIMEZONE`, `GATEWAYPRO_MASTER_SECRET`. Se a instância for validar licença remota: `LICENSE_WEBHOOK_URL`, `LICENSE_WEBHOOK_USER`, `LICENSE_WEBHOOK_PASS` (vazios no exemplo; preencher só no `.env`/painel EasyPanel). |
| Build EasyPanel | Dockerfile `docker/Dockerfile`: `composer install --no-dev` no build; entrypoint refaz Composer se `vendor/` faltar. Sem Docker: após o clone, o mesmo comando na raiz. |
| `vendor/` no Git | **Não.** Está no `.gitignore`. O clone novo sempre precisa de Composer (imagem ou comando). |
| PHP `curl` | Necessário para Stripe e webhook de licença. A imagem Docker instala `curl` do sistema; confirme a extensão `ext-curl` no PHP do container/VPS (`php -m`). |
| Domínio + HTTPS | Painel EasyPanel |
| Health check app | Não definido no Dockerfile |
| Após o deploy | Importar `database/install.sql` no banco vazio |

---

## Instalação nova vs atualização

| | Nova | Existente |
|--|------|-----------|
| SQL | `database/install.sql` | `migrations/*.sql` pontuais |
| Dados | Só seed estrutural | Dados reais preservados |
