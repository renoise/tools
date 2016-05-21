@echo off

chcp 1252

set ldoc_dir=F:\developer\lua\ldoc\ldoc.lua
set ldoc_css_dir=%vlib_dir%\support\ldoc\css
set ldoc_output_dir=%vlib_dir%\docs\

cd %ldoc_output_dir%
lua "%ldoc_dir%" -d %ldoc_output_dir% -s "%ldoc_css_dir%" "%vlib_dir%"

PAUSE
