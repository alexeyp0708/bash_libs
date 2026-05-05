#!/bin/bash

reader.read() {
    local help="$(
        cat <<EOF
[ -s "value substitution" ] - The otion value  that will substitution an interactive value request. If the option value is not empty or equal to the default value (option -'d'), then it is subject to checking by pattern (option '-p') or matching (option '-m').  If the option value is empty, interactivity will work normally. To apply the option as an empty value, pass a three spaces -s "   ". The whole complex of this behavior is needed so that option values ​​can be passed through variables (-s "$var"). If the variable is empty, the value will be requested interactively. If the variable is not empty, or it is explicitly specified with 3 spaces (to indicate that we want to specify an empty value), then the interactive prompt for the value will not occur, and the value of this option will be applied.
[ -m  "value_1|value_2|value_3" ] - value matching (ignore case). List of values ​​that a variable should have
[ -p "posix_regex_pattern" ] - The entered variable value must match the regex(posix) pattern. Applied if the option "-" is not set
[ -r ] - required input of variable value  
[ -d "default value"] - Default value
[ -i ] - Interactive information that will be displayed
[ -o "-rptsnad" ] - Options for "read" command 
[ -c $'\color_id' ] - Color Interactive information. Example:  - green text:  -c $'\e[32m';  - green+bold text:  -c $'\e[32m\e[1m''
[ -v "name_var" ] -  If the reader participates in the script as a package (source /pathe/reader.sh), then you can specify a variable to which the value will be assigned. Then the value will not be displayed on the screen
[ -x ] - Allow receiving data via pipe
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
    local _message_ _color_ _read_options_
    local OPTIND OPTARG
    while getopts "i:d:m:p:s:c:o:v:rx" _options_; do
        case "${_options_}" in
        \?)
            echo "$help" >&2
            return 1
            ;;
        i)
            _message_="${OPTARG}"
            ;;
        d)
            local _default_="${OPTARG}"
            ;;
        m)
            local _values_="${OPTARG}"
            ;;
        p)
            local _pattern_="${OPTARG}"
            ;;
        r)
            local _required_="yes"
            ;;
        s)
            #local _substitution_="${OPTARG}"
            if [ ! -z "${OPTARG}" ]; then
                [ "${OPTARG}" == "   " ] && OPTARG=""
                local _substitution_="${OPTARG}"
            fi
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
        x)
            local allow_pipe="yes"
            ;;

        esac
    done
    if [ "$#" -eq 0 ]; then
        echo "$help" >&2
        return 1
    fi
    [ ! -z "$_values_" ] && _required_="yes"

    [[ -z "$_message_" ]] && _message_="Enter value "

    local _values_message_ _default_message_
    local _default_message_=
    if [ ! -z "$_values_" ]; then
        _values_message_="[ must match the values - $_values_ ] "
    elif [ ! -z "$_pattern_" ]; then
        _pattern_message_="[ must match the pattern value - $_pattern_ ] "
    fi

    if [[ -v _default_ ]]; then
        _default_message_="[ Default value - $_default_ ] "
    elif [[ ! -z $_required_ ]]; then
        _default_message_="[ required ] "
    fi
    local _val_ _cycle_="yes"
    local full_message="${_message_} ${_values_message_}${_pattern_message_}${_default_message_}: "
    while [ ! -z "$_cycle_" ]; do
        _cycle_=
        if [[ -v _substitution_ ]]; then
            _val_="$_substitution_"
        else

            if [[ -v allow_pipe && -p /dev/stdin ]]; then
                read -p $'\n'"${_color_}${full_message}"$'\033[0m' $_read_options_ _val_
            else
                read -p $'\n'"${_color_}${full_message}"$'\033[0m' $_read_options_ _val_ </dev/tty
            fi

            # всегда считывать с терминала

        fi
        if [[ -z "$_val_" || -v _default_ && -v _substitution_ && "$_default_" == "$_val_" ]]; then
            if [[ -v _default_ || -v _substitution_ || ! -v _required_ ]]; then
                if [ -v _default_ ]; then
                    _val_="$_default_"
                else
                    _val_=""
                fi
            else
                _cycle_="yes"
            fi
            # по хорошему в $val нужно экранировать спец символы рег выражений.
        elif [[ -v _values_ && -z "$(echo $_values_ | grep -Pi "(?:^|\|)$_val_(?:\||$)")" || -v _pattern_ && -z "$(echo "$_val_" | grep -P "$_pattern_")" ]]; then
            echo -e "\033[91mBad value '$_val_'\033[0m" >&2
            _val_=""
            _cycle_="yes"
            unset _substitution_
        fi
    done
    if [[ -v _ref_var_ ]] || declare -p "_ref_var_" &>/dev/null; then
        if [[ $(declare -p _val_ 2>/dev/null) =~ "declare -a" ]]; then
            _ref_var_=("${_val_[@]}")
        else
            _ref_var_="$_val_"
        fi

    elif [[ $(declare -p _val_ 2>/dev/null) =~ "declare -a" ]]; then
        echo ${_val_[@]}
    else
        echo $_val_
    fi
}

reader() {
    "reader.$@"
}

[ "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && reader "$@"
