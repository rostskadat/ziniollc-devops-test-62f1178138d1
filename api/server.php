<?php


declare(strict_types=1);

use Swoole\Database\MysqliConfig;
use Swoole\Database\MysqliPool;
use Swoole\Runtime;

$mysql_host = getenv('MYSQL_HOST') ?: "db";
$mysql_port = getenv('MYSQL_PORT') ?: "3306";
$mysql_dbname = getenv('MYSQL_DBNAME') ?: "dbname";
$mysql_username = getenv('MYSQL_USERNAME') ?: "user";
$mysql_password = getenv('MYSQL_PASSWORD') ?: "password";

$pool = new MysqliPool(
    (new MysqliConfig())
        ->withHost($mysql_host)
        ->withPort((int) $mysql_port)
        ->withDbName($mysql_dbname)
        ->withCharset('utf8mb4')
        ->withUsername($mysql_username)
        ->withPassword($mysql_password)
);

$http = new Swoole\HTTP\Server("0.0.0.0", 9501);

$http->on('start', function ($server)  {
    echo "Swoole http server is started at http://127.0.0.1:9501\n";
});

$http->on('request', function ($request, $response) use ($pool) {
    $response->header("Content-Type", "text/plain");
    $mysqli = $pool->get();
    $query = $mysqli->query('SELECT now()');
    $response->end(mysqli_fetch_array($query)[0]);
    $pool->put($mysqli);
});

$http->start();