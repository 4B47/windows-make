ifeq ($(OS),Windows_NT) 
	DETECTED_OS := Windows
else
	DETECTED_OS := $(shell uname 2>/dev/null || echo Unknown)
	DETECTED_OS := $(patsubst CYGWIN%,Cygwin,$(DETECTED_OS))
	DETECTED_OS := $(patsubst MSYS%,MSYS,$(DETECTED_OS))
	DETECTED_OS := $(patsubst MINGW%,MSYS,$(DETECTED_OS))
endif

ifeq ($(DETECTED_OS), Windows)
	MKDIR = mkdir $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
	RM = $(wordlist 2,65535,$(foreach FILE,$(subst /,\,$(1)),& del /q $(FILE) > nul 2>&1)) || (exit 0)
	RMDIR = rmdir /q /s $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
	ECHO = echo $(1)
else
	MKDIR = mkdir -p $(1)
	RM = rm -rf $(1) > /dev/null 2>&1 || true
	RMDIR = $(RM)
	ECHO = echo "$(1)"
endif

PREFIX=arm-none-eabi

# The command for calling the compiler.
CC=${PREFIX}-gcc

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

BUILD_DIR ?= build

${BUILD_DIR}:
	$(call MKDIR, ${BUILD_DIR})

${BUILD_DIR}/%.o: %.c
	$(CC) $(CFLAGS) -o ${@} ${<}

# Set the default goal
.DEFAULT_GOAL := all
.PHONY: all
all: ${BUILD_DIR} ${BUILD_DIR}/main.o

.PHONY: debug
debug:
	$(info $$DETECTED_OS is [${DETECTED_OS}])
	$(info $$CC is [${CC}])
	$(info $$MKDIR is [${MKDIR}])
	$(info $$RM is [${RM}])
	$(info $$RMDIR is [${RMDIR}])
	$(info $$ECHO is [${ECHO}])

.PHONY: clean
clean:
	$(call RMDIR, $(BUILD_DIR))
