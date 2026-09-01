# Checklist pós-instalação

Use depois de importar `database/install.sql`, preencher `.env` e publicar o domínio. Marque cada item.

Ambiente: `https://________________`

## Acesso

- [ ] Login admin (`admin@example.com`) entra no `/admin` (não redireciona para `/ativacao`)
- [ ] Senha do admin alterada
- [ ] Logout e login novamente funcionam
- [ ] Cadastro de vendedor (infoprodutor) pelo admin
- [ ] Login do vendedor no painel

## Catálogo e mídia

- [ ] Cadastro de produto
- [ ] Categoria principal e subcategoria (criar no painel do vendedor)
- [ ] Upload de imagem do produto em `uploads/`
- [ ] Admin → Configurações: enviar logo do sistema (grava em `uploads/config/`)
- [ ] Cupom (criar e aplicar no checkout)

## Checkout e membros

- [ ] Abrir `/checkout?p={hash}` do produto
- [ ] Order Bump (se houver produto ofertado) aparece e soma no total
- [ ] Área de membros: login do aluno após entrega
- [ ] Progresso de aula (se o produto for curso)

## Comunicação e PWA

- [ ] E-mail SMTP: teste de envio (entrega ou recuperação de senha)
- [ ] PWA: HTTPS, manifest, opção de instalar (se `pwa_activated` ligado)
- [ ] Notificações no painel do vendedor após uma venda (quando houver gateway)

## Pagamentos — validar após configuração

Credenciais externas. Não bloqueiam a instalação “seca”.

- [ ] Webhook `https://DOMINIO/notification` acessível (HTTPS)
- [ ] Integração do vendedor salva no painel (Efí / MP / Stripe / outro)
- [ ] Venda teste (Pix ou cartão, conforme gateway)
- [ ] Dashboard vendedor mostra a venda
- [ ] Dashboard admin mostra a venda

## Encerramento

- [ ] Mobile: checkout e área de membros usáveis em viewport estreita
- [ ] Logout admin e vendedor

## Fora deste checklist

Recuperação ativa de checkout (`checkout_recovery_enabled`) permanece desligada no seed. Não testar como requisito de go-live.
