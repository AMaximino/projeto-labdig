`timescale 1ns/1ps

module telemetria_uart_tb;
    localparam integer CLOCK_PERIOD = 10;
    localparam integer BAUD_DIVISOR = 10;
    localparam integer BIT_PERIOD = CLOCK_PERIOD * BAUD_DIVISOR;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg event_send = 1'b0;
    wire tx;
    reg signed [20:0] test_balance = 21'sd150;
    reg [7:0] received [0:75];
    reg [7:0] received_second [0:75];
    reg [7:0] event_code = 8'd6;
    integer i;

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    telemetria_uart #(
        .CLOCK_HZ(1000),
        .BAUD_RATE(100)
    ) dut (
        .clock(clock),
        .reset(reset),
        .event_send(event_send),
        .event_code(event_code),
        .event_status(2'd1),
        .item_id(4'd7),
        .balance(test_balance),
        .salary(21'sd64),
        .investment(21'sd0),
        .fixed_expenses(21'sd40),
        .unique_expenses(21'sd120),
        .inventory_mask(10'h040),
        .round_index(4'd1),
        .move_index(4'd0),
        .tx(tx)
    );

    task receive_byte;
        output [7:0] value;
        integer bit_number;
        begin
            @(negedge tx);
            #(BIT_PERIOD / 2);
            if (tx !== 1'b0) $fatal(1, "UART start bit was not low");
            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                #(BIT_PERIOD);
                value[bit_number] = tx;
            end
            #(BIT_PERIOD);
            if (tx !== 1'b1) $fatal(1, "UART stop bit was not high");
        end
    endtask

    initial begin
        #100;
        reset = 1'b0;
        #100;
        event_send = 1'b1;
        #20;
        event_send = 1'b0;

        for (i = 0; i <= 75; i = i + 1) begin
            receive_byte(received[i]);
            if (i == 0) begin
                event_code = 8'd2;
                test_balance = -21'sd10;
                event_send = 1'b1;
                #20;
                event_send = 1'b0;
            end
            if (received[i] == 8'h0a) i = 76;
        end
        for (i = 0; i <= 75; i = i + 1) begin
            receive_byte(received_second[i]);
            if (received_second[i] == 8'h0a) i = 76;
        end

        if ({received[0], received[1], received[2], received[3]} !== "AEF1")
            $fatal(1, "Unexpected UART frame header");
        if ({received[5], received[6], received[7], received[8], received[9], received[10]} !== "000001" ||
            {received[12], received[13]} !== "06" || {received[15], received[16]} !== "07")
            $fatal(1, "Unexpected first frame sequence, event or item");
        if (received[74] !== "1" || received[75] !== 8'h0a)
            $fatal(1, "Unexpected final status or newline");
        if (received[18] !== "+" || received[19] !== "0" ||
            received[24] !== "5" || received[25] !== "0")
            $fatal(1, "Unexpected signed balance encoding");
        if ({received[27], received[28], received[29], received[30],
             received[31], received[32], received[33], received[34]} !== "+0000064" ||
            {received[63], received[64], received[65], received[66]} !== "0040" ||
            {received[68], received[69]} !== "01" || {received[71], received[72]} !== "00")
            $fatal(1, "Unexpected snapshot, inventory or counter encoding");
        if ({received_second[5], received_second[6], received_second[7],
             received_second[8], received_second[9], received_second[10]} !== "000002" ||
            {received_second[12], received_second[13]} !== "02" ||
            received_second[18] !== "-" || received_second[24] !== "1" ||
            received_second[75] !== 8'h0a)
            $fatal(1, "UART queue did not preserve the second event");

        $display("UART framing and queued event sequence verified.");
        $finish;
    end
endmodule
