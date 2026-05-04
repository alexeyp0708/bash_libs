#!/bin/bash

script_tester_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
source "$script_tester_path/asserts.sh"
source "$script_tester_path/lib/share_var/shareVar.sh"
shareVar initSpace 

#core_tests=()
_active_tests=()
_before_active_tests=()

declare -g -A _counter_test_buf=()
declare -g -A _counter_empty_test_buf=()
declare -g -A _counter_success_buf=()
declare -g -A _counter_error_buf=()
declare -g -A _counter_child_error_buf=()
declare -g -A _counter_child_success_buf=()
declare -g -A _counter_bad_test_buf=()

declare -g -A _trace_test=()

_name_core_test=
_name_current_test=
_disable_display_error= 


_count_tests=0
_count_empty_tests=0
_count_success=0 
_count_error=0
_count_bad_test=0

ENTRY_POINT=

less_message_output=
disable_display_test_error= 
disable_display_ok= 
disable_display_error=
enable_trap_err=
ASSERT_ERR=8
TEST_ERR=9
FATAL_ERR=10

tester._entryPoint(){
    local ENTRY_POINT=$ENTRY_POINT
    local trace_num
    if [[ -z "${ENTRY_POINT}" ]]
    then
        for (( i=${#FUNCNAME[@]}-1; i>=0; i-- ))
        do
            if [[ "${FUNCNAME[$i]}" == "tester" ||  ! -z "$(echo ${FUNCNAME[$i]}|grep -oP '^tester.[\S]+')" ]]
            then
                trace_num=$i
                break
            fi    
        done
        if [[ ! -z "$trace_num" ]]
        then
            ENTRY_POINT="$(readlink -f "${BASH_SOURCE[$trace_num+1]}"):${BASH_LINENO[$trace_num]}"
        fi
    fi
    if [ -z "$ENTRY_POINT" ]
    then
        ENTRY_POINT="$(readlink -f "${BASH_SOURCE[@]: -1}"):${BASH_LINENO[@]: -2:1}" 
    fi
    echo "$ENTRY_POINT"
}

tester.assert(){
    local ENTRY_POINT=$(tester._entryPoint)       
    assert "$@"
}



tester._onCounter(){
    local name_test="$1"
    local parent_test="${_active_tests[@]: -1}"

    if [[ -n  ${_counter_success_buf[$name_test]+test}  ]]
    then
        echo "The $name_test test already exists. Completing the script!" >&2
        exit $FATAL_ERR
    fi
    if [ ! -z "$parent_test" ]
    then
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

tester._offCounter(){
    local name_test="$1"
    #echo $name_test
    local parent_test=${_active_tests[@]: -1}

    if [[ "$_count_tests" -eq 1 && "$(($_count_success+$_count_error))" -eq 0 ]]
    then
            ((++_count_empty_tests))
    fi
    
    if [[ "$(( $_count_error-${_counter_child_error_buf["$name_test"]} ))"  -ne 0 ]]
     then
        ((++_count_bad_test))
    fi

    #_count_own_error="$_count_error"

    _counter_test_buf["$name_test"]=$_count_tests
    _counter_empty_test_buf["$name_test"]=$_count_empty_tests
    _counter_success_buf["$name_test"]=$_count_success
    _counter_error_buf["$name_test"]=$_count_error
    _counter_bad_test_buf["$name_test"]=$_count_bad_test

    if [ ! -z "$parent_test" ]
    then
        _counter_test_buf["$parent_test"]=$(( ${_counter_test_buf["$parent_test"]}+$_count_tests ))
        _counter_empty_test_buf["$parent_test"]=$(( ${_counter_empty_test_buf["$parent_test"]}+$_count_empty_tests ))
        _counter_success_buf["$parent_test"]=$(( ${_counter_success_buf["$parent_test"]}+$_count_success ))
        _counter_error_buf["$parent_test"]=$(( ${_counter_error_buf["$parent_test"]}+$_count_error ))
        _counter_child_error_buf["$parent_test"]=$(( ${_counter_child_error_buf["$parent_test"]}+$_count_error ))
        _counter_child_success_buf["$parent_test"]=$(( ${_counter_child_success_buf["$parent_test"]}+$_count_success ))
        _counter_bad_test_buf["$parent_test"]=$(( ${_counter_bad_test_buf["$parent_test"]}+$_count_bad_test ))
        _count_tests="${_counter_test_buf["$parent_test"]}"
        _count_empty_tests="${_counter_empty_test_buf["$parent_test"]}"
        _count_success="${_counter_success_buf["$parent_test"]}"
        _count_error="${_counter_error_buf["$parent_test"]}"
        _count_bad_test="${_counter_bad_test_buf["$parent_test"]}"
        
    fi

}

tester.startTest(){
    local name_test="$1"
    #[[ "${#active_tests[@]}" == "0" ]] && name_core_test="$name_test"
    local parent_test=${_active_tests[@]: -1}
    if [[ -z "$parent_test" ]]
    then
        _name_core_test="$name_test"
    else
        name_test="$parent_test.$name_test"    
    fi
    _trace_test["$name_test"]="$(tester._entryPoint)"
    _name_current_test="$name_test"
    tester._onCounter "$name_test"
    _active_tests+=("$name_test")
    
    if [[  "$less_message_output" != "yes" ]]
    then
        echo -e "\033[94m"
        echo "------------"
        echo "START: $name_test (${_trace_test["$name_test"]})"
        echo "------------"
        echo -en "\033[0m"
        #echo -e "\033[97m"
    fi
}

tester.start(){
    tester.startTest $@
}

tester.endTest() {
    local last_error=$?
    local command=""
    [ ${1+x} ]&& command=$1
    [ "${#_active_tests[@]}" -eq 0 ] &&  echo "Fatal error: Tests have not been completed or started" >&2 && return $FATAL_ERR
    local current_test="${_active_tests[@]: -1}"
    unset _active_tests[-1]
    local parent_test="${_active_tests[@]: -1}"
    tester._offCounter "$current_test"
    _name_current_test="$parent_test"
    if [[  "$less_message_output" != "yes" || "$command" == "info" ]]
    then
        echo -en "\033[94m"
        echo "------------"
        echo "END TEST : $current_test (${_trace_test["$current_test"]})"
        echo -en "\033[0m"
        tester.info "$current_test"
        echo -e "\033[94m------------\033[0m"
    fi
    if [[ "$(tester.amountTests "$current_test")" -le 1 &&  "$(tester.totalOfAsserts "$current_test")" -le 0 ]]
    then
        [ "$disable_display_test_error" != "yes" ] && echo -e "(Test failure) \033[0;35m Empty \"$current_test\" test (${_trace_test["$current_test"]} )\033[0m" >&2
        return $TEST_ERR
    fi

    if [[ $(tester.amountOwnErrors "$current_test") -gt 0  ]] 
    then
        if [[ "$disable_display_test_error" != "yes" ]]
        then
            echo -e "(Test failure) \033[0;35mBad \"$current_test\" test (${_trace_test["$current_test"]})\033[0m" >&2
        fi
        return $TEST_ERR
    fi
    
    if [[ $(tester.amountErrors "$current_test") -gt 0  ]] 
    then
       return $TEST_ERR 
    fi
    return 0
}

tester.end(){
    tester.endTest #@
}

tester.info(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"

    if [[  -z "${_counter_success_buf[$name_test]+test}"  ]]
    then
        echo " Error: \"$name_test\" test is missing!" >&2
        return $FATAL_ERR
    fi
    echo -e "\033[94m"
    echo "Test $name_test (${_trace_test["$name_test"]})"
    echo "Amount of tests: [ $(tester.amountTests  "$name_test") ]" 
    echo "Amount of empty tests: [ $(tester.amountEmptyTests  "$name_test") ]" 
    echo "Amount of bad tests: [ $(tester.amountBadTests  "$name_test") ]" 
    echo "Amount of assert success: [ $(tester.amountSuccess "$name_test") ]" 
    #echo "Amount of assert own success: [ $(tester.amountOwnSuccess "$name_test") ]" 
    echo "Amount of assert errors: [ $(tester.amountErrors "$name_test") ]" 
    #echo "Amount of assert own errors: [ $(tester.amountOwnErrors "$name_test") ]" 
    echo "Total of asserts: [ $(tester.totalOfAsserts "$name_test") ]"
    #echo "Total of own asserts: [ $(tester.totalOfOwnAsserts "$name_test") ]"
    echo -en "\033[0m"
}

tester.totalOfAsserts(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(( $(tester.amountErrors "$name_test") + $(tester.amountSuccess "$name_test") ))"
}

tester.totalOfOwnAsserts(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(( $(tester.amountOwnErrors "$name_test") + $(tester.amountOwnSuccess "$name_test") ))"
}

tester.amountBadTests(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_bad_test_buf["$name_test"]}"
}
tester.amountEmptyTests(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_empty_test_buf["$name_test"]}"
}

tester.amountTests(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_test_buf["$name_test"]}"
}

tester.amountErrors(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_error_buf["$name_test"]}"
}
tester.amountOwnErrors(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(( ${_counter_error_buf["$name_test"]} - ${_counter_child_error_buf["$name_test"]} ))"
}

