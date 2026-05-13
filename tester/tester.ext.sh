#!/bin/bash

script_tester_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
source $script_tester_path/tester.sh

declare -g -A _counter_test_buf=()
declare -g -A _counter_empty_test_buf=()
declare -g -A _counter_child_error_buf=()
declare -g -A _counter_child_success_buf=()
declare -g -A _counter_bad_test_buf=()

_disable_display_error=

_count_tests=0
_count_empty_tests=0
_count_bad_test=0

less_message_output=
disable_display_test_error=

export_vars="$export_vars _count_tests _count_empty_tests _count_bad_test   _counter_test_buf _counter_empty_test_buf  _counter_child_error_buf _counter_child_success_buf _counter_bad_test_buf"

_tester.onCounter() {
    local name_test="$1"
    local parent_test="${_active_tests[@]: -1}"

    if [[ -n ${_counter_success_buf[$name_test]+test} ]]; then
        echo "The $name_test test already exists. Completing the script!" >&2
        exit $FATAL_ERR
    fi
    if [ ! -z "$parent_test" ]; then
        _counter_test_buf["$parent_test"]=$_count_tests
        _counter_empty_test_buf["$parent_test"]=$_count_empty_tests
        _counter_success_buf["$parent_test"]=$_count_success
        _counter_error_buf["$parent_test"]=$_count_error
        _counter_bad_test_buf["$parent_test"]=$_count_bad_test
    fi

    _count_tests=1
    _count_empty_tests=0
    _count_success=0
    _count_error=0
    _count_bad_test=0

    _counter_test_buf["$name_test"]=$_count_tests
    _counter_empty_test_buf["$name_test"]=$_count_empty_tests
    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error
    _counter_child_error_buf["$name_test"]=$_count_error
    _counter_child_success_buf["$name_test"]=$_count_success
    _counter_bad_test_buf["$name_test"]=$_count_bad_test
}

_tester.offCounter() {
    local name_test="$1"
    #echo $name_test
    local parent_test=${_active_tests[@]: -1}

    if [[ "$_count_tests" -eq 1 && "$(($_count_success + $_count_error))" -eq 0 ]]; then
        ((++_count_empty_tests))
    fi

    if [[ "$(($_count_error - ${_counter_child_error_buf["$name_test"]}))" -ne 0 ]]; then
        ((++_count_bad_test))
    fi

    #_count_own_error="$_count_error"

    _counter_test_buf["$name_test"]=$_count_tests
    _counter_empty_test_buf["$name_test"]=$_count_empty_tests
    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error
    _counter_bad_test_buf["$name_test"]=$_count_bad_test

    if [ ! -z "$parent_test" ]; then
        _counter_test_buf["$parent_test"]=$((${_counter_test_buf["$parent_test"]} + $_count_tests))
        _counter_empty_test_buf["$parent_test"]=$((${_counter_empty_test_buf["$parent_test"]} + $_count_empty_tests))
        _counter_success_buf["$parent_test"]=$((${_counter_success_buf["$parent_test"]} + $_count_success))
        _counter_error_buf["$parent_test"]=$((${_counter_error_buf["$parent_test"]} + $_count_error))
        _counter_child_error_buf["$parent_test"]=$((${_counter_child_error_buf["$parent_test"]} + $_count_error))
        _counter_child_success_buf["$parent_test"]=$((${_counter_child_success_buf["$parent_test"]} + $_count_success))
        _counter_bad_test_buf["$parent_test"]=$((${_counter_bad_test_buf["$parent_test"]} + $_count_bad_test))
        _count_tests="${_counter_test_buf["$parent_test"]}"
        _count_empty_tests="${_counter_empty_test_buf["$parent_test"]}"
        _count_success="${_counter_success_buf["$parent_test"]}"
        _count_error="${_counter_error_buf["$parent_test"]}"
        _count_bad_test="${_counter_bad_test_buf["$parent_test"]}"

    fi
}

tester.startTest() {
    local name_test="$1"
    #[[ "${#active_tests[@]}" == "0" ]] && name_core_test="$name_test"
    local parent_test=${_active_tests[@]: -1}
    if [[ -z "$parent_test" ]]; then
        _name_core_test="$name_test"
    else
        name_test="$parent_test.$name_test"
    fi
    _trace_test["$name_test"]="$(_tester.entryPoint "tester.startTest" "tester")"
    _name_current_test="$name_test"
    _tester.onCounter "$name_test"
    _active_tests+=("$name_test")

    if [[ "$less_message_output" != "yes" ]]; then
        echo -e "\033[94m"
        echo "------------"
        echo "START: $name_test (${_trace_test["$name_test"]})"
        echo "------------"
        echo -en "\033[0m"
        #echo -e "\033[97m"
    fi
}

