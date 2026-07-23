# Programming Languages: Session 2 -- Python theory companion script
#
# VS Code usage with the Microsoft Python extension:
# 1. Open this file in VS Code.
# 2. Select one line or a small block and press Shift+Enter to run it in the
#    Python terminal/REPL. If no terminal is active, VS Code will start one.
# 3. Work section by section. Some examples are intentionally commented out
#    because they demonstrate errors.

import copy
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
from urllib.request import urlopen

# -----------------------------------------------------------------------------
# 0. Where Python Fits (vs R and Julia)
# -----------------------------------------------------------------------------

# R:
#   Traditional statistics, econometrics workflows, and high-quality statistical
#   plotting.
# Julia:
#   High-performance modern numerical/scientific computing with near low-level
#   speed.
# Python:
#   Strong "glue" language across data collection, ML, and deployment.
#
# Python is especially strong for:
#   - APIs, web scraping, and automation workflows.
#   - Machine learning, NLP, and LLM tooling.
#   - Connecting analysis to production systems (apps, services, pipelines).


# -----------------------------------------------------------------------------
# 1. Primitives
# -----------------------------------------------------------------------------

# Slide: The primitives: a very quick refresher
# Numbers: int (e.g., 42), float (e.g., 3.14159)
# Booleans: bool -> True/False
# Strings: str -> immutable sequences of characters

# String: immutable sequence
course_name = "Programming Languages"
first_char = course_name[0]  # 'P'
# course_name[0] = "p"  # This would raise a TypeError!

is_phd_level = True
attendee_count = 25
pi_approx = 3.14

print(first_char)
print(type(is_phd_level), type(attendee_count), type(pi_approx))

# Slide: String formatting with f-strings
# f"Value is {x}" inserts values directly into strings (Python 3.6+).
x = 42
print(f"Value is {x}")

# String prefixes:
#   r"raw": backslashes are not escaped (regex, file paths).
#   u"unicode": mostly historical in Python 3.
#   b"bytes": bytes object, not text.
path = r"C:\Users\Name"
udata = u"unicode"
bdata = b"bytes"
print(path, udata, bdata)


# -----------------------------------------------------------------------------
# 2. Data containers
# -----------------------------------------------------------------------------

# Slide: List: Ordered & Mutable
# Common use: ordered collection that we may modify.
# Creation and modification
numbers = [1, 2, 30, 4]
numbers.append(5)  # [1, 2, 30, 4, 5]
numbers[2] = 3  # [1, 2, 3, 4, 5]
numbers.sort()  # [1, 2, 3, 4, 5]
print(f"List: {numbers}, Length: {len(numbers)}")

# Slide: Tuple: Ordered & Immutable
# Common use: fixed collections (coordinates, RGB colors, static records).
# Creation and access
point = (10.5, 20.3)
red_color = (255, 0, 0, "RED")
print(f"Point X: {point[0]}")
# point[0] = 5.0  # TypeError: tuple does not support item assignment

# Unpacking
x_coord, y_coord = point
print(f"Unpacked: x={x_coord}, y={y_coord}")

# Strings behave largely like tuples (immutable, indexable sequences),
# but provide string-specific methods.
print(red_color)

# Slide: Set: Unordered & Unique
# Common use: membership testing, de-duplication, set operations.
# Creation and uniqueness
ids = {101, 102, 103, 101, 104}  # effectively {101, 102, 103, 104}
ids.add(105)
ids.remove(101)
print(f"Set: {ids}")
print(f"Is 102 in set? {102 in ids}")

# Set operations
set_a = {1, 2, 3}
set_b = {3, 4, 5}
print(f"Union: {set_a | set_b}")
print(f"Intersection: {set_a & set_b}")

# Slide: Dictionary: Key-Value Mapping
# Common use: structured data and fast key lookup.
# Creation and access
student = {"name": "Alice", "id": 12345, "major": "CS"}
student["major"] = "Computer Science"  # Modify
student["year"] = 4  # Add
print(f"Student Name: {student['name']}")
print(f"Keys: {list(student.keys())}")

# Slide: Collections comparison
#
# |            | List | Tuple | Set | Dict      |
# |------------|------|-------|-----|-----------|
# | Ordered    | Yes  | Yes   | No  | Yes (3.7+)|
# | Mutable    | Yes  | No    | Yes | Yes       |
# | Duplicates | Yes  | Yes   | No  | Keys unique |
# | Syntax     | []   | ()    | {}  | {k:v}     |
#
# Lists: Modifiable sequences
# Tuples: Fixed records
# Sets: Unique items, membership tests
# Dicts: Structured data, fast lookups

