CC ?= gcc
CFLAGS ?= -O3 -fPIC -static

all: mimalloc.a

mimalloc.a: mimalloc.o
	ar rcs $@ $^

mimalloc.o: mimalloc/src/static.c
	$(CC) $(CFLAGS) -Imimalloc/include/ -c -o $@ $<

mimalloc/src/static.c:
	git submodule init && git submodule update

