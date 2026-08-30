# Relatório final de portabilidade — pré-GitHub

Fechamento dos bloqueadores de distribuição. Sem alteração de checkout, pagamentos, Order Bump, cupons, produtos, membros, PWA, produção, DNS ou EasyPanel de produção. GitHub novo **não** criado. Deploy **não** feito.

---

## Alterações realizadas

| Item | O que mudou |
|------|-------------|
| `helpers/license_helper.php` | URL e Basic Auth do webhook de licença **não** estão mais no código. Leitura via `env()` (`config/env_loader.php`): `LICENSE_WEBHOOK_URL`, `LICENSE_WEBHOOK_USER`, `LICENSE_WEBHOOK_PASS`. Lógica de validate/activate/login **inalterada**. |
| `.env.example` | Placeholders vazios das três variáveis (sem valores reais). |
| `docker-compose.yml` | As mesmas chaves no serviço `app`, vazias. |
| `.gitignore` | Cobre `.env`, `.env.local`, `.env.*`, logs, `uploads/**` (exceto `.gitkeep`), dumps, `vendor/`, caches, chaves `*.pem`/`*.p12`/`*.key`. |
| `docs/INSTALACAO_COMPLETA.md` | Master secret, webhook de licença, admin temporário, Composer/EasyPanel, `vendor/` fora do Git. |
| `docker/Dockerfile` | Extensão `curl`; `composer install` no build; entrypoint refaz Composer se `vendor/` faltar. |

Nenhum arquivo local foi apagado.

---

## Secrets removidos do código

Removidos de `helpers/license_helper.php` (não listar valores):

- URL do webhook de ativação/validação
- Usuário HTTP Basic
- Senha HTTP Basic

Ainda existem **defaults de desenvolvimento** (não são credenciais da instalação Reino): fallback `DB_USER`/`DB_PASS` em `config/config.php` se `.env` faltar. Sempre preencher `.env` em produção.

---

## Variáveis novas no `.env.example`

```
LICENSE_WEBHOOK_URL=
LICENSE_WEBHOOK_USER=
LICENSE_WEBHOOK_PASS=
```

Já existentes e documentadas: `DB_*`, `APP_TIMEZONE`, `TOKEN_AUTH_SECRET`, `GATEWAYPRO_MASTER_SECRET`.

---

## Situação do `.gitignore`

Adequado para um repositório novo. Ignora o que foi pedido. Mantém `uploads/.gitkeep`. Não ignora `database/install.sql` nem `PHPMailer/`.

Logs locais que **não** devem ir para o Git (cobertos por `*.log`):

- `api_errors.log`, `admin_api_errors.log`, `notification_api_errors.log`
- `helpers/utmfy_debug.log`, `views/member/gude-2026-01-31.log`

Dump local (coberto por `uploads/**`): `uploads/aula_files/*.sql`  
Arquivo `.env` local existe nesta pasta — **não** commitar.

---

## Arquivos possivelmente já rastreados

Não foi possível executar `git ls-files` nesta sessão (terminal bloqueado). Esta pasta **não** tem `.git` próprio visível no workspace; o Git pode estar num diretório pai.

Antes do **primeiro push** do repositório **novo**, na pasta que será o root do GitHub, rode e confira o que ainda está no índice:

```bash
git ls-files .env .env.local vendor uploads process_payment_log.txt webhook_log.txt process_free_log.txt "*.log" "*.p12" "*.pem"
```

Se algo sensível aparecer, **não apague o arquivo no disco**. Só tire do tracking:

```bash
git rm --cached -r -- .env .env.local vendor uploads
git rm --cached -- "*.log" "*_log.txt" "*.p12" "*.pem" process_payment_log.txt webhook_log.txt process_free_log.txt
git add uploads/.gitkeep .gitignore
```

Depois `git commit`. O conteúdo local permanece.

---

## Validação de `database/install.sql`

**Tipo:** validação **estática** (não houve MySQL/MariaDB local descartável utilizável nesta máquina).  
**Não** foi usado banco de produção nem o banco do Reino.

| Checagem | Resultado |
|----------|-----------|
| Sem `USE checkout` | OK — serve qualquer nome de banco |
| SMTP seed | Vazio |
| `member_area_login_url` | `/member_login` |
| `usuarios.session_token` | Presente |
| Sem PII / vendas / produtos reais | OK (só seed estrutural) |
| `CREATE TABLE` | **54** |

### Funcionalidades recentes no instalador

