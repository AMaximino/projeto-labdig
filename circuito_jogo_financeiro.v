module circuito_jogo_financeiro (
    input clock,
    input reset,
    input iniciar,
    input estudar,
    input trabalhar,
    input investir,
    input resgatar,
    input compra,
    input vender,
    input [2:0] itens,
    input [5:0] config_display,

    output [11:0] display_rodadas,
    output [11:0] display_jogadas,
    output [41:0] display_dinheiro
);
    wire [23:0] dinheiro;

    fluxo_dados fd (
        .clock ( clock ),
        .config_display ( config_display ),
        .zeraCJ ( w_zeraCJ ),
        .contaCJ ( w_contaCJ ),
        .zeraCR ( w_zeraCR ),
        .contaCR ( w_contaCR ),
    
        .dinheiro ( dinheiro )
    );

    unidade_controle uc (
        .clock ( clock ),
        .reset ( reset ),
        .jogar ( iniciar ),
        .acao_pulso ( w_acao_pulso ),

        .zeraCJ ( w_zeraCJ ),
        .contaCJ ( w_contaCJ ),
        .zeraCR ( w_zeraCR ),
        .contaCR ( w_contaCR )
    );




    hexa7seg d6 (
        .hexa ( dinheiro[23:20] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[41:35] )
    );

    hexa7seg d5 (
        .hexa ( dinheiro[19:16] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[34:28] )
    );

    hexa7seg d4 (
        .hexa ( dinheiro[15:12] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[27:21] )
    );

    hexa7seg d3 (
        .hexa ( dinheiro[11:8] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[20:14] )
    );

    hexa7seg d2 (
        .hexa ( dinheiro[7:4] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[13:7] )
    );

    hexa7seg d1 (
        .hexa ( dinheiro[3:0] ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro[6:0] )
    );

    




endmodule