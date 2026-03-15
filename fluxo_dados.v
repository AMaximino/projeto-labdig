module fluxo_dados (
    input clock,
    input estudar,
    input trabalhar,
    input investir,
    input resgatar,
    input comprar,
    input vender,
    input [5:0] config_display;
    input rst_ED,
    input we,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,
    input registraD,

    output [23:0] dinheiro
);


/////////////display/////////////////////////////////
    wire sel_display;
    wire sel_display_pulso;
    wire [5:0] config_display_out;
    wire addr_read;

    edge_detector sel_display_ED (
        .clock ( clock ),
        .reset ( rst_ED ),
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
        .input ( config_display_out ),
        .output ( addr_read )
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
        .reset ( rst_ED ),
        .sinal ( tem_acao ),
        .pulso ( acao_pulso )
    );
    assign acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};
    assign tem_acao = |acoes;

    // registrador da acao realizada
    registrador_n #(.N(6)) regDisplay (
        .clock  ( clock ),
        .clear  ( zeraA ),
        .enable ( registraA ),
        .D      ( acoes ),
        .Q      ( acoes_out )
    );

///////////////////////////////////////////////////////////////////////////////





    // contador_163_modo contadorJogada
    contador_163_modo contadorJogada (
      .clock ( clock ),
      .clr   ( ~zeraCJ ),
      .ld    ( 1'b1 ),
      .ent   ( 1'b1 ),
      .enp   ( contaCJ ),
      .modo  ( 1'b1/*configuracao_out[0]*/ ),  
      .D     ( 4'b0000 ),     
      .Q     ( contagem ),
      .rco   ( )
    );


    // contador_163_modo contadorRodada
    contador_163_modo contadorRodada (
      .clock ( clock ),
      .clr   ( ~zeraCR ),
      .ld    ( 1'b1 ),
      .ent   ( 1'b1 ),
      .enp   ( contaCR ),
      .modo  ( 1'b1/*configuracao_out[0]*/ ),  
      .D     ( 4'b0000 ),     
      .Q     ( rodada ),
      .rco   ( ultima_rodada )
    );

endmodule