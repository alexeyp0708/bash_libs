#!/bin/bash
script_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))

#set -o pipefail

if [[ -z "$init_tester" ]] 
then
    source "$script_example_path/../init_tester_lite.sh"
    #source "$script_example_path/../init_tester.sh"
    less_message_output="yes"
    disable_display_ok="no" 
    disable_display_error="no"
    enable_trap_err="no"
    disable_display_test_error="no"
    #ASSERT_ERR=8
    #TEST_ERR=12
    #FATAL_ERR=10
fi

# extending the test with a unit test
test_sub_example(){
    #extending the test with a unit test
    #local less_message_output="no"
    #local disable_display_ok="no"
    source "$script_example_path/sub_example.sh"
}

#run the unit test in a separate shell.
test_unit_1(){
    #local less_message_output="no"
    #local disable_display_ok="no"
    #local disable_display_error="no"
    
    tester startTest "UNIT_1"
        tester runTest "$script_example_path/sub_example.sh"
    tester endTest
}

#run the strict (set -e) unit test in a separate shell.
    #if a strict unit test (set -e) is executed with any error (like a fatal error), then the unit test will throw an empty test error, and the unit test results will not be included in the total mass.
test_unit_2(){
    #local disable_display_ok="no"
    #local disable_display_error="no"
    tester startTest "UNIT_2"
        tester runTest "$script_example_path/sub_unit_use_strict_example.sh"
    tester endTest
}

#set -e
tester startTest EXAMPLE
    tester startTest "test_1"
    # full name EXAMPLE.test_1
        tester startTest "subtest_1_1"
        # full name EXAMPLE.test_1.subtest_1_1
            tester assert status 2 1 "assert 1"
        tester endTest
        tester assert status 1 1 "assert 2"
    tester endTest

    test_sub_example
    test_unit_1
    test_unit_2

    tester  startTest empty_tests
        tester startTest empty
            tester startTest sub_empty
            tester endTest
        tester endTest
        tester startTest no_empty
             tester assert status 1 1 "assert_no_empty"
        tester endTest
    tester endTest

    tester startTest "asserts_list"

        tester assert printOk "Success message"
        tester assert printError "Error message"    

        expr="[ 'a' != 'a' ]"
        #  will be processed as a statement - error (1)
        $expr
        status=$?    
        tester assert status $status "2" "Status bad executed command which does not correspond to error 2" "$expr"
        tester assert status $status "1" "Status executed command with error 1" "$expr"
        tester assert status $status "" "Status bad executed command for any errors except 0" "$expr"

        [ "a" == "a" ]
        tester assert status $? "0" "Check status success executed command"

        expr="[ 'a' != 'a' ]"
  
        tester assert status "$expr" "2" "Command bad executed command which does not correspond to error 2" 
        tester assert status "$expr" "1" "Status executed command with error 1"
        tester assert status "$expr" "" "Status bad executed command for any errors except 0"

        [ "a" == "a" ]
        tester assert status $? "0" "Check status success executed command"

        # use strict
        (
            set -euo pipefail
            test "a" != "a" 
        )
        tester assert status "$?" "1" "Status last error code"


        # note at this point.
        #This syntactic sugar. alternative to printError or printOk

        tester assert note ok "successful note"
        tester assert note "any short text" "Bad note"

      
        # check files and directories

        tester assert equalDataWithFIle "/path/file" "data"
        tester assert equalFileWithFIle "/path/file" "/path/file"
        #tester assert info 

    tester endTest
   # tester assert equal 1 2 "assert END"
tester endTest
echo $?


## get info for test
#tester info
#tester info "EXAMPLE.empty_tests"

## get total of asserts
# tester totalOfAsserts
# tester totalOfAsserts "full_name_test"

## Amount of tests
#tester amountTests
#tester amountTests "full_name_test"

## Amount of empty tests
#tester amountEmptyTests
#tester amountEmptyTests "full_name_test"

## Amount of success for asserts
#tester amountSuccess
#tester amountSuccess "full_name_test"

##  Amount of success for asserts
#tester amountErrors
#tester s "full_name_test"


#Warn: don't use pipe channels
#Warn: do not use pipe, there will be an error if the data is not read in the piped
#example
#finalTests|echo "bay"
