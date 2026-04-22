#!/bin/bash

reader.read(){
    local help="$(cat <<EOF
[ -s "value substitution" ] - A value that will substitution an interactive value request.  If an empty field is specified, the function will operate normally
[ -m  "value_1|value_2|value_3" ] - value matching (ignore case). List of values ​​that a variable should have
[ -p "posix_regex_pattern" ] - The entered variable value must match the regex(posix) pattern. Applied if the option "-" is not set
[ -r ] - required input of variable value  
[ -d "default value"] - Default value
[ -i ] - Interactive information that will be displayed
[ -o "-rptsnad" ] - Options for "read" command 
[ -c $'\color_id' ] - Color Interactive information. Example:  - green text:  -c $'\e[32m';  - green+bold text:  -c $'\e[32m\e[1m''
[ -v "name_var" ] -  If the reader participates in the script as a package (source /pathe/reader.sh), then you can specify a variable to which the value will be assigned. Then the value will not be displayed on the screen

After execution it will display the entered value

Usage example
---
#! /bin/bash 
_is_run=yes
is_run="\$(reader read -s "\$_is_run" -i "Should I run the program?" -m "yes|no" -d "no" -r)"   
#The 'is_run' variable will automatically be set to 'yes'
---

If the '_debug' variable is specified and the -d (default) option is specified, the default value will be automatically applied without prompting for the value interactively.
EOF
)"
    local _message_ _default_ _values_ _pattern_ _required_  _color_ _read_options_ _ref_var_
    local OPTIND OPTARG
    while getopts "i:d:m:p:s:c:o:v:r" _options_; do
        case "${_options_}" in
            \?) 
                echo "$help" >&2
                return 1
            ;;
            i)
                _message_="${OPTARG}"
            ;;
            d)
                _default_="${OPTARG}"
            ;;
            m)
                 _values_="${OPTARG}"
            ;;
            p)
                _pattern_="${OPTARG}"
            ;;
            r)
                _required_="yes"
            ;;
            s)
                _substitution_="${OPTARG}"
            ;;
            c)
                _color_="${OPTARG}"
            ;;
            o)
                _read_options_="${OPTARG}"
            ;;
            v)
                declare -n _ref_var_="${OPTARG}"
            ;;

        esac
    done
    if [ "$#" -eq 0 ]
    then
        echo "$help" >&2
        return 1
    fi
    [ ! -z "$_values_" ] && _required_="yes"

    [[ -z "$_message_" ]] && _message_="Enter value "

    local _values_message_ _default_message_
    local _default_message_=
    if [ ! -z "$_values_" ] 
    then
        _values_message_="[ must match the values - $_values_ ] "
    elif [ ! -z "$_pattern_" ] 
    then
        _pattern_message_="[ must match the pattern value - $_pattern_ ] "
    fi 

    if [[ ! -z "$_default_" ]] 
    then
        _default_message_="[ Default value - $_default_ ] "
    elif [[ ! -z $_required_ ]]
    then
        _default_message_="[ required ] "
    fi
    local _val_ _cycle_="yes"
    local full_message="${_message_} ${_values_message_}${_pattern_message_}${_default_message_}: "
    while [ ! -z "$_cycle_" ] 
    do
        _cycle_=

        if [ ! -z "$_substitution_" ]
        then
            _val_="$_substitution_"
            _substitution_=""
        else 
            read -p "${_color_}${full_message}"$'\033[0m' $_read_options_ _val_
        fi

        if [ -z "$_val_" ]
        then
            if [[ ! -z "$_default_" ||  -z "$_required_"  ]]
            then
                _val_="$_default_"
            else
                _cycle_="yes"
            fi
            # по хорошему в $val нужно экранировать спец символы рег выражений.
        elif [[ ! -z "$_values_" && -z "$(echo $_values_|grep -Pi "(?:^|\|)$_val_(?:\||$)")" || ! -z "$_pattern_" && -z "$(echo "$_val_"|grep -P "$_pattern_")" ]]
        then
            echo -e "\033[91mBad value '$_val_'\033[0m" >&2
            _val_=""
            _cycle_="yes"
        fi    
    done 
    if [[ "$(declare -p _ref_var_ 2>/dev/null)" =~ "declare -n" ]]
    then
        if [[ $(declare -p _val_ 2>/dev/null) =~ "declare -a" ]]
        then
            _ref_var_=("${_val_[@]}")
        else 
            _ref_var_="$_val_"
        fi
        
    elif [[ $(declare -p _val_ 2>/dev/null) =~ "declare -a" ]]
    then
        echo ${_val_[@]}
    else
        echo $_val_
    fi
}

reader(){
    "reader.$@"
}

if [ -z "$is_packed" ]
then
    reader "$@"    
fi
