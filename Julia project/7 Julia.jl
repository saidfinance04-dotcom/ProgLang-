# Programming Languages: Session 4 -- Julia theory companion script
#
# VS Code usage with the Julia extension:
# 1. Open this file in VS Code.
# 2. Start a Julia REPL with the command palette: "Julia: Start REPL".
# 3. Select a line or block and press Alt+Enter to execute it in the REPL.
#
# Teaching use:
# This script is a runnable translation of the slides. Comments carry the verbal
# content; code blocks mirror the slide snippets.

# -----------------------------------------------------------------------------
# 0. Overview
# -----------------------------------------------------------------------------

# Slide: Outline
# - Core Types & Tensors
# - Data containers
# - Assignment & Copying
# - Iteration
# - Parallelization
# - Julia-Specific Behavior

# Slide: Where Julia Fits
# - Python is a "glue language" for scripting, web, automation, and much of
#   applied machine learning.
# - R is the traditional language for statistics, econometrics, and fast and
#   elegant exploratory visualization.
# - Julia is positioned where high-level productivity and low-level numerical
#   performance are both central.
# - Julia development started at MIT in 2009 (Jeff Bezanson, Stefan Karpinski,
#   Viral B. Shah, and Alan Edelman), with a first public release in 2012 and
#   stable 1.0 in 2018.
# - Julia's central philosophy is to solve the "two-language problem" by
#   allowing high-level code without giving up compiled-language speed.

# Slide: Julia's Design Influences
#
# | Influence       | What Julia Inherits |
# |-----------------|----------------------|
# | MATLAB          | Linear algebra syntax, 1-based indexing, array-first numerical computing, interactive scientific workflow |
# | R               | Statistical computing orientation, data analysis culture, vectorized workflows |
# | Python          | Readable general-purpose scripting, comprehensions, ecosystem-like usability, NumPy-style vectorized thinking (including dot-broadcasting workflows) |
# | Lisp / Scheme   | Macros (@time, @views, @threads), code-transforming-code |
# | CLOS / Dylan    | Multiple dispatch as a central abstraction mechanism |
# | Fortran & C/C++ | High-performance numerical computing, column-major arrays, systems interoperability, explicit control when needed |


# -----------------------------------------------------------------------------
# 1. Core Types & Tensors
# -----------------------------------------------------------------------------

# Slide: Primitive Data Types in Julia
# Julia has several basic/primitive/atomic data types.
x_num = 3.14        # Float64
x_int = 2           # Int64 (no special suffix needed)
x_str = "hello"     # String
x_log = true        # Bool
x_cplx = 1 + 2im    # Complex{Int64}

# Note the native support for complex numbers (using im instead of i).

# String interpolation is done with $.
name = "Julia"
println("Hello, $name")

# Slide: Vectors, Matrices, and Arrays
# Arrays/Vectors: 1D collections of elements.
x = [1, 3, 2, 5]    # Create a vector
length(x)        # Get length

# Matrices: 2D collections (filled column-wise by default, like R).
m = reshape(1:4, 2, 2)                    # 2x2 matrix
size(m)                                   # Dimensions
m_byrow = [1 2; 3 4]                      # Row-wise construction

# Multi-dimensional Arrays: N-dimensional generalization (also column-major).
arr = reshape(1:24, 2, 3, 4)              # 3D array
size(arr)                                 # Dimensions
arr[1, 2, 3]                              # Access element


# -----------------------------------------------------------------------------
# 2. Data containers
# -----------------------------------------------------------------------------

# Slide: Tuples, Named Tuples, and Sets
# Tuples: Ordered, immutable fixed-size collections.
t = (10.5, 20.3)
t[1]

# Named Tuples: Immutable structured records.
nt = (numbers = [1, 2, 3], name = "Alice", flag = true)
nt.name  # Access by name
nt.numbers[2]
# Sets: Unordered collections of unique elements, useful for membership tests.
s = Set([1, 2, 2, 3])
push!(s, 4)                      # Add element
in(2, s)                         # Check membership
setdiff(s, Set([2, 3]))          # Set difference

# Slide: Dictionaries
# Dictionaries: Key-value pairs (like Python dictionaries).
# Create a dictionary with different types.
my_dict = Dict(
    "numbers" => [1, 2, 3],
    "name" => "Alice",
    "flag" => true,
    "mat" => [1 2; 3 4],
)

# Access elements by key.
my_dict["name"]

# Add or modify elements.
my_dict["new_item"] = "Hello"
my_dict["numbers"] = [10, 20]
my_dict
# Slide: Python vs Julia Containers
#
# | Python | Julia                   | Typical Use |
# |--------|-------------------------|-------------|
# | list   | Vector/Array            | Ordered mutable sequence |
# | tuple  | Tuple/NamedTuple        | Fixed immutable record |
# | set    | Set                     | Unique elements, fast membership |
# | dict   | Dict                    | Key-value mapping |
#
# Julia's vectors do overlap with Python lists in terms of mutability and
# order, but should be thought of more as mathematical vectors (homogenous,
# fixed-type arrays). Python's lists are more general-purpose containers that
# can hold mixed types. Julia's vectors can do the same, but are primarily
# designed for numerical computing with homogenous types.


# -----------------------------------------------------------------------------
# 3. Assignment & Copying
# -----------------------------------------------------------------------------

