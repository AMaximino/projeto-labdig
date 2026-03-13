module fluxo_dados (
    input clock,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,
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