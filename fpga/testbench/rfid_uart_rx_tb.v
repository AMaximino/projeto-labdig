`timescale 1ns/1ps
module rfid_uart_rx_tb;
    localparam integer CLOCK_HZ = 1000000;
    localparam integer BAUD_RATE = 50000;
    localparam integer BIT_TICKS = CLOCK_HZ / BAUD_RATE;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg rx = 1'b1;
    reg acknowledge = 1'b0;
    wire [3:0] item_id;
    wire item_valid;
    integer bit_number;

    rfid_uart_rx #(.CLOCK_HZ(CLOCK_HZ), .BAUD_RATE(BAUD_RATE)) dut (
        .clock(clock), .reset(reset), .rx(rx), .acknowledge(acknowledge),
        .item_id(item_id), .item_valid(item_valid)
    );

    always #10 clock = ~clock;

    task send_byte;
        input [7:0] value;
        begin
            rx = 1'b0;
            repeat (BIT_TICKS) @(posedge clock);
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                rx = value[bit_number];
                repeat (BIT_TICKS) @(posedge clock);
            end
            rx = 1'b1;
            repeat (BIT_TICKS) @(posedge clock);
        end
    endtask

    task send_command;
        input [7:0] tens_digit;
        input [7:0] ones_digit;
        begin
            send_byte("R");
            send_byte(tens_digit);
            send_byte(ones_digit);
            send_byte(8'h0a);
        end
    endtask

    initial begin
        repeat (4) @(posedge clock);
        reset = 1'b0;

        send_command("0", "7");
        wait (item_valid);
        if (item_id !== 4'd7) $fatal(1, "R07 decoded as item %0d", item_id);
        repeat (BIT_TICKS * 4) @(posedge clock);
        if (!item_valid) $fatal(1, "command must remain pending until acknowledge");

        acknowledge = 1'b1;
        repeat (4) @(posedge clock);
        acknowledge = 1'b0;
        repeat (4) @(posedge clock);
        if (item_valid) $fatal(1, "acknowledge did not clear the pending command");

        send_command("1", "0");
        wait (item_valid);
        if (item_id !== 4'd10) $fatal(1, "R10 decoded as item %0d", item_id);

        $display("PASS RFID UART command parsing and acknowledge latch");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "RFID UART receiver test timed out");
    end
endmodule
