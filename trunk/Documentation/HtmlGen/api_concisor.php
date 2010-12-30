<?php

require_once(dirname(__FILE__) . '/config.php');

$concise = array();
foreach(new DirectoryIterator($CONFIG['DOCS_DIR']) as $file) {

    if (!$file->isFile()) continue;
    if (!preg_match('/lua$/', $file->getFilename())) continue;

    $tmp = file_get_contents($file->getPathname());

    /*
    Regular expression mayhem
    For modifier explinations, see:
    http://php.net/manual/en/reference.pcre.pattern.modifiers.php
    */

    // Find `--[[ % ]]--` or `--[[ % ]]` and replace with null
    $tmp = preg_replace('/--\[\[(.*?)(\]\]--|\]\])/s', null, $tmp);

    // Find `-- %` and replace with null
    $tmp = preg_replace('/^--(.*?)$/sm', null, $tmp);

    // Find `_observable` and replace with null
    $tmp = str_replace(', _observable', null, $tmp);
    $tmp = str_replace(', TODO: _observable', null, $tmp);

    // Append to array
    $concise = array_merge($concise, explode("\n", $tmp));
}

foreach ($concise as $key => &$val) {

    $val = rtrim($val);

    // If `(` or ` or` are the last characters, concatenate the next line
    if (preg_match('/(\(| or)$/', $val)) {
        $val .= @trim($concise[$key+1]);
        unset($concise[$key+1]);
    }

    // Remove everything after ` -> `, also check the next line...
    if (preg_match('/\s*?->(.*?)/', $val)) {
        $val = preg_replace('/\s*?->(.*?)$/', null, $val);
        // Next line...
        if (preg_match('/^\s.?/', @$concise[$key+1])) {
            unset($concise[$key+1]);
        }
    }

    $val = trim($val);

    // Remove blank lines
    if ($val == '') {
        unset($concise[$key]);
        continue;
    }

    // Remove operators
    if (!preg_match('/^[A-z0-9]/', $val)) {
        unset($concise[$key]);
        continue;
    }

}

// Sort and print
natcasesort($concise);
$concise = array_values($concise);
// print_r($concise);
echo implode("\n", $concise) . "\n";

?>