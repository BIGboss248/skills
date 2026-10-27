# Re-applies container-layer patches after the WordPress container is created,
# recreated, or upgraded.
#
# The official wordpress:latest image ships mysqli/mysqlnd but not pdo_mysql.
# Persian WooCommerce (and other Laravel/Eloquent plugins) need pdo_mysql, and
# WP-CLI is not bundled either. Both live in the container layer, so they are
# lost whenever the container is recreated. Run this script after every
# `docker compose up`, `down`, or image update.
#
# Usage:
#   pwsh ./patch-wordpress.ps1
#   pwsh ./patch-wordpress.ps1 -ContainerName wordpress

param(
    [string]$ContainerName = "wordpress"
)

$ErrorActionPreference = "Stop"

$modules = docker exec $ContainerName php -m
$hasPdoMysql = $modules | Where-Object { $_ -eq "pdo_mysql" }

if (-not $hasPdoMysql) {
    Write-Host "[*] pdo_mysql is missing. Compiling and installing it..."
    docker exec -u 0 $ContainerName docker-php-ext-install pdo_mysql
    docker exec $ContainerName apache2ctl graceful
    Write-Host "[+] pdo_mysql installed and Apache reloaded."
} else {
    Write-Host "[+] pdo_mysql is already installed."
}

$wpCliCheck = docker exec $ContainerName sh -lc "test -x /usr/local/bin/wp && echo yes || echo no"
if ($wpCliCheck.Trim() -ne "yes") {
    Write-Host "[*] WP-CLI is missing. Installing it..."
    $phar = Join-Path $env:TEMP "wp-cli.phar"
    curl.exe -L --retry 3 -o $phar "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
    docker cp $phar "${ContainerName}:/usr/local/bin/wp"
    docker exec $ContainerName chmod +x /usr/local/bin/wp
    Write-Host "[+] WP-CLI installed."
} else {
    Write-Host "[+] WP-CLI is already installed."
}

docker exec $ContainerName php -m | Select-String -Pattern "pdo_mysql"
