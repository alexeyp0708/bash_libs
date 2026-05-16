script_runTestAsserts="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"

runtest(){
    "$script_runTestAsserts/../../run-test.sh" $@
}

runtest -o "disable_display=yes" -t  "$script_runTestAsserts/test_FuncDeclaration.sh FUNC1 FUNC2" \ -f "$script_runTestAsserts/check_FuncDeclaration.sh"
