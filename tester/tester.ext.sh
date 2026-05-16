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

_tester_onCounter() {
    local name_test="$1"
    local parent_test="${_tester_activeTests[@]: -1}"

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

_tester_offCounter() {
    local name_test="$1"
    #echo $name_test
    local parent_test=${_tester_activeTests[@]: -1}

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

tester_startTest() {
    local name_test="$1"
    #[[ "${#active_tests[@]}" == "0" ]] && name_core_test="$name_test"
    local parent_test=${_tester_activeTests[@]: -1}
    if [[ -z "$parent_test" ]]; then
        _name_core_test="$name_test"
    else
        name_test="$parent_test.$name_test"
    fi
    _trace_test["$name_test"]="$(_tester_entryPoint "tester_startTest" "tester")"
    _name_current_test="$name_test"
    _tester_onCounter "$name_test"
    _tester_activeTests+=("$name_test")
    _tester_print "test.start" "$name_test (${_trace_test["$name_test"]})"
}

tester_endTest() {
    local last_error=$?
    local command=""
    [ ${1+x} ] && command=$1
    [ "${#_tester_activeTests[@]}" -eq 0 ] && _tester_print "error" "Fatal error: Tests have not been completed or started" && return $FATAL_ERR
    local current_test="${_tester_activeTests[@]: -1}"
    unset _tester_activeTests[-1]
    local parent_test="${_tester_activeTests[@]: -1}"
    _tester_offCounter "$current_test"
    _name_current_test="$parent_test"
    _tester_print "test.end" "$(tester_info "$current_test")"
 
    if [[ "$(tester_amountTests "$current_test")" -le 1 && "$(tester_totalOfAsserts "$current_test")" -le 0 ]]; then
        _tester_print "error.test" "Empty \"$current_test\" test ( ${_trace_test["$current_test"]} )"
        return $TEST_ERR
    fi

    if [[ $(tester_amountOwnErrors "$current_test") -gt 0 ]]; then
        if [[ "$disable_display_test_error" != "yes" ]]; then
            _tester_print "error.test" "Bad \"$current_test\" test ( ${_trace_test["$current_test"]} )"
        fi
        return $TEST_ERR
    fi

    if [[ $(tester_amountErrors "$current_test") -gt 0 ]]; then
        return $TEST_ERR
    fi
    return 0
}

tester_info() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [[ -z "${_counter_success_buf[$name_test]+test}" ]]; then
        _tester_print "error" "\"$name_test\" test is missing!" 
        return $FATAL_ERR
    fi
    _tester_print "info" "$(echo -e \
        "Test $name_test (${_trace_test["$name_test"]})\n" \
        "Amount of tests: [ $(tester_amountTests "$name_test") ]\n" \
        "Amount of empty tests: [ $(tester_amountEmptyTests "$name_test") ]\n" \
        "Amount of bad tests: [ $(tester_amountBadTests "$name_test") ]\n" \
        "Amount of assert success: [ $(tester_amountSuccess "$name_test") ]\n" \
        "Amount of assert errors: [ $(tester_amountErrors "$name_test") ]\n" \
        "Total of asserts: [ $(tester_totalOfAsserts "$name_test") ]\n"
    )"
}

tester_totalOfOwnAsserts() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "$(($(tester_amountOwnErrors "$name_test") + $(tester_amountOwnSuccess "$name_test")))"
}

tester_amountOwnErrors() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "$((${_counter_error_buf["$name_test"]} - ${_counter_child_error_buf["$name_test"]}))"
}

tester_amountOwnSuccess() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "$((${_counter_success_buf["$name_test"]} - ${_counter_child_success_buf["$name_test"]}))"
}

tester_amountBadTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist" >&2; return 1; fi
    echo "${_counter_bad_test_buf["$name_test"]}"
}
tester_amountEmptyTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "${_counter_empty_test_buf["$name_test"]}"
}

tester_amountTests() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "${_counter_test_buf["$name_test"]}"
}
