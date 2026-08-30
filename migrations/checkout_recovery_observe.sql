-- Recuperação de carrinho — ETAPA 1B.1
-- Fundação de observação (tabelas + flags DESLIGADAS).
-- Ambiente: LOCAL apenas. Não executar em produção sem autorização explícita.
--
-- Camada PARALELA: não altera vendas, checkout, Pix, cartão, gateways nem UUIDs de pagamento.
-- Sem seed de jornada. Sem endpoint. Sem JavaScript. Sem disparos.
-- Flags nascem em '0'. Ausência da chave também deve ser tratada como desligado no PHP.
--
-- Tipos alinhados ao schema atual:
--   usuarios.id                 int(11) signed
--   produtos.id                 int(11) signed
--   produtos.usuario_id         int(11) signed
--   produtos.community_id       int(11)
--   produto_ofertas.id          int(11) signed
--   vendas.transacao_id         varchar(255)
--   vendas.checkout_session_uuid varchar(255)
--   vendas.comprador_*          varchar(255)/varchar(20)
-- Sem FK para vendas (a observação não controla o pagamento).
--
-- NÃO armazenar: cartão, CVV, QR Pix, copia-e-cola, tokens, credenciais, senhas.
--
-- recovery_jobs: NÃO criada nesta etapa (não é necessária para modo observação).
--
-- Aplicar (local):
--   mysql -u USUARIO -p NOME_DO_BANCO < migrations/checkout_recovery_observe.sql
--
-- Reexecução: CREATE TABLE IF NOT EXISTS é idempotente; INSERT IGNORE das flags (UNIQUE chave).

-- ========== APLICAÇÃO ==========

CREATE TABLE IF NOT EXISTS `checkout_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL COMMENT 'Seller dono do produto (isolamento multi-seller; obrigatório)',
  `produto_id` int(11) NOT NULL COMMENT 'Produto do checkout observado',
  `community_id` int(11) DEFAULT 1 COMMENT 'Comunidade (mesmo padrão de produtos/vendas)',
  `browser_uuid` varchar(64) NOT NULL COMMENT 'UUID de observação no browser (NÃO é vendas.checkout_session_uuid)',
  `venda_session_uuid` varchar(255) DEFAULT NULL COMMENT 'Referência opcional ao UUID 2 de vendas (agrupamento de pagamento); NULL até haver tentativa',
  `transacao_id` varchar(255) DEFAULT NULL COMMENT 'Referência opcional a vendas.transacao_id; não substitui o ID do gateway',
  `oferta_id` int(11) DEFAULT NULL COMMENT 'produto_ofertas.id se o checkout usar oferta; sem FK',
  `cliente_nome` varchar(255) DEFAULT NULL,
  `cliente_email` varchar(255) DEFAULT NULL,
  `cliente_telefone` varchar(20) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL COMMENT 'Método observado (ex.: Pix); não é token de gateway',
  `order_bumps_json` text DEFAULT NULL COMMENT 'IDs de bumps observados (JSON). Sem preços recalculados aqui',
  `coupon_code` varchar(50) DEFAULT NULL COMMENT 'Código observado; não aplica cupom',
  `last_stage` varchar(40) DEFAULT NULL COMMENT 'Último estágio observado (opened, lead, ...)',
  `status` varchar(32) NOT NULL DEFAULT 'open' COMMENT 'open|lead|payment_attempted|converted|abandoned',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_event_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cs_usuario_browser` (`usuario_id`, `browser_uuid`),
  KEY `idx_cs_usuario_status_event` (`usuario_id`, `status`, `last_event_at`),
  KEY `idx_cs_transacao` (`transacao_id`),
  KEY `idx_cs_produto` (`produto_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Observação de jornada de checkout. Não é fonte de verdade de pagamento.';

CREATE TABLE IF NOT EXISTS `checkout_session_events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL COMMENT 'checkout_sessions.id',
  `usuario_id` int(11) NOT NULL COMMENT 'Cópia do seller para isolamento sem JOIN obrigatório',
  `event_name` varchar(64) NOT NULL COMMENT 'opened, customer_info, payment_method_selected, payment_attempted, ...',
  `payload_json` text DEFAULT NULL COMMENT 'JSON restrito: sem cartão, CVV, QR Pix, tokens ou dump de request',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_cse_session` (`session_id`),
  KEY `idx_cse_usuario_created` (`usuario_id`, `created_at`),
  KEY `idx_cse_session_event` (`session_id`, `event_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Eventos da jornada observada. Permite o mesmo event_name mais de uma vez.';

ALTER TABLE `checkout_sessions`
  ADD CONSTRAINT `fk_cs_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cs_produto`
    FOREIGN KEY (`produto_id`) REFERENCES `produtos` (`id`) ON DELETE CASCADE;

ALTER TABLE `checkout_session_events`
  ADD CONSTRAINT `fk_cse_session`
    FOREIGN KEY (`session_id`) REFERENCES `checkout_sessions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cse_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

INSERT IGNORE INTO `configuracoes_sistema` (`community_id`, `chave`, `valor`, `tipo`, `descricao`) VALUES
(NULL, 'checkout_recovery_observe', '0', 'boolean', 'Observação de jornada de checkout (1=on). Default 0. Não dispara mensagens nem altera pagamento.'),
(NULL, 'checkout_recovery_enabled', '0', 'boolean', 'Recuperação ativa (WhatsApp/fila). Reservada; manter 0 até autorização. Independente da observação.');

-- ========== ROLLBACK (não execute junto com a aplicação) ==========
-- ALTER TABLE `checkout_session_events` DROP FOREIGN KEY `fk_cse_session`;
-- ALTER TABLE `checkout_session_events` DROP FOREIGN KEY `fk_cse_usuario`;
-- ALTER TABLE `checkout_sessions` DROP FOREIGN KEY `fk_cs_produto`;
-- ALTER TABLE `checkout_sessions` DROP FOREIGN KEY `fk_cs_usuario`;
-- DROP TABLE IF EXISTS `checkout_session_events`;
-- DROP TABLE IF EXISTS `checkout_sessions`;
-- DELETE FROM `configuracoes_sistema` WHERE `chave` IN ('checkout_recovery_observe', 'checkout_recovery_enabled');
