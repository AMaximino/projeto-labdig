module rfid_uart_rx #(
    parameter integer CLOCK_HZ = 50000000,
    parameter integer BAUD_RATE = 115200
) (
    input clock,
    input reset,
    input rx,
    input acknowledge,
    output reg [3:0] item_id,
    output reg item_valid
);
    localparam integer BIT_TICKS = CLOCK_HZ / BAUD_RATE;
    localparam [1:0] IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg rx_meta, rx_sync;
    reg ack_meta, ack_sync;
    reg [1:0] state;
    reg [15:0] tick_count;
    reg [2:0] bit_index;
    reg [7:0] rx_shift;
    reg [1:0] field_index;
    reg [3:0] tens_digit, units_digit;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            ack_meta <= 1'b0;
            ack_sync <= 1'b0;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
            ack_meta <= acknowledge;
            ack_sync <= ack_meta;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tick_count <= 0;
            bit_index <= 0;
            rx_shift <= 0;
            field_index <= 0;
            tens_digit <= 0;
            units_digit <= 0;
            item_id <= 0;
            item_valid <= 1'b0;
        end else begin
            if (ack_sync) item_valid <= 1'b0;

            case (state)
                IDLE: if (!rx_sync && !item_valid) begin
                    state <= START;
                    tick_count <= BIT_TICKS / 2;
                end
                START: if (tick_count == 0) begin
                    if (!rx_sync) begin
                        state <= DATA;
                        tick_count <= BIT_TICKS - 1;
                        bit_index <= 0;
                    end else state <= IDLE;
                end else tick_count <= tick_count - 1'b1;
                DATA: if (tick_count == 0) begin
                    rx_shift[bit_index] <= rx_sync;
                    tick_count <= BIT_TICKS - 1;
                    if (bit_index == 3'd7) state <= STOP;
                    else bit_index <= bit_index + 1'b1;
                end else tick_count <= tick_count - 1'b1;
                STOP: if (tick_count == 0) begin
                    state <= IDLE;
                    tick_count <= 0;
                    if (rx_sync) begin
                        case (field_index)
                            0: if (rx_shift == "R") field_index <= 1;
                               else field_index <= 0;
                            1: if (rx_shift >= "0" && rx_shift <= "9") begin
                                   tens_digit <= rx_shift - "0";
                                   field_index <= 2;
                               end else field_index <= 0;
                            2: if (rx_shift >= "0" && rx_shift <= "9") begin
                                   units_digit <= rx_shift - "0";
                                   field_index <= 3;
                               end else field_index <= 0;
                            3: begin
                                field_index <= 0;
                                if (rx_shift == 8'h0a &&
                                    ((tens_digit * 10) + units_digit >= 1) &&
                                    ((tens_digit * 10) + units_digit <= 10)) begin
                                    item_id <= (tens_digit * 10) + units_digit;
                                    item_valid <= 1'b1;
                                end
                            end
                            default: field_index <= 0;
                        endcase
                    end else field_index <= 0;
                end else tick_count <= tick_count - 1'b1;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
