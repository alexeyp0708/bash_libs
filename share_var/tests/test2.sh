#!/bin/bash
script_path=$(dirname $(readlink -f "$0"))

source "$script_path/../shareVar.sh"
shareVar initSpace
shareVar import
var_2="var_2:test2"
arr=([bay]="BAY")
qwer3(){
    shareVar export "var_1" "var_2" 
    shareVar space|"./test3.sh"
    shareVar import  
}

var_1="$var_1|test2"


qwer3

shareVar export "var_1" "var_2" "var_3" "arr"
