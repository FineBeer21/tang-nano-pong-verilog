# FPGA Pong Game (Tang Nano 9K & ST7735 LCD)

A complete hardware implementation of the classic Pong arcade game written from scratch in Verilog HDL. The design runs on the **Sipeed Tang Nano 9K** (Gowin GW1NR-9 FPGA) and interfaces with a **1.8" ST7735 SPI TFT LCD** using an on-the-fly rendering architecture.

---

## Features

- **Hardware Rendering Pipeline:** Real-time, "racing-the-beam" style rendering directly to the SPI interface without utilizing internal Framebuffer memory.
- **Parametric Game Physics:** Collision detection logic with sub-pixel bounding box calculations and speed/direction vector routing.
- **Hardware Button Debouncer:** Multi-stage synchronization and digital debounce filtering for responsive paddle movement.
- **ST7735 Hardware Driver:** Custom state machine handling SPI bit-banging, LCD initialization sequence, and streaming continuous pixel color data.

---

## Hardware Architecture

The design is split into modular Verilog blocks:

- `top.v` – Top-level entity routing clocks, button inputs, display SPI pins, and interconnecting submodules.
- `pong_engine.v` – Game state machine managing paddle coordinates, ball velocity/direction registers, collision physics, and real-time pixel color determination.
- `st7735_driver.v` – SPI communication driver and initialization FSM for the ST7735 TFT display.
- `device_manager.v` – Central coordinator controlling frame timing and data synchronization.
- `button_debouncer.v` – Metastability protection and clock-domain digital filtering for hardware pushbuttons.

---

## Hardware Utilization (Tang Nano 9K)

Synthesized using the Gowin EDA / open-source toolchain for Gowin GW1NR-9:

| Resource | Used | Available | Utilization |
| :--- | :--- | :--- | :--- |
| **LUT4** | 1,068 | 8,640 | 12% |
| **ALU** | 712 | 6,480 | 10% |
| **DFF** | 213 | 6,480 | 3% |
| **BSRAM** | 0 | 26 | **0% (Zero Framebuffer Usage)** |
| **IOB** | 10 | 276 | 3% |

---

## Pinout Mapping (`pins.cst`)

| Signal | Tang Nano 9K Pin | Description |
| :--- | :--- | :--- |
| `clk` | 52 | 27 MHz On-board Crystal |
| `rst_n` | 4 | Reset (Active Low) |
| `tft_scl` | *(Assigned in CST)* | SPI Clock |
| `tft_sda` | *(Assigned in CST)* | SPI MOSI Data |
| `tft_res` | *(Assigned in CST)* | Display Hardware Reset |
| `tft_dc` | *(Assigned in CST)* | Data / Command Select |
| `tft_cs` | *(Assigned in CST)* | Chip Select |
| `btn_*` | *(Assigned in CST)* | Player 1 / Player 2 Paddle Controls |

---

## Build & Flash

Using open-source toolchain (Yosys + NextPNR + OpenFPGALoader) via `Makefile`:

```bash
make
make flash
