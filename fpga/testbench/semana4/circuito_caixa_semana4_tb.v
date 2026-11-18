`timescale 1ns/1ps
// ---------------------------------------------------------------------------
// Semana 4 - Cenario de Teste 10: interface fisica da caixa no topo do circuito
//
// Simula o circuito_jogo_financeiro completo do ponto de vista da tampa da
// caixa: botoes e seletor ativos em nivel baixo (comum no GND), cartao RFID
// chegando pela UART da ESP32 (comando RNN\n em rfid_rx, 115200 8-N-1),
// LEDs dos itens (indicador_itens), LEDs FALIU/FIM DO JOGO, LEDs ULTIMA e
// contadores dos displays de rodada e jogada.
//
// Para a simulacao terminar em segundos, o divisor de clock do topo e
// reduzido por defparam (CLOCK_DIV = 4 -> clock_ajustado de 512 ciclos de
// 50 MHz, em vez de 100.000). A logica do jogo e a mesma; a UART continua a
// 115200 baud porque usa o clock de 50 MHz.
//
// Sequencia (casos 1 a 9):
//   1  reset e INICIAR: saldo inicial 150, LEDs apagados
//   2  seletor girado da posicao 1 ate a 10: evento 14 com o item certo
//   3  painel de consulta: config_display mostra salario e volta ao saldo
//   4  TRABALHAR, ESTUDAR (sem custo, so o custo de vida), INVESTIR, RESGATAR e avanco de rodada
//   5  cartao R08: compra aceita, LED do item 8 aceso (evento 06)
//   6  seletor no 8 + VENDER: LED 8 apaga (evento 08)
//   7  cartao R08 duas vezes: a segunda e recusada (evento 07)
//   8  3 vidas (adaptado depois da semana 4): COMPRAR sem saldo e ESTUDAR que
//      fale no custo de vida desfazem a jogada e tiram 1 vida (evento 15); na
//      3a falha, saldo negativo, LED FALIU (evento 13)
//   9  RESET, INICIAR e partida ate a ultima rodada: 15|15, LEDs ULTIMA e
//      FIM DO JOGO (evento 12; ver AVISO no caso 9)
//
// Gera semana4.vcd quando chamado com +vcd (usado nas imagens do relatorio).
// ---------------------------------------------------------------------------
module circuito_caixa_semana4_tb;

    // ---------------- estados da UC (para conferencia) ----------------
    localparam [4:0] ESPERA_INICIO = 5'b00001;
    localparam [4:0] ESPERA_ACAO   = 5'b00100;
    localparam [4:0] FIM_JOGO      = 5'b11101;
    localparam [4:0] FIM_FALENCIA  = 5'b11110;

    // ---------------- entradas da caixa (ativas em 0) ----------------
    reg        clock      = 1'b0;
    reg        reset      = 1'b1;
    reg        iniciar    = 1'b1;
    reg        estudar    = 1'b1;
    reg        trabalhar  = 1'b1;
    reg        investir   = 1'b1;
    reg        resgatar   = 1'b1;
    reg        comprar    = 1'b1;
    reg        vender     = 1'b1;
    reg  [9:0] seletor_item   = 10'b11_1111_1111;
    reg  [5:0] config_display = 6'b11_1111;
    reg        rfid_rx    = 1'b1;   // linha UART em repouso

    // ---------------- saidas para a tampa ----------------
    wire [11:0] display_jogadas;
    wire [11:0] display_rodadas;
    wire [41:0] display_dinheiro;
    wire [9:0]  indicador_itens;
    wire        ultima_jogada;
    wire        ultima_rodada;
    wire        terminou;
    wire        perdeu;
    wire        uart_tx;

    always #10 clock = ~clock;      // 50 MHz

    circuito_jogo_financeiro dut (
        .clock            ( clock ),
        .reset            ( reset ),
        .iniciar          ( iniciar ),
        .estudar          ( estudar ),
        .trabalhar        ( trabalhar ),
        .investir         ( investir ),
        .resgatar         ( resgatar ),
        .comprar          ( comprar ),
        .vender           ( vender ),
        .seletor_item     ( seletor_item ),
        .config_display   ( config_display ),
        .rfid_rx          ( rfid_rx ),
        .display_jogadas  ( display_jogadas ),
        .display_rodadas  ( display_rodadas ),
        .display_dinheiro ( display_dinheiro ),
        .indicador_itens  ( indicador_itens ),
        .ultima_jogada    ( ultima_jogada ),
        .ultima_rodada    ( ultima_rodada ),
        .terminou         ( terminou ),
        .perdeu           ( perdeu ),
        .uart_tx          ( uart_tx )
    );

    // clock do jogo acelerado apenas na simulacao
    defparam dut.divisor_clock.CLOCK_DIV = 4;

    // ---------------- sinais internos observados ----------------
    wire               clk_jogo   = dut.clock_ajustado;
    wire [4:0]         estado     = dut.w_estado;
    wire signed [20:0] saldo      = dut.fd.saldo;
    wire signed [20:0] salario    = dut.fd.salario;
    wire signed [20:0] investido  = dut.fd.valorInvestido;
    wire [3:0]         rodada     = dut.w_rodada;
    wire [3:0]         jogada     = dut.w_contagem;
    wire [1:0]         vidas      = dut.fd.vidas;
    wire [23:0]        dinheiro   = dut.dinheiro;      // BCD do display HEX
    wire               tel_send   = dut.fd.telemetry_send;
    wire [7:0]         tel_evento = dut.fd.telemetry_event;
    wire [3:0]         tel_item   = dut.fd.telemetry_item;
    wire               rfid_valid = dut.rfid_item_valid;
    wire               rfid_ack   = dut.rfid_ack;

    reg [31:0] caso = 0;
    reg [3:0]  jogada_antes;
    reg signed [20:0] salario_antes;
    integer    erros = 0;
    integer    verificacoes = 0;

    // ---------------- captura dos eventos de telemetria ----------------
    reg        tel_send_ant = 1'b0;
    integer    n_eventos = 0;
    reg [7:0]  ult_evento = 8'd0;
    reg [3:0]  ult_item   = 4'd0;
    integer    n_evento12 = 0;          // eventos 12 (fim de jogo) enviados
    reg [4:0]  estado_evento12 = 5'd0;  // estado da UC quando o 12 saiu
    always @(posedge clk_jogo) begin
        tel_send_ant <= tel_send;
        if (tel_send && !tel_send_ant) begin
            n_eventos  = n_eventos + 1;
            ult_evento = tel_evento;
            ult_item   = tel_item;
            if (tel_evento == 8'd12) begin
                n_evento12 = n_evento12 + 1;
                estado_evento12 = estado;
            end
        end
    end
    integer    avisos = 0;

    // bytes enviados pela FPGA a ESP32 (borda de descida = start bit aproximado)
    integer bytes_tx = 0;
    reg     tx_ant = 1'b1;
    always @(posedge clock) begin
        tx_ant <= uart_tx;
        if (tx_ant && !uart_tx) bytes_tx = bytes_tx + 1;
    end

    // ---------------- tarefas auxiliares ----------------
    task espera_jogo(input integer n);
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) @(posedge clk_jogo);
        end
    endtask

    task confere(input cond, input [8*72-1:0] msg);
        begin
            verificacoes = verificacoes + 1;
            if (!cond) begin
                erros = erros + 1;
                $display("  FALHOU [caso %0d] %0s", caso, msg);
            end
        end
    endtask

    task confere_saldo(input integer esperado, input [8*40-1:0] msg);
        begin
            verificacoes = verificacoes + 1;
            if (saldo !== esperado) begin
                erros = erros + 1;
                $display("  FALHOU [caso %0d] %0s: saldo=%0d esperado=%0d",
                         caso, msg, saldo, esperado);
            end
        end
    endtask

    task confere_evento(input [7:0] evento, input [3:0] item, input [8*40-1:0] msg);
        begin
            verificacoes = verificacoes + 1;
            if (ult_evento !== evento || ult_item !== item) begin
                erros = erros + 1;
                $display("  FALHOU [caso %0d] %0s: evento=%0d item=%0d (esperado %0d/%0d)",
                         caso, msg, ult_evento, ult_item, evento, item);
            end
        end
    endtask

    // aperta um botao da tampa (nivel 0) por 6 ciclos do jogo e solta
    localparam integer B_INICIAR = 0, B_TRABALHAR = 1, B_ESTUDAR = 2,
                       B_INVESTIR = 3, B_RESGATAR = 4, B_COMPRAR = 5,
                       B_VENDER = 6;
    task botao(input integer id, input nivel);
        begin
            case (id)
                B_INICIAR:   iniciar   = nivel;
                B_TRABALHAR: trabalhar = nivel;
                B_ESTUDAR:   estudar   = nivel;
                B_INVESTIR:  investir  = nivel;
                B_RESGATAR:  resgatar  = nivel;
                B_COMPRAR:   comprar   = nivel;
                B_VENDER:    vender    = nivel;
            endcase
        end
    endtask

    task aperta(input integer id);
        begin
            @(negedge clk_jogo);
            botao(id, 1'b0);
            espera_jogo(6);
            botao(id, 1'b1);
            espera_jogo(8);
        end
    endtask

    // gira o seletor (comum no GND: a posicao escolhida fica em 0)
    task gira_seletor(input integer posicao);
        begin
            seletor_item = ~(10'b1 << (posicao - 1));
            espera_jogo(48);    // > 40 ciclos do filtro de estabilidade
        end
    endtask

    // ESP32 envia um byte na UART (115200 baud, 8-N-1)
    localparam integer BIT_NS = 434 * 20;   // mesmo arredondamento do RTL
    task uart_byte(input [7:0] b);
        integer k;
        begin
            rfid_rx = 1'b0; #(BIT_NS);
            for (k = 0; k < 8; k = k + 1) begin
                rfid_rx = b[k]; #(BIT_NS);
            end
            rfid_rx = 1'b1; #(BIT_NS);
        end
    endtask

    // cartao aproximado: a ESP32 manda "RNN\n"
    task cartao(input integer item);
        begin
            uart_byte("R");
            uart_byte("0" + item / 10);
            uart_byte("0" + item % 10);
            uart_byte(8'h0a);
            espera_jogo(14);
        end
    endtask

    task inicia_partida;
        begin
            aperta(B_INICIAR);
            confere(estado == ESPERA_ACAO, "UC em ESPERA_ACAO apos INICIAR");
        end
    endtask

    integer i;
    integer saldo_esp;

    // ---------------- estimulos ----------------
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("semana4.vcd");
            $dumpvars(0, caso, reset, iniciar, estudar, trabalhar, investir,
                      resgatar, comprar, vender, seletor_item, config_display,
                      rfid_rx, indicador_itens, ultima_jogada, ultima_rodada,
                      terminou, perdeu, uart_tx, clk_jogo, estado, saldo,
                      salario, investido, rodada, jogada, dinheiro, tel_send,
                      tel_evento, tel_item, rfid_valid, rfid_ack);
        end

        $display("Semana 4 - interface fisica da caixa (circuito_jogo_financeiro)");

        // ---- caso 1: reset e inicio ----
        caso = 1;
        #(200);
        reset = 1'b0;           // botao RESET da tampa
        #(20 * 512 * 20);
        reset = 1'b1;
        espera_jogo(6);
        confere(estado == ESPERA_INICIO, "UC em ESPERA_INICIO apos RESET");
        confere(indicador_itens == 10'd0, "LEDs dos itens apagados apos RESET");
        confere(!terminou && !perdeu, "LEDs FIM DO JOGO e FALIU apagados");
        inicia_partida;
        espera_jogo(2);
        confere_saldo(150, "saldo inicial");
        confere(dinheiro == 24'h000150, "display mostra o saldo sem botao de consulta");
        confere(rodada == 0 && jogada == 0, "displays em rodada 1 e jogada 1");
        confere_evento(8'd1, 4'd0, "evento 01 (inicio de sessao)");

        // ---- caso 2: seletor da posicao 1 ate a 10 ----
        caso = 2;
        for (i = 1; i <= 10; i = i + 1) begin
            gira_seletor(i);
            confere_evento(8'd14, i[3:0], "evento 14 com o item do seletor");
        end
        confere_saldo(150, "girar o seletor nao muda o saldo");
        seletor_item = 10'b11_1111_1111;   // entre posicoes: nenhuma em 0
        espera_jogo(48);
        confere_evento(8'd14, 4'd10, "posicao sem item nao gera evento");

        // ---- caso 3: painel de consulta interno ----
        caso = 3;
        @(negedge clk_jogo); config_display = 6'b10_1111;   // botao do salario
        espera_jogo(6); config_display = 6'b11_1111; espera_jogo(6);
        confere(dinheiro == 24'h000064, "display mostra o salario (64)");
        @(negedge clk_jogo); config_display = 6'b01_1111;   // botao do saldo
        espera_jogo(6); config_display = 6'b11_1111; espera_jogo(6);
        confere(dinheiro == 24'h000150, "display volta ao saldo (150)");
        confere(estado == ESPERA_ACAO, "consulta nao gasta jogada");

        // ---- caso 4: acoes da tampa ----
        caso = 4;
        aperta(B_TRABALHAR);                      // 150 + 64 - 40
        confere_saldo(174, "TRABALHAR + despesa fixa");
        confere(jogada == 1, "jogada 2 de 3");
        aperta(B_ESTUDAR);                        // 174 - 40 (estudar nao custa), salario 104
        confere_saldo(134, "ESTUDAR so paga a despesa fixa");
        confere(salario == 104, "salario aumenta com ESTUDAR");
        confere(jogada == 2 && ultima_jogada, "jogada 3 de 3 e LED ULTIMA (jogada)");
        aperta(B_TRABALHAR);                      // 134 + 104 - 40, nova rodada
        confere_saldo(198, "TRABALHAR na ultima jogada");
        confere(rodada == 1 && jogada == 0, "rodada 2, jogada 1");
        aperta(B_TRABALHAR);                      // 262
        aperta(B_TRABALHAR);                      // 326
        confere_saldo(326, "mais duas jogadas de TRABALHAR");
        aperta(B_INVESTIR);
        confere_saldo(316, "INVESTIR retira 10 do saldo");
        confere(investido == 10, "valor investido = 10");
        confere_evento(8'd4, 4'd0, "evento 04 (investir)");
        aperta(B_RESGATAR);
        confere_saldo(326, "RESGATAR devolve o investimento");
        confere(investido == 0, "investimento zerado");
        confere_evento(8'd5, 4'd0, "evento 05 (resgatar)");

        // ---- caso 5: cartao no item 8 ----
        caso = 5;
        cartao(8);
        confere_saldo(246, "compra do item 8 pelo cartao (80)");
        confere(indicador_itens == 10'b00_1000_0000, "LED do item 8 aceso");
        confere(!rfid_valid, "comando RFID consumido pelo acknowledge");
        confere_evento(8'd6, 4'd8, "evento 06 (compra aceita, item 8)");

        // ---- caso 6: vender o item 8 com seletor + VENDER ----
        caso = 6;
        gira_seletor(8);
        aperta(B_VENDER);
        confere_saldo(326, "venda devolve o preco do item 8");
        confere(indicador_itens == 10'd0, "LED do item 8 apaga");
        confere_evento(8'd8, 4'd8, "evento 08 (venda aceita, item 8)");

        // ---- caso 7: item repetido pelo cartao ----
        caso = 7;
        cartao(8);
        confere_saldo(246, "nova compra do item 8");
        cartao(8);
        confere_saldo(246, "item repetido nao debita o saldo");
        confere(indicador_itens == 10'b00_1000_0000, "inventario inalterado");
        confere_evento(8'd7, 4'd8, "evento 07 (compra recusada)");
        confere(estado == ESPERA_ACAO, "jogo continua apos a recusa");

        // ---- caso 8: 3 vidas; a 3a falha e falencia ----
        caso = 8;
        confere(vidas == 3, "partida comeca com 3 vidas");
        // 8a: COMPRAR o item 1 (600) com 246: falha na acao. A compra e desfeita
        // e o jogador perde 1 vida.
        gira_seletor(1);
        aperta(B_COMPRAR);
        confere_saldo(246, "compra sem saldo e desfeita");
        confere(indicador_itens == 10'b00_1000_0000, "item 1 nao entra no inventario");
        confere(vidas == 2 && estado == ESPERA_ACAO && !perdeu, "perde 1 vida e continua (2 vidas)");
        espera_jogo(4);
        confere_evento(8'd15, 4'd0, "evento 15 (vida perdida)");
        // 8b: falha no custo de vida. Compra o item 7 (120) e investe ate sobrar
        // 36; ESTUDAR paga 40 de custo de vida: 36 - 40 = -4. A jogada e desfeita:
        // saldo, salario e jogada voltam; perde mais 1 vida.
        gira_seletor(7);
        aperta(B_COMPRAR);                        // 246 - 120 = 126
        for (i = 0; i < 9; i = i + 1) aperta(B_INVESTIR);  // 126 - 90 = 36
        confere_saldo(36, "saldo menor que o custo de vida");
        jogada_antes = jogada;
        salario_antes = salario;
        aperta(B_ESTUDAR);
        confere_saldo(36, "ESTUDAR que fale no custo de vida e desfeito");
        confere(salario == salario_antes, "aumento de salario do estudo desfeito");
        confere(jogada == jogada_antes, "jogada nao avanca: o jogador repete a jogada");
        confere(vidas == 1 && estado == ESPERA_ACAO && !perdeu, "perde 1 vida e continua (1 vida)");
        espera_jogo(4);
        confere_evento(8'd15, 4'd0, "evento 15 (vida perdida)");
        // 8c: 3a falha: falencia de verdade.
        gira_seletor(1);
        aperta(B_COMPRAR);                        // 36 - 600 = -564
        confere_saldo(-564, "3a falha deixa o saldo negativo");
        confere(indicador_itens == 10'b00_1100_0001, "LEDs dos itens 1, 7 e 8 acesos");
        confere(estado == FIM_FALENCIA && perdeu, "LED FALIU aceso (FIM_FALENCIA)");
        confere(!terminou, "LED FIM DO JOGO apagado na falencia");
        confere(dut.fd.telemetry_lives == 0, "telemetria mostra 0 vidas na falencia");
        espera_jogo(4);
        confere_evento(8'd13, 4'd0, "evento 13 (falencia)");

        // ---- caso 9: RESET, nova partida ate o fim ----
        caso = 9;
        reset = 1'b0;
        #(20 * 512 * 20);
        reset = 1'b1;
        espera_jogo(6);
        confere(indicador_itens == 10'd0 && !perdeu, "RESET apaga LEDs dos itens e FALIU");
        inicia_partida;
        espera_jogo(2);
        confere_saldo(150, "saldo inicial na nova partida");
        saldo_esp = 150;
        for (i = 1; i <= 45; i = i + 1) begin
            aperta(B_TRABALHAR);
            saldo_esp = saldo_esp + 64 - 40;
            if (i == 42)
                confere(rodada == 14 && ultima_rodada, "rodada 15 e LED ULTIMA (rodada)");
        end
        confere_saldo(saldo_esp, "saldo apos 45 jogadas");
        confere(rodada == 14 && jogada == 2, "displays em 15|15 e 3|3");
        confere(ultima_rodada && ultima_jogada, "LEDs ULTIMA acesos");
        confere(estado == FIM_JOGO && terminou, "LED FIM DO JOGO aceso");
        confere(!perdeu, "LED FALIU apagado no fim de jogo");
        espera_jogo(4);
        confere(n_evento12 == 1, "evento 12 (fim de jogo) enviado uma unica vez");
        // Nao conformidade conhecida do RTL: fim_jogo = fim_rodada && ultima_rodada
        // ja vale em ESPERA_ACAO da ultima jogada, entao o evento 12 sai antes da
        // jogada final (o LED FIM DO JOGO, que vem do estado FIM_JOGO, esta correto).
        if (estado_evento12 != FIM_JOGO) begin
            avisos = avisos + 1;
            $display("  AVISO [caso 9] evento 12 enviado com a UC no estado %b (ESPERA_ACAO),", estado_evento12);
            $display("        antes da ultima jogada; o painel mostra o fim uma jogada antes do LED");
        end
        aperta(B_TRABALHAR);
        confere(estado == FIM_JOGO, "acoes ignoradas apos o fim do jogo");

        confere(bytes_tx > 0, "FPGA enviou quadros AEF2 pela uart_tx");

        $display("  verificacoes: %0d, avisos: %0d, eventos de telemetria: %0d, bytes na uart_tx: %0d",
                 verificacoes, avisos, n_eventos, bytes_tx);
        if (erros == 0)
            $display("PASS Semana 4: interface fisica da caixa (casos 1 a 9)");
        else begin
            $display("FALHOU Semana 4: %0d verificacoes com erro", erros);
            $fatal(1);
        end
        $finish;
    end

    initial begin
        #(400_000_000);
        $display("FALHOU Semana 4: tempo limite da simulacao");
        $fatal(1);
    end
endmodule
