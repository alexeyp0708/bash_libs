#!/bin/bash
script_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))


if [[ -z "$init_tester" ]] 
then
    source "$script_example_path/../init_tester.sh"
    less_message_output="yes"
    disable_display_ok="yes" 
    disable_display_error="yes"
    enable_trap_err="no"
    #ASSERT_ERR=8
    #TEST_ERR=12
    #FATAL_ERR=10
fi


tester startTest PARENT
   
    #tester assert equal 1 2 ""
   
    tester startTest EMPTY
    tester endTest
    tester startTest CHILD
        tester startTest NO_EMPTY
            tester startTest EMPTY
            tester endTest
        tester endTest
        tester assert equal 1 2 ""
        
        tester startTest SUB_CHILD
            tester assert equal 1 2 ""
        tester endTest
        
        tester assert equal 1 2 ""
        
        tester startTest SUB_CHILD2
            tester assert equal 1 2 ""
        tester endTest

        tester assert equal 1 2 ""
    tester endTest

    #tester assert equal 1 2 ""
    
    tester startTest CHILD2
        tester assert equal 1 1 ""
    tester endTest
    #tester assert equal 1 2 ""

tester endTest
