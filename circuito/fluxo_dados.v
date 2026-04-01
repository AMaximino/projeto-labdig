module fluxo_dados (
    input clock,
    input estudar,
    input trabalhar,
    input investir,
    input resgatar,
    input comprar,
    input vender,
    input [5:0] config_display,
    input [9:0] seletor_item,

    input rstED,
    input init,
    input processaE,
    input rende,
    input despesa,
    input zeraCJ,
    input contaCJ,
    input zeraCR,
    input contaCR,
    input zeraD,
    input registraD,
    input zeraA,
    input registraA,
    input zeraV,
    input registraV,
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
    output [23:0] dinheiro,
    output [9:0] itens_out
);

    //em complemento de 2 -> bit 21 = 1 indica negativo
    wire [20:0] saldo;
    wire [20:0] saldo_next;
    wire [20:0] salario;
    wire [20:0] salario_next;
    wire [20:0] valorInvestido;
    wire [20:0] valorInvestido_next;
    wire [20:0] rendimento;
    wire [20:0] rendimento_next;
    wire [20:0] gastosFixos;
    wire [20:0] gastosFixos_next;
    wire [20:0] gastosUnicos;
    wire [20:0] gastosUnicos_next;
    wire [9:0] itens;
    wire [9:0] itens_next;

    wire [5:0] acoes_out;

    assign itens_out = itens;

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
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( saldo_next ),
        .Q      ( saldo )
    );
    registrador_n #(.N(21)) reg_salario (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( salario_next ),
        .Q      ( salario )
    );
    registrador_n #(.N(21)) reg_valorInvestido (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( valorInvestido_next ),
        .Q      ( valorInvestido )
    );
    /*registrador_n #(.N(21)) reg_rendimento (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( rendimento_next ),
        .Q      ( rendimento )
    );*/
    assign rendimento = valorInvestido >> 5; //3,125% ao trimestre (rodada)
    registrador_n #(.N(21)) reg_gastosFixos (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( gastosFixos_next ),
        .Q      ( gastosFixos )
    );
    registrador_n #(.N(21)) reg_gastosUnicos (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( gastosUnicos_next ),
        .Q      ( gastosUnicos )
    );

    registrador_n #(.N(10)) reg_itens (
        .clock  ( clock ),
        .clear  ( zeraV ),
        .enable ( registraV ),
        .D      ( itens_next ),
        .Q      ( itens )
    );

///////////////////////////////////////////////////////////////////////////
////////////////processamento//////////////////////////////////////////////

    wire [20:0] saldo_proc;
    wire [20:0] salario_proc;
    wire [20:0] valorInvestido_proc;
    wire [20:0] gastosFixos_proc;
    wire [20:0] gastosUnicos_proc;
    wire [9:0]  itens_proc;
    processador_acao pa (
        .saldo_in            ( saldo ),
        .salario_in          ( salario ),
        .valorInvestido_in   ( valorInvestido ),
        .gastosFixos_in      ( gastosFixos ),
        .gastosUnicos_in     ( gastosUnicos ),
        .acao                ( acoes_out ),
        .processaE           ( processaE ),
        .seletor_item        ( seletor_item ),
        .itens_in            ( itens ),
        .saldo_out           ( saldo_proc ),
        .salario_out         ( salario_proc ),
        .valorInvestido_out  ( valorInvestido_proc ),
        .gastosFixos_out     ( gastosFixos_proc ),
        .gastosUnicos_out    ( gastosUnicos_proc ),
        .itens_out           ( itens_proc )
    );

    wire [20:0] saldo_evento;
    wire [20:0] salario_evento;
    wire [20:0] valorInvestido_evento;
    wire [20:0] gastosFixos_evento;
    wire [20:0] gastosUnicos_evento;
    processador_evento pe (
        .saldo_in            ( saldo ),
        .salario_in          ( salario ),
        .valorInvestido_in   ( valorInvestido ),
        .rendimento_in       ( rendimento ),
        .gastosFixos_in      ( gastosFixos ),
        .gastosUnicos_in     ( gastosUnicos ),
        .rende               ( rende ),
        .despesa             ( despesa ),
        .saldo_out           ( saldo_evento ),
        .salario_out         ( salario_evento ),
        .valorInvestido_out  ( valorInvestido_evento ),
        .gastosFixos_out     ( gastosFixos_evento ),
        .gastosUnicos_out    ( gastosUnicos_evento )
    );

    wire [20:0] saldo_init;
    wire [20:0] salario_init;
    wire [20:0] valorInvestido_init;
    wire [20:0] gastosFixos_init;
    wire [20:0] gastosUnicos_init;
    wire [9:0]  itens_init;
    inicializador i (
        .saldo          ( saldo_init ),
        .salario        ( salario_init ),
        .valorInvestido ( valorInvestido_init ),
        .gastosFixos    ( gastosFixos_init ),
        .gastosUnicos   ( gastosUnicos_init ),
        .itens          ( itens_init )
    );

    sel_valor MUX (
        .saldo_init            ( saldo_init ),
        .salario_init          ( salario_init ),
        .valorInvestido_init   ( valorInvestido_init ),
        .gastosFixos_init      ( gastosFixos_init ),
        .gastosUnicos_init     ( gastosUnicos_init ),
        .itens_init            ( itens_init ),
        .saldo_proc            ( saldo_proc ),
        .salario_proc          ( salario_proc ),
        .valorInvestido_proc   ( valorInvestido_proc ),
        .gastosFixos_proc      ( gastosFixos_proc ),
        .gastosUnicos_proc     ( gastosUnicos_proc ),
        .itens_proc            ( itens_proc ),
        .saldo_evento          ( saldo_evento ),
        .salario_evento        ( salario_evento ),
        .valorInvestido_evento ( valorInvestido_evento ),
        .gastosFixos_evento    ( gastosFixos_evento ),
        .gastosUnicos_evento   ( gastosUnicos_evento ),
        .init                  ( init ),
        .processaE             ( processaE ),
        .saldo_out             ( saldo_next ),
        .salario_out           ( salario_next ),
        .valorInvestido_out    ( valorInvestido_next ),
        .gastosFixos_out       ( gastosFixos_next ),
        .gastosUnicos_out      ( gastosUnicos_next ),
        .itens_out             ( itens_next )
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
    assign jogada = {acoes_out[5], acoes_out[4]};
    assign eh_jogada = |jogada;
    


    // contador_modulo_n contadorJogada
    contador_modulo_n #(.N(4)) contadorJogada (
      .clock  ( clock ),
      .clr    ( ~zeraCJ ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCJ ),
      .modulo ( 4'b0010 ),  //(modulo +1) jogadas, 3 jogadas -> 3 meses por jogada (trimestre)
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
      .modulo ( 4'b1001 ),  //(modulo + 1) rodadas, 10 rodadas -> 10 trimestres no jogo
      .D      ( 4'b0000 ),     
      .Q      ( rodada ),
      .rco    ( ultima_rodada )
    );

    assign fim_jogo = fim_rodada && ultima_rodada;
    assign fim_perdeu = saldo[20];

endmodule