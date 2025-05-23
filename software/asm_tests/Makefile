EXTENT := rv32ui
SHELL := $(shell which bash) -o pipefail
TESTS := $(notdir $(shell find isa/$(EXTENT) -type f -name "*.S"))
TESTS_HEX := $(subst .S,.hex,$(TESTS))
GCC_OPTS := -march=rv32im -mabi=ilp32 -static -mstrict-align -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -T ../linker_script.ld -Wl,--build-id=none

RISCV_PACKAGE := riscv64-linux-gnu
RISCV_DEFAULT := riscv64-unknown-elf
RISCV_DEFAULT_PRESENT := $(shell command -v $(RISCV_DEFAULT)-gcc 2> /dev/null)

ifdef RISCV_DEFAULT_PRESENT
    RISCV := $(RISCV_DEFAULT)
else
    RISCV := $(RISCV_PACKAGE)
endif

all: $(TESTS_HEX)

%.hex: isa/$(EXTENT)/%.S
	$(RISCV)-gcc $(GCC_OPTS) -Iheaders -Iisa/macros/scalar $^ -o $(basename $(notdir $^)).elf
	$(RISCV)-objdump -D -Mnumeric $(basename $(notdir $^)).elf > $(basename $@).dump
	$(RISCV)-objcopy $(basename $@).elf -O binary $(basename $@).bin
	$(RISCV)-bin2hex -w 32 $(basename $@).bin $(basename $@).hex
	sed -i '1i @0' $(basename $@).hex

clean:
	rm -f *.elf *.bin *.hex *.dump
