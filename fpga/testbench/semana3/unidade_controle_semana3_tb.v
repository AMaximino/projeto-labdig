`timescale 1ns/1ps

module unidade_controle_semana3_tb;
    localparam [4:0] INICIO = 5'b00000;
    localparam [4:0] ESPERA_INICIO = 5'b00001;
    localparam [4:0] INICIALIZA_JOGO = 5'b00010;
    localparam [4:0] PREPARA_JOGO = 5'b00011;
    localparam [4:0] ESPERA_ACAO = 5'b00100;
    localparam [4:0] REGISTRA_ACAO = 5'b00101;
    localparam [4:0] PROCESSA_ACAO = 5'b00110;
    localparam [4:0] VERIFICA_FALENCIA = 5'b00111;
    localparam [4:0] VERIFICA_JOGADA = 5'b01000;
    localparam [4:0] VERIFICA_FIM_JOGO = 5'b01001;
    localparam [4:0] VERIFICA_FIM_RODADA = 5'b01010;
    localparam [4:0] AVANCA_JOGADA = 5'b01011;
    localparam [4:0] AVANCA_RODADA = 5'b01100;
    localparam [4:0] APLICA_DESPESA = 5'b01101;
    localparam [4:0] VERIFICA_FALENCIA_DESPESA = 5'b01110;
    localparam [4:0] REGISTRA_DISPLAY = 5'b11010;
    localparam [4:0] REGISTRA_DISPLAY_FINAL = 5'b11011;
    localparam [4:0] REGISTRA_DISPLAY_FALENCIA = 5'b11100;
    localparam [4:0] FIM_JOGO = 5'b11101;
    localparam [4:0] FIM_FALENCIA = 5'b11110;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg iniciar = 1'b0;
    reg acao_pulso = 1'b0;
    reg eh_jogada = 1'b0;
    reg display_pulso = 1'b0;
    reg fim_jogo = 1'b0;
    reg fim_perdeu = 1'b0;
    reg fim_rodada = 1'b0;

    wire desligaDisplay;
    wire rstED;
    wire init;
    wire processaE;
    wire rende;
    wire despesa;
    wire zeraCJ;
    wire contaCJ;
    wire zeraCR;
    wire contaCR;
    wire zeraD;
    wire registraD;
    wire zeraA;
    wire registraA;
    wire zeraV;
    wire registraV;
    wire zeraM;
    wire registraM;
    wire terminou;
    wire perdeu;
    wire [4:0] estado;

    always #5 clock = ~clock;

    unidade_controle dut (
        .clock(clock),
        .reset(reset),
        .iniciar(iniciar),
        .acao_pulso(acao_pulso),
        .eh_jogada(eh_jogada),
        .display_pulso(display_pulso),
        .fim_jogo(fim_jogo),
        .fim_perdeu(fim_perdeu),
        .fim_rodada(fim_rodada),
        .desligaDisplay(desligaDisplay),
        .rstED(rstED),
        .init(init),
        .processaE(processaE),
        .rende(rende),
        .despesa(despesa),
        .zeraCJ(zeraCJ),
        .contaCJ(contaCJ),
        .zeraCR(zeraCR),
        .contaCR(contaCR),
        .zeraD(zeraD),
        .registraD(registraD),
        .zeraA(zeraA),
        .registraA(registraA),
        .zeraV(zeraV),
        .registraV(registraV),
        .zeraM(zeraM),
        .registraM(registraM),
        .terminou(terminou),
        .perdeu(perdeu),
        .estado(estado)
    );

    task tick;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    task expect_state;
        input [4:0] expected;
        input [8*32-1:0] description;
        begin
            if (estado !== expected)
                $fatal(1, "%0s: expected state %b, got %b", description, expected, estado);
        end
    endtask

    task start_game;
        begin
            iniciar = 1'b1;
            tick;
            expect_state(INICIALIZA_JOGO, "initialize game");
            if (!init) $fatal(1, "init output not asserted during initialization");
            iniciar = 1'b0;
            tick;
            expect_state(PREPARA_JOGO, "prepare game");
            tick;
            expect_state(ESPERA_ACAO, "wait for action");
        end
    endtask

    task register_action;
        begin
            acao_pulso = 1'b1;
            tick;
            expect_state(REGISTRA_ACAO, "register action");
            if (!registraA) $fatal(1, "registraA output not asserted");
            acao_pulso = 1'b0;
            tick;
            expect_state(PROCESSA_ACAO, "process action");
            if (!processaE) $fatal(1, "processaE output not asserted");
            tick;
            expect_state(VERIFICA_FALENCIA, "check bankruptcy after action");
        end
    endtask

    task apply_successful_move;
        begin
            register_action();
            tick;
            expect_state(VERIFICA_JOGADA, "check whether action counts as move");
            eh_jogada = 1'b1;
            tick;
            expect_state(APLICA_DESPESA, "apply move expenses");
            if (!despesa) $fatal(1, "despesa output not asserted");
            eh_jogada = 1'b0;
            tick;
            expect_state(VERIFICA_FALENCIA_DESPESA, "check bankruptcy after expenses");
            tick;
            expect_state(VERIFICA_FIM_JOGO, "check game completion");
        end
    endtask

    initial begin
        tick;
        expect_state(INICIO, "asynchronous reset state");
        if (!rstED) $fatal(1, "rstED output not asserted in INICIO");

        reset = 1'b0;
        tick;
        expect_state(ESPERA_INICIO, "wait for start");
        if (!desligaDisplay) $fatal(1, "display should be disabled before start");

        start_game();

        register_action();
        tick;
        expect_state(VERIFICA_JOGADA, "check non-move action");
        eh_jogada = 1'b0;
        tick;
        expect_state(ESPERA_ACAO, "return after non-move action");

        display_pulso = 1'b1;
        tick;
        expect_state(REGISTRA_DISPLAY, "register live display selection");
        if (!registraD) $fatal(1, "registraD output not asserted");
        display_pulso = 1'b0;
        tick;
        expect_state(ESPERA_ACAO, "return after live display selection");

        apply_successful_move();
        fim_jogo = 1'b0;
        tick;
        expect_state(VERIFICA_FIM_RODADA, "check round completion");
        fim_rodada = 1'b0;
        tick;
        expect_state(AVANCA_JOGADA, "advance regular move");
        if (!contaCJ) $fatal(1, "contaCJ output not asserted while advancing move");
        tick;
        expect_state(ESPERA_ACAO, "return after advancing move");

        apply_successful_move();
        fim_jogo = 1'b0;
        tick;
        expect_state(VERIFICA_FIM_RODADA, "check round completion before round advance");
        fim_rodada = 1'b1;
        tick;
        expect_state(AVANCA_RODADA, "advance completed round");
        if (!rende || !contaCR) $fatal(1, "round advance outputs not asserted");
        fim_rodada = 1'b0;
        tick;
        expect_state(ESPERA_ACAO, "return after advancing round");

        register_action();
        fim_perdeu = 1'b1;
        tick;
        expect_state(FIM_FALENCIA, "bankruptcy before move");
        if (!perdeu) $fatal(1, "perdeu output not asserted");
        fim_perdeu = 1'b0;
        display_pulso = 1'b1;
        tick;
        expect_state(REGISTRA_DISPLAY_FALENCIA, "register bankruptcy display");
        display_pulso = 1'b0;
        tick;
        expect_state(FIM_FALENCIA, "return to bankruptcy terminal state");

        start_game();
        register_action();
        tick;
        expect_state(VERIFICA_JOGADA, "check move before expense bankruptcy");
        eh_jogada = 1'b1;
        tick;
        expect_state(APLICA_DESPESA, "apply move before expense bankruptcy");
        eh_jogada = 1'b0;
        tick;
        expect_state(VERIFICA_FALENCIA_DESPESA, "check bankruptcy after expenses");
        fim_perdeu = 1'b1;
        tick;
        expect_state(FIM_FALENCIA, "bankruptcy after expenses");
        if (!perdeu) $fatal(1, "perdeu output not asserted after expenses");
        fim_perdeu = 1'b0;

        start_game();
        apply_successful_move();
        fim_jogo = 1'b1;
        tick;
        expect_state(FIM_JOGO, "game completion");
        if (!terminou) $fatal(1, "terminou output not asserted");
        fim_jogo = 1'b0;
        display_pulso = 1'b1;
        tick;
        expect_state(REGISTRA_DISPLAY_FINAL, "register final display");
        display_pulso = 1'b0;
        tick;
        expect_state(FIM_JOGO, "return to game terminal state");

        $display("PASS Semana 3: game FSM action, display, round and terminal paths");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Semana 3 game FSM test timed out");
    end
endmodule
