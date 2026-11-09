`timescale 1ns/1ps

module tb_uart_controller;

    reg clk;
    reg reset;

    reg [7:0] tx_data;
    reg tx_start;

    wire tx;
    wire tx_busy;
    wire tx_done;

    wire [7:0] rx_data;
    wire rx_valid;

    integer errors;

    // Loopback: TX connected to RX
    wire rx;
    assign rx = tx;

    //==================================================
    // DUT INSTANTIATION
    //==================================================

    uart_controller #(
        .CLK_FREQ(1000000),
        .BAUD_RATE(10000)
    ) DUT (

        .clk(clk),
        .reset(reset),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),

        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)

    );

    //==================================================
    // CLOCK GENERATION
    //==================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    //==================================================
    // RESET TASK
    //==================================================

    task reset_system;
    begin

        reset = 1'b1;

        tx_data = 8'h00;
        tx_start = 1'b0;

        repeat(5) @(negedge clk);

        reset = 1'b0;

        repeat(5) @(negedge clk);

        $display("PASS: RESET COMPLETED");

    end
    endtask

    //==================================================
    // UART TRANSMISSION AND RECEPTION TEST
    //==================================================

    task send_and_check;

        input [7:0] test_data;

    begin

        // Apply input data
        @(negedge clk);

        tx_data = test_data;
        tx_start = 1'b1;

        @(negedge clk);

        tx_start = 1'b0;

        $display("--------------------------------");
        $display("TRANSMITTING DATA: %h", test_data);

        // Check transmitter busy
        if (tx_busy !== 1'b1) begin

            $display("FAIL: TX BUSY");

            errors = errors + 1;

        end

        // Wait for receiver
        wait(rx_valid == 1'b1);

        #1;

        // Compare received data
        if (rx_data !== test_data) begin

            $display("FAIL: DATA MISMATCH");

            $display("EXPECTED: %h", test_data);
            $display("RECEIVED: %h", rx_data);

            errors = errors + 1;

        end

        else begin

            $display("PASS: DATA RECEIVED CORRECTLY");

            $display("RECEIVED DATA: %h", rx_data);

        end

        // Wait for transmitter completion
        wait(tx_done == 1'b1);

        #1;

        if (tx_busy !== 1'b0) begin

            $display("FAIL: TX BUSY DID NOT CLEAR");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TRANSMISSION COMPLETED");

        end

        // Allow idle time
        repeat(5) @(negedge clk);

    end

    endtask

    //==================================================
    // MAIN TEST SEQUENCE
    //==================================================

    initial begin

        errors = 0;

        reset = 1'b1;

        tx_data = 8'h00;
        tx_start = 1'b0;

        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart_controller);

        $display("================================");
        $display("UART CONTROLLER TEST STARTED");
        $display("================================");

        // Reset test
        reset_system();

        // Check idle condition
        if (tx !== 1'b1) begin

            $display("FAIL: UART IDLE STATE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: UART IDLE STATE");

        end

        // Test 1
        send_and_check(8'hA5);

        // Test 2
        send_and_check(8'h3C);

        // Test 3
        send_and_check(8'hFF);

        // Test 4
        send_and_check(8'h00);

        // Test 5
        send_and_check(8'h81);

        // Final result
        $display("================================");

        if (errors == 0) begin

            $display("ALL UART TESTS PASSED");

        end

        else begin

            $display("UART TEST FAILED");
            $display("TOTAL ERRORS: %0d", errors);

        end

        $display("================================");

        $finish;

    end

    //==================================================
    // SIMULATION TIMEOUT
    //==================================================

    initial begin

        #2000000;

        $display("ERROR: SIMULATION TIMEOUT");

        $finish;

    end

endmodule
