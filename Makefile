DETECTED_OS := Unknown

# Check to see if we're using Windows,MSYS,MINGW,CYGWIN
ifeq ($(OS),Windows_NT)
# Look for ";" in PATH
# Windows and MSYS/MINGW/CYGWIN define OS as "Windows_NT"
# Only native Windows uses ";" in the PATH variable
ifeq '$(findstring ;,$(PATH))' ';'
    DETECTED_OS := Windows
else
	DETECTED_OS := Not_Windows
endif
endif

# Use uname to figure out what OS we're using
ifneq ($(DETECTED_OS),Windows)
	DETECTED_OS := $(shell uname 2>/dev/null || echo Unknown)
	DETECTED_OS := $(patsubst CYGWIN%,Cygwin,$(DETECTED_OS))
	DETECTED_OS := $(patsubst MSYS%,MSYS,$(DETECTED_OS))
	DETECTED_OS := $(patsubst MINGW%,MSYS,$(DETECTED_OS))
endif

ifeq ($(DETECTED_OS),Unknown)
	$(warning "Unknow operating system, assuming not Windows")
endif

# Define some utilities for Windows and the other operating systems
# These should be used throughout the Makefiles to keep everything OS agnostic
ifeq ($(DETECTED_OS), Windows)
	FIXPATH = $(subst /,\,$(1))
	MKDIR = mkdir $(call FIXPATH,$(1))
	RM =  if exist $(call FIXPATH,$(1)) del /q /f $(call FIXPATH,$(1))
	RMDIR = if exist $(call FIXPATH,$(1)) rmdir /q /s $(call FIXPATH,$(1))
	ECHO = echo $(1)
else
	FIXPATH = $(1)
	MKDIR = mkdir -p $(1)
	RM = rm -rf $(1)
	RMDIR = $(RM)
	ECHO = echo "$(1)"
endif

PREFIX=arm-none-eabi

# The command for calling the compiler.
CC=$(PREFIX)-gcc

CFLAGS=-mthumb \
	-mcpu=cortex-m4 \
	-mfpu=fpv4-sp-d16 \
	-Wa,-mimplicit-it=thumb \
	-ffunction-sections \
	-fdata-sections \
	-MD \
	-Wall \
	-Wno-format \
	-c

# Default location for the build directory
BUILD_DIR ?= build

# Source files being compiled
SRCS = main.c

# Convert empty and zero to non-verbose, otherwise print the verbose output
ifeq ($(VERBOSE),)
VERBOSE:=0
endif

ifeq ($(VERBOSE),0)
_VERBOSE:=@
else
_VERBOSE:=
endif

# Create output object file names
SRCS_NOPATH := $(foreach NAME,$(SRCS),$(basename $(notdir $(NAME))).c)
OBJS_NOPATH := $(SRCS_NOPATH:.c=.o)
OBJS        := $(OBJS_NOPATH:%.o=$(BUILD_DIR)/%.o)

# Target to make the build directory
$(BUILD_DIR):
	$(_VERBOSE)$(call MKDIR, $(BUILD_DIR))

# Target to make the object files
$(BUILD_DIR)/%.o: %.c $(BUILD_DIR)
	@$(call ECHO,  CC $<)
	$(_VERBOSE)$(CC) $(CFLAGS) -o $(@) $(<)

# Set the default goal
.DEFAULT_GOAL := all
.PHONY: all
all: $(OBJS)

# Debugging target to print variables being used
.PHONY: debug
debug:
	$(info $$DETECTED_OS [$(DETECTED_OS)])
	$(info $$CC [$(CC)])
	$(info $$MKDIR [$(MKDIR)])
	$(info $$RM [$(RM)])
	$(info $$RMDIR [$(RMDIR)])
	$(info $$ECHO [$(ECHO)])
	$(info $$OBJS [$(OBJS)])
	$(info $$BUILD_DIR [$(BUILD_DIR)])
	$(info $$FIXPATH [$(FIXPATH)])

# Target to clean the build directory
.PHONY: clean
clean:
	$(_VERBOSE)$(call RMDIR, $(BUILD_DIR))
