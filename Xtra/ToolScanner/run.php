<?php

// ----------------------------------------------------------------------------
// Example
// ----------------------------------------------------------------------------

$file = '~/Downloads/foo.xrnx';

require('scanner.php');

if (file_exists(@$argv[1])) $file = $argv[1];
$result = scan($file);

if (!headers_sent()) header('Content-Type: text/plain');

if ($result !== true) {
    echo "Warnings Found: " . count($result) . "\n";
    print_r($result);
}
else {
    echo "Nothing suspicious found. Everything seems OK. \n";
}

?>