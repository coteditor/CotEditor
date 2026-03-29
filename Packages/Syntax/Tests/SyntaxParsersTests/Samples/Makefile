# ---------------------------------------------
# Sample Makefile for tree-sitter-make testing
# ---------------------------------------------

SHELL := /bin/bash
.DEFAULT_GOAL := all

PROJECT := coteditor-sample
BUILD_DIR := build
BIN_DIR := $(BUILD_DIR)/bin
OBJ_DIR := $(BUILD_DIR)/obj
DEP_DIR := $(BUILD_DIR)/dep
SRC_DIR := src
TEST_DIR := tests
SCRIPT_DIR := scripts

CC := clang
CXX := clang++
AR := ar
RM := rm -f
MKDIR_P := mkdir -p

WARN_FLAGS := -Wall -Wextra -Wpedantic
OPT_FLAGS ?= -O2
DEBUG_FLAGS ?=
STD_FLAGS := -std=c11

CPPFLAGS := -Iinclude -MMD -MP
CFLAGS := $(STD_FLAGS) $(WARN_FLAGS) $(OPT_FLAGS) $(DEBUG_FLAGS)
LDFLAGS :=
LDLIBS := -lm

SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SOURCES))
DEPFILES := $(patsubst $(OBJ_DIR)/%.o,$(DEP_DIR)/%.d,$(OBJECTS))

TEST_SOURCES := $(wildcard $(TEST_DIR)/*.c)
TEST_BINS := $(patsubst $(TEST_DIR)/%.c,$(BIN_DIR)/test-%,$(TEST_SOURCES))

VERSION ?= dev
FEATURES ?= logging metrics

space := $(empty) $(empty)
comma := ,

ifeq ($(strip $(FEATURES)),)
  $(warning FEATURES is empty; defaulting to "logging")
  FEATURES := logging
endif

ifdef CI
  OPT_FLAGS := -O0
  DEBUG_FLAGS += -g3
  CFLAGS += -DCI_BUILD=1
else
  CFLAGS += -DNDEBUG
endif

# Reusable command macro
# $(call run,cmd,desc)
define run
	@printf "[%-10s] %s\n" "$(1)" "$(2)"
	@$(1)
endef

.PHONY: all build dirs clean distclean run test check fmt lint print-vars help package install uninstall

all: build

build: dirs $(BIN_DIR)/$(PROJECT)

dirs:
	@$(MKDIR_P) $(BUILD_DIR) $(BIN_DIR) $(OBJ_DIR) $(DEP_DIR)

$(BIN_DIR)/$(PROJECT): $(OBJECTS)
	$(call run,$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS),link $@)

# Compile C source to object
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(call run,$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@,cc $<)
	@cp $(OBJ_DIR)/$*.d $(DEP_DIR)/$*.d

# Test binary pattern rule
$(BIN_DIR)/test-%: $(TEST_DIR)/%.c | dirs
	$(call run,$(CC) $(CPPFLAGS) $(CFLAGS) $< -o $@ $(LDLIBS),cc-test $<)

test: $(TEST_BINS)
	@for t in $(TEST_BINS); do \
		echo "running $$t"; \
		$$t || exit 1; \
	done

check: lint test

run: build
	@$(BIN_DIR)/$(PROJECT) --version $(VERSION)

fmt:
	@$(SCRIPT_DIR)/format.sh $(SOURCES) $(TEST_SOURCES)

lint:
	@$(SCRIPT_DIR)/lint.sh $(SOURCES)

print-vars:
	@echo "PROJECT=$(PROJECT)"
	@echo "CFLAGS=$(CFLAGS)"
	@echo "SOURCES=$(SOURCES)"
	@echo "FEATURES=$(subst $(space),$(comma),$(FEATURES))"
	@echo "OBJECTS=$(words $(OBJECTS)) files"

package: build
	@tar -czf $(PROJECT)-$(VERSION).tar.gz -C $(BIN_DIR) $(PROJECT)

install: build
	@install -d /usr/local/bin
	@install -m 755 $(BIN_DIR)/$(PROJECT) /usr/local/bin/$(PROJECT)

uninstall:
	@$(RM) /usr/local/bin/$(PROJECT)

clean:
	@$(RM) $(OBJECTS) $(TEST_BINS)
	@$(RM) $(DEPFILES)

distclean: clean
	@$(RM) -r $(BUILD_DIR)
	@$(RM) $(PROJECT)-*.tar.gz

help:
	@echo "Targets:"
	@echo "  all build run test check fmt lint clean distclean"
	@echo "  package install uninstall print-vars help"
	@echo ""
	@echo "Variables (override with VAR=value):"
	@echo "  OPT_FLAGS DEBUG_FLAGS FEATURES VERSION"

# Optional local settings
-include local.mk
-include $(DEPFILES)
