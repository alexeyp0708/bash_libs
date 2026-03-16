#!/bin/bash
script_wrap_unit_test_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))

source "$script_wrap_unit_test_path/init_tester.sh"
shareVar import
_before_active_tests=("${_active_tests[@]}")
shareVar_export(){
    shareVar export _count_success _count_error _count_tests _count_empty_tests _counter_success_buf _counter_error_buf _counter_test_buf _counter_empty_test_buf _trace_test _active_tests
}


trap_exit(){
    error_status=$?
    if [[ $- != *e* && "$error_status" -ne 0 || "$error_status" -eq 0 ]]  
    then
        shareVar_export
    fi
    return $error_status
}
tester._addTrap "trap_exit" "EXIT"

source "$1"

error_status=$?


exit $error_status
