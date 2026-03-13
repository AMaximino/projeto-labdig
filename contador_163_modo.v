//------------------------------------------------------------------
// Arquivo   : contador_163_var.v
// Projeto   : Experiencia 4 - Um Fluxo de Dados Simples
//------------------------------------------------------------------
// Descricao : Contador binario de 4 bits, modulo variavel
//             similar ao componente 74163
//
// baseado no componente Vrcntr4u.v do livro Digital Design Principles 
// and Practices, Fifth Edition, by John F. Wakerly              
//------------------------------------------------------------------
// Revisoes  :
//     Data        Versao  Autor             Descricao
//     14/12/2023  1.0     Edson Midorikawa  versao inicial
//     04/02/2026  1.1     André Maximino    versao com modulo variavel
//------------------------------------------------------------------
//
module contador_163_modo ( clock, clr, ld, ent, enp, modo, D, Q, rco );
    input clock, clr, ld, ent, enp, modo;
    input [3:0] D;
    output reg [3:0] Q;
    output reg rco;

    wire [4:0] modulo;
    assign modulo = modo ? 5'd4 : 5'd16;    // assign modulo = modo ? 5'd5 : 5'd16;

    always @ (posedge clock)
        if (~clr)               Q <= 4'd0;
        else if (~ld)           Q <= D;
        else if (ent && enp)    Q <= Q + 1'b1;
        else                    Q <= Q;
 
    always @ (Q or ent)
        if (ent && (Q == modulo))   rco = 1;
        else                        rco = 0;
endmodule