#!/bin/bash

func1(){
    echo "func1"
}

func2(){
    echo "func2-"
}

trap "func1" EXIT
trap 'echo "hello"' EXIT
sign="EXIT"
command="$( trap -p $sign|grep -Po "(?<=^trap -- ')[\s\S]+(?=' $sign\$)" )"
command="$(echo -e "$command \necho 'bay'")"
echo "$command"
trap "$command" EXIT
