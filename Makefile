TARGET := xml-parser

LIBXML2_DIR_NAME := libxml2
LIBXML2_LIB_DIR := $(LIBXML2_DIR_NAME)/.libs
LIBXML2_LIB_NAME := libxml2.a
CRASH_FILE := fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28

# CC := clang
# CXX := clang++
# CXXFLAGS := -g -fno-omit-frame-pointer -fsanitize=address 
CXXFLAGS := -g -O2 -fno-omit-frame-pointer -fsanitize=address -fsanitize-address-use-after-scope
CFLAGS := $(CXXFLAGS)

ASAN_OPTIONS := symbolize=1
ASAN_SYMBOLIZER_PATH := $(shell which llvm-symbolizer) 

all: $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NAME) $(TARGET)
	@

$(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NAME): 
	cd $(LIBXML2_DIR_NAME) && git checkout -f v2.9.2
	cd $(LIBXML2_DIR_NAME) && ./autogen.sh
	cd $(LIBXML2_DIR_NAME) && CCLD="$(CC) $(CFLAGS)" ./configure \
		--enable-static --disable-shared \
		--without-python --with-threads=no \
		--with-zlib=no --with-lzma=no
	cd $(LIBXML2_DIR_NAME) && make CFLAGS="$(CFLAGS)" -j $(nproc)
	ls $@

$(TARGET): target.cc
	$(CXX) $(CXXFLAGS) -I $(LIBXML2_DIR_NAME)/include \
		target.cc \
		-L$(LIBXML2_LIB_DIR) -l:$(LIBXML2_LIB_NAME) \
		-o $@

clean: 
	rm -f $(TARGET) $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NAME)

generate-inputs: $(CRASH_FILE)
	python3 scripts/triming.py $< 0 16
	# python3 scripts/triming.py $< 0 24
	python3 scripts/triming.py $< 0 32
	# python3 scripts/triming.py $< 0 40
	python3 scripts/triming.py $< 0 48
	# python3 scripts/triming.py $< 0 56

reproduce: $(CRASH_FILE) $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NAME) $(TARGET)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 16)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 24)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 32)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 48)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) ./fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28
