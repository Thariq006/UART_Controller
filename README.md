# UART Controller using Verilog HDL

A UART (Universal Asynchronous Receiver/Transmitter) Controller designed using Verilog HDL. This project implements both transmitter (TX) and receiver (RX) modules using finite state machines (FSMs), configurable clock and baud-rate parameters, and serial data communication.

## Project Overview

The UART Controller supports asynchronous serial communication using an 8-bit data format. It includes independent transmitter and receiver state machines, baud-rate timing counters, shift registers, and an RX input synchronizer.

The project is verified using a Verilog testbench with a loopback connection between the transmitter and receiver.

## Features

- UART transmitter and receiver implementation.
- 8-bit data transmission.
- 8N1 communication format:
  - 1 Start bit
  - 8 Data bits
  - 1 Stop bit
  - No parity bit
- Configurable clock frequency and baud rate.
- Independent TX and RX finite state machines.
- LSB-first data transmission.
- Two-stage RX input synchronizer.
- Asynchronous active-high reset.
- TX busy and transmission-complete indicators.
- RX data-valid indicator.
- Loopback verification using a testbench.

## Architecture

The design consists of the following main blocks:

| Block | Description |
|---|---|
| UART Transmitter | Converts parallel 8-bit data into serial data. |
| UART Receiver | Converts incoming serial data into parallel 8-bit data. |
| TX FSM | Controls transmission states: IDLE, START, DATA, STOP. |
| RX FSM | Controls reception states: IDLE, START, DATA, STOP. |
| Baud-Rate Counter | Generates timing intervals for serial communication. |
| Shift Registers | Store and shift the transmitted and received data. |
| RX Synchronizer | Synchronizes the incoming RX signal to the system clock. |

## UART Configuration

The default RTL parameters are:

| Parameter | Default Value |
|---|---:|
| Clock Frequency | 50 MHz |
| Baud Rate | 9600 |
| Data Width | 8 bits |
| Start Bits | 1 |
| Stop Bits | 1 |
| Parity | None |

The testbench overrides the clock and baud-rate parameters for simulation:

- Clock Frequency: 1 MHz
- Baud Rate: 10,000

## Project Structure

```text
UART_Controller/
│
├── uart_controller.v       # UART transmitter and receiver RTL
├── tb_uart_controller.v    # UART verification testbench
├── uart.vcd                # Simulation waveform
├── uart_test               # Compiled simulation executable
├── README.md               # Project documentation
└── Screenshots             # Project and simulation screenshots
```

## Simulation and Verification

The testbench uses a loopback connection in which the transmitter output is directly connected to the receiver input.

```verilog
wire rx;
assign rx = tx;
```

The following data patterns are tested:

| Test | Transmitted Data |
|---|---|
| 1 | A5 |
| 2 | 3C |
| 3 | FF |
| 4 | 00 |
| 5 | 81 |

The testbench checks:

- Reset operation.
- UART idle state.
- Transmitter busy status.
- Correct received data.
- Transmission completion.
- TX busy signal clearing after transmission.

## Tools Used

- **HDL:** Verilog
- **Simulation:** Icarus Verilog
- **Waveform Viewer:** GTKWave
- **Version Control:** Git and GitHub

## How to Run the Simulation

### 1. Compile the Verilog files

```bash
iverilog -g2012 -o uart_test uart_controller.v tb_uart_controller.v
```

### 2. Run the simulation

```bash
vvp uart_test
```

### 3. View the waveform

```bash
gtkwave uart.vcd
```

## Expected Simulation Output

The testbench is designed to report the reset, idle-state, transmission, and reception checks for all five test patterns.

A successful run should conclude with:

```text
ALL UART TESTS PASSED
```

## Learning Outcomes

Through this project, the following digital design concepts are explored:

- Finite State Machine (FSM) design.
- Serial communication protocols.
- UART transmitter and receiver architecture.
- Baud-rate timing generation.
- Shift-register implementation.
- Clock-domain input synchronization.
- RTL simulation and waveform analysis.
- Functional verification using Verilog testbenches.

## Author

**Thariq**

GitHub: [Thariq006](https://github.com/Thariq006)

## Repository

[UART Controller – Verilog HDL](https://github.com/Thariq006/UART_Controller)
