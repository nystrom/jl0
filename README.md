# Implementing a garbage collector for JL0

## Introduction

This assignment should be done in pairs.

This assignment is due before class on Friday, 29 May, at 18:00.
Please submit on github [here](https://classroom.github.com/g/pZmRz0kB).

# Overview

In this assignment, we have provided you with an interpreter for a
small subset of Julia, called JL0.

You will implement a simple garbage collector for this language.

This is essentially the language we gave you for the previous assignment, extended with
functions and structs (and bug fixes).

The interpreter is implemented as a translation from Julia expressions into abstract syntax trees
and then into a simple bytecode, which is evaluated using an operand stack.

## Getting started

Install Julia: `http://julialang.org`.

Run `julia main.jl` to get the JL0 REPL.

If you type an expression in the REPL, and it should print a value.

You can type `:q` into the REPL to quit.

## Language description

JL0 is a small subset of Julia.

It has the following features:

- integer arithmetic, including constants, `+`, `-`, `*`, and `/`
- booleans, including constants, `&&`, `||`, and `!`
- variables and assignment
- `if` expressions (and also conditional `?:` expressions)
- `while` expressions
- `begin` blocks
- `print` expressions
- `function` definitions and calls
- `struct` definitions and struct creation expressions
- field accesses and assignment

The syntax is identical to Julia's. Indeed the interpreter just uses Julia
parser to parse expressions.

The semantics differ in that only integers are supported. Booleans are
translated into the integers 0 and 1.  For instance `print true` will print `1`,
not `true`. The division operator `/` performs integer division (implemented as
`div` in Julia).

In addition, while loops evaluate to an integer (the loop iteration count, rather than to `nothing`).

Struct names must be uppercase (`Foo` not `foo`) to distinguish struct creation
expressions from function calls. Structs are mutable, even if not declared to be.

Only top-level functions are supported.

## Implementation

The Julia parser is used to parse single lines of code entered into a REPL
(`repl.jl`), which are translated and evaluated as described below.

The code is parsed as a Julia `Expr`. This is translated (`parse.jl`) into a
simpler abstract syntax tree (`syntax.jl`).

The AST is translated (`lower.jl`) into a vector of instructions (`insns.jl`).

Instructions are executed by the evaluator (`eval.jl`), which implements a
simple abstract machine.

The interpreter state is implemented in `state.jl`.
The state includes a stack of call frames and a heap as well as the vector
of instructions, a maps for looking up function and struct definitions.

The heap is implemented in `heap.jl`. This is the only file you need to modify
for this assignment.

## Interpreter state

The interpreter is implemented as an abstract machine.
The interpreter state is defined in `state.jl`.

A `State` consists of:

- a vector of instructions (`insns`),
- a program counter (`pc`),
- a map from instruction labels to instruction indices (`labels`),
- a map from function names to their definitions (`funcs`),
- a map from struct names to their definitions (`structs`),
- the call stack (`frames`), and
- the heap (`heap`).

A stack frame (`Frame`) contains an operand stack (`stack`), a
local variable store (`vars`), and the return address of the caller
function (`return_address`).

The heap is a vector of heap values, which can be either
- `nothing` (meaning the slot is unallocated),
- a struct tag (a `Symbol`),
- a mark bit,
- a value (either an `INT` or a `LOC`).

The heap is indexed via locations, defined as a `LOC` struct, which just wraps
an index into the `heap` vector. The location `LOC(0)` is used to represent
the null pointer, `nothing`.

Getting and setting fields are implemented in the functions `getfield`
and `putfield` in `heap.jl`.

Allocation is implemented in the function `alloc`, which searches the heap for
free space and returns the `LOC` of the first slot in the free block.
The algorithm used finds the first available space big enough. This isn't a very
good allocation algorithm, but is sufficient for this assignment.
The `alloc` function takes a struct tag and uses the `structs` dictionary to determine
how much spaces to allocate for the object.
The garbage collector (the `gc` function) is called from `alloc` when the heap runs out of space.

The following bytecode instructions are supported. See `insns.jl` for details.

- `LDC n` - push a constant on the stack
- `LD x` - push the local variable on the stack
- `ST x` - pop the stack and store into the given variable
- `ADD` - pop two values and push their sum
- `SUB` - pop two values and push their difference
- `MUL` - pop two values and push their product
- `DIV` - pop two values and push the lower divided by the upper
- `DUP` - duplicate: push the top value again
- `POP` - pop the top value and discard it
- `LABEL L` - a jump target label named `L`
- `JMP L` - jump to label `L`
- `JEQ L` - pop the stack and jump to `L` if `== 0`
- `JNE L` - pop the stack and jump to `L` if `!= 0`
- `JLT L` - pop the stack and jump to `L` if `< 0`
- `JGT L` - pop the stack and jump to `L` if `> 0`
- `JLE L` - pop the stack and jump to `L` if `<= 0`
- `JGE L` - pop the stack and jump to `L` if `>= 0`
- `PRINT` - print the value on top of the stack
- `STOP` - stop the program
- `CALL x` - call the named function, popping the arguments from the stack
- `RET` - return from the current function, popping the return value
- `NEW x` - create the named struct, popping the field initializers from the stack
- `GET x` - load the field `f`, popping the object address from the stack
- `PUT x` - store the field `f`, popping the value and the object address from the stack

## Assignment

In this assignment, you should implement a mark-sweep garbage collector on the heap.

You should trace the heap from the root set, marking all reachable objects. The root set is the operand stack (`stack`) and local variable store (`vars`) of each `Frame` of the call stack.

Anything reachable from the root set is not garbage. Anything else is garbage.

You'll need to modify the `alloc` function in heap.jl to add a mark bit to the object representation. Add a `MarkBit` after the tag, initializing to `Unmarked`.

Once marked, sweep the heap from the bottom, clearing any unmarked object by overwriting it with  `nothing` values. Reset the mark bit of any reachable objects to `Unmarked`.

You can assume (once you've changed `alloc`) that objects are laid out as follows.

Assume the definition

    struct Point
        x
        y
    end

Initially, the heap is a vector of `nothing`.

After evaluating the following statement:

    p = Point(1,2)

the heap will look like:

    [1] :Point   :: Symbol
    [2] Unmarked :: MarkBit
    [3] INT(1)   :: Value
    [4] INT(2)   :: Value
    [5] nothing  :: Nothing
    ...

The variable `p` will contain `LOC(1)`.
After another statement:

    q = Point(3,4)

Then the heap will look like:

    [1] :Point   :: Symbol
    [2] Unmarked :: MarkBit
    [3] INT(1)   :: Value
    [4] INT(2)   :: Value
    [5] :Point   :: Symbol
    [6] Unmarked :: MarkBit
    [7] INT(3)   :: Value
    [8] INT(4)   :: Value
    [9] nothing  :: Nothing
    ...

The variable `q` will contain `LOC(5)`.

After evaluating `p = nothing` and garbage collection (the function `gc`),
the heap should look like:

    [1] nothing  :: Nothing
    [2] nothing  :: Nothing
    [3] nothing  :: Nothing
    [4] nothing  :: Nothing
    [5] :Point   :: Symbol
    [6] Unmarked :: MarkBit
    [7] INT(3)   :: Value
    [8] INT(4)   :: Value
    [9] nothing  :: Nothing
    ...

Several tests are implemented in `test/runtests.jl`. The last two garbage collector tests should initially fail, but should succeed after you implement the garbage collector.
You may add more tests as desired. The script `test.sh` runs the test suite.
Or you can can type `]test` in the Julia REPL.

To help you debug, you can use the REPL to define functions and structs.
The command `:heap` will dump the current heap. The command `:gc` will run the garbage
collector manually.

