Assembler to Brainfuck translator
======

Supported:
----------

 - Registers
 - Stack(like C-string, can't store 0)
 - Strings and arrays

Basic types:
-----------------

 - Registers:
```nasm
mov ax 5 // ax = 5
mov bx 6 // bx = 6
sub ax bx // ax = 5 - 6 (mod 256) = 255

mov cx 12
mov dx 2 
mul cx dx // cx = 12 * 2 = 24

mov dx 10
div cx dx // division with remainder:  cx = 24 \ 10 = 2, dx = 24 % 10 = 4
```
 - Stack:
```nasm
mov ax 1
push ax
push 5
pop bx
pop cx // bx = 5, cx = 1 now

push 0 // wrong! undefined behaviour
```
 - Arrays:
```nasm
array test 10 // like C's : unsigned char test[10];
set test 0 42 // test[0] = 42
get test 0 ax // ax = test[0]
```
Also, register can be index of array, but then you can access only first 256 elements.

 - Strings:
```nasm
string hello "Hello, World!" // like C's: unsigned char hello[] = "Hello, World!";
puts hello // print string
```
Strings are arrays too:
```nasm
get hello 0 ax // ax = 'H'
put ax // prints 'H'
```
 Basic operations:
----------------------
 - IO:
```nasm
take ax // like C's: ax = getchar();
put ax // prints char in 'ax'
puts str // prints string in str variable
```
 - Loop:
```nasm
while ax // in while used one of registers
	// do smth.
endwhile
```
 - Comparing:
```nasm
mov ax 2
mov bx 1
cmp ax bx // compare, and now:

ne // not equal
    // actions in case registers are not equal
end

nl // not less
    // actions
end

ng // not greater
    // actions
end

eq // equal
    // actions
end

lt // less
    // actions
end

gt // greater
    // actions
end
```