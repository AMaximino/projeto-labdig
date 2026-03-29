`timescale 1ns/1ns

module circuito_jogo_financeiro_tb1;

    // Sinais para conectar com o DUT
    // valores iniciais para fins de simulacao (ModelSim)
    reg        clock_in = 1;
    reg        reset_in = 1;
    reg        iniciar_in = 1;
    reg        estudar_in = 1;
    reg        trabalhar_in = 1;
    reg        investir_in = 1;
    reg        resgatar_in = 1;
    reg        comprar_in = 1;
    reg        vender_in = 1;
    reg  [9:0] seletor_item_in = 10'b1111111111;
    reg  [5:0] config_display_in = 6'b111111;

    wire [3:0]  contagem_out;
    wire [3:0]  rodada_out;
    wire [4:0]  estado_out;

    //wire [11:0] display_jogadas_out;
    //wire [11:0] display_rodadas_out;
    wire [41:0] display_dinheiro_out;
    wire [9:0] indicador_itens_out;
    wire        ultima_jogada_out;
    wire        ultima_rodada_out;
    wire        terminou_out;
    wire        perdeu_out;
    

    // Configuração do clock
    parameter clockPeriod = 1_000; // in ns, f=1MHz

    // Identificacao do caso de teste
    reg [31:0] caso = 0;

    // Gerador de clock
    always #((clockPeriod / 2)) clock_in = ~clock_in;

    // instanciacao do DUT (Device Under Test)
    circuito_jogo_financeiro dut (
      .clock            ( clock_in ),
      .reset            ( reset_in ),
      .iniciar          ( iniciar_in ),
      .estudar          ( estudar_in ),
      .trabalhar        ( trabalhar_in ),
      .investir         ( investir_in ),
      .resgatar         ( resgatar_in ),
      .comprar          ( comprar_in ),
      .vender           ( vender_in ),
      .seletor_item     ( seletor_item_in ),
      .config_display   ( config_display_in ),
      .contagem         ( contagem_out ),
      .rodada           ( rodada_out ),
      .estado           ( estado_out ),
      //.display_jogadas  ( display_jogadas_out ),
      //.display_rodadas  ( display_rodadas_out ),
      .display_dinheiro ( display_dinheiro_out ),
      .indicador_itens  ( indicador_itens_out ),
      .ultima_jogada    ( ultima_jogada_out ),
      .ultima_rodada    ( ultima_rodada_out ),
      .terminou         ( terminou_out ),
      .perdeu           ( perdeu_out )
      );

    // geracao dos sinais de entrada (estimulos)
    initial begin
      $display("Inicio da simulacao");

      // condicoes iniciais
      caso            = 0;
      clock_in        = 1;
      reset_in        = 1;
      iniciar_in      = 1;
      estudar_in      = 1;
      trabalhar_in    = 1;
      investir_in     = 1;
      resgatar_in     = 1;
      comprar_in      = 1;
      vender_in       = 1;
      config_display_in = 6'b111111;
      seletor_item_in = 10'b1111111111;
      #clockPeriod;

      #(10*clockPeriod);
      // Teste 1. resetar circuito
      caso = 1;
      // gera pulso de reset
      @(negedge clock_in);
      reset_in = 0;
      #(clockPeriod);
      reset_in = 1;
      #(10*clockPeriod);

      // Teste 2. iniciar ligado (=0) por 5 periodos de clock e esperar 10 
      caso = 2;
      iniciar_in = 0;
      #(5*clockPeriod);
      iniciar_in = 1;
      #(10*clockPeriod);

      //RODADA 1
      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      estudar_in = 0;
      #(10*clockPeriod);
      estudar_in = 1;
      #(10*clockPeriod);

      // Teste 4. jogada #2
      caso = 4;
      @(negedge clock_in);
      trabalhar_in = 0;
      #(10*clockPeriod);
      trabalhar_in = 1;
      #(10*clockPeriod);

      // Teste 5. muda_display
      caso = 5;
      @(negedge clock_in);
      config_display_in = 6'b011111;
      #(10*clockPeriod);
      config_display_in = 6'b111111;
      #(10*clockPeriod);

      // Teste 6. jogada #4
      caso = 6;
      @(negedge clock_in);
      estudar_in = 0;
      #(10*clockPeriod);
      estudar_in = 1;
      #(10*clockPeriod);

      // Teste 7. jogada #5
      caso = 7;
      @(negedge clock_in);
      trabalhar_in = 0;
      #(10*clockPeriod);
      trabalhar_in = 1;
      #(10*clockPeriod);

      // Teste 8. jogada #6
      caso = 8;
      @(negedge clock_in);
      seletor_item_in = 10'b1101111111; //seleciona shoping (5 = 500 pila)
      #(10*clockPeriod);
      comprar_in = 0; //compra
      #(10*clockPeriod);
      comprar_in = 1;
      #(10*clockPeriod);

      // Teste 8. jogada #6
      caso = 8;
      @(negedge clock_in);
      seletor_item_in = 10'b1111111101; //seleciona carro2 (1000 = 100k)
      #(10*clockPeriod);
      comprar_in = 0; //compra
      #(10*clockPeriod);
      comprar_in = 1;
      #(10*clockPeriod);

      // Teste 8. jogada #6
      caso = 8;
      @(negedge clock_in);
      seletor_item_in = 10'b1111111101; //seleciona carro2 (1000 = 100k)
      #(10*clockPeriod);
      comprar_in = 0; //tenta comprar o carro ja tendo ele, é pra nao acontecer nada
      #(10*clockPeriod);
      comprar_in = 1;
      #(10*clockPeriod);

      // Teste 9. jogada #7
      caso = 9;
      @(negedge clock_in);
      seletor_item_in = 10'b1101111111; //seleciona shopping (5 = 500 pila)
      #(10*clockPeriod);
      vender_in = 0; //vender 
      #(10*clockPeriod); 
      vender_in = 1;
      #(10*clockPeriod);

      // Teste 10. jogada #8
      caso = 10;
      @(negedge clock_in);
      trabalhar_in = 0;
      #(10*clockPeriod);
      trabalhar_in = 1;
      #(10*clockPeriod);

      // final dos casos de teste da simulacao
      caso = 99;
      #100;
      $display("Fim da simulacao");
      $stop;
    end

  endmodule