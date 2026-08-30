-- Preço secundário para Order Bump
-- Ambientes existentes: execute a seção APLICAÇÃO abaixo.
-- Instalações novas: a coluna já está em Base_de_Dados_Instalacao.sql.
-- Documentação: docs/geral/PRECO_ORDER_BUMP.md
--
-- Aplicar:
--   mysql -u USUARIO -p NOME_DO_BANCO < migrations/preco_order_bump.sql
--   ou via cliente SQL: execute apenas a seção "APLICAÇÃO" abaixo.
--
-- Compatibilidade:
--   - DECIMAL(10,2) igual a produtos.preco
--   - NULL = usar produtos.preco no contexto Order Bump (fallback)
--   - Sem DEFAULT 0; registros existentes permanecem NULL (comportamento atual)
--   - Não altera dados existentes
--
-- Reexecução: falhará com "Duplicate column" se a coluna já existir (esperado).

-- ========== APLICAÇÃO ==========
ALTER TABLE `produtos`
  ADD COLUMN `preco_order_bump` DECIMAL(10,2) NULL DEFAULT NULL
  COMMENT 'Preço quando vendido como Order Bump; NULL = usar produtos.preco'
  AFTER `preco`;

-- ========== ROLLBACK (não execute junto com a aplicação) ==========
-- ALTER TABLE `produtos` DROP COLUMN `preco_order_bump`;
