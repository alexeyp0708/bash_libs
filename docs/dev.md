# методичка разрабокти BASH

## Именование скриптов и их функций
Когда скрипты подключают кодовую базу других скриптов, то методы и переменные могут пересекаться.  ЧТобы исключить такое поведение, необходимо придерживаться единого правила именований функций.
Обявление скриптов и именований функций и переменных предлагается по принципу класов/методов/свойств.
Скрипт - класс
функция скрипта - метод
Глобальная переменная скрипта - свойство
(дальше по тексту функции - классы, методы свойства) 
Допустим ваш пакет называется ./example.sh
```bash
example.myFunc(){
    echo "Hello"
}
# конструктор скрипта
example(){
    "example.$@"
}
# если скрипт подключается в качестве пакета то не производим действующий вызов .  
[ -z  "$is_packed" ] && example "$@"

```

##  Поддержка скрипта способа разделения и расширения 
Любой автономный файл скрипта - это отдельный компонент который может использоваться как расширение кода другого компонента, так и для вызова его.
Поэтому файл должен обеспечивать оба варината использования.

Варианты 

```bash
    [ -z  "$is_packed" ] && example "$@"
```

```bash
     [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
```

для будущей совместимости необходимо помещать скрипт в исполняемый метод

```bash
example.run(){
    # здесь можно расположить дополнительный код распаковки. 
    #[ -z  "$is_packed" ] && example $@
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}
example.run $@
```

## Именование глобальных переменных (свойств)

имента переменны должны в начале названия иметь префикс названия скрипта (класса)

```bash
#супер глобальные переменные. Появляются всегда при интеграции скрипта.
example_var="hello"
```
Мы должны понимать что глобальные переменные "для всех" и в теории их можно использовать везде
## Место обявления переменных

Для будущей совместимости, рекомендуется обьявлять переменные в пределах вызываемого метода скрипта.

```bash

example.run(){
    # глобальные переменные инициализируются (или востанавливают свое состояние в глобальной области видимости при интеграции скрипта, при вызове скрипта, при прямом вызове метода.
    example_var="hello"
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}
# Чтобы предотвратить вызов, данную строку парсингом можно удалить/заменить и тогда приоритет обьявления глобальных переменных остается за текущим скриптом.
example.run $@

```

```bash
example(){
    # глобальные переменные обьявляются только при вызове, тем самым их нельзя глобально переопределить, так как конструктор оставляет за собой право владения переменными.
    example_var="hello"
    "example.$@"
}
```
 Выше указанные примеры обьявления переменных рекомендуется использовать если есть общие переменные использования 2х скриптов (единое пространство) 
 
 Но если скрипт автономен, рекомендуется изолировать (делать приватными) переменные и не обьявлять их в глобальной области видимости 
```bash

example.run(){
    # локальные переменные. Они будут видны методам при исполнении кода.
    local example_var="hello"
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}
example.run "$@"
```

Или в качестве оптимизации 

```bash
example(){
    # локальные переменные. Они будут видны методам при исполнении кода.
    local example_var="hello"
    "example.$@"
}
example.run(){
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}
example.run "$@"
```
Подразумевается что глобальная переменная будет испольховаться в любом контексте расширяемого скрипта (публичное свойство).
Поэтому если глобальная переменная объявлена, то подразумевается что формат переменных в будущем не ихменяется.
Если подразумевается что современем формат переменной будет изменяться, то ее следует обьявить как защищенную `_example_var="hello"` добавив префикс "_" к имени переменной. 

Тоже самое касается обьявление методов. Если метод используется в контексте скрипта и будет менять свой формат входных выходных данных, то должен обявляться через префикс "_" к имени метода.

Полный пример как должен выглядеть скрипт "./example.sh"
```bash
#!/bin/bash

#shared script space (super global vars)
#public var
example_var="hello"

#protected var
_example_var="bay"

#public method
example.var(){
    echo $example_var
}

#pivate method
example._var(){
        echo $_example_var
}

example.privateVar(){
    echo $example_private_var
}

example.privateVar2(){
    echo $example_private_var2
}

# constructor script
example(){
    local example_private_var="Bonjour"
    "example.$@"
}

example.run(){
    #variable will be used  only for direct calls from the external environment and one-time when expanding the current script
    local example_private_var2="Hi!"
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"
}

example.run "$@"

```
### Bспользование публичных методов через вызов

`./example.sh privateVar2`
`./example.sh privateVar`
`./example.sh var`



## Подключение скрипта ./example.sh
Если
./example.sh
```bash
#....

[  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && example "$@"

```
тогда 

./sub_example.sh
```bash
#/bin/bash

source ./example.sh 

#....

```
Если 
./example.sh
```bash
#....

[ -z  "$is_packed" ] && example "$@"

```
тогда ./sub_example.sh

```bash

# This is necessary if you need to explicitly indicate for an extension that it is used as a package.
# Declaration through a method is necessary so that the scope of is_packed is local and the script cannot globally override is_packed which can be used by other scripts 
example.source_unpacked(){
    local is_packed=yes
    source "source ./example.sh"
}
example.source_unpacked

#...

```

## Способ реализации наследования (использование методов дочернего скрипта или их прямой вызов)
Цель наследования - расширять функционал родительского скрипта, но и также для создания отладочных фикстур при создании тестов. 
 This will even be useful if you write entrypoint scripts, and each subsequent container can replace the extend entrypoint script of the parent container.

./sub_example.sh
```bash
source ./example.sh 

#...


# позволяет получить доступ к методам родительского скрипта.
sub_example.example(){
    "example $@" 
}

# Вызывает дочерний метод или родительский если дочернего метода нет.
# Сovariant extension
sub_example(){
    #substitution in inheritance
    [ type -t "example2.$1" == "function" ] && "sub_example.$@" || \
    [ type -t "example.$1" == "function" ] && "example.$@" || \
    echo "Fatal!" && exit 1
}

[  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && sub_example "$@"

```
или

```bash

# convariant extension
sub_example(){
    #substitution in inheritance
    [ type -t "example.$1" == "function" ] && "example.$@" || \
    [ type -t "example2.$1" == "function" ] && "sub_example.$@" || \
    echo "Fatal!" && exit 1
}

```
Цель ковариантности - когда  функционал родительского класса претерпивает изменения не влияя на поведение и это должно быть отражено в вызываемой команде в коде, не влияя на команду и использующий ее код.
Цель контрвариантности - когда  использование функционала родительского класса сохраняется в коде , но позваляет такой класс расширить дополнительными методами (командами).




## Полный скрипт sub_example

Дочерний скрипт ./sub_example.sh

./example2.sh
```bash
#!/bin/bash
source ./example.sh 

sub_example.subTest(){
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
#override the method
sub_example.var(){
    echo "Example 2 $(example var)"
}

sub_example.example(){
    example $@ 
}
sub_example(){
    #substitution in inheritance
    [ type -t "example2.$1" == "function" ] && "sub_example.$@" || \
    [ type -t "example.$1" == "function" ] && "example.$@" 
}

sub_example.run(){
    [  "$(readlink -f "${BASH_SOURCE[0]}")" == "$(readlink -f "$0")" ] && sub_example "$@"
}
sub_example.run $@
```

Тест переопределенного публичного метода example2.var  
`./example2.sh var`
Тест публичного метода example.var (прямой вызов)  
`./example2.sh example var`

Тест приватного метода example._var   
`./example2.sh _var`

Тест приватного метода example._var   (прямой вызов)
`./example2.sh example _var`
