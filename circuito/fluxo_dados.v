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
    input init,
    input processaE,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,
    input zeraD,
    input registraD,
    input zeraA,
    input registraA,
    input zeraR,
    input registraR,
    input zeraM,
    input registraM,

    output fim_jogo,
    output fim_perdeu,
    output fim_rodada,
    output acao_pulso,
    output eh_jogada,
    output display_pulso,
    output [3:0] contagem, //
    output [3:0] rodada, //

    output ultima_rodada,
    output [23:0] dinheiro
);

    //em complemento de 2 -> bit 21 = 1 indica negativo
    wire [20:0] saldo;
    wire [20:0] saldo_in;
    wire [20:0] salario;
    wire [20:0] salario_in;
    wire [20:0] valorInvestido;
    wire [20:0] valorInvestido_in;
    wire [20:0] rendimento;
    wire [20:0] rendimento_in;
    wire [20:0] gastosFixos;
    wire [20:0] gastosFixos_in;
    wire [20:0] gastosUnicos;
    wire [20:0] gastosUnicos_in;

    wire [5:0] acoes_out;

/////////////display/////////////////////////////////
    wire sel_display;
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

    /*// transformador de formato de config_display (botoes) p/ endereco de leitura
    encoder #(.N(6)) addr_display (
        .entrada ( config_display_out ),
        .saida ( addr_read )
    );*/


    sel_dinheiro selDisplayDinheiro (
        .saldo          ( saldo ),
        .salario        ( salario ),
        .valorInvestido ( valorInvestido ),
        .rendimento     ( rendimento ),
        .gastosFixos    ( gastosFixos ),
        .gastosUnicos   ( gastosUnicos ),
        .config_display ( config_display_out ),
        .dinheiro       ( dinheiro )
    );

///////////info/////////////////////////////////////////////////////////////////////////
    
    registrador_n #(.N(21)) reg_saldo (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( saldo_in ),
        .Q      ( saldo )
    );
    registrador_n #(.N(21)) reg_salario (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( salario_in ),
        .Q      ( salario )
    );
    registrador_n #(.N(21)) reg_valorInvestido (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( valorInvestido_in ),
        .Q      ( valorInvestido )
    );
    registrador_n #(.N(21)) reg_rendimento (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( rendimento_in ),
        .Q      ( rendimento )
    );
    registrador_n #(.N(21)) reg_gastosFixos (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( gastosFixos_in ),
        .Q      ( gastosFixos )
    );
    registrador_n #(.N(21)) reg_gastosUnicos (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( gastosUnicos_in ),
        .Q      ( gastosUnicos )
    );



    /*// memoria das informacoes do jogador
    ram_8x24_dualPort infoJogador (
        .clock      ( clock ),
        .we         ( we ),
        .data       ( ),
        .addr_read  ( addr_read ),
        .addr_write ( ),
        .data_out   ( dinheiro )
    );*/

    //////////////////////////////////////////////////////////////////
////////////////processamento de acoes//////////////////////////////////////////////

processador_acao p (
    .clock               ( clock ),
    .saldo_in            ( saldo ),
    .salario_in          ( salario ),
    .valor_investido_in  ( valorInvestido ),
    .rendimento_in       ( rendimento ),
    .gastos_fixos_in     ( gastosFixos ),
    .gastos_unicos_in    ( gastosUnicos ),
    .acao                ( acoes_out ),
    .init                ( init ),
    .processaE           ( processaE ),

    .saldo_out           ( saldo_in ),
    .salario_out         ( salario_in ),
    .valor_investido_out ( valorInvestido_in ),
    .rendimento_out      ( rendimento_in ),
    .gastos_fixos_out    ( gastosFixos_in ),
    .gastos_unicos_out   ( gastosUnicos_in )
);

//////////////////////////////////////////////////////////////////
////////////////acao//////////////////////////////////////////////

    wire [5:0] acoes;
    wire tem_acao;

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
    

///////////////////////////////////////////////////////////////////////////////
//////////////jogada/////////////////////////////////////////////////////////
    wire [1:0] jogada;
    /*wire eh_jogada;*/
    assign jogada = {acoes_out[5], acoes_out[4]};
    assign eh_jogada = |jogada;
    


    // contador_modulo_n contadorJogada
    contador_modulo_n #(.N(4)) contadorJogada (
      .clock  ( clock ),
      .clr    ( ~zeraCJ ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCJ ),
      .modulo ( 4'b010 ),  //(modulo +1) jogadas, 3 jogadas -> 3 meses por jogada (trimestre)
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
      .modulo ( 4'b0111 ),  //(modulo + 1) rodadas, 8 rodadas -> 8 trimestres no jogo, 2 anos 
      .D      ( 4'b0000 ),     
      .Q      ( rodada ),
      .rco    ( ultima_rodada )
    );


    assign fim_jogo = fim_rodada && ultima_rodada;
    assign fim_perdeu = saldo[20];

endmodule