# Preço secundário para Order Bump

## Visão geral

Cada produto mantém o preço normal de venda (`produtos.preco`) e pode ter um **preço opcional** usado **somente** quando esse produto é oferecido como Order Bump em outro checkout:

| Coluna | Uso |
|--------|-----|
| `produtos.preco` | Compra como produto principal (e fallback do bump) |
| `produtos.preco_order_bump` | Preço no contexto Order Bump, se válido |

**Regra de preço efetivo do bump:**

```
preco_order_bump IS NOT NULL AND preco_order_bump > 0
  ? preco_order_bump
  : preco
```

- `NULL`, `0` ou valor negativo → usa `preco` (nunca bump “grátis” por preço inválido).
- Nenhum valor monetário deve ser hardcoded: preços vêm do banco por produto.
- O navegador envia apenas **IDs** dos bumps; o backend recalcula o total.

## Onde configurar

1. Painel → Produto → aba **Geral**.
2. Campo **Preço para Order Bump (opcional)** (abaixo de Preço / Preço Anterior).
3. Vazio = `NULL` = usa o preço normal quando for Order Bump.
4. A vinculação do bump continua na aba **Order Bumps** (sem mudança de fluxo).

## Arquivos envolvidos

| Arquivo | Papel |
|---------|--------|
| `migrations/preco_order_bump.sql` | Migration incremental (bancos existentes) |
| `Base_de_Dados_Instalacao.sql` | Schema de instalação nova (já inclui a coluna) |
| `views/produto_config/aba_geral.php` | Campo na UI |
| `views/produto_config.php` | Validação POST e `UPDATE` |
| `checkout.php` | Renderização + `data-price` com preço efetivo |
| `process_payment.php` | Recálculo servidor + `save_sales()` |
| `helpers/coupon_helper.php` | `calcularDescontoCupomPorId()` |

Endpoint de pagamento real: `/process_payment` → `process_payment.php` (raiz).  
`api/process_payment.php` é legado e **não** é o fluxo do checkout atual.

## Cálculo no backend

Ordem (inalterada em relação ao checkout):

1. Preço do produto principal (`preco` ou oferta ativa)
2. Soma dos Order Bumps com preço efetivo
3. Cupom (recalculado no servidor a partir do `cupom_id`)
4. Desconto Pix (se método Pix / PushinPay), a partir de `checkout_config`

`transaction_amount` enviado pelo browser é **ignorado** após o recálculo.

### Persistência (`save_sales`)

- Uma linha em `vendas` por produto (principal + cada bump).
- Mesmo `checkout_session_uuid` e `transacao_id`.
- Linha do bump: valor = preço efetivo de Order Bump.
- Linha do principal: `transaction_amount − soma_dos_bumps` (cupom/Pix absorvidos na linha principal, como antes).
- `cupom_id` / `valor_desconto` só na linha do principal.
- Entrega (`notification.php` / `obrigado.php` / `alunos_acessos`) segue as linhas de venda — sem alteração de fluxo.

## Migration (bancos existentes)

### Aplicar

```sql
ALTER TABLE `produtos`
  ADD COLUMN `preco_order_bump` DECIMAL(10,2) NULL DEFAULT NULL
  COMMENT 'Preço quando vendido como Order Bump; NULL = usar produtos.preco'
  AFTER `preco`;
```

Ou:

```bash
mysql -u USUARIO -p NOME_DO_BANCO < migrations/preco_order_bump.sql
```

(Execute apenas a seção **APLICAÇÃO**; o rollback no arquivo está comentado.)

### Validar

```sql
SHOW COLUMNS FROM produtos LIKE 'preco_order_bump';
-- Type: decimal(10,2), Null: YES, Default: NULL

SELECT COUNT(*) FROM produtos WHERE preco_order_bump IS NOT NULL;
-- Esperado 0 até alguém preencher o campo
```

### Rollback de schema

```sql
ALTER TABLE `produtos` DROP COLUMN `preco_order_bump`;
```

Só dropar a coluna **depois** de reverter o código PHP para uma versão que não a utilize.

## Deploy (EasyPanel / VPS)

1. Backup do banco.
2. **Executar a migration** (coluna disponível).
3. Deploy do código (arquivos listados acima).
4. Smoke tests (abaixo).

**Importante:** o PHP novo quebra se a coluna ainda não existir. Migration **antes** (ou imediatamente antes) do deploy do código.

Instalações novas: basta `Base_de_Dados_Instalacao.sql` (já contém a coluna).

## Compatibilidade

- Produtos existentes com `NULL` → comportamento idêntico ao anterior no Order Bump.
- Compra como produto principal → sempre `produtos.preco` (ou preço da oferta).
- Gateways em `gateways/` não precisam de alteração: recebem o amount já recalculado.

## Testes mínimos pós-deploy

1. Checkout só principal → valor = `preco`.
2. Bump com `preco_order_bump` NULL → UI e cobrança usam `preco`.
3. Bump com secundário preenchido (ex.: 37,90 / 14,70) → bump mostra e cobra 14,70.
4. Mesmo produto aberto como principal → 37,90.
5. Pix e/ou cartão no gateway do ambiente.
6. Cupom; Pix + cupom se configurado.
7. Conferir `vendas`: uuid/transacao iguais; valores das linhas coerentes.
8. Entrega do principal + bumps após aprovação.
9. Aba Geral: salvar/limpar o campo sem corromper `checkout_config`.

## Rollback operacional

1. Reverter os arquivos PHP/SQL de instalação no deploy para a revisão anterior.
2. Se o código antigo já estiver no ar e quiser limpar o schema: `DROP COLUMN preco_order_bump`.
3. Não dropar a coluna enquanto o PHP novo estiver ativo.
