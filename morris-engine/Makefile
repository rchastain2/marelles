CXX      ?= g++
CC       ?= gcc
CXXFLAGS ?= -O2 -DNDEBUG
CFLAGS   ?= -O2

BUILD := build
LIB   := $(BUILD)/libmorris-engine.so
CLI   := $(BUILD)/morris-cli

SRCS := morris-engine.cc algo_alphabeta.cc board.cc boardspec.cc gamehistory.cc rules.cc ttable.cc
OBJS := $(SRCS:%.cc=$(BUILD)/%.o)

LIB_CXXFLAGS := -std=c++20 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden \
                -DMORRIS_ENGINE_BUILD -Iinclude -Isrc -pthread -MMD -MP

.PHONY: all clean test

all: $(LIB) $(CLI)

$(LIB): $(OBJS)
	$(CXX) -shared -pthread -Wl,-soname,libmorris-engine.so -o $@ $^

$(BUILD)/%.o: src/%.cc | $(BUILD)
	$(CXX) $(CXXFLAGS) $(LIB_CXXFLAGS) -c -o $@ $<

$(CLI): test/morris-cli.c include/morris-engine.h $(LIB)
	$(CC) $(CFLAGS) -Iinclude -o $@ $< -L$(BUILD) -lmorris-engine -Wl,-rpath,'$$ORIGIN'

$(BUILD):
	mkdir -p $@

test: $(CLI)
	./$(CLI) play 100 200

clean:
	rm -rf $(BUILD)

-include $(OBJS:.o=.d)
