module i2s_master_clock_gen #(
    parameter CLOCK_DIV = 781
)(
    input clk,
    input rst,
    output reg sck_o,
    output reg ws_o
);

    reg [$clog2(CLOCK_DIV)-1:0] div_cnt;
    reg [5:0] frame_bit_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt       <= 0;
            sck_o         <= 1'b0;
            ws_o          <= 1'b1;
            frame_bit_cnt <= 6'd0;
        end else begin
            if (div_cnt == CLOCK_DIV-1) begin
                div_cnt <= 0;
                sck_o   <= ~sck_o;

                // atualiza frame_bit_cnt e ws no flanco de descida interno
                if (!sck_o) begin
                    if (frame_bit_cnt == 6'd63)
                        frame_bit_cnt <= 6'd0;
                    else
                        frame_bit_cnt <= frame_bit_cnt + 1'b1;

                    ws_o <= (frame_bit_cnt < 6'd32) ? 1'b1 : 1'b0;
                end
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end

endmodule