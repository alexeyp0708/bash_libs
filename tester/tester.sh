#!/bin/bash

script_tester_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
source "$script_tester_path/asserts.sh"
source "$script_tester_path/lib/share_var/shareVar.sh"
shareVar initSpace

_current_pid=$BASHPID

_tester_activeTests=()
_tester_beforeActiveTests=()

declare -g -A _counter_success_buf=()
declare -g -A _counter_error_buf=()
declare -g -A _trace_test=()

_name_core_test=
_name_current_test=

_count_success=0
_count_error=0

disable_display=
disable_display_ok=
disable_display_error=
enable_trap_err=
ASSERT_ERR=8
TEST_ERR=9
FATAL_ERR=10
ENTRY_POINT=
export_vars="_counter_success_buf _counter_error_buf _trace_test _count_success _count_error _tester_activeTests"
_tester_print(){
    [ "$disable_display" == "yes" ] && return 0
    local type="$1"
    local message="$2"
    case "$type" in
        "error")
         #error error.test
            echo "$message" >&2
        ;;
        "error.test") 
        # error error.test
            [ "$disable_display_test_error" == "yes" ] && return 0
            echo -e "(Test failure) "$'\033[0;35m'"$message"$'\033[0m' >&2
        ;;
        "info") 
        #info info.start info.end
            echo -e $'\033[94m'"\n$message\n"$'\033[0m'
        ;;
        "test.start")
            [ "$less_message_output" == "yes" ] && return 0
            echo -e $'\033[94m'"------------\nSTART :" "$message" $'\033[94m'"\n ------------"$'\033[0m'
        ;;
        "test.end")
            [ "$less_message_output" == "yes" ] && return 0
            echo -e $'\033[94m'"------------\nEND TEST : " "$message" $'\033[94m'"\n ------------"$'\033[0m'
        ;;
        *)
            echo -e "$message"
        ;;
    esac
}
_tester_entryPoint() {
    local func_entry_point="$1"
    local find_shift="tester"
    [[ ! -z "$2" ]] && find_shift="$2"

    local ENTRY_POINT=$ENTRY_POINT
    local trace_num=
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

tester_assert() {
    local ENTRY_POINT=
    ENTRY_POINT="$(_tester_entryPoint "tester_assert" "tester")"
    assert "$@"
}

_tester_onCounter() {
    local name_test="$1"
    local parent_test="${_tester_activeTests[@]: -1}"

    if [[ -n ${_counter_success_buf[$name_test]+test} ]]; then
        _tester_print "error" "The $name_test test already exists. Completing the script!"
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

_tester_offCounter() {
    local name_test="$1"
    #echo $name_test
    local parent_test=${_tester_activeTests[@]: -1}
    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error

    if [ ! -z "$parent_test" ]; then
        _counter_success_buf["$parent_test"]=$((${_counter_success_buf["$parent_test"]} + $_count_success))
        _counter_error_buf["$parent_test"]=$((${_counter_error_buf["$parent_test"]} + $_count_error))
        _count_success="${_counter_success_buf["$parent_test"]}"
        _count_error="${_counter_error_buf["$parent_test"]}"
    fi
}

tester_start() {
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
}

tester_end() {
    local last_error=$?
    local command=""
    [ ${1+x} ] && command=$1
    [ "${#_tester_activeTests[@]}" -eq 0 ] && _tester_print "error" "Tests have not been completed or started" && return $FATAL_ERR
    local current_test="${_tester_activeTests[@]: -1}"
    unset _tester_activeTests[-1]
    local parent_test="${_tester_activeTests[@]: -1}"
    _tester_offCounter "$current_test"
    _name_current_test="$parent_test"

    if [[ $(tester_amountErrors "$current_test") -gt 0 ]]; then
        return $TEST_ERR
    fi
    if [[ $(tester_totalOfAsserts "$current_test") -eq 0 ]]; then
        _tester_print "error.test" "Empty \"$current_test\" test ( ${_trace_test["$current_test"]} )"
        return $TEST_ERR
    fi
    return 0
}

tester_info() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"

    if [[ -z "${_counter_success_buf[$name_test]+test}" ]]; then
        echo " Error: \"$name_test\" test is missing!" >&2
        return $FATAL_ERR
    fi
    _tester_print "info" "$(cat <<EOF
Test $name_test (${_trace_test["$name_test"]})
Amount of assert success: [ $(tester_amountSuccess "$name_test") ]
Amount of assert errors: [ $(tester_amountErrors "$name_test") ]
Total of asserts: [ $(tester_totalOfAsserts "$name_test") ]
EOF
)"
}

tester_statusTest(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
}
tester_totalOfAsserts() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "$(( $(tester_amountErrors "$name_test") + $(tester_amountSuccess "$name_test") ))"
}

