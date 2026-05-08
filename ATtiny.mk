#
# Support for ATTiny boards
#
# You must install an ATTiny core package (default: ATTinyCore) to use this,
# then define ALTERNATE_CORE_PATH as the path to the root of the core package
# if it is not autodetected.
#
# To use Micronucleus, install the 'micronucleus' package
# and define MICRONUCLEUS as the path to the 'micronucleus' command
# if it is not autodetected.
#
# Use 'make ispload' to upload with an ISP
# and 'make microload' to upload with Micronucleus.
#
# Copyright (C) 2026 stygian-violet
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#

ifndef ARDMK_DIR
    ARDMK_DIR := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
endif

arduino_output =
ifndef ARDUINO_QUIET
    ARDUINO_QUIET = 0
endif
ifeq ($(ARDUINO_QUIET),0)
    ifeq ($(MAKE_RESTARTS),)
        ifeq ($(MAKELEVEL),0)
            arduino_output = $(info $(1))
        endif
    endif
endif

include $(ARDMK_DIR)/Common.mk

ALTERNATE_CORE ?= ATTinyCore
TIMER_CLOCK_SOURCE ?= default
ISP_PROG ?= usbasp
MICRONUCLEUS_OPTS ?= --no-ansi --run --timeout 60

$(call show_config_variable,HOME,[AUTODETECTED])

ifndef ALTERNATE_CORE_PATH
    ALTERNATE_CORE_PATH := $(firstword \
        $(wildcard $(HOME)/.arduino*/packages/$(ALTERNATE_CORE)/hardware/avr/*)\
        $(wildcard $(HOME)/Library/Arduino*/packages/$(ALTERNATE_CORE)/hardware/avr/*))
    $(call show_config_variable,ALTERNATE_CORE_PATH,$(if $(ALTERNATE_CORE_PATH),[AUTODETECTED],[NOT FOUND]))
    ifndef ALTERNATE_CORE_PATH
        echo $(error ALTERNATE_CORE_PATH is not defined)
    endif
else
    $(call show_config_variable,ALTERNATE_CORE_PATH,[USER])
endif

ifndef BOARDS_TXT
    BOARDS_TXT := $(ALTERNATE_CORE_PATH)/boards.txt
    $(call show_config_variable,BOARDS_TXT,[COMPUTED])
else
    $(call show_config_variable,BOARDS_TXT,[USER])
endif

ifndef CLOCK_SOURCE
    ifdef BOARD_CLOCK
        CLOCK_SOURCE := $(call PARSE_BOARD,$(BOARD_TAG),menu.(speed|clock|sketchclock).$(BOARD_CLOCK).build.clocksource)
    endif
    ifndef CLOCK_SOURCE
        CLOCK_SOURCE := $(call PARSE_BOARD,$(BOARD_TAG),build.clocksource)
    endif
    $(call show_config_variable,CLOCK_SOURCE,$(if $(CLOCK_SOURCE),[COMPUTED],[NOT FOUND]))
    ifndef CLOCK_SOURCE
        echo $(error CLOCK_SOURCE is not defined)
    endif
else
    $(call show_config_variable,CLOCK_SOURCE,[USER])
endif

ifndef PLL_SETTINGS
    ifdef TIMER_CLOCK_SOURCE
        PLL_SETTINGS := $(call PARSE_BOARD,$(BOARD_TAG),menu.TimerClockSource.$(TIMER_CLOCK_SOURCE).build.pllsettings)
    endif
    ifndef PLL_SETTINGS
        PLL_SETTINGS := $(call PARSE_BOARD,$(BOARD_TAG),build.pllsettings)
    endif
    $(call show_config_variable,PLL_SETTINGS,[COMPUTED])
else
    $(call show_config_variable,PLL_SETTINGS,[USER])
endif

CPPFLAGS += -DCLOCK_SOURCE=$(CLOCK_SOURCE) $(PLL_SETTINGS)

ifndef MICRONUCLEUS
    MICRONUCLEUS := $(firstword $(shell which micronucleus 2> /dev/null) \
        $(wildcard $(HOME)/.arduino*/packages/$(ALTERNATE_CORE)/tools/micronucleus/*/micronucleus) \
        $(wildcard $(HOME)/Library/Arduino*/packages/$(ALTERNATE_CORE)/tools/micronucleus/*/micronucleus))
    $(call show_config_variable,MICRONUCLEUS,$(if $(MICRONUCLEUS),[AUTODETECTED],[NOT FOUND]))
else
    $(call show_config_variable,MICRONUCLEUS,[USER])
endif

include $(ARDMK_DIR)/Arduino.mk

microload: $(TARGET_HEX) verify_size
ifndef MICRONUCLEUS
	@$(ECHO) $(error MICRONUCLEUS is not defined)
endif
	$(MICRONUCLEUS) $(MICRONUCLEUS_OPTS) $(TARGET_HEX)

.PHONY: microload
