<?php

error_reporting(E_ALL ^ E_NOTICE ^ E_WARNING);
require_once('/var/lib/mediawiki/maintenance/commandLine.inc');
ini_set('pcre.backtrack_limit', 250000);

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

$renoise_title = 'Renoise 2.5 User Manual';

$renoise_pdf = '
PDF Main

Main Screen
Setting Up Audio Devices
Setting Up MIDI Devices

Disk Browser

Transport Panel
Scopes
Instrument Selector
Song Settings
Song Comments

Playing Notes with the Computer Keyboard
Recording and Editing Notes
Pattern Editor
Pattern Sequencer
Pattern Matrix
Advanced Edit

Instrument Editor
Instrument Settings

Sample Editor
Recording New Samples

Track DSPs
Audio Effects
Routing Devices
Meta Devices
VST/AU/LADSPA Effects

Graphical Automation
Pattern Effect Commands

Mixer

Render Song to Audio File
Render & Resample Parts of the Song
Render or Freeze Plugin Instruments to Samples

ReWire
Jack Transport
MIDI Clock

MIDI Mapping

Preferences

Keyboard Shortcuts
';


$GLOBALS['wgMaxTocLevel'] = 0;
$renoise_filename = 'renoise_manual';
if(!defined('MAX_IMAGE_WIDTH')) define('MAX_IMAGE_WIDTH', 670);


// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------

function buildLink($link, $display)
{
    // Fix slashes
    $link = stripslashes($link);
    $display = stripslashes($display);

    if (stripos($display, '<img') !== false)
    {
        // Remove href links from images
        return $display;
    }
    elseif (strpos($link, '/wiki/') !== false)
    {
        // Make urls relative to self
        if (strpos($link, '#') !== false)
        {
            $link = explode('#', $link);
            $link = end($link);

        }
        else
        {
            $link = explode('/', $link);
            $link = end($link);
        }

        global $html;
        if (preg_match("/name\=(\"|\')$link(\"|\')/i", $html))
        {
            // Anchor exists
            return "<a href='#$link'>$display</a>";
        }
        else
        {
            // Anchor doesn't exist
            return $display;
        }
    }
    else
    {
        // Return the URL, unchanged
        return "<a href='$link'>$display</a>";
    }
}


// ---------------------------------------------------------------------------
// Get Wiki Markup
// ---------------------------------------------------------------------------

// Convert string to array
$renoise_pdf = explode("\n", trim($renoise_pdf));

$wiki_markup = '';
foreach ($renoise_pdf as $title)
{
    $title = trim($title);
    if (!$title) continue;

    $page = new Article(Title::newFromText($title));
    if (!$page->exists())
    {
        echo "The page '$title' doesn't exist, skipping... \n";
        continue;
    }
    $tmp = trim($page->preSaveTransform($page->getContent()));

    // When creating a PDF book, each page must have a <h1> header.
    // Fix any page that doesn't respect this convention.
    if(!preg_match('/^=\s+\w/', $tmp))
    {
        $tmp = "= $title = \n\n" . $tmp;
    }

    $wiki_markup .= $tmp . "\n\n";
}

// Hacks
$wiki_markup = preg_replace('/<!-- RENOISE_NO_PDF_START -->(.*)<!-- RENOISE_NO_PDF_STOP -->/sU', null, $wiki_markup); // Remove content between <!-- RENOISE_NO_PDF_START|STOP --> tags
$wiki_markup = str_replace('__NOTOC__', '', $wiki_markup); // Erase NOTOC tags
$wiki_markup = preg_replace('/\[\[Image:(.+)(\.jpe?g|\.gif|\.png)(.*)\]\]/iU', '[[Image:$1$2]]', $wiki_markup); // Get rid of extra crap in images

// Output wiki txt
file_put_contents("$renoise_filename.txt", $wiki_markup);

// ---------------------------------------------------------------------------
// Generate HTML
// ---------------------------------------------------------------------------

$parser = new Parser();

$popts = new ParserOptions();
$popts->setEditSection(false);
$popts->setTidy(true);

$p = $parser->parse($wiki_markup, Title::newFromText($title), $popts);
$html = $p->getText();

// Hacks
$html = preg_replace('#<a[\s]+[^>]*?href[\s]?=[\s"\']+(.*?)["\']+.*?>([^<]+|.*?)?</a>#sie', 'buildLink("$1", "$2")', $html); // <a href="">, <a href=''>, and other mutations
$html = preg_replace('#<a name=(.+)></a><h(\d)>(.+)</h\d>#iU', '<h$2>$3<a name=$1></a></h$2>', $html); // Move the anchor tags to be compatible with htmldoc book format
$html = str_replace('/images/', 'http://tutorials.renoise.com/images/', $html); // Set correct path
$html = preg_replace('/height="\d+"/', '', $html); // Remove height of images
$html = preg_replace('/width="(\d+)"/e', '"width=\"".($1> MAX_IMAGE_WIDTH ? MAX_IMAGE_WIDTH : $1)."\""', $html); // Set upper limit for image width
$html = iconv('UTF-8', 'ISO-8859-1//TRANSLIT', $html); // Convert encoding

// ---------------------------------------------------------------------------
// Make Html and PDF files
// ---------------------------------------------------------------------------

// Output HTML
$html = "<html><head><title>$renoise_title</title></head><body>$html</body></html>";
file_put_contents("$renoise_filename.html", $html);

// Output PDF
$cmd = 'htmldoc -t pdf14 --quiet --book --color --firstpage c1 --pagemode outline --numbered --jpeg 100 --links --bottom 2 --linkcolor 9B300C --bodyfont Sans --textfont Sans --headfootfont Sans ';
$cmd .= "-f $renoise_filename.pdf $renoise_filename.html";
exec($cmd);

// ---------------------------------------------------------------------------
// The end
// ---------------------------------------------------------------------------

echo "Done! \n";