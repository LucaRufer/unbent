# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

BENDER ?= bender

REG_PATH = $(shell $(BENDER) path register_interface)
REG_TOOL = $(REG_PATH)/vendor/lowrisc_opentitan/util/regtool.py

REGS_HJSON = src/err_unit_regs.hjson

gen_regs:
	python $(REG_TOOL) $(REGS_HJSON) -t src -r
	python $(REG_TOOL) $(REGS_HJSON) -D > driver/bus_err_unit.h
