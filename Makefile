PATH := $(HOME)/Documents/oss-cad-suite/bin:$(PATH)

# ==============================================================================
# Variables & Defaults
# ==============================================================================

TOP ?= top
TB  ?= top_tb

DEVICE  = GW1NR-LV9QN88PC6/I5
FAMILY  = GW1N-9C

SRC_DIR   = src
TB_DIR    = tb
BUILD_DIR = build

SRCS    = $(wildcard $(SRC_DIR)/*.v)
TB_SRCS = $(wildcard $(TB_DIR)/*.v)

# ==============================================================================
# Targets
# ==============================================================================

.PHONY: all build upload sim clean

all: build

# 1. Synthesis (Yosys)
$(BUILD_DIR)/$(TOP).json: $(SRCS)
	@mkdir -p $(BUILD_DIR)
	yosys -p "read_verilog $(SRCS); synth_gowin -top $(TOP) -json $@"

# 2. Place & Route (nextpnr-himbaechel עם הגדרת המשפחה)
$(BUILD_DIR)/$(TOP)_pnr.json: $(BUILD_DIR)/$(TOP).json pins.cst
	nextpnr-himbaechel --device $(DEVICE) --vopt family=$(FAMILY) --json $< --vopt cst=pins.cst --write $@

# 3. Bitstream Generation (gowin_pack)
$(BUILD_DIR)/$(TOP).fs: $(BUILD_DIR)/$(TOP)_pnr.json
	gowin_pack -d GW1N-9C -o $@ $<

# 4. Build Target
build: $(BUILD_DIR)/$(TOP).fs

# 5. Upload to Tang Nano 9K
upload: $(BUILD_DIR)/$(TOP).fs
	openFPGALoader -b tangnano9k $<

# 6. Simulation
sim:
	@mkdir -p $(BUILD_DIR)
	iverilog -o $(BUILD_DIR)/sim.vvp $(SRCS) $(TB_DIR)/$(TB).v
	vvp $(BUILD_DIR)/sim.vvp

# 7. Clean
clean:
	rm -rf $(BUILD_DIR)