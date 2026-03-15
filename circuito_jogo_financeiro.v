module circuito_jogo_financeiro (
    input clock,
    input reset,
    input iniciar,
    input estudar,
    input trabalhar,
    input investir,
    input resgatar,
    input comprar,
    input vender,
    input [2:0] itens,
    input [5:0] config_display,

    output [11:0] display_rodadas,
    output [11:0] display_jogadas,
    output [41:0] display_dinheiro
);
    wire [23:0] dinheiro;

    wire w_zeraCJ;
    wire w_contaCJ;
    wire w_zeraCR;
    wire w_contaCR;

    fluxo_dados fd (
        .clock          ( clock ),
        .estudar        ( estudar ),
        .trabalhar      ( trabalhar ),
        .investir       ( investir ),
        .resgatar       ( resgatar ),
        .comprar        ( comprar ),
        .vender         ( vender ),
        .config_display ( config_display ),
        .zeraCJ         ( w_zeraCJ ),
        .contaCJ        ( w_contaCJ ),
        .zeraCR         ( w_zeraCR ),
        .contaCR        ( w_contaCR ),

        .dinheiro       ( dinheiro )
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


    display6digitos disp6dig (
        .dinheiro ( dinheiro ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro )
    );



    




endmodule