tester.amountSuccess(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "${_counter_success_buf["$name_test"]}"
}
tester.amountOwnSuccess(){
    local name_test="$1"
    [ -z "$name_test" ] && name_test="$_name_core_test"
    echo "$(( ${_counter_success_buf["$name_test"]} - ${_counter_child_success_buf["$name_test"]} ))"
}


# $1 - path test
tester.runTest(){
    local status=0
    #local ENTRY_POINT=$(tester._entryPoint)
    shareVar export _counter_success_buf _counter_error_buf _counter_test_buf _counter_empty_test_buf _trace_test _name_core_test _name_current_test disable_display_ok disable_display_error less_message_output _count_success _count_error _count_tests _count_empty_tests _count_bad_test _active_tests _counter_child_error_buf _counter_child_success_buf _counter_bad_test_buf disable_display_test_error enable_trap_err

    shareVar space|"$script_tester_path/wrap_unit_test.sh" "$1"
    status=$?
    shareVar import    
    return $status
}
# $1 -  good (current open tests)  active_tests
tester._closeBadTests(){
    local i status=0 
    #local -a before_active_tests
    #read -a before_active_tests <<< "$1"
    if [[ "$(declare -p _before_active_tests)" != "$(declare -p _active_tests)" ]]
    then
        #if [[ "${#active_tests[@]}" -lt "${#good_active_tests[@]}" ]]
        #then 
        ## fatal test error. 
        #    echo "The child unit test has completed its parent tests." >&2
        #    return $FATAL_ERR
        #fi
        for i in "${!_before_active_tests[@]}"
        do
            if [[ "${_before_active_tests[$i]}" != "${_active_tests[$i]}" ]]
            then
                echo "Fatal error test: Parent test \"${_before_active_tests[$i]}\" terminated prematurely. ( ${_trace_test[${_before_active_tests[$i]}]} )" >&2
                return $FATAL_ERR
            fi
        done
        for (( i=${#_active_tests[@]}-1; i>="${#_before_active_tests[@]}"; i-- ))
        do     
            #echo "Warn test: Closed bad \"${_active_tests[$i]}\" test ( ${_trace_test[${_active_tests[$i]}]} )" >&2
            tester.endTest
            status=$TEST_ERR
        done
        return $status
    fi
}
tester._addTrap(){
    local command="$1"
    local signal="$2"
    local current_trap_command="$( trap -p $signal|grep -Po "(?<=^trap -- ')[\s\S]+(?=' $signal\$)" )"
    if [[ ! -z $current_trap_command ]]
    then
        command="$(echo -e "$current_trap_command \n$command")"
    fi
    #command="'$command'"
    trap "$command" "$signal"
}
tester._trapExit(){
    local status=$?
    set +e
    tester._closeBadTests
    local bad_test_status=$? 
    if [[ "$bad_test_status" -ne 0 ]]
    then
        status=$bad_test_status
    fi
    if [[ "${#_active_tests[@]}" -eq 0 ]]
    then
        tester.info
    fi
    return $status
}

tester._trapErr(){
    if [[  "${#_active_tests[@]}" -ne 0  && "$enable_trap_err" == "yes" && "$1" -ne $ASSERT_ERR && "$1" -ne $TEST_ERR && "$1" -ne $FATAL_ERR ]]
    then
        tester assert _printError "error ($1)" "Error caught"
    fi
}
tester(){
    "tester.$@"
    return $?
}
tester._addTrap "tester._trapExit \$?" "EXIT"
tester._addTrap "tester._trapErr \$?" "ERR"
