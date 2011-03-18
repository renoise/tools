<?php
/*************************************************************************************
 * bash.php
 * --------
 * Author: Andreas Gohr (andi@splitbrain.org)
 * Copyright: (c) 2004 Andreas Gohr, Nigel McNie (http://qbnz.com/highlighter)
 * Release Version: 1.0.8.9
 * Date Started: 2004/08/20
 *
 * BASH language file for GeSHi.
 *
 * CHANGES
 * -------
 * 2008/06/21 (1.0.8)
 *  -  Added loads of keywords and commands of GNU/Linux
 *  -  Added support for parameters starting with a dash
 * 2008/05/23 (1.0.7.22)
 *  -  Added description of extra language features (SF#1970248)
 * 2007/09/05 (1.0.7.21)
 *  -  PARSER_CONTROL patch using SF #1788408 (BenBE)
 * 2007/06/11 (1.0.7.20)
 *  -  Added a lot of keywords (BenBE / Jan G)
 * 2004/11/27 (1.0.2)
 *  -  Added support for multiple object splitters
 * 2004/10/27 (1.0.1)
 *   -  Added support for URLs
 * 2004/08/20 (1.0.0)
 *   -  First Release
 *
 * TODO (updated 2004/11/27)
 * -------------------------
 * * Get symbols working
 * * Highlight builtin vars
 *
 *************************************************************************************
 *
 *     This file is part of GeSHi.
 *
 *   GeSHi is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   GeSHi is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with GeSHi; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 ************************************************************************************/

