#!/bin/bash
script_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))
#tmppipe=$(mktemp -u)
#mkfifo $tmppipe
buf="$script_example_path/buf.log"
touch $buf
var=2
ex3.test(){
    # for import
    #[ -p /dev/stdin ] && echo "ex2:stdin pipe" >>"$buf"

    # for export
    #[ -p /dev/stdout ] && echo "ex2:stdout pipe" >>"$buf"
    tmppipe=$(mktemp -u)
    echo "$tmppipe"
    mkfifo $tmppipe
    declare -p "var" >"$tmppipe"
    source <(cat "$tmppipe")
    echo "ex3.var2=$var2">>$buf 
} 

ex3.test | "$script_example_path/example3.sh" 
echo "var2=$var2"
cat $buf

rm $buf
open
 
close
run "script"
