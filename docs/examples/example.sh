#!/bin/bash

#Bash Script Development Pattern

#public var
example_global_var="hello from global"

#protected var
#It means that the owner reserves the right to change it.
_example_global_protected_var="bay from global"

#public method
# means that the format of the input parameters and the format result should not be changed even if the method is overridden (overwritten or overridden by inheritance)
example.getGlobalVar(){
    echo "$example_global_var"
}

#pivate method
# It means that the owner reserves the right to change it.
example._getGlobalProtectedVar(){
    echo "$_example_global_protected_var"
}

#public method
#The public method that will have access to a variable declared locally in the constructor
#Calling such a method directly (`example.getPrivateVar`) will not be successful. It must be called through the constructor with the command (`example getPrivateVar`).
example.getPrivateVar(){
    echo $_example_private_var
}

# constructor - this is a method through which communication occurs with other methods.
# The name is borrowed from OOP from the class section.
example(){
    #Global variables will be declared each time before calling commands in the parent script.
    #This allows you to save the state/behavior of the script, making it more predictable for the developer. 
    #Such variables will be read-only by the child script, and changing them for the parent script will not change its behavior.
    example_global_var="hello from example (constructor)"

    #Declaring local variables in the constructor allows them to be seen by methods only at the time of their execution in the constructor.
    local _example_private_var="hello from example (constructor)"
    "example.$@"
}

example.run(){
    # global variables are initialized (or restore their state in the global scope when integrating a script, when calling a script, when calling a method directly.
    example_global_var="hello from example.run"
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}
# To prevent the call, this line can be removed/replaced by parsing and then the priority of declaring global variables remains with the current script.
example.run "$@"

example_global_var="Changed"
#API
# `./example.sh getPrivateVar` => hello from example (constructor)
# `./example.sh getGlobalVar` => hello from example (constructor)
# `./example.sh _getGlobalProtectedVar` => bay from global