$language_data = array (
    'LANG_NAME' => 'Bash',
    // Bash DOES have single line comments with # markers. But bash also has
    // the  $# variable, so comments need special handling (see sf.net
    // 1564839)
    'COMMENT_SINGLE' => array('#'),
    'COMMENT_MULTI' => array(),
    'COMMENT_REGEXP' => array(
        //Variables
        1 => "/\\$\\{[^\\n\\}]*?\\}/i",
        //BASH-style Heredoc
        2 => '/<<-?\s*?(\'?)([a-zA-Z0-9]+)\1\\n.*\\n\\2(?![a-zA-Z0-9])/siU',
        //Escaped String Starters
        3 => "/\\\\['\"]/siU"
        ),
    'CASE_KEYWORDS' => GESHI_CAPS_NO_CHANGE,
    'QUOTEMARKS' => array('"'),
    'HARDQUOTE' => array("'", "'"),
    'HARDESCAPE' => array("\'"),
    'ESCAPE_CHAR' => '',
    'ESCAPE_REGEXP' => array(
        //Simple Single Char Escapes
        1 => "#\\\\[nfrtv\\$\\\"\n]#i",
        // $var
        2 => "#\\$[a-z_][a-z0-9_]*#i",
        // ${...}
        3 => "/\\$\\{[^\\n\\}]*?\\}/i",
        // $(...)
        4 => "/\\$\\([^\\n\\)]*?\\)/i",
        // `...`
        5 => "/`[^`]*`/"
        ),
    'KEYWORDS' => array(
        1 => array(
            'case', 'do', 'done', 'elif', 'else', 'esac', 'fi', 'for', 'function',
            'if', 'in', 'select', 'set', 'then', 'until', 'while', 'time'
            ),
        2 => array(
            'aclocal', 'aconnect', 'aplay', 'apm', 'apmsleep', 'apropos',
            'apt-cache', 'apt-file', 'apt-get', 'apt-key', 'apt-src', 'aptitude',
            'ar', 'arch', 'arecord', 'as', 'as86', 'ash', 'autoconf',
            'autoheader', 'automake', 'awk',

            'basename', 'bash', 'bc', 'bison', 'bunzip2', 'bzcat',
            'bzcmp', 'bzdiff', 'bzegrep', 'bzfgrep', 'bzgrep',
            'bzip2', 'bzip2recover', 'bzless', 'bzmore',

            'c++', 'cal', 'cat', 'chattr', 'cc', 'cdda2wav', 'cdparanoia',
            'cdrdao', 'cd-read', 'cdrecord', 'chfn', 'chgrp', 'chmod',
            'chown', 'chroot', 'chsh', 'chvt', 'clear', 'cmp', 'comm', 'co',
            'col', 'cp', 'cpio', 'cpp', 'csh', 'cut', 'cvs', 'cvs-pserver',

            'dash', 'date', 'dc', 'dch', 'dcop', 'dd', 'ddate', 'ddd',
            'deallocvt', 'debconf', 'defoma', 'depmod', 'df', 'dh',
            'dialog', 'diff', 'diff3', 'dig', 'dir', 'dircolors', 'directomatic',
            'dirname', 'dmesg', 'dnsdomainname', 'domainname', 'dpkg',
            'dselect', 'du', 'dumpkeys',

            'ed', 'egrep', 'env', 'expr',

            'false', 'fbset', 'ffmpeg', 'fgconsole','fgrep', 'file', 'find',
            'flex', 'flex++', 'fmt', 'free', 'ftp', 'funzip', 'fuser',

            'g++', 'gawk', 'gc','gcc', 'gdb', 'getent', 'getkeycodes',
            'getopt', 'gettext', 'gettextize', 'gimp', 'gimp-remote',
            'gimptool', 'gmake', 'gocr', 'grep', 'groups', 'gs', 'gunzip',
            'gzexe', 'gzip',

            'git', 'gitaction', 'git-add', 'git-add--interactive', 'git-am',
            'git-annotate', 'git-apply', 'git-archive', 'git-bisect',
            'git-bisect--helper', 'git-blame', 'git-branch', 'git-bundle',
            'git-cat-file', 'git-check-attr', 'git-checkout',
            'git-checkout-index', 'git-check-ref-format', 'git-cherry',
            'git-cherry-pick', 'git-clean', 'git-clone', 'git-commit',
            'git-commit-tree', 'git-config', 'git-count-objects', 'git-daemon',
            'git-describe', 'git-diff', 'git-diff-files', 'git-diff-index',
            'git-difftool', 'git-difftool--helper', 'git-diff-tree',
            'gitdpkgname', 'git-fast-export', 'git-fast-import', 'git-fetch',
            'git-fetch-pack', 'git-fetch--tool', 'git-filter-branch', 'gitfm',
            'git-fmt-merge-msg', 'git-for-each-ref', 'git-format-patch',
            'git-fsck', 'git-fsck-objects', 'git-gc', 'git-get-tar-commit-id',
            'git-grep', 'git-hash-object', 'git-help', 'git-http-fetch',
            'git-http-push', 'git-imap-send', 'git-index-pack', 'git-init',
            'git-init-db', 'git-instaweb', 'gitkeys', 'git-log',
            'git-lost-found', 'git-ls-files', 'git-ls-remote', 'git-ls-tree',
            'git-mailinfo', 'git-mailsplit', 'git-merge', 'git-merge-base',
            'git-merge-file', 'git-merge-index', 'git-merge-octopus',
            'git-merge-one-file', 'git-merge-ours', 'git-merge-recursive',
            'git-merge-resolve', 'git-merge-subtree', 'git-mergetool',
            'git-mergetool--lib', 'git-merge-tree', 'gitmkdirs', 'git-mktag',
            'git-mktree', 'gitmount', 'git-mv', 'git-name-rev',
            'git-pack-objects', 'git-pack-redundant', 'git-pack-refs',
            'git-parse-remote', 'git-patch-id', 'git-peek-remote', 'git-prune',
            'git-prune-packed', 'gitps', 'git-pull', 'git-push',
            'git-quiltimport', 'git-read-tree', 'git-rebase',
            'git-rebase--interactive', 'git-receive-pack', 'git-reflog',
            'gitregrep', 'git-relink', 'git-remote', 'git-repack',
            'git-repo-config', 'git-request-pull', 'git-rerere', 'git-reset',
            'git-revert', 'git-rev-list', 'git-rev-parse', 'gitrfgrep',
            'gitrgrep', 'git-rm', 'git-send-pack', 'git-shell', 'git-shortlog',
            'git-show', 'git-show-branch', 'git-show-index', 'git-show-ref',
            'git-sh-setup', 'git-stage', 'git-stash', 'git-status',
            'git-stripspace', 'git-submodule', 'git-svn', 'git-symbolic-ref',
            'git-tag', 'git-tar-tree', 'gitunpack', 'git-unpack-file',
            'git-unpack-objects', 'git-update-index', 'git-update-ref',
            'git-update-server-info', 'git-upload-archive', 'git-upload-pack',
            'git-var', 'git-verify-pack', 'git-verify-tag', 'gitview',
            'git-web--browse', 'git-whatchanged', 'gitwhich', 'gitwipe',
            'git-write-tree', 'gitxgrep',

            'head', 'hexdump', 'hostname',

            'id', 'ifconfig', 'ifdown', 'ifup', 'igawk', 'install',

            'join',

            'kbd_mode','kbdrate', 'kdialog', 'kfile', 'kill', 'killall',

            'lame', 'last', 'lastb', 'ld', 'ld86', 'ldd', 'less', 'lex', 'link',
            'ln', 'loadkeys', 'loadunimap', 'locate', 'lockfile', 'login',
            'logname', 'lp', 'lpr', 'ls', 'lsattr', 'lsmod', 'lsmod.old',
            'lspci', 'ltrace', 'lynx',

            'm4', 'make', 'man', 'mapscrn', 'mesg', 'mkdir', 'mkfifo',
            'mknod', 'mktemp', 'more', 'mount', 'mplayer', 'msgfmt', 'mv',

            'namei', 'nano', 'nasm', 'nawk', 'netstat', 'nice',
            'nisdomainname', 'nl', 'nm', 'nm86', 'nmap', 'nohup', 'nop',

            'od', 'openvt',

            'passwd', 'patch', 'pcregrep', 'pcretest', 'perl', 'perror',
            'pgawk', 'pidof', 'ping', 'pr', 'procmail', 'prune', 'ps', 'pstree',
            'ps2ascii', 'ps2epsi', 'ps2frag', 'ps2pdf', 'ps2ps', 'psbook',
            'psmerge', 'psnup', 'psresize', 'psselect', 'pstops',

            'rbash', 'rcs', 'rcs2log', 'read', 'readlink', 'red', 'resizecons',
            'rev', 'rm', 'rmdir', 'rsh', 'run-parts',

            'sash', 'scp', 'screen', 'sed', 'seq', 'sendmail', 'setfont',
            'setkeycodes', 'setleds', 'setmetamode', 'setserial', 'setterm',
            'sh', 'showkey', 'shred', 'size', 'size86', 'skill', 'sleep',
            'slogin', 'snice', 'sort', 'sox', 'split', 'ssed', 'ssh', 'ssh-add',
            'ssh-agent', 'ssh-keygen', 'ssh-keyscan', 'stat', 'strace',
            'strings', 'strip', 'stty', 'su', 'sudo', 'suidperl', 'sum', 'svn',
            'svnadmin', 'svndumpfilter', 'svnlook', 'svnmerge', 'svnmucc',
            'svnserve', 'svnshell', 'svnsync', 'svnversion', 'svnwrap', 'sync',

            'tac', 'tail', 'tar', 'tee', 'tempfile', 'touch', 'tr', 'tree',
            'true',

            'umount', 'uname', 'unicode_start', 'unicode_stop', 'uniq',
            'unlink', 'unzip', 'updatedb', 'updmap', 'uptime', 'users',
            'utmpdump', 'uuidgen',

            'valgrind', 'vdir', 'vi', 'vim', 'vmstat',

            'w', 'wall', 'watch', 'wc', 'wget', 'whatis', 'whereis',
            'which', 'whiptail', 'who', 'whoami', 'whois', 'wine', 'wineboot',
            'winebuild', 'winecfg', 'wineconsole', 'winedbg', 'winedump',
            'winefile', 'wodim', 'write',

            'xargs', 'xhost', 'xmodmap', 'xset',

            'yacc', 'yes', 'ypdomainname',

            'zcat', 'zcmp', 'zdiff', 'zdump', 'zegrep', 'zfgrep', 'zforce',
            'zgrep', 'zip', 'zipgrep', 'zipinfo', 'zless', 'zmore', 'znew',
            'zsh', 'zsoelim'
            ),
        3 => array(
            'alias', 'bg', 'bind', 'break', 'builtin', 'cd', 'command',
            'compgen', 'complete', 'continue', 'declare', 'dirs', 'disown',
            'echo', 'enable', 'eval', 'exec', 'exit', 'export', 'fc',
            'fg', 'getopts', 'hash', 'help', 'history', 'jobs', 'let',
            'local', 'logout', 'popd', 'printf', 'pushd', 'pwd', 'readonly',
            'return', 'shift', 'shopt', 'source', 'suspend', 'test', 'times',
            'trap', 'type', 'typeset', 'ulimit', 'umask', 'unalias', 'unset',
            'wait'
            )
        ),
    'SYMBOLS' => array(
        '(', ')', '[', ']', '!', '@', '%', '&', '*', '|', '/', '<', '>', ';;', '`'
        ),
    'CASE_SENSITIVE' => array(
        GESHI_COMMENTS => false,
        1 => true,
        2 => true,
        3 => true
        ),
    'STYLES' => array(
        'KEYWORDS' => array(
            1 => 'color: #000000; font-weight: bold;',
            2 => 'color: #c20cb9; font-weight: bold;',
            3 => 'color: #7a0874; font-weight: bold;'
            ),
        'COMMENTS' => array(
            0 => 'color: #666666; font-style: italic;',
            1 => 'color: #800000;',
            2 => 'color: #cc0000; font-style: italic;',
            3 => 'color: #000000; font-weight: bold;'
            ),
        'ESCAPE_CHAR' => array(
            1 => 'color: #000099; font-weight: bold;',
            2 => 'color: #007800;',
            3 => 'color: #007800;',
            4 => 'color: #007800;',
            5 => 'color: #780078;',
            'HARD' => 'color: #000099; font-weight: bold;'
            ),
        'BRACKETS' => array(
            0 => 'color: #7a0874; font-weight: bold;'
            ),
        'STRINGS' => array(
            0 => 'color: #ff0000;',
            'HARD' => 'color: #ff0000;'
            ),
        'NUMBERS' => array(
            0 => 'color: #000000;'
            ),
        'METHODS' => array(
            ),
        'SYMBOLS' => array(
            0 => 'color: #000000; font-weight: bold;'
            ),
        'REGEXPS' => array(
            0 => 'color: #007800;',
            1 => 'color: #007800;',
            2 => 'color: #007800;',
            4 => 'color: #007800;',
            5 => 'color: #660033;'
            ),
        'SCRIPT' => array(
            )
        ),
    'URLS' => array(
        1 => '',
        2 => '',
        3 => ''
        ),
    'OOLANG' => false,
    'OBJECT_SPLITTERS' => array(
        ),
    'REGEXPS' => array(
        //Variables (will be handled by comment_regexps)
        0 => "\\$\\{[a-zA-Z_][a-zA-Z0-9_]*?\\}",
        //Variables without braces
        1 => "\\$[a-zA-Z_][a-zA-Z0-9_]*",
        //Variable assignment
        2 => "(?<![\.a-zA-Z_\-])([a-zA-Z_][a-zA-Z0-9_]*?)(?==)",
        //Shorthand shell variables
        4 => "\\$[*#\$\\-\\?!\d]",
        //Parameters of commands
        5 => "(?<=\s)--?[0-9a-zA-Z\-]+(?=[\s=]|<(?:SEMI|PIPE)>|$)"
        ),
    'STRICT_MODE_APPLIES' => GESHI_NEVER,
    'SCRIPT_DELIMITERS' => array(
        ),
    'HIGHLIGHT_STRICT_BLOCK' => array(
        ),
    'TAB_WIDTH' => 4,
    'PARSER_CONTROL' => array(
        'COMMENTS' => array(
            'DISALLOWED_BEFORE' => '$'
        ),
        'KEYWORDS' => array(
            'DISALLOWED_BEFORE' => "(?<![\.\-a-zA-Z0-9_\$\#])",
            'DISALLOWED_AFTER' =>  "(?![\.\-a-zA-Z0-9_%=\\/])"
        )
    )
);

?>