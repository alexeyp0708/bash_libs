#!/bin/bash

script_tester_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
source "$script_tester_path/asserts.sh"
source "$script_tester_path/lib/share_var/shareVar.sh"
shareVar initSpace

_current_pid=$BASHPID

_active_tests=()
_before_active_tests=()

declare -g -A _counter_success_buf=()
declare -g -A _counter_error_buf=()
declare -g -A _trace_test=()

_name_core_test=
_name_current_test=

_count_success=0
_count_error=0

disable_display_ok=
disable_display_error=
enable_trap_err=
ASSERT_ERR=8
TEST_ERR=9
FATAL_ERR=10
ENTRY_POINT=
export_vars="_counter_success_buf _counter_error_buf _trace_test _name_core_test _name_current_test disable_display_ok disable_display_error _count_success _count_error _active_tests  enable_trap_err"

_tester.entryPoint() {
    local func_entry_point="$1"
    local find_shift="tester"
    [[ ! -z "$2" ]] && find_shift="$2"

    local ENTRY_POINT=$ENTRY_POINT
    local trace_num
    if [ -z "$func_entry_point" ]; then
        func_entry_point="tester"
    fi
    if [[ -z "${ENTRY_POINT}" ]]; then
        #for (( i=${#FUNCNAME[@]}-1; i>=0; i-- ))
        for i in "${!FUNCNAME[@]}"; do
            if [[ ! -z $trace_num ]]; then
                if [[ "${FUNCNAME[$i]}" == "$find_shift" ]]; then
                    trace_num=$(($i))
                    break
                fi
            elif [[ "${FUNCNAME[$i]}" == "$func_entry_point" ]]; then
                trace_num=$(($i))
                [[ "$find_shift" == "$func_entry_point" ]] && break
                continue
            fi
        done
        if [[ ! -z "$trace_num" ]]; then
            ENTRY_POINT="$(readlink -f "${BASH_SOURCE[$trace_num + 1]}"):${BASH_LINENO[$trace_num]}"
        fi
    fi
    if [ -z "$ENTRY_POINT" ]; then
        ENTRY_POINT="$(readlink -f "${BASH_SOURCE[@]: -1}"):${BASH_LINENO[@]: -2:1}"
    fi
    echo "$ENTRY_POINT"
}

tester.assert() {
    local ENTRY_POINT=
    ENTRY_POINT="$(_tester.entryPoint "tester.assert" "tester")"
    assert "$@"
}

_tester.onCounter() {
    local name_test="$1"
    local parent_test="${_active_tests[@]: -1}"

    if [[ -n ${_counter_success_buf[$name_test]+test} ]]; then
        echo "The $name_test test already exists. Completing the script!" >&2
        exit $FATAL_ERR
    fi
    if [ ! -z "$parent_test" ]; then
        _counter_success_buf["$parent_test"]=$_count_success
        _counter_error_buf["$parent_test"]=$_count_error
    fi

    _count_success=0
    _count_error=0

    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error

}

_tester.offCounter() {
    local name_test="$1"
    #echo $name_test
    local parent_test=${_active_tests[@]: -1}
    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error

    if [ ! -z "$parent_test" ]; then
        _counter_success_buf["$parent_test"]=$((${_counter_success_buf["$parent_test"]} + $_count_success))
        _counter_error_buf["$parent_test"]=$((${_counter_error_buf["$parent_test"]} + $_count_error))
        _count_success="${_counter_success_buf["$parent_test"]}"
        _count_error="${_counter_error_buf["$parent_test"]}"
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
}

tester.start() {
    tester.startTest "$@"
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

    if [[ $(tester.amountErrors "$current_test") -gt 0 ]]; then
        return $TEST_ERR
    fi
    return 0
}

tester.end() {
    tester.endTest "$@"
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
    echo "Amount of assert success: [ $(tester.amountSuccess "$name_test") ]"
    echo "Amount of assert errors: [ $(tester.amountErrors "$name_test") ]"
    echo "Total of asserts: [ $(tester.totalOfAsserts "$name_test") ]"
    echo -en "\033[0m"
}

tester.totalOfAsserts() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(($(tester.amountErrors "$name_test") + $(tester.amountSuccess "$name_test")))"
}

tester.amountErrors() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_error_buf["$name_test"]}"
}
tester.amountOwnErrors() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$((${_counter_error_buf["$name_test"]} - ${_counter_child_error_buf["$name_test"]}))"
}

tester.amountSuccess() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_success_buf["$name_test"]}"
}
tester.amountOwnSuccess() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$((${_counter_success_buf["$name_test"]} - ${_counter_child_success_buf["$name_test"]}))"
}

