module fluxo_dados (
    input clock,
    input [5:0] config_display;
    input rst_ED,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,

    output [5:0] config_display_out,
    output [23:0] dinheiro
);

    wire w_sel_display,
    wire sel_display_pulso,

    edge_detector sel_display_ed (
        .clock ( clock ),
        .reset ( rst_ED ),
        .sinal ( w_sel_display ),
        .pulso ( display_pulso )
    );
    assign w_sel_display = |config_display;

    // registrador da opcao de selecao do display
    registrador_n #(.N(6)) regDisplay (
        .clock  ( clock ),
        .clear  (  ),
        .enable (  ),
        .D      ( config_display ),
        .Q      ( config_display_out )
    );

    // memoria das informacoes do jogador
    info_ram infoJogador (
        .clock      ( clock ),
        .we         ( e ),
        .data       ( ),
        .addr_read  ( ),
        .addr_write ( ),
        .data_out   ( dinheiro )
    );








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