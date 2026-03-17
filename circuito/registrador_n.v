//------------------------------------------------------------------
// Arquivo   : registrador_n.v
// Projeto   : Experiencia 6 - Projeto do
//             Jogo do Desafio da Memória
//------------------------------------------------------------------
// Descricao : Registrador parametrizável
//             
//------------------------------------------------------------------
// Revisoes  :
//     Data        Versao  Autor             Descricao
//     21/02/2026  1.0     André Maximino    versao inicial
//------------------------------------------------------------------
//
module registrador_n #(parameter N = 1) (
    input        clock,
    input        clear,
    input        enable,
    input  [N-1:0] D,
    output [N-1:0] Q
);

    reg [N-1:0] IQ;

    always @(posedge clock or posedge clear) begin
        if (clear)
            IQ <= 0;
        else if (enable)
            IQ <= D;
    end

    assign Q = IQ;

endmodule