# Programming Languages: Session 3 -- Theory
# R Basics
# Markus Brobeil
# GSEFM - First Year PhD Course

# -----------------------------------------------------------------------------
# Outline
# -----------------------------------------------------------------------------

# Where R Fits
# Python is our broad ecosystem language for scripting, web, automation, and much of applied machine learning.
# Julia is positioned where high-level numerical code and compiled-language performance need to coexist naturally.
# R is the most established language for statistics. If you walk into a statistics department and ask what language is being used, >90% of people will say R.
# R was created in the early 1990s by Ross Ihaka and Robert Gentleman at the University of Auckland, with the first public release in 1995.
# The tidyverse is a set of packages that has become the de facto standard way of using R for most applied data workflows.

# Core Types & Tensors

# Primitive Data Types in R
# R has several basic/primitive/atomic data types:

x_num <- 3.14        # numeric
x_int <- 2L          # integer (L for integer Literal)
x_char <- "hello"    # character
x_log <- TRUE        # logical
x_cplx <- 1 + 2i     # complex

typeof(x_num)   # "double"
typeof(x_int)   # "integer"
typeof(x_char)  # "character"
typeof(x_log)   # "logical"
typeof(x_cplx)  # "complex"

# Note the native support for complex numbers.

# Vectors, Matrices, and Arrays in R
# Vectors: 1D collections of elements.

x <- c(1, 3, 2, 5)   # Create a vector
length(x)            # Get length

# Matrices: 2D collections (filled column-wise by default!).

m <- matrix(1:4, nrow = 2, ncol = 2)      # 2x2 matrix
dim(m)                                 # Dimensions
m_byrow <- matrix(1:4, 2, 2, byrow = TRUE)

# Arrays: Multi-dimensional generalization of matrices (also column-major).

arr <- array(1:24, dim = c(2, 3, 4))     # 3D array
dim(arr)                                 # Dimensions
arr[1, 2, 3]                             # Access element
arr
# Vectors, Matrices, and Arrays Recap

# -----------------------------------------------------------------------------
# Data containers
# -----------------------------------------------------------------------------

# Lists
# Lists: (like a union of Python lists and dictionaries)

# Create a list with different types
my_list <- list(numbers = c(1, 2, 3),
                name = "Alice",
                flag = TRUE,
                mat = matrix(1:4, 2, 2))

# Access elements by name or position
my_list$name
my_list[["name"]]
my_list[[1]]

# Add or modify elements
my_list$new_item <- "Hello"
my_list$numbers <- c(10, 20)

# Data Frames
df <- data.frame(
    name = c("Alice", "Bob", "Carol"),
    age = c(25, 30, 22),
    score = c(90, 85, 88)
)
df
# Access columns
df$name
df[["age"]]
df[, "score"]

# Add a new column
df$passed <- df$score > 85
df
# Tidyverse equivalent is a tibble, which largely works the same way, but with better printing and subsetting.
# The Python analogon is of course a pandas DataFrame.

# Factors
# Factors are used to represent categorical data: (bit niche)

# Create a factor
gender <- factor(c("male", "female", "female", "male"))
gender

# Check levels
levels(gender)

# Change levels order
gender <- factor(gender, levels = c("male", "female"))
levels(gender)

# Summary of a factor
summary(gender)

# More or less a mapping from a (latent) integer to a string representation.

# Data Containers Recap

# -----------------------------------------------------------------------------
# Assignment & Copying
# -----------------------------------------------------------------------------

# Assignment & Copying in R vs Python
# R generally does not have the assignment-by-reference problem/feature that Python has.
# Technically, R also assigns by reference, but creates a copy the instance that changes are made. (Reduces memory footprint if none are made.)

x <- c(1, 2, 3)
y <- x      # No copy yet!
y[1] <- 99  # Now R copies x to y
print(x)    # x is unchanged: 1 2 3
print(y)    # y is: 99 2 3

# The only common objects that are copied by reference are data.table() (separate package) and environment(). It is unlikely that you will encounter either.

# Assignment & Copying Recap

# -----------------------------------------------------------------------------
# Iteration
# -----------------------------------------------------------------------------

# For Loops in R
# Simple for loop:

# Print numbers 1 to 5
for (i in 1:5) {
    print(i)
}

# Nested for loop:

# Print all pairs (i, j) for i, j in 1:3
for (i in 1:3) {
    for (j in 1:3) {
        print(paste("i =", i, ", j =", j))
    }
}

# Equivalents for zip() and enumerate() in R
# R equivalents for zip() and enumerate():

# zip(): iterate over two vectors in parallel
a <- c("A", "B", "C")
b <- c(10, 20, 30)
for (i in seq_along(a)) {
    print(paste(a[i], b[i]))
}

# enumerate(): get index and value
for (i in seq_along(a)) {
    print(paste("Index", i, "Value", a[i]))
}

# Elegant iteration

# apply: apply a function over rows or columns of a matrix
mat <- matrix(1:9, nrow = 3)
apply(mat, 1, sum) # Row sums
apply(mat, 2, mean) # Column means

# lapply: Takes in vector or list, and always returns a list
nums <- c(1, 2, 3, 4)
lapply(nums, function(x) x^2)

# sapply: Takes in vector or list, and tries to return a vector
sapply(nums, function(x) x^2)

# Fundamentally, same idea as list comprehension in Python.

# Vectorization in R
# Many R functions and operators work on entire vectors or matrices at once, this is called vectorization.
# This is essentially R telling its C implementation that it does not need to iterate over elements sequentially, but can apply the operation all at once.
# In this sense, vectorization is a primitive form of parallelization.
# Works mostly through parallelized numerical libraries like BLAS or LAPACK which make use of multi-threading and SIMD.
# Note that this works well with threads, but if the C backend had to create new processes, this would be much slower. Threads have very low overhead, see last lecture.

x = 1:5000000

# Slow: using an (elegant) for loop
y <- sapply(x, function(i) i^2)
y
# Fast: vectorized operation
y <- x^2
y
# Iteration Recap

# -----------------------------------------------------------------------------
# Parallelization
# -----------------------------------------------------------------------------

# Parallelization in Base R
# R provides built-in support for parallel computing via the parallel package (part of the R standard library):

library(parallel)

# Detect number of available cores
detectCores()

# Parallel version of lapply: mclapply (Unix/macOS only)
result <- mclapply(1:5000000, function(x) x^2, mc.cores = 2)

# For Windows or cross-platform: use parLapply with a cluster
cl <- makeCluster(24)  # Create a cluster with 24 workers
result <- parLapply(cl, 1:50000000, function(x) x^2)
stopCluster(cl)

# mclapply uses multiple processes via forking (not available on Windows). parLapply works on all platforms using clusters.

# Background: Parallelization in R
# snow (2003) introduced socket-based clusters, enabling parallelism across platforms and even across multiple machines.
# multicore (2009) leveraged Unix's fork() system call for process-based parallelism. Fast, but not available on Windows.
# parallel (2011): is part of base R, and combines multicore and snow under a unified interface.
# Summary: Use parallel for most parallel tasks in R. Choose mclapply() for simple, Unix-only jobs; use cluster-based functions (parLapply, parSapply) for cross-platform or distributed computing.
# Important note: In R, snow, multicore, and parallel are process-based (separate R workers), not thread-based. Threading in R is mostly provided by native libraries/packages (e.g., BLAS/OpenMP), not as the main user-level parallel model.

# Parallelization Recap
