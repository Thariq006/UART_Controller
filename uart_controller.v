`timescale 1ns/1ps

module uart_controller #(
    parameter integer CLK_FREQ  = 50000000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       reset,

    // Transmitter Interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        tx,
    output wire       tx_busy,
    output reg        tx_done,

    // Receiver Interface
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid
);

    // Baud Rate Calculation
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // TX FSM States
    localparam TX_IDLE  = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA  = 2'b10;
    localparam TX_STOP  = 2'b11;

    // RX FSM States
    localparam RX_IDLE  = 2'b00;
    localparam RX_START = 2'b01;
    localparam RX_DATA  = 2'b10;
    localparam RX_STOP  = 2'b11;

    reg [1:0] tx_state;
    reg [1:0] rx_state;

    // Counters
    reg [31:0] tx_count;
    reg [31:0] rx_count;

    // Bit Counters
    reg [2:0] tx_bit_index;
    reg [2:0] rx_bit_index;

    // Shift Registers
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    // RX Synchronizer
    reg rx_sync1;
    reg rx_sync2;

    // TX Busy Indicator
    assign tx_busy = (tx_state != TX_IDLE);

    //==================================================
    // RX INPUT SYNCHRONIZER
    //==================================================

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end

        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end

    end

    //==================================================
    // UART TRANSMITTER FSM
    //==================================================

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            tx_state     <= TX_IDLE;
            tx_count     <= 0;
            tx_bit_index <= 0;
            tx_shift     <= 0;
            tx_done      <= 0;

        end

        else begin

            tx_done <= 1'b0;

            case (tx_state)

                // IDLE
                TX_IDLE: begin

                    tx_count <= 0;

                    if (tx_start) begin

                        tx_shift     <= tx_data;
                        tx_bit_index <= 0;
                        tx_state     <= TX_START;

                    end

                end

                // START BIT
                TX_START: begin

                    if (tx_count == CLKS_PER_BIT - 1) begin

                        tx_count <= 0;
                        tx_bit_index <= 0;
                        tx_state <= TX_DATA;

                    end

                    else begin

                        tx_count <= tx_count + 1'b1;

                    end

                end

                // DATA BITS (LSB FIRST)
                TX_DATA: begin

                    if (tx_count == CLKS_PER_BIT - 1) begin

                        tx_count <= 0;

                        if (tx_bit_index == 3'd7) begin

                            tx_state <= TX_STOP;

                        end

                        else begin

                            tx_bit_index <= tx_bit_index + 1'b1;

                        end

                    end

                    else begin

                        tx_count <= tx_count + 1'b1;

                    end

                end

                // STOP BIT
                TX_STOP: begin

                    if (tx_count == CLKS_PER_BIT - 1) begin

                        tx_count <= 0;
                        tx_state <= TX_IDLE;
                        tx_done <= 1'b1;

                    end

                    else begin

                        tx_count <= tx_count + 1'b1;

                    end

                end

                default: begin

                    tx_state <= TX_IDLE;
                    tx_count <= 0;

                end

            endcase

        end

    end

    //==================================================
    // TRANSMITTER OUTPUT LOGIC
    //==================================================

    always @(*) begin

        case (tx_state)

            TX_IDLE: begin
                tx = 1'b1;
            end

            TX_START: begin
                tx = 1'b0;
            end

            TX_DATA: begin
                tx = tx_shift[tx_bit_index];
            end

            TX_STOP: begin
                tx = 1'b1;
            end

            default: begin
                tx = 1'b1;
            end

        endcase

    end

    //==================================================
    // UART RECEIVER FSM
    //==================================================

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            rx_state     <= RX_IDLE;
            rx_count     <= 0;
            rx_bit_index <= 0;
            rx_shift     <= 0;
            rx_data      <= 0;
            rx_valid     <= 0;

        end

        else begin

            rx_valid <= 1'b0;

            case (rx_state)

                // IDLE
                RX_IDLE: begin

                    rx_count <= 0;

                    if (rx_sync2 == 1'b0) begin

                        rx_state <= RX_START;

                    end

                end

                // START BIT VALIDATION
                RX_START: begin

                    if (rx_count == (CLKS_PER_BIT / 2) - 1) begin

                        rx_count <= 0;

                        if (rx_sync2 == 1'b0) begin

                            rx_bit_index <= 0;
                            rx_state <= RX_DATA;

                        end

                        else begin

                            rx_state <= RX_IDLE;

                        end

                    end

                    else begin

                        rx_count <= rx_count + 1'b1;

                    end

                end

                // RECEIVE 8 DATA BITS
                RX_DATA: begin

                    if (rx_count == CLKS_PER_BIT - 1) begin

                        rx_count <= 0;

                        rx_shift[rx_bit_index] <= rx_sync2;

                        if (rx_bit_index == 3'd7) begin

                            rx_state <= RX_STOP;

                        end

                        else begin

                            rx_bit_index <= rx_bit_index + 1'b1;

                        end

                    end

                    else begin

                        rx_count <= rx_count + 1'b1;

                    end

                end

                // STOP BIT VALIDATION
                RX_STOP: begin

                    if (rx_count == CLKS_PER_BIT - 1) begin

                        rx_count <= 0;

                        if (rx_sync2 == 1'b1) begin

                            rx_data <= rx_shift;
                            rx_valid <= 1'b1;

                        end

                        rx_state <= RX_IDLE;

                    end

                    else begin

                        rx_count <= rx_count + 1'b1;

                    end

                end

                default: begin

                    rx_state <= RX_IDLE;
                    rx_count <= 0;

                end

            endcase

        end

    end

    // Parameter Check
    initial begin

        if (BAUD_RATE <= 0 || CLK_FREQ < BAUD_RATE * 2) begin
            $error("Invalid UART clock or baud-rate parameters");
        end

    end

endmodule
