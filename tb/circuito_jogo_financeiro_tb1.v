`timescale 1ns/1ns

module circuito_jogo_financeiro_tb1;

    // Sinais para conectar com o DUT
    // valores iniciais para fins de simulacao (ModelSim)
    reg        clock_in = 1;
    reg        reset_in = 0;
    reg        iniciar_in = 0;
    reg        trabalhar_in = 0;
    reg        estudar_in = 0;
    reg        investir_in = 0;
    reg        resgatar_in = 0;
    reg        comprar_in = 0;
    reg        vender_in = 0;
    reg  [2:0] itens_in = 3'b000;
    reg  [5:0] config_display_in = 4'b0000;
    reg        jogada_in;

    wire [6:0]  contagem_out;
    wire [6:0]  rodada_out;
    wire [11:0] display_rodadas_out;
    wire [11:0] display_jogadas_out;
    wire [41:0] display_dinheiro_out;
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
      .trabalhar        ( trabalhar ),
      .estudar          ( estudar_in ),
      .investir         ( investir_in ),
      .resgatar         ( resgatar_in ),
      .comprar          ( comprar_in),
      .vender           ( vender_in),
      .itens            ( itens_in ),
      .config_display   ( config_display_in ),
      .jogada           ( leds_rgb_out ),
      .contagem         ( contagem_out ),
      .rodada           ( rodada_out ),
      .display_rodadas  ( display_rodadas_out ),
      .display_jogadas  ( display_jogadas_out ),
      .display_dinheiro ( display_dinheiro_out ),
      .terminou         ( terminou_out ),
      .perdeu           ( perdeu_out )
      );

    // geracao dos sinais de entrada (estimulos)
    initial begin
      $display("Inicio da simulacao");

      // condicoes iniciais
      caso            = 0;
      clock_in        = 1;
      reset_in        = 0;
      iniciar_in      = 0;
      #clockPeriod;

      // Teste 1. resetar circuito
      caso = 1;
      // gera pulso de reset
      @(negedge clock_in);
      reset_in = 1;
      #(clockPeriod);
      reset_in = 0;
      #(10*clockPeriod);

      // Teste 2. iniciar = 1 por 5 periodos de clock // e esperar 10 segundos
      caso = 2;
      iniciar_in = 1;
      #(5*clockPeriod);
      iniciar_in = 0;
      #(10*clockPeriod);

      //RODADA 1
      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 4. jogada #1
      caso = 4;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 5. jogada #1
      caso = 5;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 6. jogada #1
      caso = 6;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 7. jogada #1
      caso = 7;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 8. jogada #1
      caso = 8;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 9. jogada #1
      caso = 9;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 10. jogada #1
      caso = 10;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 11. jogada #1
      caso = 11;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 12. jogada #1
      caso = 12;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 13. jogada #1
      caso = 13;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 14. jogada #1
      caso = 14;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);

      // Teste 3. jogada #1
      caso = 3;
      @(negedge clock_in);
      jogada_in = 1'b1;
      #(10*clockPeriod);
      jogada_in = 1'b0;
      #(10*clockPeriod);



      // final dos casos de teste da simulacao
      caso = 99;
      #100;
      $display("Fim da simulacao");
      $stop;
    end

  endmodule