#!/bin/bash
script_TestAsserts="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
tester start 1
    tester assert printOk "Success message"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester assert printError "Error message"    
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester assert status "0" "0" "Check status success executed command"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"

    tester assert status "2" "2" "Status  executed command which does not correspond to error 2"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"

    tester assert status "1" "" "Status bad executed command for any errors except 0" 
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"

    tester assert note ok "successful note"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"

    tester assert note "any short text" "Bad note"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"
tester end
