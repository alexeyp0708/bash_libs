#!/bin/bash

#Bash Script Development Pattern

#Symbolic definitions for an example of a way to extend commands by inheritance:
# - parent class -a script that extends the current script
# - child class - current script which is extended by parent classes
# - constructor - this is a method through which communication occurs with other methods.

#Often, an extension technique is necessary to connect additional libraries.
#An inheritance scheme is needed only when there is an urgent need for refactoring and testing scripts


#parent class extends (script)
source ./example.sh

sub_example.subTest() {
    # calling a method directly
    # disadvantages - variables and other resources declared in the constructor will not be connected
    example.var
    #error - empty vriable
    example.privateVar

    # (recommended) calling a method through a constructor
    example privateVar
    #error - empty vriable
    example privateVar2
}

# override the method
sub_example.getGlobalVar() {
    #Expand  result of parent method
    echo "Example 2: $(example getGlobalVar)"
}

sub_example.otherMethod() {
    echo "Other"
}

# explicitly call the methods of the parent constructor
sub_example.example() {
    example "$@"
}

#  to call child methods directly when used contravariantly
example.sub_example(){
    sub_example "$@"
}


## constructor 
## The name is borrowed from OOP from the class section.
## Often this format of constructor declaration is sufficient. But the methods examples below shows how to extend the commands of a parent class with a child class.
#sub_example() { 
#    "sub_example.$@"
#}


# (default) constructor - covariant expansion of commands 
# The purpose of covariance is when the functionality of the parent class undergoes changes without affecting the way the command is used, its result format, or the code that uses it.
sub_example() { 
    #substitution in inheritance
    if declare -f "sub_example.$1" &>/dev/null;
    then
        #In the native constructor a method call is required. Otherwise you may end up in a loop.
        "sub_example.$@"
    else
        #The parent method is called through the constructor.
        example "$@"
    fi
}

sub_example.run() {
    [ "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && sub_example "$@"
}
#sub_example.run $@


# Note:
# for examples
# The following descriptions of the methods are shown as an example. Often this behavior will be redundant.


# contravariant constructor 
# contravariant expansion of commands 
# The purpose of contravariance is when the use of the functionality of the parent class is preserved in the code, but allows such a class to be extended with additional methods (commands).
sub_example._contravariantConstructor() { 
    if declare -f "example.$1" &>/dev/null;
    then
        example "$@"
        ## Note:Be careful
        ## example.method - calls a method
        ## example method - calls the constructor, which in turn calls the method. This is preferable if the method call occurs in other methods or outside the native constructor 
    else
        #In the native constructor a method call is required. Otherwise you may end up in a loop.
        "sub_example.$@"
    fi
}



# if the parent constructor accepts options, then it is better to move the processing of options into a separate method so that the child script can apply them in its constructor.
# The same applies to overridden methods
# In this example and for example, such the method  is used in the "sub_example.run2" invoked method to apply additional execution behavior.
sub_example._run_options(){
    local OPTIND OPTARG skip=0
     while getopts ":-:c" option; do
        case "${option}" in
        c)
            is_contravariant="yes"
            local _is_contravariant=is_contravariant
        ;;
        #any '--' commands should be ignored.    
        -)
            ((++skip))
            ;;

        esac
    done
    # As an example, if somewhere in the method script there will be a check for the presence of a variable
    # This check is useful if the variable exists but an empty value is also a value.
    
    [ ! -v _is_contravariant ] && unset is_contravariant
    options_shift="$((OPTIND - 1 - skip))"
}

# Let's determine how to run methods covariantly or convariantly
# (default) Сovariant extension
sub_example.run2() {
    [ "$(readlink -f "${BASH_SOURCE[0]}")" != "$(readlink -f "$0")" ] && return
    # define local variables for options
    local is_contravariant options_shift
    # processing options
    sub_example._run_options $@ && shift $options_shift #; unset options_result
    if [ ! -v is_contravariant ]; then
        unset is_contravariant
        sub_example "$@"
    else
        sub_example._contravariantConstructor "$@"
    fi
}
sub_example.run2 $@

##API
## Test covariant
# `./sub_example.sh getGlobalVar` => Example 2: hello from example (constructor)
# `./example2.sh example getGlobalVar` =>  hello from example (constructor)
# contravariant
## Test contravariant
# `./sub_example.sh -c getGlobalVar` => hello from example (constructor)
# `./sub_example.sh -c sub_example getGlobalVar` =>Example 2: hello from example (constructor)
# `./sub_example.sh -c otherMethod` => otherMethod
# `./sub_example.sh -c otherMethod` => otherMethod

# `./sub_example.sh example sub_example example getGlobalVar` =>))))

# PS:By developing this behavior, the concept of namespaces develops. In the future, you can create a naming rule "{contributor}.{name_pack}.{name_method}"
# By adjusting the run method or constructor, the package of one contributor can be changed by another, observing the rules of the interface.
