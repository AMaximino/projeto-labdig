module display_bcd_4dig_cc (
    input wire clock,
    input wire reset,

    input wire [3:0] valor,
    input wire [3:0] limite,

    output reg [7:0] seg,
    output reg [3:0] dig
);

    // =========================
    // Conversão HEX → DECIMAL
    // =========================

    wire [3:0] atual_dez = (valor >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] atual_uni = (valor >= 4'd10) ? (valor - 4'd10) : valor;

    wire [3:0] max_dez = (limite >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] max_uni = (limite >= 4'd10) ? (limite - 4'd10) : limite;

    // =========================
    // Multiplexação
    // =========================

    reg [1:0] sel;

    always @(posedge clock) begin
        if (reset)
            sel <= 2'b00;
        else
            sel <= sel + 2'b01;
    end

    reg [3:0] val;

    always @(posedge clock) begin
        case (sel)
            2'b00: begin
                dig <= 4'b1000;
                val <= max_uni;
            end
            2'b01: begin
                dig <= 4'b0100;
                val <= max_dez;
            end
            2'b10: begin
                dig <= 4'b0010;
                val <= atual_uni;
            end
            2'b11: begin
                dig <= 4'b0001;
                val <= atual_dez;
            end
        endcase
    end

    // =========================
    // Decoder 7 segmentos (decimal)
    // =========================

    always @(*) begin
        case (val)
            4'd0: seg = 8'b11111100;
            4'd1: seg = 8'b01100000;
            4'd2: seg = 8'b11011010;
            4'd3: seg = 8'b11110010;
            4'd4: seg = 8'b01100110;
            4'd5: seg = 8'b10110110;
            4'd6: seg = 8'b10111110;
            4'd7: seg = 8'b11100000;
            4'd8: seg = 8'b11111110;
            4'd9: seg = 8'b11110110;
            default: seg = 8'b00000000;
        endcase
    end

endmodule