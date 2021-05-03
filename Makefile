TARGET := xml-parser 
TARGET_NOASAN := xml-parser.noasan

LIBXML2_DIR_NAME := libxml2
LIBXML2_LIB_DIR := $(LIBXML2_DIR_NAME)/.libs
LIBXML2_LIB_ORIG_NAME := libxml2.a
LIBXML2_LIB_ASAN_NAME := libxml2-asan.a
LIBXML2_LIB_NOASAN_NAME := libxml2-noasan.a
CRASH_FILE := fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28

CXXFLAGS := -g -O2 
CFLAGS_ASAN := -fno-omit-frame-pointer -fsanitize=address -fsanitize-address-use-after-scope
CFLAGS := $(CXXFLAGS)

ASAN_OPTIONS := symbolize=1
ASAN_SYMBOLIZER_PATH := $(shell which llvm-symbolizer) 

all: $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_ASAN_NAME) $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NOASAN_NAME) $(TARGET) $(TARGET_NOASAN)
	@

$(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_ASAN_NAME): 
	cd $(LIBXML2_DIR_NAME) && git checkout -f v2.9.2
	cd $(LIBXML2_DIR_NAME) && ./autogen.sh
	cd $(LIBXML2_DIR_NAME) && CCLD="$(CC) $(CFLAGS) $(CFLAGS_ASAN)" ./configure \
		--enable-static --disable-shared \
		--without-python --with-threads=no \
		--with-zlib=no --with-lzma=no
	cd $(LIBXML2_DIR_NAME) && make -j $(nproc)
	mv $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_ORIG_NAME) $@
	ls $@

$(TARGET): target.cc
	$(CXX) $(CXXFLAGS) $(CFLAGS_ASAN) -I $(LIBXML2_DIR_NAME)/include \
		target.cc \
		-L$(LIBXML2_LIB_DIR) -l:$(LIBXML2_LIB_ASAN_NAME) \
		-o $@

$(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NOASAN_NAME): 
	cd $(LIBXML2_DIR_NAME) && git checkout -f v2.9.2
	cd $(LIBXML2_DIR_NAME) && ./autogen.sh
	cd $(LIBXML2_DIR_NAME) && CCLD="$(CC) $(CFLAGS)" ./configure \
		--enable-static --disable-shared \
		--without-python --with-threads=no \
		--with-zlib=no --with-lzma=no
	cd $(LIBXML2_DIR_NAME) && make -j $(nproc)
	mv $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_ORIG_NAME) $@
	ls $@

$(TARGET_NOASAN): target.cc
	$(CXX) $(CXXFLAGS) -I $(LIBXML2_DIR_NAME)/include \
		target.cc \
		-L$(LIBXML2_LIB_DIR) -l:$(LIBXML2_LIB_NOASAN_NAME) \
		-o $@

clean: 
	rm -f $(TARGET) $(LIBXML2_LIB_DIR)/{$(LIBXML2_LIB_ASAN_NAME),$(LIBXML2_LIB_NOASAN_NAME)}

generate-inputs: $(CRASH_FILE)
	python3 scripts/triming.py $< 0 16
	python3 scripts/triming.py $< 0 32
	python3 scripts/triming.py $< 0 48

reproduce: $(CRASH_FILE) $(LIBXML2_LIB_DIR)/$(LIBXML2_LIB_NAME) $(TARGET)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 16)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 24)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 32)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) $$(python3 scripts/triming.py $< 0 48)
	ASAN_OPTIONS=$(ASAN_OPTIONS) ASAN_SYMBOLIZER_PATH=$(ASAN_SYMBOLIZER_PATH) ./$(TARGET) ./fuzzer-test-suite/libxml2-v2.9.2/crash-50b12d37d6968a2cd9eb3665d158d9a2fb1f6e28
