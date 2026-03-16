

The tester keeps track of tests without completing code execution. If the statements fail, the parent test will throw error 1 after execution.


## Init

Любой новый тест должен оформляться в строгой последовательности кода.
Это необходимо чтобы тест можно было запустить как и отдельный юнит тест, так и подключить его в общую массу тестов и использовать не однократно. 


```bash
#!/bin/bash
script_example_path=$(dirname $(readlink -f  "${BASH_SOURCE[0]}"))


# Если тест запускается как отдельный юнит тест, то инициализируется код тестера с его настройками.
# Иначе текущий тест расширит  родительский тест
# Otherwise the current test will extend the parent test
if [[ -z "$init_tester" ]] 
then
    source "$script_example_path/../init_tester.sh"
    
    # Optional: you can expand the asserts with your own asserts  
    source "$script_tester_path/my_asserts.sh"
    
    # disable detailed information for each test
    less_message_output="yes"

    # Disable display of successful assertions
    disable_display_ok="yes" 

    # disable display of assertion errors
    disable_display_error="no"

    #if activated, then error-generating expressions will be processed as assert
    enable_trap_err="no"

  # Optional: change error codes if such codes are occupied by another script
    #ASSERT_ERR=8
    #TEST_ERR=9
    #FATAL_ERR=10
fi


#Обьявление теста
# При закрытии корневого теста, будет выведена информация о нем
tester startTest NAME_TEST
    tester assert equal 1 1 "Successful test"
tester endTest

echo $?

```

Чтобы вывести в  подробную информацию о тесте 

```bash
tester startTest PARENT
    tester startTest NAME_TEST
        #....
    tester endTest info
tester endTest
```

Чтобы расширить тест другим файлом теста ,  можно сделать следующее:


```bash

tester startTest PARENT
    source "$script_example_path/sub_example.sh"
tester endTest


```


или



```bash

test_sub_example(){
    # If tester settings variables are declared locally, they will be applied only for the test being enabled.
    local less_message_output="yes"
    local disable_display_error="no"
    local disable_display_ok="no"

    source "$script_example_path/sub_example.sh"
}

tester startTest PARENT
    tester startTest ATTEMPT_1
        test_sub_example
    tester endTest
    tester startTest ATTEMPT_2
        test_sub_example
    tester endTest
tester endTest


```

Тест можно запускать в отдельной  оболочке.
Это замедляет процессы, но позваляет юнит тестам быть автономными.

```bash

test_run_unit(){
    # If tester settings variables are declared locally, they will be applied only for the test being enabled.
    local less_message_output="yes"
    local disable_display_error="no"
    local disable_display_ok="no"

    #if a strict unit test (set -e) is executed with any error (like a fatal error), then the unit test will throw an empty test error, and the unit test results will not be included in the total mass
    tester startTest "UNIT_1"
        tester runTest "$script_example_path/sub_example.sh"
    tester endTest
}
tester startTest PARENT 
    test_run_unit
tester endTest

```

Tests may be empty

```bash
    tester startTest "EMPTY_TEST"
    # will throw an empty test error  
    # Useful for planning test writing
    tester endTest
```

use strict test

```bash
 # use strict
    tester startTest "EMPTY_TEST"
        (
            set -e
            test "a" != "a" 
            test "a" == "a" 
        )
        tester assert status "$?" "1" "Status last error code"
    tester endTest

```

asserts test

```bash
    # Succesful messaga
    tester assert printOk "Success message"
    # Failure
    tester assert printError "Error message"  

    # check successful status

    tester assert status $? 0 "message test" "$?==0"

    # check error 1 status

    tester assert status $? 1 "message test" "$?==1"    

    # check any errors 
    tester assert status $status "" "message test" "$?!=0"

    # note at this point.
    #This syntactic sugar. alternative to printError or printOk
    tester assert note ok "Successful note"
    tester assert note "any short text" "Bad note"

    # check files and directories

    #compare string data with file data
    tester assert equalDataWithFIle "/path/file" "data"

    #compare data from two files
    tester assert equalFileWithFIle "/path/file" "/path/file"

```

Утверждения для лаконичности можно создовать спомощью обыных выржаений чьи ошибки будут отлавливаться

```bash

test_exp_unit(){
    local enable_trap_err="yes"
    tester startTest "EXP_UNIT"
        #will catch error 1 and generate a statement for it
        [ 1 -eq 2 ]
    tester endTest
}

test_exp_unit

```


Rule for formatting a file with your own statements

file `/path/my_asserts.sh`

```bash
#!/bin/bash
assert.true(){
    if [[ "$1" == "1" || "$1" == "true" || "$1" == "yes" || "$1" == "ok"  ]]
    then
        #assert._printOk  "system message" "assert message"
        assert._printOk  "true ( true )" "$2"
        return 0
    else
        #assert._printError  "system message" "assert message"
        assert._printError "true ( false ) "  "$2"
        return $ASSERT_ERR
    fi
}

assert.false(){
    if [[ "$1" == "0" || "$1" == "false" || "$1" == "no"  ]]
    then
        #assert._printOk  "system message" "assert message"
        assert._printOk  "false ( true )" "$2"
        return 0
    else
        #assert._printError  "system message" "assert message"
        assert._printError "false ( false ) "  "$2"
        return $ASSERT_ERR
    fi
}

```
