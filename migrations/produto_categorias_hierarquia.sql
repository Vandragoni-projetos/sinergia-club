-- Categoria Principal + Subcategoria (classificação TEMÁTICA adicional)
-- Ambiente: LOCAL apenas. Não executar em produção sem autorização explícita.
--
-- Esta taxonomia é INDEPENDENTE de produtos.product_type (E-books, PLR, etc.).
-- Não reutiliza migrations/nicho_separation.sql.
-- Sem seed: nenhum nome de categoria/subcategoria é gravado aqui.
-- Sem backfill: produtos existentes permanecem com as novas FKs em NULL.
--
-- Tipos alinhados ao schema atual:
--   produtos.id          int(11) signed
--   produtos.usuario_id  int(11) signed
--   usuarios.id          int(11) signed
-- Por isso as PKs/FKs novas usam int(11) (NÃO UNSIGNED).
--
-- Aplicar (local):
--   mysql -u USUARIO -p NOME_DO_BANCO < migrations/produto_categorias_hierarquia.sql
--   ou via cliente SQL: execute apenas a seção "APLICAÇÃO" abaixo.
--
-- Reexecução: falhará se as tabelas/colunas já existirem (esperado).

-- ========== APLICAÇÃO ==========

CREATE TABLE `product_main_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL COMMENT 'Infoprodutor dono da categoria (isolamento multi-seller)',
  `nome` varchar(120) NOT NULL COMMENT 'Nome cadastrado pelo usuário autorizado (não hardcoded)',
  `slug` varchar(120) DEFAULT NULL,
  `ordem` int(11) NOT NULL DEFAULT 0,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pmc_usuario_nome` (`usuario_id`, `nome`),
  KEY `idx_pmc_usuario` (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `product_subcategories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` int(11) NOT NULL COMMENT 'Infoprodutor dono (deve coincidir com a categoria principal)',
  `main_category_id` int(11) NOT NULL COMMENT 'Categoria principal à qual esta subcategoria pertence',
  `nome` varchar(120) NOT NULL COMMENT 'Nome cadastrado pelo usuário autorizado (não hardcoded)',
  `slug` varchar(120) DEFAULT NULL,
  `ordem` int(11) NOT NULL DEFAULT 0,
  `ativo` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_psc_main_nome` (`main_category_id`, `nome`),
  KEY `idx_psc_usuario` (`usuario_id`),
  KEY `idx_psc_main` (`main_category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `produtos`
  ADD COLUMN `main_category_id` int(11) DEFAULT NULL
    COMMENT 'Categoria principal temática (opcional; independente de product_type)'
    AFTER `product_type`,
  ADD COLUMN `subcategory_id` int(11) DEFAULT NULL
    COMMENT 'Subcategoria temática (opcional; deve pertencer à categoria principal)'
    AFTER `main_category_id`,
  ADD KEY `idx_produtos_main_cat` (`main_category_id`),
  ADD KEY `idx_produtos_subcat` (`subcategory_id`);

ALTER TABLE `product_main_categories`
  ADD CONSTRAINT `fk_pmc_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

ALTER TABLE `product_subcategories`
  ADD CONSTRAINT `fk_psc_usuario`
    FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_psc_main`
    FOREIGN KEY (`main_category_id`) REFERENCES `product_main_categories` (`id`) ON DELETE CASCADE;

ALTER TABLE `produtos`
  ADD CONSTRAINT `fk_produtos_main_cat`
    FOREIGN KEY (`main_category_id`) REFERENCES `product_main_categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_produtos_subcat`
    FOREIGN KEY (`subcategory_id`) REFERENCES `product_subcategories` (`id`) ON DELETE SET NULL;

-- ========== ROLLBACK (não execute junto com a aplicação) ==========
-- ALTER TABLE `produtos` DROP FOREIGN KEY `fk_produtos_subcat`;
-- ALTER TABLE `produtos` DROP FOREIGN KEY `fk_produtos_main_cat`;
-- ALTER TABLE `produtos` DROP INDEX `idx_produtos_subcat`;
-- ALTER TABLE `produtos` DROP INDEX `idx_produtos_main_cat`;
-- ALTER TABLE `produtos` DROP COLUMN `subcategory_id`;
-- ALTER TABLE `produtos` DROP COLUMN `main_category_id`;
-- ALTER TABLE `product_subcategories` DROP FOREIGN KEY `fk_psc_main`;
-- ALTER TABLE `product_subcategories` DROP FOREIGN KEY `fk_psc_usuario`;
-- ALTER TABLE `product_main_categories` DROP FOREIGN KEY `fk_pmc_usuario`;
-- DROP TABLE IF EXISTS `product_subcategories`;
-- DROP TABLE IF EXISTS `product_main_categories`;
