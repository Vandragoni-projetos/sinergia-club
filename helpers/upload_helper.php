<?php
/**
 * Diretórios de upload com caminho absoluto.
 *
 * api/admin_api.php roda com CWD em /var/www/html/api. Um mkdir('uploads/config')
 * relativo cria api/uploads/config, enquanto move_uploaded_file gravava em
 * /var/www/html/uploads/config — pasta que frequentemente não existe ou não é
 * gravável (volume Docker vazio). Sempre use caminho absoluto a partir da raiz.
 */

/**
 * Garante que $absoluteDir exista e seja gravável pelo processo PHP.
 *
 * @return array{ok:bool, dir:string, error:?string}
 */
function ensure_writable_upload_dir($absoluteDir, $mode = 0775)
{
    $absoluteDir = rtrim(str_replace('\\', '/', (string) $absoluteDir), '/');
    if ($absoluteDir === '' || $absoluteDir === '/') {
        return ['ok' => false, 'dir' => $absoluteDir, 'error' => 'Caminho de upload inválido'];
    }

    if (!is_dir($absoluteDir)) {
        if (!@mkdir($absoluteDir, $mode, true) && !is_dir($absoluteDir)) {
            $err = error_get_last();
            $hint = isset($err['message']) ? ' (' . $err['message'] . ')' : '';
            return [
                'ok' => false,
                'dir' => $absoluteDir,
                'error' => 'Não foi possível criar o diretório de upload: ' . $absoluteDir . $hint
                    . '. Verifique se o servidor web pode gravar em uploads/.',
            ];
        }
        @chmod($absoluteDir, $mode);
    }

    if (!is_writable($absoluteDir)) {
        @chmod($absoluteDir, $mode);
    }

    if (!is_writable($absoluteDir)) {
        return [
            'ok' => false,
            'dir' => $absoluteDir,
            'error' => 'Diretório de upload sem permissão de escrita: ' . $absoluteDir
                . '. Ajuste dono e permissões (ex.: chown www-data:www-data uploads && chmod -R 775 uploads).',
        ];
    }

    return ['ok' => true, 'dir' => $absoluteDir, 'error' => null];
}

/**
 * Garante uploads/config na raiz do projeto (não relativo ao CWD).
 *
 * @param string|null $projectRoot Raiz do projeto; default = pasta pai de helpers/
 * @return array{ok:bool, dir:string, error:?string}
 */
function ensure_uploads_config_dir($projectRoot = null)
{
    $root = $projectRoot !== null ? rtrim(str_replace('\\', '/', $projectRoot), '/') : dirname(__DIR__);
    return ensure_writable_upload_dir($root . '/uploads/config');
}

/**
 * Remove um arquivo de upload local antigo, apenas se estiver dentro de uploads/.
 */
function delete_local_upload_file($storedPath, $projectRoot = null)
{
    if ($storedPath === null || $storedPath === '') {
        return;
    }
    $storedPath = (string) $storedPath;
    if (strpos($storedPath, 'http://') === 0 || strpos($storedPath, 'https://') === 0) {
        return;
    }

    $root = $projectRoot !== null ? rtrim(str_replace('\\', '/', $projectRoot), '/') : dirname(__DIR__);
    $uploadsRoot = realpath($root . '/uploads');
    $candidate = $root . '/' . ltrim($storedPath, '/');
    $resolved = realpath($candidate);

    if ($uploadsRoot && $resolved && strpos($resolved, $uploadsRoot) === 0 && is_file($resolved)) {
        @unlink($resolved);
    }
}
