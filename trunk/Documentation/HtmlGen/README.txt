# Usage  #####################################################################

copy the images to a public webserver
copy `config.sample.php` to `config.php` and edit accordingly
run the scripts at the command prompt, example:
$ php api_to_html.php


# api_to_html.php #############################################################

Hacks the Lua docs into HTML; uses PHP Markdown.

Markdown tips:

When you do want to insert a <br /> break tag using Markdown, you end a line
with two or more spaces, then type return.

Syntax docs available at:
* http://daringfireball.net/projects/markdown/syntax
* http://michelf.com/projects/php-markdown/extra/


# api_concisor.php ############################################################

Reduces the API docs into a list of functions.

// WORK IN PROGRESS, CURRENTLY NOT FUNCTIONAL...