tester.runTest() {
    local status=0
    (
        trap - EXIT
        #ARGS="$test"
        #source <(echo "set -- $ARGS")
        test_file="$(readlink -f "$1")"
        source "$test_file"
        _tester.runFuncTest "$@"
    )
}

_tester.runFuncTest() {
    local parent_test=$_name_current_test
    local _name_current_test
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
    local func_info status=0
    local file_test_name="$(basename "$test_file" | grep -Po '(?:^test[_\.-])?\K[\s\S]+?(?=\.[\w]+?$)')"
    for func in $func_list; do
        if [[ ! "$func" =~ ^test[\._] ]]; then
            continue
        fi
        test_name=$(echo "$func" | grep -Po "^test[\._]\K[\S\s]+")
        _name_current_test="$parent_test.$file_test_name.$test_name"
        $func
        status=$?
        [[ "$use_strict" == "yes" && "$status" != "0" ]] && break
    done
}

# $1 -  good (current open tests)  active_tests
_tester.closeBadTests() {
    local i status=0
    #local -a before_active_tests
    #read -a before_active_tests <<< "$1"
    if [[ "$(declare -p _before_active_tests)" != "$(declare -p _active_tests)" ]]; then
        #if [[ "${#active_tests[@]}" -lt "${#good_active_tests[@]}" ]]
        #then
        ## fatal test error.
        #    echo "The child unit test has completed its parent tests." >&2
        #    return $FATAL_ERR
        #fi
        for i in "${!_before_active_tests[@]}"; do
            if [[ "${_before_active_tests[$i]}" != "${_active_tests[$i]}" ]]; then
                echo "Fatal error test: Parent test \"${_before_active_tests[$i]}\" terminated prematurely. ( ${_trace_test[${_before_active_tests[$i]}]} )" >&2
                return $FATAL_ERR
            fi
        done
        for ((i = ${#_active_tests[@]} - 1; i >= "${#_before_active_tests[@]}"; i--)); do
            #echo "Warn test: Closed bad \"${_active_tests[$i]}\" test ( ${_trace_test[${_active_tests[$i]}]} )" >&2
            tester.endTest
            status=$TEST_ERR
        done
        return $status
    fi
}

_tester.addTrap() {
    local command="$1"
    local signal="$2"
    local current_trap_command="$(trap -p $signal | grep -Po "(?<=^trap -- ')[\s\S]+(?=' $signal\$)")"
    if [[ ! -z $current_trap_command ]]; then
        command="$(echo -e "$current_trap_command \n$command")"
    fi
    #command="'$command'"
    trap "$command" "$signal"
}

_tester.trapExit() {
    [ -z "$_name_core_test" ] && return 0
    local status=$?
    set +e
    _tester.closeBadTests
    local bad_test_status=$?
    if [[ "$bad_test_status" -ne 0 ]]; then
        status=$bad_test_status
    fi
    if [[ "${#_active_tests[@]}" -eq 0 ]]; then
        tester.info
    fi
    return $status
}

_tester.trapErr() {
    if [[ "${#_active_tests[@]}" -ne 0 && "$enable_trap_err" == "yes" && "$1" -ne $ASSERT_ERR && "$1" -ne $TEST_ERR && "$1" -ne $FATAL_ERR ]]; then
        tester.assert printError "error ()" "Error caught" "$1"
    fi
}

_tester.trapSubProc_EXIT() {
    shareVar export $export_vars
    kill -SIGUSR2 $1
}

_tester.trapSubProc_SIGUSR2() {
    shareVar import
}

_tester.init() {
    if [[ "$_current_pid" != "$BASHPID" ]]; then
        #trap - SIGCHLD
        #trap - EXIT
        #trap "tester._trapSubProc_EXIT $_current_pid" EXIT
        #trap "tester._trapSubProc_SIGUSR2" SIGUSR2
        _tester.addTrap "_tester.trapSubProc_EXIT $_current_pid" "EXIT"
        _tester.addTrap "_tester.trapSubProc_SIGUSR2" SIGUSR2
        _current_pid=$BASHPID
    fi
}

tester() {
    _tester.init
    [[ ! -z "$@" ]] && "tester.$@"
    local status=$?
    return $status
}

_tester.addTrap "_tester.trapExit \$?" "EXIT"
_tester.addTrap "_tester.trapErr \$?" "ERR"
_tester.addTrap "_tester.trapSubProc_SIGUSR2" "SIGUSR2"
