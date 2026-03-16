#!/bin/bash

script_sub_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))

if  [[ -z "$init_tester" ]]
then
    source "$script_sub_example_path/../init_tester_pack.sh"
    #source "$script_example2_path/../init_tester.sh"
    less_message_output="no"
    disable_display_ok="no" 
    disable_display_error="no"
fi

tester startTest SUB_EXAMPLE
    tester assert equal 1 2 "assert1_SUB_EXAMPLE_test"
    tester assert equal 1 1 "assert2_SUB_EXAMPLE_test"
tester endTest
