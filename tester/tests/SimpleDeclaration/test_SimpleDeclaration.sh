#!/bin/bash
#Declaration of test
tester start 1
    #Declaration of assert in CORE.SimpleDeclaration test
    tester assert status "0" "0" "Success SimpleDeclaration"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
tester end
# [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

tester start 2
    tester assert status "1" "0" "Error SimpleDeclaration2"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
tester end
[ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"

#Declaration of empty test
tester start 3_empty
tester end
[ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 


tester start 4
#Declaration of child test   
    tester start 5
        tester assert status "0" "0" "Success SimpleDeclaration5"
        [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
    tester end
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester assert status "1" "0" "Error SimpleDeclaration4_1"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
    
    tester start 6
        tester assert status "0" "0" "Success SimpleDeclaration6"
        [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
    tester end
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester assert status "1" "0" "Error SimpleDeclaration4_2"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester start 7

        tester assert status "0" "0" "Success SimpleDeclaration7_1"
        [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        
        tester assert status "1" "0" "Error SimpleDeclaration7_2"
        [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester end
    [ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
    
    tester assert status "1" "0" "Error SimpleDeclaration4_3"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}"    
    
    tester assert status "1" "0" "Error SimpleDeclaration4_4"
    [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester start 8
    tester end
    [ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    tester start 9
    tester end
    [ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

tester end
[ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

tester start 10
    #Executing commands in a subshell     
     
    (
        #Clear signal traps so that unexpected situations do not arise.
        #Subprocesses do not inherit the state of the parent, but the scope of declared hooks is preserved. Executable code can operate on such data and produce unexpected results.
        trap - EXIT
        trap - SIGUSR2
        #Disable error traps assigned by the tester. This is necessary if the executable code processes errors.
        #Also, if errors occur in a subprocess, and the tester tracks errors, the tester is initialized in the subprocess at the first error that occurs, which imposes additional costs for synchronizing data between processes.
        trap - ERR
        set -euo pipefail
        test "a" != "a" 
    )
    #check status subshell 
    #1
    tester assert status "$?" "1" "SimpleDeclaration10_1"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    (
        set -euo pipefail
        test "a" == "a" 
    )
    #2
    tester assert status "$?" "0" "SimpleDeclaration10_2"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    #declaration of tests in a subshell
    #Test results will be taken into account in the main shell
    #warn: Do not abuse. Test results are transmitted using data serialization where the clipboard can be a pipe or a file or a export variable 
    #warn: - if you combine the commands being tested and the tester in one subprocess, then be dybvfntkmyst in working with the following traps : trap -p EXIT, trap -P SIGUSR2 trap -p ERR
    (

        tester start 11
            #3
            tester assert status "0" "0" "Success SimpleDeclaration11"
            [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        tester end 
        [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        tester start 12
            #4
            tester assert status "1" "0" "Error SimpleDeclaration12"
            [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        tester end
        [ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

        tester start 13
        tester end    
        [ "$?" == "9" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        
        #5
        tester assert status "0" "0" "SimpleDeclaration10_3"
        [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        
        (   #6
            tester assert status "0" "0" "SimpleDeclaration10_4"
            [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        )
    )
    #7
    tester assert status "$?" "0" "SimpleDeclaration10_5"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 

    (
        set -euo pipefail
        tester start 14
            #8
            tester assert status "1" "0" "Error SimpleDeclaration14_1"
            #Won't work
            [ "$?" == "8" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
        tester end
        # test  will not count
        tester start 15
            # assert  will not count
            #--
            tester assert status "0" "0" "Error SimpleDeclaration15_1"
        tester end
        #EXIT TRAP: When an exception occurs, the open tests of the current subprocess are closed. since the close procedure is in an EXIT trap, the status of the last closed test will not be transmitted
    )
    #9   
    tester assert status "$?" "8" "SimpleDeclaration10_6"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
    (
        # activating subprocess traps
        tester 
        
        # remove traps
        trap - EXIT
        trap - SIGUSR2
        #the statement will be fulfilled but will not be taken into account
        #--
        tester assert status "1" "0" "Error SimpleDeclaration10_7"
    )
    #10
    tester assert status "$?" "8" "Error SimpleDeclaration10_8"
    [ "$?" == "0" ] || echo "Error: ${BASH_SOURCE[0]}:${LINENO}" 
tester end
