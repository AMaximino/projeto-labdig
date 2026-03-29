module display_7seg_4dig (
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

    wire [3:0] rod_dez = (valor >= 10) ? 4'd1 : 4'd0;
    wire [3:0] rod_uni = (valor >= 10) ? (valor - 10) : valor;

    wire [3:0] max_dez = (limite >= 10) ? 4'd1 : 4'd0;
    wire [3:0] max_uni = (limite >= 10) ? (limite - 10) : limite;

    // =========================
    // Multiplexação
    // =========================

    reg [1:0] sel;
    reg [15:0] counter;

    always @(posedge clock or posedge reset) begin
        if (reset)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    always @(posedge counter[15] or posedge reset) begin
        if (reset)
            sel <= 0;
        else
            sel <= sel + 1;
    end

    reg [3:0] val;

    always @(*) begin
        case (sel)
            2'b00: begin
                dig = 4'b0001; // D1
                val = max_uni;
            end
            2'b01: begin
                dig = 4'b0010; // D2
                val = max_dez;
            end
            2'b10: begin
                dig = 4'b0100; // D3
                val = rod_uni;
            end
            2'b11: begin
                dig = 4'b1000; // D4
                val = rod_dez;
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






/* colocar no fluxo de dados 
 wire [7:0] seg_jogada;
wire [3:0] dig_jogada;

// --- Display de JOGADAS ---
display_7seg_4dig dispJogadas (
    .clock  (clock),
    .reset  (~reset),
    .valor  ({4'b0, w_contagem}), // Converte 4 bits para 8 bits
    .limite (8'd3),               // Seu limite de 3 jogadas por rodada
    .seg    (display_jogadas_seg), // Conectar aos pinos A-DP do display 1
    .dig    (display_jogadas_dig)  // Conectar aos pinos D1-D4 do display 1
);

// --- Display de RODADAS ---
display_7seg_4dig dispRodadas (
    .clock  (clock),
    .reset  (~reset),
    .valor  ({4'b0, w_rodada}),   
    .limite (8'd8),               // Seu limite de 8 rodadas
    .seg    (display_rodadas_seg), // Conectar aos pinos A-DP do display 2
    .dig    (display_rodadas_dig)  // Conectar aos pinos D1-D4 do display 2
);
/*