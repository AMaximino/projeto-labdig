`timescale 1ns/1ps

module rfid_uart_rx_semana3_tb;
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
        .clock(clock),
        .reset(reset),
        .rx(rx),
        .acknowledge(acknowledge),
        .item_id(item_id),
        .item_valid(item_valid)
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
        input [7:0] prefix;
        input [7:0] tens_digit;
        input [7:0] units_digit;
        begin
            send_byte(prefix);
            send_byte(tens_digit);
            send_byte(units_digit);
            send_byte(8'h0a);
        end
    endtask

    task expect_rejected;
        input [8*24-1:0] description;
        begin
            repeat (4) @(posedge clock);
            if (item_valid)
                $fatal(1, "Invalid command accepted: %0s", description);
        end
    endtask

    task acknowledge_command;
        begin
            acknowledge = 1'b1;
            repeat (4) @(posedge clock);
            acknowledge = 1'b0;
            repeat (4) @(posedge clock);
            if (item_valid)
                $fatal(1, "Acknowledge did not clear the pending command");
        end
    endtask

    initial begin
        repeat (4) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;

        send_command("R", "0", "0");
        expect_rejected("R00 below item range");
        send_command("R", "1", "1");
        expect_rejected("R11 above item range");
        send_command("X", "0", "7");
        expect_rejected("wrong command prefix");

        send_command("R", "0", "1");
        wait (item_valid);
        if (item_id !== 4'd1) $fatal(1, "R01 decoded as item %0d", item_id);
        repeat (BIT_TICKS * 4) @(posedge clock);
        if (!item_valid) $fatal(1, "Valid command must remain pending until acknowledge");

        send_command("R", "1", "0");
        if (!item_valid || item_id !== 4'd1)
            $fatal(1, "A pending command was overwritten before acknowledge");
        acknowledge_command();

        send_command("R", "0", "7");
        wait (item_valid);
        if (item_id !== 4'd7) $fatal(1, "R07 decoded as item %0d", item_id);
        acknowledge_command();

        send_command("R", "1", "0");
        wait (item_valid);
        if (item_id !== 4'd10) $fatal(1, "R10 decoded as item %0d", item_id);

        $display("PASS Semana 3: RFID command range, pending latch and acknowledge");
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "Semana 3 RFID UART test timed out");
    end
endmodule
