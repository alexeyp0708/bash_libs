#!/bin/bash
# test.myTest(){
#     tester assert status "1" "0" "Bad assert"
# }
tester startTest hello
    tester assert status "1" "0"
tester endTest