# -----------------------------------------------------------------------------
# 3. Assignment & copying
# -----------------------------------------------------------------------------

# Slide: Assignment in Python: Reference, Not Copy
# For mutable objects, assignment creates another reference, not a copy.
# Most "complex" objects (for example, class instances) are mutable, so this
# same reference behavior usually applies there too.
a = [1, 2, 3]
b = a
print(a is b)  # True (same list object)
b[0] = 99
print(a)  # Output: [99, 2, 3]

# Slide: Immutable Types: Value-Like Behavior
# Immutable types cannot be changed in place. Rebinding creates a new object.
t1 = (1, 2, 3)
t2 = t1
t2 = t2 + (4,)
print(t1)  # (1, 2, 3)
print(t2)  # (1, 2, 3, 4)

# Slide: Functions Modify Mutable Arguments
# Mutable objects are passed to functions by reference.
def add_item(lst):
    lst.append(99)


mylist = [1, 2]
add_item(mylist)
print(mylist)  # [1, 2, 99]

# Same implication as before: changing a mutable object in a function also
# changes it outside the function.

# Slide: Copying Objects: Shallow vs Deep Copy
# .copy(): top-level only, deepcopy(): nested structures too
a = [1, 2, [3, 4]]

b = a.copy()  # shallow copy
b[0] = 99
b[2][0] = 42
print(a)  # [1, 2, [42, 4]]

c = copy.deepcopy(a)  # deep copy
c[2][0] = 100
print(a)  # [1, 2, [42, 4]]

# -----------------------------------------------------------------------------
# 4. Iteration
# -----------------------------------------------------------------------------

# Slide: For Loops: Basic and Nested
# Basic summation loop:
total = 0
for value in [3, 2, 19]:
    total += value
print(f"Total is: {total}")

# Nested for loops (sum over all value-weight products):
total = 0
for value in [2, 3, 19]:
    for weight in [3, 2, 1]:
        total += value * weight
print(f"Total is: {total}")

# Slide: Zip and Enumerate: Iterate Over Pairs with Indices
# Weighted average using zip():
total = 0
for value, weight in zip([2, 3, 19], [0.2, 0.3, 0.5]):
    total += weight * value
print(f"Weighted average is: {total}")

# Using enumerate() to access indices:
values = [2, 3, 19]
weights = [0.2, 0.3, 0.5]
for idx, (value, weight) in enumerate(zip(values, weights)):
    print(f"Index {idx}: value={value}, weight={weight}")

# Slide: List Comprehension: Concise Loop-Based Construction
# Syntax: [expression for item in iterable]
# Optional condition: [expression for item in iterable if condition]
numbers = [1, 2, 3, 4]
squares = [x**2 for x in numbers]
print(squares)  # [1, 4, 9, 16]

even_squares = [x**2 for x in numbers if x % 2 == 0]
print(even_squares)  # [4, 16]

# -----------------------------------------------------------------------------
# 5. Parallelization
# -----------------------------------------------------------------------------

# Slide: Threads vs Processes
# Threads share memory and run in one process.
# Processes have separate memory and run independently.
# Python provides both via threading/multiprocessing.
#
# Special Python quirk:
#   only one thread executes Python bytecode at a time (GIL).
#   So threads are mostly useful when waiting on I/O.
#
# Use threads for I/O-bound tasks.
# Use processes for CPU-bound tasks.
# For heavy number crunching, Python may not be the best choice.

# Slide: Comparison table
#
# | Feature       | threading      | multiprocessing     |
# |---------------|----------------|---------------------|
# | Memory        | Shared         | Separate            |
# | Bypasses GIL? | No             | Yes                 |
# | Use case      | I/O-bound tasks| CPU-bound tasks     |
# | Overhead      | Low            | Higher              |
# | Data sharing  | Easy           | Requires serialization |

def cube(x):
    return x**3


if __name__ == "__main__":
    # Note: On Windows, ProcessPoolExecutor must be run as a script,
    # not pasted into the interactive REPL.
    with ProcessPoolExecutor(max_workers=3) as executor:
        results = list(executor.map(cube, [1, 2, 3, 4]))
    print(results)  # [1, 8, 27, 64]

# High-level abstraction over multiprocessing with cleaner process-pool syntax.

def fetch_url(url):
    # I/O-bound: open URL and read bytes from the network.
    with urlopen(url, timeout=10) as response:
        return len(response.read(200))


urls = ["https://example.com", "https://example.com", "https://example.com"]
with ThreadPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(fetch_url, urls))

print(results)

# Ideal for waiting-heavy tasks (file/network access).
# Threads allow overlapping of I/O operations.
