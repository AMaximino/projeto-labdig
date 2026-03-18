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

    input jogada, //

    output [6:0] contagem, //
    output [6:0] rodada, //

    output [11:0] display_rodadas,
    output [11:0] display_jogadas,
    output [41:0] display_dinheiro,
    output ultima_rodada,
    output ultima_jogada,
    output terminou,
    output perdeu
);

    wire w_fim_jogo;
    wire w_fim_perdeu;
    wire w_fim_rodada;

    assign ultima_jogada = w_fim_rodada;
    wire [23:0] dinheiro;

    wire w_rstED;
    wire w_we;
    wire w_zeraCJ;
    wire w_contaCJ;
    wire w_zeraCR;
    wire w_contaCR;
    wire w_registraD;

    wire w_jogada_pulso;
    wire [3:0] w_contagem;
    wire [3:0] w_rodada;

    fluxo_dados fd (
        .clock          ( clock ),
        .estudar        ( estudar ),
        .trabalhar      ( trabalhar ),
        .investir       ( investir ),
        .resgatar       ( resgatar ),
        .comprar        ( comprar ),
        .vender         ( vender ),
        .config_display ( config_display ),

        .jogada         ( jogada ),
        .rstED          ( w_rstED ),
        .we             ( w_we ),
        .zeraCJ         ( w_zeraCJ ),
        .contaCJ        ( w_contaCJ ),
        .zeraCR         ( w_zeraCR ),
        .contaCR        ( w_contaCR ),
        .registraD      ( w_registraD ),

        .fim_jogo       ( w_fim_jogo ),
        .fim_perdeu     ( w_fim_perdeu ),
        .fim_rodada     ( w_fim_rodada ),
        .jogada_pulso   ( w_jogada_pulso ),
        .contagem       ( w_contagem ),
        .rodada         ( w_rodada ),

        .ultima_rodada  ( ultima_rodada ),
        .dinheiro       ( dinheiro )
    );

    unidade_controle uc (
        .clock        ( clock ),
        .reset        ( reset ),
        .iniciar      ( iniciar ),
        .jogada_pulso ( w_jogada_pulso ),
        .fim_jogo     ( w_fim_jogo ),
        .fim_perdeu   ( w_fim_perdeu ),
        .fim_rodada   ( w_fim_rodada ),

        .rstED        ( w_rstED ),
        .we           ( w_we ),
        .zeraCJ       ( w_zeraCJ ),
        .contaCJ      ( w_contaCJ ),
        .zeraCR       ( w_zeraCR ),
        .contaCR      ( w_contaCR ),
        .registraD    ( w_registraD ),
        .terminou     ( terminou ),
        .perdeu       ( perdeu )
    );


/*    display6digitos disp6dig (
        .dinheiro ( dinheiro ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro )
    ); */

    hexa7seg d5 (  //provisorio
        .hexa ( w_rodada ),
        .enable ( 1'b1 ),
        .display ( contagem )
    );

    hexa7seg d3 (  //provisorio
        .hexa ( w_contagem ),
        .enable ( 1'b1 ),
        .display ( rodada )
    );



    




endmodule