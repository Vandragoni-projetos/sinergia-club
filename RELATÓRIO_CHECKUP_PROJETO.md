# Relatório de checkup do projeto

Auditoria local para tornar a pasta uma base **portável** (nova instância em sinergia.club, instalação só pela documentação). Nenhuma alteração de regra de negócio. Produção (reino.sinergia.club) **não** foi tocada. GitHub novo **não** foi criado. Deploy **não** foi feito.

Data do checkup: 2026-08-29.

---

## 1. Estrutura

| Área | Situação |
|------|----------|
| Entrada | `index.php`, `login.php`, `admin.php`, `checkout.php`, `obrigado.php` |
| Rotas Apache | `.htaccess`: URLs limpas (`/checkout`, `/obrigado`, `/notification`, `/process_payment`, `/check_status`); bloqueio de `config/`, `helpers/`, `gateways/`, `database/`, `docs/`, `.env` |
| Config | `config/config.php` + `config/env_loader.php` + `.env` |
| Includes | `helpers/`, `views/`, `gateways/` |
| APIs | `api/*.php`; pagamento canônico na **raiz** (`process_payment.php`, `notification.php`) |
| Cron | Nenhum `cron*.php` obrigatório no core |
| Webhooks | `/notification` (gateways); Stripe secret por vendedor |
| Uploads | `uploads/` (volume EasyPanel) |
| PWA | `pwa/manifest.php`, `pwa/sw.js`, `manifest.json` |
| Composer | `composer.json` / `composer.lock`; `PHPMailer/` vendored |
| JS | Inline nas views + `pwa/*.js` |
| Docker | `docker/Dockerfile` (PHP 8.2 Apache) válido; `docker/Dockerfile.db` **inválido** (cópia da imagem PHP) |

Problemas relatados (não corrigidos no PHP de negócio):

- `api/process_payment.php` é legado (sem o mesmo fluxo Stripe da raiz).
- Fallbacks de logo apontam para CDN Vitrine Academy (veja §2).
- `helpers/license_helper.php` contém URL e credenciais de webhook de licença **hardcoded** (veja §3).

---

## 2. Auditoria de domínios

Classificação: **A** dinâmica · **B** intencional · **C** documentação · **D** legado · **E** pode impedir instalação limpa.

| Ocorrência | Onde | Classe |
|------------|------|--------|
| Host em runtime (`HTTP_HOST`) | checkout, webhooks, e-mails, PWA | **A** — o mesmo código serve reino e sinergia.club |
| `https://sinergia.club` | `ativacao.php`, `views/admin/admin_revenda_autorizada.php` | **B** — link de marketing/ativação |
| Comentários `*.sinergia.club` | `helpers/community_helper.php` | **C** |
| `localhost` como default de env/host | `config/config.php`, PWA, e-mails `noreply@` | **A** / fallback |
| Logo `midias.vitrineacademy.com.br` | `config/load_settings.php`, `admin.php`, `certificado_curso.php`, `api/admin_api.php`, `api/generate_legal_page.php`, `views/member/member_area_dashboard.php`, `manifest.json` | **E** — logo 404/marca errada até o admin gravar `logo_url`. **Não substituído** (URLs funcionais deixadas) |
| `core.vitrineacademy.com.br/member_login.php` | estava no SQL seed | **E** — sanitizado para `/member_login` no instalador |
| `reino.sinergia.club`, `prime.sinergia.club`, `hub.sinergia.club` | código PHP/SQL | **não encontrados** |
| IP de VPS | código | **não encontrado** |
| Webhook de licença | `LICENSE_WEBHOOK_*` no `.env` (`helpers/license_helper.php` lê via `env()`) | **A** — sem valores no código; preencher só se for validar licença remota |

Conclusão de portabilidade de URL: **sim**, checkout/webhooks/PWA seguem o domínio da requisição. Exceções: logos de fallback e o sistema de licença.

---

## 3. Segredos (sem valores)

| Segredo | Onde | Classificação |
|---------|------|----------------|
| `DB_*` | `.env` | variável de ambiente |
| Fallback DB user/pass | `config/config.php` | hardcoded (default de parse; não usar em produção) |
| Senhas Docker Compose | `docker-compose.yml` | hardcoded de desenvolvimento |
| SMTP | tabela `configuracoes` | configurável pelo painel; **seed agora vazio** |
| Gateways (Stripe, Efí, MP, etc.) | colunas em `usuarios` | painel Integrações |
| Certificado Efí `.p12` | `uploads/certificados/` | arquivo local |
| `TOKEN_AUTH_SECRET`, `GATEWAYPRO_MASTER_SECRET` | `.env` | variável de ambiente |
| Webhook de licença (URL, user, pass) | `.env` (`LICENSE_WEBHOOK_*`); placeholders em `.env.example` | variável de ambiente |
| Hash do admin seed | `database/install.sql` | hash conhecido da palavra `password` (trocar no 1º acesso) |

