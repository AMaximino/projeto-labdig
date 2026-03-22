// algoritmo double-dabble feito pelo chat-GPT
// transforma numero em binario em binary coded decimal
// 22/03/2026
module bin2bcd #(
    parameter BIN_WIDTH = 16,
    parameter DIGITS = 5
)(
    input  [BIN_WIDTH-1:0] bin,
    output reg [DIGITS*4-1:0] bcd
);

integer i, j;

always @(*) begin
    // zera o BCD
    bcd = 0;

    // percorre todos os bits do binário
    for (i = BIN_WIDTH-1; i >= 0; i = i - 1) begin

        // passo 1: add-3 em cada dígito >= 5
        for (j = 0; j < DIGITS; j = j + 1) begin
            if (bcd[j*4 +: 4] >= 5)
                bcd[j*4 +: 4] = bcd[j*4 +: 4] + 3;
        end

        // passo 2: shift left
        bcd = bcd << 1;

        // passo 3: insere bit do binário
        bcd[0] = bin[i];
    end
end

endmodule