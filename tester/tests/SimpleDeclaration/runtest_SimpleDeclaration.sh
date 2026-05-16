#!/bin/bash

script_runTestSimpleDeclaration="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"

runtest(){
    "$script_runTestSimpleDeclaration/../../run-test.sh" $@
}

runtest -o "disable_display=yes" -t  "$script_runTestSimpleDeclaration/test_SimpleDeclaration.sh" -f "$script_runTestSimpleDeclaration/check_SimpleDeclaration.sh"
runtest -d "$script_runTestSimpleDeclaration/../../tester.ext.sh" -o "disable_display=yes" -t  "$script_runTestSimpleDeclaration/test_SimpleDeclaration.sh" -f "$script_runTestSimpleDeclaration/check_SimpleDeclaration.sh"
