# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **Betaflight CLI configuration dumps** for a **BetaFPV Meteor75 Pro** FPV drone (1S whoop). These are not source code files — they are flight controller configuration backups and tuned variants.

- **Flight controller board:** BETAFPVG473 (STM32G47X)
- **Firmware:** Betaflight 4.5.1
- **Motor protocol:** DSHOT300 with bidirectional DShot
- **Receiver protocol:** SBUS (fast baud enabled in V1)
- **PID profile:** Single profile ("GF 40mm") tuned for 1S with 40mm props

## File Structure

- `BTFL_cli_backup_M75_PRO_20260130_212146_BETAFPVG473 - original.txt` — Factory/stock CLI dump from the quad
- `M75_PRO_CLAUDE_CODE_V1.txt` — Modified configuration with the following key changes from original:
  - AUX channel reassignment (flight modes moved to AUX2/CH6, arm moved to AUX1/CH5, turtle mode on AUX5/CH9)
  - `sbus_baud_fast = ON` added
  - `vbat_max_cell_voltage` lowered from 440 to 435
  - `dyn_idle_min_rpm` raised from 30 to 75
  - Two named rate profiles: "Beginner" (rateprofile 0) with higher expo/lower srates, and "Stock" (rateprofile 1) preserving original rates
  - OSD layout adjustments (stick overlay, artificial horizon, repositioned elements)
  - `save` command added at end (original lacks it)

## Betaflight CLI Config Format

These files use `diff all` format — they only contain settings that differ from Betaflight defaults. They are applied by pasting into the Betaflight Configurator CLI tab.

Key sections in order: `defaults nosave` → board/MCU info → features → serial ports → beacons → aux modes → master settings → PID profiles → rate profiles → `save`.

## Working with These Files

- When modifying configs, preserve the `batch start` / `defaults nosave` header and the `save` footer
- AUX mode IDs: 0=ANGLE, 1=HORIZON, 2=ACRO (implicit), 13=BEEPER, 35=TURTLE
- AUX format: `aux <index> <mode_id> <channel> <range_low> <range_high> 0 0`
- Channel numbers in aux lines are 0-indexed (0=AUX1/CH5, 1=AUX2/CH6, etc.)
- OSD position values are encoded integers — use Betaflight Configurator OSD tab to calculate positions rather than editing raw values
