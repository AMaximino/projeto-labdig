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
    input we,
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

    wire [19:0] saldo;
    wire [19:0] saldo_in;
    wire [19:0] salario;
    wire [19:0] salario_in;
    wire [19:0] valorInvestido;
    wire [19:0] valorInvestido_in;
    wire [19:0] rendimento;
    wire [19:0] rendimento_in;
    wire [19:0] gastosFixos;
    wire [19:0] gastosFixos_in;
    wire [19:0] gastosUnicos;
    wire [19:0] gastosUnicos_in;

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

    reg [19:0] dinheiro_bin;
    bin2bcd #(
        .BIN_WIDTH(20),
        .DIGITS(6)
    ) bin2bcd (
        .bin ( dinheiro_bin ),
        .bcd ( dinheiro )
    );
    always @(*) begin
        case (config_display_out)
            6'b000001: dinheiro_bin = gastosUnicos;
            6'b000010: dinheiro_bin = gastosFixos;
            6'b000100: dinheiro_bin = rendimento;
            6'b001000: dinheiro_bin = valorInvestido;
            6'b010000: dinheiro_bin = salario;
            6'b100000: dinheiro_bin = saldo;
            default: dinheiro_bin = saldo;
        endcase
    end


///////////info/////////////////////////////////////////////////////////////////////////
    
    registrador_n #(.N(20)) reg_saldo (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( saldo_in ),
        .Q      ( saldo )
    );
    registrador_n #(.N(20)) reg_salario (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( salario_in ),
        .Q      ( salario )
    );
    registrador_n #(.N(20)) reg_valorInvestido (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( valorInvestido_in ),
        .Q      ( valorInvestido )
    );
    registrador_n #(.N(20)) reg_rendimento (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( rendimento_in ),
        .Q      ( rendimento )
    );
    registrador_n #(.N(20)) reg_gastosFixos (
        .clock  ( clock ),
        .clear  ( zeraR ),
        .enable ( registraR ),
        .D      ( gastosFixos_in ),
        .Q      ( gastosFixos )
    );
    registrador_n #(.N(20)) reg_gastosUnicos (
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

processador_acao #(.N(20)) p (
    .clock               ( clock ),
    .saldo_in            ( saldo ),
    .salario_in          ( salario ),
    .valor_investido_in  ( valorInvestido ),
    .rendimento_in       ( rendimento ),
    .gastos_fixos_in     ( gastosFixos ),
    .gastos_unicos_in    ( gastosUnicos ),
    .acao                ( acoes_out ),
    .init                ( init ),

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
      .clr    ( zeraCJ ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCJ ),
      .modulo ( 4'b0100 ),  //(modulo +1) jogadas
      .D      ( 4'b0000 ),     
      .Q      ( contagem ),
      .rco    ( fim_rodada )
    );


    // contador_modulo_n contadorRodada
    contador_modulo_n #(.N(4)) contadorRodada (
      .clock  ( clock ),
      .clr    ( zeraCR ),
      .ld     ( 1'b1 ),
      .ent    ( 1'b1 ),
      .enp    ( contaCR ),
      .modulo ( 4'b0011 ),  //(modulo + 1) rodadas
      .D      ( 4'b0000 ),     
      .Q      ( rodada ),
      .rco    ( ultima_rodada )
    );


    assign fim_jogo = fim_rodada && ultima_rodada;
    assign fim_perdeu = 1'b0; //provisorio

endmodule