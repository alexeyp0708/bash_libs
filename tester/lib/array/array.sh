#!/bin/bash


array.formatCode(){
    echo "$@"|grep -Po '^(?:declare[\S\s]*?=)?\K[\s\S]*$'
}
array.print(){
    #declare -n var="$1"
    array.formatCode $(declare -p "$1")
}

array.codeToArray(){
    local var_name=$1
    shift
    if [ ! -v $var_name ] && ! declare -p $var_name &>/dev/null;
    then
        declare -g -A $var_name 
    fi 
    source <(echo "$var_name=$@")
}

# array optionsToArray array_name -o "opt1=long str" -o "opt2=long str"
# result $array_name=(...)
array.optionsToArray(){
    local var_name=$1
    shift
    if [ ! -v "$var_name" ] && ! declare -p $var_name &>/dev/null;
    then
        declare -g -A $var_name
    fi 
    declare -n ref_arr=$var_name
    local ARGS="$@"
    source <(echo "set -- $ARGS")
    local OPTIND OPTARG opt_name opt_value index=0
    
    while getopts "o:" option; do
        case "${option}" in
        o)
            #OPTARG="$(echo ${OPTARG}|grep -Po "(?'q'^['\"]*)\K[\s\S]+(?=\k'q'$)")"
            opt_name="$(echo "${OPTARG}" | grep -oP '^(?:[\w\.\-]+(?=\s*\=))?')"
            opt_value="$(echo "${OPTARG}" | grep -oP '^(?:[\w\.\-]+\s*=)?\K[\s\S]*')"
            if [ -z "$opt_name" ]
            then
                opt_name="$index"
            fi
            if [[ "$(declare -p $var_name 2>/dev/null)" == "declare -A"* ]]
            then
                ref_arr[$opt_name]="$opt_value"
            else
                ref_arr+=( "$opt_value" )
            fi
            (( ++index ))
            ;;
        esac
    done
}
# array ArrayToOptions  array_name
# result  -o "opt1=long str" -o "opt2=long str"
# result  -o "long str" -o "long str"
array.ArrayToOptions(){
    local key var_name="$1" options_str=
    shift
    declare -n ref_arr=$var_name
    local keys=( $(IFS=$'\n' && echo "${!ref_arr[*]}"|sort -n) )
    for key in "${keys[@]}" 
    do
        if [[ "$key" =~ ^[0-9]+$ ]]
        then
            options_str="$options_str -o '${ref_arr[$key]}'"            
        else
            options_str="$options_str -o '$key=${ref_arr[$key]}'"
        fi
    done
    echo $options_str
}

# array optionsToArrayCode array_name -o "opt1=long str" -o "opt2=long str"
# result array_name=(["opt"]="long str"....)
array.optionsToArrayCode(){
    local var_name=$1
    shift
    declare -A options
    options=()
    array.optionsToArray options "$@"
    echo "$var_name=$(array.print options)"
}

# array ArrayCodeToOptions [-Aa]  "[declare [-Aag] array_name=](["opt"]="long str"....)"
# # result  -o "opt1=long str" -o "opt2=long str"
array.ArrayCodeToOptions(){
    local code="$(array.formatCode $@)"
    shift
    declare -A options
    source <(echo "options=$code")
    array.ArrayToOptions options
}

array() {
    "array.$@"
}

[ "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && array "$@"
