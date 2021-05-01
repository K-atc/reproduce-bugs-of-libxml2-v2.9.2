Reproduce bugs claimed by https://github.com/google/fuzzer-test-suite/tree/master/libxml2-v2.9.2
====


How to build & run
----
```shell
git submodule init
git submodule update
make reproduce
```


Sample output
----
### non crash input
```
$ ASAN_OPTIONS=symbolize=1 ASAN_SYMBOLIZER_PATH=/usr/local/bin/llvm-symbolizer ./xml-parser inputs/header-only.xml 
inputs/header-only.xml:1: parser error : Start tag expected, '<' not found
<?xml version="1.0" encoding="utf-8"?>
                                      ^
```

### crash input
```
$ make reproduce 
ASAN_OPTIONS=symbolize=1 ASAN_SYMBOLIZER_PATH=/usr/local/bin/llvm-symbolizer  ./xml-parser ./fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28 || echo
./fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28:1: parser error : Malformed declaration expecting version
<?xml encoding="UTF-32�BELLLLLLLLLLLLLLLhhhh'h1"#2
      ^
... snipped ...
=================================================================
==15634==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x621000002500 at pc 0x5585bde435b4 bp 0x7ffdaf7d59a0 sp 0x7ffdaf7d5990
READ of size 1 at 0x621000002500 thread T0
... snipped ...
```