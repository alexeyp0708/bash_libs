
error=0

[ "$status" == "9" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


#CORE.SimpleDeclaration

[ "$(tester totalOfAsserts CORE.SimpleDeclaration.1)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountSuccess CORE.SimpleDeclaration.1)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountErrors CORE.SimpleDeclaration.1)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


# #ext
if [[ "$(type -t "tester_amountBadTests")" == "function" ]]
then
    [ "$(tester amountTests CORE.SimpleDeclaration.1)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountEmptyTests CORE.SimpleDeclaration.1)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountBadTests CORE.SimpleDeclaration.1)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester totalOfOwnAsserts CORE.SimpleDeclaration.1)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnSuccess CORE.SimpleDeclaration.1)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnErrors CORE.SimpleDeclaration.1)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
fi

#CORE.SimpleDeclaration.2

[ "$(tester totalOfAsserts CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountSuccess CORE.SimpleDeclaration.2)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountErrors CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


#ext
if [[ "$(type -t "tester_amountBadTests")" == "function" ]]
then
    [ "$(tester amountTests CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountEmptyTests CORE.SimpleDeclaration.2)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountBadTests CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester totalOfOwnAsserts CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnSuccess CORE.SimpleDeclaration.2)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnErrors CORE.SimpleDeclaration.2)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
fi

#CORE.SimpleDeclaration3_empty

[ "$(tester totalOfAsserts CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountSuccess CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountErrors CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


#ext
if [[ "$(type -t "tester_amountBadTests")" == "function" ]]
then
    [ "$(tester amountTests CORE.SimpleDeclaration.3_empty)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountEmptyTests CORE.SimpleDeclaration.3_empty)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountBadTests CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester totalOfOwnAsserts CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnSuccess CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnErrors CORE.SimpleDeclaration.3_empty)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
fi

#CORE.SimpleDeclaration4

[ "$(tester totalOfAsserts CORE.SimpleDeclaration.4)" == "8" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountSuccess CORE.SimpleDeclaration.4)" == "3" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountErrors CORE.SimpleDeclaration.4)" == "5" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


#ext
if [[ "$(type -t "tester_amountBadTests")" == "function" ]]
then
    [ "$(tester amountTests CORE.SimpleDeclaration.4)" == "6" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountEmptyTests CORE.SimpleDeclaration.4)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountBadTests CORE.SimpleDeclaration.4)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester totalOfOwnAsserts CORE.SimpleDeclaration.4)" == "4" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnSuccess CORE.SimpleDeclaration.4)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnErrors CORE.SimpleDeclaration.4)" == "4" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
fi

#CORE.SimpleDeclaration10
[ "$(tester totalOfAsserts CORE.SimpleDeclaration.10)" == "10" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountSuccess CORE.SimpleDeclaration.10)" == "8" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
[ "$(tester amountErrors CORE.SimpleDeclaration.10)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 


#ext
if [[ "$(type -t "tester_amountBadTests")" == "function" ]]
then
    [ "$(tester amountTests CORE.SimpleDeclaration.10)" == "5" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountEmptyTests CORE.SimpleDeclaration.10)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountBadTests CORE.SimpleDeclaration.10)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester totalOfOwnAsserts CORE.SimpleDeclaration.10)" == "7" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnSuccess CORE.SimpleDeclaration.10)" == "7" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
    [ "$(tester amountOwnErrors CORE.SimpleDeclaration.10)" == "0" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
fi




 

## CORE

# [ "$(tester totalOfAsserts)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
# [ "$(tester amountErrors)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 
# [ "$(tester amountSuccess)" == "1" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}" ; error=1 ; } 

exit $error
