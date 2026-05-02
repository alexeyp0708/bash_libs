#! /bin/bash

script_reader_path=$(dirname $(readlink -f "$0"))

reader="$script_reader_path/../reader.sh"

is_packed="yes"
source "$script_reader_path/../reader.sh"

#var="$($reader read -i "Test var 1")"
#var="$($reader read -i "Test var 1")"
[ -p /dev/stdin ] && echo "pipe"
[ -s /dev/stdin ] && echo "socket"
[  -t 0 ] && echo "terminal"

var="$($reader read -x -i "Test var 1" <<< "test")"
[ "$var" != "test" ] && echo "${LINENO} [ "$var" != "test" ]"

var="$($reader read  -x  -i "Test var 2" -m "yes|no" <<<"yes")"
[ "$var" != "yes" ] && echo "${LINENO} [ "$var" != "test" ]"

var="$($reader read  -x  -i "Test var 3 (math)" -m "yes|no" -d "no" <<< "")"
[ "$var" != "no" ] && echo "${LINENO} [ "$var" != "no" ]"

var="$($reader read   -x -i "Test var 4 (pattern)" -p "^[0-9]$" -d "1" <<< "15")"
[ "$var" != "1" ] && echo "${LINENO} [ "$var" != "1" ]"

var="$($reader read  -x  -i "Test var 5 (required)" -p "^[0-9]$" -r <<< "1")"
[ "$var" != "1" ] && echo "${LINENO} [ "$var" != "1" ]"

var="$($reader read  -x  -i "Test var 6 (substitution)" -p "^[0-9]$" -r -s "3" )"
[ "$var" != "3" ] && echo "${LINENO} [ "$var" != "3" ]"

var="$($reader read  -x  -i "Test var 6-1" -r -s "" <<< qwer)"
[ "$var" != "qwer" ] && echo "${LINENO} [ "$var" != "qwer" ]"

var="$($reader read  -x  -i "Test var 6-1" -r -s "   ")"
[ ! -z "$var" ] && echo "${LINENO} [ ! -z "$var" ]"

var="$($reader read  -x -i "Test var 7 (color)" -c $'\e[32m\e[1m' <<< "any text")"
[ "$var" != "any text" ] && echo "[${LINENO} "$var" != "any text" ]"

var="$($reader read  -x  -i "Test var 8 (timeout)" -d "qwer" -o "-t 1")"
[ "$var" != "qwer" ] && echo "[${LINENO} "$var" != "qwer" ]"

var=( $($reader read  -x  -i "Test var 9 (array)" -o "-a" <<< "one two") )
[[ "${var[@]}" != "one two" ]] && echo "${LINENO} [ "${var[@]}" != "one two" ]"

declare -a var
reader read  -x -i "Test var 10" -o "-a" -v "var" <<< "one two"
[[ "${var[@]}" != "one two" ]] && echo "${LINENO} [ "${var[@]}" != "one two" ]"
unset var
var=
#echo "qwer"|reader read -i "hello" -v "var"

echo "end"
