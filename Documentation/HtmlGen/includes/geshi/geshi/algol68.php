<?php
/**
 * algol68.php
 * --------
 * Author: Neville Dempsey (NevilleD.sourceforge@sgr-a.net)
 * Copyright: (c) 2010 Neville Dempsey (https://sourceforge.net/projects/algol68/files/)
 * Release Version: v.v.v.v
 * Date Started: 2010/04/24
 *
 * ALGOL 68 language file for GeSHi.
 *
 * CHANGES
 * -------
 * yyyy/mm/dd (v.v.v.v)
 *   -  First Release
 *
 * TODO (updated yyyy/mm/dd)
 * -------------------------
 *
 *
 *
 *
 *      This file is part of GeSHi.
 *
 *    GeSHi is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    GeSHi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with GeSHi; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

$language_data = array(
    'LANG_NAME' => 'ALGOL 68',
    'COMMENT_SINGLE' => array(),
    'COMMENT_MULTI' => array(
        '#' => '#',
        '¢' => '¢',
        '£' => '£',
        ),
    'COMMENT_REGEXP' => array(
        1 => '/\bCO((?:MMENT)?)\b.*?\bCO\\1\b/i',
        2 => '/\bPR((?:AGMAT)?)\b.*?\bPR\\1\b/i',
        3 => '/\bQUOTE\b.*?\bQUOTE\b/i'
        ),
    'CASE_KEYWORDS' => GESHI_CAPS_NO_CHANGE,
    'QUOTEMARKS' => array('"'),
    'ESCAPE_CHAR' => '"',
    'KEYWORDS' => array(
        1 => array('KEEP', 'FINISH', 'USE', 'SYSPROCS', 'IOSTATE', 'USING', 'ENVIRON'),
        2 => array('CASE', 'IN', 'OUSE', 'IN', 'OUT', 'ESAC', '(', '|', '|:', ')', 'FOR', 'FROM', 'TO', 'BY', 'WHILE', 'DO', 'OD', 'IF', 'THEN', 'ELIF', 'THEN', 'ELSE', 'FI', 'PAR', 'BEGIN', 'EXIT', 'END', 'GO', 'GOTO', 'FORALL', 'UPTO', 'DOWNTO', 'FOREACH', 'ASSERT'),
        3 => array('BITS', 'BOOL', 'BYTES', 'CHAR', 'COMPL', 'INT', 'REAL', 'SEMA', 'STRING', 'VOID', 'COMPLEX', 'VECTOR'),
        4 => array('MODE', 'OP', 'PRIO', 'PROC'),
        5 => array('FLEX', 'HEAP', 'LOC', 'LONG', 'REF', 'SHORT', 'EITHER'),
        6 => array('CHANNEL', 'FILE', 'FORMAT', 'STRUCT', 'UNION'),
        7 => array('OF', 'AT', '@', 'IS', ':=:', 'ISNT', ':/=:', ':≠:', 'CTB', 'CT', '::', 'CTAB', '::=', 'TRUE', 'FALSE', 'EMPTY', 'NIL', '○', 'SKIP', '~'),
        8 => array('NOT', 'UP', 'DOWN', 'LWB', 'UPB', '-', 'ABS', 'ARG', 'BIN', 'ENTIER', 'LENG', 'LEVEL', 'ODD', 'REPR', 'ROUND', 'SHORTEN', 'CONJ', 'SIGN'),
        9 => array('¬', '↑', '↓', '⌊', '⌈', '~', '⎩', '⎧'),
        10 => array('+*', 'I', '+×', '⊥', '!', '⏨'),
        11 => array('SHL', 'SHR', '**', 'UP', 'DOWN', 'LWB', 'UPB', '↑', '↓', '⌊', '⌈', '⎩', '⎧'),
        12 => array('*', '/', '%', 'OVER', '%*', 'MOD', 'ELEM', '×', '÷', '÷×', '÷*', '%×', '□', '÷:'),
        13 => array('-', '+'),
        14 => array('<', 'LT', '<=', 'LE', '>=', 'GE', '>', 'GT', '≤', '≥'),
        15 => array('=', 'EQ', '/=', 'NE', '≠', '~='),
        16 => array('&', 'AND', '∧', 'OR', '∨'),
        17 => array('MINUSAB', 'PLUSAB', 'TIMESAB', 'DIVAB', 'OVERAB', 'MODAB', 'PLUSTO'),
        18 => array('-:=', '+:=', '*:=', '/:=', '%:=', '%*:=', '+=:', '×:=', '÷:=', '÷×:=', '÷*:=', '%×:=', '÷::=', 'MINUS', 'PLUS', 'DIV', 'MOD', 'PRUS'),
        19 => array('THEF', 'ANDF', 'ORF', 'ANDTH', 'OREL', 'ANDTHEN', 'ORELSE'),
        20 => array('int_lengths', 'intlengths', 'int_shorths', 'intshorths', 'max_int', 'maxint', 'real_lengths', 'reallengths', 'real_shorths', 'realshorths', 'bits_lengths', 'bitslengths', 'bits_shorths', 'bitsshorths', 'bytes_lengths', 'byteslengths', 'bytes_shorths', 'bytesshorths', 'max_abs_char', 'maxabschar', 'int_width', 'intwidth', 'long_int_width', 'longintwidth', 'long_long_int_width', 'longlongintwidth', 'real_width', 'realwidth', 'long_real_width', 'longrealwidth', 'long_long_real_width', 'longlongrealwidth', 'exp_width', 'expwidth', 'long_exp_width', 'longexpwidth', 'long_long_exp_width', 'longlongexpwidth', 'bits_width', 'bitswidth', 'long_bits_width', 'longbitswidth', 'long_long_bits_width', 'longlongbitswidth', 'bytes_width', 'byteswidth', 'long_bytes_width', 'longbyteswidth', 'max_real', 'maxreal', 'small_real', 'smallreal', 'long_max_int', 'longmaxint', 'long_long_max_int', 'longlongmaxint', 'long_max_real', 'longmaxreal', 'long_small_real', 'longsmallreal', 'long_long_max_real', 'longlongmaxreal', 'long_long_small_real', 'longlongsmallreal', 'long_max_bits', 'longmaxbits', 'long_long_max_bits', 'longlongmaxbits', 'null_character', 'nullcharacter', 'blank', 'flip', 'flop', 'error_char', 'errorchar', 'exp_char', 'expchar', 'newline_char', 'newlinechar', 'formfeed_char', 'formfeedchar', 'tab_char', 'tabchar'),
        21 => array('stand_in_channel', 'standinchannel', 'stand_out_channel', 'standoutchannel', 'stand_back_channel', 'standbackchannel', 'stand_draw_channel', 'standdrawchannel', 'stand_error_channel', 'standerrorchannel'),
        22 => array('put_possible', 'putpossible', 'get_possible', 'getpossible', 'bin_possible', 'binpossible', 'set_possible', 'setpossible', 'reset_possible', 'resetpossible', 'reidf_possible', 'reidfpossible', 'draw_possible', 'drawpossible', 'compressible', 'on_logical_file_end', 'onlogicalfileend', 'on_physical_file_end', 'onphysicalfileend', 'on_line_end', 'onlineend', 'on_page_end', 'onpageend', 'on_format_end', 'onformatend', 'on_value_error', 'onvalueerror', 'on_open_error', 'onopenerror', 'on_transput_error', 'ontransputerror', 'on_format_error', 'onformaterror', 'open', 'establish', 'create', 'associate', 'close', 'lock', 'scratch', 'space', 'new_line', 'newline', 'print', 'write_f', 'writef', 'print_f', 'printf', 'write_bin', 'writebin', 'print_bin', 'printbin', 'read_f', 'readf', 'read_bin', 'readbin', 'put_f', 'putf', 'get_f', 'getf', 'make_term', 'maketerm', 'make_device', 'makedevice', 'idf', 'term', 'read_int', 'readint', 'read_long_int', 'readlongint', 'read_long_long_int', 'readlonglongint', 'read_real', 'readreal', 'read_long_real', 'readlongreal', 'read_long_long_real', 'readlonglongreal', 'read_complex', 'readcomplex', 'read_long_complex', 'readlongcomplex', 'read_long_long_complex', 'readlonglongcomplex', 'read_bool', 'readbool', 'read_bits', 'readbits', 'read_long_bits', 'readlongbits', 'read_long_long_bits', 'readlonglongbits', 'read_char', 'readchar', 'read_string', 'readstring', 'print_int', 'printint', 'print_long_int', 'printlongint', 'print_long_long_int', 'printlonglongint', 'print_real', 'printreal', 'print_long_real', 'printlongreal', 'print_long_long_real', 'printlonglongreal', 'print_complex', 'printcomplex', 'print_long_complex', 'printlongcomplex', 'print_long_long_complex', 'printlonglongcomplex', 'print_bool', 'printbool', 'print_bits', 'printbits', 'print_long_bits', 'printlongbits', 'print_long_long_bits', 'printlonglongbits', 'print_char', 'printchar', 'print_string', 'printstring', 'whole', 'fixed', 'float'),
        23 => array('pi', 'long_pi', 'longpi', 'long_long_pi', 'longlongpi'),
        24 => array('sqrt', 'curt', 'cbrt', 'exp', 'ln', 'log', 'sin', 'arc_sin', 'arcsin', 'cos', 'arc_cos', 'arccos', 'tan', 'arc_tan', 'arctan', 'long_sqrt', 'longsqrt', 'long_curt', 'longcurt', 'long_cbrt', 'longcbrt', 'long_exp', 'longexp', 'long_ln', 'longln', 'long_log', 'longlog', 'long_sin', 'longsin', 'long_arc_sin', 'longarcsin', 'long_cos', 'longcos', 'long_arc_cos', 'longarccos', 'long_tan', 'longtan', 'long_arc_tan', 'longarctan', 'long_long_sqrt', 'longlongsqrt', 'long_long_curt', 'longlongcurt', 'long_long_cbrt', 'longlongcbrt', 'long_long_exp', 'longlongexp', 'long_long_ln', 'longlongln', 'long_long_log', 'longlonglog', 'long_long_sin', 'longlongsin', 'long_long_arc_sin', 'longlongarcsin', 'long_long_cos', 'longlongcos', 'long_long_arc_cos', 'longlongarccos', 'long_long_tan', 'longlongtan', 'long_long_arc_tan', 'longlongarctan'),
        25 => array('first_random', 'firstrandom', 'next_random', 'nextrandom', 'long_next_random', 'longnextrandom', 'long_long_next_random', 'longlongnextrandom'),
        26 => array('real', 'bits_pack', 'bitspack', 'long_bits_pack', 'longbitspack', 'long_long_bits_pack', 'longlongbitspack', 'bytes_pack', 'bytespack', 'long_bytes_pack', 'longbytespack', 'char_in_string', 'charinstring', 'last_char_in_string', 'lastcharinstring', 'string_in_string', 'stringinstring'),
        27 => array('utc_time', 'utctime', 'local_time', 'localtime', 'argc', 'argv', 'get_env', 'getenv', 'reset_errno', 'reseterrno', 'errno', 'strerror'),
        28 => array('sinh', 'long_sinh', 'longsinh', 'long_long_sinh', 'longlongsinh', 'arc_sinh', 'arcsinh', 'long_arc_sinh', 'longarcsinh', 'long_long_arc_sinh', 'longlongarcsinh', 'cosh', 'long_cosh', 'longcosh', 'long_long_cosh', 'longlongcosh', 'arc_cosh', 'arccosh', 'long_arc_cosh', 'longarccosh', 'long_long_arc_cosh', 'longlongarccosh', 'tanh', 'long_tanh', 'longtanh', 'long_long_tanh', 'longlongtanh', 'arc_tanh', 'arctanh', 'long_arc_tanh', 'longarctanh', 'long_long_arc_tanh', 'longlongarctanh', 'arc_tan2', 'arctan2', 'long_arc_tan2', 'longarctan2', 'long_long_arc_tan2', 'longlongarctan2'),
        29 => array('complex_sqrt', 'complexsqrt', 'long_complex_sqrt', 'longcomplexsqrt', 'long_long_complex_sqrt', 'longlongcomplexsqrt', 'complex_exp', 'complexexp', 'long_complex_exp', 'longcomplexexp', 'long_long_complex_exp', 'longlongcomplexexp', 'complex_ln', 'complexln', 'long_complex_ln', 'longcomplexln', 'long_long_complex_ln', 'longlongcomplexln', 'complex_sin', 'complexsin', 'long_complex_sin', 'longcomplexsin', 'long_long_complex_sin', 'longlongcomplexsin', 'complex_arc_sin', 'complexarcsin', 'long_complex_arc_sin', 'longcomplexarcsin', 'long_long_complex_arc_sin', 'longlongcomplexarcsin', 'complex_cos', 'complexcos', 'long_complex_cos', 'longcomplexcos', 'long_long_complex_cos', 'longlongcomplexcos', 'complex_arc_cos', 'complexarccos', 'long_complex_arc_cos', 'longcomplexarccos', 'long_long_complex_arc_cos', 'longlongcomplexarccos', 'complex_tan', 'complextan', 'long_complex_tan', 'longcomplextan', 'long_long_complex_tan', 'longlongcomplextan', 'complex_arc_tan', 'complexarctan', 'long_complex_arc_tan', 'longcomplexarctan', 'long_long_complex_arc_tan', 'longlongcomplexarctan', 'complex_sinh', 'complexsinh', 'complex_arc_sinh', 'complexarcsinh', 'complex_cosh', 'complexcosh', 'complex_arc_cosh', 'complexarccosh', 'complex_tanh', 'complextanh', 'complex_arc_tanh', 'complexarctanh')
        ),
    'SYMBOLS' => array(
        1 => array(
            '(', ')', '{', '}', '[', ']', '+', '-', '*', '/', '%', '=', '<', '>', '!', '^', '&', '|', '?', ':', ';', ','
            )
        ),
    'CASE_SENSITIVE' => array(
        GESHI_COMMENTS => false,
        1 => true,
        2 => true,
        3 => true,
        4 => true,
        5 => true,
        6 => true,
        7 => true,
        8 => true,
        9 => true,
        10 => true,
        11 => true,
        12 => true,
        13 => true,
        14 => true,
        15 => true,
        16 => true,
        17 => true,
        18 => true,
        19 => true,
        20 => true,
        21 => true,
        22 => true,
        23 => true,
        24 => true,
        25 => true,
        26 => true,
        27 => true,
        28 => true,
        29 => true
        ),
    'STYLES' => array(
        'KEYWORDS' => array(
            1 => 'color: #b1b100; font-weight: bold;',
            2 => 'color: #b1b100; font-weight: bold;',
            3 => 'color: #b1b100; font-weight: bold;',
            4 => 'color: #b1b100; font-weight: bold;',
            5 => 'color: #b1b100; font-weight: bold;',
            6 => 'color: #b1b100; font-weight: bold;',
            7 => 'color: #b1b100; font-weight: bold;',
            8 => 'color: #b1b100; font-weight: bold;',
            9 => 'color: #b1b100; font-weight: bold;',
            10 => 'color: #b1b100; font-weight: bold;',
            11 => 'color: #b1b100; font-weight: bold;',
            12 => 'color: #b1b100; font-weight: bold;',
            13 => 'color: #b1b100; font-weight: bold;',
            14 => 'color: #b1b100; font-weight: bold;',
            15 => 'color: #b1b100; font-weight: bold;',
            16 => 'color: #b1b100; font-weight: bold;',
            17 => 'color: #b1b100; font-weight: bold;',
            18 => 'color: #b1b100; font-weight: bold;',
            19 => 'color: #b1b100; font-weight: bold;',
            20 => 'color: #b1b100;',
            21 => 'color: #b1b100;',
            22 => 'color: #b1b100;',
            23 => 'color: #b1b100;',
            24 => 'color: #b1b100;',
            25 => 'color: #b1b100;',
            26 => 'color: #b1b100;',
            27 => 'color: #b1b100;',
            28 => 'color: #b1b100;',
            29 => 'color: #b1b100;'
            ),
        'COMMENTS' => array(
            1 => 'color: #666666; font-style: italic;',
            2 => 'color: #666666; font-style: italic;',
            3 => 'color: #666666; font-style: italic;',
            4 => 'color: #666666; font-style: italic;',
            5 => 'color: #666666; font-style: italic;',
            'MULTI' => 'color: #666666; font-style: italic;'
            ),
        'ESCAPE_CHAR' => array(
            0 => 'color: #000099; font-weight: bold;'
            ),
        'BRACKETS' => array(
            0 => 'color: #009900;'
            ),
        'STRINGS' => array(
            0 => 'color: #0000ff;'
            ),
        'NUMBERS' => array(
            0 => 'color: #cc66cc;',
            ),
        'METHODS' => array(
            0 => 'color: #004000;'
            ),
        'SYMBOLS' => array(
            1 => 'color: #339933;'
            ),
        'REGEXPS' => array(),
        'SCRIPT' => array()
        ),
    'URLS' => array(
        1 => '',
        2 => '',
        3 => '',
        4 => '',
        5 => '',
        6 => '',
        7 => '',
        8 => '',
        9 => '',
        10 => '',
        11 => '',
        12 => '',
        13 => '',
        14 => '',
        15 => '',
        16 => '',
        17 => '',
        18 => '',
        19 => '',
        20 => '',
        21 => '',
        22 => '',
        23 => '',
        24 => '',
        25 => '',
        26 => '',
        27 => '',
        28 => '',
        29 => ''
        ),
    'OOLANG' => true,
    'OBJECT_SPLITTERS' => array(
        1 => 'OF'
        ),
    'REGEXPS' => array(),
    'STRICT_MODE_APPLIES' => GESHI_NEVER,
    'SCRIPT_DELIMITERS' => array(),
    'HIGHLIGHT_STRICT_BLOCK' => array()
);

?>