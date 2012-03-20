<?php

// ----------------------------------------------------------------------------
// Generic
// ----------------------------------------------------------------------------

function unzip($file, $dir)
{
    if (class_exists('ZipArchive')) {

        $zip = new ZipArchive();
        if ($zip->open($file) === true) {
            $_ret = $zip->extractTo($dir);
            $zip->close();
            return $_ret;
        }
        else return false;
    }
    else {

        // Escape
        $file = escapeshellarg($file);
        $dir = escapeshellarg($dir);

        $cmd = "unzip {$file} -d {$dir}"; // Info-zip assumed to be in path

        $res = -1; // any nonzero value
        $unused = array();
        $unused2 = exec($cmd, $unused, $res);
        if ($res != 0) trigger_error("Warning: unzip return value is $res ", E_USER_WARNING);

        return ($res == 0 || $res == 1); // http://www.info-zip.org/FAQ.html#error-codes
    }
}


function obliterate_dir($dirname)
{
    if (!is_dir($dirname)) return false;

    if (isset($_ENV['OS']) && strripos($_ENV['OS'], "windows", 0) !== FALSE) {

        // Windows patch for buggy perimssions on some machines
        $command = 'cmd /C "rmdir /S /Q "'.str_replace('//', '\\', $dirname).'\\""';
        $wsh = new COM("WScript.Shell");
        $wsh->Run($command, 7, false);
        $wsh = null;
        return true;

    }
    else {

        $dscan = array(realpath($dirname));
        $darr = array();
        while (!empty($dscan)) {
            $dcur = array_pop($dscan);
            $darr[] = $dcur;
            if ($d = opendir($dcur)) {
                while ($f=readdir($d)) {
                    if ($f == '.' || $f == '..') continue;
                    $f = $dcur . '/' . $f;
                    if (is_dir($f)) $dscan[] = $f;
                    else unlink($f);
                }
                closedir($d);
            }
        }

        for ($i=count($darr)-1; $i >= 0 ; $i--) {
            if (!rmdir($darr[$i]))
                trigger_error("Warning: There was a problem deleting a temporary file in $dirname ", E_USER_WARNING);
        }
        return (!is_dir($dirname));
    }
}


function get_temp_dir() {
    // Try to get from environment variable
    if (!empty($_ENV['TMP'])) {
        return realpath($_ENV['TMP']);
    }
    else if (!empty($_ENV['TMPDIR'])) {
        return realpath($_ENV['TMPDIR']);
    }
    else if (!empty($_ENV['TEMP'])) {
        return realpath($_ENV['TEMP']);
    }
    else {
        // Detect by creating a temporary file
        $temp_file = tempnam(md5(uniqid(mt_rand(), true)), '');
        if ($temp_file) {
            $temp_dir = realpath(dirname($temp_file));
            unlink($temp_file);
            return $temp_dir;
        }
        else {
            return false;
        }
    }
}


function is_binary($file)
{
    if (file_exists($file)) {
        if (!is_file($file)) return false;

        $fh  = fopen($file, "r");
        $blk = fread($fh, 512);
        fclose($fh);
        clearstatcache();

        return (
        	false ||
        	substr_count($blk, "^\r\n")/512 > 0.3 ||
        	substr_count($blk, "^ -~")/512 > 0.3 ||
        	substr_count($blk, "\x00") > 0
            );
    }
    return false;
}

?>