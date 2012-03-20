<?php

require_once('functions.php');

// ----------------------------------------------------------------------------
// Config
// ----------------------------------------------------------------------------

$valid_extensions = array('lua', 'xml'); // Lowercase letters!

$suspicious = array(
    'execute',
    'install_tool',
    'load',
    'loadfile',
    'loadstring',
    'open',
    'osc',
    'read',
    'socket',
    'uninstall_tool',
    'write',
    'remove',
    'rename',
    );

// ----------------------------------------------------------------------------
// Functions
// ----------------------------------------------------------------------------

function get_files($file, $tmp_dir)
{
    if (!is_dir($tmp_dir) && !mkdir($tmp_dir, 0777, true)) {
        throw new Exception('Can\'t create temp dir ' . $tmp_dir);
    }

    if (unzip($file, $tmp_dir)) {
        $files = array();
        foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($tmp_dir)) as $file) {
            if (!$file->isFile()) continue;
            $files[$file->getPathname()] = $file->getFilename();
        }
        return $files;
    }
    else return false;
}

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------

function scan($file) {

    global $valid_extensions, $suspicious;

    try {

        $tmp_dir = get_temp_dir() . '/' . md5(uniqid(mt_rand(), true));
        $warnings = array();

        // Check if extension is XRNX
        $format = explode('.', $file);
        $format = strtolower(end($format));
        if ($format != 'xrnx') {
            $warnings[] = "$file is not of type XRNX";
        }
        // Check if file can be unzipped
        $files = get_files($file, $tmp_dir);
        if ($files === false) {
            $warnings[] = "Cannot unzip $file";
        }
        // Check if file is empty
        else if (!count($files)) {
            $warnings[] = "$file is empty";
        }
        else foreach($files as $fullpath => $filename) {

            $format = explode('.', $filename);
            $format = strtolower(end($format));
            $relpath = substr_replace($fullpath, '', 0, strlen($tmp_dir) + 1);

            // Check if file is binary
            if (is_binary($fullpath)) {
                $warnings[] = "$relpath is binary";
            }
            // Check for OSX junk
            else if ((mb_strpos($fullpath, '__MACOSX') !== false)) {
                $warnings[] = "$relpath is OSX junk";
            }
            // Check for sane extensions
            else if (!in_array($format, $valid_extensions)) {
                $warnings[] = "$relpath is not of type: " . strtoupper(implode(',', $valid_extensions));
            }
            else {
                // Scan contents for suspect code
                $tmp = file($fullpath);
                foreach ($tmp as $line => $tmp2) {
                    $tokens = mb_split("\W", $tmp2);
                    foreach ($tokens as $tmp3) {
                        foreach ($suspicious as $findme) {
                            $pos = strtolower($tmp3) == strtolower($findme);
                            if ($pos !== false) {
                            	$suspect_code = "$relpath contains suspect code `$findme` on line " . ($line + 1) . ":\n";
                            	$suspect_code .= "\t";
                            	$suspect_code .=  str_repeat(' ', strlen(count($warnings)) - 1);
                            	$suspect_code .= '-> ' . trim($tmp2);
                            	$warnings[] = $suspect_code;
                            }
                        }
                    }
                }
            }
        }

        // Cleanup and return
        obliterate_dir($tmp_dir);
        if (count($warnings)) return $warnings;
        else return true;

    }
    catch (Exception $e) {

        obliterate_dir($tmp_dir); // Cleanup

        $tmp = 'Error: ';
        $tmp .= $e->getMessage() . "\n";
        $tmp .= "File: " . $e->getFile() . "\n";
        $tmp .= "Line: " . $e->getLine() . "\n\n";
        $tmp .= "Backtrace: \n" . print_r($e->getTrace(), true) . "\n\n";

        if (!headers_sent()) header('Content-Type: text/plain');
        die($tmp);
    }
}

?>