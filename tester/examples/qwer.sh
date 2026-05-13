#!/bin/bash
run(){
    $1
}
(
    source "$(dirname $(readlink -f "${BASH_SOURCE[0]}"))/qwer2.sh"
    run hello
)
run hello