tester_amountErrors() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "${_counter_error_buf["$name_test"]}"
}


tester_amountSuccess() {
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    if [ -z "${_trace_test["$name_test"]}" ]; then echo "'$name_test' test does not exist"  >&2; return 1; fi
    echo "${_counter_success_buf["$name_test"]}"
}

tester_runTest() {
    local status=0
    local test_file=$1
    (
        trap - EXIT
        trap - SIGUSR2
        #ARGS="$test"
        #source <(echo "set -- $ARGS")
        source "$test_file"
        _tester_init
        _tester_runFuncTest
    )
}

_tester_runFuncTest() {
    local parent_test=$_name_current_test
    local _name_current_test
    local OPTIND OPTARG skip=0
    local use_strict use_isolate
    while getopts ":-:si" options; do
        case "${options}" in
        s)
            use_strict="yes"
            ;;
        i)
            use_isolate="yes"
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
    local hand_trap 
    for func in $func_list; do
        if [[ ! "$func" =~ ^test[\._] ]]; then
            continue
        fi
        test_name=$(echo "$func" | grep -Po "^test[\._]\K[\S\s]+")
        if [[ "$use_isolate" == "yes" ]]
        then
            (   
                trap - EXIT
                trap - SIGUSR2
                _tester_init
                $func    
            ) 
            status=$?
        else
            $func
            status=$?
        fi
        [[ "$use_strict" == "yes" && "$status" != "0" ]] && break
    done
}

# $1 -  good (current open tests)  active_tests
_tester_closeBadTests() {
    local i status=0
        for i in "${!_tester_beforeActiveTests[@]}"; do
            if [[ "${_tester_beforeActiveTests[$i]}" != "${_tester_activeTests[$i]}" ]]; then
                _tester_print "error" "Fatal error test: Parent test \"${_tester_beforeActiveTests[$i]}\" terminated prematurely. ( ${_trace_test[${_tester_beforeActiveTests[$i]}]} )"
                return $FATAL_ERR
            fi
        done
        for ((i = ${#_tester_activeTests[@]} - 1; i >= "${#_tester_beforeActiveTests[@]}"; i--)); do
            tester_end
            status=$?
        done
        return $status
    fi
}

_tester_addTrap() {
    local command="$1"
    local signal="$2"
    local current_trap_command="$(trap -p $signal | grep -Po "(?<=^trap -- ')[\s\S]+(?=' $signal\$)")"
    if [[ ! -z $current_trap_command ]]; then
        command="$(echo -e "$current_trap_command \n$command")"
    fi
    #command="'$command'"
    trap "$command" "$signal"
}

_tester_trapExit() {
    [ -z "$_name_core_test" ] && return 0
    local status=$?
    set +e
    _tester_closeBadTests
    local bad_test_status=$?
    if [[ "$bad_test_status" -ne 0 ]]; then
        status=$bad_test_status
    fi
    
    if [[ "${#_tester_activeTests[@]}" -eq 0 ]]; then
        tester_info
    fi
    return $status
}

_tester_trapErr() {
    if [[ "${#_tester_activeTests[@]}" -ne 0 && "$enable_trap_err" == "yes" && "$1" -ne $ASSERT_ERR && "$1" -ne $TEST_ERR && "$1" -ne $FATAL_ERR ]]; then
        tester_assert printError "error ()" "Error caught" "$1"
    fi
}

_tester_trapSubProc_EXIT() {
    shareVar export $export_vars
    kill -SIGUSR2 $1
}

_tester_trapSubProc_SIGUSR2() {
    shareVar import
}

_tester_init() {
    if [[ "$_current_pid" != "$BASHPID" ]]; then
        #trap - SIGCHLD
        #trap - EXIT
        #trap "_tester_trapSubProc_EXIT $_current_pid" EXIT
        #trap "_tester_trapSubProc_SIGUSR2" SIGUSR2
        _tester_beforeActiveTests=("${_tester_activeTests[@]}")
        _tester_addTrap "_tester_trapExit \$?" "EXIT"
        _tester_addTrap "_tester_trapSubProc_EXIT $_current_pid" "EXIT"
        _tester_addTrap "_tester_trapSubProc_SIGUSR2" SIGUSR2
        _current_pid=$BASHPID
    fi
}

tester() {
    _tester_init
    [[ ! -z "$@" ]] && "tester_$@"
    local status=$?
    return $status
}

_tester_addTrap "_tester_trapExit \$?" "EXIT"
[ "$enable_trap_err" == "yes" ] && _tester_addTrap "_tester_trapErr \$?" "ERR"
_tester_addTrap "_tester_trapSubProc_SIGUSR2" "SIGUSR2"
