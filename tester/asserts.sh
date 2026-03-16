#!/bin/bash

script_asserts_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))

_name_current_test=
disable_display_error=
disable_display_ok=
_count_success=
_count_error=
ENTRY_POINT=
ASSERT_ERR=8
is_init_assert="yes"

assert._entryPoint(){
    local ENTRY_POINT=$ENTRY_POINT
    local trace_num
    if [[ -z "${ENTRY_POINT}"  ]]
    then
        for (( i=${#FUNCNAME[@]}-1; i>=0; i-- ))
        do
            if [[ "${FUNCNAME[$i]}" == "assert"  || ! -z "$(echo ${FUNCNAME[$i]}|grep -oP '^assert.[\S]+')" ]]
            then
                trace_num=$i
                break
            fi    
        done
        if [[ ! -z "$trace_num" ]]
        then
            ENTRY_POINT="$(readlink -f "${BASH_SOURCE[$trace_num+1]}"):${BASH_LINENO[$trace_num]}"
        fi
    fi
    if [ -z "$ENTRY_POINT" ]
    then
        ENTRY_POINT="$(readlink -f "${BASH_SOURCE[@]: -1}"):${BASH_LINENO[@]: -2:1}" 
    fi
    echo "$ENTRY_POINT"
}

assert._fail(){
    assert._printError "$1" "$2" 
    return 8
}
assert._print(){
    local type="$1"
    local sys_message="$(echo -e "$2"|sed ':a;N;$!ba;s/\n/\\\\n/g')"
    local message="$3"
    local color="$4"   
    local entry_point="$(assert._entryPoint)"
    echo -e "($type) $color Assert of test (\"$_name_current_test\"): $sys_message : $message ( $entry_point ) \033[97m"
}

# _printError ${system_message} ${message} ${entry_point}
assert._printError(){
    ((++_count_error))
    [[ "$disable_display_error" == "yes" ]] && return 0
    assert._print "Assert failure" "$1" "$2" "\033[91m"
}

# _printOk ${system_message} ${message} ${entry_point}
assert._printOk(){
    ((++_count_success))
    [[ "$disable_display_ok" == "yes" ]] && return 0
    assert._print "Assert ok" "$1" "$2" "\033[92m"
}

assert.info(){
    echo "------------------------"
    echo "Test - $_name_current_test"
    echo "------------------------"
    echo -e "\033[92m Amount of success: [ $_count_success ]\033[97m"
    echo -e "\033[91m Amount of errors: [ $_count_error ]\033[97m"
    echo "------------------------"
}


# printError  ${message}
assert.printError(){
    assert._printError "printError ()" "$1"
    return $ASSERT_ERR
}

# printOk  ${message} 
assert.printOk(){
    assert._printOk "printOk ()" "$1"
    return 0
}

#deprecated
# use command status
assert.success(){
    echo "Assert "success" is deprecated.(${BASH[0]}:${LINENO[0]})" >&2
    if [[ "$1" == "1" || "$1" == "true" || "$1" == "yes" || "$1" == "ok"  ]]
    then
        assert._printOk  "success( $1 )" "$2"
        return 0
    else
        assert._printError "success ( $1 ) "  "$2"
        return $ASSERT_ERR
    fi
}

#as="[ a == a ]"; $as;
# status "$?" "0" "check successful for success status"  "$as"
# status "$?" "" "check successful for any errors" 
# status "$?" "1" "check successful for  error 1"
assert.status(){
    local status="$1" 
    local match="$2" 
    local message="$3"
    local exp="$4" 
    
    if [[ ( -z "$match" ) && ("$status" -ne 0)  || ("$status" -eq "$match") ]]
    then
        assert._printOk  "status( $exp )=>( $status )" "$message"
        return 0
    else
       assert._printError  "status( $exp )=>( $status != $match )" "$message"
        return $ASSERT_ERR
    fi
}

#deprecated
# use command status
assert.equal(){
    #echo "Assert "equal" is deprecated.(${BASH_SOURCE[0]}:${LINENO[@]})" >&2
    local math="$1"
    local exp="$2"
    local message="$3"
    if [ "$math" == "$exp" ]
    then
        assert._printOk  "equal ('$math' == '$exp')" "$message"
        return 0
    else
        assert._printError "equal ('$math' != '$exp')"  "$message" 
        return $ASSERT_ERR
    fi
}



#Required for planning future assers
# note "ok" "message"  - Success note output  
# note "any text" "message"  - Error note output  
assert.note(){
    if [[ "$1" == "ok" ]]
    then
        assert._printOk  "note ( $1 )" "$2"
        return 0
    else
        assert._printError "note ( $1 )" "$2"
        return $ASSERT_ERR
    fi
}


assert.equalDataWithFIle(){
    local file="$1"
    local exp="$2"
    local message="$3"
    if [ ! -f "$file" ]
    then
        assert._printError "not exist ( $file )" "$message"
        return 8
    fi

    local math="$(cat "$file")"

    if [ "$math" == "$exp" ]
    then
        assert._printOk  "equalDataWithFIle ('$math' == '$exp')" "$message"
        return 0
    else
      assert._printError "equalDataWithFIle ('$math' != '$exp')"  "$message" 
        return $ASSERT_ERR
    fi
}

assert.equalFileWithFIle(){
    local file_math="$1"
    local file_exp="$2"
    local message="$3"
    if [ ! -f "$file" ]
    then
        assert._printError "not exist ( $file_math )" "$message"
        return $ASSERT_ERR
    fi
    if [ ! -f "$file_exp" ]
    then
        assert._printError "not exist ( $file_exp )" "$message"
        return $ASSERT_ERR
    fi

    local math="$(cat "$file_math")"
    local exp="$(cat "$file_exp")"

    if [ "$(cat "$file_math")" == "$(cat "$file_exp")" ]
    then
        assert._printOk  "equalFileWithFIle ('$math' == '$exp')" "$message"
        return 0
    else
        assert._printError "equalFileWithFIle ('$math' != '$exp')" "$message" 
        return $ASSERT_ERR
    fi
}

assert (){
    "assert.$@"
    return $?
}