# Slide: Assignment & Copying in Julia vs Python/R
# Julia behaves like Python here: assignment binds another name to the same
# object. Mutable objects (tensors, dictionaries) are shared by reference.
# Use copy() for a shallow copy and deepcopy() for fully independent nested
# mutable structures.
x = [[1, 2],5,[3, 4]]
y = x                 # reference (same nested arrays)
y[1][1] = 99
println(x)            # [[99, 2], [3, 4]]

s = copy(x)           # shallow copy (outer container copied)
s[1][1] = 77
s[2] = 55
s[3][1] = 88
s
x
println(x)            # still changes: [[77, 2], [3, 4]]
println(s) 
d = deepcopy(x)       # deep copy (nested containers copied too)
d[1][1] = -1
println(x)            # unchanged by deep copy mutation
println(d)            # independent nested structure


# -----------------------------------------------------------------------------
# 4. Iteration
# -----------------------------------------------------------------------------

# Slide: For Loops in Julia
# Simple for loop.
for i in 1:5
    println(i)
end

# Nested for loops.
for i in 1:3
    for j in 1:3
        println("i = $i, j = $j")
    end
end

# Slide: zip() and enumerate() in Julia
# Julia has built-in zip() and enumerate().
a = ["A", "B", "C"]
b = [10, 20, 30]
for (x, y) in zip(a, b)
    println("$x $y")
end

for (i, val) in enumerate(a)
    println("Index $i Value $val")
end

# Much cleaner than R's seq_along() approach.

# Slide: Advanced iteration patterns
# Julia provides many iteration utilities and patterns.
# Comprehensions (like Python).
squares = [x^2 for x in 1:5]
squares
# Generator expressions (lazy evaluation).
squares_gen = (x^2 for x in 1:5)
squares_gen
# Filtering with comprehensions.
evens = [x for x in 1:10 if x % 2 == 0]
evens
# Multiple iterators.
[(i, j) for i in 1:3, j in 1:3]

# Comprehensions and broadcasting are often the most "Julian"
# (cf. "Pythonic") way to iterate.

# Slide: Prefer Vectorization and Broadcasting
# - Julia supports vectorization through broadcasting with the dot operator (.).
# - Broadcasting applies operations element-wise and is highly optimized.
# - Julia's approach is more explicit than R's automatic vectorization.

# Slow: using a for loop.
x = 1:100000000
y = zeros(length(x))
y
for i in eachindex(x)
    y[i] = x[i]^2
end

# Fast: broadcasting.
y = x .^ 2

# Note: Julia's broadcasting can be very fast and, for type-stable code,
# can approach hand-optimized C performance.


# -----------------------------------------------------------------------------
# 5. Parallelization
# -----------------------------------------------------------------------------

# Slide: Background: Julia's Parallel Computing Model
# - Threads share memory and have low creation/communication overhead, so they
#   are usually ideal for speed within one machine.
# - Processes are separate workers with separate memory, useful for isolation
#   and distributed workloads.
# - Julia supports both models directly and without the core constraints seen
#   in Python and base R.
# - Python threads are limited for CPU-bound work by the GIL, and base R only
#   exposes process-based parallelism at user level.
# - So among the three languages in this course, Julia has the strongest
#   built-in parallel model for general compute workloads.
# Rule of thumb: use threads first for shared-memory CPU work, and use
# processes for independent tasks across workers or machines.

# Slide: Parallelization in Base Julia
# The simplest way to parallelize is to use the @distributed macro for loops,
# which automatically distributes iterations across available processes.
using Distributed

# Add worker processes.
addprocs(2)  # Add 2 worker processes
nprocs()     # Check total number of processes

# Distributed for loop with @distributed.
sum_result = @distributed (+) for i = 1:100
    i^2
end
println(sum_result)  # Sum of squares 1^2 + 2^2 + ... + 100^2

# Slide: Multi-threading in Julia
# Start Julia with "julia -t 4" to use 4 threads, or set
#  as an environment variable.
using Base.Threads
println("Number of threads: $(nthreads())")
julia -t 4

# Parallel for loop with threading.
result = zeros(1000)
@threads for i = 1:1000
    result[i] = i^2
end


# -----------------------------------------------------------------------------
# 6. How is Julia so fast?
# -----------------------------------------------------------------------------

# Slide: JIT Compilation
# Julia uses just-in-time compilation. The first call to a new method includes
# compilation time.
function jit_demo(x)
    s = zero(eltype(x))
    for xi in x
        s += sin(xi)^2 + cos(xi)^2
    end
    return s
end

x = rand(10_000)

@time jit_demo(x)  # compilation + execution
@time jit_demo(x)  # mostly execution

# Slide: Types
# Because Julia is implemented in C, every variable has a concrete type under the hood.
# High-level languages like Python and R do not make you define types explicitly,
# but if you want to you can by using :: to assert or restrict types.
x = 5
typeof(x)          # Float64

y::Float64 = 2.5 # explicit variable type
typeof(y) # Float64
y = 5    # explicit variable type
typeof(y)           # Float64

f(x::Float64) = x^2 + 1
f(2.0)             # works
f(2)               # MethodError because Float inputs are enforced

# Slide: Type Stability
# Julia is fastest when it can infer concrete types. Type annotations can help
# when the intended type is ambiguous.
# Can return Int64 or Float64.
unstable(x) = x > 0 ? x^2 : 0.0

# Always returns Float64.
stable(x)::Float64 = x > 0 ? x^2 : 0.0

unstable(2)    # 4
unstable(-2)   # 0.0

stable(2)      # 4.0
stable(-2)     # 0.0

# The first function has return type Union{Int64, Float64}.
# The second makes the intended return type explicit.
