# Default target
all: $(TARGET)

# Toolchain settings
CC := $(CC)
AS := $(AS)
SIZE := $(SIZE)

# Directories
SRC :=
INC_DIR :=
ARCH := $(ARCH)
BUILD_DIR := $(BUILD_DIR)/$(ARCH)
include include.mk
$(info  SRC:${SRC})
$(info  INC_DIR:${INC_DIR})
# Source files
C_SRCS := $(wildcard $(SRC)/**/*.c)
ASM_SRCS := $(wildcard $(SRC)/**/*.s)
OBJS := $(patsubst $(SRC)/%.c, $(BUILD_DIR)/%.o, $(C_SRCS)) $(patsubst $(SRC)/%.s, $(BUILD_DIR)/%.o, $(ASM_SRCS))
DEPS := $(OBJS:.o=.d)

# Compiler and linker flags
CFLAGS := $(CFLAGS) $(foreach dir, $(INC_DIR), -I$(dir))
LDFLAGS := $(LDFLAGS)

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build rules
$(BUILD_DIR)/%.o: $(SRC)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(SRC)/%.s | $(BUILD_DIR)
	$(AS) -c $< -o $@

$(TARGET): $(BUILD_DIR) $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $(BUILD_DIR)/$(TARGET)

clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)
