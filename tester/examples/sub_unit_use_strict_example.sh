#!/bin/bash

sub_unit_use_strict_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))

if  [[ -z "$init_tester" ]]
then
    source "$sub_unit_use_strict_example_path/../init_tester.sh"
    less_message_output="no"
    disable_display_ok="no" 
    disable_display_error="no"
fi

set -eu -o pipefail

tester startTest USE_STRICT
    tester.assert status 1 2 "assert1_USE_STRICT_test" ""
    tester assert status 1 1 "assert2_USE_STRICT_test" ""
tester endTest
#set +eu +o pipefail
