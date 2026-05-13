#!/bin/bash
test_example3_myTest() {
    tester assert status "1" "0" "Bad assert"
}
test_example3_myTest2() {
    tester assert status "0" "0" "Bad assert"
    return 0
}