tester.endTest() {
    local last_error=$?
    local command=""
    [ ${1+x} ] && command=$1
    [ "${#_active_tests[@]}" -eq 0 ] && echo "Fatal error: Tests have not been completed or started" >&2 && return $FATAL_ERR
    local current_test="${_active_tests[@]: -1}"
    unset _active_tests[-1]
    local parent_test="${_active_tests[@]: -1}"
    _tester.offCounter "$current_test"
    _name_current_test="$parent_test"
    if [[ "$less_message_output" != "yes" || "$command" == "info" ]]; then
        echo -en "\033[94m"
        echo "------------"
        echo "END TEST : $current_test (${_trace_test["$current_test"]})"
        echo -en "\033[0m"
        tester.info "$current_test"
        echo -e "\033[94m------------\033[0m"
    fi
    if [[ "$(tester.amountTests "$current_test")" -le 1 && "$(tester.totalOfAsserts "$current_test")" -le 0 ]]; then
        [ "$disable_display_test_error" != "yes" ] && echo -e "(Test failure) \033[0;35m Empty \"$current_test\" test ( ${_trace_test["$current_test"]} )\033[0m" >&2
        return $TEST_ERR
    fi

    if [[ $(tester.amountOwnErrors "$current_test") -gt 0 ]]; then
        if [[ "$disable_display_test_error" != "yes" ]]; then
            echo -e "(Test failure) \033[0;35mBad \"$current_test\" test ( ${_trace_test["$current_test"]} )\033[0m" >&2
        fi
        return $TEST_ERR
    fi

    if [[ $(tester.amountErrors "$current_test") -gt 0 ]]; then
        return $TEST_ERR
    fi
    return 0
}

tester.info() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [[ -z "${_counter_success_buf[$name_test]+test}" ]]; then
        echo " Error: \"$name_test\" test is missing!" >&2
        return $FATAL_ERR
    fi
    echo -e "\033[94m"
    echo "Test $name_test (${_trace_test["$name_test"]})"
    echo "Amount of tests: [ $(tester.amountTests "$name_test") ]"
    echo "Amount of empty tests: [ $(tester.amountEmptyTests "$name_test") ]"
    echo "Amount of bad tests: [ $(tester.amountBadTests "$name_test") ]"
    echo "Amount of assert success: [ $(tester.amountSuccess "$name_test") ]"
    #echo "Amount of assert own success: [ $(tester.amountOwnSuccess "$name_test") ]"
    echo "Amount of assert errors: [ $(tester.amountErrors "$name_test") ]"
    #echo "Amount of assert own errors: [ $(tester.amountOwnErrors "$name_test") ]"
    echo "Total of asserts: [ $(tester.totalOfAsserts "$name_test") ]"
    #echo "Total of own asserts: [ $(tester.totalOfOwnAsserts "$name_test") ]"
    echo -e "\033[0m"
}

tester.totalOfOwnAsserts() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(($(tester.amountOwnErrors "$name_test") + $(tester.amountOwnSuccess "$name_test")))"
}

tester.amountBadTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_bad_test_buf["$name_test"]}"
}
tester.amountEmptyTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_empty_test_buf["$name_test"]}"
}

tester.amountTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_test_buf["$name_test"]}"
}

_tester.runFuncTest() {
    local test_file="$(readlink -f "$1")"
    shift
    local OPTIND OPTARG skip=0
    local use_strict
    while getopts ":-:s" options; do
        case "${options}" in
        s)
            use_strict="yes"
            ;;

        -)
            ((++skip))
            ;;
        esac
    done
    shift $((OPTIND - 1 - skip))

    local func func_list="$@"
    if [ -z "$func_list" ]; then
        func_list=$(declare -F | grep -Po "^declare -f \Ktest[\._][\s\S]+$")
    fi
    local func_info test_name status=0
    local ENTRY_POINT
    local file_test_name="$(basename "$test_file" | grep -Po '(?:^test[_\.-])?\K[\s\S]+?(?=\.[\w]+?$)')"
    for func in $func_list; do
        if [[ ! "$func" =~ ^test[\._] ]]; then
            continue
        fi
        shopt -s extdebug
        func_info=$(declare -F $func)
        shopt -u extdebug
        ENTRY_POINT="$(echo "$func_info" | awk '{print $3}'):$(echo "$func_info" | awk '{print $2}')"
        test_name=$(echo "$func" | grep -Po "^test[\._]\K[\S\s]+")
        tester startTest "$file_test_name.$test_name"
        ENTRY_POINT=
        $func
        status=$?
        tester endTest
        [[ "$use_strict" == "yes" && "$status" != "0" ]] && break
    done
}
