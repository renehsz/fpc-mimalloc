# fpc-mimalloc
A fast freepascal memory manager using Microsoft's state-of-the-art [`mimalloc`](https://github.com/microsoft/mimalloc) allocator.

## Build
Simply build using the Makefile, optionally specifying the compiler to use in the `CC` environment variable.

```sh
make
```

## Usage
Make sure the unit `fpc_mimalloc` is the first unit included in your program, so that all other units allocate memory with this allocator.

```pascal
uses fpc_mimalloc, SysUtils, ...;
```

## LICENSE
The code in this repository is free and unencumbered software released into the public domain.
The license of the mimalloc library can be found in the LICENSE file of the mimalloc submodule.

