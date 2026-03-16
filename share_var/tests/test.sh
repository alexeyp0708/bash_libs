#!/bin/bash
script_path=$(dirname $(readlink -f "$0"))

#Let's declare the function shareVar
source "$script_path/../shareVar.sh"
#We define the variable space (the file through which we will exchange with other scripts)
#If the script is called via pipes, it will define the variable space via /dev/stdin
shareVar initSpace 
var_1='var_1:test'
local_var_1=
declare -A arr=([hello]="HELLO")
qwer2(){
     local var_1='local_var_1:test'
     #Exporting variables into space
     shareVar export "var_1" 
     shareVar export "arr"
#Indicate in the channel the variable space (file) for script execution. If no file is specified, the current space is used. If a file is specified, it is set as the current variable space.
     shareVar space|"./test2.sh"

     #import all variables from the current space (file)
     shareVar import
     local_var_1=$var_1
}
qwer2 
#echo "[$var_1] [$local_var_1] [$var_2] [${var_3[one]}]"

[ "$var_1" == "var_1:test" ] || echo "Error  $LINENO"
[ "$local_var_1" == "local_var_1:test|test2|test3" ] || echo "Error  $LINENO"
[ "$var_2" == "var_2:test2|test3" ] || echo "Error  $LINENO"
[ "${var_3[one]}" == "var_3:test3" ] || echo "Error $LINENO" 
[ "${arr[bay]}" == "BAY" ] || echo "Error  $LINENO"
