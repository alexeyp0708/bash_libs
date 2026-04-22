#! /bin/bash

script_reader_path=$(dirname $(readlink -f "$0"))

reader="$script_reader_path/../reader.sh"

is_packed="yes"
source "$script_reader_path/../reader.sh"


var="$($reader read -i "Test var 1")"
echo -e "Test var 1=>$var"

var="$($reader read -i "Test var 2" -m "yes|no")"
echo -e "Test var 2 (math)=> $var"

var="$($reader read -i "Test var 3 (math)" -m "yes|no" -d "no")"
echo -e "Test var 3 (default)=> $var"

var="$($reader read -i "Test var 4 (pattern)" -p "^[0-9]$" -d "1")"
echo -e "Test var 4 (pattern)=> $var"

var="$($reader read -i "Test var 5 (required)" -p "^[0-9]$" -r )"
echo -e "Test var 5 (required)=> $var"

var="$($reader read -i "Test var 6 (substitution)" -p "^[0-9]$" -r -s "3" )"
echo -e "Test var 6 (substitution)=> $var"

var="$($reader read -i "Test var 7 (color)" -c $'\e[32m\e[1m')"
echo -e "Test var 7 (color+bold)=> $var"

var="$($reader read -i "Test var 8 (timeout)" -o "-t 1")"
echo -e "Test var 8 (set timeout option )=> $var"

var=( $($reader read -i "Test var 9 (array)" -o "-a") )
echo -e "Test var 9 (set array)=> $var"
declare -p var

reader read -i "Test var 10" -o "-a" -v "var" 
echo -e "Test var 10 (set array)=> $var"
declare -p var
unset var

echo "end"
