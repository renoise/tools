<?php

// ----------------------------------------------------------------------------
// Example
// ----------------------------------------------------------------------------

$file = '/Users/dac514/Desktop/com.renoise.IRCclientV1_13.xrnx';

require('scanner.php');

if (file_exists(@$argv[1])) $file = $argv[1];
$result = scan($file);
if ($result !== true) {
    if (!headers_sent()) header('Content-Type: text/plain');
    echo "Warnings Found: " . count($result) . "\n";
    print_r($result);
}

?>