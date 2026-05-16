#!/bin/bash

OPTIND=
OPTARG=
skip=0
raw_tester_opts=
sources=()
final_sources=()
test_files=()
final_script=
tester_lite=
tester_verbose=
tester_driver=
while getopts ":d:s:t:f:o:-:" options; do
    case "${options}" in
    v) #verbose
        tester_verbose="yes"
        ;;
    d) # driver
        tester_driver="$(readlink -f "$OPTARG")"
        ;;
    s) # source
        sources+=("$(readlink -f "$OPTARG")")
        ;;
    f) # finalize
        final_sources+=("$(readlink -f "$OPTARG")")
        ;;
    t) # test
        test_files+=("$(readlink -f "$OPTARG")")
        ;;

    o) # optons
        raw_tester_opts="$raw_tester_opts -o '${OPTARG}'"
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

if [ ! -z "$tester_driver" ]; then
    source "$tester_driver"
else
    source "$script_run_test_path/tester.sh"
fi

for script in "${sources[@]}"; do
    source $script
done

init_tester=1
less_message_output="yes"
disable_display="no"
disable_display_ok="yes"
disable_display_error="no"
disable_display_test_error="no"
enable_trap_err="no"
#ASSERT_ERR=8
#TEST_ERR=9
#FATAL_ERR=10
[ ! -z "${tester_opts[disable_display]}" ] && disable_display="${tester_opts[disable_display]}"
[ ! -z "${tester_opts[less_message_output]}" ] && less_message_output="${tester_opts[less_message_output]}"
[ ! -z "${tester_opts[disable_display_ok]}" ] && disable_display_ok="${tester_opts[disable_display_ok]}"
[ ! -z "${tester_opts[disable_display_error]}" ] && disable_display_error="${tester_opts[disable_display_error]}"
[ ! -z "${tester_opts[disable_display_test_error]}" ] && disable_display_test_error="${tester_opts[disable_display_test_error]}"
[ ! -z "${tester_opts[enable_trap_err]}" ] && enable_trap_err="${tester_opts[enable_trap_err]}"

tester start CORE
for raw_test_file in "${test_files[@]}"; do
    #ARGS="$test"
    #source <(echo "set -- $ARGS")
    test_name="$(echo "$raw_test_file"|grep -Po '^[\w\.]+(?=[\s]*=[\s\S]+$)')"
    test_file="$( echo "$raw_test_file"|grep -Po '^(?:[\w\.]+\s*=\s*)?\K[\s\S]+$')"
    test_file="$(readlink -f "$test_file")"

    if [ -z "$test_name" ]
    then
        test_name="$(basename "$test_file"| grep -Po '^(?:test[_\.-])?\K[\s\S]+?(?=\.[\w]+?$)')"
    fi
    
    #shopt -s extdebug
    #local func_info=$(declare -F $func)
    #shopt -u extdebug
    #ENTRY_POINT="$(echo "$func_info" | awk '{print $3}'):$(echo "$func_info" | awk '{print $2}')"
    ENTRY_POINT="$test_file"
    tester start $test_name
    ENTRY_POINT=
        tester_runTest $test_file
    tester end
done
tester end
final_status=$?

for script in "${final_sources[@]}"; do
    status=$final_status
    source $script
done
exit $final_status
