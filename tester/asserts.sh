#!/bin/bash

script_asserts_path=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))

_name_current_test=
disable_display_error=
disable_display_ok=
disable_display=
_count_success=
_count_error=
ENTRY_POINT=
ASSERT_ERR=8
is_init_assert="yes"

_assert_entryPoint() {
    local func_entry_point="$1"
    local find_shift="assert"
    [[ ! -z "$2" ]] && find_shift="$2"

    local ENTRY_POINT=$ENTRY_POINT
    local trace_num
    if [ -z "$func_entry_point" ]; then
        func_entry_point="assert"
    fi
    if [[ -z "${ENTRY_POINT}" ]]; then
        for i in "${!FUNCNAME[@]}"; do
            if [[ ! -z $trace_num ]]; then
                if [[ "${FUNCNAME[$i]}" == "$find_shift" ]]; then
                    trace_num=$(($i))
                    break
                fi
            elif [[ "${FUNCNAME[$i]}" == "$func_entry_point" ]]; then
                trace_num=$(($i))
                [[ "$find_shift" == "$func_entry_point" ]] && break
                continue
            fi
        done
        if [[ ! -z "$trace_num" ]]; then
            ENTRY_POINT="$(readlink -f "${BASH_SOURCE[$trace_num + 1]}"):${BASH_LINENO[$trace_num]}"
        fi
    fi
    if [ -z "$ENTRY_POINT" ]; then
        ENTRY_POINT="$(readlink -f "${BASH_SOURCE[@]: -1}"):${BASH_LINENO[@]: -2:1}"
    fi
    echo "$ENTRY_POINT"
}

_assert_fail(){
    _assert_printError "$1" "$2" 
    return 8
}
_assert_print(){
    local type="$1"
    local sys_message="$(echo -e "$2"|sed ':a;N;$!ba;s/\n/\\\\n/g')"
    local message="$3"
    local color="$4"   
    local entry_point="$(_assert_entryPoint)"
    echo -e "($type) $color Assert of test (\"$_name_current_test\"): $sys_message : $message ( $entry_point ) \033[97m"
}

# _printError ${system_message} ${message} ${entry_point}
_assert_printError(){
    ((++_count_error))
    [[ "$disable_display_error" == "yes" || "$disable_display" == "yes"  ]] && return 0
    _assert_print "Assert failure" "$1" "$2" "\033[91m"
}

# _printOk ${system_message} ${message} ${entry_point}
_assert_printOk(){
    ((++_count_success))
    [[ "$disable_display_ok" == "yes" || "$disable_display" == "yes" ]] && return 0
    _assert_print "Assert ok" "$1" "$2" "\033[92m"
}

assert_info(){
    echo "------------------------"
    echo "Test - $_name_current_test"
    echo "------------------------"
    echo -e "\033[92m Amount of success: [ $_count_success ]\033[97m"
    echo -e "\033[91m Amount of errors: [ $_count_error ]\033[97m"
    echo "------------------------"
}

# printError  ${message} [${status or expression}]
assert_printError(){
    _assert_printError "Error ($2)" "$1"
    return $ASSERT_ERR
}

# printOk  ${message} [${status or expression}]
assert_printOk(){
    _assert_printOk "Ok ($2)" "$1"
    return 0
}


#Check status error
#[ a == a ]
# status "$?" "0" "check successful for success status"  "[ a == a ]"
# status "$?" "" "check successful for any errors" "[ a == a ]"
# status "$?" "1" "check successful for  error 1" "[ a == a ]"

#Check command (Syntax sugar)
# status "[ a == a ]" "0" "check successful for success status" 
# status "[ a == a ]" "" "check successful for any errors" 
# status "[ a == a ]" "1" "check successful for  error 1"
assert_status(){
    local status="" command="" exp=""
    local match= message=

    if [  "$#" -ge 2  ]
    then
        match="$2"
    fi

    if [  "$#" -ge 3  ]
    then
        message="$3"
    fi

    if [[ $1 =~ ^[0-9]+$ ]]
    then
        status="$1"
    else 
        command="$1"
        source <(echo "$command")
        status=$?
       exp="$command"
    fi 

    #if [ ! -z "$4" ]
    if [  "$#" -ge 4  ]
    then
        exp="$4"
    fi

    if [[ ( -z "$match" ) && ("$status" -ne 0)  || ("$status" -eq "$match") ]]
    then
        _assert_printOk  "status( $exp )=>( $status )" "$message"
        return 0
    else
       _assert_printError  "status( $exp )=>( $status != $match )" "$message"
        return $ASSERT_ERR
    fi
}

#Required for planning future assers
# note "ok" "message"  - Success note output  
# note "any text" "message"  - Error note output  
assert_note(){
    if [[ "$1" == "ok" ]]
    then
        _assert_printOk  "note ( $1 )" "$2"
        return 0
    else
        _assert_printError "note ( $1 )" "$2"
        return $ASSERT_ERR
    fi
}

#deprecated
assert_equalDataWithFIle(){
    local file="$1"
    # echo -e заменит все экранирующие последовательности и возможно возниктнет сравнение экранирующих данных
    # поэтому надо сравнивать данные через source < echo equal
    local exp=$(echo -e "$2")
    local message="$3"
    if [ ! -f "$file" ]
    then
        _assert_printError "not exist ( $file )" "$message"
        return 8
    fi

    local math="$(cat "$file")"

    if [ "$math" == "$exp" ]
    then
        _assert_printOk  "equalDataWithFIle ('$math' == '$exp')" "$message"
        return 0
    else
      _assert_printError "equalDataWithFIle ('$math' != '$exp')"  "$message" 
        return $ASSERT_ERR
    fi
}
#deprecated
assert_equalFileWithFIle(){
# сравнить  побайтно cmp -s file1.txt file2.txt && echo "Файлы идентичны" || echo "Файлы различаются"
# сравнить через хеш файлов md5sum == md5sum 
    local file_math="$1"
    local file_exp="$2"
    local message="$3"
    if [ ! -f "$file" ]
    then
        _assert_printError "not exist ( $file_math )" "$message"
        return $ASSERT_ERR
    fi
    if [ ! -f "$file_exp" ]
    then
        _assert_printError "not exist ( $file_exp )" "$message"
        return $ASSERT_ERR
    fi

    local math="$(cat "$file_math")"
    local exp="$(cat "$file_exp")"

    if [ "$(cat "$file_math")" == "$(cat "$file_exp")" ]
    then
        _assert_printOk  "equalFileWithFIle ('$math' == '$exp')" "$message"
        return 0
    else
        _assert_printError "equalFileWithFIle ('$math' != '$exp')" "$message" 
        return $ASSERT_ERR
    fi
}

assert (){
    "assert_$@"
    return $?
}
