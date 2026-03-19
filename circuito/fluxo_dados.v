module fluxo_dados (
    input clock,
    input estudar,
    input trabalhar,
    input investir,
    input resgatar,
    input comprar,
    input vender,
    input [5:0] config_display,

    input rstED,
    input we,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,
    input registraD,

    output fim_jogo,
    output fim_perdeu,
    output fim_rodada,
    output acao_pulso,
    output eh_jogada,
    output [3:0] contagem, //
    output [3:0] rodada, //

    output [23:0] dinheiro
);


/////////////display/////////////////////////////////
    wire sel_display;
    wire sel_display_pulso;
    wire [5:0] config_display_out;
    wire [2:0] addr_read;

    edge_detector sel_display_ED (
        .clock ( clock ),
        .reset ( rstED ),
        .sinal ( sel_display ),
        .pulso ( display_pulso )
    );
    assign sel_display = |config_display;

    // registrador da opcao de selecao do display
    registrador_n #(.N(6)) regDisplay (
        .clock  ( clock ),
        .clear  ( zeraD ),
        .enable ( registraD ),
        .D      ( config_display ),
        .Q      ( config_display_out )
    );

    // transformador de formato de config_display (botoes) p/ endereco de leitura
    encoder #(.N(6)) addr_display (
        .entrada ( config_display_out ),
        .saida ( addr_read )
    );

    // memoria das informacoes do jogador
    info_ram infoJogador (
        .clock      ( clock ),
        .we         ( we ),
        .data       ( ),
        .addr_read  ( addr_read ),
        .addr_write ( ),
        .data_out   ( dinheiro )
    );

//////////////////////////////////////////////////////////////////
////////////////acao//////////////////////////////////////////////

    wire [5:0] acoes;
    wire tem_acao;
    wire acao_pulso;

    edge_detector acao_ED (
        .clock ( clock ),
        .reset ( rstED ),
        .sinal ( tem_acao ),
        .pulso ( acao_pulso )
    );
    assign acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};
    /*assign acoes_sem_jogada = (investir || resgatar || comprar || vender);
    assign jogada = (estudar || trabalhar);*/
    assign tem_acao = |acoes;
    

    // registrador da acao realizada
    registrador_n #(.N(6)) regAcao (
        .clock  ( clock ),
        .clear  ( zeraA ),
        .enable ( registraA ),
        .D      ( acoes ),
        .Q      ( acoes_out )
    );
    wire [5:0] acoes_out;

///////////////////////////////////////////////////////////////////////////////
//////////////jogada/////////////////////////////////////////////////////////
    wire [1:0] jogada;
    wire eh_jogada;
    assign jogada = {acoes_out[5], acoes_out[4]};
    assign eh_jogada = |jogada;
    


    // contador_modulo_n contadorJogada
    contador_modulo_n #(.N(4)) contadorJogada (
      .clock  ( clock ),
      .clr    ( ~zeraCJ ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCJ ),
      .modulo ( 4'b0100 ),  
      .D      ( 4'b0000 ),     
      .Q      ( contagem ),
      .rco    ( fim_rodada )
    );


    // contador_modulo_n contadorRodada
    contador_modulo_n #(.N(4)) contadorRodada (
      .clock  ( clock ),
      .clr    ( ~zeraCR ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCR ),
      .modulo ( 4'b0011 ),  
      .D      ( 4'b0000 ),     
      .Q      ( rodada ),
      .rco    ( ultima_rodada )
    );


    assign fim_jogo = fim_rodada && ultima_rodada;
    assign fim_perdeu = 1'b0; //provisorio

endmodule