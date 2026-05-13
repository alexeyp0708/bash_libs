#!/bin/bash

OPTIND=
OPTARG=
skip=0
raw_tester_opts=
test_files=()
tester_lite=
while getopts ":o:t:-:e" options; do
    case "${options}" in
    o)
        raw_tester_opts="$raw_tester_opts -o '${OPTARG}'"
        ;;
    t)
        test_files+=("${OPTARG}")
        ;;
    e)
        tester_ext="yes"
        ;;
    -)
        ((++skip))
        ;;
    esac
done
shift $((OPTIND - 1 - skip))

script_run_test_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))

array() {
    "$script_run_test_path/lib/array/array.sh" "$@"
}
declare -A tester_opts
source <(array optionsToArrayCode tester_opts $raw_tester_opts)

if [ ! -z "$tester_ext" ]; then
    source "$script_run_test_path/tester.ext.sh"
else
    source "$script_run_test_path/tester.sh"
fi

init_tester=1
less_message_output="yes"
disable_display_ok="yes"
disable_display_error="no"
enable_trap_err="no"
#ASSERT_ERR=8
#TEST_ERR=9
#FATAL_ERR=10

[ ! -z "${tester_opts[less_message_output]}" ] && less_message_output="${tester_opts[less_message_output]}"
[ ! -z "${tester_opts[disable_display_ok]}" ] && disable_display_ok="${tester_opts[disable_display_ok]}"
[ ! -z "${tester_opts[disable_display_error]}" ] && disable_display_error="${tester_opts[disable_display_error]}"
[ ! -z "${tester_opts[disable_display_test_error]}" ] && disable_display_test_error="${tester_opts[disable_display_test_error]}"
[ ! -z "${tester_opts[enable_trap_err]}" ] && enable_trap_err="${tester_opts[enable_trap_err]}"

tester startTest CORE
for test in "${test_files[@]}"; do
    #ARGS="$test"
    #source <(echo "set -- $ARGS")
    tester.runTest $test
done
tester endTest
