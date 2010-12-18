<?php

require_once(dirname(__FILE__) . '/markdown/markdown.php');
require_once(dirname(__FILE__) . '/geshi/geshi.php');


// Override Markdown Class, parse code with Geshi
class MarkdownGeshi_Parser extends MarkdownExtra_Parser {

    public $geshi_code_type = 'lua';

    function _doCodeBlocks_callback($matches) {
        $codeblock = $matches[1];
        $codeblock = $this->outdent($codeblock);
        $geshi = new GeSHi(trim($codeblock), $this->geshi_code_type);
        $codeblock  = $geshi->parse_code();
        return "\n\n".$this->hashBlock($codeblock)."\n\n";
    }

    function _doFencedCodeBlocks_callback($matches) {
        $codeblock = $matches[2];
        $geshi = new GeSHi(trim($codeblock), $this->geshi_code_type);
        $codeblock  = $geshi->parse_code();
        return "\n\n".$this->hashBlock($codeblock)."\n\n";
    }

}


function Markdown_with_geshi($text) {
    static $parser;
    if (!isset($parser)) {
        $parser = new MarkdownGeshi_Parser();
    }
    return $parser->transform($text);
}