O arquivo `Base_de_Dados_Instalacao.sql` na raiz **continha SMTP real**; as credenciais foram **apagadas do arquivo** (substituídas por vazio). Não apagamos o arquivo (legado).

`.env` local não deve ser commitado (agora no `.gitignore`).

---

## 4. `.gitignore`

Não existia. Foi **criado** (não apagamos arquivos locais). Cobre: `.env`, logs, `uploads/**` (exceto `.gitkeep`), `vendor/`, dumps, chaves, caches, IDE.

Bloqueador anterior: dump SQL sob `uploads/aula_files/` e logs na raiz iriam para um GitHub novo.

---

## 5–9. Banco

**Hoje, banco vazio:** **1 arquivo**, nesta ordem:

1. `database/install.sql`

**54** `CREATE TABLE`. Inclui categorias, `preco_order_bump`, `price_usd`/`price_eur`, Order Bump, `checkout_sessions` / `checkout_session_events`, PWA, funil, cupons, `usuarios.session_token`.

**Não inclui:** `nicho_separation.sql` (`nichos` / `produto_categorias`) — não é usado pelas queries PHP atuais. Opcional só para instalações antigas que queiram esse recurso.

**11 migrations históricas** (mantidas):

`checkout_recovery_observe.sql`, `produto_categorias_hierarquia.sql`, `preco_order_bump.sql`, `single_session.sql`, `pwa_tables.sql`, `nicho_separation.sql`, `funnel_tables.sql`, `funnel_offer_theme.sql`, `funnel_events.sql`, `funnel_custom_config.sql`, `checkout_internacional.sql`

Cruzamento PHP × instalador: `session_token` estava faltando no dump antigo; **incluído** em `install.sql`. Flags de recovery nascem em 0. PWA sem linha obrigatória em `pwa_config` (módulo usa defaults).

Seed **não** leva dados da produção Reino (sem vendas, produtos, PII). Communities `club` / `prime` são estruturais (renomeáveis no admin).

---

## 10. Admin inicial

Depende do `INSERT` no SQL (`admin@example.com` + senha de demonstração `password`) **e** de `GATEWAYPRO_MASTER_SECRET` no `.env` para não cair em `/ativacao`.

Recomendação futura (não implementada): wizard de instalação ou gerar o hash fora do Git, sem senha conhecida no repositório.

---

## 11–12. Documentação

Inventário (instalação): `INSTALL.md`, `docs/deploy/*`, `docker/README.md`, `migrations/README.md`, `docs/README.md`, dezenas de docs de feature em `docs/geral`, `docs/funil`, etc.

Duplicados/obsoletos: três guias de deploy + INSTALL apontavam para `Base_de_Dados_Instalacao.sql` e Hostinger. Marcados **LEGADO** com ponteiro para `docs/INSTALACAO_COMPLETA.md`.

Guia mestre criado: `docs/INSTALACAO_COMPLETA.md`.

---

## 16. Preparação para novo GitHub

**NÃO PRONTA** para copiar a pasta inteira sem revisão, por:

1. Credenciais de webhook de licença **no código PHP** (`license_helper.php`).
2. `vendor/` ignorado a partir de agora — o clone novo **exige** `composer install` (ou build Docker).
3. Conteúdo atual de `uploads/` e `.env` locais devem permanecer fora do Git (`.gitignore` cuida do futuro; arquivos **já rastreados** no Git antigo precisam ser conferidos no `git status` na hora do repositório novo).
4. Logo/manifest ainda apontam CDN de terceiros (não bloqueia o boot, degrada a marca).

Não criar o repositório nesta etapa.

---

## 17. Teste mental (VPS vazia + domínio + GitHub)

Percurso só com a documentação mestra:

1. EasyPanel + Dockerfile + MySQL separado — **documentado**.
2. `install.sql` — **documentado**.
3. `.env` + `GATEWAYPRO_MASTER_SECRET` — **era implícito**; agora está explícito (sem isso o admin não entra).
4. SMTP e gateways — **durante a implantação**, não no SQL.
5. `Dockerfile.db` / Compose — armadilha; **documentada**.
6. Conhecimento que ainda não está 100% no papel: hostname interno exato do MySQL no EasyPanel (varia por painel — o instalador não pode fixar).
7. Ativação de licença “de verdade” (chave comprada) vs bypass master — depende do modelo comercial.

---

## Riscos (funcionais, sem correção de código)

- Login admin sem `GATEWAYPRO_MASTER_SECRET` → `/ativacao`.
- Logos fallback Vitrine Academy.
- Stripe: webhook `payment_intent.succeeded` pode não casar `transacao_id` (já auditado; não alterado).
- Cupom valor fixo em checkout USD (já auditado; não alterado).
- Dockerfile da app não instala extensão `curl` explicitamente (Stripe pede `ext-curl`) — validar na imagem EasyPanel.

---

## Status

Ver classificação obrigatória no relatório final no Cursor (mensagem desta conversa).
