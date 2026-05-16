error=0
[ "$final_status" == "9" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}"; error=1; } 

#CORE.SimpleDeclaration

[ "$(tester totalOfAsserts CORE.Asserts.1)" == "7" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}";  error=1; }
[ "$(tester amountSuccess CORE.Asserts.1)" == "5" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}";  error=1; }
[ "$(tester amountErrors CORE.Asserts.1)" == "2" ] || { echo "Error: ${BASH_SOURCE[0]}:${LINENO}";  error=1; }
