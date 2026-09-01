-- =============================================================================
-- Limpeza de duplicados em products_feed_items + índice que impede novos NULLs
-- Execute MANUALMENTE em instalação existente. NÃO roda no boot da aplicação.
-- Instalação nova: database/install.sql já inclui unique_user_item.
-- =============================================================================
--
-- Como os duplicados surgiram
-- ---------------------------
-- reorder_feed fazia UPDATE ... SET sort_order = ? WHERE usuario_id + item_type + item_id
-- e, se rowCount() === 0, INSERT com community_id NULL.
-- rowCount() = 0 também ocorre quando a linha EXISTE e o sort_order já era o mesmo.
-- UNIQUE(usuario_id, community_id, item_type, item_id) NÃO impede vários NULL
-- em community_id no MySQL/MariaDB.
--
-- Qual registro é mantido (ordem visual atual)
-- --------------------------------------------
-- Listagem (views/produtos.php, área de membros, ofertas):
--   ORDER BY sort_order ASC, id ASC
--   depois dedupe por (item_type, item_id) — fica a PRIMEIRA linha do grupo.
-- Portanto o registro "exibido" é o de menor sort_order; empate: menor id.
-- Entre empatados no sort_order, preferimos community_id preenchido
-- (não altera a posição visual, só preserva tenant quando existir).
--
-- O que é removido
-- ----------------
-- Qualquer outra linha do mesmo (usuario_id, item_type, item_id).
-- sort_order do keeper NÃO é reescrito: a ordem relativa entre itens únicos
-- permanece a mesma. Não mexe em produtos.ordem.
--
-- Isolamento
-- ----------
-- Apenas apaga duplicatas DENTRO do mesmo usuario_id + item_type + item_id.
-- Não cruza usuários. Não altera sort_order de keepers.
--
-- ETAPA 1 — auditoria (pode rodar sozinha e parar)
-- ETAPA 2 — tabela de keepers
-- ETAPA 3 — DELETE dos não-keepers
-- ETAPA 4 — UNIQUE (usuario_id, item_type, item_id)
-- =============================================================================

-- ETAPA 1: auditoria (permanece após o script para conferência)
CREATE TABLE IF NOT EXISTS `_products_feed_items_dupes_audit` (
  `usuario_id` int(11) UNSIGNED NOT NULL,
  `item_type` enum('product','banner') NOT NULL,
  `item_id` int(11) UNSIGNED NOT NULL,
  `duplicate_count` int(11) NOT NULL,
  `min_sort_order` int(11) NOT NULL,
  `max_sort_order` int(11) NOT NULL,
  `keeper_id` int(11) UNSIGNED DEFAULT NULL,
  `audited_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`usuario_id`, `item_type`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `_products_feed_items_dupes_audit`
  (`usuario_id`, `item_type`, `item_id`, `duplicate_count`, `min_sort_order`, `max_sort_order`, `keeper_id`)
SELECT
  g.usuario_id,
  g.item_type,
  g.item_id,
  g.duplicate_count,
  g.min_sort_order,
  g.max_sort_order,
  NULL
FROM (
  SELECT
    usuario_id,
    item_type,
    item_id,
    COUNT(*) AS duplicate_count,
    MIN(sort_order) AS min_sort_order,
    MAX(sort_order) AS max_sort_order
  FROM `products_feed_items`
  GROUP BY usuario_id, item_type, item_id
  HAVING COUNT(*) > 1
) g
ON DUPLICATE KEY UPDATE
  duplicate_count = VALUES(duplicate_count),
  min_sort_order = VALUES(min_sort_order),
  max_sort_order = VALUES(max_sort_order),
  audited_at = CURRENT_TIMESTAMP;

-- Conferir antes do DELETE:
-- SELECT * FROM _products_feed_items_dupes_audit ORDER BY duplicate_count DESC;

-- ETAPA 2: keepers (um id por usuario_id + item_type + item_id, inclusive itens sem duplicata)
DROP TEMPORARY TABLE IF EXISTS `_pfi_keepers`;
CREATE TEMPORARY TABLE `_pfi_keepers` (
  `id` int(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT INTO `_pfi_keepers` (`id`)
SELECT `id` FROM (
  SELECT
    `id`,
    ROW_NUMBER() OVER (
      PARTITION BY `usuario_id`, `item_type`, `item_id`
      ORDER BY `sort_order` ASC, (`community_id` IS NULL) ASC, `id` ASC
    ) AS rn
  FROM `products_feed_items`
) ranked
WHERE ranked.rn = 1;

UPDATE `_products_feed_items_dupes_audit` a
INNER JOIN (
  SELECT p.usuario_id, p.item_type, p.item_id, p.id AS keeper_id
  FROM `products_feed_items` p
  INNER JOIN `_pfi_keepers` k ON k.id = p.id
) x ON x.usuario_id = a.usuario_id AND x.item_type = a.item_type AND x.item_id = a.item_id
SET a.keeper_id = x.keeper_id;

-- ETAPA 3: remove duplicados; keepers intactos (mesmo sort_order)
-- A temp table _pfi_keepers é outra tabela, então NOT IN é seguro (não é 1093).
DELETE FROM `products_feed_items`
WHERE `id` NOT IN (SELECT `id` FROM `_pfi_keepers`);

DROP TEMPORARY TABLE IF EXISTS `_pfi_keepers`;

-- ETAPA 4: impede novas duplicatas mesmo com community_id NULL
-- (o UNIQUE antigo unique_item não cobre múltiplos NULL)
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'products_feed_items'
    AND index_name = 'unique_user_item'
);
SET @sql_idx := IF(
  @idx_exists = 0,
  'ALTER TABLE `products_feed_items` ADD UNIQUE KEY `unique_user_item` (`usuario_id`, `item_type`, `item_id`)',
  'SELECT ''unique_user_item already exists'' AS info'
);
PREPARE stmt_idx FROM @sql_idx;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;
