#!/bin/bash
_current_pid=$BASHPID
var=0
TMP_DIR=$(mktemp -d)
trap "child_exit $_current_pid" SIGCHLD

_exit_pid(){
   echo "var=$var" >"$TMP_DIR/core"
}
init(){
    [ -z "$_current_pid" ] && _current_pid=$BASHPID
    if [ $_current_pid != $BASHPID ]
    then
        trap "_exit_pid $_current_pid" EXIT
        trap "child_exit $BASHPID" SIGCHLD
        _current_pid=$BASHPID
    fi
}
child_exit(){
     if [ -f "$TMP_DIR/core" ]
    then
        source "$TMP_DIR/core"
        #rm "$TMP_DIR/core"
    fi
}

action(){
    init
    echo $BASHPID
    (( ++var ))
}
 echo $BASHPID
action

(
    echo $BASHPID
    action
    (
        action
    )
    action
    (
        action
    )
)
trap -p SIGCHLD

action

echo "$var"
