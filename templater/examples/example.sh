#! /bin/bash

script_path="$(dirname $(readlink -f "$0"))"

templater(){
    "$script_path/../templater.sh" $@
}
export TEST_VAR_1="test1"
export TEST_VAR_2="test2"
templater envsubst -t "$script_path/templates" -o "$script_path/output1/" -e "TEST_VAR_1|TEST_VAR_2" -b
export TEST_VAR_1="test3"
export TEST_VAR_2="test4"
echo "sdfsfs">"$script_path/output1/dir1/qwer"
templater envsubst -t "$script_path/templates" -o "$script_path/output1/" -e "TEST_VAR_1|TEST_VAR_2" -f
touch "$script_path/output1/output.txt"
templater envsubst -t "$script_path/templates" -o "$script_path/output1/output.txt" -e "TEST_VAR_1|TEST_VAR_2" -b
templater envsubst -t "$script_path/templates" -o "$script_path/output1/output.txt" -e "TEST_VAR_1|TEST_VAR_2" -f
templater envsubst -t "$script_path/templates" -e "TEST_VAR_1|TEST_VAR_2" 
touch "$script_path/output2/output.txt"
echo 'Hello ${TEST_VAR_1}'|templater envsubst -o "$script_path/output2/output.txt" -e "TEST_VAR_1|TEST_VAR_2" -b
echo 'Hello ${TEST_VAR_2}'|templater envsubst -o "$script_path/output2/output.txt" -e "TEST_VAR_1|TEST_VAR_2" -f
