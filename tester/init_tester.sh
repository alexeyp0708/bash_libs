
if [[ -z "$init_tester" ]]
then
    script_init_tester_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
    source "$script_init_tester_path/tester.sh"   
    init_tester=1
    less_message_output="yes"
    disable_display_ok="yes" 
    disable_display_error="no"
    enable_trap_err="no"
    #ASSERT_ERR=8
    #TEST_ERR=9
    #FATAL_ERR=10
fi
