// algoritmo double-dabble feito pelo chat-GPT
// transforma numero em binario em binary coded decimal
// 22/03/2026
// 27/03/2026 -> representacao de numeros negativos com '-' no algarismo mais significativo

module bin2bcd #(
    parameter BIN_WIDTH = 16,
    parameter DIGITS = 5
)(
    input  signed [BIN_WIDTH-1:0] bin,
    output reg [DIGITS*4-1:0] bcd
);

integer i, j;

reg [BIN_WIDTH-1:0] magnitude;
reg negativo;

always @(*) begin
    // detectar sinal
    negativo = bin[BIN_WIDTH-1];

    // calcular modulo (valor absoluto)
    if (negativo)
        magnitude = -bin;
    else
        magnitude = bin;

    // zera o BCD
    bcd = 0;

    // double dabble
    for (i = BIN_WIDTH-1; i >= 0; i = i - 1) begin

        for (j = 0; j < DIGITS; j = j + 1) begin
            if (bcd[j*4 +: 4] >= 5)
                bcd[j*4 +: 4] = bcd[j*4 +: 4] + 3;
        end

        bcd = bcd << 1;
        bcd[0] = magnitude[i];
    end

    // se negativo → coloca "1010" -> '-' no dígito mais significativo
    if (negativo) begin
        bcd[(DIGITS-1)*4 +: 4] = 4'b1010;
    end
end

endmodule