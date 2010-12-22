<?php

require_once(dirname(__FILE__) . '/config.php');

$concise = array();
foreach(new DirectoryIterator($CONFIG['DOCS_DIR']) as $file) {

    if (!$file->isFile()) continue;
    if (!preg_match('/lua$/', $file->getFilename())) continue;

    $tmp = file_get_contents($file->getPathname());

    $tmp = preg_replace('/--\[\[(.*?)(\]\]--|\]\])/s', null, $tmp);
    $tmp = preg_replace('/^--(.*?)$/sm', null, $tmp);
    $tmp = preg_replace('/\s*?->(.*?)$/sm', null, $tmp);
    $tmp = str_replace(', _observable', null, $tmp);

    $tmp = preg_replace("/(^[\r\n]*|[\r\n]+)[\s\t]*[\r\n]+/", "\n", $tmp);

    // $concise .= "\n >>> " . $file->getFilename() . " <<< \n";

    $concise = array_merge($concise, explode("\n", $tmp));
}

// natcasesort($concise);

print_r($concise);

?>