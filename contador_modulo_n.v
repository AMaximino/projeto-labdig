//------------------------------------------------------------------
// Arquivo   : contador_modulo_n.v
// Projeto   : Projeto LabDig
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
//     17/03/2026  1.2     André Maximino    versao com input modulo (mais flexivel)
//------------------------------------------------------------------
//
module contador_modulo_n #(parameter N=4) ( clock, clr, ld, ent, enp, modulo, D, Q, rco );
    input clock, clr, ld, ent, enp;
    input [N-1:0] modulo, D;
    output reg [N-1:0] Q;
    output reg rco;

    always @ (posedge clock)
        if (~clr)               Q <= {N{1'b0}};
        else if (~ld)           Q <= D;
        else if (ent && enp)    Q <= Q + 1'b1;
        else                    Q <= Q;
 
    always @ (Q or ent)
        if (ent && (Q == modulo))   rco = 1;
        else                        rco = 0;
endmodule