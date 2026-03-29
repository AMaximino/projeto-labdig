module display_7seg_4dig_base10 (
    input wire clock,
    input wire reset,
    input wire [7:0] valor,  // Número atual (aceita até 99)
    input wire [7:0] limite, // Limite máximo (aceita até 99)
    output reg [7:0] seg,    // Barramento de segmentos (A, B, C, D, E, F, G, DP)
    output reg [3:0] dig     // Seleção do dígito (D4, D3, D2, D1)
);

    // --- Conversão Binário para BCD (Dezena e Unidade) ---
    // Para valores até 99, a conta simples de divisão/resto funciona bem
    wire [3:0] val_dez = (valor / 10);
    wire [3:0] val_uni = (valor % 10);
    wire [3:0] lim_dez = (limite / 10);
    wire [3:0] lim_uni = (limite % 10);

    // --- Multiplexação ---
    reg [15:0] counter;
    always @(posedge clock or posedge reset) begin
        if (reset) counter <= 0;
        else counter <= counter + 1;
    end

    wire [1:0] sel = counter[15:14]; // Alterna os dígitos a cada ~1.3ms (em 50MHz)
    reg [3:0] hex_digit;
    reg ponto;

    always @(*) begin
        ponto = 1'b0; // Ponto desligado por padrão
        case (sel)
            2'b00: begin
                dig = 4'b1110;       // Ativa D1 (Unidade do Limite)
                hex_digit = lim_uni;
            end
            2'b01: begin
                dig = 4'b1101;       // Ativa D2 (Dezena do Limite)
                hex_digit = lim_dez;
            end
            2'b10: begin
                dig = 4'b1011;       // Ativa D3 (Unidade do Valor Atual)
                hex_digit = val_uni;
                ponto = 1'b1;        // Liga o ponto no meio para separar (Valor.Limite)
            end
            2'b11: begin
                dig = 4'b0111;       // Ativa D4 (Dezena do Valor Atual)
                hex_digit = val_dez;
            end
        endcase
    end

    // --- Decoder 7 Segmentos (Configurado para sua pinagem) ---
    // Mapeamento: seg[7]=A, [6]=B, [5]=C, [4]=D, [3]=E, [2]=F, [1]=G, [0]=DP
    always @(*) begin
        case (hex_digit)
            4'd0: seg[7:1] = 7'b1111110; 
            4'd1: seg[7:1] = 7'b0110000;
            4'd2: seg[7:1] = 7'b1101101;
            4'd3: seg[7:1] = 7'b1111001;
            4'd4: seg[7:1] = 7'b0110011;
            4'd5: seg[7:1] = 7'b1011011;
            4'd6: seg[7:1] = 7'b1011111;
            4'd7: seg[7:1] = 7'b1110000;
            4'd8: seg[7:1] = 7'b1111111;
            4'd9: seg[7:1] = 7'b1111011;
            default: seg[7:1] = 7'b0000000;
        endcase
        seg[0] = ponto; // Pino 3 (DP)
    end

endmodule