| Recurso | No SQL |
|---------|--------|
| Categorias / subcategorias | `product_main_categories`, `product_subcategories`, FKs em `produtos` |
| Order Bump | `order_bumps` |
| Preço especial bump | `produtos.preco_order_bump` |
| Preço USD | `produtos.price_usd` (+ `price_eur`) |
| Checkout | `produtos.checkout_hash`, `checkout_config`, `produto_ofertas` |
| Cupons | `cupons`, `cupom_produtos` |
| Área de membros / progresso | `alunos_acessos`, `aluno_progresso`, `aluno_ultima_aula`, `cursos`, `modulos`, `aulas` |
| PWA / push | `pwa_config`, `pwa_push_subscriptions`, `pwa_push_notifications` |
| Observação de checkout | `checkout_sessions`, `checkout_session_events` |
| Vendedores | `usuarios` (`tipo` admin/infoprodutor) |
| Vendas / notificações / config | `vendas`, `notificacoes`, `configuracoes`, `configuracoes_sistema` |

`nicho_separation.sql` (`nichos`) **não** está no instalador e **não** é usado pelo PHP atual.

Inconsistências menores (não bloqueiam boot): `AUTO_INCREMENT` altos herdados do dump (tabelas vazias); `pwa_config.id` ganha `AUTO_INCREMENT` no `ALTER` posterior (estilo phpMyAdmin).

---

## Primeiro admin

Seed temporário: `admin@example.com` / palavra `password` (hash de demonstração).

- Instalação interna sinergia.club: pode usar **e trocar na hora**.
- Distribuição a clientes: **pendência de produto** — senha conhecida; não há troca forçada no primeiro login; não foi criado wizard.

Documentado em `docs/INSTALACAO_COMPLETA.md` §8.

---

## `GATEWAYPRO_MASTER_SECRET`

| | |
|--|--|
| Onde é lido | `helpers/master_helper.php` → `getenv('GATEWAYPRO_MASTER_SECRET')` (o `env_loader` faz `putenv` ao carregar `.env`) |
| `.env.example` | Sim, vazio, com comentário |
| Sem valor + `license_key` vazio | `checkLicenseOnLogin()` falha → `login.php` redireciona para `/ativacao` |
| Instalação nova | Gerar um segredo longo **novo** no `.env`/EasyPanel. Não copiar valor de outra instância. Não commitar. |

---

## Composer / build

Clone novo:

```bash
composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
```

Dependências: `minishlink/web-push`, `stripe/stripe-php`. `PHPMailer/` continua versionado.

Extensões: `pdo`, `pdo_mysql`, `mbstring`, `json`, `openssl`, `curl`, `zip`, `exif`.

Permissão gravável: `uploads/`.

`vendor/` **não** vai para o Git (`.gitignore`).

EasyPanel: build `docker/Dockerfile` (contexto = raiz). O Dockerfile já roda Composer; o entrypoint refaz se `vendor/autoload.php` não existir. Banco = serviço MySQL separado + import de `database/install.sql`. **Não** usar `docker/Dockerfile.db`.

---

## Teste final de portabilidade

**Pergunta:** GitHub novo + VPS limpa + banco vazio + `docs/INSTALACAO_COMPLETA.md` — ainda é obrigatório algum segredo, arquivo ou conhecimento da instalação Reino?

**Não.** Não é preciso copiar `.env`, uploads, dumps, SMTP, chaves de gateway nem o webhook de licença da instalação antiga.

O que **é** obrigatório (gerado/obtido na instância nova, não “trazido do Reino”):

1. `DB_*` do banco EasyPanel desta VPS
2. `GATEWAYPRO_MASTER_SECRET` **novo**
3. SMTP e gateways se for testar e-mail/pagamento
4. `LICENSE_WEBHOOK_*` **só** se for validar chave remota (senão o master secret basta para o primeiro admin)

Conhecimento operacional do painel (hostname interno do MySQL no EasyPanel) não é da instalação Reino.

---

## Pendências restantes (não bloqueiam o GitHub limpo)

- Confirmar `git ls-files` no momento de criar o repo (comandos acima)
- Importar `install.sql` num banco vazio descartável antes do go-live
- Trocar senha do admin seed
- Pendência de produto: senha padrão sem forçar troca (distribuição a alunos)
- Logos fallback Vitrine Academy no PHP (marca; não impede boot)
- `Dockerfile.db` inválido (já documentado: não usar)
- Defaults `DB_*` em `config/config.php` se alguém subir sem `.env`

---

## Status final

🟢 LIBERADO PARA NOVO GITHUB
