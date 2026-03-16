#!/bin/bash
script_path=$(dirname $(readlink -f "$0"))

source "$script_path/../shareVar.sh"
shareVar initSpace
shareVar import
var_1="$var_1|test3"
var_2="$var_2|test3"
declare -A var_3=([one]="var_3:test3")
shareVar export "var_1" "var_2" "var_3"
