#!/bin/bash
script_share_space_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))
_share_var_space=



shareVar.export(){
    declare -p "$@" >>"$_share_var_space"
}

# import var_1 var_2 .... (or empty args)
# If there are arguments, it will only import existing variables. Otherwise, it imports all variables
#If a variable exists, it will override its value. Those. can override local variables.
# If the variable does not exist, will create a global variable
#Warn: The user must take care to match the types of existing variables
shareVar.import() {
    local vars="$@"
    ##This behavior is necessary when you need to free up space immediately. But why?
    #local import_vars=$(cat "$_share_var_space")
    #>"$_share_var_space"
    local import_var import_var_name
    local to_source=
    while IFS= read -r line; do
        import_var="$(echo "$line" | sed -r 's/^declare (-.)+ //')"
        import_var_name="$(echo "$import_var" | grep -oP '^.+?(?==|\s*$)')"
        if [[ -z "$vars" || ! -z "$(echo "$vars" | grep -oP "(?:^|\s)$import_var_name(?:$|\s)")" ]]; then
            if [ -v $import_var_name ] || declare -p "$import_var_name" &>/dev/null; then
            [[ ! $import_var =~ "=" ]] &&  import_var="$import_var="
                to_source="$to_source\n$import_var"
            else
                to_source="$to_source\n$(echo "$line" | sed -r 's/^declare /declare -g /')"
            fi
        fi
    done <"$_share_var_space"
    >"$_share_var_space"
    to_source="$(echo "$to_source" | sed 's/\\n/\n/g')"
    [ ! -z "$to_source" ] && source <(echo "$to_source")
}

#Initializes space (file) for variables
#If a script is called by a parent script via pipe, it will try to set the variable space file from stdin.  
#Set at the beginning of the called script
# $1 default variable space(file). If not specified, it will be generated randomly.Applies if variable space is not specified via pipe
shareVar.initSpace(){
    local default="$1"
    if [ -z "$default" ]
    then
        default="$(mktemp -u)"
    fi
    local var_space="$(shareVar.externalSpace)"
    if [[ -z "$var_space" ]]
    then
        var_space="$default"
    fi
    shareVar.setSpace "$var_space"
}


shareVar.setSpace(){
    _share_var_space="$(readlink -f  "$1")"
    touch "$_share_var_space"
}

#extracts path space (file) from pipe
shareVar.externalSpace(){
    if [ -p "/dev/stdin" ]
    then
        path="$(head -n 1 "/dev/stdin" )"
        if [ ! -z "$(echo "$path"|grep '^var_space:')" ]
        then
            echo "$path"| cut -d':' -f2
        fi
    fi
}
# Declares the default variable space
# must be declared at the very beginning of the script, or before the first lines are printed.
# must also be declared at the beginning of the pipe if the child script needs to specify the current variable space
#$1 - If specified, set the default variable space.

shareVar.declareSpace(){
    if [[ ! -z "$1" ]]
    then
        shareVar.setSpace "$1"
    fi
    echo "var_space:$_share_var_space"
}

shareVar.space(){
    shareVar.declareSpace $@
}


shareVar(){
    "shareVar.$@"
    return $?
}
