module telemetria_uart #(
    parameter integer CLOCK_HZ = 50000000,
    parameter integer BAUD_RATE = 115200
) (
    input clock,
    input reset,
    input event_send,
    input [7:0] event_code,
    input [1:0] event_status,
    input [3:0] item_id,
    input signed [20:0] balance,
    input signed [20:0] salary,
    input signed [20:0] investment,
    input signed [20:0] fixed_expenses,
    input signed [20:0] unique_expenses,
    input [9:0] inventory_mask,
    input [3:0] round_index,
    input [3:0] move_index,
    output reg tx
);
    localparam integer BAUD_DIVISOR = CLOCK_HZ / BAUD_RATE;
    localparam [2:0] IDLE = 3'd0, START = 3'd1, DATA = 3'd2, STOP = 3'd3, GAP = 3'd4;
    localparam [6:0] LAST_CHAR = 7'd75;

    reg send_meta;
    reg send_sync;
    reg send_previous;
    reg [2:0] state;
    reg [15:0] baud_counter;
    reg [2:0] bit_index;
    reg [6:0] char_index;
    reg [7:0] shift_register;
    reg [19:0] sequence_number;
    reg [19:0] saved_sequence;
    reg [156:0] event_queue [0:3];
    reg [1:0] queue_head;
    reg [1:0] queue_tail;
    reg [2:0] queue_count;
    reg [7:0] saved_event;
    reg [1:0] saved_status;
    reg [3:0] saved_item;
    reg signed [20:0] saved_balance;
    reg signed [20:0] saved_salary;
    reg signed [20:0] saved_investment;
    reg signed [20:0] saved_fixed_expenses;
    reg signed [20:0] saved_unique_expenses;
    reg [9:0] saved_inventory;
    reg [3:0] saved_round;
    reg [3:0] saved_move;
    wire send_rising = send_sync && !send_previous;
    wire pop_event = (state == IDLE) && (queue_count != 0);
    wire push_event = send_rising && ((queue_count < 4) || pop_event);
    wire [19:0] next_sequence = sequence_number == 20'd999999
        ? 20'd1 : sequence_number + 1'b1;

    function [7:0] decimal_digit;
        input [31:0] value;
        input [3:0] position;
        begin
            case (position)
                4'd0: decimal_digit = 8'd48 + (value % 10);
                4'd1: decimal_digit = 8'd48 + ((value / 10) % 10);
                4'd2: decimal_digit = 8'd48 + ((value / 100) % 10);
                4'd3: decimal_digit = 8'd48 + ((value / 1000) % 10);
                4'd4: decimal_digit = 8'd48 + ((value / 10000) % 10);
                4'd5: decimal_digit = 8'd48 + ((value / 100000) % 10);
                default: decimal_digit = 8'd48 + ((value / 1000000) % 10);
            endcase
        end
    endfunction

    function [7:0] amount_character;
        input signed [20:0] value;
        input [3:0] position;
        reg [31:0] magnitude;
        begin
            magnitude = value < 0 ? -value : value;
            if (position == 0)
                amount_character = value < 0 ? 8'h2d : 8'h2b;
            else
                amount_character = decimal_digit(magnitude, 4'd7 - position);
        end
    endfunction

    function [7:0] hex_character;
        input [3:0] value;
        begin
            hex_character = value < 10 ? 8'd48 + value : 8'd55 + value;
        end
    endfunction

    function [7:0] frame_character;
        input [6:0] position;
        input [19:0] sequence_value;
        input [7:0] event_value;
        input [3:0] item_value;
        input signed [20:0] balance_value;
        input signed [20:0] salary_value;
        input signed [20:0] investment_value;
        input signed [20:0] fixed_value;
        input signed [20:0] unique_value;
        input [9:0] inventory_value;
        input [3:0] round_value;
        input [3:0] move_value;
        input [1:0] status_value;
        begin
            case (position)
                0: frame_character = "A";
                1: frame_character = "E";
                2: frame_character = "F";
                3: frame_character = "1";
                4, 11, 14, 17, 26, 35, 44, 53, 62, 67, 70, 73: frame_character = ",";
                5: frame_character = decimal_digit(sequence_value, 4'd5);
                6: frame_character = decimal_digit(sequence_value, 4'd4);
                7: frame_character = decimal_digit(sequence_value, 4'd3);
                8: frame_character = decimal_digit(sequence_value, 4'd2);
                9: frame_character = decimal_digit(sequence_value, 4'd1);
                10: frame_character = decimal_digit(sequence_value, 4'd0);
                12: frame_character = decimal_digit({24'd0, event_value}, 4'd1);
                13: frame_character = decimal_digit({24'd0, event_value}, 4'd0);
                15: frame_character = decimal_digit({28'd0, item_value}, 4'd1);
                16: frame_character = decimal_digit({28'd0, item_value}, 4'd0);
                18,19,20,21,22,23,24,25: frame_character = amount_character(balance_value, position - 7'd18);
                27,28,29,30,31,32,33,34: frame_character = amount_character(salary_value, position - 7'd27);
                36,37,38,39,40,41,42,43: frame_character = amount_character(investment_value, position - 7'd36);
                45,46,47,48,49,50,51,52: frame_character = amount_character(fixed_value, position - 7'd45);
                54,55,56,57,58,59,60,61: frame_character = amount_character(unique_value, position - 7'd54);
                63: frame_character = "0";
                64: frame_character = hex_character({2'b00, inventory_value[9:8]});
                65: frame_character = hex_character(inventory_value[7:4]);
                66: frame_character = hex_character(inventory_value[3:0]);
                68: frame_character = decimal_digit({28'd0, round_value}, 4'd1);
                69: frame_character = decimal_digit({28'd0, round_value}, 4'd0);
                71: frame_character = decimal_digit({28'd0, move_value}, 4'd1);
                72: frame_character = decimal_digit({28'd0, move_value}, 4'd0);
                74: frame_character = decimal_digit({30'd0, status_value}, 4'd0);
                default: frame_character = 8'h0a;
            endcase
        end
    endfunction

    wire [7:0] next_character = frame_character(
        char_index, saved_sequence, saved_event, saved_item, saved_balance,
        saved_salary, saved_investment, saved_fixed_expenses,
        saved_unique_expenses, saved_inventory, saved_round, saved_move,
        saved_status
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            send_meta <= 1'b0;
            send_sync <= 1'b0;
            send_previous <= 1'b0;
        end else begin
            send_meta <= event_send;
            send_sync <= send_meta;
            send_previous <= send_sync;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            baud_counter <= 0;
            bit_index <= 0;
            char_index <= 0;
            shift_register <= 8'hff;
            sequence_number <= 0;
            saved_sequence <= 0;
            queue_head <= 0;
            queue_tail <= 0;
            queue_count <= 0;
            saved_event <= 0;
            saved_status <= 0;
            saved_item <= 0;
            saved_balance <= 0;
            saved_salary <= 0;
            saved_investment <= 0;
            saved_fixed_expenses <= 0;
            saved_unique_expenses <= 0;
            saved_inventory <= 0;
            saved_round <= 0;
            saved_move <= 0;
            tx <= 1'b1;
        end else begin
            if (push_event) begin
                event_queue[queue_tail] <= {
                    next_sequence,
                    event_code,
                    event_status,
                    item_id,
                    balance,
                    salary,
                    investment,
                    fixed_expenses,
                    unique_expenses,
                    inventory_mask,
                    round_index,
                    move_index
                };
                queue_tail <= queue_tail + 1'b1;
                sequence_number <= next_sequence;
            end
            if (pop_event)
                queue_head <= queue_head + 1'b1;
            case ({push_event, pop_event})
                2'b10: queue_count <= queue_count + 1'b1;
                2'b01: queue_count <= queue_count - 1'b1;
                default: queue_count <= queue_count;
            endcase

            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (pop_event) begin
                        saved_sequence <= event_queue[queue_head][156:137];
                        saved_event <= event_queue[queue_head][136:129];
                        saved_status <= event_queue[queue_head][128:127];
                        saved_item <= event_queue[queue_head][126:123];
                        saved_balance <= event_queue[queue_head][122:102];
                        saved_salary <= event_queue[queue_head][101:81];
                        saved_investment <= event_queue[queue_head][80:60];
                        saved_fixed_expenses <= event_queue[queue_head][59:39];
                        saved_unique_expenses <= event_queue[queue_head][38:18];
                        saved_inventory <= event_queue[queue_head][17:8];
                        saved_round <= event_queue[queue_head][7:4];
                        saved_move <= event_queue[queue_head][3:0];
                        char_index <= 0;
                        bit_index <= 0;
                        baud_counter <= 0;
                        state <= START;
                    end
                end
                START: begin
                    tx <= 1'b0;
                    if (baud_counter == BAUD_DIVISOR) begin
                        baud_counter <= 0;
                        tx <= next_character[0];
                        shift_register <= {1'b1, next_character[7:1]};
                        bit_index <= 3'd1;
                        state <= DATA;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                DATA: begin
                    if (baud_counter == BAUD_DIVISOR - 1) begin
                        baud_counter <= 0;
                        tx <= shift_register[0];
                        shift_register <= {1'b1, shift_register[7:1]};
                        if (bit_index == 3'd7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                STOP: begin
                    if (baud_counter == BAUD_DIVISOR - 1) begin
                        baud_counter <= 0;
                        tx <= 1'b1;
                        state <= GAP;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                GAP: begin
                    tx <= 1'b1;
                    if (baud_counter == BAUD_DIVISOR - 1) begin
                        baud_counter <= 0;
                        if (char_index == LAST_CHAR) begin
                            state <= IDLE;
                        end else begin
                            char_index <= char_index + 1'b1;
                            state <= START;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
