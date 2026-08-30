#!/bin/bash
set -e

if [ ! -f /var/www/html/vendor/autoload.php ]; then
  echo "[SinergIA] vendor/ não encontrado. Executando composer install..."
  cd /var/www/html && composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader
  chown -R www-data:www-data /var/www/html/vendor 2>/dev/null || true
  echo "[SinergIA] composer install concluído."
fi

# Volume persistente em /var/www/html/uploads (EasyPanel/Compose) pode nascer
# vazio e owned by root. Sem isso, move_uploaded_file falha em uploads/config.
mkdir -p /var/www/html/uploads/config
chown -R www-data:www-data /var/www/html/uploads 2>/dev/null || true
chmod -R 775 /var/www/html/uploads 2>/dev/null || true

exec "$@"
