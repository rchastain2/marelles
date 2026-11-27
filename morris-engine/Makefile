CXX      ?= g++
CC       ?= gcc
CXXFLAGS ?= -O2 -DNDEBUG
CFLAGS   ?= -O2
FPC      ?= fpc

BUILD := build
LIB   := $(BUILD)/libmorris-engine.so
CTEST := $(BUILD)/morristest-c
PTEST := $(BUILD)/morristest-pas

SRCS := morris-engine.cc algo_alphabeta.cc board.cc boardspec.cc gamehistory.cc rules.cc ttable.cc
OBJS := $(SRCS:%.cc=$(BUILD)/%.o)

LIB_CXXFLAGS := -std=c++20 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden \
                -DMORRIS_ENGINE_BUILD -Iinclude -Isrc -pthread -MMD -MP

.PHONY: all clean pascal test test-c test-pas

all: $(LIB) $(CTEST)

$(LIB): $(OBJS)
	$(CXX) -shared -pthread -Wl,-soname,libmorris-engine.so -o $@ $^

$(BUILD)/%.o: src/%.cc | $(BUILD)
	$(CXX) $(CXXFLAGS) $(LIB_CXXFLAGS) -c -o $@ $<

$(CTEST): test/morristest.c include/morris-engine.h $(LIB)
	$(CC) $(CFLAGS) -Iinclude -o $@ $< -L$(BUILD) -lmorris-engine -Wl,-rpath,'$$ORIGIN'

$(BUILD):
	mkdir -p $@

pascal: $(PTEST)

$(PTEST): test/morristest.pas morrislib.pas ../game.pas ../logfile.pas ../tables.inc | $(BUILD)
	mkdir -p $(BUILD)/units
	$(FPC) -Mobjfpc -Sh -O2 -l- -vewn -Fu. -Fu.. -Fi.. -FU$(BUILD)/units -FE$(BUILD) -omorristest-pas $<

test: test-c test-pas

test-c: $(CTEST)
	./$(CTEST) play 100 200

test-pas: $(PTEST) $(LIB)
	./$(PTEST)

clean:
	rm -rf $(BUILD)

-include $(OBJS:.o=.d)
