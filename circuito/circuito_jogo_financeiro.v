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
    //input [2:0] itens,
    input [5:0] config_display,

    output [3:0] contagem, //
    output [3:0] rodada, //
    output [4:0] estado, //

    //output [11:0] display_jogadas,
    //output [11:0] display_rodadas,
    output [41:0] display_dinheiro,
    output ultima_jogada,
    output ultima_rodada,
    output terminou,
    output perdeu
);
    

    wire w_fim_jogo;
    wire w_fim_perdeu;
    wire w_fim_rodada;

    assign ultima_jogada = w_fim_rodada;
    wire [23:0] dinheiro;

    wire w_rstED;
    wire w_init;
    wire w_processaE;
    wire w_rende;
    wire w_despesa;
    wire w_zeraCJ;
    wire w_contaCJ;
    wire w_zeraCR;
    wire w_contaCR;
    wire w_zeraD;
    wire w_registraD;
    wire w_zeraA;
    wire w_registraA;
    wire w_zeraV;
    wire w_registraV;
    wire w_zeraM;
    wire w_registraM;

    wire w_acao_pulso;
    wire w_eh_jogada;
    wire w_display_pulso;
    wire [3:0] w_contagem;
    wire [3:0] w_rodada;
    wire [4:0] w_estado;


    assign contagem = w_contagem;
    assign rodada = w_rodada;
    assign estado = w_estado;

    fluxo_dados fd (
        .clock          ( clock ),
        .estudar        ( ~estudar ),
        .trabalhar      ( ~trabalhar ),
        .investir       ( ~investir ),
        .resgatar       ( ~resgatar ),
        .comprar        ( ~comprar ),
        .vender         ( ~vender ),
        .config_display ( ~config_display ),

        .rstED          ( w_rstED ),
        .init           ( w_init ),
        .processaE      ( w_processaE ),
        .rende          ( w_rende ),
        .despesa        ( w_despesa ),
        .zeraCJ         ( w_zeraCJ ),
        .contaCJ        ( w_contaCJ ),
        .zeraCR         ( w_zeraCR ),
        .contaCR        ( w_contaCR ),
        .zeraD          ( w_zeraD ),
        .registraD      ( w_registraD ),
        .zeraA          ( w_zeraA ),
        .registraA      ( w_registraA ),
        .zeraV          ( w_zeraV ),
        .registraV      ( w_registraV ),
        .zeraM          ( w_zeraM ),
        .registraM      ( w_registraM ),

        .fim_jogo       ( w_fim_jogo ),
        .fim_perdeu     ( w_fim_perdeu ),
        .fim_rodada     ( w_fim_rodada ),
        .acao_pulso     ( w_acao_pulso ),
        .eh_jogada      ( w_eh_jogada ),
        .display_pulso  ( w_display_pulso ),
        .contagem       ( w_contagem ),
        .rodada         ( w_rodada ),

        .ultima_rodada  ( ultima_rodada ),
        .dinheiro       ( dinheiro )
    );

    unidade_controle uc (
        .clock         ( clock ),
        .reset         ( ~reset ),
        .iniciar       ( ~iniciar ),
        .acao_pulso    ( w_acao_pulso ),
        .eh_jogada     ( w_eh_jogada ),
        .display_pulso ( w_display_pulso ),
        .fim_jogo      ( w_fim_jogo ),
        .fim_perdeu    ( w_fim_perdeu ),
        .fim_rodada    ( w_fim_rodada ),

        .rstED         ( w_rstED ),
        .init          ( w_init ),
        .processaE     ( w_processaE ),
        .rende         ( w_rende ),
        .despesa       ( w_despesa ),
        .zeraCJ        ( w_zeraCJ ),
        .contaCJ       ( w_contaCJ ),
        .zeraCR        ( w_zeraCR ),
        .contaCR       ( w_contaCR ),
        .zeraD         ( w_zeraD ),
        .registraD     ( w_registraD ),
        .zeraA         ( w_zeraA ),
        .registraA     ( w_registraA ),
        .zeraV         ( w_zeraV ),
        .registraV     ( w_registraV ),
        .zeraM         ( w_zeraM ),
        .registraM     ( w_registraM ),
        .terminou      ( terminou ),
        .perdeu        ( perdeu ),
        .estado        ( w_estado )
    );


    display6digitos disp6dig (
        .dinheiro ( dinheiro ),
        .enable ( 1'b1 ),
        .display ( display_dinheiro )
    );

    /*display4digitos dispRodadas (

    );*/

    /*display4digitos dispJogadas (

    );*/

endmodule