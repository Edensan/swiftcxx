# Swift <-> Cxx interop sample

This repo showcases a minimalist setup to C++ <-> Swift interop.

Requirements:
- LLVM & Swift have to be installed on your system
- "swiftc" command has to be accessible from the terminal
  - Everything else will be deduced using "where swiftc" (version and other paths)
  
Todo:
- Move dependencies to a 3rdparty subdirectory & strip out unnecessary stuff
- Add more tests to document basic interop rules
